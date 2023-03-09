/**
 *  Creates Route_Process_Sheet__c sObjects using Route_Schedule_Account__c information
 */
public class clBatchRouteProcessingSheetCreation implements Database.Batchable<SObject>, Database.Stateful{

    @TestVisible private final static String MDT_DEV_NAME_EMAIL = 'clQueueableProcessFillSummaryEmail';
    public static String jobName = 'clBatchRouteProcessingSheetCreation'; // Important as your custom mdt is keyed by this.
    public Id jobId;
    //  Changed batch size from 50 to 2.
    private Integer batchSize = 2;
    private Integer metersBatchSize = 2;
    private date routeFillDate;
    private Id   routeScheduleId;
    private Set<Id> rpsIdsCreated = new Set<Id>();
    private Set<String> processingLocations  = new Set<String>();
    private String region; //  aka processing location

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;
    public  Batch_Job_Setting__mdt jobMdt;

    //  Various internal stateful counters
    private Integer     iTotalRecordsSelected = 0,iTotalRpsCreated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0, iTotalRecordsUpdated = 0;

    //  @See https://accel-entertainment.monday.com/boards/1300348967/pulses/1924837832
    public final Static Set<String> COL_TYPES_NO_METER_CREATION = new Set<String>{
            'Additional Fill – RT Only',
            'Regular - 2nd RT',
            'Regular - RT Only' // 9/22/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
    };

    /**
     * @param pRouteFillDate        The Fill Date to filter Route_Schedules by.
     * @param region                The Region (processing location) to general rps records for.
     */
    public clBatchRouteProcessingSheetCreation(Date pRouteFillDate, String region) {
       this.routeFillDate = pRouteFillDate;
       this.region = region;
        this.initLog(region);
        log.Execution_Details__c += '\n * Constructor:\n   route fill date  = '+ pRouteFillDate
                +' \n   region: '+region;
    }

    /**
     * @param pRouteFillDate  The Fill Date to filter Route_Schedules by.
     */
    public clBatchRouteProcessingSheetCreation(Date pRouteFillDate) {
        this.routeFillDate = pRouteFillDate;
        this.initLog();
        log.Execution_Details__c += '\n * Constructor:]\n   route fill date  = '+ pRouteFillDate;
    }

    /**
     * @param pRouteScheduleId  The route schedule id to filter Route_Schedules_By
     */
    public clBatchRouteProcessingSheetCreation(Id pRouteScheduleId,String region) {
        this.routeScheduleId = pRouteScheduleId;
        this.region = region;
        this.initLog(region);
        log.Execution_Details__c += '\n * Constructor:\n   route schedule id  = '+ pRouteScheduleId
                +' \n   region: '+region;
    }

    /**
     * Return Route_Schedule__c sObjects and Route_Schedule_Account__c sObjects with filter criteria passed in
     * constructor.
     *
     * @param bc  Batchable ctx.
     * @return    A QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator ql;

        if(routeFillDate != null) {
            ql = Database.getQueryLocator([
                    SELECT Id, Route_Collection_Date__c,CountRoom__c, Route_Fill_Date__c,(
                            SELECT  Id, Name, Stop_Number__c, Route_Schedule__c, Account__c,
                                    Route_Schedule__r.Processing_Location__c,
                                    Cassette_1_Fill_Level__c,
                                    Cassette_5_Fill_Level__c,
                                    Cassette_20_Fill_level__c,
                                    Cassette_50_Fill_Level__c,
                                    Cassette_100_Fill_Level__c,
                                    Redemption_Type_From_Asset__c,
                                    Redemption_Asset__c,
                                    Collection_Type__c,
                                    Replenishment_Type__c
                            FROM    Route_Schedule_Accounts__r
                    )
                    FROM Route_Schedule__c
                    WHERE Route_Fill_Date__c = :routeFillDate
                    AND   Processing_Location__c = :region
            ]);
            log.Execution_Details__c += '\n * Start method query route schedules with fill date = '+routeFillDate + ' and region = '+region;
        } else if (routeScheduleId != null) {
            ql = Database.getQueryLocator([
                    SELECT Id, Route_Collection_Date__c,CountRoom__c,Route_Fill_Date__c, (
                            SELECT  Id, Name, Stop_Number__c, Route_Schedule__c, Account__c,
                                    Route_Schedule__r.Processing_Location__c,
                                    Cassette_1_Fill_Level__c,
                                    Cassette_5_Fill_Level__c,
                                    Cassette_20_Fill_level__c,
                                    Cassette_50_Fill_Level__c,
                                    Cassette_100_Fill_Level__c,
                                    Redemption_Type_From_Asset__c,
                                    Redemption_Asset__c,
                                    Collection_Type__c,
                                    Replenishment_Type__c
                            FROM    Route_Schedule_Accounts__r
                    )
                    FROM Route_Schedule__c
                    WHERE Id = :routeScheduleId
            ]);
            log.Execution_Details__c += '\n * Start method query route schedules  region = '+region;
        }
        return ql;
    }

    /**
     * Rolls through Route_Schedule__c (and child Route_Schedule_Account__c sObjects) and copies info to
     * Route_Processing_Sheet__c sObjects.
     *
     * @param bc     The Batchable ctx.
     * @param scope  The Route_Schedule__c sObjects retrieved in the start method.
     */
    public void execute(Database.BatchableContext bc, List<Route_Schedule__c> scope ) {

        this.jobId = bc.getJobId();
        log.Initiating_Job_Id__c = this.jobId;
        List<Route_Processing_Sheet__c> routeProcessingSheetsIns = new List<Route_Processing_Sheet__c>();
        this.iTotalRecordsSelected += scope.size();

        for (Route_Schedule__c routeSchedule : scope) {
            Set<Id> allAccountIds = new Set<Id>();
            if(routeSchedule.Route_Schedule_Accounts__r != null ) {
                for(Route_Schedule_Account__c rsa : routeSchedule.Route_Schedule_Accounts__r) {
                    allAccountIds.add(rsa.Account__c);
                    Route_Processing_Sheet__c rps = new Route_Processing_Sheet__c();
                    rps.Account__c = rsa.Account__c;
                    rps.CountRoom__c = routeSchedule.CountRoom__c;
                    rps.Route_Schedule__c = routeSchedule.Id;
                    rps.Stop_Number__c = rsa.Stop_Number__c;
                    rps.Collection_Date__c = routeSchedule.Route_Collection_Date__c;
                    rps.Status__c = 'Not Started';
                    rps.Cassette_5_Note_Count_Outbound__c =rsa.Cassette_5_Fill_Level__c;
                    rps.Cassette_1_Note_Count_Outbound__c = rsa.Cassette_1_Fill_Level__c;
                    rps.Cassette_20_Note_Count_Outbound__c = rsa.Cassette_20_Fill_level__c;
                    rps.Cassette_50_Note_Count_Outbound__c = rsa.Cassette_50_Fill_Level__c;
                    rps.Cassette_100_Note_Count_Outbound__c = rsa.Cassette_100_Fill_Level__c;
                    //  @see https://accel-entertainment.monday.com/boards/1300348967/pulses/1887234837
                    rps.Processing_Location__c = rsa.Route_Schedule__r.Processing_Location__c;
                    processingLocations.add(rps.Processing_Location__c);
                    rps.Fill_Type__c = 'Standard';
                    rps.Redemption_Terminal_Status__c = 'Not Started';
                    rps.Route_Schedule_Account__c = rsa.Id;
                    rps.Route_Fill_Date__c = routeSchedule.Route_Fill_Date__c;
                    rps.Redemption_Asset__c = rsa.Redemption_Asset__c;
                    //rps.Route_Account__c = rsa.Id;
                    rps.Collection_Type__c = rsa.Collection_Type__c;
                    rps.Replenishment_Type__c = rsa.Replenishment_Type__c;
                    this.iTotalRecordsProcessed  ++;
                    routeProcessingSheetsIns.add(rps);
                }
            }
        }
        insert routeProcessingSheetsIns;
        iTotalRpsCreated = routeProcessingSheetsIns.size();
        log.Execution_Details__c += '\n * execute -  inserting '+routeProcessingSheetsIns.size()+ ' route processing sheet records';
        for(Route_Processing_Sheet__c rps : routeProcessingSheetsIns) {
            this.rpsIdsCreated.add(rps.Id);
        }
    }

    /**
     * Fires a Route_Schedule_Change__PE__c Platform Event for usage by any subscribing clients.
     * @param bc  The Batchable ctx.
     */
    public void finish(Database.BatchableContext bc) {
        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Route_Schedule_Change_PE__e changePe    = new Route_Schedule_Change_PE__e();
        List<String> sRpsIds = new List<String>();
        for(Id rpsId : this.rpsIdsCreated) {
            sRpsIds.add(rpsId);
        }
        changePe.Route_Processing_Sheet_Ids__c = String.join(sRpsIds, ',');
        if(this.routeScheduleId!=null) {
            changePe.Route_Schedule_Ids__c = this.routeScheduleId;
        }
        changePe.Operation_Type__c = PlatformEventSvc.DML_ACTION_INSERT;
        //Firing Job to Create Meter Readings......
        changePe.Ui_Message__c = sRpsIds.size() + ' Route Processing Sheets Created Successfully';
        changePe.Status__c = 'Processing';
        changePe.Publishing_Process_Name__c = 'clBatchRouteProcessingSheetCreation';
        changePEs.add(changePe);
        PlatformEventSvc.publishPlatformEvents(changePes);
        log.Execution_Details__c += '\n * finish - fire platform event ';

        if(!Test.isRunningTest()) {
            // filter out those rps that we do not want to create meter readings for!
            // @see https://accel-entertainment.monday.com/boards/1300348967/pulses/1924837832
            Set<Id> rpsIdsForMeterReadings = remove2ndRtFromMeterCreation(this.rpsIdsCreated);
            //log.Execution_Details__c += '\n * finish - remove 2nd rt from meter creation for ids ='+rpsIdsForMeterReadings;
            clBatchMeterReadingsCreation b = new clBatchMeterReadingsCreation(rpsIdsForMeterReadings);
            Id jId = Database.executeBatch(b, metersBatchSize);
            log.Execution_Details__c += '\n * finish - chaining batch job id '+jId+'  clBatchMeterReadingsCreation with  '
                    + ' with parms rpsIds  '+rpsIdsForMeterReadings + ' AND BatchSize = '+metersBatchSize;
            for(Id rpsId : rpsIdsForMeterReadings) {
                log.Execution_Details__c += rpsId +'.';
            }
            log.Execution_Details__c.removeEnd(',');
        }
        this.sendProcessingFillSummaryEmail();
        this.writeFinalLog(log);
    }
    /**
     * Remove 2nd RT types from meter readings creation process.
     *
     * @param rpsIds    A Set of Route_Processing_Sheet__c.Id values that were recently created.
     * @return          A Set of Route_Processing_Sheet__c.Id values to create meters for.
     *
     * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/1924837832
     */
    public Set<Id> remove2ndRtFromMeterCreation( Set<Id> rpsIds) {
        Set<Id> filteredIds = new Set<Id>();
        if(!rpsIds.isEmpty()) {
            Map<Id,Route_Processing_Sheet__c> rpssToProcess = new Map<Id,Route_Processing_Sheet__c>([
                    SELECT Id,Collection_Type__c
                    FROM   Route_Processing_Sheet__c
                    WHERE  Id IN :rpsIds
                    AND    Collection_Type__c NOT IN :COL_TYPES_NO_METER_CREATION
            ]);
            Map<Id,Route_Processing_Sheet__c> rpssFiltered = new Map<Id,Route_Processing_Sheet__c>([
                    SELECT Id,Collection_Type__c
                    FROM   Route_Processing_Sheet__c
                    WHERE  Id IN :rpsIds
                    AND    Collection_Type__c IN :COL_TYPES_NO_METER_CREATION
            ]);
            if(!rpssFiltered.isEmpty()) {
                log.Execution_Details__c += '\n * remove2ndRtFromMeterCreation - Skipping the following rps ids from meters creation: \n';
                for(Id rpsId : rpssFiltered.keySet()) {
                    log.Execution_Details__c += rpsId+',';
                }
                log.Execution_Details__c.removeEnd(',');
            }
            filteredIds = rpssToProcess.keySet();
        }
        return filteredIds;
    }

    public void sendProcessingFillSummaryEmail() {

        Cash_Logistics_Automation_Setting__mdt automationMdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_EMAIL);
        Cash_Logistics_Schedule_Setting__mdt scheduleMdt = (Cash_Logistics_Schedule_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(
                        Cash_Logistics_Schedule_Setting__mdt.getSObjectType(),region);

        if(automationMdt != null && automationMdt.Send_Email__c) {
           // if(processingLocations.contains('Burr Ridge')) {
               if(region != null) {
                   Id jobId = System.enqueueJob(new clQueueableProcessFillSummaryEmail(region));
                   System.debug('--> fire process fill summary queueable job id =' + jobId);
                   log.Execution_Details__c += '\n * finish - sendProccessFillSummary Email  '
                           + ' with parm of region = '+region;

               }
          //  }
        }
    }

    private void initLog() {
        this.initLog(null);
    }
    private void initLog( String region ) {
        this.jobMdt = BatchjobSvc.queryForMetadata(jobName);    //  Query Metadata for params.
        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);
        if(region != null) {
            log.Job_Name__c = log.Job_Name__c + ' - '+region;
        }
        log.Overall_Job_Status__c = 'Processing';
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Batch_Size__c = this.batchSize;
        log.Execution_Details__c = ' ';
        this.log = log;
    }

    private void writeFinalLog(Accel_Application_Error__c log) {

        if (log != null /* && log.Id != null*/) {

            log.Execution_Details__c += '\n * finish - writing log file.';
            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Batch ' + this.jobId + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Total_Records_Updated__c = iTotalRpsCreated;
            log.Execution_Details__c += '* Total Records Selected = '+ iTotalRecordsSelected+ '\n';
            log.Execution_Details__c += '* Total Records Processed = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total Route processing sheets Created = ' + iTotalRpsCreated + '\n';
            log.Execution_Details__c += '* --> All Route Processing Sheets Created <-- ' + iTotalRpsCreated + '\n\n';

            if(this.rpsIdsCreated != null) {
                List<Route_Processing_Sheet__c> rpss = [
                        SELECT Id,Name,Account__r.Name,Processing_Location__c
                        FROM Route_Processing_Sheet__c
                        WHERE Id IN :this.rpsIdsCreated
                ];
                for(Route_Processing_Sheet__c rps : rpss) {
                    log.Execution_Details__c += '*  ' +  rps.Name + ' - Region: '+rps.Processing_Location__c + ' -- Account: '+rps.Account__r.Name + ' \n';
                }
            }
            log.Overall_Job_Status__c  = 'Success';
            insert log;
        }
    }
}