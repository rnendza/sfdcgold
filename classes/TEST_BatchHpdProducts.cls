@isTest
private class TEST_BatchHpdProducts{
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
        }
    }
    /**
     *
     */
    @isTest static void testBatchUpdateHpdAccountTotals12() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Map<Id,Hold_Per_Day_Total__c> mHoldPerDaysTotalsByIds = new Map<Id,Hold_Per_Day_Total__c>([select id from Hold_Per_Day_Total__c]);
            List<String> accountTypes = HpdStatsHelper.hpdTotalAccountSetting.HPD_Account_Types__c.split(',');
            Test.startTest();

            BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly',-12);
            Database.executeBatch(b);

            Test.stopTest();
            //Integer iMonths,Map<String,HpdStats> mHpdStatsByIds, String qType, String frequency)

            //@todo do real calc tests!
        }
    }
    @isTest static void testBatchUpdateHpdAccountTotals3() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Map<Id,Hold_Per_Day_Total__c> mHoldPerDaysTotalsByIds = new Map<Id,Hold_Per_Day_Total__c>([select id from Hold_Per_Day_Total__c]);
            List<String> accountTypes = HpdStatsHelper.hpdTotalAccountSetting.HPD_Account_Types__c.split(',');
            Test.startTest();

            BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly',-3);
            Database.executeBatch(b);

            Test.stopTest();
            //Integer iMonths,Map<String,HpdStats> mHpdStatsByIds, String qType, String frequency)

            //@todo do real calc tests!
        }
    }
    @isTest static void testBatchUpdateHpdAccountTotals2() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Map<Id,Hold_Per_Day_Total__c> mHoldPerDaysTotalsByIds = new Map<Id,Hold_Per_Day_Total__c>([select id from Hold_Per_Day_Total__c]);
            List<String> accountTypes = HpdStatsHelper.hpdTotalAccountSetting.HPD_Account_Types__c.split(',');
            Test.startTest();

            BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly',-2);
            Database.executeBatch(b);

            Test.stopTest();
            //Integer iMonths,Map<String,HpdStats> mHpdStatsByIds, String qType, String frequency)

            //@todo do real calc tests!
        }
    }
    @isTest static void testBatchUpdateHpdAccountTotals1() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Map<Id,Hold_Per_Day_Total__c> mHoldPerDaysTotalsByIds = new Map<Id,Hold_Per_Day_Total__c>([select id from Hold_Per_Day_Total__c]);
            List<String> accountTypes = HpdStatsHelper.hpdTotalAccountSetting.HPD_Account_Types__c.split(',');
            Test.startTest();

            BatchHpdAccountTotals b = new BatchHpdAccountTotals('Monthly',-1);
            Database.executeBatch(b);

            Test.stopTest();
            //Integer iMonths,Map<String,HpdStats> mHpdStatsByIds, String qType, String frequency)

            //@todo do real calc tests!
        }
    }
}