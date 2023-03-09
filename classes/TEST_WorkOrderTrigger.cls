@isTest
private class TEST_WorkOrderTrigger {

    public static String ADMINUNAME         = 'acceltestadmin@accel.com';
    public static String CALLCENTERUNAME    = 'callcenterdude@dude.com';

    public static  User uCallCenter = TestUtils.getUserForTest( CALLCENTERUNAME );
    public static  User uAdmin      = TestUtils.getUserForTest( ADMINUNAME );

    static {
        List<Profile> profiles = [SELECT Id from Profile where Name in :SvcWatchdogController.noAssignedResourceProfileNames];
        uCallCenter.profileId = profiles[0].id;
        update uCallCenter;
    }

    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * ties them all together.
     */
    @testSetup static void setup() {
        System.runAs(uCallCenter) {
            Test.startTest();  //merely to reset gov limits to get around cpu time
            TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
            TestUtils.createAllDataToServiceAppointments( params );
            Test.stopTest();
        }
    }
    /**
     * Test an insert of a WorkOrder. Note Process Builder will be fired causing an update. Generally this test is to
     * ensure that there is a field visible to service on the mobile app.
     *
     * --(1)-- Tests that when an account is set to Priority A. .WorkOrder.Location_Priority__c is High.
     * --(2)-- Tests that when an account is set to a non supported value ie.  'D' WorkOrder.Location__Priority__c is null.
     */
    @IsTest static void test_WorkOrderInsert_LocationPriority_Positive() {

        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        System.runAs(uAdmin) {

            List<Account> accounts = [SELECT Id, Priority__c FROM Account];
            for(Account account : accounts) {
                account.Priority__c = 'A';
            }
            update accounts;

            Id workOrderRtId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get(params.workOrderRecordTypeName).getRecordTypeId();

            List<ServiceTerritory> serviceTerritories = [SELECT Id from ServiceTerritory];
            //---------- CREATE WORK ORDERS
            List<WorkOrder> workOrders = new List<WorkOrder>();
            List<Case > cases = [SELECT Id, AccountId FROM Case ] ;

            for (Case cse : cases) {
                for (Integer i = 0; i < params.iNumWorkOrdersPerCase; i++) {
                    WorkOrder workOrder = new WorkOrder();
                    workOrder.AccountId = cse.AccountId;
                    workOrder.CaseId = cse.id;
                    workOrder.RecordTypeId = workOrderRtId;
                  //  workOrder.Priority = 'A'; --- process will overwrite this anyway so n/a
                    workOrder.Status = params.workOrderStatus;
                    workOrder.Site_Grade__c = params.workOrderSiteGrade;
                    workOrder.ServiceTerritoryId = serviceTerritories[0].Id;
                    workOrders.add(workOrder);
                }
            }
            Test.startTest();

            insert workOrders;
            workOrders = [SELECT Id, Location_Priority__c,Priority FROM WorkOrder WHERE Id In :workOrders];
            //  TEST (1)
            for(WorkOrder wo : workOrders) {
                System.assertEquals(wo.Location_Priority__c, WorkOrderTriggerHandler.mPriorityTranslation.get('A'));
                wo.Priority = 'D'; // set priority to a non  supported value now so we can test a negative case.
            }
            update workOrders;
            workOrders = [SELECT Id, Location_Priority__c,Priority FROM WorkOrder WHERE Id In :workOrders];

            // TEST (2)
            for(WorkOrder wo : workOrders) {
                System.assertEquals(wo.Location_Priority__c, null);
            }

            Test.stopTest();
        }
    }
    /**
     * --(1)-- Test an insert of a ServiceAppointment. Ensure it's Solution__c (PL) Matches Accel_Solution__c (Lookup)
     */
    @isTest static void test_WorkOrderInsert_Solution_Positive() {
        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        Map<Id,Solution__c> mAccelSolutionsByIds = new Map<Id,Solution__c>( [SELECT Id, Name FROM Solution__c] );
        Solution__c solution;
        //just grab one.
        for(Solution__c sol : mAccelSolutionsByIds.values()) {
            solution = sol;
            break;
        }
        System.runAs(uAdmin) {

            List<Account> accounts = [SELECT Id, Priority__c FROM Account];
            for(Account account : accounts) {
                account.Priority__c = 'A';
            }
            update accounts;

            Id workOrderRtId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get(params.workOrderRecordTypeName).getRecordTypeId();

            List<ServiceTerritory> serviceTerritories = [SELECT Id from ServiceTerritory];
            //---------- CREATE WORK ORDERS
            List<WorkOrder> workOrders = new List<WorkOrder>();
            List<Case > cases = [SELECT Id, AccountId FROM Case ] ;

            for (Case cse : cases) {
                for (Integer i = 0; i < params.iNumWorkOrdersPerCase; i++) {
                    WorkOrder workOrder = new WorkOrder();
                    workOrder.AccountId = cse.AccountId;
                    workOrder.CaseId = cse.id;
                    workOrder.RecordTypeId = workOrderRtId;
                    //  workOrder.Priority = 'A'; --- process will overwrite this anyway so n/a
                    workOrder.Status = params.workOrderStatus;
                    workOrder.Site_Grade__c = params.workOrderSiteGrade;
                    workOrder.ServiceTerritoryId = serviceTerritories[0].Id;
                    workOrder.Accel_Solution__c =  solution.id;
                    workOrders.add(workOrder);
                }
            }
            Test.startTest();

            insert workOrders;
            workOrders = [SELECT Id, Solution__c, Accel_Solution__r.Name FROM WorkOrder limit 12];

            for(WorkOrder wo : workOrders) {
                System.assertEquals(wo.Solution__c, wo.Accel_Solution__r.Name);
            }

            Test.stopTest();
        }
    }
    /**
     * --(1)-- Test an update of a WorkOrder. Ensure it's Solution__c (PL) Matches Accel_Solution__c (Lookup)
     */
    @isTest static void test_WorkOrderUpdate_Solution_Positive() {

        System.runAs(uAdmin) {

            List<WorkOrder> workOrders = [SELECT Id, Accel_Solution__c, Solution__C FROM WorkOrder LIMIT 12];
            Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                    SELECT  Id,Name
                    FROM    Solution__c
            ]);
            Solution__c solution;
            //just grab one.
            for(Solution__c sol : mSolutionsByIds.values()) {
                solution = sol;
                break;
            }
            for(WorkOrder wo : workOrders) {
                wo.Accel_Solution__c = solution.Id;
            }
            Test.startTest();

            update workOrders;
            workOrders = [SELECT Id, Accel_Solution__r.Name, Solution__C FROM WorkOrder LIMIT 12];
            for( WorkOrder wo : workOrders) {
                System.assertEquals(wo.Accel_Solution__r.Name, wo.Solution__c);
            }

            Test.stopTest();
        }
    }
   /**
    * --(1)-- Test an insert of a WorkOrder. Ensure it's WorkOrder caller phone equals it's parent Case
    * caller phone if they left it null on creation of the WO and it's parent case has a value.
    */
    @isTest static void test_WorkOrderInsert_Positive() {
        String testPhone = '630-310-0898';
        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        System.runAs(uAdmin) {

            Set<Id> caseIds = new Set<Id>();
            List<Case> cases = [    SELECT  Id, AccountId, Service_Category__c
                                    FROM    Case];
            for(Case cse : cases) {
                cse.Caller_Phone__c = testPhone;
                caseIds.add(cse.Id);
            }
            update cases;

            Id workOrderRtId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get(params.workOrderRecordTypeName).getRecordTypeId();

            List<ServiceTerritory> serviceTerritories = [SELECT Id from ServiceTerritory];
            //---------- CREATE WORK ORDERS
            List<WorkOrder> workOrders = new List<WorkOrder>();

            for (Case cse : cases) {
                for (Integer i = 0; i < params.iNumWorkOrdersPerCase; i++) {
                    WorkOrder workOrder = new WorkOrder();
                    workOrder.AccountId = cse.AccountId;
                    workOrder.CaseId = cse.id;
                    workOrder.RecordTypeId = workOrderRtId;
                    //@TODO play the asset game.
//                    workOrder.AssetId = accountAssets[0].Id;
                    workOrder.Status = params.workOrderStatus;
                    workOrder.Site_Grade__c = params.workOrderSiteGrade;
                    workOrder.ServiceTerritoryId = serviceTerritories[0].Id;
                    workOrders.add(workOrder);
                }
            }
            Test.startTest();

            insert workOrders;
            workOrders = [SELECT Id, Caller_Phone__c,Case.Caller_Phone__c FROM WorkOrder where CaseId = :caseIds limit 12];
            //--(1)-- all ServiceAppointment.Service_Category__c matches their parent case Service_Category__c.
            for(WorkOrder wo : workOrders) {
                System.assertEquals(wo.Caller_Phone__c, wo.Case.Caller_Phone__c);
            }
            Test.stopTest();
        }
    }
    /**
     * --(1)-- Test an Update of a WorkOrder. Ensure it's parent cases caller phone equals it's parent Case caller phone
     * if it changed update update.
     */
    @isTest static void test_WorkOrderUpdate_CasePhone_Positive() {

        String testPhone = '666-666-6666';
        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();

        System.runAs(uCallCenter) {
            //create new work orders just use existing cases.
            Set<Id> caseIds = new Set<Id>();
            List<Case> cases = [    SELECT  Id, AccountId, Caller_Phone__c
                                    FROM    Case
            ];
            for(Case cse : cases) {
                cse.Caller_Phone__c = testPhone;
                caseIds.add(cse.Id);
            }
            update cases;

            Id workOrderRtId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get(params.workOrderRecordTypeName).getRecordTypeId();

            List<ServiceTerritory> serviceTerritories = [SELECT Id from ServiceTerritory];
            //---------- CREATE WORK ORDERS
            List<WorkOrder> workOrders = new List<WorkOrder>();

            for (Case cse : cases) {
                for (Integer i = 0; i < params.iNumWorkOrdersPerCase; i++) {
                    WorkOrder workOrder = new WorkOrder();
                    workOrder.AccountId = cse.AccountId;
                    workOrder.CaseId = cse.id;
                    workOrder.RecordTypeId = workOrderRtId;
                    //@TODO play the asset game.
//                    workOrder.AssetId = accountAssets[0].Id;
                    workOrder.Status = params.workOrderStatus;
                    workOrder.Site_Grade__c = params.workOrderSiteGrade;
                    workOrder.ServiceTerritoryId = serviceTerritories[0].Id;
                    workOrders.add(workOrder);
                }
            }
            insert workOrders;

            Test.startTest();

            workOrders = [
                    SELECT  Id, Caller_Phone__c,Case.Caller_Phone__c
                    FROM    WorkOrder
                    WHERE   Id IN :workOrders
            ];
            for(WorkOrder wo : workOrders) {
                wo.Caller_Phone__c = testPhone;
            }
            update workOrders;
            //--(1)-- all Case Caller phones eq this work order caller phone.
            for(WorkOrder wo : workOrders) {
                System.assertEquals(wo.Caller_Phone__c, wo.Case.Caller_Phone__c);
            }
            Test.stopTest();
        }
    }
    /**
     *
     */
    @isTest static void test_WorkOrderUpdate_CaseAccelSolution_Positive() {

        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        params.iNumWorkOrdersPerCase = 2;

        Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                SELECT  Id,Name
                FROM    Solution__c
        ]);
        Solution__c solution;
        //just grab one.
        for(Solution__c sol : mSolutionsByIds.values()) {
            solution = sol;
            break;
        }

        System.runAs(uCallCenter) {
            //create new work orders just use existing cases.
            Set<Id> caseIds = new Set<Id>();
            List<Case> cases = [    SELECT  Id, AccountId
                                    FROM    Case
                                    LIMIT   2
            ];
            for(Case cse : cases) {
                caseIds.add(cse.Id);
            }
            update cases;

            Id workOrderRtId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get(params.workOrderRecordTypeName).getRecordTypeId();

            List<ServiceTerritory> serviceTerritories = [SELECT Id from ServiceTerritory];
            //---------- CREATE WORK ORDERS
            List<WorkOrder> workOrders = new List<WorkOrder>();

            for (Case cse : cases) {
                for (Integer i = 0; i < params.iNumWorkOrdersPerCase; i++) {
                    WorkOrder workOrder = new WorkOrder();
                    workOrder.AccountId = cse.AccountId;
                    workOrder.CaseId = cse.id;
                    workOrder.RecordTypeId = workOrderRtId;
                    //@TODO play the asset game.
//                    workOrder.AssetId = accountAssets[0].Id;
                    workOrder.Status = params.workOrderStatus;
                    workOrder.Site_Grade__c = params.workOrderSiteGrade;
                    workOrder.ServiceTerritoryId = serviceTerritories[0].Id;
                    workOrders.add(workOrder);
                }
            }
            insert workOrders;

            Test.startTest();

            workOrders = [
                    SELECT  Id, Status, Accel_Solution__c, CaseId
                    FROM    WorkOrder
                    WHERE   Id IN :workOrders
            ];
            Map<Id,Id> mCaseIdSolutionId = new Map<Id,Id>();
            for(WorkOrder wo : workOrders) {
                wo.Status = 'Completed';
                wo.Accel_Solution__c = solution.Id;
                mCaseIdSolutionId.put(wo.CaseId, wo.Accel_Solution__c);
            }
            update workOrders;
            cases = [SELECT Id, Accel_Solution__c FROM Case where id in :mCaseIdSolutionId.keySet()];
            for(Case cse : cases) {
                System.assertEquals(cse.Accel_Solution__c, mCaseIdSolutionId.get(cse.Id));
            }
            Test.stopTest();
        }
    }
}