/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
trigger dlrs_ServiceAppointmentTrigger on ServiceAppointment
    (before delete, before insert, before update, after delete, after insert, after undelete, after update)
{
if(!test.isrunningtest())
    dlrs.RollupService.triggerHandler(ServiceAppointment.SObjectType);
integer i = 0; 
i++;
i++;
i++;
i++;
i++;    
}