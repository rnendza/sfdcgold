@IsTest
private class clUserSettingsSvcTest {

    @TestSetup
    static void setupData() {

        Test.startTest();

        Map<String,Object> mUsers = clTESTUTILS.createClUsers();
        User collector = (User)mUsers.get(clTESTUTILS.COLLECTOR);
        User processor = (User)mUsers.get(clTESTUTILS.PROCESSOR);
        clTESTUTILS.createUserSetting(collector);
        clTESTUTILS.createUserSetting(processor);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveSetting() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);

        Test.startTest();

        System.runAs(collector) {
            CL_User_Setting__c collectorSetting = clUserSettingsSvc.retrieveSetting(collector.Id);
            System.assertEquals(collectorSetting.User__c,collector.Id);
        }
        System.runAs(processor) {
            CL_User_Setting__c processorSetting = clUserSettingsSvc.retrieveSetting(processor.Id);
            System.assertEquals(processorSetting.User__c,processor.Id);
        }

        Test.stopTest();
    }
}