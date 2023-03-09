@isTest
private class TEST_ServiceAppointmentTrigger {

    public static String ADMINUNAME         = 'acceltestadmin@accel.com';
    public static String CALLCENTERUNAME    = 'callcenterdude@dude.com';

    public static  User uCallCenter = TestUtils.getUserForTest( CALLCENTERUNAME );
    public static  User uAdmin      = TestUtils.getUserForTest( ADMINUNAME );

    public static final String SA_SCHEDULED_STATUS      = 'Scheduled';
    public static final String SA_COMPLETED_STATUS      = 'Completed';
    public static final String SA_VAL_MSG_CANNOT_COMPLETE_WITHOUT_SOLUTION = 'You cannot close a Service Appointment without a Solution';
    public static final String EX_VAL_RULE = 'FIELD_CUSTOM_VALIDATION_EXCEPTION';

    static {
        List<Profile> profiles = [SELECT Id from Profile where Name in :SvcWatchdogController.noAssignedResourceProfileNames];
        uCallCenter.profileId = profiles[0].id;
        update uCallCenter;
    }
    public static Svc_Utility_Bar_Settings__mdt utilityRejectedMdt = SvcWatchdogController.utilityRejectedMdt;

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
    * --(1)-- Test an insert of a ServiceAppointment. Ensure it's Solution__c (PL) Matches Accel_Solution__c (Lookup)
    */
    @isTest static void test_ServiceAppointmentInsert_Solution_Positive() {
        System.runAs(uAdmin) {
            List<Case> cases = [SELECT Id, Service_Category__c FROM Case];
            for(Case cse : cases) {
                cse.Service_Category__c = 'Vgt';
            }
            update cases;

            Map<Id,WorkOrder> mWorkOrdersByIds = new Map<Id,WorkOrder>([SELECT Id, Case.Service_Category__c from WorkOrder ]);
            List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory];

            Id saRtId = Schema.getGlobalDescribe().get('ServiceAppointment').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Service').getRecordTypeId();


            Map<Id,Solution__c> mAccelSolutionsByIds = new Map<Id,Solution__c>( [SELECT Id, Name FROM Solution__c] );
            Solution__c solution;
            //just grab one.
            for(Solution__c sol : mAccelSolutionsByIds.values()) {
                solution = sol;
                break;
            }
            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            for(Id workOrderId : mWorkOrdersByIds.keySet()) {
                ServiceAppointment sa = new ServiceAppointment();
                sa.Work_Order__c = mWorkOrdersByIds.values()[0].Id;
                sa.RecordTypeId = saRtId;
                sa.EarliestStartTime = System.now();
                sa.DueDate = Date.today().addDays(2);
                sa.ParentRecordId = mWorkOrdersByIds.values()[0].Id;
                //   RJN 11/17/2020 Changed to abide by new validation rules implemented 10/30 ie.
                //   "If The Status of the SA is not Completed, Do Not select a Solution".
                //   https://accelentertainment.lightning.force.com/lightning/setup/ObjectManager/ServiceAppointment/ValidationRules/03d1I000000B7H8QAK/view
                //sa.Status = 'Scheduled';
                sa.Status = 'Completed';
                sa.Machine_Up_Upon_Departure__c = 'Yes';
                sa.Solution_Notes__c = 'test solution notes';
                sa.ServiceTerritoryId = serviceTerritories[0].id;
                sa.Accel_Solution__c = solution.id;
                sa.Machine_Down_Upon_Arrival__c = 'Yes';
                serviceAppointments.add(sa);
            }
            Test.startTest();

            insert serviceAppointments;
            serviceAppointments = [SELECT Id, Solution__c, Accel_Solution__r.Name FROM ServiceAppointment limit 12];
            //--(1)-- all ServiceAppointment.Solution__c pl values need to match Accel_Solution__r.Name values.
            for(ServiceAppointment sa : serviceAppointments) {
                System.assertEquals(sa.Solution__c, sa.Accel_Solution__r.Name);
            }

            Test.stopTest();
        }
    }
   /**
    * --(1)-- Test an update of a ServiceAppointment. Ensure it's Solution__c (PL) Matches Accel_Solution__c (Lookup)
    */
    @isTest static void test_ServiceAppointmentUpdate_Solution_Positive() {

        System.runAs(uAdmin) {


            List<ServiceAppointment> sas = [
                    SELECT Id, Accel_Solution__c, Solution__C, Solution_Notes__c,Machine_Up_Upon_Departure__c
                    FROM ServiceAppointment
                    LIMIT 12
            ];
            //   RJN 11/17/2020 Changed to abide by new validation rules implemented 10/30 ie.
            //  "If The Status of the SA is not Completed, Do Not select a Solution".
            //   Also changed to reflect new FSL Status transitions
            //
            for(ServiceAppointment sa : sas) {  sa.Status = 'Scheduled';}
            update sas;
           /*
            * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
            * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
            */
            for(ServiceAppointment sa : sas) { sa.Status = null; } // huh? why???
            update sas;
            // ===================================================================

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
            for(ServiceAppointment sa : sas) {
                sa.Accel_Solution__c = solution.Id;
                sa.Status = 'Completed';
                sa.Machine_Up_Upon_Departure__c = 'Yes';
                sa.Solution_Notes__c = 'adasfasf1';
            }

            Test.startTest();

            update sas;
            sas = [SELECT Id, Accel_Solution__r.Name, Solution__C FROM ServiceAppointment LIMIT 12];
            for(ServiceAppointment sa : sas) {
                System.assertEquals(sa.Accel_Solution__r.Name, sa.Solution__c);
            }

            Test.stopTest();
        }
    }


    @isTest static void test_ServiceAppointment_Delete_Positive() {

        String testSolutionName = 'OTHER - VGT & RT & SGI & AMUSEMENT & UPSHOW & TABLET & ATM';

        System.runAs(uAdmin) {

            Solution__c newSolution = new Solution__c();
            newSolution.Name = testSolutionName;
            newSolution.Status__c = 'Active';
            insert newSolution;

            List<ServiceAppointment> sas = [
                    SELECT Id, Accel_Solution__c, Solution__C, Solution_Notes__c,Machine_Up_Upon_Departure__c
                    FROM ServiceAppointment
                    LIMIT 12
            ];
            for (ServiceAppointment sa : sas) {
                sa.Status = 'Scheduled';
            }
            update sas;
            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for (ServiceAppointment sa : sas) {
                sa.Status = null;
            } // huh? why???
            update sas;

            // ===================================================================

            Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                    SELECT Id,Name
                    FROM Solution__c
            ]);
            Solution__c solution;
            // get 'OTHER - VGT & RT & SGI & AMUSEMENT & UPSHOW & TABLET & ATM'
            for (Solution__c sol : mSolutionsByIds.values()) {
                if (sol.Name == testSolutionName) {
                    solution = sol;
                    break;
                }
            }
            Set<Id> saIds = new Set<Id>();
            if (solution != null) {
                System.debug('----> found solution');
                for (ServiceAppointment sa : sas) {
                    saIds.add(sa.Id);
                    sa.Accel_Solution__c = solution.Id;
                    sa.Status = 'Completed';
                    sa.Machine_Up_Upon_Departure__c = 'Yes';
                    sa.Solution_Notes__c = 'test solution notes';
                }
                update sas;

                Test.startTest();
                delete sas;
                sas = [SELECT Id From ServiceAppointment WHERE Id IN :saIds];
                System.assert(sas.isEmpty());
                Test.stopTest();
            } else {
                System.debug('----> did not find solution');
            }
        }
    }

    /**
     *
     */
    @isTest static void test_ServiceAppointmentUpdate_WorkOrderSolution_Positive() {

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
            Map<Id,Id> mWorkOrderId_SolutionId = new Map<Id,Id>();
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status,Accel_Solution__c, ParentRecordId
                    FROM    ServiceAppointment
                    LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;
            /*
            * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
            * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
            */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            Test.startTest();

            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Completed';
                serviceAppointment.Accel_Solution__c = solution.id;
                serviceAppointment.Was_Software_Gameset_Changed__c = 'YES';
                serviceAppointment.Machine_Up_Upon_Departure__c = 'YES';
                serviceAppointment.Solution_Notes__c = 'blah tech notes';

                mWorkOrderId_SolutionId.put(serviceAppointment.parentRecordId, serviceAppointment.Accel_Solution__c);
            }
            update serviceAppointments;

            List<WorkOrder> workOrders = [
                    SELECT  Id, Accel_Solution__c
                    FROM    WorkOrder
                    WHERE   Id IN :mWorkOrderId_SolutionId.keySet()
            ];
            for(WorkOrder workOrder : workOrders) {
                System.assertEquals(workOrder.Accel_Solution__c, mWorkOrderId_SolutionId.get(workOrder.Id));
            }
            Test.stopTest();
        }
    }
    /**
     * --(1)-- Test an insert of a ServiceAppointment. Ensure it's Service_Category__c matches it's parent Case (via work order)
     * Service_Category__c after insert.
     */
    @isTest static void test_ServiceAppointmentInsert_ServiceCategory_Positive() {
        System.runAs(uAdmin) {
            List<Case> cases = [SELECT Id, Service_Category__c FROM Case];
            for(Case cse : cases) {
                cse.Service_Category__c = 'Vgt';
            }
            update cases;

            Map<Id,WorkOrder> mWorkOrdersByIds = new Map<Id,WorkOrder>([SELECT Id, Case.Service_Category__c from WorkOrder ]);
            List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory];

            Id saRtId = Schema.getGlobalDescribe().get('ServiceAppointment').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Service').getRecordTypeId();

            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            for(Id workOrderId : mWorkOrdersByIds.keySet()) {
                ServiceAppointment sa = new ServiceAppointment();
                sa.Work_Order__c = mWorkOrdersByIds.values()[0].Id;
                sa.RecordTypeId = saRtId;
                sa.EarliestStartTime = System.now();
                sa.DueDate = Date.today().addDays(2);
                sa.ParentRecordId = mWorkOrdersByIds.values()[0].Id;
                sa.Status = 'Scheduled';
                sa.ServiceTerritoryId = serviceTerritories[0].id;
                sa.Machine_Down_Upon_Arrival__c = 'Yes';
                serviceAppointments.add(sa);
            }
            Test.startTest();

            insert serviceAppointments;
            serviceAppointments = [SELECT Id, Service_Category__c,Work_Order__r.Case.Service_Category__c FROM ServiceAppointment limit 12];
            //--(1)-- all ServiceAppointment.Service_Category__c matches their parent case Service_Category__c.
            for(ServiceAppointment sa : serviceAppointments) {
                System.assertEquals(sa.Service_Category__c, sa.Work_Order__r.Case.Service_Category__c);
            }

            Test.stopTest();
        }
    }
  /**
   * --(1)-- Test an insert of a ServiceAppointment. Ensure it's Location_Priority matches it's parent WorkOrder.Location_Priority
   * after insert.
   */
    @isTest static void test_ServiceAppointmentInsert_LocationPriority_Positive() {
        System.runAs(uAdmin) {


            Map<Id,WorkOrder> mWorkOrdersByIds = new Map<Id,WorkOrder>([SELECT Id, Location_Priority__c from WorkOrder ]);
            List<ServiceTerritory> serviceTerritories = [SELECT Id FROM ServiceTerritory];

            Id saRtId = Schema.getGlobalDescribe().get('ServiceAppointment').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Service').getRecordTypeId();

            List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
            for(Id workOrderId : mWorkOrdersByIds.keySet()) {
                ServiceAppointment sa = new ServiceAppointment();
                sa.Work_Order__c = mWorkOrdersByIds.values()[0].Id;
                sa.RecordTypeId = saRtId;
                sa.EarliestStartTime = System.now();
                sa.DueDate = Date.today().addDays(2);
                sa.ParentRecordId = mWorkOrdersByIds.values()[0].Id;
                sa.Status = 'Scheduled';
                sa.ServiceTerritoryId = serviceTerritories[0].id;
                sa.Machine_Down_Upon_Arrival__c = 'Yes';
                serviceAppointments.add(sa);
            }
            Test.startTest();

            insert serviceAppointments;
            serviceAppointments = [SELECT Id, Location_Priority__c, Work_Order__r.Location_Priority__c FROM ServiceAppointment limit 12];
            //--(1)-- all ServiceAppointment.Location_Priority__c matches their parent work order Location Priority.
            for(ServiceAppointment sa : serviceAppointments) {
                System.assertEquals(sa.Location_Priority__c, sa.Work_Order__r.Location_Priority__c);
            }

            Test.stopTest();
        }
    }
    @isTest static void test_ServiceAppointment_Reject_Positive() {
        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory
                    FROM    ServiceAppointment
                    LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;
            //--- must have the below for flow that clears the assigned resource.
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case];
            for(Case cse : cases) {
                cse.Assigned_Resource__c = null;
            }
            update cases;

            Test.startTest();

           /*
            * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
            * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
            */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            for(ServiceAppointment sa : serviceAppointments) {
                sa.Status = SvcWatchdogController.rejectedStatusToWatch;
                sa.Solution_Notes__c = 'FSL Is horrible';
            }
            update serviceAppointments;

            Test.stopTest();

            serviceAppointments = [SELECT Id, Status FROM ServiceAppointment where id in :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assert(sa.status == SvcWatchdogController.rejectedStatusToWatch);
            }
            if(!utilityRejectedMdt.Disable_Rejected_PE__c) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Service_Appointment_Rejected_PE__e> serviceAppointmentRejectedPES =
                        ServiceAppointmentTriggerHandler.serviceAppointmentRejectedPES;

               //@TODO why isn't this assert working? System.assert(serviceAppointmentRejectedPES.size() == serviceAppointments.size());

                for(Service_Appointment_Rejected_PE__e saPe : serviceAppointmentRejectedPES) {
                    system.assert(saPe.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
                    system.assert(saPe.Service_Appointment_Status__c == SvcWatchdogController.rejectedStatusToWatch);
                }
            }
        }
    }
    /**
     *
     */
    @isTest static void test_ServiceAppointment_Reject_Then_Scheduled() {
        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory
                    FROM    ServiceAppointment
                    LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;
            //--- must have the below for flow that clears the assigned resource.
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case];
            for(Case cse : cases) {
                cse.Assigned_Resource__c = null;
            }
            update cases;

            Test.startTest();

            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            for(ServiceAppointment sa : serviceAppointments) {
                sa.Status = SvcWatchdogController.rejectedStatusToWatch;
                sa.Solution_Notes__c = 'FSL Is horrible';
            }
            update serviceAppointments;
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;

            Test.stopTest();

            serviceAppointments = [SELECT Id, Status FROM ServiceAppointment where id in :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assert(sa.status == 'Scheduled');
            }
            if(!utilityRejectedMdt.Disable_Rejected_PE__c) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Service_Appointment_Rejected_PE__e> serviceAppointmentRejectedPES =
                        ServiceAppointmentTriggerHandler.serviceAppointmentRejectedPES;

                for(Service_Appointment_Rejected_PE__e saPe : serviceAppointmentRejectedPES) {
                    system.assert(saPe.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
                    system.assert(saPe.Service_Appointment_Status__c == SvcWatchdogController.rejectedStatusToWatch);
                }
            }
        }
    }


        @isTest static void test_ServiceAppointment_NotDispatched_Positive() {
        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory
                    FROM    ServiceAppointment
                    LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;

            Test.startTest();

            update serviceAppointments;

            Test.stopTest();

            serviceAppointments = [SELECT Id, Status FROM ServiceAppointment where id in :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assert(sa.status == 'Scheduled');
            }
          // if(!utilityRejectedMdt.Disable_Rejected_PE__c) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Not_Dispatched_Platform_Event__e> serviceAppointmentNotDispatchedPES =
                        ServiceAppointmentTriggerHandler.serviceAppointmentNotDispatchedPES;

                //@TODO why isn't this assert working? System.assert(serviceAppointmentRejectedPES.size() == serviceAppointments.size());
                for(Not_Dispatched_Platform_Event__e saPe : serviceAppointmentNotDispatchedPES) {
                    system.assert(saPe.DML_Action__c == PlatformEventSvc.DML_ACTION_UPDATE);
                    system.assert(saPe.Service_Appointment_Status__c == 'Scheduled');
                }
        //    }
        }
    }
    @isTest static void test_ServiceAppointment_PE_Disabled() {
        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            // Boolean isItDisabled = utilityRejectedMdt.Disable_
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory
                    FROM    ServiceAppointment
                    LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;
            //--- must have the below for flow that clears the assigned resource.
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case];
            for(Case cse : cases) {
                cse.Assigned_Resource__c = null;
            }
            update cases;

            Test.startTest();

            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            for(ServiceAppointment sa : serviceAppointments) {
                sa.Status = SvcWatchdogController.rejectedStatusToWatch;
                sa.Solution_Notes__c = 'FSL Is horrible';
            }
            update serviceAppointments;

            Test.stopTest();

            serviceAppointments = [SELECT Id, Status FROM ServiceAppointment where id in :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assert(sa.status == SvcWatchdogController.rejectedStatusToWatch);
            }
            if(utilityRejectedMdt.Disable_Rejected_PE__c) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Service_Appointment_Rejected_PE__e> serviceAppointmentRejectedPES =
                        ServiceAppointmentTriggerHandler.serviceAppointmentRejectedPES;
                system.assert(serviceAppointmentRejectedPES.isEmpty());
            }
        }
    }
    @isTest static void test_ServiceAppointment_Reject_Negative() {
        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory
                    FROM    ServiceAppointment
                    LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;

            Test.startTest();

            update serviceAppointments;

            Test.stopTest();

            serviceAppointments = [SELECT Id, Status FROM ServiceAppointment where id in :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assert(sa.status == 'Scheduled');
            }
            if(!utilityRejectedMdt.Disable_Rejected_PE__c) {
                //@TODO  Not sure salesforce supports checking the PE Yet via event bus.. check static on handler
                List<Service_Appointment_Rejected_PE__e> serviceAppointmentRejectedPES =
                        ServiceAppointmentTriggerHandler.serviceAppointmentRejectedPES;
                System.assert(serviceAppointmentRejectedPES.isEmpty());
            }
        }
    }
    /**
     * Tests Validation Rule ServiceAppointment.Cannot_Complete_without_Solution focusing on Accel_Solution__C.
     * Note this is split into 2 unit test methods as processes / flows are causing too many soql queries.
     * Not much we can do about that other then rewrite them/properly bulkify them (if possible) or rewrite them into triggers.
     *
     * --(1)-- Tests the update of ServiceAppointment sObjects Status changed to Completed withOUT Accel_Solution__c.
     * --(2)-- Tests the update of ServiceAppointment sObjects Status changed to Completed WITH Accel_Solution__c.
     */
    @isTest static void test_ServiceAppointment_Completed_Without_AccelSolution_ValRule() {

        System.runAs(uCallCenter) {

            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  Id, Status, Solution_Notes__c, StatusCategory,Solution__c, Accel_Solution__c
                    FROM    ServiceAppointment
                    LIMIT   2
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = SA_SCHEDULED_STATUS;
            }
            update serviceAppointments;
            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            Map<Id,Solution__c> mAccelSolutionsByIds = new Map<Id,Solution__c>( [SELECT Id, Name FROM Solution__c] );
            Solution__c solution;
            //just grab one.
            for(Solution__c sol : mAccelSolutionsByIds.values()) {
                solution = sol;
                break;
            }
            Test.startTest();

            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = SA_COMPLETED_STATUS;
            }
            // --(1)-- Try to update a ServiceAppointment status to Completed without the lookup Accel_Solution__c populated.
            try {
                update serviceAppointments;
            } catch (Exception e) {
                System.assert( e.getMessage().contains( EX_VAL_RULE ) );
               //--- System.assert( e.getMessage().contains( SA_VAL_MSG_CANNOT_COMPLETE_WITHOUT_SOLUTION ) );
            }
            // --(2)-- Try to update a ServiceAppointment status to Completed WITH the lookup Accel_Solution__c populated.
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status               = SA_COMPLETED_STATUS;
                serviceAppointment.Accel_Solution__c    = solution.Id;
                serviceAppointment.Machine_Up_Upon_Departure__c = 'YES';
                serviceAppointment.Was_Software_Gameset_Changed__c = 'YES';
                serviceAppointment.Solution_Notes__c = 'blah good times tech notes';
            }
            update serviceAppointments;
            serviceAppointments = [SELECT Id, Status, ParentRecordId FROM ServiceAppointment WHERE Id IN :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assertEquals(sa.Status, SA_COMPLETED_STATUS);
            }

            //--- CEDRIC HERE  QUICK TEST tHAT SHOWS WHEN SA Status set to complted the processes got fired and copied it up.
            Set<Id> workOrderIds = new Set<Id>();
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                workOrderIds.add(serviceAppointment.ParentRecordId);
            }
            List<WorkOrder> workOrders = [
                    SELECT Id, Solution_Notes__c
                    FROM   WorkOrder
                    WHERE  Id  IN :workOrderIds
            ];
            for(WorkOrder workOrder : workOrders) {
                System.assert(workOrder.Solution_Notes__c != null); //  Boom they were copied via sa getting set to completed above.
            }
            //---- END MOCK TEST

            Test.stopTest();
        }
    }
   /**
    * Tests Validation Rule ServiceAppointment.Cannot_Complete_without_Solution. Note this is split into
    * as processes / flows are causing too many soql queries.
    *
    * --(1)-- Tests the update of ServiceAppointment sObjects Status changed to Completed withOUT Accel_Solution__c
    *         but with Solution__c.
    */
    @isTest static void test_ServiceAppointment_Completed_Without_Solution_ValRule() {

        System.runAs(uCallCenter) {

            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  Id, Status, Solution_Notes__c, StatusCategory,Solution__c, Accel_Solution__c,
                            Was_Software_Gameset_Changed__c
                    FROM    ServiceAppointment
                    LIMIT   2
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = SA_SCHEDULED_STATUS;
                serviceAppointment.Was_Software_Gameset_Changed__c = 'YES';
            }
            update serviceAppointments;
            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            Map<Id,Solution__c> mAccelSolutionsByIds = new Map<Id,Solution__c>( [SELECT Id, Name FROM Solution__c] );
            Solution__c solution;
            //just grab one.
            for(Solution__c sol : mAccelSolutionsByIds.values()) {
                solution = sol;
                break;
            }
            Test.startTest();

            // --(1)-- Tests the update of ServiceAppointment sObjects Status changed to Completed with Accel_Solution__c
            //         and with Solution__c.
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = SA_COMPLETED_STATUS;
                serviceAppointment.Solution__c = solution.name;
                serviceAppointment.Accel_Solution__c = solution.Id;
                serviceAppointment.Machine_Up_Upon_Departure__c = 'YES';
                serviceAppointment.Solution_Notes__c = 'TECH NOTES';
            }
            update serviceAppointments;
            serviceAppointments = [SELECT Id, Status FROM ServiceAppointment WHERE Id IN :serviceAppointments];
            for(ServiceAppointment sa : serviceAppointments) {
                System.assertEquals(sa.Status, SA_COMPLETED_STATUS);
            }
            Test.stopTest();
        }
    }
}