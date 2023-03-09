/**
 * @see ServiceAppointmentTriggerHandler
 */
trigger Accel_ServiceAppointmentTrigger on ServiceAppointment (before insert, before update, after update) {

    public static Svc_Utility_Bar_Settings__mdt utilityRejectedMdt = (Svc_Utility_Bar_Settings__mdt)CustomMetadataSvc.retrieveCustomSearchMeta
            (Svc_Utility_Bar_Settings__mdt.getSObjectType(), 'Rejected');

    public static Svc_Utility_Bar_Settings__mdt utilityAcceptedNotEnrouteMdt = (Svc_Utility_Bar_Settings__mdt)CustomMetadataSvc.retrieveCustomSearchMeta
            (Svc_Utility_Bar_Settings__mdt.getSObjectType(), 'Accepted_But_Not_En_route');

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            try {
                List<ServiceAppointment> serviceAppointmentsUpdated = ServiceAppointmentTriggerHandler.updateServiceCategory( Trigger.new );
                System.debug( LoggingLevel.INFO, serviceAppointmentsUpdated );

                List<ServiceAppointment> serviceAppointmentsUpdatedPriority =
                        ServiceAppointmentTriggerHandler.updateServiceLocationPriority( Trigger.new );
                System.debug( LoggingLevel.INFO, serviceAppointmentsUpdatedPriority );

                List<ServiceAppointment> serviceAppointmentsUpdatedSolutions =
                        ServiceAppointmentTriggerHandler.updateSolutionPicklist(Trigger.New);
                System.debug(LoggingLevel.INFO, serviceAppointmentsUpdatedSolutions);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, e);
            }
        } else if (Trigger.IsUpdate) {
            List<ServiceAppointment> serviceAppointmentsUpdatedSolutions =
                    ServiceAppointmentTriggerHandler.updateSolutionPicklist(Trigger.oldMap, Trigger.newMap);
            System.debug(LoggingLevel.INFO, serviceAppointmentsUpdatedSolutions);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isUpdate) {
            //  User has picked an Accel_Solution__c on the service appointment. go and update the parent work order
            //  with the solution lookup value from the service appointment
            List<WorkOrder> workOrdersSolutionsUpdated = ServiceAppointmentTriggerHandler.updateWorkOrderSolution(  Trigger.oldMap,
                                                                                                                    Trigger.newMap );
            System.debug( LoggingLevel.DEBUG, workOrdersSolutionsUpdated );

            try {
                if(!utilityRejectedMdt.Disable_Rejected_PE__c) {
                    String action = PlatformEventSvc.DML_ACTION_UPDATE;
                    ServiceAppointmentTriggerHandler.fireServiceAppointmentRejectedPlatformEvent(
                            Trigger.oldMap,
                            Trigger.newMap,
                            action );
                }
                String action =  PlatformEventSvc.DML_ACTION_UPDATE;
                ServiceAppointmentTriggerHandler.fireServiceAppointmentNotDispatchedPlatformEvent(
                            Trigger.oldMap,
                            Trigger.newMap,
                            action );

                ServiceAppointmentTriggerHandler.fireServiceAppointmentStatusChangePe(
                            Trigger.oldMap,
                            Trigger.newMap,
                            action );

            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
        }
    }
}