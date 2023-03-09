@isTest
private class TEST_CommunityInfoController {

    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP        = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME    = 'mollys unit test';
    public static String PROFILENAMECP  = 'Accel Customer Community';
    public static String ROLENAME       = 'AdminRoleName';

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        User adminUser = TestUtils.createAdminUserWithRole(UNAMEADMIN,ROLENAME);
        system.runAs(adminUser) {
            User user = TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
//            PermissionSet ps =  TestUtils.buildPermissionSet(UserTriggerHandler.PERMISSION_SET_API_NAME, UserTriggerHandler.PERMISSION_SET_API_NAME);
//            insert ps;
        }
    }
    /**
     *
     */
    @isTest static void testRetrieveCommunityReleaseNotesPositive() {

        Integer iNumNotes =10;
        List<Community_Release_Note__c> releaseNotes = new List<Community_Release_Note__c>();

        Schema.DescribeFieldResult majorFieldResult = Community_Release_Note__c.Major_Version__c.getDescribe();
        List<Schema.PicklistEntry> majorValues = majorFieldResult.getPicklistValues();


        for(Integer i = 0; i<iNumNotes; i++) {
            Community_Release_Note__c crn = new Community_Release_Note__c();
            crn.Active__c = true;
            crn.Description__c = 'For those about to rock! '+i;
            crn.Change_Date__c = Date.today();
            crn.Major_Version__c = majorValues[0].getLabel();
            releaseNotes.add(crn);
        }
        insert releaseNotes;

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();

            ResponseDto dto = Accel_CommunityInfoController.retrieveCommunityReleaseNotes();
            List<Community_Release_Note__c> notes = (List<Community_Release_Note__c>)dto.values
                    .get(Accel_CommunityInfoController.MAP_KEY_RELEASE_NOTES);

            System.assertEquals(notes.size(),iNumNotes);

            Test.stopTest();
        }
    }
    @isTest static void testRetrieveTermsOfUseText() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();

            ResponseDto dto = Accel_CommunityInfoController.retrieveTermsOfUse();
            system.assert(dto.isSuccess);
            String text =  (String)dto.values.get(Accel_CommunityInfoController.MAP_KEY_TERM_OF_USE_TEXT);
            system.assert( text != null && text !='' );

            Test.stopTest();
        }
    }
    @isTest static void testPrivacyText() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();

            ResponseDto dto = Accel_CommunityInfoController.retrievePrivacy();
            system.assert(dto.isSuccess);
            String text =  (String)dto.values.get(Accel_CommunityInfoController.MAP_KEY_PRIVACY_TEXT);
            system.assert( text != null && text !='' );

            Test.stopTest();
        }
    }
    @isTest static void  retrieveUserContact_Positive() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();

            ResponseDto dto = Accel_CommunityInfoController.retrieveUserContact();
            system.assert(dto.isSuccess);

            Contact contact =  (Contact)dto.values.get(Accel_CommunityInfoController.MAP_KEY_CONTACT);
            system.assert( contact!= null);
            system.assert( contact.Id == communityUser.contactId);

            Test.stopTest();
        }
    }
    /**
     * @TODO this is failing. we are in SFDC Bizarro world here..
     */
    @isTest static void  retrieveUserContact_Negative() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username,IsPortalEnabled  from user where id = :communityUser.id];
//        communityUser.isPortalEnabled = false;
//        update communityUser;
//        List<Contact> contacts = [SELECT ID from Contact where id = :communityUser.contactId];
//        delete contacts;
        System.runAs(communityUser) {

            Test.startTest();

            ResponseDto dto = Accel_CommunityInfoController.retrieveUserContact();
//            system.assert(!dto.isSuccess);
//            system.assert(dto.severity == 'error');
            Test.stopTest();
        }
    }
    @isTest static void  updateContactTermsAcceptance_Positive() {
        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();
            //set the date.
            ResponseDto dto = Accel_CommunityInfoController.updateContactTermsAcceptance(true);
            system.assert(dto.isSuccess);
            Contact contact =  (Contact)dto.values.get(Accel_CommunityInfoController.MAP_KEY_CONTACT);
            system.assert( contact!= null);
            system.assert( contact.Id == communityUser.contactId);
            system.assert( contact.Community_Terms_Accepted_Date__c != null);

            //null out the date
            dto = Accel_CommunityInfoController.updateContactTermsAcceptance(false);
            system.assert(dto.isSuccess);
            contact = null;
            contact =  (Contact)dto.values.get(Accel_CommunityInfoController.MAP_KEY_CONTACT);
            system.assert( contact!= null);
            system.assert( contact.Id == communityUser.contactId);
            system.assert( contact.Community_Terms_Accepted_Date__c == null);

            Test.stopTest();
        }
    }
}