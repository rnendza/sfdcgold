/**
 * SvcWatchdogController provides the UI Toolbar with backend information about Cases, Work Orders and
 * Services Appointments.
 */
public class SvcWatchdogController {

    public static final String MAP_KEY_WATCHDOG_WRAPPERS_REJECTED = 'WATCHDOG_WRAPPERS_REJECTED';
    public static final String MAP_KEY_WATCHDOG_WRAPPERS_REJECTED_OBSERVE = 'WATCHDOG_WRAPPERS_REJECTED_OBSERVE';
    public static final String MAP_KEY_CRON_TRIGGERS = 'WATCHDOG_CRON_TRIGGERS';

    public static final String MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT = 'WATCHDOG_NOT_DISPATCHED_ALERT';
    public static final String MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_OBSERVE = 'WATCHDOG_NOT_DISPATCHED_OBSERVE';

    public static final String MAP_KEY_WATCHDOG_WRAPPERS_ALERT = 'WATCHDOG_WRAPPERS_TO_ALERT';
    public static final String MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE = 'WATCHDOG_WRAPPERS_TO_OBSERVE';

    public static final String MAP_KEY_SVC_UTILITY_MDT_NO_AR = 'WATCHDOG_UTILITY_MDT_NO_ASSIGNED_RESOURCE';
    public static final String MAP_KEY_SVC_UTILITY_MDT_NOT_DISPATCHED = 'WATCHDOG_UTILITY_MDT_NOT_DISPATCHED';
    public static final String MAP_KEY_USER_PROFILE_DATA = 'USER_PROFILE_DATA';
    public static final String MAP_KEY_SVC_WATCHDOG_UTILITY_SETTINGS = 'WATCHDOG_UTILITY_SETTINGS';

    public static final String META_SETTING_NAME_NO_AR = 'No_Assigned_Resource';
    public static final String META_SETTING_NAME_REJECTED = 'Rejected';
    // --- NOTE THE BELOW SETTING NAME WAS NAMED Incorrect (too late to change now)
    public static final String META_SETTING_NAME_UNACCEPTED_NOT_DISPATCHED = 'Accepted_But_Not_En_route';

    //  Get configurable metadata.
    public static Svc_Utility_Bar_Settings__mdt utilityArMdt;
    public static Svc_Utility_Bar_Settings__mdt utilityRejectedMdt;
    public static Svc_Utility_Bar_Settings__mdt utilityUnacceptedNotDispatched;

    public static Boolean ALLOW_AUTOMATED_CUSTOM_NOTIFICATIONS = false;  // @todo move to custom meta

    public static String noAssignedResourceStatusToWatch;
    public static List<String> noAssignedResourceProfileNames;
    public static String noAssignedResourceCreatedByOverride;

    public static String rejectedStatusToWatch;
    public static List<String> rejectedProfileNames;
    public static String rejectedCreatedByOverride;
    public static Integer rejectedCreatedDateNbrOfDays = 0;

    static {
        utilityArMdt = (Svc_Utility_Bar_Settings__mdt) CustomMetadataSvc.retrieveCustomSearchMeta(
                Svc_Utility_Bar_Settings__mdt.getSObjectType(), META_SETTING_NAME_NO_AR);

        utilityRejectedMdt = (Svc_Utility_Bar_Settings__mdt) CustomMetadataSvc.retrieveCustomSearchMeta(
                Svc_Utility_Bar_Settings__mdt.getSObjectType(), META_SETTING_NAME_REJECTED);

        utilityUnacceptedNotDispatched = (Svc_Utility_Bar_Settings__mdt) CustomMetadataSvc.retrieveCustomSearchMeta(
                Svc_Utility_Bar_Settings__mdt.getSObjectType(), META_SETTING_NAME_UNACCEPTED_NOT_DISPATCHED);

        noAssignedResourceStatusToWatch = utilityArMdt.Status_To_Watch__c;
        noAssignedResourceProfileNames = utilityArMdt.Profile_Names_to_Watch__c.split(',');
        noAssignedResourceCreatedByOverride = utilityArMdt.Case_Created_Override__c;

        rejectedStatusToWatch = utilityRejectedMdt.Status_To_Watch__c;
        rejectedProfileNames = utilityRejectedMdt.Profile_Names_to_Watch__c.split(',');
        rejectedCreatedByOverride = utilityRejectedMdt.Case_Created_Override__c;

        if (utilityRejectedMdt.Rejected_Created_Date_Nbr_of_Days__c != null) {
            rejectedCreatedDateNbrOfDays = Integer.valueOf(utilityRejectedMdt.Rejected_Created_Date_Nbr_of_Days__c);
        }
    }
    /**
     * Runs a query to determine if the user has the proper permission set to view the watchdog.
     *
     * @param permissionSetApiName
     * @return true if the user has the permission set, otherwise false.
     */
    @AuraEnabled (Cacheable=true)
    public static Boolean isUserInPermissionSet(String permissionSetApiName) {
        return PermissionSetSvc.isUserInPermissionSet(permissionSetApiName);
    }
    /**
     * (1)Queries ALL cases that are in progress, with a created date >= YESTERDAY,  that have no Case.Assigned_Resource__c.
     * (2)Queries Rejected Service Appointments
     * (3)Queries Not Dispatched Service Appointments.
     * Combines these into Alert and Observe Collections and returns to the client.
     *
     * @return a ResponseDto containing a list of SvcWatchdogWrappers of Observes and Alerts.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveCasesMissingAssignedResourcesCacheable() {
        return retrieveCasesMissingAssignedResources();
    }
    /**
     * (1)Queries ALL cases that are in progress, with a created date >= YESTERDAY,  that have no Case.Assigned_Resource__c.
     * (2)Queries Rejected Service Appointments
     * (3)Queries Not Dispatched Service Appointments.
     * Combines these into Alert and Observe Collections and returns to the client.
     *
     * @return a ResponseDto containing a list of SvcWatchdogWrappers of Observes and Alerts.
     */
    @AuraEnabled //intentionally not made cacheable.
    public static ResponseDto retrieveCasesMissingAssignedResources() {

        ResponseDto dto = new ResponseDto();
        List<SvcWatchdogWrapper> wrapsToAlert = new List<SvcWatchdogWrapper>();
        List<SvcWatchdogWrapper> wrapsToObserve = new List<SvcWatchdogWrapper>();

        Integer iMaxAgeOfCaseMinutes = Integer.valueOf(utilityArMdt.Max_Age_of_Cases__c);
        //Integer iMaxAgeOfCaseMinutes = 0;

        List<Case> cases = [
                SELECT Id, Status, CreatedDate, Age_of_Case_Hours__c, Service_Region__c, CaseNumber, Description,
                        LastModifiedDate, LastModifiedBy.Name,
                        Case.Tech_Notes__c,Location_DBA__r.Name,Account__r.name,
                        Work_Type__c,Work_Type__r.Name, Work_Order__r.Case.Status,
                        AccountId, Account.DBA_Account_Name__c,Account.ShippingCity,Account.ShippingStreet,Account.ShippingState
                FROM Case
                WHERE Status = :noAssignedResourceStatusToWatch
                AND CreatedDate >= YESTERDAY
                AND Assigned_Resource__c = NULL
                AND (CreatedBy.Profile.Name IN :noAssignedResourceProfileNames
                OR CreatedBy.Name LIKE :noAssignedResourceCreatedByOverride )
                ORDER BY Age_of_Case_Hours__c DESC
        ];
        if (!cases.isEmpty()) {
            dto.isSuccess = true;
            for (Case cse : cases) {
                if (cse.Age_of_Case_Hours__c >= iMaxAgeOfCaseMinutes) {
                    wrapsToAlert.add(new SvcWatchdogWrapper(cse));
                } else {
                    wrapsToObserve.add(new SvcWatchdogWrapper(cse));
                }
            }
        }
        ResponseDto dtoRejected = retrieveRejectedServiceCalls();
        dto.technicalMsg += dtoRejected.technicalMsg;
        if (dtoRejected.isSuccess) {
            dto.isSuccess = true;
        }
        List<SvcWatchdogWrapper> wrapsRejected = (List<SvcWatchdogWrapper>) dtoRejected.values
                .get(MAP_KEY_WATCHDOG_WRAPPERS_REJECTED);
        List<SvcWatchdogWrapper> wrapsRejectedObserve = (List<SvcWatchdogWrapper>) dtoRejected.values
                .get(MAP_KEY_WATCHDOG_WRAPPERS_REJECTED_OBSERVE);
        if (wrapsRejected != null && !wrapsRejected.isEmpty()) {
            wrapsToAlert.addAll(wrapsRejected);
        }
        if (wrapsRejectedObserve != null && !wrapsRejectedObserve.isEmpty()) {
            wrapsToObserve.addAll(wrapsRejectedObserve);
        }
        ResponseDto dtoNotDispatched = retrieveNotDispatched();
        if (dtoNotDispatched.isSuccess) {
            dto.isSuccess = true;
        }
        List<SvcWatchdogWrapper> wrapsNotDispatchedObserve = (List<SvcWatchdogWrapper>) dtoNotDispatched.values
                .get(MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_OBSERVE);
        List<SvcWatchdogWrapper> wrapsNotDispatchedAlert = (List<SvcWatchdogWrapper>) dtoNotDispatched.values
                .get(MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);
        if (wrapsNotDispatchedAlert != null && !wrapsNotDispatchedAlert.isEmpty()) {
            wrapsToAlert.addAll(wrapsNotDispatchedAlert);
        }
        if (wrapsNotDispatchedObserve != null && !wrapsNotDispatchedObserve.isEmpty()) {
            wrapsToObserve.addAll(wrapsNotDispatchedObserve);
        }
        if (!wrapsToAlert.isEmpty()) {
            SvcWatchdogWrapper.sortBy = SvcWatchdogWrapper.SORT_BY.ByCaseAgeSeconds;
            wrapsToAlert.sort();
        }
        if (!wrapsToObserve.isEmpty()) {
            SvcWatchdogWrapper.sortBy = SvcWatchdogWrapper.SORT_BY.ByCaseAgeSeconds;
            wrapsToObserve.sort();
        }
        if (wrapsToObserve.isEmpty() && wrapsToAlert.isEmpty()) {
            dto.technicalMsg = 'No in progress cases to alert or observe: ' + System.now();
            dto.isSuccess = false;
        }
        dto.values.put(MAP_KEY_WATCHDOG_WRAPPERS_ALERT, wrapsToAlert);
        dto.values.put(MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE, wrapsToObserve);
        dto.values.put(MAP_KEY_SVC_UTILITY_MDT_NO_AR, utilityArMdt);
        dto.values.put(MAP_KEY_SVC_UTILITY_MDT_NOT_DISPATCHED, utilityUnacceptedNotDispatched );
        return dto;
    }

    /**
     * Find all service appointments rejected.
     * @return a ResponseDto with ServiceAppointment sObjects if any.
     *
     * Note: for lack of any detailed reqs .. This is based on this this report:
     * https://accelentertainment.lightning.force.com/lightning/r/Report/00O1I000006dE0ZUAU/edit
     * If that is wrong. this is wrong.
     */
    @AuraEnabled //intentionally not made cacheable.
    public static ResponseDto retrieveRejectedServiceCalls() {
        ResponseDto dto = new ResponseDto();
        List<SvcWatchdogWrapper> wrapsToAlert = new List<SvcWatchdogWrapper>();
        List<SvcWatchdogWrapper> wrapsToObserve = new List<SvcWatchdogWrapper>();

        Date createdDate = Date.today().addDays(rejectedCreatedDateNbrOfDays);
        Integer iMaxAgeOfCaseMinutes = Integer.valueOf(utilityArMdt.Max_Age_of_Cases__c);
        //Date                        createdDate    = Date.today().addDays(7);
        List<ServiceAppointment> serviceAppointments = [
                SELECT Id, AccountId, Account.DBA_Account_Name__c,Account.ShippingCity,Account.ShippingStreet,Account.ShippingState,
                        AppointmentNumber, Status, Account.Accel_VGT_Live_Date__c,Pending_Acceptance_Time__c,Time_Accepted__c,
                        LastModifiedDate, LastModifiedBy.Name,
                        Work_Order__c, Solution_Notes__c,Work_Order__r.Case.Work_Type__c,
                        Work_Order__r.Case.Assigned_Resource__c,Work_Order__r.Case.Assigned_Resource__r.Name,
                        Work_Order__r.Case.Assigned_Resource__r.MobilePhone,Work_Order__r.Case.Assigned_Resource__r.Phone,
                        Work_Order__r.Status, Work_Order__r.CaseId,
                        Work_Order__r.Case.Case_Status__c,Work_Order__r.Case.CreatedDate,
                        Work_Order__r.Case.Status,
                        Work_Order__r.Case.CaseNumber,Work_Order__r.Case.Service_Region__c,
                        Work_Order__r.Case.Description,Work_Order__r.Case.Age_of_Case_Hours__c,
                        Work_Order__r.Case.Tech_Notes__c,Work_Order__r.WorkOrderNumber,
                        Work_Order__r.Case.LastModifiedDate,Work_Order__r.Case.LastModifiedBy.Name
                FROM    ServiceAppointment
                WHERE   Status = :rejectedStatusToWatch
                AND     Work_Order__r.Case.Status = :noAssignedResourceStatusToWatch
                AND     Work_Order__r.Case.Assigned_Resource__c = NULL
                AND     CreatedDate >= :createdDate
                AND     (CreatedBy.Profile.Name IN :rejectedProfileNames
                OR      CreatedBy.Name LIKE :rejectedCreatedByOverride )

                ORDER BY Work_Order__r.Case.Age_of_Case_Hours__c DESC
        ];
        if (!serviceAppointments.isEmpty()) {
            dto.isSuccess = true;

            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                SvcWatchdogWrapper sa = new SvcWatchdogWrapper(serviceAppointment);
                sa.notificationReason = 'Rejected';
                if (serviceAppointment.Work_Order__r.Case.Age_of_Case_Hours__c >= iMaxAgeOfCaseMinutes) {
                    wrapsToAlert.add(sa);
                } else {
                    wrapsToObserve.add(sa);
                }
            }
        } else {
            dto.technicalMsg = 'No in rejected service appointments: ' + System.now();
        }
        dto.values.put(MAP_KEY_WATCHDOG_WRAPPERS_REJECTED, wrapsToAlert);
        dto.values.put(MAP_KEY_WATCHDOG_WRAPPERS_REJECTED_OBSERVE, wrapsToObserve);
        return dto;
    }
    /**
     *
     * ie. Unaccepted / Not Dispatched
     * @return
     */
    @AuraEnabled
    public static ResponseDto retrieveNotDispatched() {
        ResponseDto dto = new ResponseDto();
        List<SvcWatchdogWrapper> wrapsToAlert = new List<SvcWatchdogWrapper>();
        List<SvcWatchdogWrapper> wrapsToObserve = new List<SvcWatchdogWrapper>();
        //String                      sScheduledStatues       = 'Scheduled';
        Set<String> sStatusesToFind = new Set<String>{
                'Scheduled', 'None'
        };

        Date createdDate = Date.today().addDays(-1);
        Integer iMaxAgeOfAcceptMinutes = Integer.valueOf(utilityArMdt.Max_Age_of_Cases__c);


        List<ServiceAppointment> serviceAppointments = [
                SELECT Id, AccountId, Account.DBA_Account_Name__c, Account.ShippingCity,Account.ShippingStreet,Account.ShippingState,
                        AppointmentNumber, Status,Time_Accepted__c,Account.Accel_VGT_Live_Date__c,Pending_Acceptance_Time__c,
                        LastModifiedDate, LastModifiedBy.Name,
                        Work_Order__r.Case.Assigned_Resource__c,Work_Order__r.Case.Assigned_Resource__r.Name,
                        Work_Order__r.Case.Assigned_Resource__r.MobilePhone,Work_Order__r.Case.Assigned_Resource__r.Phone,
                        Work_Order__c, Solution_Notes__c,Work_Order__r.Case.Work_Type__c,
                        Work_Order__r.Status, Work_Order__r.CaseId,
                        Work_Order__r.Case.Status,Work_Order__r.Case.CreatedDate,
                        Work_Order__r.Case.CaseNumber,Work_Order__r.Case.Service_Region__c,
                        Work_Order__r.Case.Description,Work_Order__r.Case.Age_of_Case_Hours__c,
                        Work_Order__r.Case.Tech_Notes__c,Work_Order__r.WorkOrderNumber,
                        Work_Order__r.Case.LastModifiedDate,Work_Order__r.Case.LastModifiedBy.Name,
                        //  -- Custom notification enhancement
                        ( SELECT    Id,Custom_Notification_Api_Name__c,CreatedDate,Alert_Type__c, CreatedBy.Name,
                                    User__c, User__r.Name, Msg_Title__c, Notification_Type__c
                            FROM    Custom_Notifications_Sent__r
                         ORDER BY   CreatedDate DESC )
                FROM ServiceAppointment
                WHERE Status IN :sStatusesToFind
                AND CreatedDate >= :createdDate
                AND (CreatedBy.Profile.Name IN :rejectedProfileNames
                OR CreatedBy.Name LIKE :rejectedCreatedByOverride )
                AND Work_Order__r.Case.Status != 'Closed'
                ORDER BY Work_Order__r.Case.Age_of_Case_Hours__c DESC
        ];
        if (!serviceAppointments.isEmpty()) {
            for (ServiceAppointment serviceAppointment : serviceAppointments) {
                if (serviceAppointment.Pending_Acceptance_Time__c >= iMaxAgeOfAcceptMinutes) {
                    SvcWatchdogWrapper sa = new SvcWatchdogWrapper(serviceAppointment);
                    sa.notificationReason = 'Unaccepted / Not Dispatched';
                    wrapsToAlert.add(sa);
                    System.debug('adding not dispatched to alerts');
                } else {
                    SvcWatchdogWrapper sa = new SvcWatchdogWrapper(serviceAppointment);
                    sa.notificationReason = 'Unaccepted / Not Dispatched';
                    wrapsToObserve.add(sa);
                    System.debug('adding not dispatched to observes');
                }
            }
            if(!wrapsToAlert.isEmpty()) {
                if(ALLOW_AUTOMATED_CUSTOM_NOTIFICATIONS) {
                  //  fireAutomatedCustomNotifications(wrapsToAlert);
                }
            }
            if (!wrapsToAlert.isEmpty() || !wrapsToObserve.isEmpty()) {
                dto.isSuccess = true;
            }
        } else {
            dto.technicalMsg = 'No service appoints that are not dispatched: ' + System.now();
        }
        dto.values.put(MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT, wrapsToAlert);
        dto.values.put(MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_OBSERVE, wrapsToObserve);
        return dto;
    }
    /**
     * Returns the running user Profile Data as well as SvcWatchdog utility bar custom settings.
     * @return a ResponseDTO Containing a Profile sObject and a Service_Utility_Bar_Config__c custom setting.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveRunningUserData() {
        ResponseDto dto = new ResponseDto();
        Profile profile = UserSvc.retrieveProfileById(UserInfo.getProfileId());
        dto.isSuccess = profile != null ? true : false;
        dto.values.put(MAP_KEY_USER_PROFILE_DATA, profile);

        Service_Utility_Bar_Config__c configSetting = CustomSettingsSvc.getSvcUtilityBarConfig(UserInfo.getUserId());
        dto.values.put(MAP_KEY_SVC_WATCHDOG_UTILITY_SETTINGS, configSetting);
        User user = new User();
        user.Username = UserInfo.getUserName();
        user.Email = UserInfo.getUserEmail();
        dto.values.put('USER',user);

        return dto;
    }
    /**
     * @param jobName   The name of the CronJobDetail record.
     * @return          A responseDto containing the the scheduled record if found, otherwise empty.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveNotificationSchedulingInfo( String jobName ) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' Looking for jobName = '+jobName;

        List<CronTrigger> cronTriggers = [
                SELECT  Id,CronExpression,StartTime,EndTime,NextFireTime,PreviousFireTime,State,TimesTriggered,
                        CronJobDetail.Name,CronJobDetail.Id,CronJobDetail.JobType
                FROM    CronTrigger
                where   CronJobDetail.Name LIKE :jobName + '%'
        ];
        dto.values.put(MAP_KEY_CRON_TRIGGERS,cronTriggers);
        dto.isSuccess = !cronTriggers.isEmpty();
        return dto;
    }

}