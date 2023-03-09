@IsTest
private class TEST_LicenseSvc {

    public static String UNAME = 'acceltest@accel.com';
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
    @IsTest static void test_retrieveAccountsExpiredLicenses_Positive() {
        List<Account>       accounts = [SELECT Id FROM Account];
        // retrieve with list of account sObjects
        List<License__c>    expiredLicenses = LicenseSvc.retrieveAccountsExpiredLicenses(accounts);
        System.assert(expiredLicenses.size() > 0);

        for(License__c license : expiredLicenses) {
            System.assert(LicenseSvc.isLicenseExpired(license.Expiration_Date__c));
        }

        //retrieve with list of account ids
        expiredLicenses.clear();
        List<Id> accountIds = new List<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
        }
        expiredLicenses = LicenseSvc.retrieveAccountsExpiredLicenses(accountIds);
        System.assert(expiredLicenses.size() > 0);

        for(License__c license : expiredLicenses) {
            System.assert(LicenseSvc.isLicenseExpired(license.Expiration_Date__c));
        }
        //retrieve with a single account id
        expiredLicenses.clear();
        Id accountId = accounts[0].Id;
        expiredLicenses = LicenseSvc.retrieveAccountExpiredLicenses(accountId);
        System.assert(expiredLicenses.size() > 0);

        for(License__c license : expiredLicenses) {
            System.assert(license.Expiration_Date__c < Date.today());
        }
    }

    /**
     *
     */
    @IsTest static void test_retrieveAccountsExpiringLicenses_Positive() {
        List<Account>       accounts = [SELECT Id FROM Account];
        // retrieve with list of account sObjects
        Integer iNumDaysTillExpiration = 8;
        List<License__c>    expiringLicenses = LicenseSvc.retrieveAccountsExpiringLicenses(accounts,iNumDaysTillExpiration);

        System.assert(expiringLicenses.size() > 0);
        for(License__c license : expiringLicenses) {
            System.assert(!LicenseSvc.isLicenseExpired(license.Expiration_Date__c)
                    && LicenseSvc.isLicenseExpiring(license.Expiration_Date__c,iNumDaysTillExpiration));
        }

        //retrieve with list of account ids
        expiringLicenses.clear();
        List<Id> accountIds = new List<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
        }
        expiringLicenses = LicenseSvc.retrieveAccountsExpiringLicenses(accountIds,iNumDaysTillExpiration);

        System.assert(expiringLicenses.size() > 0);
        for(License__c license : expiringLicenses) {
            System.assert(!LicenseSvc.isLicenseExpired(license.Expiration_Date__c)
                    && LicenseSvc.isLicenseExpiring(license.Expiration_Date__c,iNumDaysTillExpiration));
        }

        //retrieve with a single account id
        expiringLicenses.clear();
        Id accountId = accounts[0].Id;
        expiringLicenses = LicenseSvc.retrieveAccountExpiringLicenses(accountId,iNumDaysTillExpiration);

        System.assert(expiringLicenses.size() > 0);
        for(License__c license : expiringLicenses) {
            System.assert(!LicenseSvc.isLicenseExpired(license.Expiration_Date__c)
                    && LicenseSvc.isLicenseExpiring(license.Expiration_Date__c,iNumDaysTillExpiration));
        }
    }
    /**
     *
     */
    @IsTest static void test_retrieveAccountsExpiringOrExpiredLicenses_Positive() {
        List<Account>       accounts = [SELECT Id FROM Account];
        // retrieve with list of account sObjects
        Integer iNumDaysTillExpiration = 8;
        List<License__c>    expiringLicenses = LicenseSvc.retrieveAccountsExpiringOrExpiredLicenses(accounts,iNumDaysTillExpiration);

        System.assert(expiringLicenses.size() > 0);
        //@TODO Proper asserts
//        for(License__c license : expiringLicenses) {
//            System.assert(license.Expiration_Date__c > Date.today()
//                    && license.Expiration_Date__c < Date.today().addDays(iNumDaysTillExpiration));
//        }

//        //retrieve with list of account ids
//        expiringLicenses.clear();
//        List<Id> accountIds = new List<Id>();
//        for(Account account : accounts) {
//            accountIds.add(account.Id);
//        }
//        expiringLicenses = LicenseSvc.retrieveAccountsExpiringLicenses(accountIds,iNumDaysTillExpiration);
//
//        System.assert(expiringLicenses.size() > 0);
//        for(License__c license : expiringLicenses) {
//            System.assert(license.Expiration_Date__c > Date.today()
//                    && license.Expiration_Date__c < Date.today().addDays(iNumDaysTillExpiration));
//        }
//
//        //retrieve with a single account id
//        expiringLicenses.clear();
//        Id accountId = accounts[0].Id;
//        expiringLicenses = LicenseSvc.retrieveAccountExpiringLicenses(accountId,iNumDaysTillExpiration);
//
//        System.assert(expiringLicenses.size() > 0);
//        for(License__c license : expiringLicenses) {
//            System.assert(license.Expiration_Date__c > Date.today()
//                    && license.Expiration_Date__c < Date.today().addDays(iNumDaysTillExpiration));
//        }
    }

}