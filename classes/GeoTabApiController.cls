public class GeoTabApiController {

    public static String                MAP_KEY_DEVICES                 = 'DEVICES';
    public static String                MAP_KEY_DEVICES_STATUS_INFO     = 'DEVICES_STATUS_INFO';
    public static String                MAP_KEY_SERVICE_RESOURCE_WRAPS  = 'SERVICE_RESOURCE_WRAPS';
    public static String                MAP_KEY_SERVICE_RESOURCE_STATE  = 'SR_STATE';
    public static String                MAP_KEY_APEX_JOBS               = 'APEX_JOBS';
    public static String                MAP_KEY_AUTH_MDT                = 'AUTH_MDT';
    public static String                MAP_KEY_AUTH_MDT_URL            = 'AUTH_MDT_URL';
    public static String                MAP_KEY_CACHE_SETUP_URL         = 'AUTH_CACHE_URL';
    public static String                MAP_KEY_AUTH_CACHE              = 'AUTH_CACHE';
    public static String                MAP_KEY_APP_LOGS                = 'APP_LOGS';
    public static String                MAP_KEY_JOB_ABORT_IDS           = 'JOB_ABORT_IDS';


    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrieveAppLogs(  Integer iLimit,Integer iHoursBack,
                                                List<String> jobNames,List<String> jobStatuses) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'params.. iLimit='+iLimit +'...iHoursBack='+iHoursBack+'..jobName='+jobNames;
        Set<String> sJobNames = new Set<String>();
        Set<String> sJobStatuses = new Set<String>();
        sJobNames.addAll(jobNames);
        sJobStatuses.addAll(jobStatuses);
        List<Accel_Application_Error__c> logs = retrieveLogListWithinHours(iLimit,iHoursBack,sJobNames,sJobStatuses);
        dto.isSuccess = logs != null && !logs.isEmpty();
        dto.values.put(MAP_KEY_APP_LOGS,logs);
        return dto;
    }

    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrieveAuthMdt() {
        ResponseDto dto = new ResponseDto();
        API_Setting__mdt mdt = ApiSvc.retrieveApiSetting(GeoTabSvc.DEFAULT_API_SETTING_DEV_NAME);
        dto.isSuccess = mdt != null;
        String baseUrl =  Url.getSalesforceBaseUrl().toExternalForm();
        String mdtUrl = baseUrl +'/'+mdt.Id;
        String cacheUrl;
        //String cacheUrl = baseUrl + '/lightning/setup/PlatformCache/home';
        PlatformCachePartition partition = PlatformCacheSvc.retrievePcPartition(GeoTabPlatformCacheSvc.GEOTAB_PARTITION);
        if(partition != null) {
            cacheUrl = baseUrl + '/' + partition.Id;
        }
        dto.values.put(MAP_KEY_AUTH_MDT,mdt);
        dto.values.put(MAP_KEY_AUTH_MDT_URL,mdtUrl);
        dto.values.put(MAP_KEY_CACHE_SETUP_URL,cacheUrl);
        return dto;
    }

    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrievePlatformCacheAuth() {
        ResponseDto dto = new ResponseDto();
        GeoTabAuthJsonToApex geoTabAuth = GeoTabPlatformCacheSvc.getAuthResp();
        CredentialsWrapper credentialsWrapper = new CredentialsWrapper(geoTabAuth);
        dto.isSuccess = credentialsWrapper.userName != null;
        dto.values.put(MAP_KEY_AUTH_CACHE,credentialsWrapper);
        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllDevices(Integer iLimit) {
        ResponseDto dto = new ResponseDto();
        GeoTabDeviceResult gdr = GeoTabSvc.getDevices(GeoTabUtils.generateId(),null,iLimit);
        List<ServiceResource> srsWithDevices = GeoTabSvc.retrieveServiceResources(null);
        dto.isSuccess = gdr.error == null;
        if(gdr.error != null) {
            dto.severity = 'warning';
            dto.message = gdr.error.error.message;
        }
        List<DeviceWrapper> drs;
        if(dto.isSuccess) {
            drs = buildDeviceWrappers(gdr, srsWithDevices);
        }
        dto.values.put(MAP_KEY_DEVICES,drs);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveServiceResources() {
        ResponseDto dto = new ResponseDto();
        List<ServiceResource> srsWithDevices = GeoTabSvc.retrieveServiceResources(null);
        List<ServiceResourceWrapper> srWrappers = buildSrWrappers(srsWithDevices);
        dto.isSuccess = !srsWithDevices.isEmpty();
        dto.values.put(MAP_KEY_SERVICE_RESOURCE_WRAPS,srWrappers);
        return dto;
    }


    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrieveAllDevicesStatusInfo(Integer iLimit) {
        ResponseDto dto = new ResponseDto();
        GeoTabDeviceStatusInfoResult res = GeoTabSvc.getDeviceStatusInfo(GeoTabUtils.generateId(),null,iLimit);
        List<ServiceResource> srsWithDevices = GeoTabSvc.retrieveServiceResources(null);
        dto.isSuccess = true;
        List<DeviceStatusInfoWrapper> dSiWrappers = buildDeviceStatusInfoWrappers(res,srsWithDevices);
        dto.values.put(MAP_KEY_DEVICES_STATUS_INFO,dSiWrappers);
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

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveCurrentServiceResourceState() {
        ResponseDto dto = new ResponseDto();

        ServiceResourceState state = buildServiceResourceState();
        dto.values.put(MAP_KEY_SERVICE_RESOURCE_STATE,state);
        dto.isSuccess = true;

        return dto;
    }

    @AuraEnabled
    public static ResponseDto fireDeviceStatusJob() {
        // Schedule GPS job to run every minute.
        String JOB_NAME = GeoTab_Sch_QueueableLocRefresh.JOB_NAME;
        Integer intervalMinutes = 1;
        Datetime dtNow = Datetime.now();

        GeoTab_Sch_QueueableLocRefresh schJob = new GeoTab_Sch_QueueableLocRefresh(intervalMinutes);

        String cronString = '' + dtNow.second()+' '+dtNow.addMinutes(intervalMinutes).minute()+
                ' '+ dtNow.hour()+' '+dtNow.day()+' '+ dtNow.month()+' ? '+dtNow.year();

        String jobId = System.schedule(
                JOB_NAME + '-' + dtNow.format(),
                cronString,
                schJob
        );
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        dto.values.put('JOB_FIRE_STATUS',jobId);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto abortAllDeviceStatusJobs() {
        ResponseDto dto = new ResponseDto();

        GeoTab_Sch_QueueableLocRefresh schJob = new GeoTab_Sch_QueueableLocRefresh(1);
        Set<Id> abortedIds = schJob.abortAll();
        dto.isSuccess = !abortedIds.isEmpty();
        dto.values.put(MAP_KEY_JOB_ABORT_IDS,abortedIds);
        return dto;
    }


    private static List<JobWrapper> buildJobWrappers(List<AsyncApexJob> apexJobs) {
        List<JobWrapper> jobWrappers = new List<JobWrapper>();
        for(AsyncApexJob apexJob : apexJobs) {
            jobWrappers.add(new JobWrapper(apexJob));
        }
        return jobWrappers;
    }

    private static List<ServiceResourceWrapper> buildSrWrappers(List<ServiceResource> srs) {
        List<ServiceResourceWrapper> srWrappers = new List<ServiceResourceWrapper>();
        for(ServiceResource sr : srs) {
            srWrappers.add(new ServiceResourceWrapper(sr));
        }
        return srWrappers;
    }

    private static List<DeviceWrapper> buildDeviceWrappers(GeoTabDeviceResult gdr, List<ServiceResource> srs) {
        List<DeviceWrapper> deviceWrappers  =  new List<DeviceWrapper>();

        Map<String,ServiceResource> m = new Map<String,ServiceResource>();
        if(srs != null && !srs.isEmpty()) {
            for(ServiceResource sr : srs) {
                m.put(sr.GeotabId__c,sr);
            }
        }
        if(gdr.result != null) {
            for(GeoTabDevice gd : gdr.result) {
                DeviceWrapper dw = new DeviceWrapper(gd);
                if(m.containsKey(dw.id)) {
                    ServiceResource sr = m.get(dw.id);
                    dw.serviceResourceId = sr.Id;
                    dw.serviceResourceName = sr.Name;
                }
                deviceWrappers.add(dw);
            }
        }
        return deviceWrappers;
    }

    private static List<DeviceStatusInfoWrapper> buildDeviceStatusInfoWrappers( GeoTabDeviceStatusInfoResult statusInfoResult,
                                                                                List<ServiceResource> srs) {
        List<DeviceStatusInfoWrapper> statusInfoWrappers  =  new List<DeviceStatusInfoWrapper>();

        Map<String,ServiceResource> m = new Map<String,ServiceResource>();
        if(srs != null && !srs.isEmpty()) {
            for(ServiceResource sr : srs) {
                m.put(sr.GeotabId__c,sr);
            }
        }
        if(statusInfoResult.result != null) {
            for(GeoTabDeviceStatusInfo statusInfo  : statusInfoResult.result) {
                DeviceStatusInfoWrapper statusInfoWrapper  = new DeviceStatusInfoWrapper(statusInfo);
                if(m.containsKey(statusInfoWrapper.statusInfo.device.id)) {
                    ServiceResource sr = m.get(statusInfoWrapper.statusInfo.device.id);
                    statusInfoWrapper.serviceResourceId = sr.Id;
                    statusInfoWrapper.serviceResourceName = sr.Name;
                }
                statusInfoWrappers.add(statusInfoWrapper);
            }
        }
        return statusInfoWrappers;
    }

    /**
     * @param iLimit        The Limit of Rows to return.
     * @param hoursBack     The number of hours back to go with the created date.
     * @param jobNames      The Job_Name__c field for the query filter.
     * @param jobStatuses   The Overall_Job_Status__c for the query filter.
     *
     * @return              A List of Accel_Application_Error__c sObjects.
     */
    public static List<Accel_Application_Error__c> retrieveLogListWithinHours(
            Integer iLimit,Integer hoursBack,Set<String> jobNames, Set<String> jobStatuses ) {

        Datetime dtHoursBack = System.now().addHours(-hoursBack);
        List<Accel_Application_Error__c> logs;
        logs = [
                SELECT  Id,Name,JobType__c,Job_Name__c,Overall_Job_Status__c,Process_Start_Date__c,Process_End_Date__c,
                        Total_Records_Selected__c,Total_Records_Processed__c,Total_Records_Updated__c,Total_Updates_Failed__c,
                        Initiating_Job_Id__c,CreatedDate,LastModifiedDate
                FROM    Accel_Application_Error__c
                WHERE   CreatedDate >= :dtHoursBack
                AND     Job_Name__c IN :jobNames
                AND     Overall_Job_Status__c IN :jobStatuses
                ORDER BY CreatedDate DESC
                LIMIT   :iLimit
        ];
        return logs;
    }

    @TestVisible
    private static ServiceResourceState buildServiceResourceState() {
        ServiceResourceState state = new ServiceResourceState();

        state.totalActiveServiceResources = GeoTabSvc.retrieveNumActiveServiceResources();
        state.totalActiveServiceResourcesWithGeoTabId = GeoTabSvc.retrieveNumActiveServiceResourcesWithGeoTabId();
        state.totalActiveServiceResourcesWithoutGeoTabId = GeoTabSvc.retrieveNumActiveServiceResourcesWithoutGeoTabId();

        return state;
    }

    public class ServiceResourceState {
        @AuraEnabled public Integer totalActiveServiceResources = 0;
        @AuraEnabled public Integer totalActiveServiceResourcesWithGeoTabId = 0;
        @AuraEnabled public Integer totalActiveServiceResourcesWithoutGeoTabId = 0;
    }

    public class DeviceWrapper {
        @AuraEnabled public Id serviceResourceId = null;
        @AuraEnabled public String serviceResourceName = null;
        @AuraEnabled public String id;
        @AuraEnabled public String serialNumber;
        @AuraEnabled public String name;
        @AuraEnabled public String vehicleIdentificationNumber;
        @AuraEnabled public Integer idleMinutes;
        @AuraEnabled public Integer major;
        @AuraEnabled public Integer minor;

        public DeviceWrapper(GeoTabDevice gd) {
            this.id = gd.id;
            this.serialNumber = gd.serialNumber;
            this.name = gd.name;
            this.vehicleIdentificationNumber = gd.vehicleIdentificationNumber;
            this.idleMinutes = gd.idleMinutes;
            this.major = gd.major;
            this.minor = gd.minor;
        }
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

    public class CredentialsWrapper {
        @AuraEnabled public String databaseName;
        @AuraEnabled public String userName;
        @AuraEnabled public String sessionId;
        @AuraEnabled public String path;

        public CredentialsWrapper(GeoTabAuthJsonToApex authObj) {
            if(authObj != null && authObj.result != null && authObj.result.credentials != null) {
                this.databaseName = authObj.result.credentials.database;
                this.userName = authObj.result.credentials.userName;
                this.sessionId = authObj.result.credentials.sessionId;
                this.path = authObj.result.path;
            }
        }
    }

    public class DeviceStatusInfoWrapper {
        @AuraEnabled public Id serviceResourceId;
        @AuraEnabled public String serviceResourceName;
        @AuraEnabled public GeoTabDeviceStatusInfo statusInfo;
        @AuraEnabled public Double speedMph;


        public DeviceStatusInfoWrapper(GeoTabDeviceStatusInfo gdsi) {
            this.statusInfo = gdsi;
            if(this.statusInfo.speed != null) {
                this.speedMph = calcSpeedMph(this.statusInfo.speed);
            }
        }
    }

    public class ServiceResourceWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String name;
        @AuraEnabled public String deviceId;
        @AuraEnabled public Double lat;
        @AuraEnabled public Double lng;
        @AuraEnabled public Datetime lastKnownLocDate;

        public ServiceResourceWrapper(ServiceResource sr) {
            this.recordId = sr.Id;
            this.name = sr.Name;
            this.deviceId = sr.GeotabId__c;
            this.lat = sr.LastKnownLatitude;
            this.lng = sr.LastKnownLongitude;
            this.lastKnownLocDate = sr.LastKnownLocationDate;
        }
    }
    /**
     * @todo move to utils!
     *
     * @param val xx
     *
     * @return xx
     */
    @TestVisible
    private static Double calcSpeedMph(Double val) {
        Double mph;
        if (val != null) {
            if (val != 0) {
                mph = (val * .621371).setScale(0);
            } else {
                mph = 0;
            }
        }
        return mph;
    }

    private static String unitTestJobsJson = '[{"attributes":{"type":"AsyncApexJob","url":"/services/data/v55.0/sobjects/AsyncApexJob/7075300000mC1rbAAC"},"Id":"7075300000mC1rbAAC","CronTriggerId":"08e53000008UWGeAAO","ApexClassId":"01p8W00000ITfRoQAL","Status":"Queued","ApexClass":{"attributes":{"type":"ApexClass","url":"/services/data/v55.0/sobjects/ApexClass/01p8W00000ITfRoQAL"},"Id":"01p8W00000ITfRoQAL","Name":"GeoTab_Sch_QueueableLocRefresh"},"CronTrigger":{"attributes":{"type":"CronTrigger","url":"/services/data/v55.0/sobjects/CronTrigger/08e53000008UWGeAAO"},"Id":"08e53000008UWGeAAO","CronJobDetailId":"08a53000008UY15AAG","NextFireTime":"2022-09-09T12:59:24.000+0000","StartTime":"2022-09-09T12:58:24.000+0000","CronJobDetail":{"attributes":{"type":"CronJobDetail","url":"/services/data/v55.0/sobjects/CronJobDetail/08a53000008UY15AAG"},"Id":"08a53000008UY15AAG","Name":"GeoTab_Gps_Location_Update_(Every_Minute)-9/9/2022 7:58 AM24"}}}]';

    /**
     * Bogus does nothing.. needed for obsolete lwc in prod that can't be deleted for some reason.
     * @param iLimit xxx
     * @return xx
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllUsers(Integer iLimit) {
        return null;
    }

}