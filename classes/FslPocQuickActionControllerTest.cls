@IsTest
private class FslPocQuickActionControllerTest {
    public static String ADMINUNAME                             = 'acceltestadmin@accel.com';
    public static String CALLCENTERUNAME                        = 'callcenterdude@dude.com';
    public static  User uCallCenter; /* = AccelTestHarness.getUserForTest( CALLCENTERUNAME );*/



    static {
        uCallCenter = [SELECT Id FROM User WHERE IsActive = TRUE And Profile.Name IN :SvcWatchdogController.noAssignedResourceProfileNames LIMIT 1];
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
            AccelTestHarness.createAllDataToServiceAppointments( params );
            AccelTestHarness.createSvcWatchdogUtilityBarSettings(uCallCenter);
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

    @IsTest
    static void test_retrieveSaCustomNotifications() {
        System.runAs(uCallCenter) {
            Integer iLimitSas = 10;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  Id, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
                    FROM    ServiceAppointment
                    LIMIT   :iLimitSas
            ];
            System.debug('---> test notification sas='+serviceAppointments);
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

            System.debug('---> test notification sas after update ='+serviceAppointments);

            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case WHERE Id IN :caseIds];
            for(Case cse: cases) {
                cse.Assigned_Resource__c = uCallCenter.Id;
            }
            update cases;
            System.debug('---> test notification cases='+cases);

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


            Test.startTest();
                ResponseDto dtoNotifications = FslPocQuickActionController.retrieveSaCustomNotifications(saId);

            Test.stopTest();
        }
    }
}