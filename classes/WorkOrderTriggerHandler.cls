/**
 * Contains all business logic backing trigger events on WorkOrder.
 */
public with sharing class WorkOrderTriggerHandler {

//    public static Map<String,String> mPriorityTranslation =
//            new Map<String, String>{'A' => 'HIGH PRIORITY', 'B' => 'MEDIUM PRIORITY', 'C' => 'LOW PRIORITY'};
    public static Map<String,String> mPriorityTranslation =
            new Map<String, String>{'A' => 'HIGH PRIORITY',  'C' => 'LOW PRIORITY'};

    /**
    * On AFTER Update Runs an explicit update to copy WorkOrder.Accel_Solution__c to Case.Accel_Solution__c (Lookup)
    * @param    oldWos      Trigger.old of WorkOrder sObjects.
    * @param    newWos      Trigger.new of WorkOrder sObjects.
    * @return  List of WorkOrder sObjects that were implicitly updated (if any).
    */
    public static List<Case> updateCaseSolution(  Map<Id,WorkOrder> mOldWos,
                                                  Map<Id,WorkOrder> mNewWos ) {

        List<Case>      casesUpdated        = new List<Case>();
        Map<Id,Id>      mCaseId_SolutionId  = new Map<Id,Id>();

        for(WorkOrder newWo : mNewWos.values()) {
            WorkOrder oldWo = mOldWos.get(newWo.id);
            if(newWo.Status == 'Completed' && newWo.Status != oldWo.Status) {
                if(newWo.CaseId != null && newWo.Accel_Solution__c != null) {
                    mCaseId_SolutionId.put(newWo.CaseId,newWo.Accel_Solution__c);
                }
            }
        }
        if(!mCaseId_SolutionId.isEmpty()) {
            List<Case> cases = [
                    SELECT  Id,Accel_Solution__c
                    FROM    Case
                    WHERE   Id IN :mCaseId_SolutionId.keySet()
            ];
            if(!cases.isEmpty()) {
                for(Case cse : cases) {
                    Id solutionId = mCaseId_SolutionId.get(cse.Id);
                    if(solutionId != null ) {
                        cse.Accel_Solution__c = solutionId;
                        casesUpdated.add(cse);
                    }
                }
                try {
                    update casesUpdated;
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR,e);
                }
            }
        }
        return  casesUpdated;
    }
    /**
     * On Insert. Runs an implicit update to sync WorkOrder.Solution__c (PL) with Accel_Solution__c (Lookup)
     * @param newWorkOrders    Trigger.new List of WorkOrder sObjects.
     * @return                 List of WorkOrder sObjects that were implicitly updated (if any).
     */
    public static List<WorkOrder> updateSolutionPicklist(List<WorkOrder> newWorkOrders) {

        List<WorkOrder>    workOrdersUpdated    = new List<WorkOrder>();
        Set<Id>            solutionIds          = new Set<Id>();

        for(WorkOrder workOrder : newWorkOrders) {
            if(workOrder.Accel_Solution__c != null) {
                solutionIds.add(workOrder.Accel_Solution__c);
            }
        }
        if(!solutionIds.isEmpty()) {
            Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                    SELECT  Id,Name
                    FROM    Solution__c
                    WHERE   Id IN :solutionIds
            ]);
            if(!mSolutionsByIds.isEmpty()) {
                for(WorkOrder sa : newWorkOrders) {
                    Solution__c solution  = mSolutionsByIds.get(sa.Accel_Solution__c);
                    if(solution != null) {
                        sa.Solution__c = solution.Name;
                        workOrdersUpdated.add(sa);
                    }
                }
            }
        }
        return  workOrdersUpdated;
    }
    /**
     * On Update Runs an implicit update to sync WorkOrder.Solution__c (PL) with Accel_Solution__c (Lookup)
     * @param    oldWos      Trigger.old of Service Appointment sObjects.
     * @param    newWos      Trigger.new of Service Appointment sObjects.
     * @return  List of WorkOrder sObjects that were implicitly updated (if any).
     */
    public static List<WorkOrder> updateSolutionPicklist(  Map<Id,WorkOrder> mOldWos,
                                                           Map<Id,WorkOrder> mNewWos ) {

        List<WorkOrder>    workOrdersUpdated  = new List<WorkOrder>();
        Set<Id>            solutionIds        = new Set<Id>();

        Map<Id, Solution__c> mSolutionsByIds = new Map<Id, Solution__c> ([
                SELECT  Id,Name
                FROM    Solution__c
        ]);
        for(WorkOrder newSa : mNewWos.values()) {
            WorkOrder oldSa = mOldWos.get(newSa.id);
            try {
                if (newSa.Accel_Solution__c != oldSa.Id) {
                    if (newSa.Accel_Solution__c != null) {
                        Solution__c solution = mSolutionsByIds.get(newSa.Accel_Solution__c);
                        if (solution != null) {
                            newSa.Solution__c = solution.Name;
                        } else {
                            newSa.Solution__c = null;
                        }
                        workOrdersUpdated.add(newSa);
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
        }
        return  workOrdersUpdated;
    }
  /**
   * On insert of a new work order, look at the caseId of the new WorkOrder. Find it's related case.
   * If there is a caller_phone__c associated with the case, use it to populate the caller_phone__c on the WorkOrder.
   *
   * @param newWorkOrders  Trigger.new for WorkOrders
   * @return a list up implicitly updated WorkOrder sObjects.
   */
    public static List<WorkOrder> updateWorkOrderCallerPhone(List<WorkOrder> newWorkOrders) {

        List<WorkOrder> workOrdersUpdated = new List<WorkOrder>();
        Set<Id> caseIds = new Set<Id>(); //work orders most likely

        for (WorkOrder wo : newWorkOrders) {
            caseIds.add(wo.caseId);
        }
        if (!caseIds.isEmpty()) {
            Map<Id, Case> mCasesByIds = new Map<Id, Case>([
                    SELECT  Id,Caller_Phone__c
                    FROM    Case
                    WHERE   Id IN :caseIds
            ]);
            if (!mCasesByIds.isEmpty()) {
                for (WorkOrder wo : newWorkOrders) {
                    Case cse = mCasesByIds.get(wo.CaseId);
                    if (cse != null) {
                        if(wo.Caller_Phone__c == null) {
                            wo.Caller_Phone__c = cse.Caller_Phone__c;
                        }
                        workOrdersUpdated.add(wo);
                    }
                }
            }
        }
        return workOrdersUpdated;
    }
   /**
    * Maps WorkOrder.Priority to WorkOrder.Location_Priority__c for Call Center team display purposes.
    *
    * @param mOldWOs
    * @param newWOs
    *
    * Note since a process builder is run on this on create / edit. this will technically handle an insert as well.
    *
    * @see https://accelentertainment.atlassian.net/jira/software/projects/SFSERVICE/boards/9?selectedIssue=SFSERVICE-6
    * @return  Implicitly updated WorkOrder sObjects if applicable.
    */
    public static List<WorkOrder> updateWorkOrderLocationPriority(Map<Id,WorkOrder> mOldWOs, Map<Id,WorkOrder> newWOs ) {

        List<WorkOrder> workOrdersUpdated = new List<WorkOrder>();

        for(WorkOrder newWo : newWOs.values()) {
            WorkOrder oldWo = mOldWOs.get(newWo.Id);
            if(newWo.Priority != oldWo.Priority || (newWo.Location_Priority__c == null)) {
                if(newWo.Priority == null || !mPriorityTranslation.containsKey(newWo.Priority)) {
                    newWo.Location_Priority__c  =  null;
                    workOrdersUpdated.add(newWo);
                } else {
                    String translatedPriority = mPriorityTranslation.get(newWo.Priority);
                    if(translatedPriority != null) {
                        newWo.Location_Priority__c = translatedPriority;
                        workOrdersUpdated.add(newWo);
                    }
                }
            }
        }
        return workOrdersUpdated;
    }
    /**
     * Rolls through updated work orders and if the new work order caller phone is not eq to the old work order
     * caller phone, goes up to the parent case and updates the caller phone on the case with the new caller phone
     * on the work order.
     *
     * @param mOldWoMap   Trigger.newMap for WorkOrders
     * @param mNewWoMap   Trigger.oldMap for WorkOrders
     * @return a List of Cases updated (if any).
     */
    public static List<Case> updateCaseCallerPhone(Map<Id,WorkOrder> mOldWoMap, Map<Id,WorkOrder> mNewWoMap) {

        List<Case> casesUpdated = new List<Case>();
        Set<Id> caseIds = new Set<Id>(); //work orders most likely
        Set<WorkOrder> workOrdersToProcess = new Set<WorkOrder>();

        for (WorkOrder newWo : mNewWoMap.values()) {
            WorkOrder oldWo = mOldWoMap.get(newWo.id);
            if(newWo.Caller_Phone__c != oldWo.Caller_Phone__c) {
                if(newWo.CaseId != null) {
                    caseIds.add(newWo.CaseId);
                    workOrdersToProcess.add(newWo);
                }
            }
        }
        if (!caseIds.isEmpty()) {
            Map<Id, Case> mCasesByIds = new Map<Id, Case>([
                    SELECT  Id,Caller_Phone__c
                    FROM    Case
                    WHERE   Id IN :caseIds
            ]);
            if (!mCasesByIds.isEmpty()) {
                for (WorkOrder wo : workOrdersToProcess) {
                    Case cse = mCasesByIds.get(wo.CaseId);
                    if (cse != null) {
                        cse.Caller_Phone__c = wo.Caller_Phone__c;
                        casesUpdated.add(cse);
                    }
                }
                if(!casesUpdated.isEmpty()) {
                    try {
                        update casesUpdated;
                    } catch (Exception e) {
                        System.debug(LoggingLevel.ERROR,e);
                    }
                }
            }
        }
        return casesUpdated;
    }
}