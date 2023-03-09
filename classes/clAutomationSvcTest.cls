@IsTest
private class clAutomationSvcTest {

    public static String UNAME = 'acceltest@accel.com';

   /**
    * NOTE start / stop test merely there to reset gov limits as creating non cl data takes forever given
    * all the processors / flows and eventually will bust cpu time outs on it's own.
    */
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }



    @IsTest
    static void test_Account_Delete() {
        User u = TestUtils.getUserForTest(UNAME);

        List<Route__c> routes = clTESTUTILS.createRoutes(1,1);
        List<Route_Schedule__c> routeSchedules = clTESTUTILS.createRouteSchedules(routes,Date.today()+1,Date.today(),u.Id);

        System.runAs(u) {

            Test.startTest();


            //=== (1) delete of account with no restrictions.
            String name = 'Test New Account With Bufu Billing City';
            Account account = TestUtils.buildAccount(name,null,'Accel Account');
            account.BillingStreet = '123 spring';account.BillingCity = 'Bufu';account.BillingState = '';
            account.BillingCountry = 'Egypt';account.BillingPostalCode = '234243';
            insert account;

            delete account;
            System.assert([SELECT Id FROM Account WHERE Name = :name].isEmpty());


            //=== (2) delete of account with RPS children.
            account = TestUtils.buildAccount(name,null,'Accel Account');
            account.BillingStreet = '123 spring';account.BillingCity = 'Bufu';account.BillingState = '';
            account.BillingCountry = 'Egypt';account.BillingPostalCode = '234243';
            insert account;

            Route_Processing_Sheet__c rps = new Route_Processing_Sheet__c(Account__c = account.Id,Route_Schedule__c = routeSchedules[0].Id);
            insert rps;

            DmlException dmlEx;
            try {
                delete account;
            } catch (DmlException ex) {
                dmlEx = ex;
            }
            System.assert(dmlEx != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveScheduleMetadatas() {
        User u = TestUtils.getUserForTest(UNAME);

        List<Route__c> routes = clTESTUTILS.createRoutes(1,1);
        List<Route_Schedule__c> routeSchedules = clTESTUTILS.createRouteSchedules(routes,Date.today()+1,Date.today(),u.Id);

        System.runAs(u) {

            Test.startTest();

            List<Cash_Logistics_Schedule_Setting__mdt> mdts = clAutomationSvc.retrieveScheduleMetadatas(TRUE);


            Test.stopTest();
        }
    }
}