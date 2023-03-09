@isTest
private class TEST_CustomSettingsSvc {

    public static String UNAME = 'acceltest@accel.com';
    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(new TestUtils.SecSettings('', UNAME, '', '', ''), Datetime.now());
        TestUtils.createAccelTimeEditSettings(u);

        List<SObject> sObjs = new List<SObject>();
        String settingName = 'Batch_Settings__c ' + UserInfo.getOrganizationId();
        sObjs.add(new Batch_Settings__c(Name = settingName, SetupOwnerId = UserInfo.getOrganizationId(),
                Most_Recent_Hpd_Date__c  = Date.today().addDays(-1)));

        settingName = 'Service_Utility_Bar_Config__c  ' + UserInfo.getOrganizationId();
        sObjs.add(new  Service_Utility_Bar_Config__c (Name = settingName, SetupOwnerId = UserInfo.getOrganizationId()));

        settingName = 'Software_Assets_Config__c  ' + UserInfo.getOrganizationId();
        sObjs.add(new  Software_Assets_Config__c(Name = settingName, SetupOwnerId = UserInfo.getOrganizationId()));

        insert sObjs;
    }
    /**
     * (1) Test for valid boolean retrieval.
     * (2) Test for valid field retrieval.
     * (3) Test for valid instance retrieval.
     */
    @isTest static void testCustomSettingsPositive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            //=== (1) Valid boolean retrieval.
            system.assertEquals(CustomSettingsSvc.getAccelTimeEditBooleanSetting('Debug_Console__c')
                    , Accel_Time_Edit__c.getInstance(u.id).Debug_Console__c);

            //=== (2) Valid field retrieval
            system.assert((Boolean) CustomSettingsSvc.getAccelTimeEditSetting(u.id, 'Debug_Console__c'));

            //=== (3) Valid instance retrieval
            system.assertEquals(CustomSettingsSvc.getAccelTimeEditSettings(u.id).id
                    , Accel_Time_Edit__c.getInstance(u.id).id);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_getBatchSettings_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
                System.assert(CustomSettingsSvc.getBatchSettings() != null);
                System.assert(CustomSettingsSvc.getBatchSettings(UserInfo.getUserId()) != null);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getSvcUtilityBarConfig_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            System.assert(CustomSettingsSvc.getSvcUtilityBarConfig(UserInfo.getUserId()) != null);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getSoftwareAssetsConfig_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            System.assert(CustomSettingsSvc.getSoftwareAssetsConfigSettings(UserInfo.getUserId()) != null);
            Test.stopTest();
        }
    }
    /**
    * (1) Test for invalid field name retrieval attempt.
    */
    @isTest static void testCustomSettingsNegative() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            //=== (1) Test for invalid field name retrieval attempt.
            system.assert(CustomSettingsSvc.getAccelTimeEditSetting(u.id,'Bogus Name') == null);

            Test.stopTest();
        }
    }
}