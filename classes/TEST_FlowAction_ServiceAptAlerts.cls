@IsTest
private class TEST_FlowAction_ServiceAptAlerts {

    public static String ADMINUNAME                             = 'acceltestadmin@accel.com';
    public static String CALLCENTERUNAME                        = 'callcenterdude@dude.com';
    public static final String SVC_WATCHDOG_PERM_SET_API_NAME   = 'Service_Watchdog_Component_Access';
    public static final String SVC_WATCHDOG_PERM_SET_LABEL      = 'Service Watchdog Component Access';

    public static  User uCallCenter = TestUtils.getUserForTest( CALLCENTERUNAME );
    public static  User uAdmin      = TestUtils.getUserForTest( ADMINUNAME );


    static {
        List<Profile> profiles = [SELECT Id from Profile where Name in :SvcWatchdogController.noAssignedResourceProfileNames];
        uCallCenter.profileId = profiles[0].id;
        update uCallCenter;
    }

    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * service appointments and ties them all together.
     */
    @testSetup
    static void setup() {

        System.runAs(uCallCenter) {
            Test.startTest();  //merely to reset gov limits to get around cpu time
            TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
            TestUtils.createAllDataToServiceAppointments( params );
            TestUtils.createSvcWatchdogUtilityBarSettings(uCallCenter);
            List<Account> accounts = [SELECT Id, ShippingStreet, ShippingCity, ShippingState FROM Account ];
            Integer i = 0;
            for(Account account :accounts) {
                account.ShippingStreet = '123 xyz - '+i;
                account.ShippingCity   = 'Chicago - '+i;
                account.ShippingState  = 'IL';            //  Be careful of we implement state / country picklists!
            }
            update accounts;
            // Can't so as of Spring 2020  TestUtils.createPermissionSetAndAssignment(  SVC_WATCHDOG_PERM_SET_LABEL,SVC_WATCHDOG_PERM_SET_API_NAME,uCallCenter.Id );
            Test.stopTest();
        }
        //Move to be created by the running user which will be system admin (Spring 2020 PSA Insert Fix)
        TestUtils.createPermissionSetAndAssignment(  SVC_WATCHDOG_PERM_SET_LABEL,SVC_WATCHDOG_PERM_SET_API_NAME,uCallCenter.Id );
    }
    /**
     *
     */
    @IsTest
    static void test_fireNotDispatchedServiceCallsAlerts_Manual_Positive() {

        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            Integer iLimitSas = 12;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
                    FROM    ServiceAppointment
                    LIMIT   :iLimitSas
            ];
            Set<Id> caseIds = new Set<Id>();
            if(serviceAppointments.size() < iLimitSas) {
                iLimitSas = serviceAppointments.size();
            }
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
                caseIds.add(serviceAppointment.Work_Order__r.CaseId);
            }
            update serviceAppointments;

            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case WHERE Id IN :caseIds];
            for(Case cse: cases) {
                cse.Assigned_Resource__c = uCallCenter.Id;
            }
            update cases;

            Datetime yesterday = Datetime.now().addDays(-1);
            Integer halfOfServiceAppointments = iLimitSas/2;
            for(Integer i=0; i<=halfOfServiceAppointments; i++ ) {
                ServiceAppointment sa = serviceAppointments[i];
                Test.setCreatedDate(sa.Work_Order__c, yesterday);
                Test.setCreatedDate(sa.Work_Order__r.CaseId, yesterday);
                Test.setCreatedDate(sa.Id, yesterday);
            }


            ResponseDto dto = SvcWatchdogController.retrieveNotDispatched();
            System.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> notDispatchedWrapsAlerts = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);

            System.debug(LoggingLevel.INFO,'---> dto alerts= '+notDispatchedWrapsAlerts);
            String apiName = 'TEST_SERVICE_WATCHDOG_NOTIFICATION';
            CustomNotificationType customNotificationType = CustomNotificationsSvc.retrieveNotificationType(apiName);
            System.assert(customNotificationType != null);

            Test.startTest();

            if(notDispatchedWrapsAlerts != null && !notDispatchedWrapsAlerts.isEmpty() ) {
                for(SvcWatchdogWrapper wrap : notDispatchedWrapsAlerts) {
                    if(wrap.assignedResourceId != null) {
                        System.debug(LoggingLevel.INFO,'-----> fire flow as nothing was sent yet!');
                        String notificationType = 'Manual';
                        Flow.Interview.flow_ServiceAppointment_Alerts flow = fireFlow('NO_ASSIGNED_RESOURCE',notificationType,wrap);
                        System.debug('----> flow='+flow);
                        Boolean sendResult = (Boolean)flow.getVariableValue('varOutputSendResult');
                        System.assert(sendResult);

                        List<Custom_Notifications_Sent__c> notifications =
                                CustomNotificationsSvc.retrieveNotificationsSent('ServiceAppointment',wrap.serviceAptId);

                        for(Custom_Notifications_Sent__c notificationSent : notifications) {
                            System.debug('----> notificationSent: '+notificationSent);
                            //System.assertEquals(notificationSent.User__c, uCallCenter.Id);
                            //@todo uncomment after new version of flow is deployed
                            // System.assertEquals(notificationSent.Notification_Type__c, notificationType);
                        }
                    }
                }
            }

            Test.stopTest();
        }
    }
    /**
      *
      */
    @IsTest
    static void test_fireNotDispatchedServiceCallsAlerts_Manual_Negative_Invalid_AssignedResource() {

        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            Integer iLimitSas = 12;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
                    FROM    ServiceAppointment
                    LIMIT   :iLimitSas
            ];
            Set<Id> caseIds = new Set<Id>();
            if(serviceAppointments.size() < iLimitSas) {
                iLimitSas = serviceAppointments.size();
            }
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
                caseIds.add(serviceAppointment.Work_Order__r.CaseId);
            }
            update serviceAppointments;

            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case WHERE Id IN :caseIds];
            for(Case cse: cases) {
                cse.Assigned_Resource__c = uCallCenter.Id;
            }
            update cases;

            Datetime yesterday = Datetime.now().addDays(-1);
            Integer halfOfServiceAppointments = iLimitSas/2;
            for(Integer i=0; i<=halfOfServiceAppointments; i++ ) {
                ServiceAppointment sa = serviceAppointments[i];
                Test.setCreatedDate(sa.Work_Order__c, yesterday);
                Test.setCreatedDate(sa.Work_Order__r.CaseId, yesterday);
                Test.setCreatedDate(sa.Id, yesterday);
            }


            ResponseDto dto = SvcWatchdogController.retrieveNotDispatched();
            System.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> notDispatchedWrapsAlerts = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);

            System.debug(LoggingLevel.INFO,'---> dto alerts= '+notDispatchedWrapsAlerts);
            String apiName = 'TEST_SERVICE_WATCHDOG_NOTIFICATION';
            CustomNotificationType customNotificationType = CustomNotificationsSvc.retrieveNotificationType(apiName);
            System.assert(customNotificationType != null);

            Test.startTest();

            if(notDispatchedWrapsAlerts != null && !notDispatchedWrapsAlerts.isEmpty() ) {
                for(SvcWatchdogWrapper wrap : notDispatchedWrapsAlerts) {
                    if(wrap.assignedResourceId != null) {
                        wrap.assignedResourceId = null;
                        String notificationType = 'Manual';
                        Flow.Interview.flow_ServiceAppointment_Alerts flow = fireFlow('NO_ASSIGNED_RESOURCE',notificationType,wrap);
                        Boolean sendResult = (Boolean)flow.getVariableValue('varOutputSendResult');
                        System.assert(!sendResult);
                    }
                }
            }

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void test_fireNotDispatchedServiceCallsAlerts_Automated_Positive() {

        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            Integer iLimitSas = 12;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
                    FROM    ServiceAppointment
                    LIMIT   :iLimitSas
            ];
            Set<Id> caseIds = new Set<Id>();
            if(serviceAppointments.size() < iLimitSas) {
                iLimitSas = serviceAppointments.size();
            }
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
                caseIds.add(serviceAppointment.Work_Order__r.CaseId);
            }
            update serviceAppointments;

            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case WHERE Id IN :caseIds];
            for(Case cse: cases) {
                cse.Assigned_Resource__c = uCallCenter.Id;
            }
            update cases;

            Datetime yesterday = Datetime.now().addDays(-1);
            Integer halfOfServiceAppointments = iLimitSas/2;
            for(Integer i=0; i<=halfOfServiceAppointments; i++ ) {
                ServiceAppointment sa = serviceAppointments[i];
                Test.setCreatedDate(sa.Work_Order__c, yesterday);
                Test.setCreatedDate(sa.Work_Order__r.CaseId, yesterday);
                Test.setCreatedDate(sa.Id, yesterday);
            }


            ResponseDto dto = SvcWatchdogController.retrieveNotDispatched();
            System.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> notDispatchedWrapsAlerts = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);

            System.debug(LoggingLevel.INFO,'---> dto alerts= '+notDispatchedWrapsAlerts);
            String apiName = 'TEST_SERVICE_WATCHDOG_NOTIFICATION';
            CustomNotificationType customNotificationType = CustomNotificationsSvc.retrieveNotificationType(apiName);
            System.assert(customNotificationType != null);

            Test.startTest();

            if(notDispatchedWrapsAlerts != null && !notDispatchedWrapsAlerts.isEmpty() ) {
                for(SvcWatchdogWrapper wrap : notDispatchedWrapsAlerts) {
                    if(wrap.assignedResourceId != null && wrap.customNotificationsSent == null || wrap.customNotificationsSent.isEmpty()) {
                        System.debug(LoggingLevel.INFO,'-----> fire flow as nothing was sent yet!');
                        String notificationType = 'Automated';
                        Flow.Interview.flow_ServiceAppointment_Alerts flow = fireFlow('NO_ASSIGNED_RESOURCE',notificationType,wrap);
                        System.debug('----> flow='+flow);
                        Boolean sendResult = (Boolean)flow.getVariableValue('varOutputSendResult');
                        System.assert(sendResult);

                        List<Custom_Notifications_Sent__c> notifications =
                                CustomNotificationsSvc.retrieveNotificationsSent('ServiceAppointment',wrap.serviceAptId);

                        for(Custom_Notifications_Sent__c notificationSent : notifications) {
                         //   System.assertEquals(notificationSent.User__c, uCallCenter.Id);
                            //@todo uncomment after new version of flow is deployed
                             //System.assertEquals(notificationSent.Notification_Type__c, notificationType);
                        }
                    }
                }
            }

            Test.stopTest();
        }
    }
    /**
     * @param alertType
     * @param notificationType
     * @param wrap
     */
    private static Flow.Interview.flow_ServiceAppointment_Alerts fireFlow(String alertType, String notificationType, SvcWatchdogWrapper wrap) {
        //--- fire the flow to create SA related notifications
        String apiName = 'TEST_SERVICE_WATCHDOG_NOTIFICATION';
        String saId = wrap.serviceAptId;
        String assignedResourceId = wrap.assignedResourceId;

        Map<String, Object> params = new Map<String, Object>();
        params.put('varInputAlertType',alertType);
        params.put('varInputOutputNotificationType',notificationType);
        params.put('varInputOutputCustomNotificationApiName',apiName);
        params.put('varInputOutputServiceAppointmentId',saId);
        params.put('varInputOutputAssignedResourceId',assignedResourceId);
        System.debug('---->>> firing flow with params='+params);

        Flow.Interview.flow_ServiceAppointment_Alerts flow = new Flow.Interview.flow_ServiceAppointment_Alerts(params);
        flow.start();
        return flow;
    }

}