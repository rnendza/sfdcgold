@isTest
private class TEST_BatchTimeSlotExport {

    public static String UNAME = 'acceltest@accel.com';
    /**
     * Runs gen test method to create the entire heirarchy up to timeslots.
     * Updates timeslot dayofweek to current run day.
     */
    @testSetup static void setup() {
        TestUtils.createMemberTimeSlots(UNAME);

        Export_Settings__mdt exportSettings = (Export_Settings__mdt)CustomMetadataSvc.retrieveCustomSearchMeta(
                Export_Settings__mdt.getSObjectType(),BatchTimeSlotExport.SETTING_NAME
        );
        List<String> daysOfWeek = new BatchTimeSlotExport().buildDaysOfWeek( exportSettings );
       //---------- String todayDayName =  System.now().format(BatchTimeSlotExport.DAYOFWEEK_FORMAT);
        List<TimeSlot> timeSlots = [SELECT Id, DayOfWeek from TimeSlot];
        for(TimeSlot timeSlot :timeSlots) {
            timeSlot.DayOfWeek = daysOfWeek[0];
        }
        update timeSlots;
    }
    /**
     * -(1)-  test that time slots  were retrieved for today.
     */
    @isTest static void testExportServiceTerritoryMembersTimeSlots_Positive() {
        List<TimeSlot> timeSlots = [SELECT Id, DayOfWeek FROM TimeSlot];

        Test.startTest();

        BatchTimeSlotExport b = new BatchTimeSlotExport();
        DataBase.executeBatch(b);

        Test.stopTest();

        System.assertEquals( BatchTimeSlotExport.numTimeSlotWraps,timeSlots.size() );
    }
    /**
     * -(1)-  test that no time slots were retrieved for days that are not in custom meta data.
     * @TODO if someone puts every day in there (not likely) this test may fail.
     */
    @isTest static void testExportServiceTerritoryMembersTimeSlots_Negative() {
        List<TimeSlot> timeSlots = [SELECT Id, DayOfWeek FROM TimeSlot];
        Set<String> daysOfWeek = new Set<String> {'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'};
        List<String> daysOfWeekNotInCustomMeta = new List<String>();
        Export_Settings__mdt exportSettings = (Export_Settings__mdt)CustomMetadataSvc.retrieveCustomSearchMeta(
                Export_Settings__mdt.getSObjectType(),BatchTimeSlotExport.SETTING_NAME
        );
        List<String> daysOfWeekMdt = new BatchTimeSlotExport().buildDaysOfWeek( exportSettings );
        for(String dayOfWeek : daysOfWeek) {
            if(!daysOfWeekMdt.contains(dayOfWeek)) {
                daysOfWeekNotInCustomMeta.add(dayOfWeek);
            }
        }
        for(TimeSlot timeSlot : timeSlots) {
            try {
                timeSlot.DayOfWeek = daysOfWeekNotInCustomMeta[0];
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
        }
        update timeSlots;

        Test.startTest();

        BatchTimeSlotExport b = new BatchTimeSlotExport();
        Database.executeBatch(b);

        Test.stopTest();

        System.assertEquals( BatchTimeSlotExport.numTimeSlotWraps, 0 );
    }

}