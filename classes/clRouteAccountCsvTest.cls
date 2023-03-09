@IsTest
private class clRouteAccountCsvTest {

    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();
        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_generateCsv() {

        Route__C route = [SELECT Id FROM Route__c LIMIT 1];

        List<Route_Account__c> routeAccounts = [
                SELECT Id,Name,Route__c,X1_Fill_Level__c,X50_Fill_Level__c,X20_Fill_Level__c,X100_Fill_Level__c,
                        X5_Fill_Level__c,Route__r.Name,CreatedDate,CreatedById,CreatedBy.Username,
                        Account__r.NAme,Collection_Type__c,Replenishment_Type__c,Stop_Number__c
                FROM Route_Account__c
                WHERE Route__c = :route.Id
        ];

        Test.startTest();

        String csv = new clRouteAccountCsv().generateRouteAccountCsv(routeAccounts);
        //  @todo asserts

        Test.stopTest();
    }

    @IsTest
    static void test_generateCsv_null_stopnumber() {

        Route__C route = [SELECT Id FROM Route__c LIMIT 1];

        List<Route_Account__c> routeAccounts = [
                SELECT Id,Name,Route__c,X1_Fill_Level__c,X50_Fill_Level__c,X20_Fill_Level__c,X100_Fill_Level__c,
                        X5_Fill_Level__c,Route__r.Name,CreatedDate,CreatedById,CreatedBy.Username,
                        Account__r.NAme,Collection_Type__c,Replenishment_Type__c,Stop_Number__c
                FROM Route_Account__c
                WHERE Route__c = :route.Id
        ];
        for(Route_Account__c ra : routeAccounts) {
            ra.Stop_Number__c = null;
        }

        Test.startTest();

        String csv = new clRouteAccountCsv().generateRouteAccountCsv(routeAccounts);
        System.assert(csv.containsIgnoreCase('Stop'));

        Test.stopTest();
    }

}