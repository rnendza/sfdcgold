@IsTest
private class Accel_ContentVersionTriggerTest {

    /**
     * NOTE start / stop test merely there to reset gov limits as creating non cl data takes forever given
     * all the processors / flows and eventually will bust cpu time outs on it's own.
     */
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();
        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
        List<Route_Import__c> routeImports = clTESTUTILS.createClRouteImportRecords();
    }

    @IsTest
    static void test_uploadRouteImport() {

        List<Route_Import__c> routeImports = [
                SELECT Id, Name, Region__C, Active__c
                FROM Route_Import__c
        ];

        Test.startTest();
            List<ContentVersion> contentVersions = clTESTUTILS.createRouteImportFiles(routeImports);
            System.assertEquals(contentVersions.size(),routeImports.size());
            //@todo subscribe and assert to platform event fired?
        Test.stopTest();
    }
    
}