/**
 * Simply creates Route_Schedule__c and Route_Schedule_Account__c (s) from Route__c and Route_Account__c
 * based on the next cycle number passed. If
 */
public class clBatchRouteScheduleCreation implements Database.Batchable<SObject>, Database.Stateful {

    public static String jobName = 'clBatchRouteScheduleCreation'; // Important as your custom mdt is keyed by this.
    public Id jobId;
    private Integer batchSize;
    private Integer numTimesExecuteCalled = 0;

    //  This is primarily used if we want to limit real time testing. (Gov limit is 50 mil)
    public static Integer RECORDS_TO_PROCESS_LIMIT = 49000000;

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;

    //  Custom metadata used. This will normally have a developername of the name of this executing class.
    public  Batch_Job_Setting__mdt jobMdt;
    public  Cash_Logistics_Setting__mdt clSchMdt;
    public  final static String CL_SCH_MDT_DEV_NAME = 'Scheduler';
    public  String region; //ie processing location;

    //  Used for Unit Testing.
    @TestVisible private static Boolean FORCE_PARTIAL_DML_EXCEPTION = false;

    //  Various internal stateful counters
    private Integer     iTotalRecordsSelected = 0,iTotalRsCreated = 0,iTotalRsaCreated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0;

    private Integer nextCycle;
    private Boolean chainRouteProcessingSheets = false;
    private Date routeCollectionDate;
    private Date routeFillDate;
    private List<Route_Schedule__c> routeSchedulesCreated = new List<Route_Schedule__c>();

    /**
     * @param pNextCycle  The Route__c.Cycle_Number__c value.
     */
    public clBatchRouteScheduleCreation(Integer pNextCycle) {
        this.nextCycle = pNextCycle;
        this.batchSize = 50;
        this.initLog();
        log.Execution_Details__c += '\n * Constructor:  cycle number = '+ pNextCycle;
    }


    public clBatchRouteScheduleCreation(Integer pNextCycle, String pRegion) {
        this.nextCycle = pNextCycle;
        this.region = pRegion;
        this.batchSize = 50;
        System.debug('---> rs sch batcd exe region used to pass to batch constr:'+this.region);
        this.initLog(this.region);
        log.Execution_Details__c += '\n * Constructor:  cycle number  = '+ pNextCycle
                +' \nregion: '+pRegion;
    }

    /**
    /**
     * @param pNextCycle                    The Route__c.Cycle_Number__c value.
     * @param pChainRouteProcessingSheets   If TRUE, chain batch job to create RPS Records.
     */
    public clBatchRouteScheduleCreation(Integer pNextCycle, Boolean pChainRouteProcessingSheets) {
        this.nextCycle = pNextCycle;
        this.chainRouteProcessingSheets = pChainRouteProcessingSheets;
        this.initLog();
        log.Execution_Details__c += '\n * Constructor:\n cycle number  = '+ pNextCycle
                + '\nchain rps sheets='+pChainRouteProcessingSheets;
    }

   /**
    * @param pNextCycle                    The Route__c.Cycle_Number__c value.
    * @param pChainRouteProcessingSheets   If TRUE, chain batch job to create RPS Records.
    */
    public clBatchRouteScheduleCreation(Integer pNextCycle, Boolean pChainRouteProcessingSheets, Integer pbatchSize) {
        this.nextCycle = pNextCycle;
        this.chainRouteProcessingSheets = pChainRouteProcessingSheets;
        this.batchSize = pbatchSize;
        this.initLog();
        log.Execution_Details__c += '\n * Constructor:\n cycle number  = '+ pNextCycle
                + '\n chain rps sheets='+pChainRouteProcessingSheets + '\n batch size ='+pbatchSize;
    }
    /**
     * @param pNextCycle                    The Cmd next cycle number.
     * @param pChainRouteProcessingSheets   Chain the creation of rps and meters.
     * @param pbatchSize                    The batch size.
     * @param pRouteCollectionDate          The schedule collection date.
     */
    public clBatchRouteScheduleCreation(Integer pNextCycle, Boolean pChainRouteProcessingSheets,
                                        Integer pbatchSize, Date pRouteCollectionDate, Date pRouteFillDate) {
        this.nextCycle = pNextCycle;
        this.chainRouteProcessingSheets = pChainRouteProcessingSheets;
        this.batchSize = pbatchSize;
        this.routeCollectionDate = pRouteCollectionDate;
        this.routeFillDate = pRouteFillDate;
        this.initLog();
        log.Execution_Details__c += '\n * Constructor:\n cycle number  = '+ pNextCycle
                + '\n chain rps sheets='+pChainRouteProcessingSheets + ' batch size ='+pbatchSize
                + '\n collection date='+pRouteCollectionDate +'\n fill date='+pRouteFillDate;
    }

    /**
     * Give me all route records that match passed Route__c.Cycle_Number__c value.
     *
     * @param bc BC
     * @return   A QueryLocator
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {

        this.clSchMdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,CL_SCH_MDT_DEV_NAME);

        Database.QueryLocator ql;
        System.debug('---> rs sch batch start region used:'+this.region);
        if(this.region == null) {
            ql = Database.getQueryLocator([
                    SELECT Id,Name,Cycle_Number__c,Vehicle__c,Geolocation__Longitude__s,
                            Geolocation__Latitude__s,Processing_Location__c,
                            Collection_Cycle_Number__c, Next_Collection_Date__c,
                            Next_Fill_Date__c, (
                            SELECT Id,Name,Stop_Number__c,Route__c,Account__c,
                                    X1_Fill_Level__c,
                                    X5_Fill_Level__c,
                                    X20_Fill_Level__c,
                                    X50_Fill_Level__c,
                                    X100_Fill_Level__c,
                                    Collection_Type__c,
                                    Replenishment_Type__c
                            FROM Route_Accounts__r
                            ORDER BY Account__r.Name ASC
                    )
                    FROM Route__c
                    WHERE Cycle_Number__c = :nextCycle
            ]);
            log.Execution_Details__c += '\n\n * Start method query routes with cycle number='+nextCycle;
        } else  {
            String tmpRegion = this.region;
            ql = Database.getQueryLocator([
                    SELECT Id,Name,Cycle_Number__c,Vehicle__c,Geolocation__Longitude__s,
                            Geolocation__Latitude__s,Processing_Location__c,
                            Collection_Cycle_Number__c, Next_Collection_Date__c,
                            Next_Fill_Date__c, (
                            SELECT Id,Name,Stop_Number__c,Route__c,Account__c,
                                    X1_Fill_Level__c,
                                    X5_Fill_Level__c,
                                    X20_Fill_Level__c,
                                    X50_Fill_Level__c,
                                    X100_Fill_Level__c,
                                    Collection_Type__c,
                                    Replenishment_Type__c
                            FROM Route_Accounts__r
                            ORDER BY Account__r.Name ASC
                    )
                    FROM Route__c
                    WHERE Cycle_Number__c = :nextCycle
                    AND   Processing_Location__c = :tmpRegion
            ]);
            log.Execution_Details__c += '\n * Start method query routes with cycle number='+nextCycle
                    +' and region = '+tmpRegion;
        }
        return ql;
    }

    /**
     * Roll through Route__c records. create Route_Schedule__c records and Route_Schedule_Account__c records.
     *
     * @param bc     The DB Ctx.
     * @param scope  The Route__c recourd in scope.
     */
    public void execute(Database.BatchableContext bc, List<Route__c> scope) {

        this.jobId = bc.getJobId();

        log.Initiating_Job_Id__c = this.jobId;
        this.numTimesExecuteCalled ++;
        List<Route_Schedule__c> routeSchedulesIns = new List<Route_Schedule__c>();
        List<Route_Schedule_Account__c> rsasIns = new List<Route_Schedule_Account__c>();

        Map<Id, List<Route_Account__c>> mRouteId_Accounts = new Map<Id, List<Route_Account__c>>();
        Set<Id> allAccountIds = new Set<Id>();
        iTotalRecordsProcessed+= scope.size();
        iTotalRecordsSelected+= scope.size();
        for (Route__c route : scope) {
            Route_Schedule__c routeSchedule = new Route_Schedule__c();
            routeSchedule.Name = route.Name;
            routeSchedule.Vehicle__c = route.Vehicle__c;
            routeSchedule.Route__c = route.Id;
            // @todo --> obsolete routeSchedule.Route_Collection_Date__c = this.routeCollectionDate;
            if(this.routeCollectionDate != null) {
                routeSchedule.Route_Collection_Date__c = this.routeCollectionDate;
            } else {
                routeSchedule.Route_Collection_Date__c = route.Next_Collection_Date__c;
            }
            routeSchedule.Processing_Location__c = route.Processing_Location__c;
            if(this.routeFillDate != null) {
                routeSchedule.Route_Fill_Date__c = this.routeFillDate;
            } else {
                routeSchedule.Route_Fill_Date__c = route.Next_Fill_Date__c;
            }
            /**
             *  If there is no stop number on Route_Account__c lets assume we override and use an auto incremented number
             *  based on the order by query from the start method on Account.Name ASC
             */
            if (route.Route_Accounts__r != null) {
                Integer iStopNumber = 1;
                for (Route_Account__c ra : route.Route_Accounts__r) {
                    allAccountIds.add(ra.Id);
                    ra.Stop_Number__c = (ra.Stop_Number__c != null && ra.Stop_Number__c != 0) ? ra.Stop_Number__c : iStopNumber;
                    if (!mRouteId_Accounts.containsKey(ra.Route__c)) {
                        mRouteId_Accounts.put(ra.Route__c, new List<Route_Account__c>{ra});
                    } else {
                        List<Route_Account__c> ras = mRouteId_Accounts.get(ra.Route__c);
                        ras.add(ra);
                    }
                    iStopNumber++;
                }
            }
            routeSchedulesIns.add(routeSchedule);
        }


        log.Execution_Details__c += '\n * execute -  inserting '+routeSchedulesIns.size()+ ' route schedule records';
        insert routeSchedulesIns;

        for(Route_Schedule__c routeSchedule : routeSchedulesIns) {
            this.routeSchedulesCreated.add(routeSchedule);
            this.iTotalRsCreated++;
        }


        for (Route_Schedule__c rs : routeSchedulesIns) {
            List<Route_Account__c> ras = mRouteId_Accounts.get(rs.Route__c);
            if (ras != null) {
                for (Route_Account__c ra : ras) {
                    Route_Schedule_Account__c rsa = new Route_Schedule_Account__c();
                    rsa.Route_Schedule__c = rs.Id;
                    rsa.Account__c = ra.Account__c;
                    rsa.Stop_Number__c = ra.Stop_Number__c;
                    rsa.Cassette_1_Fill_Level__c    = ra.X1_Fill_Level__c;
                    rsa.Cassette_5_Fill_Level__c    = ra.X5_Fill_Level__c;
                    rsa.Cassette_20_Fill_Level__c   = ra.X20_Fill_Level__c;
                    rsa.Cassette_50_Fill_Level__c   = ra.X50_Fill_Level__c;
                    rsa.Cassette_100_Fill_Level__c  = ra.X100_Fill_Level__c;
                    rsa.Collection_Type__c          = ra.Collection_Type__c;
                    rsa.Replenishment_Type__c = ra.Replenishment_Type__c;

                    rsasIns.add(rsa);
                }
            }
        }

        log.Execution_Details__c += '\n * execute -  tagging redemption assets ';
        clRouteSvc.tagRedemptionAssets(rsasIns);

        if (!rsasIns.isEmpty()) {
            insert rsasIns;
            iTotalRsaCreated += rsasIns.size();
            log.Execution_Details__c += '\n * execute -  inserting  '+ rsasIns.size() + ' route schedule accounts.';
        }
    }

    /**
     * @param bc  DB
     */
    public void finish(Database.BatchableContext bc) {

        if(this.chainRouteProcessingSheets) {
            clBatchRouteProcessingSheetCreation b;
            if(this.region != null) {
                log.Execution_Details__c += '\n * finish - chaining batch job clBatchRouteProcessingSheetCreation '
                + ' with parm  of date = '+Date.today().addDays(1) + ' and region ='+this.region;
               b  = new clBatchRouteProcessingSheetCreation(Date.today().addDays(1),this.region);
            } else {
               b  = new clBatchRouteProcessingSheetCreation(Date.today().addDays(1));
                log.Execution_Details__c += '\n * finish - chaining batch job clBatchRouteProcessingSheetCreation '
                        + ' with parm  of date = '+Date.today().addDays(1);
            }
            Id chainedJobId = Database.executeBatch(b,50);
            log.Execution_Details__c += '\n * finish - chained batch job id: '+chainedJobId;
        } else {
            if(this.routeSchedulesCreated != null && !this.routeSchedulesCreated.isEmpty()) {
                this.fireSuccessPlatformEvent();
                log.Execution_Details__c += '\n * finish - firing success platform event.';
            } else {
                this.fireFailurePlatformEvent();
                log.Execution_Details__c += '\n * finish - firing failure platform event.';
            }
        }
        this.writeFinalLog(log);
    }

    private void writeFinalLog(Accel_Application_Error__c log) {

        if (log != null /* && log.Id != null*/) {

            log.Execution_Details__c += '\n * finish - writing log file.';
            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of Batch ' + this.jobId + '\n';
            log.Execution_Details__c += '* Cycle # used: ' + this.nextCycle + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Total_Records_Updated__c = iTotalRsaCreated + iTotalRsaCreated;
            log.Execution_Details__c += '* Total Records Selected = '+ iTotalRecordsSelected+ '\n';
            log.Execution_Details__c += '* Total Records Processed = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total RouteSchedules Created = ' + iTotalRsCreated + '\n';
            log.Execution_Details__c += '* Total RouteScheduleAccounts Created = ' + iTotalRsaCreated + '\n\n';
            log.Execution_Details__c += '* --> All Route Schedules Created <-- ' + iTotalRsCreated + '\n\n';

            List<Route_Schedule__c> rss = [
                    SELECT Id,Name,Total_Accounts__c,Route_Collection_Date__c,Route_Fill_Date__c
                    FROM Route_Schedule__c
                    WHERE Id IN :this.routeSchedulesCreated
            ];
            for(Route_Schedule__c rs : rss) {
                log.Execution_Details__c += '*  ' + rs.Name + ' - Num Accounts: '+rs.Total_Accounts__c + ' '
                        +'- Route Fill Date: '+ rs.Route_Fill_Date__c + ' - Route Collection Date: '+rs.Route_Collection_Date__c;
            }

            log.Overall_Job_Status__c  = 'Success';
            insert log;
        }
    }

    @TestVisible
    private void fireSuccessPlatformEvent() {
        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Route_Schedule_Change_PE__e changePe = new Route_Schedule_Change_PE__e();
        List<String> sRsIds = new List<String>();
        String uiMessage = 'Route Schedules created for ';
        for(Route_Schedule__c rs : this.routeSchedulesCreated) {
            sRsIds.add(rs.Id);
            uiMessage += rs.Name + ',';
        }
        uiMessage.removeEnd(',');
        uiMessage += ' Successfully!';
        changePe.Route_Schedule_Ids__c = String.join(sRsIds,',');
        changePe.Operation_Type__c = PlatformEventSvc.DML_ACTION_INSERT;
        changePe.Ui_Message__c = uiMessage;
        changePe.Status__c = 'ScheduleCreationComplete';
        changePe.Publishing_Process_Name__c = 'clBatchRouteScheduleCreation';
        changePEs.add(changePe);
        PlatformEventSvc.publishPlatformEvents(changePes);
    }

    @TestVisible
    private void fireFailurePlatformEvent() {
        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Route_Schedule_Change_PE__e changePe = new Route_Schedule_Change_PE__e();
        String uiMessage = 'Unable to create route schedules for cycle number '+nextCycle+'. No Routes Found.';
        uiMessage += ' Num times execute called: '+this.numTimesExecuteCalled;
        changePe.Operation_Type__c = PlatformEventSvc.DML_ACTION_INSERT;
        changePe.Ui_Message__c = uiMessage;
        changePe.Publishing_Process_Name__c = 'clBatchRouteScheduleCreation';
        changePe.Status__c = 'ScheduleCreationFailed';
        changePEs.add(changePe);
        PlatformEventSvc.publishPlatformEvents(changePes);
    }

    private void initLog() {
        this.initLog(null);
    }
    private void initLog(String region ) {
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
}