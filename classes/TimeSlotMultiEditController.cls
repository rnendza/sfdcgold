/**
 * @see TerritorySvc
 */
public with sharing class TimeSlotMultiEditController {

    public static final String MAP_KEY_USER_TERRITORY_LIST = 'USER_TERRITORIES';
    public static final String MAP_KEY_SERVICE_MEMBER_LIST = 'SERVICE_MEMBERS';
    public static final String MAP_KEY_TIME_SLOT_WRAP_LIST = 'TIME_SLOTS';
    public static final String MAP_KEY_TIME_EDIT_SETTINGS  = 'TIME_EDIT_SETTINGS';

    @AuraEnabled
    public static ResponseDto deleteTimeSlot(Id timeSlotId) {
        ResponseDto dto = new ResponseDto();
        List<TimeSlot> timeSlots = [    SELECT  DayOfWeek,EndTime,FSL__Designated_Work_Boolean_Fields__c,FSL__Slot_Color__c,
                                                Id,OperatingHoursId,StartTime,TimeSlotNumber,Type
                                        FROM    TimeSlot
                                        WHERE   id = :timeSlotId] ;
        if(!timeSlots.isEmpty()) {
            TimeSlot timeSlotToDel = timeSlots[0];
            delete timeSlotToDel;
            dto.isSuccess = true;
            dto.message = 'Timeslot '+timeSlots[0].timeSlotNumber + '  successfully deleted!';
            dto.severity = 'success';
        }
        return dto;
    }
    /**
     *
     * @param sAccelRoles a json string of possible access roles. This is a JSON string as opposed to a Set of Strings
     *                    a lightning has a bug in passing a Set of Strings.
     * @return
     */
    @AuraEnabled
    public static ResponseDto retrieveUserTerritories(String sAccelRoles) {
        ResponseDto dto = new ResponseDto();
        dto.values.put(MAP_KEY_TIME_EDIT_SETTINGS,CustomSettingsSvc.getAccelTimeEditSettings(UserInfo.getUserId()));
        Object[] oAccelRoles = (Object[])JSON.deserializeUntyped(sAccelRoles);
        Set<String> accelRoles = new Set<String>();
        if(oAccelRoles.size() > 0) {
            for(Object role : oAccelRoles) {
                accelRoles.add(string.valueOf(role));
            }
        }
        Id userId = UserInfo.getUserId();

        List<FSL__User_Territory__c> userTers = TerritorySvc.retrieveUserTerritories(userId, accelRoles);
        if(!userTers.isEmpty()) {
            dto.technicalMsg = 'userId='+userId+ 'accelRoles='+accelRoles;
            dto.values.put(MAP_KEY_USER_TERRITORY_LIST,userTers);
            dto.isSuccess = true;
        } else {
            String sMsg = UserInfo.getUserName() + ' does not have a record in user territory with an Accel Role of : '+ String.join(new List<String>(accelRoles), ',');
            dto.isSuccess = false;
            dto.message = sMsg;
        }
        return dto;
    }
    /**
     *
     * @param tsID
     * @return
     */
    @AuraEnabled
    public static ResponseDto retrieveTimeSlot( Id tsId) {
        ResponseDto dto = new ResponseDto();
        TimeSlot timeSlot = TerritorySvc.retrieveTimeSlot( tsId );
        if(timeSlot != null) {
            dto.isSuccess = true;
            dto.sObj = timeSlot;
            TimeSlotDateWrapper tsWrap = new TimeSlotDateWrapper(timeSlot);
            dto.values.put('TS_DATE_WRAP',tsWrap);
            //convert start / stop time values here since it can be a pain with aura localization service or in js.
        }
        return dto;
    }
    public class TimeSlotDateWrapper {
        @AuraEnabled String sStartDateLocal  {get;set;}
        @AuraEnabled String sEndDateLocal  {get;set;}
        @AuraEnabled DateTime dtStartDateLocal {get;set;}
        @AuraEnabled DateTime dtEndDateLocal    {get;set;}

        public TimeSlotDateWrapper(TimeSlot ts) {
            if(ts.StartTime != null) {
                dtStartDateLocal = DateTime.newInstance(System.today(),ts.StartTime);
                sStartDateLocal = dtStartDateLocal.format('HH:mm');
            }
            if(ts.EndTime != null) {
                dtEndDateLocal = DateTime.newInstance(System.today(),ts.EndTime);
                sEndDateLocal = dtEndDateLocal.format('HH:mm');
            }
        }
    }
    /**
     *
     * @param serviceTerritoryId
     * @param stmIds
     * @return
     */
    @AuraEnabled
    public static ResponseDto retrieveTimeSlotWraps( Id serviceTerritoryId,String selectedSmId, List<String> daysOfWeek) {
        ResponseDto dto = new ResponseDto();
        List<TimeSlotWrapper> tsWraps = new List<TimeSlotWrapper>();
        Set<Id> svcTerritoryIds = new Set<Id>{serviceTerritoryId};
        dto.technicalMsg = 'serviceTerritoryId='+serviceTerritoryId;
        List<ServiceTerritoryMember> stms = TerritorySvc.retrieveSvcTerritoryMembers(svcTerritoryIds,'P');

        if (!stms.isEmpty()) {
            dto.values.put(MAP_KEY_SERVICE_MEMBER_LIST,stms);
            Map<Id, ServiceTerritoryMember> mOhId_Stm = new Map<Id, ServiceTerritoryMember>();
            for (ServiceTerritoryMember stm : stms) {
                if(selectedSmId == null || selectedSmId == '') {
                    mOhId_Stm.put(stm.OperatingHoursId, stm);
                } else {
                    if(selectedSmId == stm.Id) {
                        mOhId_Stm.put(stm.OperatingHoursId, stm);
                    }
                }
            }
            Map<Id, List<TimeSlot>> mOhId_TimeSlots = new Map<Id,List<TimeSlot>>();
            if(selectedSmId != null && selectedSmId != '') {
                mOhId_TimeSlots = TerritorySvc.retrieveOppHourTimeSlots(mOhId_Stm.keySet(), daysOfWeek);
            } else {
                dto.isSuccess = true;
            }
            if (!mOhId_TimeSlots.isEmpty()) {
                dto.isSuccess = true;
                for (Id ohId : mOhId_TimeSlots.keySet()) {
                    List<TimeSlot> ohTimeSlots = mOhId_TimeSlots.get(ohId);
                    String prevStmName = '';
                    for (TimeSlot ts : ohTimeSlots) {
                        ServiceTerritoryMember stm = mOhId_Stm.get(ohId);
                        String currStmName = stm.ServiceResource.Accel_User__r.name;
                        TimeSlotWrapper tsWrap = new TimeSlotWrapper(ts,stm);
                        if(currStmName != prevStmName) {
                            tsWrap.name = currStmName;
                        } else {
                            //tsWrap.name = '<span style="color:white>'+currStmName+'</span>';
                            tsWrap.name = currStmName;
                        }
                        tsWraps.add(tsWrap);
                        prevStmName = currStmName;
                    }
                }
            } else {
                if(selectedSmId != null && selectedSmId != '') {
                    dto.isSuccess = false;
                    String sMsg = 'No time slot records found';
                    if (selectedSmId != null && selectedSmId != '') {
                        sMsg += ' for selected service member';
                    }
                    if (daysOfWeek != null && !daysOfWeek.isEmpty()) {
                        sMsg += ' and selected day of week';
                    }
                    dto.message = sMsg;
                    dto.severity = 'warning';
                    String techMsg = 'retrieveTimeSlots with serviceTerritoryId=' + serviceTerritoryId + ' and selectedMemberId=' + selectedSmId + '. and daysOfWeek=' + daysOfWeek;
                    dto.technicalMsg = techMsg;
                }
            }
        }
        dto.values.put(MAP_KEY_TIME_SLOT_WRAP_LIST,tsWraps);
        return dto;
    }
}