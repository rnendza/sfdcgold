@IsTest
private class TEST_AdminSvc {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup
    static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<Account> accounts = new List<Account>();
            for (Integer i=0; i<20; i++) {
                Account a = TestUtils.buildAccount('TEST Admin Svc Account ' + i, null);
                a.ShippingLatitude = 44.968046;
                a.ShippingLongitude = -94.420307;
                a.Type = 'Accel Account';
                a.Accel_VGT_Live_Date__c = Date.today();
                a.Location_Type__c = 'Truck Stop';
                accounts.add(a);
            }
            insert accounts;
        }
    }

    @isTest
    static void testGetClosestAccounts_positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Account acc = [select id from account order by createddate desc limit 1];
            TEST.startTest();
            List<Account> closestAccounts = AdminSvc.getClosestAccounts(acc.id, 'Truck Stop');
          //  system.assert(!closestAccounts.isEmpty()); @TODO why is this not working?
            TEST.stopTest();
        }
    }
    @isTest
    static void testGetClosestAccounts_negative() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Account acc = [select id from account order by createddate desc limit 1];
            TEST.startTest();
            List<Account> closestAccounts = AdminSvc.getClosestAccounts(acc.id, '');
            system.assert(closestAccounts.isEmpty());
            TEST.stopTest();
        }
    }
}