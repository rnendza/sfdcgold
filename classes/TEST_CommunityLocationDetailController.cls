@IsTest
private class TEST_CommunityLocationDetailController {

    public static String UNAMECP        = 'accelcustomerportal@portal.com';

    /**
     * Create Muni Account and License Data and link them together.
     * Creates IGB and State liquor licenses for each account and expires them within 7 days.
     * Created IBA License for each account that is expired.
     */
    @TestSetup static void setup() {
        List<Municipality__c>   munis       = TestUtils.createMunicipalities('accel test muni',2);
        List<Account>           accounts    = new List<Account>();
        List<License__c>        licenses    = new List<License__c>();

        Id locationRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();

        Date licenseExpDate = Date.today().addDays(7);
        License__c igbLicense           = TestUtils.buildLicense(licenseExpDate,'IGB Gaming License');
        License__c stateLiquorLicense   = TestUtils.buildLicense(licenseExpDate,'State Liquor License');
        License__c ibaLicense           = TestUtils.buildLicense(   Date.today().addDays(-2),
                'Illinois Business Authorization');
        Integer i = 0;
        for(Municipality__c muni : munis) {
            Account account = TestUtils.buildAccount('test account '+ i, muni.id,'Accel Account');
            account.RecordTypeId = locationRtId;
            account.Accel_VGT_Live_Date__c = Date.today();
            accounts.add(account);
            i++;
        }
        insert accounts;
        accounts = [
                SELECT  Id, Accel_VGT_Live_Date__c
                FROM    Account
                WHERE   Id IN :accounts
        ];
        for(Account account : accounts) {
            account.Accel_VGT_Live_Date__c = Date.today();
            account.Type = 'Accel Account';
        }
        update accounts;

        for(Account account : accounts) {
            License__c acctIgbLicense           = igbLicense.clone(false);
            License__c acctStateLicense         = stateLiquorLicense.clone(false);
            License__c acctIbaLicense           = ibaLicense.clone(false);
            acctIgbLicense.Location__c          = account.Id;
            acctIgbLicense.Active_License__c    = true;
            acctStateLicense.Location__c        = account.Id;
            acctStateLicense.Active_License__c  = true;
            acctIbaLicense.Location__c          = account.Id;
            acctIbaLicense.Active_License__c    = true;
            licenses.add(acctIgbLicense);
            licenses.add(acctStateLicense);
            licenses.add(acctIbaLicense);
        }
        insert licenses; // @see process builder set account active licenses.
    }
    /**
     *
     */
    @IsTest
    static void test_RetrieveAccountLicenses_Positive() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            //---(1) Test Wraps ------
            ResponseDto dto = Accel_CommunityLocationDetailController.retrieveAccountLicenses();

            List<Accel_CommunityLocationDetailController.AccountLicenseWrapper> wraps =
                    (List<Accel_CommunityLocationDetailController.AccountLicenseWrapper>)
                            dto.values.get(Accel_CommunityLocationDetailController.MAP_KEY_ACCOUNT_LICENSE_WRAPPERS);
            System.assert(dto.isSuccess);
            List<Account> allUnitTestAccounts = [
                    SELECT  Id
                    FROM    Account
            ];
            System.assertEquals(wraps.size(),allUnitTestAccounts.size());
            //---(2) Test Summary
            AccountLicenseSummary licenseSummary = (AccountLicenseSummary) dto.values
                    .get(Accel_CommunityLocationDetailController.MAP_KEY_ACCOUNT_LICENSE_SUMMARY);
            System.assert(licenseSummary.anyExpiredOrExpiring);

            //  TEST WE GOT A VGT LIVE DATE TO DISPLAY
            for(Accel_CommunityLocationDetailController.AccountLicenseWrapper wrap: wraps) {
                System.assert(wrap.accelVgtLiveDate != null);
            }
        }
    }
    /**
     *
     */
    @IsTest
    static void test_RetrieveAccountLicenses_NoData() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        List<Account> accounts = [SELECT ID FROM Account];
        delete accounts;
         System.runAs(communityUser) {
            ResponseDto dto = Accel_CommunityLocationDetailController.retrieveAccountLicenses();
            System.assert(!dto.isSuccess);
        }
    }
}