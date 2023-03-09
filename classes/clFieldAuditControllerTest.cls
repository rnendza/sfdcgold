@IsTest
private class clFieldAuditControllerTest {
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_retrieveFieldHistoryByParams() {

        String historyObject = 'Route_Schedule__History';
        Datetime dtStart = System.now().addDays(-2);
        Datetime dtEnd = System.now();

        Map<Id,Route_Schedule__c> mRs = new Map<Id,Route_Schedule__c> ([
                Select Id
                FROM   Route_Schedule__c
                WHERE  CreatedDate >= :dtStart
                AND    CreatedDate <= :dtEnd
                LIMIT  2
        ]);
        Map<Id,Account> mAccounts = new Map<Id,Account> ([
                Select Id
                FROM   Account
                WHERE  CreatedDate >= :dtStart
                AND    CreatedDate <= :dtEnd
                LIMIT  2
        ]);

        Route_Schedule__History routeScheduleHistory = new Route_Schedule__History(
                Field = 'Starting_Vehicle_Milage__c', ParentId = mRs.values().get(0).Id
        );
        insert routeScheduleHistory;

        AccountHistory accountHistory = new AccountHistory(
                Field = 'Legal_Name__c', AccountId = mAccounts.values().get(0).Id
        );
        insert accountHistory;

        Test.startTest();

        System.runAs(new User(Id=UserInfo.getUserId())) {

            List<String> fields = new List<String>{'Assigned_Driver__c','Starting_Vehicle_Milage__c','Vehicle_License__c'};
            ResponseDto dto = clFieldAuditController.retrieveFieldHistoryByParams(dtStart,dtEnd,historyObject,fields);

            fields = new List<String>{'Legal_Name__c'};
            dto = clFieldAuditController.retrieveFieldHistoryByParams(dtStart,dtEnd,'AccountHistory',fields);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveMdt() {

        Test.startTest();

        System.runAs(new User(Id=UserInfo.getUserId())) {
            ResponseDto dto = clFieldAuditController.retrieveFieldHistoryMetadata(clFieldAuditController.MDT_DEV_NAME_CL_FIELD_HISTORY);
        }

        Test.stopTest();
    }

}