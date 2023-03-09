/**
 * Note 100% sure of the business function here. I think it's due to people missing data uploads?
 */
public class clAdminOnlyDailyUploadMissController {

    public static final String      MAP_KEY_SYNC_RESULTS            = 'SYNC_RESULTS';
    public static final String      MAP_KEY_RS_BATCH_JOB_ID         = 'RS_BATCH_JOB_ID';
    public static final String      MAP_KEY_RPS_BATCH_JOB_ID        = 'RPS_BATCH_JOB_ID';
    public static final String      MAP_KEY_APEX_JOBS               = 'APEX_JOBS';
    public static final String      MAP_KEY_DATA_TOTALS             = 'DATA_TOTALS';
    public static final String      MAP_KEY_METERS_TO_MOD_TOTALS    = 'METERS_TO_MOD_TOTALS';
    public static final String      MAP_KEY_REGIONS_AFFECTED        = 'REGIONS_AFFECTED';
    public static final String      MAP_KEY_MAX_METER_CREATED_DATE  = 'MAX_METER_CREATED_DATE';
    public static final String      MAP_KEY_LATEST_ROUTE_SCHEDULE   = 'LATEST_ROUTE_SCHEDULE';
    public static final String      ERROR_MSG_INVALID_PARAMS        = 'Invalid params';
    public static final String      ERROR_SEVERITY                  = 'error';
    public static final String      SUCCESS_SEVERITY                = 'success';
    public static       Integer     DEFAULT_BATCH_SIZE              = 2;
    public static final Date        DEFAULT_ROUTE_FILL_DATE         = Date.today();

    /**
     * Search for meters to delete.
     *
     * @param meterCreatedDate                              The Meter created date.
     * @param region                                        The Processing Location aka Region.
     * @param nbrOfMinutesToAddToMeterCreatedDate           The # of minutes to add to Meter_Reading__c.CreatedDate.
     * @param nbrOfMinutesToSubtractFromMeterCreatedDate    The # of minutes to subtract from Meter_Reading__c.CreatedDate.
     * @return                                              A ResponseDto object with found meter totals in the values map.
     *
     * @see clAdminOnlyDailyUploadMissController.retrieveMetersToModTotals
     */
    @AuraEnabled
    public static ResponseDto searchForMetersToModify(  Datetime meterCreatedDate,
                                                        String region,
                                                        Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                        Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += '--> return from call of searchForMetersToModify.. passed params:meterCreatedDate..'
                +meterCreatedDate+'..region:'+region;

        ResponseDto dtoMeters = retrieveMetersToModTotals(meterCreatedDate,region,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dto.values.put(MAP_KEY_METERS_TO_MOD_TOTALS,dtoMeters.values.get(MAP_KEY_METERS_TO_MOD_TOTALS));
        dto.values.put(MAP_KEY_REGIONS_AFFECTED,retrieveRegionsAffected(meterCreatedDate,region,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate));

        dto.isSuccess = dtoMeters.isSuccess;
        dto.message = dtoMeters.message;
        dto.severity = dtoMeters.severity;
        return dto;
    }

    /**
     * Fire the route schedule creation batch job.
     *
     * @param processingLocation The region to create records for.
     * @param iNextCycle         The next cycle # stored in the custom mdt.
     * @param meterCreatedDate   The meter created datetime to delete records for.
     *
     * @return                   A Response Dto containing totals / result information.
     */
    @AuraEnabled
    public static ResponseDto fireRsJob(    String processingLocation,
                                            Integer iNextCycle,
                                            Datetime meterCreatedDate,
                                            Integer nbrOfMinutesToAddToMeterCreatedDate,
                                            Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {
        ResponseDto dto = new ResponseDto();

        if(iNextCycle==null || String.isBlank(processingLocation) || meterCreatedDate == null){
            dto.message = ERROR_MSG_INVALID_PARAMS+'.. iNextCycle:'+iNextCycle+'...processingLocation:'+processingLocation;
            dto.message +=' .. meterCreatedDate:'+meterCreatedDate;
            dto.severity = ERROR_SEVERITY;
            return dto;
        } else {
            dto.technicalMsg += 'run with params.. iNextCycle:'+iNextCycle+'...processingLocation:'+processingLocation;
            dto.technicalMsg += '..meterCreatedDate:'+meterCreatedDate;
        }
        List<SyncResult> syncResults = runDeletes(meterCreatedDate,processingLocation,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dto.values.put(MAP_KEY_SYNC_RESULTS,syncResults);

        clBatchRouteScheduleCreation bRs = new clBatchRouteScheduleCreation(iNextCycle,processingLocation);
        Id batchRsId = Database.executeBatch(bRs,DEFAULT_BATCH_SIZE);
        syncResults.add(new SyncResult('Fired Route Schedule Creation batch Job '+batchRsId,iNextCycle,processingLocation));

        dto.values.put(MAP_KEY_RS_BATCH_JOB_ID,batchRsId);

        dto.message = 'RS, RPS, and Meters for '+processingLocation+' deleted and Route Schedule Creation Batch Job '+batchRsId+' fired. ';
        dto.severity = SUCCESS_SEVERITY;
        dto.isSuccess = true;
//        dto.message = 'no deletes execution';
//        dto.severity = ERROR_SEVERITY;
//        dto.isSuccess = false;
        return dto;
    }

    /**
     * Fire the Route_Processing_Sheet__c creation job (which chains Meter_Reading__c creation from it's finish method.
     *
     * @param processingLocation    The region to create RPS and Meters for.
     * @return                      A ResponseDto containing a list of SyncResult objects. and ui messages.
     */
    @AuraEnabled
    public static ResponseDto fireRpsJob(String processingLocation) {
        ResponseDto dto = new ResponseDto();

        if(String.isBlank(processingLocation)){
            dto.message = ERROR_MSG_INVALID_PARAMS+'.. processingLocation:'+processingLocation;
            dto.severity = ERROR_SEVERITY;
            return dto;
        } else {
            dto.technicalMsg += 'run with params.. processingLocation:'+processingLocation;
        }

        clBatchRouteProcessingSheetCreation bRps = new clBatchRouteProcessingSheetCreation(DEFAULT_ROUTE_FILL_DATE,processingLocation);
        Id batchRpsId = Database.executeBatch(bRps,DEFAULT_BATCH_SIZE);

        dto.values.put(MAP_KEY_RPS_BATCH_JOB_ID,batchRpsId);

        dto.message = 'Fired Route Processing Sheet Creation Job  '+batchRpsId+'. ';
        List<SyncResult> syncResults = new List<SyncResult>();
        syncResults.add(new SyncResult(dto.message,processingLocation));
        dto.values.put(MAP_KEY_SYNC_RESULTS,syncResults);

        dto.severity = SUCCESS_SEVERITY;
        dto.isSuccess = true;
        return dto;
    }

    /**
     * Deletes meters / RPS Records / and Route Schedule Records.
     *
     * @param meterCreatedDate  The created date of the meters to find to delete.
     * @return                  A List of SyncResults objects for UI Display.
     */
    public static List<SyncResult> runDeletes(  Datetime meterCreatedDate,
                                                String region,
                                                Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                Integer nbrOfMinutesToSubtractFromMeterCreatedDate){

        List<SyncResult> syncResults = new List<SyncResult>();

        Datetime startDt = meterCreatedDate.addMinutes(-nbrOfMinutesToSubtractFromMeterCreatedDate);
        Datetime endDt = meterCreatedDate.addMinutes(nbrOfMinutesToAddToMeterCreatedDate);

        Map<Id,Meter_Reading__c> mMeters = new Map<Id,Meter_Reading__c>();
        Set<Id> rpsIdsToDel = new Set<Id>();
        Set<Id> rsIdsToDel = new Set<Id>();
        List<Route_Processing_Sheet__c> rpsToDel = new List<Route_Processing_Sheet__c>();
        List<Route_Schedule__c> rssToDel = new List<Route_Schedule__c>();

        //  1. Find Meters
        mMeters =  new Map<Id,Meter_Reading__c>([
                SELECT Id,Route_Processing_Sheet__c
                FROM   Meter_Reading__c
                WHERE  ( CreatedDate >= :startDt AND createdDate <= :endDt )
                OR     ( Route_Processing_Sheet__r.Processing_Location__c = : region AND CreatedDate = TODAY )
        ]);

        if(!mMeters.isEmpty()) {
            syncResults.add(new SyncResult(mMeters.values(),meterCreatedDate,region));
            for(Meter_Reading__c mr : mMeters.values()) {
                rpsIdsToDel.add(mr.Route_Processing_Sheet__c);
            }
            //delete mMeters.values();
        } else {
            syncResults.add(new SyncResult('No Meters found to delete',meterCreatedDate ,region));
        }
        //  2. Find RPS records.
        if(!rpsIdsToDel.isEmpty()) {
            rsIdsToDel = new Set<Id>();
            rpsToDel = [
                    SELECT Id,Route_Schedule__c
                    FROM   Route_Processing_Sheet__c
                    WHERE  Id IN :rpsIdsToDel
                    OR (Processing_Location__c = :region AND CreatedDate = TODAY)
            ];
            if (!rpsToDel.isEmpty()) {
                syncResults.add(new SyncResult(rpsToDel, meterCreatedDate,region));
                for(Route_Processing_Sheet__c rps : rpsToDel) {
                    rsIdsToDel.add(rps.Route_Schedule__c);
                }
               //delete rpsToDel;
            } else {
                syncResults.add(new SyncResult('No Route Processing Sheets found to delete', meterCreatedDate,region));
            }
            // Find RS Records
             rssToDel = [
                    SELECT Id
                    FROM   Route_Schedule__c
                    WHERE  Id IN :rsIdsToDel
                    OR     ( Processing_Location__c = :region AND CreatedDate = TODAY )
            ];
            if(!rssToDel.isEmpty()) {
                //delete rss;
                syncResults.add(new SyncResult(rssToDel, meterCreatedDate,region));
            } else {
                syncResults.add(new SyncResult('No Route Schedules found to delete', meterCreatedDate,region));
            }
            Boolean anyRecordsDeleted = false;
            try {
                if(!mMeters.isEmpty()) {
                    delete mMeters.values();
                    anyRecordsDeleted = true;
                }
                if(!rpsToDel.isEmpty()) {
                    delete rpsToDel;
                    anyRecordsDeleted = true;
                }
                if(!rssToDel.isEmpty()) {
                    delete rssToDel;
                    anyRecordsDeleted = true;
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
            if(!anyRecordsDeleted) {
                syncResults.add(new SyncResult('No Records at all found to delete', meterCreatedDate, region));
            }
        }
        return syncResults;
    }

    /**
     * Find the current status of the async batch meters job.
     *
     * @param apexClassName     The apex class name for the meters batch job.
     * @param jobStatuses       The job statuses to search for.
     *
     * @return                  A ResponseDto containing a list of job wrappers with job status info.
     */
    @AuraEnabled
    public static ResponseDto retrieveBatchMeterJobInfo(String apexClassName,List<String> jobStatuses) {

        // @todo this is iffy!
        DateTime createdDate = System.now().addSeconds(-120);
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' params.. apexClassName='+apexClassName + '..job statuses='+jobStatuses
        + '...createdDAte='+createdDate;

        List<AsyncApexJob> jobs = retrieveMeterJobInfo(jobStatuses,apexClassName,createdDate);
        if(Test.isRunningTest()) {
            jobs = (List<AsyncApexJob>)JSON.deserialize(unitTestJobsJson,List<AsyncApexJob>.class);
        }
        System.debug('jobs json='+JSON.serialize(jobs));
        List<JobWrapper> jobWrappers = buildJobWrappers(jobs);
        dto.isSuccess = !jobWrappers.isEmpty();
        dto.values.put(MAP_KEY_APEX_JOBS,jobWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveScheduledJobInfo(List<String> apexClassNames,List<String> jobStatuses,
                                                       List<Id> jobIds ) {
        ResponseDto dto = new ResponseDto();

        List<AsyncApexJob> jobs = retrieveJobInfo(jobStatuses,apexClassNames,jobIds);
        if(Test.isRunningTest()) {
            jobs = (List<AsyncApexJob>)JSON.deserialize(unitTestJobsJson,List<AsyncApexJob>.class);
        }
        System.debug('jobs json='+JSON.serialize(jobs));
        List<JobWrapper> jobWrappers = buildJobWrappers(jobs);
        dto.isSuccess = !jobWrappers.isEmpty();
        dto.values.put(MAP_KEY_APEX_JOBS,jobWrappers);

        return dto;
    }

    /**
     * Find the max meter created date/time.
     *
     * @return A ResponseDto with a datetime value.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveLatestMeterRecordsTotal() {
        ResponseDto dto = new ResponseDto();
        List<Meter_Reading__c> meters = [
                SELECT      CreatedDate
                FROM        Meter_Reading__c
                ORDER BY    CreatedDate DESC
                LIMIT 1
        ];
        Datetime maxMeterCreatedDate;
        if(!meters.isEmpty()) {
            maxMeterCreatedDate = meters[0].CreatedDate;
        }
        dto.isSuccess = !meters.isEmpty();
        dto.values.put(MAP_KEY_MAX_METER_CREATED_DATE,maxMeterCreatedDate);
        return dto;
    }


    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveLatestRouteSchedule() {
        ResponseDto dto = new ResponseDto();

        Route_Schedule__c latestRouteSchedule;
        List<Route_Schedule__c> routeSchedules = [
                SELECT      Id,CreatedDate,Processing_Location__c
                FROM        Route_Schedule__c
                ORDER BY    CreatedDate DESC
                LIMIT 1
        ];

        if(!routeSchedules.isEmpty()) {
            latestRouteSchedule = routeSchedules[0];
        }
        dto.isSuccess = !routeSchedules.isEmpty();
        dto.values.put(MAP_KEY_LATEST_ROUTE_SCHEDULE,latestRouteSchedule);
        return dto;
    }

    /**
     * Find total meter, rps, and rs data based on meter created date.
     *
     * @param meterCreatedDate                              The Meter created date.
     * @param region                                        The Processing Location aka Region.
     * @param nbrOfMinutesToAddToMeterCreatedDate           The # of minutes to add to Meter_Reading__c.CreatedDate.
     * @param nbrOfMinutesToSubtractFromMeterCreatedDate    The # of minutes to subtract from Meter_Reading__c.CreatedDate.
     *
     * @return                  A Response dto with meters to modify totals in the values map, otherwise
     *                          Warnings messages if none are found.
     */
    @AuraEnabled
    public static ResponseDto retrieveMetersToModTotals(    Datetime meterCreatedDate,
                                                            String  region,
                                                            Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                            Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {

        ResponseDto dto = new ResponseDto();
        DataTotals dataTotals = new DataTotals();

        dataTotals.numMeters = retrieveNumMeters(meterCreatedDate,region,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dataTotals.numRPS = retrieveNumRouteProcessingSheets(meterCreatedDate,region,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dataTotals.numRS = retrieveNumRouteSchedules(meterCreatedDate,region,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dto.isSuccess = dataTotals.numMeters > 0;
        dto.values.put(MAP_KEY_METERS_TO_MOD_TOTALS,dataTotals);

        if(!dto.isSuccess) {
            dto.severity = 'warning';
            dto.message += 'Could not find any meters created  ';
            dto.message += meterCreatedDate.format() +'.';
            dto.message += ' Please select a new meter created time.';

            ResponseDto dtoLatestMeter = retrieveLatestMeterRecordsTotal();
            if(dtoLatestMeter.isSuccess) {
                Datetime maxDt = (Datetime)dtoLatestMeter.values.get(MAP_KEY_MAX_METER_CREATED_DATE);
                if(maxDt != null) {
                    dto.message += '  The Latest meter created time is '+maxDt.format();
                }
            }
        }
        return dto;
    }

    /**
     * @param processingLocation The region to process.
     * @return
     */
    @AuraEnabled
    public static ResponseDto retrieveDataCreationTotals(   String processingLocation,
                                                            Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                            Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {
        ResponseDto dto = new ResponseDto();
        DataTotals dataTotals = new DataTotals();
        dataTotals.numRS = retrieveNumRouteSchedules(null,processingLocation,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dataTotals.numRPS = retrieveNumRouteProcessingSheets(null,processingLocation,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dataTotals.numMeters = retrieveNumMeters(null,processingLocation,nbrOfMinutesToAddToMeterCreatedDate,nbrOfMinutesToSubtractFromMeterCreatedDate);
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_DATA_TOTALS,dataTotals);
        return dto;
    }

    private static List<JobWrapper> buildJobWrappers(List<AsyncApexJob> apexJobs) {
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for(AsyncApexJob apexJob : apexJobs) {
            jobWrappers.add(new JobWrapper(apexJob));
        }
        return jobWrappers;
    }

    public static List<AsyncApexJob> retrieveJobInfo(List<String> jobStatuses, List<String> apexClassNames, List<Id> jobIds) {

        List<AsyncApexJob> jobs = [
                SELECT   Id, ApexClass.Name, Status,CompletedDate,ExtendedStatus,
                         NumberOfErrors,MethodName,JobType,JobItemsProcessed,
                         LastProcessedOffset,TotalJobItems,ParentJobId
                FROM     AsyncApexJob
                WHERE    Id IN :jobIds
                AND      Status          IN :jobStatuses
                AND      ApexClass.Name  IN :apexClassNames
                ORDER BY ApexClass.NAME, CreatedDate DESC
        ];
        return jobs;
    }
    public static List<AsyncApexJob> retrieveMeterJobInfo(List<String> jobStatuses, String apexClassName,Datetime createdDate) {

        List<AsyncApexJob> jobs = [
                SELECT   Id, ApexClass.Name, Status,CompletedDate,ExtendedStatus,
                        NumberOfErrors,MethodName,JobType,JobItemsProcessed,
                        LastProcessedOffset,TotalJobItems,ParentJobId
                FROM     AsyncApexJob
                WHERE    Status          IN :jobStatuses
                AND      ApexClass.Name  =  :apexClassName
                AND      CreatedDate >= :createdDate
                AND      JobType = 'BatchApex'
                ORDER BY ApexClass.NAME, CreatedDate DESC
        ];
        return jobs;
    }

    public static Integer retrieveNumMeters(    Datetime meterCreatedDate,String region,
                                                Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {

        Datetime startDt;
        Datetime endDt;

        if( meterCreatedDate != null ) {
           startDt =  meterCreatedDate.addMinutes(-nbrOfMinutesToSubtractFromMeterCreatedDate);
           endDt   = meterCreatedDate.addMinutes(nbrOfMinutesToAddToMeterCreatedDate);
        }

        String soql = '';
        soql += ' SELECT COUNT() ';
        soql += ' FROM   Meter_Reading__c ';
        soql += ' WHERE  ( Route_Processing_Sheet__r.Processing_Location__c = :region ';
        soql += '        AND CreatedDate = TODAY  ) ';
        if(meterCreatedDate != null) {
            soql += ' OR     ( ';
            soql += '          CreatedDate >= :startDt AND createdDate <= :endDt    ';
            soql += '        ) ';
        }
        return Database.countQuery(soql);
    }

    public static Integer retrieveNumRouteProcessingSheets( Datetime meterCreatedDate,String region,
                                                            Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                            Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {
        Integer iNum = 0;
        String soql = '';

        if(meterCreatedDate != null) {
            Datetime startDt = meterCreatedDate.addMinutes(-nbrOfMinutesToSubtractFromMeterCreatedDate);
            Datetime endDt = meterCreatedDate.addMinutes(nbrOfMinutesToAddToMeterCreatedDate);
            soql = ' SELECT COUNT() ';
            soql += ' FROM   Route_Processing_Sheet__c ';
            soql += ' WHERE  Id IN ( ';
            soql += '           SELECT Route_Processing_Sheet__c ';
            soql += '           FROM   Meter_Reading__c ';
            soql += '           WHERE  CreatedDate >= :startDt AND createdDate <= :endDt  ';
            soql += ' ) ';
            iNum += Database.countQuery(soql);

        }

//        soql = ' SELECT COUNT() ';
//        soql += ' FROM   Route_Processing_Sheet__c ';
//        soql += ' WHERE  ( ';
//        soql += '           Processing_Location__c = :region ';
//        soql += '           AND CreatedDate = YESTERDAY  ';
//        soql += '        ) ';
//        iNum+= Database.countQuery(soql);

        return iNum;
    }

    public static Integer retrieveNumRouteSchedules(    Datetime meterCreatedDate,String region,
                                                        Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                        Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {

        Integer iNum = 0;
        String soql = '';
        Set<String> regionsToExclude = new Set<String>();

        if(meterCreatedDate != null) {
            Datetime startDt = meterCreatedDate.addMinutes(-nbrOfMinutesToSubtractFromMeterCreatedDate);
            Datetime endDt = meterCreatedDate.addMinutes(nbrOfMinutesToAddToMeterCreatedDate);

            soql += ' SELECT Route_Schedule__c rsId, Processing_Location__c region ';
            soql += ' FROM   Route_Processing_Sheet__c ';
            soql += ' WHERE   ';
            soql += '           ID IN (  ';
            soql += '              SELECT Route_Processing_Sheet__c ';
            soql += '              FROM   Meter_Reading__c  ';
            soql += '              WHERE CreatedDate >= :startDt AND CreatedDate <= :endDt ';
            soql += '           ) ';
            soql += ' GROUP BY Route_Schedule__c, Processing_Location__c ';

            List<AggregateResult> ars = Database.query(soql);
            iNum = ars.size();
//            if(!ars.isEmpty()) {
//                for(AggregateResult ar : ars) {
//                    String tmpRegion = (String)ar.get('region');
//                    if(!region.equalsIgnoreCase(tmpRegion)) {
//                        regionsToExclude.add((String) ar.get('region'));
//                    }
//                }
//            }
        }
        soql =  ' SELECT COUNT() ';
        soql += ' FROM Route_Schedule__c ';
        soql += ' WHERE Processing_Location__c = :region ';
        soql += ' AND  Total_Meter_Readings__c < 1 ';
        soql += ' AND  CreatedDate = YESTERDAY ';

//        soql =  ' SELECT COUNT() ';
//        soql += ' FROM Route_Schedule__c ';
//        soql += ' WHERE Processing_Location__c = :region ';
//        soql += ' AND Processing_Location__c NOT IN :regionsToExclude ';
//        soql += ' AND  CreatedDate = TODAY ';
        iNum += Database.countQuery(soql);

        return iNum;
    }

    public static Set<String> retrieveRegionsAffected(  Datetime meterCreatedDate,
                                                        String  region,
                                                        Integer nbrOfMinutesToAddToMeterCreatedDate,
                                                        Integer nbrOfMinutesToSubtractFromMeterCreatedDate) {
        Set<String> regions = new Set<String>();

        Datetime startDt = meterCreatedDate.addMinutes(-nbrOfMinutesToSubtractFromMeterCreatedDate);
        Datetime endDt = meterCreatedDate.addMinutes(nbrOfMinutesToAddToMeterCreatedDate);

        List<AggregateResult> ars = [
                SELECT Processing_Location__c region
                FROM Route_Processing_Sheet__c
                WHERE Id IN (
                        SELECT Route_Processing_Sheet__c
                        FROM Meter_Reading__c
                        WHERE CreatedDate >= :startDt AND CreatedDate <= :endDt
                )
                GROUP BY Processing_Location__c
        ];
        if (!ars.isEmpty()) {
            for (AggregateResult ar : ars) {
                regions.add((String)ar.get('region'));
            }
        }
        regions.add(region);
        return regions;
    }


    /**
     * A simple wrapper for synchronous results to display on a UI if desired.
     */
    public class SyncResult {
        @AuraEnabled public String msg;
        @AuraEnabled public String criteria;
        @AuraEnabled public Datetime meterCreatedDate;
        @AuraEnabled public Datetime msgDateTime;

        public SyncResult(String msg,Datetime meterCreatedDate,String region) {
            this.msg = msg;
            this.msgDateTime = System.now();
            this.criteria = 'Meters created = '+meterCreatedDate + ' or region = '+region;
        }

        public SyncResult(List<SObject> sObjs,Datetime metersCreatedDate,String region) {
            this.msgDateTime = System.now();
            if(!sObjs.isEmpty()) {
                SObject sobj = sObjs[0];
                SObjectType sObjType = sobj.getSObjectType();
                String label = sObjType.getDescribe().getLabel();
                this.msg = 'Deleted '+sObjs.size() +  ' ' +label + 's';
                this.criteria = 'Meters Created ' + metersCreatedDate.format() + ' or region ='+region;
            }
        }

        public SyncResult(String msg,String processingLocation) {
            this.msg = msg;
            this.msgDateTime = System.now();
            this.criteria = 'Created Today and Processing Location = '+processingLocation;
        }

        public SyncResult(String msg,Integer iNextCycle, String processingLocation) {
            this.msg = msg;
            this.msgDateTime = System.now();
            this.criteria = 'Next Cycle: '+iNextCycle+ ' and Processing Location = '+processingLocation;
        }
        public SyncResult(List<SObject> sObjs,String processingLocation) {
            this.msgDateTime = System.now();
            if(!sObjs.isEmpty()) {
                SObject sobj = sObjs[0];
                SObjectType sObjType = sobj.getSObjectType();
                String label = sObjType.getDescribe().getLabel();
                this.msg = 'Deleted '+sObjs.size() +  ' ' +label + 's';
                this.criteria = 'Created Today and Processing Location = '+processingLocation;
            }
        }
    }

    public class JobWrapper {
        @AuraEnabled public Id  recordId;
        @AuraEnabled public Id  jobId;
        @AuraEnabled public Id  parentJobId;
        @AuraEnabled public String apexClassName;
        @AuraEnabled public String methodName;
        @AuraEnabled public String status;
        @AuraEnabled public String extendedStatus;
        @AuraEnabled public Datetime completedDate;
        @AuraEnabled public Integer jobItemsProcessed;
        @AuraEnabled public Integer totalJobItems;
        @AuraEnabled public Integer numberOfErrors;
        @AuraEnabled public Integer lastProcessedOffset;
        @AuraEnabled public String  jobType;

        public JobWrapper(AsyncApexJob apexJob) {
            this.jobId = apexJob.Id;
            this.parentJobId = apexJob.ParentJobId;
            this.apexClassName = apexJob.ApexClass.Name;
            this.methodName = apexJob.MethodName;
            this.status = apexJob.Status;
            this.extendedStatus = apexJob.ExtendedStatus;
            this.completedDate = apexJob.CompletedDate;
            this.jobItemsProcessed = apexJob.JobItemsProcessed;
            this.totalJobItems = apexJob.TotalJobItems;
            this.jobType = apexJob.JobType;
            this.numberOfErrors = apexJob.NumberOfErrors;
            this.lastProcessedOffset = apexJob.LastProcessedOffset;
        }
    }

    public class DataTotals {
        @AuraEnabled public Integer numRS;
        @AuraEnabled public Integer numRPS;
        @AuraEnabled public Integer numMeters;
    }
    private static String unitTestJobsJson = '[{"attributes":{"type":"AsyncApexJob","url":"/services/data/v55.0/sobjects/AsyncApexJob/7075300000mC1rbAAC"},"Id":"7075300000mC1rbAAC","CronTriggerId":"08e53000008UWGeAAO","ApexClassId":"01p8W00000ITfRoQAL","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v55.0/sobjects/ApexClass/01p8W00000ITfRoQAL"},"Id":"01p8W00000ITfRoQAL","Name":"GeoTab_Sch_QueueableLocRefresh"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v55.0/sobjects/CronTrigger/08e53000008UWGeAAO"},"Id":"08e53000008UWGeAAO","CronJobDetailId":"08a53000008UY15AAG","NextFireTime":"2022-09-09T12:59:24.000+0000","StartTime":"2022-09-09T12:58:24.000+0000","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v55.0/sobjects/CronJobDetail/08a53000008UY15AAG"},"Id":"08a53000008UY15AAG","Name":"GeoTab_Gps_Location_Update_(Every_Minute)-9/9/2022 7:58 AM24"}}}]';
}