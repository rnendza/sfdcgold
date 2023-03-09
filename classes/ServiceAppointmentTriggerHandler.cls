/**
 * Business Logic intended to back ServiceAppointment
 */
public with sharing class ServiceAppointmentTriggerHandler {

    public static List<Service_Appointment_Rejected_PE__e>      serviceAppointmentRejectedPES       = new List<Service_Appointment_Rejected_PE__e>();
    public static List<Not_Dispatched_Platform_Event__e>        serviceAppointmentNotDispatchedPES  = new List<Not_Dispatched_Platform_Event__e>();
    public static List<Service_Appointment_Status_Change_PE__e> serviceAppointmentStatusChangePES   = new List<Service_Appointment_Status_Change_PE__e>();

   /**
    * On AFTER Update Runs an explicit update to copy ServiceAppointment.Accel_Solution__c to WorkOrder.Accel_Solution__c (Lookup)

    * @param    mOldServiceAppointments      Trigger.old of ServiceAppointment sObjects.
    * @param    mNewServiceAppointments      Trigger.new of ServiceAppointmentt sObjects.
    *
    * @return  List of WorkOrder sObjects that were explicitly updated (if any).
    */
    public static List<WorkOrder> updateWorkOrderSolution(  Map<Id,ServiceAppointment>  mOldServiceAppointments,
                                                            Map<Id,ServiceAppointment>  mNewServiceAppointments ) {

        List<WorkOrder>     workOrdersUpdated          = new List<WorkOrder>();
        Map<Id,Id>          mWorkOrderId_SolutionId    = new Map<Id,Id>();

        for(ServiceAppointment newServiceAppointment : mNewServiceAppointments.values()) {
            ServiceAppointment oldServiceAppointment = mOldServiceAppointments.get(newServiceAppointment.id);
            if(newServiceAppointment.Status == 'Completed' && newServiceAppointment.Status != oldServiceAppointment.Status) {
                if(newServiceAppointment.Accel_Solution__c != null) {
                    if(newServiceAppointment.ParentRecordId != null) {
                        Schema.SObjectType parentSobjectType = newServiceAppointment.ParentRecordId.getSObjectType();
                        String parentSObjectName = parentSobjectType.getDescribe().getName();
                        if(parentSObjectName == 'WorkOrder') {
                            mWorkOrderId_SolutionId.put(newServiceAppointment.ParentRecordId, newServiceAppointment.Accel_Solution__c);
                        }
                    }
                }
            }
        }
        if(!mWorkOrderId_SolutionId.isEmpty()) {
            List<WorkOrder> workOrders = [
                    SELECT  Id,Accel_Solution__c
                    FROM    WorkOrder
                    WHERE   Id IN :mWorkOrderId_SolutionId.keySet()
            ];
            if(!workOrders.isEmpty()) {
                for(WorkOrder wo : workOrders) {
                    Id solutionId = mWorkOrderId_SolutionId.get(wo.Id);
                    if(solutionId != null ) {
                        wo.Accel_Solution__c = solutionId;
                        workOrdersUpdated.add(wo);
                    }
                }
                try {
                    update workOrdersUpdated;
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR,e);
                }
            }
        }
        return  workOrdersUpdated;
    }
    /**
     * On Insert. Runs an implicit update to sync ServiceAppointment.Solution__c (PL) with Accel_Solution__c (Lookup)
     * @param newServiceAppointments    Trigger.new List of ServiceAppointment sObjects.
     * @return                          List of ServiceAppointment sObjects that were implicitly updated (if any).
     */
    public static List<ServiceAppointment> updateSolutionPicklist(List<ServiceAppointment> newServiceAppointments) {

        List<ServiceAppointment>    serviceAppointmentsUpdated  = new List<ServiceAppointment>();
        Set<Id>                     solutionIds       = new Set<Id>();

        for(ServiceAppointment serviceAppointment : newServiceAppointments) {
            if(serviceAppointment.Accel_Solution__c != null) {
                solutionIds.add(serviceAppointment.Accel_Solution__c);
            }
        }
        if(!solutionIds.isEmpty()) {
            Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                    SELECT  Id,Name
                    FROM    Solution__c
                    WHERE   Id IN :solutionIds
            ]);
            if(!mSolutionsByIds.isEmpty()) {
                for(ServiceAppointment sa : newServiceAppointments) {
                    Solution__c solution  = mSolutionsByIds.get(sa.Accel_Solution__c);
                    if(solution != null) {
                        sa.Solution__c = solution.Name;
                        serviceAppointmentsUpdated.add(sa);
                    }
                }
            }
        }
        return  serviceAppointmentsUpdated;
    }
   /**
    * On Update Runs an implicit update to sync ServiceAppointment.Solution__c (PL) with Accel_Solution__c (Lookup)
    * @param    oldSas      Trigger.old of Service Appointment sObjects.
    * @param    newSas      Trigger.new of Service Appointment sObjects.
    * @return  List of ServiceAppointment sObjects that were implicitly updated (if any).
    */
    public static List<ServiceAppointment> updateSolutionPicklist(  Map<Id,ServiceAppointment> mOldSas,
                                                                    Map<Id,ServiceAppointment> mNewSas) {

        List<ServiceAppointment>    serviceAppointmentsUpdated  = new List<ServiceAppointment>();
        Set<Id>                     solutionIds                 = new Set<Id>();

        Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                SELECT  Id,Name
                FROM    Solution__c
        ]);
        for(ServiceAppointment newSa : mNewSas.values()) {
            ServiceAppointment oldSa = mOldSas.get(newSa.id);

            try {
                System.debug('--------> newSa='+newSa.Status+'...'+newSa);
                System.debug('--------> oldSa='+oldSa.Status+'...'+oldSa);
                if (newSa.Accel_Solution__c != oldSa.Id) {
                    if (newSa.Accel_Solution__c != null) {
                        Solution__c solution = mSolutionsByIds.get(newSa.Accel_Solution__c);
                        if (solution != null) {
                            newSa.Solution__c = solution.Name;
                        } else {
                            newSa.Solution__c = null;
                        }
                        serviceAppointmentsUpdated.add(newSa);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
        }
        return  serviceAppointmentsUpdated;
    }
    /**
     * Looking at the parentId of the new ServiceAppointment, find it's WorkOrder.
     * If there is a location priority associated with the WorkOrder, use it to populate ServiceAppointment.Location_Priority__c.
     *
     * @param newServiceAppointments  Trigger.new for ServiceAppointment.
     * @return a list up implicitly updated ServiceAppointment sObjects.
     */
    public static List<ServiceAppointment> updateServiceLocationPriority(List<ServiceAppointment> newServiceAppointments) {

        List<ServiceAppointment> serviceAppointmentsUpdated = new List<ServiceAppointment>();
        Set<Id> parentIds = new Set<Id>(); //work orders most likely

        for (ServiceAppointment sa : newServiceAppointments) {
            parentIds.add(sa.ParentRecordId);
        }
        if (!parentIds.isEmpty()) {
            Map<Id, WorkOrder> mWorkOrdersByIds = new Map<Id, WorkOrder>([
                    SELECT Id,Location_Priority__c
                    FROM WorkOrder
                    WHERE Id IN :parentIds
            ]);
            if (!mWorkOrdersByIds.isEmpty()) {
                for (ServiceAppointment sa : newServiceAppointments) {
                    WorkOrder workOrder = mWorkOrdersByIds.get(sa.ParentRecordId);
                    if (workOrder != null) {
                        sa.Location_Priority__c = workOrder.Location_Priority__c;
                        serviceAppointmentsUpdated.add(sa);
                    }
                }
            }
        }
        return serviceAppointmentsUpdated;
    }
    /**
     * Looking at the parentId of the new ServiceAppointment, find it's related case (via WorkOrder).
     * If there is a service category associated with the case, use it to populate the Service Category on the
     * ServiceAppointment.
     *
     * @param newServiceAppointments  Trigger.new for ServiceAppointment.
     * @return a list up implicitly updated ServiceAppointment sObjects.
     */
    public static List<ServiceAppointment> updateServiceCategory(List<ServiceAppointment> newServiceAppointments) {

        List<ServiceAppointment> serviceAppointmentsUpdated = new List<ServiceAppointment>();
        Set<Id> parentIds = new Set<Id>(); //work orders most likely

        for (ServiceAppointment sa : newServiceAppointments) {
            parentIds.add(sa.ParentRecordId);
        }
        if (!parentIds.isEmpty()) {
            Map<Id, WorkOrder> mWorkOrdersByIds = new Map<Id, WorkOrder>([
                    SELECT Id,CaseId,Case.Service_Category__c
                    FROM WorkOrder
                    WHERE Id IN :parentIds
            ]);
            if (!mWorkOrdersByIds.isEmpty()) {
                for (ServiceAppointment sa : newServiceAppointments) {
                    WorkOrder workOrder = mWorkOrdersByIds.get(sa.ParentRecordId);
                    if (workOrder != null && workOrder.Case.Service_Category__c != null) {
                        sa.Service_Category__c = workOrder.Case.Service_Category__c;
                        serviceAppointmentsUpdated.add(sa);
                    }
                }
            }
        }
        return serviceAppointmentsUpdated;
    }
    /**
     *
     *
     * @param oldSaMap
     * @param newSaMap
     * @param dmlAction
     */
    public static void fireServiceAppointmentStatusChangePe(    Map<Id,ServiceAppointment>  oldSaMap,
                                                                Map<Id, ServiceAppointment> newSaMap,
                                                                String dmlAction ) {

        List<Service_Appointment_Status_Change_PE__e> pes = new List<Service_Appointment_Status_Change_PE__e>();
        Set<Id> validSaIds = new Set<Id>();
        for (ServiceAppointment newSa : newSaMap.values()) {
            ServiceAppointment oldSa = oldSaMap.get(newSa.Id);
            if (newSa.Status != null && newSa.Status != oldSa.Status) {
                validSaIds.add(newSa.id);
            }
        }
        //---- Get additional ServiceAppointment related fields beyond what a trigger provides)
        String soql = '';
        soql += ' SELECT    Id, Status, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, ';
        soql += '           Work_Order__r.Case.Assigned_Resource__c ';
        soql += ' FROM      ServiceAppointment ';
        soql += ' WHERE   Id  IN :validSaIds ';

        newSaMap = new Map<Id, ServiceAppointment> ((List<ServiceAppointment>) Database.query(soql));

        for (ServiceAppointment sa : newSaMap.values()) {
            ServiceAppointment oldSa  = oldSaMap.get(sa.Id);

            if (isEligibleToFireServiceAppointmentRejectPE(sa, dmlAction)) {
                Service_Appointment_Status_Change_PE__e pe = new Service_Appointment_Status_Change_PE__e();
                pe.Service_Appointment_Id__c = sa.Id;
                pe.Previous_Service_Appointment_Status__c = oldSa.status;
                pe.Service_Appointment_Status__c = sa.Status;
                pe.DML_Action__c = dmlAction;
                pes.add(pe);
            }
        }
        if (!pes.isEmpty()) {
            serviceAppointmentStatusChangePES.addAll(pes);
            System.debug(LoggingLevel.INFO, 'FIRING PE for status change UPDATE');
            PlatformEventSvc.publishPlatformEvents(pes);
        }
        if (newSaMap.values().isEmpty()) {
            System.debug(LoggingLevel.WARN, 'NO SERVICE APPOINTMENTS FOUND FOR FIRING PE FOR UPDATE for status change');
        }
    }
    /**
     *
     *
     * @param oldSaMap
     * @param newSaMap
     * @param dmlAction
     */
    public static void fireServiceAppointmentNotDispatchedPlatformEvent(Map<Id, ServiceAppointment> oldSaMap,
            Map<Id, ServiceAppointment> newSaMap,
            String dmlAction) {

        List<Not_Dispatched_Platform_Event__e> pes = new List<Not_Dispatched_Platform_Event__e>();
        Set<Id> validSaIds = new Set<Id>();
        for (ServiceAppointment newSa : newSaMap.values()) {
            ServiceAppointment oldSa = oldSaMap.get(newSa.Id);
            if (newSa.Status != null && newSa.Status.equalsIgnoreCase('Scheduled')
                    && oldSa.Status != 'Scheduled') {
                validSaIds.add(newSa.id);
            }
        }
        //---- Get additional ServiceAppointment related fields beyond what a trigger provides)
        Set<Id> saIds = validSaIds;
        String caseStatusExclude = 'Closed';
        String soql = '';
        soql += ' SELECT    Id, Status, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, ';
        soql += '           Work_Order__r.Case.Assigned_Resource__c ';
        soql += ' FROM      ServiceAppointment ';
        soql += ' WHERE     Id  IN :validSaIds ';
        soql += ' AND       Work_Order__r.Case.Status != :caseStatusExclude ';
        soql += ' AND       CreatedDate >= YESTERDAY ';
        newSaMap = new Map<Id, ServiceAppointment> ((List<ServiceAppointment>) Database.query(soql));
        for (ServiceAppointment sa : newSaMap.values()) {
            ServiceAppointment oldSa = oldSaMap.get(sa.Id);
            if (isEligibleToFireServiceAppointmentRejectPE(sa, dmlAction)) {
                Not_Dispatched_Platform_Event__e pe = new Not_Dispatched_Platform_Event__e();
                pe.Service_Appointment_Id__c = sa.Id;
                pe.Previous_Service_Appointment_Status__c = oldSa.status;
                pe.Service_Appointment_Status__c = sa.Status;
                pe.DML_Action__c = dmlAction;
                pes.add(pe);
            }
        }
        if (!pes.isEmpty()) {
            serviceAppointmentNotDispatchedPES.addAll(pes);
            System.debug(LoggingLevel.INFO, 'FIRING PE for not dispatched  UPDATE');
            PlatformEventSvc.publishPlatformEvents(pes);
        }
        if (newSaMap.values().isEmpty()) {
            System.debug(LoggingLevel.WARN, 'NO SERVICE APPOINTMENTS FOUND FOR FIRING PE FOR UPDATE for not dispatched');
        }
    }

    /**
     *
     *
     * @param oldSaMap
     * @param newSaMap
     * @param dmlAction
     */
    public static void fireServiceAppointmentRejectedPlatformEvent( Map<Id,ServiceAppointment>  oldSaMap,
                                                                    Map<Id, ServiceAppointment> newSaMap, String dmlAction ) {

            List<Service_Appointment_Rejected_PE__e> saPes = new List<Service_Appointment_Rejected_PE__e>();

            Set<Id> validSaIds = new Set<Id>();
            for (ServiceAppointment newSa : newSaMap.values()) {
                ServiceAppointment oldSa = oldSaMap.get(newSa.Id);
                if(newSa.Status != null && newSa.Status.equalsIgnoreCase(SvcWatchdogController.rejectedStatusToWatch)
                        && oldSa.Status != SvcWatchdogController.rejectedStatusToWatch) {
                    validSaIds.add(newSa.id);
                }
            }
            //---- Get additional ServiceAppointment related fields beyond what a trigger provides)
            Set<Id> saIds = validSaIds;
            String soql = '';
            soql += ' SELECT    Id, Status, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, ';
            soql += '           Work_Order__r.Case.Assigned_Resource__c ';
            soql += ' FROM      ServiceAppointment ';
            soql += ' WHERE     Id  IN :validSaIds ';

            newSaMap = new Map<Id, ServiceAppointment> ((List<ServiceAppointment>) Database.query(soql));

            for (ServiceAppointment sa : newSaMap.values()) {
                if (isEligibleToFireServiceAppointmentRejectPE(sa, dmlAction)) {
                    ServiceAppointment oldSa = oldSaMap.get(sa.Id);
                    Service_Appointment_Rejected_PE__e pe = new Service_Appointment_Rejected_PE__e();
                    pe.Service_Appointment_Id__c = sa.Id;
                    pe.Previous_Service_Appointment_Status__c = oldSa.Status;
                    pe.Service_Appointment_Status__c = sa.Status;
                    pe.DML_Action__c = dmlAction;
                    System.debug(LoggingLevel.INFO,'adding rejected pe:'+pe);
                    saPes.add(pe);
                }
                if (!saPes.isEmpty()) {
                    serviceAppointmentRejectedPES.addAll(saPes);
                    System.debug(LoggingLevel.INFO, 'FIRING PE for UPDATE FOR REJECTED');
                    PlatformEventSvc.publishPlatformEvents(saPes);
                }
            }
            if (newSaMap.values().isEmpty()) {
                System.debug(LoggingLevel.WARN, 'NO SERVICE APPOINTMENTS FOUND FOR FIRING PE FOR UPDATE');
            }
    }


    /**
     * Evaluate the Service Appointment to determine if we need to fire the platform event.
     *
     * @param sa   A Service Appointment sObject. Minimally requires sa.CreatedBy.Profile.Name, sa.CreatedBy.Name
     * @return True if we can fire the Platform Event, Otherwise False.
     */
    @TestVisible
    private static Boolean isEligibleToFireServiceAppointmentRejectPE( ServiceAppointment sa, String dmlAction) {
        Boolean doIt = false;

        String createdByOverride        = '';
        if( SvcWatchdogController.rejectedCreatedByOverride != null) {
            createdByOverride = SvcWatchdogController.rejectedCreatedByOverride.replaceAll('%',''); //might be wild carded for a like clause.
        }
        System.debug('accel sa created by profile name='+sa.createdby.profile.name);
        System.debug('accel override = '+createdByOverride);
        System.debug('accel SvcWatchdogController.noAssignedResourceProfileNames='+SvcWatchdogController.noAssignedResourceProfileNames);

        if(dmlAction == PlatformEventSvc.DML_ACTION_INSERT || dmlAction == PlatformEventSvc.DML_ACTION_DELETE) {

        } else if (dmlAction == PlatformEventSvc.DML_ACTION_UPDATE) {
            if (SvcWatchdogController.rejectedProfileNames.contains(sa.CreatedBy.Profile.Name)
                    || sa.CreatedBy.Name.contains(createdByOverride)
                    || SvcWatchdogController.noAssignedResourceProfileNames.contains(sa.createdby.profile.name)) {
                doIt = true;
            }
        }
        return doIt;
    }
}