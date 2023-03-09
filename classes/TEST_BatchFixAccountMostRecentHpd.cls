@isTest
private class TEST_BatchFixAccountMostRecentHpd {

    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni', 1);
            List<Account> accounts = new List<Account>();
            Integer i = 0;
            for (Municipality__c municipality : municipalities) {
                accounts.add(TestUtils.buildAccount('accel test acct:' + i + 'a', municipality.id, 'Accel Account'));
                accounts.add(TestUtils.buildAccount('accel test acct:' + i + 'b', municipality.id, 'Competitor Account'));
                i++;
            }
            insert accounts;

            //build more hold per days that the standard test util will but for just one of the accounts.
            String rtName = 'Monthly HPD';
            Id rtId = Schema.SObjectType.Hold_Per_Day__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
            List<Hold_Per_Day__c> holdPerDays = new List<Hold_Per_Day__c>();
            Integer iNumPerAcct = 12;
            accounts = [select id from account];

            for (Account account : accounts) {
                Hold_Per_Day__c holdPerDay1 = new Hold_Per_Day__c();
                holdPerDay1.RecordTypeId = rtId;
                holdPerDay1.account__C = account.id;
                holdPerDay1.Date__c = System.today();
                holdPerDay1.VGT_Count__c = 5;
                holdPerDay1.Amount_Played__c = 1 * 1000;
                holdPerDay1.Amount_Won__c = holdPerDay1.Amount_Played__c * .8;
                holdPerDay1.Funds_In__c = holdPerDay1.Amount_Played__c;
                holdPerDay1.Funds_Out__c = holdPerDay1.Amount_Won__c;
                holdPerDay1.hpd__c = holdPerDay1.Funds_In__c - holdPerDay1.funds_out__c;
                holdPerDays.add(holdPerDay1);
                for (Integer x = 0; x < iNumPerAcct; x++) {
                    Hold_Per_Day__c holdPerDay = new Hold_Per_Day__c();
                    holdPerDay.RecordTypeId = rtId;
                    holdPerDay.account__C = account.id;
                    holdPerDay.Date__c = System.today().addMonths(-x);
                    holdPerDay.VGT_Count__c = 5;
                    holdPerDay.Amount_Played__c = x * 1000;
                    holdPerDay.Amount_Won__c = holdPerDay.Amount_Played__c * .8;
                    holdPerDay.Funds_In__c = holdPerDay.Amount_Played__c;
                    holdPerDay.Funds_Out__c = holdPerDay.Amount_Won__c;
                    holdPerDay.hpd__c = holdPerDay.Funds_In__c - holdPerDay.funds_out__c;
                    holdPerDays.add(holdPerDay);
                }
            }
            //============ VERY VERY BAD BUT WE SHOULD HAVE ENOUGH DML STATEMENTS IF WE DON'T DO THOSE THOSE BRITTLE PROCESS BUILDERS GO BOOM!
            //============ insert backwards so the most recent hpd doesn't get jazzed up.
            Integer iNumHpds = holdPerDays.size() - 1;
            for (Integer y = iNumHpds; y >= 0; y--) {
                insert holdPerDays[y];
            }

            List<Hold_Per_Day_Total__c> holdPerDayTotals2 = [SELECT Id from Hold_Per_Day_Total__c];
            delete holdPerDayTotals2;
            HpdStatsHelper.reInitHpdTotals();
        }
    }
    @isTest static void testUpdateAccount() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();

            Id rtIdMonthly = Schema.SObjectType.Hold_Per_Day__c.getRecordTypeInfosByName().get('Monthly HPD').getRecordTypeId();
            Map<Id, Hold_Per_Day__c> mHoldPerDaysByIds = new Map<Id, Hold_Per_Day__c>([select id,account__c,Date__c from Hold_Per_Day__c where recordtypeid = :rtIdMonthly]);
            BatchFixAccountMostRecentHpd b = new BatchFixAccountMostRecentHpd('Monthly HPD',System.today());
            Database.executeBatch(b,20);

            Test.stopTest();
            Set<Id> accountIds = new Set<Id>();
            for(Hold_Per_Day__c hpd : mHoldPerDaysByIds.values()) {
                accountIds.add(hpd.account__c);
            }
            List<Account> accounts = [SELECT Id, Most_Recent_Hold_Per_Day__c FROM Account where ID in :accountIds];
            for(Account account : accounts) {
                system.assert(account.Most_Recent_Hold_Per_Day__c ==   ((Hold_Per_Day__c)mHoldPerDaysByIds.get(account.Most_Recent_Hold_Per_Day__c)).id );
            }
        }
    }
}