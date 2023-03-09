@IsTest
private class TEST_BatchAccountBrandingUpdater {

    public static String ADMINUNAME = 'acceltestadmin@accel.com';
    public static User uAdmin = TestUtils.getUserForTest(ADMINUNAME);

    @testSetup
    static void setup() {

        System.runAs(uAdmin) {
            Test.startTest();

            List<Municipality__c> munis = TestUtils.createMunicipalities('muni name', 1);
            Account account = TestUtils.buildAccount('account name', munis[0].id);
            account.ShippingStreet = '4916 Main Street Unit 2';
            account.ShippingCity = 'Lisle';
            account.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
            account.ShippingPostalCode = '60532';
            account.ShippingCountry = 'US';
            account.ShippingLatitude = 41.795778000000000;
            account.ShippingLongitude = -88.075013000000000;
            insert account;

            Region__c region = new Region__c(Name= 'Region 1',State__c = 'IL');
            insert region;

            County__c county = new County__c(Name = 'DuPage',State__c = 'IL', Covaid_Region__c = region.Id);
            insert county;

            munis = TestUtils.createMunicipalities('muni GA name', 1);
            Municipality__c muni = munis[0];
            muni.State__c = 'GA';
            update muni;

            Account account2 = TestUtils.buildAccount('account name', muni.id);
            account2.ShippingStreet = '123 Spring Rd';
            account2.ShippingCity = 'Atlanta';
            account2.ShippingState = 'GA';  //  Be careful of we implement state / country picklists!
            account2.ShippingPostalCode = '30301';
            account2.ShippingCountry = 'US';
            insert account2;

            List<Account> accounts = [SELECT  Id, Branding__c FROM Account];
            for(Account accountx : accounts) {
                accountx.Branding__c = null;
            }
            update accounts;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_Batch_Account_Branding_Updater_Positive() {

        System.runAs(uAdmin) {

            Test.startTest();
            BatchAccountBrandingUpdater b = new BatchAccountBrandingUpdater();
            Database.executeBatch(b,20);

            List<Account> accounts = [SELECT Id FROM Account];
            Map<Id,String> mErrorsByIds = new Map<Id,String>();
            for(Account account : accounts) {
                mErrorsByIds.put(account.Id,'Bogus error');
            }
            b.buildCsvAttachmentAllErrors('error_csv_name',mErrorsByIds);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_Batch_Account_Branding_Updater_RollItBack() {
        Test.startTest();
        BatchAccountBrandingUpdater b = new BatchAccountBrandingUpdater(true);
        Database.executeBatch(b,20);
        Test.stopTest();
    }

    @IsTest
    static void test_Batch_Account_Branding_Updater_Log_Existing() {

        System.runAs(uAdmin) {

            Test.startTest();

            String jobName = 'BatchAccountBrandingUpdater';
            String rtDevName ='Salesforce_Jobs';
            Id rtId =  SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName().get(rtDevName).getRecordTypeId();
            Accel_Application_Error__c log = new Accel_Application_Error__c(RecordTypeId = rtId, Job_Name__c = jobName);
            insert log;
            BatchAccountBrandingUpdater b = new BatchAccountBrandingUpdater();
            Database.executeBatch(b,20);
            Test.stopTest();

        }
    }

}