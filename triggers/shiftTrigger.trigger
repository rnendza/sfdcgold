trigger shiftTrigger on Shift (before insert) {
    Set<Id> resourceIds = new Set<Id>();
    for (Shift s : Trigger.new){
        resourceIds.add(s.ServiceResourceId);
    }
    
    List<Shift> existingShifts = [select ServiceResourceId, StartTime from Shift where ServiceResourceId in :resourceIds];
    Map<Id, List<Datetime>> shiftsByResource = new Map<Id, List<Datetime>>();
    for (Shift s : existingShifts){
        if (shiftsByResource.get(s.ServiceResourceId) != null){
            shiftsByResource.get(s.ServiceResourceId).add(s.StartTime);
        } else{
            shiftsByResource.put(s.ServiceResourceId, new List<Datetime>{s.StartTime});
        }
    }
    
    for (Shift s : Trigger.new){
        if (shiftsByResource.get(s.ServiceResourceId) != null && shiftsByResource.get(s.ServiceResourceId).contains(s.StartTime)){
            s.StartTime.addError('A Shift already exists at this time for this Service Resource');
        }
    }
}