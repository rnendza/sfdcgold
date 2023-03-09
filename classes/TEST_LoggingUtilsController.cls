@IsTest
private class TEST_LoggingUtilsController {

    public static String UNAMEADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String UNAMECP                = 'accelcustomerportal@portal.com';
    public static String ACCOUNTNAME            = 'Blah Random UT Account';
    public static String PROFILENAMECP          = 'Accel Customer Community';

    @TestSetup static void setup() {
        UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
        insert adminRole;
        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        adminUser = [SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id];
        adminUser.UserRoleId = adminRole.Id;
        update adminUser;
        User setupUser = adminUser;

        System.runAs(setupUser) {
            TestUtils.getPortalUserForTest(PROFILENAMECP, ACCOUNTNAME, UNAMECP);
        }
    }
    /**
     *  Tests AccelLoggingUtilsController.logErrorMsg. (Positive) for non community stuff.
     *
     *  (1)  Test that we got a successful response and the technicalMsg shows we got back part of the passed errorMsg.
     *  (2)  Test that we only got 1 error back.
     *  (3)  Test that User__c associated with the error is the running user.
     *  (4)  Test that the RecordType was written as Salesforce_CRM;
     */
    @IsTest static void test_logErrorMessage_Salesforce_CRM_Positive() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();
            String sBogusJson = JSON.serialize(communityUser);
            ResponseDto logDto = Accel_LoggingUtilsController.logErrorMessage(sBogusJson,null);
            //--(1)  Test that we got a successful response and the technicalMsg shows we got back part of the passed errorMsg.
            System.assert(logDto.isSuccess);
            System.assert(logDto.technicalMsg.contains(communityUser.username));

            List<Accel_Application_Error__c> errors = [
                SELECT  Id, Stack_Trace__c, User__c,RecordTypeId,RecordType.DeveloperName
                FROM    Accel_Application_Error__c
                WHERE   User__c = :communityUser.Id
            ];
            System.debug(errors);
            //--(2)  Test that we only got 1 error back.
            System.assert(errors.size() == 1);
            Accel_Application_Error__c error = errors[0];
            //--(3)  Test that User__c associated with the error is the running user.
            System.assertEquals(error.User__c,communityUser.Id);
            //--(4)  Test that the RecordType was written as Salesforce_CRM;
            System.assert(error.RecordType.DeveloperName == Accel_LoggingUtilsController.APP_ERROR_LOG_RT_Salesforce_CRM_DEVNAME);

            Test.stopTest();
        }
    }
    /**
     *  Tests AccelLoggingUtilsController.logErrorMsg. (Positive) for non community stuff.
     *
     *  (1)  Test that we got a successful response and the technicalMsg shows we got back part of the passed errorMsg.
     *  (2)  Test that we only got 1 error back.
     *  (3)  Test that User__c associated with the error is the running user.
     *  (4)  Test that the RecordType was written as Community;
     */
    @IsTest static void test_logErrorMessage_Community_Positive() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();
            String sBogusJson = JSON.serialize(communityUser);
            String recordTypeId =  SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName()
                    .get(Accel_LoggingUtilsController.APP_ERROR_LOG_RT_COMMUNITY_DEVNAME).getRecordTypeId();

            ResponseDto logDto = Accel_LoggingUtilsController.logErrorMessage(sBogusJson,recordTypeId);
            //--(1)  Test that we got a successful response and the technicalMsg shows we got back part of the passed errorMsg.
            System.assert(logDto.isSuccess);
            System.assert(logDto.technicalMsg.contains(communityUser.username));

            List<Accel_Application_Error__c> errors = [
                    SELECT  Id, Stack_Trace__c, User__c,RecordTypeId,RecordType.DeveloperName
                    FROM    Accel_Application_Error__c
                    WHERE   User__c = :communityUser.Id
            ];
            System.debug(errors);
            //--(2)  Test that we only got 1 error back.
            System.assert(errors.size() == 1);
            Accel_Application_Error__c error = errors[0];
            //--(3)  Test that User__c associated with the error is the running user.
            System.assertEquals(error.User__c,communityUser.Id);
            //--(4)  Test that the RecordType was written as Salesforce_CRM;
            System.assert(error.RecordType.DeveloperName == Accel_LoggingUtilsController.APP_ERROR_LOG_RT_COMMUNITY_DEVNAME);

            Test.stopTest();
        }
    }
    /**
     *  Tests AccelLoggingUtilsController.logErrorMsg. (Negative)
     *
     *  (1)  Test that we got a failure response.
     *  (2)  Test that we 0 back.
     */
    @isTest static void test_logErrorMessage_Negative_tooLarge() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();
            //@TODO use metadat api to get field size and then add 1.
            String sBogusStack = constructTestString(131073);//one larger then Stack_Trace__c
            ResponseDto logDto = Accel_LoggingUtilsController.logErrorMessage(sBogusStack,null);
            //--(1)  Test that we got a failure response.
            System.assert(!logDto.isSuccess);
            //System.assert(logDto.technicalMsg.contains('STRING_TOO_LONG'));

            List<Accel_Application_Error__c> errors = [
                    SELECT  Id, Stack_Trace__c, User__c
                    FROM    Accel_Application_Error__c
                    WHERE   User__c = :communityUser.Id
            ];
            //--(2)  Test that we 0 back.
            Test.stopTest();
        }
    }

    @IsTest static void test_logErrorMessage_Negative_BadRTId() {

        User communityUser = TESTUtils.getUserForTest(UNAMECP);
        communityUser = [SELECT Id, contactId, accountId,username from user where id = :communityUser.id];
        System.runAs(communityUser) {

            Test.startTest();
            String sBogusJson = JSON.serialize(communityUser);
            String recordTypeId =  'BOGUSRTIDGOBOOM';

            ResponseDto logDto = Accel_LoggingUtilsController.logErrorMessage(sBogusJson,recordTypeId);
            System.assert(!logDto.isSuccess);
            System.debug(logDto.technicalMsg.contains('Invalid Id'));

            Test.stopTest();
        }
    }
    /**
     *
     *
     * @param length
     *
     * @return
     * @TODO move to test utils
     */
    private static String constructTestString(Integer length) {
        String sample = 'abcde12345'; //10-digit string.

        for (Integer cutoff = 10; cutoff <= 2000000; cutoff = cutoff * 10) {
            if (length <= cutoff) {
                return sample.substring(0, length);
            }
            else {
                String newSample = '';
                for (Integer i = 0; i < 10; i ++) {
                    newSample += sample;
                }
                sample = newSample;
            }
        }
        return sample;
    }
}