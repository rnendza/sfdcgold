@isTest
private class TEST_CommunityPerformanceController {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'mollys unit test';
    public static String PROFILENAMECP  = 'Accel Customer Community';
    public static String ROLENAME       = 'AdminRoleName';

    /**
     * Setup test data.
     * @TODO Refactor into generic TEST Util!
     */
    @testSetup static void setup() {
        User adminUser = TestUtils.createAdminUserWithRole(UNAMEADMIN,ROLENAME);

        system.runAs(adminUser) {

            Account account = TestUtils.updateCommunityAccountWithTypeandIGBLicenseNumber(PROFILENAMECP,ACCOUNTNAME,UNAMECP);

            License__c license = TestUtils.buildGenericIgbLicense(account.Id);
            insert license;
            account.active_igb_gaming_license__C = license.id;
            update account;

            List<Asset> assets = new List<Asset>();
            Asset ass1 = TestUtils.buildAsset('ass1',account.id,'VGT');
            Asset ass2 = TestUtils.buildAsset('ass2',account.id,'VGT');
            assets.add(ass1);assets.add(ass2);
            insert assets;

            List<Hold_Per_Day__c> holdPerDaysAssets = TestUtils.buildAssetHoldPerDays(assets, 2,'Daily HPD');
            insert holdPerDaysAssets;

        }

    }
    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void testRetieveAccounts() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();

            ResponseDto dto = Accel_CommunityPerformanceController.retrieveAccounts();
            List<Account> accounts = (List<Account>) dto.values.get(Accel_CommunityPerformanceController.MAP_KEY_ACCOUNT_LIST);


            Test.stopTest();
        }
    }

    /**
     * @TODO Real asserts! This is Weak ass testing..
     */
    @isTest static void testRetrieveHoldPerDayByAccount() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {
            Test.startTest();
            Date dStartDate = System.today().addDays(-14);
            Date dEndDate = System.today();
            String sStartDate = JSON.serialize(dStartDate);
            String sEndDate = JSON.serialize(dEndDate);

            ResponseDto dto = Accel_CommunityPerformanceController.retrieveHoldPerDayByAccount(
                    communityUser.accountId,sStartDate,sEndDate );


            Test.stopTest();
        }
    }

    /**
    * @TODO Real asserts! This is Weak ass testing..
    */
    @isTest static void testRetrieveHoldPerDayByAccountsMonthlyAggregates() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();

            Date dStartDate = System.today().addDays(-14);
            Date dEndDate = System.today();
            String sStartDate = JSON.serialize(dStartDate);
            String sEndDate = JSON.serialize(dEndDate);

            ResponseDto dto = Accel_CommunityPerformanceController.retrieveHoldPerDayByAccountsMonthlyAggregates(new List<Id>{
                    communityUser.accountId
            }, sStartDate, sEndDate);

            Test.stopTest();
        }
    }
    @isTest static void testRetrieveDataExportSetting() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();
            //---- TEST Abstracted retrieve in app
            ResponseDto dto = Accel_CommunityPerformanceController.retrieveMachineDataExportSettings();
            system.assert(dto.isSuccess);
            system.assert( ! ( (List<String>)dto.values.get(Accel_CommunityPerformanceController.MACHINE_EXPORT_FIELD_NAMES)).isEmpty() );

            //---- TEST Basic retrieval;
            String settingName = 'MachineExport', fieldName='Export_Field_Names__c';
            Object o = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName,fieldName);
            String delimitedString = (String)o;
            List<String> fieldNames = delimitedString.split('~');
            system.assert( !fieldNames.isEmpty() );

            Test.stopTest();
        }
    }
}