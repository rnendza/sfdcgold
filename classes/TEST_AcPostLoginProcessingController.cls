@IsTest
private class TEST_AcPostLoginProcessingController {

    public static String UNAME = 'acceltest@accel.com';
   /**
    * Create Muni Account and License Data and link them together. Creates IGB and State liquor licenses for each
    * account and expires them within 7 days.
    */
    @TestSetup static void setup() {
        List<Municipality__c>   munis       = TestUtils.createMunicipalities('accel test muni',2);
        List<Account>           accounts    = new List<Account>();
        List<License__c>        licenses    = new List<License__c>();

        Id locationRtId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();

        Integer i = 0;
        Date licenseExpDate = Date.today().addDays(7);
        License__c igbLicense           = TestUtils.buildLicense(licenseExpDate,'IGB Gaming License');
        License__c stateLiquorLicense   = TestUtils.buildLicense(licenseExpDate,'State Liquor License');

        for(Municipality__c muni : munis) {
            Account account = TestUtils.buildAccount('test account '+ i, muni.id,'Accel Account');
            account.RecordTypeId = locationRtId;
            account.Accel_VGT_Live_Date__c = Date.today();
            accounts.add(account);
            i++;
        }
        insert accounts;
        accounts = [
                SELECT  Id, Accel_VGT_Live_Date__c,Active_IGB_Gaming_License__c,Active_State_Liquor_License__c
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
            acctIgbLicense.Location__c          = account.Id;
            acctIgbLicense.Active_License__c    = true;
            acctStateLicense.Location__c        = account.Id;
            acctStateLicense.Active_License__c  = true;
            licenses.add(acctIgbLicense);
            licenses.add(acctStateLicense);
        }
        insert licenses; // @see process builder set account active licenses.
    }
    /**
     *
     */
    @IsTest static void test_retrieveExpiredLicenseInfo_Positive() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();

            ResponseDto dto  = AcPostLoginProcessingController.retrieveExpiredLicenseInfo();
            System.assert(dto.isSuccess);

            List<License__c> licenses = (List<License__c>)dto.values
                    .get(AcPostLoginProcessingController.MAP_KEY_LICENSE_WARNINGS);
            AccountLicenseSummary licenseSummary  = (AccountLicenseSummary)dto.values
                    .get(AcPostLoginProcessingController.MAP_KEY_LICENSE_SUMMARY);

            System.assert(!licenses.isEmpty());
            System.assert(licenseSummary.anyExpiredOrExpiring);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest static void test_retrieveExpiredLicenseInfo_Negative_None_Expiring() {
        User u = TestUtils.getUserForTest(UNAME);

        List<License__c> licenses = [
                SELECT  Id, Expiration_Date__c
                FROM    License__c
                WHERE   Active_License__c = TRUE
        ];
        for(License__c license : licenses) {
            license.Expiration_Date__c = license.Expiration_Date__c.addDays(120);
        }
        update licenses;

        System.runAs(u) {

            Test.startTest();

            ResponseDto dto  = AcPostLoginProcessingController.retrieveExpiredLicenseInfo();
            System.assert(!dto.isSuccess);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest static void test_retrieveAccounts_ToManyRows() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();
            Warnings.QueryLimitException qleCaught;
            try {
               AccountSvc.retrieveAccounts(50001);
            } catch (Warnings.QueryLimitException qle) {
                qleCaught = qle;
            }
            System.assert(qleCaught != null);
            Test.stopTest();
        }
    }
}