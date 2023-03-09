@isTest
private class TEST_ScheduleBatchIncrDemoDataRefresh {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<Municipality__c> municipalities = TestUtils.createMunicipalities('Rockford',1);
            Municipality__c muni = municipalities[0];
            List<Account> realAccounts = new List<Account>();
            List<Account> demoAccounts = new List<Account>();
            Map<String,String> mReal_Demo = DemoUtils.getAccountNameMap();
            Integer iNumPerAccount = 2;
            for(String real : mReal_Demo.keySet()) {
                String demo = mReal_Demo.get(real);
                Account realAccount = TestUtils.buildAccount(real, muni.id,'Other');
                realAccount.Legal_Name__c = 'Portal ';
                Account demoAccount = TestUtils.buildAccount(demo, muni.id,'Other');
                realAccounts.add(realAccount);
                demoAccounts.add(demoAccount);
            }
            insert realAccounts;
            insert demoAccounts;
            List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(realAccounts, iNumPerAccount,'Monthly HPD');
            holdPerDays.addAll(TestUtils.buildAccountHoldPerDays(realAccounts,iNumPerAccount,'Daily HPD'));
            system.debug('about to insert... hold per day num of recs='+holdPerDays);
            insert holdPerDays;
        }
    }
    @isTest static void testScheduleBatch() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            ScheduleBatchIncrementalDemoDataRefresh.scheduleIt(System.now());
            ScheduleBatchIncrementalDemoDataRefresh s = new ScheduleBatchIncrementalDemoDataRefresh();
            String sch1 = '0 0 23 * * ?';
            system.schedule('Test schedule hpd demo data', sch1, s);

            Test.stopTest();
        }
    }

}