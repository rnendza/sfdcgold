@IsTest
private class TEST_HoldPerDayTrigger{
//    // @deprecated replace with BatchHpdMonthlyImport for CPU Timeout issues.

    public static String UNAME = 'acceltest@accel.com';
//    /**
//     *  Sets up a bunch of a test muni,account,hold per day etc. data.
//     */
    @TestSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TestUtils.createTestHoldPerDays();
        }
    }
    /**
     * Just enough so we can deploy the commented out trigger.
     */
    @IsTest static void touchTrigger() {
        Id rtId = Hold_Per_Day__c.SObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getRecordTypeId();
        Account account = [SELECT Id FROM Account LIMIT 1];
        Hold_Per_Day__c hpd = new Hold_Per_Day__c(RecordTypeId=rtId, Date__c =Date.today(), Account__c = account.Id);
        insert hpd;
    }
//    /**
//     * Created 205 hold per days for each of 6 accounts and endure upon insert their parent Account.Most_Recent_Hpd__c is correct.
//     */
//    @IsTest static void testUpdateMostRecentHoldPerDayOnAccount_Positive() {
//        User u = TestUtils.getUserForTest(UNAME);
//        System.runAs(u) {
//            List<Account> accounts = [SELECT Id, Most_Recent_Hold_Per_Day__c FROM Account];
//            List<Hold_Per_Day__c> holdPerDays = [SELECT Id FROM Hold_Per_Day__c];
//            // Get rid of setup data hold per days and refs on Account.Most_Recent_Hold_Per_Day__c.
//            delete  holdPerDays;
//            for(Account account : accounts) {
//                account.Most_Recent_Hold_Per_Day__c = null;
//            }
//            update accounts;
//            Integer iNumPerAccount = 50;
//            String rtName = 'Monthly HPD';
//            holdPerDays = TestUtils.buildAccountHoldPerDays(accounts, iNumPerAccount, rtName);
//
//            Test.startTest();
//
//
//            insert holdPerDays;
//            //-- bad but there will only be a couple of accounts.
//            Map<Id,Hold_Per_Day__c> mAccountPerLatestHpd = new Map<Id,Hold_Per_Day__c>();
//            for(Account account : accounts) {
//                Hold_Per_Day__c latestHpd = [
//                        SELECT  Id, CreatedDate
//                        FROM    Hold_Per_Day__c
//                        WHERE   Account__c = :account.Id
//                        ORDER BY CreatedDate DESC LIMIT 1
//                ];
//                mAccountPerLatestHpd.put(account.Id,latestHpd);
//            }
//
//            Test.stopTest();
//            // give extra time for processes / flows / inevitable recursion.
//            accounts = [SELECT Id, Most_Recent_Hold_Per_Day__c FROM Account WHERE Id IN:accounts];
//            for(Account account : accounts) {
//                system.debug('-- rjn account='+account);
//                system.debug('--- rjn mrhd='+mAccountPerLatestHpd.get(account.id));
//                System.assert(account.Most_Recent_Hold_Per_Day__c == mAccountPerLatestHpd.get(account.Id).Id);
//            }
//        }
//    }
}