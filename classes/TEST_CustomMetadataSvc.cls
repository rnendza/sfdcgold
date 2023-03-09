@isTest
private class TEST_CustomMetadataSvc {
    public static final String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        TestUtils.getUserForTest(new TestUtils.SecSettings('', UNAME, '', '', ''), Datetime.now());
    }
    /**
     * (1) Test for data existing in metadata type.
     * (2) Test for existence of account aggregation record.
     * (3) Test for existence of muni aggregation record.
     */
    @isTest static void testHptTotalSettingsPositive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            //=== (1) Ensure meta data type has data.
            system.assert(!CustomMetadataSvc.retrieveHpdTotalSettingsMetas().isEmpty());
            //=== (2) Ensure account aggregation record exists.
            system.assert(CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME) != null);
            //=== (3) Ensure municipality aggregation record exists.
            system.assert(CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.MUNICIPALITY_AGGREGATION_DEVNAME) != null);

            //@todo turn the below into real tests!
            CustomMetadataSvc.retrieveGeoAccuracyDisplayValue('Street');
            CustomMetadataSvc.retrieveCustomSearchMeta(Geocode_Setting__mdt.getSobjectType(),'Address');
            CustomMetadataSvc.retrieveCommunityAccountTypes();
            CustomMetadataSvc.retrieveCommunityMetaFieldValue('Terms_of_Service','Terms_of_Service_Text__c');
           // CustomMetadataSvc.retrieveCommunityMeta('Terms_of_Service');


            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveCustomMetadata_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            Sobject sObj = CustomMetadataSvc.retrieveCustomMetadata(Geocode_Setting__mdt.getSObjectType(),'Address');
            System.assert(sObj != null);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveCustomMetadata_Exception() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            Sobject sObj = CustomMetadataSvc.retrieveCustomMetadata(Geocode_Setting__mdt.getSObjectType(),'xxxxAddress');
            System.assert(sObj == null);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveSurveyMetadatas_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            String surveyMdtCustomDevName = 'RPSQuestions';

            Test.startTest();
            List<Cash_Logistics_Survey_Setting__mdt> mdts;
            mdts = CustomMetadataSvc.retrieveSurveyMetadatas(surveyMdtCustomDevName);
            System.assert(!mdts.isEmpty());
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveSurveyMetadatas_Exception() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            String surveyMdtCustomDevName = 'bogus_custom_dev_name';

            Test.startTest();
            List<Cash_Logistics_Survey_Setting__mdt> mdts;
            mdts = CustomMetadataSvc.retrieveSurveyMetadatas(surveyMdtCustomDevName);
            System.assert(mdts.isEmpty());
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAutomationMetadata_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            String automationMdtDevName = 'clQueueableRpsEmailer';

            Test.startTest();
            Cash_Logistics_Automation_Setting__mdt mdt = CustomMetadataSvc.retrieveAutomationMetadata(automationMdtDevName);
            System.assert(mdt != null);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAutomationMetadata_Exception() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            String automationMdtDevName = 'bogus_dev_name';

            Test.startTest();
            Cash_Logistics_Automation_Setting__mdt mdt = CustomMetadataSvc.retrieveAutomationMetadata(automationMdtDevName);
            System.assert(mdt == null);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveCommunityMetadata() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();
            //  positive
            String settingName = 'Bottom_Nav_Bar';
            Community_Setting__mdt mdtGood = CustomMetadataSvc.retrieveCommunityMeta(settingName);
            System.assert(mdtGood.DeveloperName == settingName);

            //  negative
            settingName = 'Bogus';

            Community_Setting__mdt mdtBad = CustomMetadataSvc.retrieveCommunityMeta(settingName);
            System.assert(mdtBad == null);

            Test.stopTest();
        }
    }
}