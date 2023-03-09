@isTest
private class TEST_ScheduleBatchTimeSlotExport {
    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        TestUtils.createMemberTimeSlots(UNAME);
        String todayDayName =  System.now().format('EEEE');
        List<TimeSlot> timeSlots = [SELECT Id, DayOfWeek from TimeSlot];
        for(TimeSlot timeSlot :timeSlots) {
            timeSlot.DayOfWeek = todayDayName;
        }
        update timeSlots;
    }
    @isTest static void testScheduleBatchTimeSlotExport_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            ScheduleBatchTimeSlotExport.scheduleIt(System.now());
            ScheduleBatchTimeSlotExport scheduleBatchTimeSlotExport = new ScheduleBatchTimeSlotExport();
            String sch = '0 0 23 * * ?';
            system.schedule('Test schedule batch time slot export...', sch, scheduleBatchTimeSlotExport);

            Test.stopTest();
        }
    }

}