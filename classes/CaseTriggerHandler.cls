/**
 * Business Logic intended to back Case Triggers.
 */
public with sharing class CaseTriggerHandler {

    public static List<Exception> exceptions = new List<Exception>();
    public static List<Case_Assigned_Resource_PE__e>    caseAssignedResourcePES = new List<Case_Assigned_Resource_PE__e>();
    public static List<Case_Closed_PE__e>               caseClosedPES           = new List<Case_Closed_PE__e>();

    /**
     *
     * Prepend *67 on Case.Caller_Phone__c (Which supposedly is only used by the call center) if it doesn't already
     * exist upon Initial Creation of the case.
     *
     * @param newCases Trigger.new List of Case sObjects.
     * @return   List of Case sObjects that were implicitly updated (if any).
     */
    public static List<Case> flagCallerPhoneWithStar67(List<Case> newCases) {
        List<Case>    casesUpdated    = new List<Case>();

        for(Case cse : newCases) {
            if(cse.Caller_Phone__c != null && cse.Caller_Phone__c != '') {
                if(!(cse.Caller_Phone__c.trim().contains('*67'))) {
                    cse.Caller_Phone__c = '*67' +cse.Caller_Phone__c;
                    casesUpdated.add(cse);
                }
            }
        }
        return  casesUpdated;
    }
   /**
    * On Insert.         Runs an implicit update to sync Case.Solution__c (PL) with Accel_Solution__c (Lookup)
    * @param newCases    Trigger.new List of Case sObjects.
    * @return             List of Case sObjects that were implicitly updated (if any).
    */
    public static List<Case> updateSolutionPicklist(List<Case> newCases) {

        List<Case>    casesUpdated    = new List<Case>();
        Set<Id>       solutionIds     = new Set<Id>();

        for(Case cse : newCases) {
            if(cse.Accel_Solution__c != null) {
                solutionIds.add(cse.Accel_Solution__c);
            }
        }
        if(!solutionIds.isEmpty()) {
            Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                    SELECT  Id,Name
                    FROM    Solution__c
                    WHERE   Id IN :solutionIds
            ]);
            if(!mSolutionsByIds.isEmpty()) {
                for(Case cse : newCases) {
                    Solution__c solution  = mSolutionsByIds.get(cse.Accel_Solution__c);
                    if(solution != null) {
                        cse.Solution__c = solution.Name;
                        casesUpdated.add(cse);
                    }
                }
            }
        }
        return  casesUpdated;
    }
    /**
     * On Update Runs an implicit update to sync Case.Solution__c (PL) with Accel_Solution__c (Lookup)
     * @param    oldWos      Trigger.old of Case sObjects.
     * @param    newWos      Trigger.new of Case sObjects.
     * @return  List of Case sObjects that were implicitly updated (if any).
     */
    public static List<Case> updateSolutionPicklist(  Map<Id,Case> mOldCases, Map<Id,Case> mNewCases ) {

        List<Case>    casesUpdated  = new List<Case>();
        Set<Id>       solutionIds        = new Set<Id>();

        Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                SELECT  Id,Name
                FROM    Solution__c
        ]);
        try {
            for (Case newCase : mNewCases.values()) {
                Case oldCase = mOldCases.get(newCase.id);
                if (newCase.Accel_Solution__c != oldCase.Id) {
                    if (newCase.Accel_Solution__c != null) {
                        Solution__c solution = mSolutionsByIds.get(newCase.Accel_Solution__c);
                        if (solution != null) {
                            newCase.Solution__c = solution.Name;
                        } else {
                            newCase.Solution__c = null;
                        }
                        casesUpdated.add(newCase);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
        }
        return  casesUpdated;
    }
    /**
     * If the case caller phone number changed, reflect it on associated child work orders.
     *
     * @param oldCaseMap   Trigger.new map of Case sObjects.
     * @param newCaseMap   Trigger.old map of Case sObjects.
     * @return  a List of updated WorkOrder sObject if any.
     */
    public static List<WorkOrder> evalCaseForCallerPhoneMods(   Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap) {
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();
        Map<Id,Case> mCasesByIds = new Map<Id,Case>();
        if( oldCaseMap != null && !oldCaseMap.isEmpty() ) {
            // UPDATE OF A CASE
            for(Case newCase : newCaseMap.values() ) {
                Case oldCase = oldCaseMap.get(newCase.id);
                if(newCase.Caller_Phone__c != oldCase.Caller_Phone__c) {
                    mCasesByIds.put(newCase.Id,newCase);
                }
            }
        }
        if( !mCasesByIds.isEmpty() ) {
            updatedWorkOrders = updateWorkOrderCallerPhone( mCasesByIds );
        }
        return updatedWorkOrders;
    }
    /**
     * Finds all child work orders of the case and update WorkOrder.Caller_Phone__c with the value
     * in Case.Caller_Phone__c.
     *
     * @param caseMap a map of caseId => Case.
     * @return  a list of WorkOrders updated if any.
     */
    public static List<WorkOrder> updateWorkOrderCallerPhone( Map<Id, Case> caseMap ) {
        List<WorkOrder> updatedWorkOrders = new List<WorkOrder>();
        Map<Id, WorkOrder> mWorkOrdersByIds = new Map<Id, WorkOrder>([
                SELECT  Id, CaseId, Caller_Phone__c
                FROM    WorkOrder
                WHERE   CaseId IN :caseMap.keySet()
                AND     Caller_Phone__c = NULL
        ]);

        if (!mWorkOrdersByIds.isEmpty()) {
            for (WorkOrder wo : mWorkOrdersByIds.values()) {
                wo.Caller_Phone__c = caseMap.get(wo.CaseId).Caller_Phone__c;
                updatedWorkOrders.add(wo);
            }
            //note if there are bad legacy sa's not abiding by validation rules put on without fixing data.
            //this might throw an ex. the caller (ie Accel_CaseTrigger ) can catch that if it chooses to.
            update updatedWorkOrders;
        }
        return updatedWorkOrders;
    }
    /**
     * Handles the update of a Case.
     *
     * 1. Checks to see if Case.Service_Category__c was modified.
     *    a. If so query for all ServiceAppointments related to the work order related to the case.
     *    b. Ensure that ServiceAppointment.Service_Category__c = Case.Service_Category__c;
     *    c. Update the ServiceAppointments and return those updated (if any)
     *
     * @param oldCaseMap    A Map of CaseId => Case for new case sObjects.
     * @param newCaseMap    A Map of CaseId => Case for old case sObjects.
     *
     * @return  a List of explicitly updated ServiceAppointments (if any).
     */
    public static List<ServiceAppointment> evalCaseForServiceAppointmentMods(   Map<Id, Case> oldCaseMap,
                                                                                Map<Id, Case> newCaseMap) {

        List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();
        if (oldCaseMap != null && !oldCaseMap.isEmpty()) {
            //----This is an Update of an Case.  See if the field was modified.
            Map<Id,Case> mCasesByIds = new Map<Id,Case>();
            for (Case newCase : newCaseMap.values()) {
                Case oldCase = oldCaseMap.get(newCase.id);
                if (newCase.Service_Category__c != oldCase.Service_Category__c) {
                    mCasesByIds.put(newCase.Id,newCase);
                }
            }
            if(!mCasesByIds.isEmpty()) {
                updatedServiceAppointments = updateServiceAppointments(mCasesByIds);
            }
        }
        return updatedServiceAppointments;
    }
    /**
     * Take the Map of modified Cases and Query for ServiceAppointment related to the work orders that are related
     * to the case. Updates ServiceAppointment.Service_Category__c to match Case.Service_Category__c.
     *
     * @param mCasesByIds  a Map of CaseId => Case.
     * @return a List of ServiceAppointment sObjects (if any)
     */
    @TestVisible
    private static List<ServiceAppointment> updateServiceAppointments( Map<Id, Case> mCasesByIds ) {

        List<ServiceAppointment> updatedServiceAppointments = new List<ServiceAppointment>();
        Map<Id,ServiceAppointment> mServiceAppointmentsByIds = new Map<Id,ServiceAppointment>([
                SELECT  Id, Work_Order__r.CaseId, Service_Category__c
                FROM    ServiceAppointment
                WHERE   Work_Order__r.CaseId In :mCasesByIds.keySet()
        ]);
        if(!mServiceAppointmentsByIds.isEmpty()) {
            Map<Id,ServiceAppointment> mCaseId_ServiceAppointment = new Map<Id,ServiceAppointment>();
            for(ServiceAppointment sa : mServiceAppointmentsByIds.values()) {
                mCaseId_ServiceAppointment.put(sa.Work_Order__r.CaseId,sa);
                sa.Service_Category__c = mCasesByIds.get(sa.Work_Order__r.CaseId).Service_Category__c;
                updatedServiceAppointments.add(sa);
            }
            //note if there are bad legacy sa's not abiding by validation rules put on without fixing data.
            //this might throw an ex. the caller (ie Accel_CaseTrigger ) can catch that if it chooses to.
            update updatedServiceAppointments;
        }
        return updatedServiceAppointments;
    }
    /**
   * Fires a platform event to be consumed by clients if applicable on UPDATE of a case when  a case is closed.
   *
   * @param oldCaseMap        Trigger.old map of Case sObjects.
   * @param newCaseMap        Trigger.new map of Case sObjects.
   * @param dmlAction         UPDATE
   *
   * @See PlatformEventSvc
   */
    public static void fireCaseClosedPlatformEvent(Map<Id, Case> oldCaseMap, Map<Id, Case> newCaseMap,
            String dmlAction) {

        List<Case_Closed_PE__e> casePes = new List<Case_Closed_PE__e>();
        Set<Id> validCaseIds = new Set<Id>();
        for (Case newCase : newCaseMap.values()) {
            Case oldCase = oldCaseMap.get(newCase.Id);
            if (newCase.Status == 'Closed' && oldCase.Status != 'Closed') {
                validCaseIds.add(newCase.id);
            }
        }
        //---- Get additional case related fields beyond what a trigger provides)
        Set<Id> caseIds = validCaseIds;
        String soql = '';
        soql += ' SELECT  Id, Status, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name ';
        soql += ' FROM    Case ';
        soql += ' WHERE   Id  IN :caseIds ';

        newCaseMap = new Map<Id, Case> ((List<Case>) Database.query(soql));
        for (Case cse : newCaseMap.values()) {
            if (isEligibleToFireCaseAssignedResourcePE(cse, dmlAction)) {
                Case_Closed_PE__e pe = new Case_Closed_PE__e();
                pe.Case_Id__c = cse.Id;
                pe.Case_Status__c = cse.Status;
                pe.Date_Time_Opened__c = cse.CreatedDate;
                pe.DML_Action__c = dmlAction;
                casePes.add(pe);
            }
        }
        if (!casePes.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'rjn FIRING PE for CASE CLOSED UPDATE PE:' + casePes);
            caseClosedPES.addAll(casePes);
            PlatformEventSvc.publishPlatformEvents(casePes);
        }
        if (newCaseMap.values().isEmpty()) {
            System.debug(LoggingLevel.WARN, 'rjn NO CASES FOUND FOR FIRING PE FOR CASE closed for  dmlaction:' + dmlAction);
        }
    }
    /**
     * Fires a platform event to be consumed by clients if applicable on UPDATE of a case when an Assigned Resource
     * As Added or Removed..
     *
     * @param oldCaseMap        Trigger.old map of Case sObjects.
     * @param newCaseMap        Trigger.new map of Case sObjects.
     * @param dmlAction         UPDATE
     *
     * @See PlatformEventSvc
     */
    public static void fireCaseNoAssignedResourcePlatformEvent( Map<Id,Case> oldCaseMap,  Map<Id, Case> newCaseMap,
                                                                String dmlAction ) {
        if(RecursiveTriggerHandler.isFirstTime) {
            RecursiveTriggerHandler.isFirstTime = false;

            List<Case_Assigned_Resource_PE__e> casePes = new List<Case_Assigned_Resource_PE__e>();
            Set<Id> validCaseIds = new Set<Id>();
            for (Case newCase : newCaseMap.values()) {
                Case oldCase = oldCaseMap.get(newCase.Id);
                if (newCase.Assigned_Resource__c != oldCase.Assigned_Resource__c) {
                    validCaseIds.add(newCase.id);
                }
            }
            //---- Get additional case related fields beyond what a trigger provides)
            Set<Id> caseIds = validCaseIds;
            String soql = '';
            soql += ' SELECT  Id, Status, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, Assigned_Resource__c ';
            soql += ' FROM    Case ';
            soql += ' WHERE   Id  IN :caseIds ';

            newCaseMap = new Map<Id, Case> ((List<Case>) Database.query(soql));
            for (Case cse : newCaseMap.values()) {
                if (isEligibleToFireCaseAssignedResourcePE(cse, dmlAction)) {
                    Case_Assigned_Resource_PE__e pe = new Case_Assigned_Resource_PE__e();
                    pe.Case_Id__c = cse.Id;
                    pe.Case_Status__c = cse.Status;
                    pe.Date_Time_Opened__c = cse.CreatedDate;
                    pe.Case_Assigned_Resource_Id__c = cse.Assigned_Resource__c;
                    pe.DML_Action__c = dmlAction;
                    casePes.add(pe);
                }
            }
            if (!casePes.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'rjn FIRING PE for UPDATE PE:'+casePes);
                caseAssignedResourcePES.addAll(casePes);
                PlatformEventSvc.publishPlatformEvents(casePes);
            }
            if (newCaseMap.values().isEmpty()) {
                System.debug(LoggingLevel.WARN, 'rjn NO CASES FOUND FOR FIRING PE FOR dmlaction:'+dmlAction);
            }
        }
    }
    /**
     * Fires a platform event to be consumed by clients if applicable on insert or delete of case.
     *
     * @param caseMap    A Map of Case Id => Case. Can be Trigger.newMap or Trigger.oldMap depending on the Context.
     * @param dmlAction  DELETE, INSERT
     *
     * @See PlatformEventSvc
     */
    public static void fireCaseNoAssignedResourcePlatformEvent(   Map<Id, Case> caseMap, String dmlAction ) {
        List<Case_Assigned_Resource_PE__e> casePes = new List<Case_Assigned_Resource_PE__e>();

        //---- Get additional case related fields beyond what a trigger provides)
        Set<Id> caseIds = caseMap.keySet();
        String soql = '';
        soql += ' SELECT  Id, Status, CreatedDate, CreatedBy.Name, CreatedBy.Profile.Name, Assigned_Resource__c ';
        soql += ' FROM    Case ';
        soql += ' WHERE   Id  IN :caseIds ';
        if(dmlAction == PlatformEventSvc.DML_ACTION_UPDATE) {
            System.debug(LoggingLevel.DEBUG,'looking for updated case ids:'+caseIds);
        }
        if(dmlAction == PlatformEventSvc.DML_ACTION_DELETE) {
            System.debug(LoggingLevel.DEBUG,'looking for deleted case ids:'+caseIds);
            soql += ' AND IsDeleted = true ';
            soql += ' ALL ROWS ';
        }
        if(dmlAction == PlatformEventSvc.DML_ACTION_INSERT) {
            System.debug(LoggingLevel.DEBUG,'looking for insert case ids:'+caseIds);
        }
        caseMap = new Map<Id,Case> ( (List<Case>) Database.query(soql) );
        for (Case cse : caseMap.values()) {
            if(isEligibleToFireCaseAssignedResourcePE( cse, dmlAction )) {
                Case_Assigned_Resource_PE__e pe = new Case_Assigned_Resource_PE__e();
                pe.Case_Id__c           = cse.Id;
                pe.Case_Status__c       = cse.Status;
                pe.Date_Time_Opened__c  = cse.CreatedDate;
                pe.Case_Assigned_Resource_Id__c = cse.Assigned_Resource__c;
                pe.DML_Action__c        = dmlAction;
                casePes.add(pe);
            } else {
                system.debug('case not elilible. status='+cse.status + ' created by name='+cse.createdby.name);
            }
            if(!casePes.isEmpty()) {
                System.debug(LoggingLevel.INFO,'FIRING PE with PES='+casePes);
                PlatformEventSvc.publishPlatformEvents(casePes);
            }
        }
        if(caseMap.values().isEmpty()) {
            System.debug(LoggingLevel.WARN,'NO CASES FOUND FOR FIRING PE for dmlaction='+dmlAction);
        }
    }
    /**
     * Evaluate the case to determine if we need to fire the platform event.
     *
     * @param cse   A Case sObject. Minimally requires cse.Status, case.CreatedBy.Profile.Name, case.CreatedBy.Name
     * @return True if we can fire the Platform Event, Otherwise False.
     */
    @TestVisible
    private static Boolean isEligibleToFireCaseAssignedResourcePE( Case cse, String dmlAction ) {
        Boolean doIt = false;
        String createdByOverride        = '';
        if( SvcWatchdogController.noAssignedResourceCreatedByOverride != null) {
            createdByOverride = SvcWatchdogController.noAssignedResourceCreatedByOverride.replaceAll('%',''); //might be wild carded for a like clause.
        }
        if(dmlAction == PlatformEventSvc.DML_ACTION_INSERT || dmlAction == PlatformEventSvc.DML_ACTION_DELETE) {
            if (cse.Status != null && cse.Status == SvcWatchdogController.noAssignedResourceStatusToWatch
                        && (SvcWatchdogController.noAssignedResourceProfileNames.contains(cse.CreatedBy.Profile.Name)
                    || cse.CreatedBy.Name.contains(createdByOverride))) {
                doIt = true;
            }
        } else if (dmlAction == PlatformEventSvc.DML_ACTION_UPDATE) {
            system.debug('rjn created by profile name='+cse.CreatedBy.Profile.Name);
            if (SvcWatchdogController.noAssignedResourceProfileNames.contains(cse.CreatedBy.Profile.Name)
                    || cse.CreatedBy.Name.contains(createdByOverride)) {
                doIt = true;
            }
        }
        return doIt;
    }
}