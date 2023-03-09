/**
 * Ui Backing Controller for the PA Advisory Gallery for both photo and datatable display.
 */
public class PaAdvisoryGalleryController {

    //  Map keys allow for easy client retrieval of multiple values returned from method calls.
    public static final String MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT     = 'ADVISORY_RECORDS_TOTAL_COUNT';
    public static final String MAP_KEY_ADVISORY_WRAPS                   = 'ADVISORY_WRAPS';
    public static final String MAP_KEY_ADVISORY_EXPORT                  = 'ADVISORY_EXPORT';
    public static final String MAP_KEY_ADVISORY_RECORD                  = 'ADVISORY_RECORD';
    public static final String MAP_KEY_APEX_JOBS                        = 'APEX_JOBS';
    public static final String MAP_KEY_JOB_FIRE_STATUS                  = 'JOB_FIRE_STATUS';
    public static final String MAP_KEY_JOB_ABORT_IDS                    = 'MAP_KEY_JOB_ABORT_IDS';
    public static final String JOB_NAME                                 = 'PortalAdvisory Import - 07:00 Daily';
    private static final Integer DEFAULT_ROWS_LIMIT                     = 2000; //  SOQL Offset LIMIT.

    /**
    * UI Accessible search to retrieve multiple PA_Advisory__c sObjects based on search params.
    * Use for wired / declarative calls and providing an offset for pagination / infinite scroll.
    * as well as advanced filter criteria. Retrieves a subset of fields.
    *
    * @param searchParams  The AdvisorySearchParams to execute the search with.
    * @return              A responseDto containing a List of AdvisoryWrapper classes in the values map.
    *
    * @see AdvisorySearchParams
    * @see AdvisoryWrapper
    */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrievePaAdvisoriesAdvancedSearchDeclarative(AdvisorySearchParams searchParams) {
        return retrievePaAdvisoriesAdvancedSearch(searchParams);
    }

    /**
     * Total count of records the search would include.
     *
     * UI Accessible search to retrieve multiple PA_Advisory__c sObjects based on search params.
     * Use for wired / declarative calls and providing an offset for pagination / infinite scroll.
     * as well as advanced filter criteria. Retrieves a subset of fields.
     *
     * @param searchParams  The AdvisorySearchParams to execute the search with.
     * @return              A responseDto containing a List of AdvisoryWrapper classes in the values map.
     *
     * @see AdvisorySearchParams
     * @see AdvisoryWrapper
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrievePaAdvisoriesAdvancedSearchDeclarativeTotalRecords(AdvisorySearchParams searchParams) {
        return retrievePaAdvisoriesAdvancedSearchTotalRecords(searchParams);
    }

   /**
    * UI Accessible search to retrieve multiple PA_Advisory__c sObjects based on search params.
    * Use for IMPERATIVE and providing an offset for pagination / infinite scroll.
    * as well as advanced filter criteria. Retrieves a subset of fields.
    *
    * @param searchParams  The AdvisorySearchParams to execute the search with.
    * @return              A responseDto containing a List of AdvisoryWrapper classes in the values map.
    *
    * @see AdvisorySearchParams
    * @see AdvisoryWrapper
    */
    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrievePaAdvisoriesAdvancedSearchImperative(AdvisorySearchParams searchParams) {
        return retrievePaAdvisoriesAdvancedSearch(searchParams);
    }

    /**
     * UI Accessible search to retrieve multiple PA_Advisory__c sObjects based on search params.
     * Use for wired / declarative calls and providing an offset for pagination / infinite scroll.
     * as well as advanced filter criteria. Retrieves a subset of fields.
     *
     * @param searchParams  The AdvisorySearchParams to execute the search with.
     * @return              A responseDto containing a List of AdvisoryWrapper classes in the values map.
     *
     * @see AdvisorySearchParams
     * @see AdvisoryWrapper
     */
    public static ResponseDto retrievePaAdvisoriesAdvancedSearch(AdvisorySearchParams searchParams) {
        ResponseDto dto = new ResponseDto();
        List<AdvisoryWrapper> resultWraps = new List<AdvisoryWrapper>();

        dto.technicalMsg += '--> search params '+searchParams;
        if(searchParams == null) {
            dto.technicalMsg += ' unable to find params.. returning ';
            dto.severity = 'error';
            dto.message = 'No Parameters passed.';
        } else {

            List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                    searchParams.iOffset,
                    searchParams.iLimit,
                    searchParams.advisoryStartDate,
                    searchParams.advisoryEndDate,
                    searchParams.isVisible,
                    searchParams.fullName,
                    searchParams.city
            );
            resultWraps = buildAdvisoryWraps(advisories);
            dto.technicalMsg += '--> retrieved ' + resultWraps.size() + ' PA_Advisory__c WRAPS.';
            dto.isSuccess = !resultWraps.isEmpty();
            dto.values.put(MAP_KEY_ADVISORY_WRAPS, resultWraps);
        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveScheduledJobInfo(List<String> apexClassNames,List<String> jobStatuses) {
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        List<AsyncApexJob> jobs = AsyncApexJobsSvc.retrieveJobInfo(jobStatuses,apexClassNames);
        if(Test.isRunningTest()) {
            jobs = (List<AsyncApexJob>)JSON.deserialize(unitTestJobsJson,List<AsyncApexJob>.class);
        }
        System.debug('jobs json='+JSON.serialize(jobs));
        List<JobWrapper> jobWrappers = buildJobWrappers(jobs);
        dto.values.put(MAP_KEY_APEX_JOBS,jobWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto firePaImportJob() {
        PortalAdvisory_Sch_Import schJob = new PortalAdvisory_Sch_Import();
        String cron = '0 0 07 * * ?';
        String jobName = Test.isRunningTest() ? JOB_NAME + ' Test' : JOB_NAME;
        Id jobId = system.schedule(jobName, cron, schJob);
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_JOB_FIRE_STATUS,jobId);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto abortPaImportJob() {
        ResponseDto dto = new ResponseDto();
        List<Id> jobIds = findAllJobs();
        if(!jobIds.isEmpty()) {
            for(Id jobId : jobIds) {
                System.abortJob(jobId);
            }
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_JOB_ABORT_IDS,jobIds);
        return dto;
    }


    /**
     * UI Accessible search to retrieve multiple PA_Advisory__c sObjects based on search params.
     * Use for wired / declarative calls and providing an offset for pagination / infinite scroll.
     * as well as advanced filter criteria. Retrieves a subset of fields.
     *
     * @param searchParams  The AdvisorySearchParams to execute the search with.
     * @return              A responseDto containing a List of AdvisoryWrapper classes in the values map.
     *
     * @see AdvisorySearchParams
     * @see AdvisoryWrapper
     */
    public static ResponseDto retrievePaAdvisoriesAdvancedSearchTotalRecords(AdvisorySearchParams searchParams) {
        ResponseDto dto = new ResponseDto();
        Integer iTotalCount;

        dto.technicalMsg += '--> search params '+searchParams;
        if(searchParams == null) {
            dto.technicalMsg += ' unable to find params.. returning ';
            dto.severity = 'error';
            dto.message = 'No Parameters passed.';
        } else {
            iTotalCount = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                    searchParams.iOffset,
                    searchParams.iLimit,
                    searchParams.advisoryStartDate,
                    searchParams.advisoryEndDate,
                    searchParams.isVisible,
                    searchParams.fullName,
                    searchParams.city
            );
            dto.technicalMsg += '--> retrieved ' + iTotalCount+ ' records';
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_ADVISORY_RECORDS_TOTAL_COUNT, iTotalCount);
        }
        return dto;
    }

    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrievePaAdvisoriesExportData(AdvisorySearchParams searchParams) {
        ResponseDto dto = new ResponseDto();
        Boolean isVisible = searchParams.isVisible;
        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesExportData(isVisible);
        dto.isSuccess = !advisories.isEmpty();
        dto.values.put(MAP_KEY_ADVISORY_EXPORT,advisories);
        return dto;
    }

    /**
     * Converts the List of Pa_Advisory__c sObjects to wrappers.
     *
     * @param advisories    A List of Pa_Advisory__c sObjects.
     * @return              A List of AdvisoryWrapper classes.
     *
     * @see AdvisoryWrapper
     */
    @TestVisible
    private static List<AdvisoryWrapper> buildAdvisoryWraps(List<PA_Advisory__c> advisories) {
        List<AdvisoryWrapper> wraps = new List<AdvisoryWrapper>();
        if(advisories != null) {
            for (PA_Advisory__c advisory : advisories) {
                wraps.add(new AdvisoryWrapper(advisory));
            }
        }
        return wraps;
    }

    private static List<JobWrapper> buildJobWrappers(List<AsyncApexJob> apexJobs) {
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for(AsyncApexJob apexJob : apexJobs) {
            jobWrappers.add(new JobWrapper(apexJob));
        }
        return jobWrappers;
    }

    /**
     * UI Accessible search to retrieve multiple AdvisoryWrappers based on search params.
     * Retrieves a subset of fields.
     *
     * @param searchParams  The AdvisorySearchParams to execute the search with.
     * @return              A responseDto containing a List of AdvisoryWrapper classes in the values map.
     */
    @AuraEnabled
    public static ResponseDto retrievePaAdvisories(AdvisorySearchParams searchParams) {
        ResponseDto dto = retrievePaAdvisoriesSearch(searchParams);
        return dto;
    }

    /**
     * A Simple search by advisory start and end dates. Retrieves a subset of fields.
     *
     * @param params  The AdvisorySearchParams to execute the search with.
     * @return       A responseDto containing a List of AdvisoryWrapper classes in the values map.
     */
    public static ResponseDto retrievePaAdvisoriesSearch(AdvisorySearchParams params) {
        ResponseDto dto = new ResponseDto();
        List<AdvisoryWrapper> advisoryWrappers = new List<AdvisoryWrapper>();
        dto.technicalMsg += '--> search params '+params;
        if(params == null) {
            params = new AdvisorySearchParams();
            dto.technicalMsg += ' unable to find params.. initting defaults';
        }
        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisories(params.iLimit,
                                                                                    params.advisoryStartDate,
                                                                                    params.advisoryEndDate);
        advisoryWrappers =  buildAdvisoryWraps(advisories);

        dto.technicalMsg += '--> retrieved '+advisoryWrappers.size() + ' Advisory Wrappers.';
        dto.isSuccess = !advisoryWrappers.isEmpty();
        dto.values.put(MAP_KEY_ADVISORY_WRAPS,advisoryWrappers);

        return dto;
    }

    /**
     * Use for PDF Export
     *
     * @param   advisoryIds     A List of Pa_Advisory__c.Id values.
     * @return                  A responseDto containing a List of AdvisoryWrapper classes in the values map.
     */
    @AuraEnabled
    public static ResponseDto retrievePaAdvisoriesForPdfExport( List<Id> advisoryIds ) {
        ResponseDto dto = new ResponseDto();
        List<AdvisoryWrapper> advisoryWrappers = new List<AdvisoryWrapper>();
        Set<Id> setAdvisoryIds = new Set<Id>(advisoryIds);
        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesForPdfExport(setAdvisoryIds);
        advisoryWrappers =  buildAdvisoryWraps(advisories);

        dto.technicalMsg += '--> retrieved '+advisoryWrappers.size() + ' Advisory Wrappers.';
        dto.isSuccess = !advisoryWrappers.isEmpty();
        dto.values.put(MAP_KEY_ADVISORY_WRAPS,advisoryWrappers);

        return dto;
    }

    /**
     * Retrieve all fields from PA_Advisory__c.
     *
     * @param         paAdvisoryId  - A single PA_Advisory__c.Id.
     * @return        A responseDto containing a single PA_Advisory__c sObject (all fields) in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrievePaAdvisoryDetail(Id paAdvisoryId) {
        ResponseDto dto = new ResponseDto();

        PA_Advisory__c advisory;
        advisory = PaAdvisoryGallerySvc.retrievePaAdvisory(paAdvisoryId);
        dto.isSuccess = advisory != null;
        dto.values.put(MAP_KEY_ADVISORY_RECORD,advisory);

        return dto;
    }

    /**
     * A simple search param wrapper. Used mostly for advanced search functionality.
     * Eliminates the need to pass N number of params from the client to server but rather allows easy
     * add of new parameters via wrapping in an object.
     */
    public class AdvisorySearchParams {
        @AuraEnabled public Integer iLimit {get;set;}           //  soql LIMIT
        @AuraEnabled public Integer iOffset {get;set;}          //  soql OFFSET
        @AuraEnabled public Date advisoryStartDate {get;set;}   //  Pa_Advisory__c.Advisory_Date__c (Start)
        @AuraEnabled public Date advisoryEndDate {get;set;}     //  Pa_Advisory__c.Advisory_Date__c (End)
        @AuraEnabled public Boolean isVisible {get;set;}        //  Pa_Advisory__c.Visible__c
        @AuraEnabled public String fullName  {get;set;}         //  Pa_Advisory__c.Full_Name__c.
        @AuraEnabled public String city {get;set;}              //  Pa_Advisory__c.City__c;

        public AdvisorySearchParams() {
            this.iLimit = DEFAULT_ROWS_LIMIT;
        }
    }
    /**
     * A Wrapper around PA_Advisory__c sObjects (for future growth / server side sorting if needed).
     */
    public class AdvisoryWrapper {
        @AuraEnabled public PA_Advisory__c advisory;
        @AuraEnabled public String photoSrcUrl;

        public AdvisoryWrapper(PA_Advisory__c rec) {
            this.advisory = rec;
            this.photoSrcUrl = parseImageUrl(this.advisory.Photo__c);
        }
    }
    /**
     * @param rteField The Standard SFDC Rich Text Edit Field
     * @return An img src url embedded in the RT Field
     */
    private static String parseImageUrl(String rteField) {
        String link;
        if(String.isNotBlank(rteField)) {
            String firstSubString = rteField.substringBetween('<img', 'img>');
            String secondSubString = firstSubString.substringBetween('src="', '"');
            link = secondSubString.replace('amp;', '');
        }
        return link;
    }

    public class JobWrapper {

        @AuraEnabled public Id cronTriggerId;
        @AuraEnabled public String apexClassName;
        @AuraEnabled public String jobName;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime nextFireTime;
        @AuraEnabled public Datetime startTime;
        @AuraEnabled public String state;

        public JobWrapper(AsyncApexJob apexJob) {
            this.cronTriggerId = apexJob.CronTriggerId;
            this.apexClassName = apexJob.ApexClass.Name;
            this.jobName = apexJob.CronTrigger.CronJobDetail.Name;
            this.status = apexJob.Status;
            this.nextFireTime = apexJob.CronTrigger.NextFireTime;
            this.startTime = apexJob.CronTrigger.StartTime;
            this.state = apexJob.CronTrigger.State;
        }
    }

    public static List<Id> findAllJobs() {
        List<Id> jobIds = new List<Id>();
        String jobName = Test.isRunningTest() ? JOB_NAME + ' TEST' : JOB_NAME;
        List<CronTrigger> cts = [
                SELECT Id,CronJobDetail.Name
                FROM CronTrigger
                WHERE CronJobDetail.Name = :jobName AND State = 'Waiting'
        ];

        if(!cts.isEmpty()) {
            for(CronTrigger ct : cts) {
                jobIds.add(ct.Id);
            }
        }
        return jobIds;
    }
    private static String unitTestJobsJson = '[{"attributes":{"type":"AsyncApexJob","url":"/services/data/v55.0/sobjects/AsyncApexJob/7075300000mC1rbAAC"},"Id":"7075300000mC1rbAAC","CronTriggerId":"08e53000008UWGeAAO","ApexClassId":"01p8W00000ITfRoQAL","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v55.0/sobjects/ApexClass/01p8W00000ITfRoQAL"},"Id":"01p8W00000ITfRoQAL","Name":"GeoTab_Sch_QueueableLocRefresh"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v55.0/sobjects/CronTrigger/08e53000008UWGeAAO"},"Id":"08e53000008UWGeAAO","CronJobDetailId":"08a53000008UY15AAG","NextFireTime":"2022-09-09T12:59:24.000+0000","StartTime":"2022-09-09T12:58:24.000+0000","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v55.0/sobjects/CronJobDetail/08a53000008UY15AAG"},"Id":"08a53000008UY15AAG","Name":"GeoTab_Gps_Location_Update_(Every_Minute)-9/9/2022 7:58 AM24"}}}]';
}