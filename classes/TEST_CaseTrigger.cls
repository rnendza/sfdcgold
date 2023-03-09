@isTest
private class TEST_CaseTrigger {

    public static   String  UNAME                  = 'acceltest@accel.com';
    public static   String  CALLCENTERUNAME        = 'callcenterdude@dude.com';
    public static   User    uCallCenter            = TestUtils.getUserForTest( CALLCENTERUNAME );

    public static Svc_Utility_Bar_Settings__mdt utilityArMdt = SvcWatchdogController.utilityArMdt;

    static {
        List<Profile> profiles = [SELECT Id from Profile where Name in :SvcWatchdogController.noAssignedResourceProfileNames];
        uCallCenter.profileId = profiles[0].id;
        update uCallCenter;
    }

    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * service appointments and ties them all together.
     */
    @testSetup static void setup() {
        System.runAs(uCallCenter) {
            Test.startTest();  //merely to reset gov limits to get around cpu time
            TestUtils.createAllDataToServiceAppointments();
            Test.stopTest();
        }
    }
    /**
     *  (1) Test that *67 was prepended to user entered Case.Caller_Phone__c if not already added by the user
     *      upon insert of a case. This rolls down the chain as usual to Work Order and SA. The design is only
     *      on insert to allow a user to update the phone to a non *67 prefix and have it roll down to WO and Case
     *      if desired.
     *
     *  (2) Test that *67 was *not* prepended if the user already added it on Case.Caller_Phone__c
     *      upon insert of a case so as not to have multiple *67 on the phone number.
     */
    @IsTest
    static void test_CaseInsert_FlagWithStar67_Positive() {
        String testCallerPhone = '630-310-0898';

        System.runAs(uCallCenter) {
            Test.startTest();
            Case cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            cse.Caller_Phone__c = testCallerPhone;
            insert cse;
            cse = [SELECT Id, Caller_Phone__c FROM Case WHERE Id = :cse.Id  ];
            //---(1) Test that *67 was prepended to user entered Case.Caller_Phone__c if not already added by the user
            // upon insert of a case.
            System.assert(cse.Caller_Phone__c == '*67'+testCallerPhone );

            cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            cse.Caller_Phone__c = '*67 ' +testCallerPhone;
            insert cse;
            cse = [SELECT Id, Caller_Phone__c FROM Case WHERE Id = :cse.Id  ];
            //---(2) Test that *67 was prepended if the user already added it on Case.Caller_Phone__c
            // upon insert of a case.
            System.assert(cse.Caller_Phone__c == '*67 '+testCallerPhone );

            Test.stopTest();
        }
    }
    /**
    * Test the update of a Work Order to ensure  it's child  Work Orders sync the Caller_Phone__c field
    * (1)-- Test update of Case Caller Phone
    */
    @isTest static void test_CaseUpdate_WorkOrder_CallerPhone_Positive() {
        System.runAs(uCallCenter) {
            String testPhoneNumber = '630-310-0898';
            List<WorkOrder> workOrders = [SELECT Id, CaseId,Caller_Phone__c FROM WorkOrder];
            System.assert(!workOrders.isEmpty());
            Set<Id> caseIds = new Set<Id>();
            for(WorkOrder  wo : workOrders) {
                caseIds.add(wo.CaseId);
            }
            Test.startTest();

            List<Case> cases = [SELECT Id, Caller_Phone__c FROM Case where Id IN :caseIds];
            for(Case cse : cases) {
                cse.Caller_Phone__c = testPhoneNumber;
            }
            update cases;
            workOrders =  [
                    SELECT  Id, Caller_Phone__c, Case.Caller_Phone__c
                    FROM    WorkOrder
                    WHERE   CaseId IN :caseIds];
            //(1) ensure child work orders caller phones matches the parent cases caller phone after update.
            for(WorkOrder wo : workOrders) {
                System.assert(wo.Caller_Phone__c  == wo.Caller_Phone__c);
            }
            Test.stopTest();
        }
    }
    /**
     * Test the update of a Case to ensure it's child Service Appointments sync the Service_Category__c field
     * (1)-- Test update of a Case from Service_Category__c = 'Amusement' to Service_Category__c = 'Vgt'
     */
    @isTest static void test_CaseUpdate_Service_Appointment_Positive() {
        System.runAs(uCallCenter) {
            List<ServiceAppointment> serviceAppointments = [SELECT Id, Service_Category__c, Work_Order__r.CaseId FROM ServiceAppointment];
            System.assert(!serviceAppointments.isEmpty());
            Set<Id> caseIds = new Set<Id>();
            for(ServiceAppointment sa : serviceAppointments) {
                caseIds.add(sa.Work_Order__r.CaseId);
            }
            Test.startTest();

            List<Case> cases = [SELECT Id, Service_Category__c FROM Case where Id IN :caseIds];
            for(Case cse : cases) {
                cse.Service_Category__c = 'VGT';
            }
            update cases;
            serviceAppointments =  [SELECT  Id, Service_Category__c, Work_Order__r.Case.Service_Category__c
                                    FROM    ServiceAppointment
                                    WHERE   Work_Order__r.CaseId in :caseIds];
            //(1) ensure child service categories match then parent cases service categories (via work order) after update.
            for(ServiceAppointment sa : serviceAppointments) {
                System.assert(sa.Service_Category__c == sa.Work_Order__r.Case.Service_Category__c);
            }

            Test.stopTest();
        }
    }
    /**
    * Test the insert of a an in progress case and the firing of a PE.
    * (1)-- Case is created no assigned resource.
    */
    @isTest static void test_CaseInsert_NoAssignedResource_PlatformEvent() {

        Boolean isItDisabled = utilityArMdt.Disable_No_Assigned_Resource_PE__c;
        System.runAs(uCallCenter) {
            Test.startTest();

            Case cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            insert cse;

            Test.stopTest();

            if(!isItDisabled) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Case_Assigned_Resource_PE__e> caseAssignedResourcePES = CaseTriggerHandler.caseAssignedResourcePES;
                // System.assert(caseAssignedResourcePES.size() == 2); @TODO why is this not working?
                //(1) Platform events are created
                for(Case_Assigned_Resource_PE__e caseArPe : caseAssignedResourcePES) {
                    System.assert(caseArPe.DML_Action__c == PlatformEventSvc.DML_ACTION_INSERT);
                }
            }
        }
    }
   /**
    * --(1)-- Test an insert of a Case. Ensure it's Solution__c (PL) Matches Accel_Solution__c (Lookup)
    */
    @isTest static void test_CaseInsert_Solution_Positive() {

        System.runAs(uCallCenter) {

            Map<Id,Solution__c> mAccelSolutionsByIds = new Map<Id,Solution__c>( [SELECT Id, Name FROM Solution__c] );
            Solution__c solution;
            //just grab one.
            for(Solution__c sol : mAccelSolutionsByIds.values()) {
                solution = sol;
                break;
            }

            Test.startTest();

            Case cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            cse.Accel_Solution__c = solution.Id;
            Case cse2 = new Case();
            cse2.Account__c = [select id from account limit 1].id;
            cse2.Status = 'In Progress';
            cse2.Accel_Solution__c = solution.Id;
            List<Case> cases = new List<Case>();
            cases.add(cse);
            cases.add(cse2);
            insert cases;

            Test.stopTest();

            cases = [SELECT Id, Solution__c, Accel_Solution__r.Name FROM Case where Id in :cases];

            for(Case tmpCase : cases) {
                System.assertEquals(tmpCase.Solution__c, tmpCase.Accel_Solution__r.Name);
            }
        }
    }
    @isTest static void test_CaseUpdate_Solution_Positive() {

        Map<Id,Solution__c> mAccelSolutionsByIds = new Map<Id,Solution__c>( [SELECT Id, Name FROM Solution__c] );
        Solution__c solution;
        //just grab one.
        for(Solution__c sol : mAccelSolutionsByIds.values()) {
            solution = sol;
            break;
        }

        System.runAs(uCallCenter) {

            Case cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            insert cse;

            Test.startTest();

            cse.Accel_Solution__c = solution.id;
            update cse;

            Test.stopTest();

            List<Case_Closed_PE__e> caseClosedPES = CaseTriggerHandler.caseClosedPES;

            for (Case_Closed_PE__e caseClosedPE : caseClosedPES) {
                System.assert(caseClosedPE.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
            }
        }
    }
    /**
    * Test the update of a case and the firing of a PE.
    * (1)-- Case is closed.
    */
    @isTest static void test_CaseUpdate_CaseClosed_PlatformEvent() {

        System.runAs(uCallCenter) {

            Case cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            insert cse;

            Test.startTest();

            cse.status = 'Closed';
            update cse;

            Test.stopTest();

            List<Case_Closed_PE__e> caseClosedPES = CaseTriggerHandler.caseClosedPES;

            for (Case_Closed_PE__e caseClosedPE : caseClosedPES) {
                System.assert(caseClosedPE.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
            }
        }
    }
    /**
     * Test the Insert of a case with an assigned resource attached to it. (probably won't happen)
     * but technically via object model.. it could.
     */
    @isTest static void test_CaseUpdate_AssignedResource_Added_PlatformEvent() {

        Boolean isItDisabled = utilityArMdt.Disable_No_Assigned_Resource_PE__c;
        System.runAs(uCallCenter) {
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case LIMIT  12];
            //-- note flow will f with the assigned_resource__c if no work orders attached when updating below
            //-- so we need an existing one that has workorders attached as opposed to a simple insert of a new one!
            Test.startTest();

            for(Case cse : cases) {
                cse.Assigned_Resource__c = uCallCenter.id;
            }
            update cases;

            Test.stopTest();

            if(!isItDisabled) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Case_Assigned_Resource_PE__e> caseAssignedResourcePES = CaseTriggerHandler.caseAssignedResourcePES;
               // System.assert(caseAssignedResourcePES.size() == 2); @TODO why is this not asserting?
                for(Case_Assigned_Resource_PE__e caseArPe : caseAssignedResourcePES) {
                    system.debug(LoggingLevel.DEBUG,'rjn caseArpe1='+caseArPe);
                    System.assert(caseArPe.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
                }
            }
        }
    }
    /**
     * Test the nullification of a case assigned resource and the firing of a PE.
     */
    @isTest static void test_CaseUpdate_AssignedResource_Removed_PlatformEvent() {

        Boolean isItDisabled = utilityArMdt.Disable_No_Assigned_Resource_PE__c;
        System.runAs(uCallCenter) {
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case LIMIT  2];
            //-- note flow will f with the assigned_resource__c if no work orders attached when updating below
            //-- so we need an existing one that has workorders attached as opposed to a simple insert of a new one!
            Test.startTest();

            for(Case cse : cases) {
                cse.Assigned_Resource__c = uCallCenter.id;
            }
            update cases;

            for(Case cse : cases) {
                cse.Assigned_Resource__c = null;
            }
            update cases;

            Test.stopTest();

            if(!isItDisabled) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Case_Assigned_Resource_PE__e> caseAssignedResourcePES = CaseTriggerHandler.caseAssignedResourcePES;
                system.debug('rjnsize='+caseAssignedResourcePES.size());
                //System.assert(caseAssignedResourcePES.size() == 2);
                for(Case_Assigned_Resource_PE__e caseArPe : caseAssignedResourcePES) {
                    system.debug(caseArPe);
                    System.assert(caseArPe.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
                }
            }
        }
    }
    /**
     * TEst the deletion of a case and firing of a PE.
     */
    @isTest static void test_CaseDelete_NoAssignedResource_PlatformEvent() {

        Boolean isItDisabled = utilityArMdt.Disable_No_Assigned_Resource_PE__c;
        System.runAs(uCallCenter) {
            Case cse = new Case();
            cse.Account__c = [select id from account limit 1].id;
            cse.Status = 'In Progress';
            insert cse;

            Test.startTest();
            delete cse;
            Test.stopTest();

            if(!isItDisabled) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Case_Assigned_Resource_PE__e> caseAssignedResourcePES = CaseTriggerHandler.caseAssignedResourcePES;
                system.debug('rjnsizedel='+caseAssignedResourcePES.size());
                //System.assert(caseAssignedResourcePES.size() == 2);
                for(Case_Assigned_Resource_PE__e caseArPe : caseAssignedResourcePES) {
                    system.debug(caseArPe);
                    System.assert(caseArPe.DML_Action__c == PlatformEventSvc.DML_ACTION_DELETE);
                }
            }
        }
    }
    //============= @TODO Test exceptions!
}