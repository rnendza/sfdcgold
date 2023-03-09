/**
 * Note there are try catch blocks here as we have all kinds of validation rules put on top of service appointments
 * without old service appointments being fixed to obey them so if  this will most likely crash on mass updates of those records.
 * So rather then risk not being able to update a service appointment for simple field syncs just catch it..
 * Also platform events seem to throw n/a exceptions. ie exception thrown but it still fires and works.
 * and maybe email the ex @TODO email ex.
 *
 * @see CaseTriggerHandler
 */
trigger Accel_CaseTrigger on Case ( before update, after update,
                                    before insert, after insert,
                                    after delete ) {

    public static List<Exception> exceptions = new List<Exception>();

    public static Svc_Utility_Bar_Settings__mdt utilityArMdt = (Svc_Utility_Bar_Settings__mdt)CustomMetadataSvc.retrieveCustomSearchMeta
            (Svc_Utility_Bar_Settings__mdt.getSObjectType(), 'No_Assigned_Resource');

    if (Trigger.isAfter) {
        List<ServiceAppointment>    updatedServiceAppointments  = new List<ServiceAppointment>();
        List<WorkOrder>             updatedWorkOrders           = new List<WorkOrder>();
        if (Trigger.isUpdate) {
            try {
                updatedServiceAppointments = CaseTriggerHandler.evalCaseForServiceAppointmentMods(Trigger.oldMap,
                        Trigger.newMap);
                System.debug(LoggingLevel.DEBUG, updatedServiceAppointments);
                updatedWorkOrders = CaseTriggerHandler.evalCaseForCallerPhoneMods(Trigger.oldMap, Trigger.newMap);
                System.debug(LoggingLevel.DEBUG, updatedWorkOrders);
                String action = PlatformEventSvc.DML_ACTION_UPDATE;
                try {
                    if (!utilityArMdt.Disable_No_Assigned_Resource_PE__c) {
                        CaseTriggerHandler.fireCaseNoAssignedResourcePlatformEvent( Trigger.oldMap, Trigger.newMap, action );
                    } else {
                        System.debug(LoggingLevel.INFO, '(Svc_Utility_Bar_Settings__mdt is telling us to disable the ' +
                                ' firing of the no assigned resource PE ');
                    }
                    CaseTriggerHandler.fireCaseClosedPlatformEvent( Trigger.oldMap, Trigger.newMap, action );
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error in CaseTrigger platform event send caught!');
                    System.debug(LoggingLevel.ERROR, e);
                    exceptions.add(e);
                }
            } catch (Exception e) {
                exceptions.add(e);
                System.debug(e);
            }
        } else if (Trigger.isInsert || Trigger.isDelete) {
            //----- Fire a platform event so we can watch assigned resources on a case. @TODO Check bulk deletes!
            try {
                if (!utilityArMdt.Disable_No_Assigned_Resource_PE__c) {
                    String action = Trigger.isDelete ? PlatformEventSvc.DML_ACTION_DELETE : PlatformEventSvc.DML_ACTION_INSERT;
                    Map<Id,Case> caseMap = Trigger.isDelete ? Trigger.oldMap : Trigger.newMap;
                    system.debug(LoggingLevel.INFO, 'trigger action='+action);
                    CaseTriggerHandler.fireCaseNoAssignedResourcePlatformEvent( caseMap, action );
                } else {
                    System.debug(LoggingLevel.INFO, '(Svc_Utility_Bar_Settings__mdt is telling us to disable the ' +
                            ' firing of the no assigned resource PE ');
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error in CaseTrigger caught!');
                System.debug(LoggingLevel.ERROR, e);
            }
        }
    } else if (Trigger.isBefore) {
        if(Trigger.isInsert) {
            List<Case> casesUpdatedSolutions = CaseTriggerHandler.updateSolutionPicklist(Trigger.New);
            System.debug(LoggingLevel.INFO, casesUpdatedSolutions);
            List<Case> casesUpdatedStar67 = CaseTriggerHandler.flagCallerPhoneWithStar67(Trigger.New);
            System.debug(LoggingLevel.INFO, casesUpdatedStar67);
        } else if (Trigger.isUpdate) {
            List<Case> casesUpdatedSolutions = CaseTriggerHandler.updateSolutionPicklist(Trigger.oldMap, Trigger.newMap);
            System.debug(LoggingLevel.INFO, casesUpdatedSolutions);
        }
    }
}