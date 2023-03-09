@IsTest
private class TEST_QueueableSvcAutomatedNotifications {

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

    @IsTest
    static void test_Queueable_Svc_Automated_Notifications_Positive() {

        System.runAs(uAdmin) {

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
            Set<Id> serviceAppointmentsQualified = new Set<Id>();
            for(Integer i=0; i<=halfOfServiceAppointments; i++ ) {
                ServiceAppointment sa = serviceAppointments[i];
                Test.setCreatedDate(sa.Work_Order__c, yesterday);
                Test.setCreatedDate(sa.Work_Order__r.CaseId, yesterday);
                Test.setCreatedDate(sa.Id, yesterday);
                serviceAppointmentsQualified.add(sa.Id);
            }

            Test.startTest();
            System.enqueueJob(new QueueableSvcAutomatedNotifications());
            Test.stopTest();

            List<Custom_Notifications_Sent__c> customNotificationsSent = [
                    SELECT Id, Service_Appointment__c
                    FROM   Custom_Notifications_Sent__c
                    WHERE  Service_Appointment__c IN :serviceAppointmentsQualified
            ];
            System.assertEquals(customNotificationsSent.size(), serviceAppointmentsQualified.size());
        }
    }
}