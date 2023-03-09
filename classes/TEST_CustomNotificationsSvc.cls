@IsTest
private class TEST_CustomNotificationsSvc{

    public static String ADMINUNAME                             = 'acceltestadmin@accel.com';
    public static String CALLCENTERUNAME                        = 'callcenterdude@dude.com';
    public static  User uCallCenter = TestUtils.getUserForTest( CALLCENTERUNAME );


    static {
        List<Profile> profiles = [SELECT Id from Profile where Name in :SvcWatchdogController.noAssignedResourceProfileNames];
        uCallCenter.profileId = profiles[0].id;
        update uCallCenter;
    }

    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * service appointments and ties them all together.
     */
    @testSetup static void setup() {

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
            Test.stopTest();
        }
    }

    /**
     * Uses the apex service (as opposed to auto launched flow to send the custom notifications)
     */
    @IsTest
    static void test_sendNotifications_Positive() {
        System.runAs(uCallCenter) {
            Integer iLimitSas = 10;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  Id, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
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
            List<SvcWatchdogWrapper> wraps =
                    (List<SvcWatchdogWrapper>) dto.values.get(SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);
            System.assert(dto.isSuccess);

            SvcWatchdogWrapper firstWrap = wraps[0];
            System.debug('====> firstWrap='+firstWrap);

            Test.startTest();

            String apiName = 'TEST_SERVICE_WATCHDOG_NOTIFICATION';
            String saId = firstWrap.serviceAptId;
            String assignedResourceId = firstWrap.assignedResourceId;

            Set<String> recipientIds  = new Set<String> { assignedResourceId };
            Id targetId = saId;
            String msgTitle = 'Test msg title', msgBody = 'Test msg body';
            String alertType = 'NOT_DISPATCHED', notificationType = 'Automated';

            Custom_Notifications_Sent__c notificationSent1 = CustomNotificationsSvc.sendNotification
                    (recipientIds, targetId, apiName, alertType, notificationType,msgTitle, msgBody );

            Custom_Notifications_Sent__c notificationSent2 = CustomNotificationsSvc.sendNotification
                    (recipientIds, null, apiName, alertType, notificationType,msgTitle, msgBody );

            list<Custom_Notifications_Sent__c> notificationsSent = new list<Custom_Notifications_Sent__c>{notificationSent1,notificationSent2};

            insert notificationsSent;

            List<Custom_Notifications_Sent__c> testNotificationsSent = [
                    SELECT Id, Service_Appointment__c FROM Custom_Notifications_Sent__c
            ];

            System.assertEquals(testNotificationsSent.size(), 2);

            Boolean foundSa = false, foundNull = false;
            for(Custom_Notifications_Sent__c sent : testNotificationsSent) {
                if(sent.Service_Appointment__c == saId) foundSa = true;
                if(sent.Service_Appointment__c == null) foundNull = true;
            }
            System.assert(foundSa);
            System.assert(foundNull);

            Test.stopTest();
        }
    }


    /**
     *
     */
    @IsTest
    static void test_retrieveNotificationsSent_Positive() {

        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            Integer iLimitSas = 12;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  Id, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
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
            List<SvcWatchdogWrapper> wraps =
                    (List<SvcWatchdogWrapper>) dto.values.get(SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);
            System.assert(dto.isSuccess);

            SvcWatchdogWrapper firstWrap = wraps[0];
            System.debug('====> firstWrap='+firstWrap);

            Test.startTest();

            //--- fire the flow to create SA related notifications
            String apiName = 'TEST_SERVICE_WATCHDOG_NOTIFICATION' , alertType = 'NO_ASSIGNED_RESOURCE';
            String saId = firstWrap.serviceAptId;
            String assignedResourceId = firstWrap.assignedResourceId;

            Map<String, Object> params = new Map<String, Object>();
            params.put('varInputAlertType',alertType);
            params.put('varInputOutputCustomNotificationApiName',apiName);
            params.put('varInputOutputServiceAppointmentId',saId);
            params.put('varInputOutputAssignedResourceId',assignedResourceId);
            System.debug('---->>> firing flow with params='+params);

            Flow.Interview.flow_ServiceAppointment_Alerts flow = new Flow.Interview.flow_ServiceAppointment_Alerts(params);
            flow.start();
            System.debug('---->> flow output='+flow);

            Boolean sendResult = (Boolean)flow.getVariableValue('varOutputSendResult');
            System.assert(sendResult);

            List<Custom_Notifications_Sent__c> notifications =
                    CustomNotificationsSvc.retrieveNotificationsSent('ServiceAppointment',saId);

            for(Custom_Notifications_Sent__c notificationsSent : notifications) {
                System.assertEquals(notificationsSent.User__c, uCallCenter.Id);
            }

            Test.stopTest();
        }
    }
}