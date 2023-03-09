public class clBatchMeterReadingsCreation implements Database.Batchable<SObject>, Database.Stateful{

    private Set<Id> rpsIds;
    private Set<Id> rsIds = new Set<Id>();
    private Set<Id> meterReadingIds = new Set<Id>();
    private Set<String> processingLocations = new Set<String>();
    private Map<Id,Set<Id>> mRpsId_MeterIds = new Map<Id,Set<Id>>();
    private Set<Route_Processing_Sheet__c> rpsNoMeters = new Set<Route_Processing_Sheet__c>();

    public static String jobName = 'clBatchMetersCreation'; // Important as your custom mdt is keyed by this.
    public Id jobId;
    public  Batch_Job_Setting__mdt jobMdt;
    private Integer batchSize;

    //  Single log file for each nightly run which will be updated throughout the process.
    public Accel_Application_Error__c log;

    //  Various internal stateful counters
    private Integer     iTotalRecordsSelected = 0,iTotalMetersCreated = 0;
    private Integer     iTotalRecordsProcessed = 0,iNumExeCalls = 0;

    public clBatchMeterReadingsCreation(Set<Id> pRpsIds) {
        this.rpsIds = pRpsIds;
        this.initLog();
        log.Execution_Details__c += '\n * Constructor:  rps ids = ';
        if(rpsIds != null) {
            for (Id rpsId : rpsIds) {
                log.Execution_Details__c += rpsId + ',';
            }
            log.Execution_Details__c.removeEnd(',');
        }
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        Database.QueryLocator ql = Database.getQueryLocator([
                SELECT  Id,Account__c,Route_Schedule__c,Processing_Location__c,Name
                FROM    Route_Processing_Sheet__c
                WHERE   Id IN :rpsIds
        ]);
        log.Execution_Details__c += '\n\n * Start method query rps with rpsIds=';
        for(Id rpsId : rpsIds) {
            log.Execution_Details__c += rpsId+',';
        }
        log.Execution_Details__c.removeEnd(',');

        return ql;
    }

    public void execute(Database.BatchableContext bc, List<Route_Processing_Sheet__c> scope ) {

        this.jobId = bc.getJobId();
        log.Initiating_Job_Id__c = this.jobId;
        iTotalRecordsProcessed+= scope.size();
        iTotalRecordsSelected+= scope.size();

        List<Meter_Reading__c> meterReadingsIns = new List<Meter_Reading__c>();

        Map<Id,Id> mRpsId_Account = new Map<Id,Id>();


        for (Route_Processing_Sheet__c rps : scope) {
            mRpsId_Account.put(rps.Id,rps.Account__c);
            rsIds.add(rps.Route_Schedule__c);
            processingLocations.add(rps.Processing_Location__c);
        }
        Set<String> rtDevNames = new Set<String>{'VGT'};
        Map<Id,Asset> accountMachines = AssetSvc.retrieveAccountMachines(new Set<Id>(mRpsId_Account.values()), rtDevNames);

        Map<Id,List<Asset>> mAccountId_Assets = new Map<Id,List<Asset>>();
        for(Asset asset : accountMachines.values()) {
            if(!mAccountId_Assets.containsKey(asset.AccountID)) {
                mAccountId_Assets.put(asset.AccountId,new List<Asset>{asset});
            } else {
                List<Asset> currAccountAssets = mAccountId_Assets.get(asset.AccountId);
                currAccountAssets.add(asset);
            }
        }
        for(Route_Processing_Sheet__c rps : scope) {
            if(!mRpsId_MeterIds.containsKey(rps.Id)) {
                mRpsId_MeterIds.put(rps.Id, new Set<Id>());
            }
            List<Asset> rpsAssets = mAccountId_Assets.get(rps.Account__c);
            this.iTotalRecordsProcessed++;

            if(rpsAssets != null && !rpsAssets.isEmpty()) {
                for (Asset rpsAsset : rpsAssets) {
                    Meter_Reading__c reading = new Meter_Reading__c();
                    reading.Asset__c = rpsAsset.Id;
                    reading.BV_Type__c = rpsAsset.BV_Type__c;
                    reading.Route_Processing_Sheet__c = rps.Id;
                    reading.Reading_Status__c = 'New';
                    meterReadingsIns.add(reading);
                }
            } else {
                rpsNoMeters.add(rps);
                log.Execution_Details__c += '\n * execute -  no assets found for rps: '+rps.Name;
            }
        }
        insert meterReadingsIns;

        iTotalMetersCreated += meterReadingsIns.size();
        for(Meter_Reading__c meterReading : meterReadingsIns) {
            this.meterReadingIds.add(meterReading.Id);
            Set<Id> rpsMeterIds = mRpsId_MeterIds.get(meterReading.Route_Processing_Sheet__c);
            if(rpsMeterIds != null) {
                rpsMeterIds.add(meterReading.Id);
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        log.Execution_Details__c += '* finish - Batch jobId: ' + this.jobId + '\n';
        log.Execution_Details__c += '* finish - Meteres created for processing locations ' + this.processingLocations + '\n';
        log.Execution_Details__c += '\n* finish - The following Meter Ids were inserted: ';
        if(!rpsNoMeters.isEmpty()) {
            this.sendNoMetersExistEmail(rpsNoMeters);
        }
        if(!this.meterReadingIds.isEmpty()) {
            if(!mRpsId_MeterIds.isEmpty()) {
               for(Id rpsId : mRpsId_MeterIds.keySet()) {
                   log.Execution_Details__c += '\n=== RPSID ='+rpsId;
                   Set<Id> meterIds = mRpsId_MeterIds.get(rpsId);
                   if(meterIds != null) {
                       log.Execution_Details__c += '.. RPSMeterIds=';
                       for(Id meterId : meterIds) {
                           log.Execution_Details__c += meterId +',';
                       }
                       log.Execution_Details__c.removeEnd(',');
                   }
               }
                log.Execution_Details__c +='\n';
            }
//            for (Id meterId : this.meterReadingIds) {
//                log.Execution_Details__c += meterId +',';
//            }
//            log.Execution_Details__c.removeEnd(',');
        }
        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Route_Schedule_Change_PE__e changePe    = new Route_Schedule_Change_PE__e();
        if(this.rsIds!=null && !this.rsIds.isEmpty()) {
            List<String> sRsIds = new List<String>();
            for(Id rsId : rsIds) {
                sRsIds.add(rsId);
            }
            changePe.Route_Schedule_Ids__c = String.join(sRsIds,',');
        }
        changePe.Operation_Type__c = PlatformEventSvc.DML_ACTION_INSERT;
        changePe.Ui_Message__c = rpsIds.size() + ' RPS successfully created with '+ meterReadingIds.size() + ' Meter readings!. Job is complete.';
        changePe.Status__c = 'Complete';
        changePe.Publishing_Process_Name__c = 'clBatchMeterReadingsCreation';
        changePEs.add(changePe);
        log.Execution_Details__c += '* finish - firing platform event\n';
        PlatformEventSvc.publishPlatformEvents(changePes);
        this.writeFinalLog(this.log);

    }

    private void initLog() {
        this.jobMdt = BatchjobSvc.queryForMetadata(jobName);    //  Query Metadata for params.
        Accel_Application_Error__c log = BatchjobSvc.buildLog(jobName);

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

            log.Execution_Details__c += '* finish - writing log file.\n';
            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Total_Records_Updated__c = iTotalMetersCreated;
            log.Execution_Details__c += '* Total Records Selected = '+ iTotalRecordsSelected+ '\n';
            log.Execution_Details__c += '* Total Records Processed = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total Meters Created = ' + iTotalMetersCreated + '\n';
            log.Overall_Job_Status__c  = 'Success';
            insert log;
        }
    }

    public void sendNoMetersExistEmail(Set<Route_Processing_Sheet__c> rpsNoMeters) {
        String subject = 'Cash Logistics Warning  xx NO METERS CREATED XX';
        String body = '';
        body += 'clBatchMeterReadingsCreation.. jobId= '+this.jobId + '<br/>';
        body += 'No Meters Where Created For the Following RPS Sheets:<br/><br/>';
        for(Route_Processing_Sheet__c rps : rpsNoMeters) {
            body += 'RPS Name: ' + rps.Name  + ' rpsId='+rps.Id +'<br/>';
        }
        String[] emailAddys = new String[]{'rick@chicagosalesforceconsulting.com'};
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}