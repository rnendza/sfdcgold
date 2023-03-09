@IsTest
private class TEST_BatchVGTSoftwareToAsset{

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static Date CURRENT_DATE_OVERRIDE    = Date.today();

    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_IR_LINES = 5;
    public static final Integer NUMBER_OF_MUNIS = 2;
    public static final Integer NUMBER_OF_ACCTS_PER_MUNI = 2;
    public static final Integer NUMBER_OF_ASSETS_PER_ACCT = 10;

    @TestSetup
    static void setup() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Date TODAY = CURRENT_DATE_OVERRIDE;

        System.runAs(adminUser) {

            Schema.DescribeFieldResult assetSoftwareDr = Asset.Software__c.getDescribe();
            List<Schema.PicklistEntry> assetSoftwarePlEntries = assetSoftwareDr.getPicklistValues();


            List<Municipality__c> munis = TestUtils.createMunicipalities('UT MUNI', NUMBER_OF_MUNIS);
            List<Account> accounts = new List<Account>();
            List<Asset> assets = new List<Asset>();
            Integer z = 0;
            for (Municipality__c municipality : munis) {
                for (Integer i = 0; i < NUMBER_OF_ACCTS_PER_MUNI; i++) {
                    Account account = TestUtils.buildAccount('accel test acct:' + z + 'a', municipality.id,
                            'Accel Account');
                    account.ShippingState = 'IL';
                    accounts.add(account);
                    z++;
                }
            }
            insert accounts;
            String rtDevName = 'VGT';
            for (Account account : accounts) {
                for(Integer i=0; i < NUMBER_OF_ASSETS_PER_ACCT; i++) {
                    Asset asset = TestUtils.buildAsset('UT ' + account.Name + ' ' +i+ ' TEST VGT ASSET',
                                    account.Id, rtDevName);
                    //get a random entry
                    Schema.PicklistEntry ple = assetSoftwarePlEntries[i];
                    asset.Software__c = ple.value;
                    assets.add(asset);
                }
            }
           // insert assets;
        }
    }

    @IsTest
    static void test_fireBatch_VGT_SoftwareToAsset_Rollback() {

        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Boolean bCommit = false;

        List<ASset> swAssets = [SELECT Id FROM Asset WHERE RecordType.Name = 'Software'];
        if(!swAssets.isEmpty()) {
            delete swAssets;
        }

        System.runAs(adminUser) {
            Test.startTest();
                //TEST rollback
                BatchVGTSoftwareToAsset b = new BatchVGTSoftwareToAsset(null,bCommit);
                Database.executeBatch(b);
            Test.stopTest();

//            swAssets = [SELECT Id FROM Asset WHERE RecordType.Name = 'Software'];
            //System.assert(swAssets.isEmpty());
        }
    }
}