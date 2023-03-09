public class FSLUtils {

    /**
     *
     *
     * @param mOhId_TimeSlots a Map of operating hours id => list of TimeSlots
     * @param mOhId_Stm       a Map of operating hours id => ServiceTerritoryMember
     *
     * @return a List of TimeSlotWrappers
     * @see TimeSlotWrapper
     */
    public static List<TimeSlotWrapper> buildTimeSlotWrappers(  Map<Id, List<TimeSlot>> mOhId_TimeSlots,
                                                                Map<Id, ServiceTerritoryMember> mOhId_Stm) {

        List<TimeSlotWrapper> timeSlotWrappers = new List<TimeSlotWrapper>();
        if(mOhId_TimeSlots != null && mOhId_Stm != null) {
            for (Id ohId : mOhId_TimeSlots.keySet()) {
                List<TimeSlot> ohTimeSlots = mOhId_TimeSlots.get(ohId);
                String prevStmName = '';
                for (TimeSlot ts : ohTimeSlots) {
                    ServiceTerritoryMember stm = mOhId_Stm.get(ohId);
                    String currStmName = stm.ServiceResource.Accel_User__r.name;
                    TimeSlotWrapper tsWrap = new TimeSlotWrapper(ts, stm);
                    if (currStmName != prevStmName) {
                        tsWrap.name = currStmName;
                    } else {
                        tsWrap.name = currStmName;
                    }
                    timeSlotWrappers.add(tsWrap);
                    prevStmName = currStmName;
                }
            }
        }
        return timeSlotWrappers;
    }
}