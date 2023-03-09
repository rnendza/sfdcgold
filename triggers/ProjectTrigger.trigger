trigger ProjectTrigger on Project__c (after insert, after update) {
    if(Trigger.isInsert) {
        ProjectTriggerHandler.createProjectLines(Trigger.new);    
    } else if(Trigger.isUpdate) {
        ProjectTriggerHandler.createProjectLines(Trigger.new, Trigger.oldMap);    
    }
}