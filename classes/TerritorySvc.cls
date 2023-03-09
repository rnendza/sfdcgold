/**
 * Service class intended for all Territory Operations.
 */
public with sharing class TerritorySvc {
 
    public static List<ServiceTerritoryMember> retrieveSvcTerritoryMembers(List<ServiceTerritory> svcTerritories, String sType) {
        Set<Id> svcTerritoryIds = new Set<Id>();
        for(ServiceTerritory st : svcTerritories) {
            svcTerritoryIds.add(st.id);
        }
        return retrieveSvcTerritoryMembers(svcTerritoryIds,sType);
    }
    /**
     * @param svcTerritoryIds
     * @param sType ie'P' = Primary
     * @return a list of service territory members for the pass svc terr ids, type
     * @todo change to dynamic soql
     */
    public static List<ServiceTerritoryMember> retrieveSvcTerritoryMembers(Set<Id> svcTerritoryIds, String sType) {
        List<ServiceTerritoryMember> stms = new List<ServiceTerritoryMember>();
        stms = [
                SELECT id, EffectiveStartDate, EffectiveEndDate,
                        ServiceResource.Accel_User__c,ServiceResource.Accel_User__r.name,
                        ServiceResource.Accel_User__r.firstname,ServiceResource.Accel_User__r.lastname,
                        OperatingHoursId,OperatingHours.name, territorytype
                FROM ServiceTerritoryMember
                WHERE ServiceTerritory.Id in :svcTerritoryIds
                and OperatingHoursId != null
                and TerritoryType = :sType
                and ServiceResource.Accel_User__r.IsActive = TRUE
                ORDER BY ServiceResource.Accel_User__r.firstname asc
        ];
        return stms;
    }
    public static List<OperatingHours> retrieveOperatingHours() {
        List<OperatingHours> operatingHours = [
            SELECT  id,name
            FROM    OperatingHours
        ];
        return operatingHours;
    }
    public static List<TimeSlot> retrieveTimeSlots(List<OperatingHours> operatingHours, List<String> daysOfWeek) {
        Set<Id> oppHourIds = new Set<Id>();
        for(OperatingHours oppHours : operatingHours) {
            oppHourIds.add(oppHours.id);
        }
        return retrieveTimeSlots(oppHourIds,daysOfWeek);
    }
    /**
     *
     *
     * @param tsId   - the TimeSlot id to find.
     * @return  a TimeSlot sObject.
     */
    public static TimeSlot retrieveTimeSlot(Id tsId) {
        TimeSlot ts;
        List<TimeSlot> timeSlots = [
                SELECT  DayOfWeek,EndTime,FSL__Designated_Work_Boolean_Fields__c,FSL__Slot_Color__c,
                        Id,OperatingHoursId,OperatingHours.Name, StartTime,TimeSlotNumber,Type,LastModifiedDate,LastModifiedBy.Name
                FROM    TimeSlot
                WHERE   Id = :tsId
        ];
        if (!timeSlots.isEmpty()) {
            ts = timeSlots[0];
        }
        return ts;
    }
    /**
     * @param oppHourIds
     * @return a list of time slots for the passed opp hour ids.
     * @TODO Dynamic SOQL..
     */
    public static List<TimeSlot> retrieveTimeSlots(Set<Id> oppHourIds, List<String> daysOfWeek) {
        List<TimeSlot> timeSlots;
        if(daysOfWeek == null || daysOfWeek.isEmpty()) {
            timeSlots = [
                    SELECT DayOfWeek,EndTime,FSL__Designated_Work_Boolean_Fields__c,FSL__Slot_Color__c,
                            Id,OperatingHoursId,StartTime,TimeSlotNumber,Type,LastModifiedDate,LastModifiedBy.Name
                    FROM TimeSlot
                    WHERE OperatingHoursId in :oppHourIds
                    ORDER BY TimeSlotNumber ASC
            ];
        } else {
            timeSlots = [
                    SELECT  DayOfWeek,EndTime,FSL__Designated_Work_Boolean_Fields__c,FSL__Slot_Color__c,
                            Id,OperatingHoursId,StartTime,TimeSlotNumber,Type,LastModifiedDate,LastModifiedBy.Name
                    FROM    TimeSlot
                    WHERE   OperatingHoursId in :oppHourIds
                    and     DayOfWeek in :daysOfWeek
                    ORDER BY TimeSlotNumber ASC
            ];
        }
        return timeSlots;
    }
    public static Map<Id, List<TimeSlot>> retrieveOppHourTimeSlots(List<OperatingHours> operatingHours, List<String> daysOfWeek) {
        Set<Id> oppHourIds = new Set<Id>();
        for(OperatingHours oppHour : operatingHours) {
            oppHourIds.add(oppHour.id);
        }
        return retrieveOppHourTimeSlots(oppHourIds, daysOfWeek);
    }
    /**
     * @param oppHourIds
     * @return a map of operating hours id => List of Time Slots
     * @TODO refactor / move out of there.. this really isn't worthy of being in a Service Class IMHO
     */
    public static Map<Id, List<TimeSlot>> retrieveOppHourTimeSlots(Set<Id> oppHourIds, List<String> daysOfWeek) {
        Map<Id, List<TimeSlot>> mOhId_TimeSlots = new Map<Id, List<TimeSlot>>();
        List<TimeSlot> timeSlots = retrieveTimeSlots(oppHourIds,daysOfWeek);
        if (!timeSlots.isEmpty()) {
            for (TimeSlot ts : timeSlots) {
                if (!mOhId_TimeSlots.containsKey(ts.OperatingHoursId)) {
                    mOhId_TimeSlots.put(ts.OperatingHoursId, new List<TimeSlot>{
                            ts
                    });
                } else {
                    List<TimeSlot> tmpTimeSlots = mOhId_TimeSlots.get(ts.OperatingHoursId);
                    tmpTimeSlots.add(ts);
                }
            }
        }
        return mOhId_TimeSlots;
    }

    public static List<ServiceTerritory> retrieveServiceTerritories() {
        List<ServiceTerritory> svcTerritories = [
                SELECT  id, name, operatingHoursId
                FROM    ServiceTerritory
        ];
        return svcTerritories;
    }
    /**
     * @param managerUserId - The SFDC uid of the manager editing. (manager defined in User_Territory__c)
     * @param accelRoles    - The value on User_Territory__c.Accel_Role__c
     * @return a list of User Territory records for a territory manger.
     */
    public static List<FSL__User_Territory__c> retrieveUserTerritories(Id managerUserId, Set<String> accelRoles) {
        List<FSL__User_Territory__c> userTers;
        userTers = [
                SELECT id,name,FSL__ServiceTerritory__c,FSL__Territory_Name__c
                FROM FSL__User_Territory__c
                WHERE FSL__User__c = :managerUserId
                and Accel_Role__c in :accelRoles
                and FSL__ServiceTerritory__c in  (
                         SELECT ServiceTerritoryId
                         FROM   ServiceTerritoryMember
                         WHERE  OperatingHoursId != null
                         and    ServiceResource.Accel_User__r.IsActive = TRUE
                )
                ORDER BY FSL__Territory_Name__c
        ];
        if (!userTers.isEmpty()) {
            boolean allRegions = false;
            //--- iterate list to see if manager is associated to all regions
            for (FSL__User_Territory__c territory : userTers) {
                if (territory.FSL__Territory_Name__c == 'All Regions') {
                    allRegions = true;
                    break;
                }
            }
            if (allRegions) {
                //check for dups and remove.
                Map<Id, FSL__User_Territory__c> mUserTerritoryId_UserTerritory = new Map<Id, FSL__User_Territory__c>([
                        SELECT id,name,FSL__ServiceTerritory__c,FSL__Territory_Name__c
                        FROM FSL__User_Territory__c
                        WHERE FSL__Territory_Name__c != 'All Regions'
                        and FSL__ServiceTerritory__c in  (
                                SELECT ServiceTerritoryId
                                FROM   ServiceTerritoryMember
                                WHERE  OperatingHoursId != null
                                and    ServiceResource.Accel_User__r.IsActive = TRUE
                        )
                        ORDER BY FSL__Territory_Name__c
                ]);
                Set<FSL__User_Territory__c> tmpUserTerritories = new Set<FSL__User_Territory__c>(mUserTerritoryId_UserTerritory.values().deepClone());
                userTers = new List<FSL__User_Territory__c>(tmpUserTerritories);
            }
        }
        return userTers;
    }
}