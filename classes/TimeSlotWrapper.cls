public with sharing class TimeSlotWrapper {

    @AuraEnabled public TimeSlot timeSlot { get; set; }
    @AuraEnabled public ServiceTerritoryMember svcTerritoryMbr { get; set; }
    //---below IS TEMP HACK TO FLATTEN ABOVE TO GET IT TO WORK WITH LIGHTING DATATABLE COMPONENT.
    @AuraEnabled public String dayOfWeek { get; set; }
    @AuraEnabled public Time startTime { get; set; }
    @AuraEnabled public Time endTime { get; set; }
    @AuraEnabled public String type { get; set; }
    @AuraEnabled public Datetime lastModifiedDate { get; set; }
    @AuraEnabled public String lastModifiedByName { get; set; }
    @AuraEnabled public String name { get; set; }
    @AuraEnabled public Id timeSlotId { get; set; }

    public TimeSlotWrapper() {

    }
    public TimeSlotWrapper(TimeSlot ts, ServiceTerritoryMember stm) {
        this.timeSlot = ts;
        this.svcTerritoryMbr = stm;
        //@TODO should not have to do the below but it seems there may be a bug in the new sfdc data tables component.
        this.dayOfWeek = ts.DayOfWeek;
        this.startTime = ts.StartTime;
        this.endTime = ts.EndTime;
        this.lastModifiedDate = ts.LastModifiedDate;
        this.lastModifiedByName = ts.LastModifiedBy.Name;
        this.timeSlotId = ts.Id;
        this.type = ts.type;
    }
}