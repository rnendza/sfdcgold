/**
 * @see WorkOrderTriggerHandler
 */
trigger Accel_WorkOrderTrigger on WorkOrder (before update,before insert, after update) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            try {
                //  If the user puts nothing in work order phone. take the value if it exists on the case. and use that.
                List<WorkOrder> workOrdersUpdated = WorkOrderTriggerHandler.updateWorkOrderCallerPhone( Trigger.new );
                System.debug( LoggingLevel.DEBUG, workOrdersUpdated );

                List<WorkOrder> workOrdersUpdatedSolutions = WorkOrderTriggerHandler.updateSolutionPicklist(Trigger.New);
                System.debug(LoggingLevel.INFO, workOrdersUpdatedSolutions);
            } catch (Exception e) {
                System.debug( LoggingLevel.ERROR, e );
            }
        } else if (Trigger.isUpdate) {
            try {
                List<WorkOrder> workOrdersUpdated = WorkOrderTriggerHandler.updateWorkOrderLocationPriority(Trigger.oldMap,
                                                                                                            Trigger.newMap );
                System.debug( LoggingLevel.DEBUG, workOrdersUpdated );

                List<WorkOrder> workOrdersUpdatedSolutions = WorkOrderTriggerHandler.updateSolutionPicklist(Trigger.oldMap,
                                                                                                            Trigger.newMap);
                System.debug(LoggingLevel.INFO, workOrdersUpdatedSolutions);
            } catch (Exception e) {
                System.debug( LoggingLevel.ERROR, e );
            }
        }
    } else if (Trigger.isAfter) {
        if(Trigger.isUpdate) {
            try {
                // User updated caller phone on the work order. go and update the parent case.
                List<Case> casesPhoneUpdated = WorkOrderTriggerHandler.updateCaseCallerPhone( Trigger.oldMap,Trigger.newMap );
                System.debug( LoggingLevel.DEBUG, casesPhoneUpdated );

                //  User has picked an Accel_Solution__c on the work order and Completed the work order. go and update the parent case.
                //  with the solution lookup value from the work order.
                List<Case> casesSolutionsUpdated = WorkOrderTriggerHandler.updateCaseSolution( Trigger.oldMap,Trigger.newMap );
                System.debug( LoggingLevel.DEBUG, casesSolutionsUpdated );
            } catch (Exception e) {
                System.debug( LoggingLevel.ERROR, e );
            }
        }
    }
}