@isTest
private class TEST_BatchHpdInitLegacyDemoData {
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
                Account realAccount = TestUtils.buildAccount(real, muni.id,'Accel Account');

                Account demoAccount = TestUtils.buildAccount(demo, muni.id,'Other');
                demoAccount.Legal_Name__c = 'Portal Dummy Account';
                realAccounts.add(realAccount);
                demoAccounts.add(demoAccount);
            }
            insert realAccounts;

            insert demoAccounts;
            //---- defeat the process builder!
            for(Account realAccount : realAccounts) {
                realAccount.Accel_VGT_Live_Date__c = Date.today();
                realAccount.Type = 'Accel Account';
            }
            update realAccounts;

            //---- defeat the process builder!
            for(Account demoAccount : demoAccounts) {
                demoAccount.Type = 'Accel Account';
            }
            update demoAccounts;

            List<Hold_Per_Day__c> allHoldPerDays = new List<Hold_Per_Day__c>();

            List<Hold_Per_Day__c> monthlyHoldPerDays = TestUtils.buildAccountHoldPerDays(realAccounts, iNumPerAccount,'Monthly HPD');
            allHoldPerDays.addAll(monthlyHoldPerDays);
            List<Hold_Per_Day__c> dailyHoldPerDays =  TestUtils.buildAccountHoldPerDays(realAccounts,iNumPerAccount,'Daily HPD');
            allHoldPerDays.addAll(dailyHoldPerDays);

            system.debug('about to insert... hold per day num of recs='+allHoldPerDays);
            insert allHoldPerDays;
        }
    }

    /**
     *
     */
    @isTest static void test_BatchHpdInitLegacyDemoData_NotIncremental() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();
            BatchHpdInitLegacyDemoData b = new BatchHpdInitLegacyDemoData(false,false);
            Database.executeBatch(b);
            Test.stopTest();

            List<Hold_Per_Day__c> demoDailyHpds = [
                    SELECT  Id,Date__c,Account__r.Name
                    FROM    Hold_Per_Day__c
                    WHERE   Account__r.Legal_Name__c = 'Portal Dummy Account'
                    And     RecordType.Name = 'Daily HPD'];
            System.assert( !demoDailyHpds.isEmpty() );

            List<Hold_Per_Day__c> demoMonthlyHpds = [
                    SELECT  Id,Date__c,Account__r.Name
                    FROM    Hold_Per_Day__c
                    WHERE   Account__r.Legal_Name__c = 'Portal Dummy Account'
                    And     RecordType.Name = 'Monthly HPD'];
            System.assert( !demoMonthlyHpds.isEmpty() );
        }
    }
    /**
     *
     */
    @isTest static void test_BatchHpdInitLegacyDemoData_Incremental_YesterdayMonthlyHpds() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            //  Get rid of all dailies for a cleaner test.
            List<Hold_Per_Day__c> dailys =  [
                    SELECT  Id, CreatedDate
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.DeveloperName = 'Daily_HPD'];
            delete dailys;

            //  Set the Created Date of the monthlies to Yesterday
            List<Hold_Per_Day__c> monthlyHoldPerDays = [
                    SELECT  Id, CreatedDate,Current_Credits__c,Municipality_Share__c,Net_Wager__c,NTI__c,State_Share__c
                    FROM    Hold_Per_Day__c
                    WHERE   RecordType.DeveloperName = 'Monthly_HPD'
                    AND     Account__r.Legal_Name__c != 'Portal Dummy Account'
            ];
            //--- fill in missing fields / artificially set the create date. 
            for(Hold_Per_Day__c hpd : monthlyHoldPerDays) {
                hpd.Municipality_Share__c = 1;
                hpd.State_Share__c = 1;
                hpd.Net_Wager__c = 1;
                hpd.NTI__c = 1;
                hpd.Current_Credits__c = 1;
                TEST.setCreatedDate(hpd.id,DateTime.newInstance(Date.today().year(),Date.today().month(),
                        Date.today().day() - 1,0,0,0));
            }
            update monthlyHoldPerDays;

            Test.startTest();
            BatchHpdInitLegacyDemoData b = new BatchHpdInitLegacyDemoData(false,true);
            Database.executeBatch(b);
            Test.stopTest();


            List<Hold_Per_Day__c> demoMonthlyHpds = [
                    SELECT  Id,Date__c,Account__r.Name
                    FROM    Hold_Per_Day__c
                    WHERE   Account__r.Legal_Name__c = 'Portal Dummy Account'
                    AND     RecordType.Name = 'Monthly HPD'];

            System.assert( !demoMonthlyHpds.isEmpty() );
            System.assert( monthlyHoldPerDays.size() == demoMonthlyHpds.size());
        }
    }
    /**
     *
     */
    @isTest static void test_BatchHpdInitLegacyDemoData_Incremental() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            BatchHpdInitLegacyDemoData b = new BatchHpdInitLegacyDemoData(false,true);
            Database.executeBatch(b);
            Test.stopTest();

            List<Hold_Per_Day__c> demoDailyHpds = [
                    SELECT  Id,Date__c,Account__r.Name
                    FROM    Hold_Per_Day__c
                    WHERE   Account__r.Legal_Name__c = 'Portal Dummy Account'
                    And     RecordType.Name = 'Daily HPD'];
            System.assert( !demoDailyHpds.isEmpty() );

            List<Hold_Per_Day__c> demoMonthlyHpds = [
                    SELECT  Id,Date__c,Account__r.Name
                    FROM    Hold_Per_Day__c
                    WHERE   Account__r.Legal_Name__c = 'Portal Dummy Account'
                    And     RecordType.Name = 'Monthly HPD'];
            System.assert( !demoMonthlyHpds.isEmpty() );
            for(Hold_Per_Day__c hpd : demoMonthlyHpds) {
                System.debug('rjn monthly='+hpd);
                System.debug('rjn name='+hpd.Account__r.Name);
            }
        }
    }
}