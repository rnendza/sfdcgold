@IsTest
private class TEST_CommunityFilesController {

    public static String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String USERNAME_PORTAL            = 'accelcustomerportal@portal.com';
    public static Integer NUMBER_OF_ACCOUNTS        = 5;
    public static String HQ_ACCOUNT_NAME            = 'HQ  Portal UT Account';
    public static String PROFILE_NAME_PORTAL        = 'Grouped User Community Standard';

    @TestSetup
    static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;

        User setupUser = adminUser;

        System.runAs(setupUser) {
            User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);
            Contact portalContact = [SELECT Id, AccountId FROM Contact WHERE Id = :portalUser.ContactId];
            Account hqAccount = [SELECT Id, HQ_Account__c FROM Account WHERE Id = :portalContact.AccountId];
            hqAccount.HQ_Account__c = true;
            update hqAccount;

            Test.startTest(); // isolate gov limits

            List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni',1);

            List<Account> accounts = new List<Account>();
            for(Municipality__c municipality : municipalities) {
                for(Integer i=0; i<NUMBER_OF_ACCOUNTS; i++) {
                    Account acct = TestUtils.buildAccount('accel test acct:' + i + 'a', municipality.id,
                                                'Accel Account');
                    acct.ParentId = hqAccount.Id;
                    accounts.add(acct);
                    i++;
                }
            }
            insert accounts;
            //--- gotta do the below.. process builder again to the rescue.
            accounts = [ SELECT Id, Accel_VGT_Live_Date__c, Type FROM Account];
            TestUtils.updateAccountsToLiveAccelAccount(accounts);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_getRevenueFiles() {

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Integer iNumDocs = NUMBER_OF_ACCOUNTS + 1;
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (Integer i = 0; i < iNumDocs; i++) {
            contentVersions.add(new ContentVersion (    //  SDFC Black magic.. inserts contentDocument as well.
                    Title = 'Rev_2020.02.23 - 2020.02.29',
                    PathOnClient = '4moreyears.jpg',
                    Description = 'Revenue',
                    VersionData = Blob.valueOf('4 more years 4 more years 4 more years'),
                    IsMajorVersion = true
            ));
        }
        insert contentVersions;

        List<Account> accounts = [SELECT Id FROM Account];
        Map<Id, ContentDocument> documents = new Map<Id, ContentDocument>(
            [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title LIKE 'Rev_%']
        );
        System.assert(!documents.isEmpty());

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for(Account account : accounts ) {
            contentDocumentLinks.add( new ContentDocumentLink(
                    LinkedEntityId = account.Id,
                    ContentDocumentId = documents.values()[0].Id,
                    ShareType =  'V'
            ));
        }
        insert contentDocumentLinks;

        System.runAs(adminUser) {
            Test.startTest();

            List<ContentDocument> revDocuments =
                    Accel_CommunityFilesController.getRevenueFiles( accounts[0].Id, '2020-01-01', '2020-06-01');

            for(ContentDocument cd : revDocuments) {
                System.assert(documents.containsKey(cd.Id));
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void test_getOtherFiles() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Integer iNumDocs = NUMBER_OF_ACCOUNTS + 1;
        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for (Integer i = 0; i < iNumDocs; i++) {
            contentVersions.add(new ContentVersion (   //  SDFC Black magic.. inserts contentDocument as well.
                    Title = 'Analytics_Stuff'+i,
                    PathOnClient = '4moreyears.jpg',
                    Description = 'Analytics_'+i,
                    VersionData = Blob.valueOf('8 more years 8 more years 8 more years'),
                    IsMajorVersion = true
            ));
        }
        insert contentVersions;

        List<Account> accounts = [SELECT Id FROM Account WHERE HQ_Account__c != TRUE];
        Map<Id, ContentDocument> documents = new Map<Id, ContentDocument>(
            [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument WHERE Title LIKE 'Analytics_%']
        );
        System.assert(!documents.isEmpty());

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for(Account account : accounts ) {
            contentDocumentLinks.add( new ContentDocumentLink(
                    LinkedEntityId = account.Id,
                    ContentDocumentId = documents.values()[0].Id,
                    ShareType =  'V'
            ));
        }
        insert contentDocumentLinks;

        System.runAs(adminUser) {
            Test.startTest();

            List<ContentDocumentLink> otherDocumentLinks = Accel_CommunityFilesController.getOtherFiles();

            for(ContentDocumentLink cdl : otherDocumentLinks) {
                System.assert(documents.containsKey(cdl.ContentDocumentId));
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAccounts_ensureHq_found() {
        User portalUser = TestUtils.getPortalUserForTest(PROFILE_NAME_PORTAL, HQ_ACCOUNT_NAME, USERNAME_PORTAL);

        System.runAs(portalUser) {
            Map<Id,Account> mTestAccountsByIds = new Map<Id,Account>([
                    SELECT Id,Name
                    FROM   Account
                    WHERE  Type IN :CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ]);
            Test.startTest();

            ResponseDto dto = Accel_CommunityFilesController.retrieveAccounts();
            List<Account> portalUserAccounts =
                    (List<Account>)dto.values.get(Accel_CommunityFilesController.MAP_KEY_ACCOUNT_LIST);

            Boolean foundHq = false;
            for(Account account : portalUserAccounts){
                System.assert(mTestAccountsByIds.containsKey(account.Id));
                if(account.HQ_Account__c) {
                    foundHq = true;
                }
            }
            System.assert(foundHq);

            Test.stopTest();
        }
    }
}