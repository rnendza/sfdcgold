@IsTest
private class clUserSettingsControllerTest {
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mUsers = clTESTUTILS.createClUsers();
        Test.stopTest();
    }

    @IsTest
    static void test_insertSetting() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto  = clUserSettingsController.insertSetting(collector.Id,'VGT');
            System.assert(dto.isSuccess);
            CL_User_Setting__c setting = (CL_User_Setting__c)dto.values.get(clUserSettingsController.MAP_KEY_USER_SETTING);
            System.assertEquals(setting.User__c,collector.Id);

            dto = clUserSettingsController.insertSetting(collector.Id,'bogustype');
            System.assert(!dto.isSuccess);
        }
        System.runAs(processor) {
            ResponseDto dto  = clUserSettingsController.insertSetting(processor.Id,'Redemption');
            System.assert(dto.isSuccess);
            CL_User_Setting__c setting = (CL_User_Setting__c)dto.values.get(clUserSettingsController.MAP_KEY_USER_SETTING);
            System.assertEquals(setting.User__c,processor.Id);
        }

        Test.stopTest();
    }


    @IsTest
    static void test_retrieveSetting() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);

        clUserSettingsController.insertSetting(collector.Id,'VGT');
        clUserSettingsController.insertSetting(processor.Id,'VGT');

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto  = clUserSettingsController.retrieveUserSettings(collector.Id);
            System.assert(dto.isSuccess);
        }
        System.runAs(processor) {
            ResponseDto dto  = clUserSettingsController.retrieveUserSettings(processor.Id);
            System.assert(dto.isSuccess);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_updateSetting() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        User processor = (User)mUser.get(clTESTUTILS.PROCESSOR);

        ResponseDto dto  = clUserSettingsController.insertSetting(collector.Id,'VGT');
        CL_User_Setting__c collectorSetting = (CL_User_Setting__c)dto.values.get(clUserSettingsController.MAP_KEY_USER_SETTING);
        dto  = clUserSettingsController.insertSetting(processor.Id,'VGT');
        CL_User_Setting__c processorSetting = (CL_User_Setting__c)dto.values.get(clUserSettingsController.MAP_KEY_USER_SETTING);

        Test.startTest();

        System.runAs(collector) {

            dto  = clUserSettingsController.updateSetting(collectorSetting.Id,'Redemption');
            System.assert(dto.isSuccess);
            CL_User_Setting__c setting = (CL_User_Setting__c)dto.values.get(clUserSettingsController.MAP_KEY_USER_SETTING);
            System.assertEquals(setting.Selected_Machine_Type__c,'Redemption');

            dto = clUserSettingsController.updateSetting(collectorSetting.Id,'bogustype');
            System.assert(!dto.isSuccess);
        }
        System.runAs(processor) {
            dto  = clUserSettingsController.updateSetting(processorSetting.Id,'Redemption');
            System.assert(dto.isSuccess);
            CL_User_Setting__c setting = (CL_User_Setting__c)dto.values.get(clUserSettingsController.MAP_KEY_USER_SETTING);
            System.assertEquals(setting.Selected_Machine_Type__c,'Redemption');
        }

        Test.stopTest();
    }
}