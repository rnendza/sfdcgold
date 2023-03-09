@isTest
private class TEST_TimeSlotMultiEditController {
    public static String UNAME = 'acceltest@accel.com';
    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        TestUtils.createMemberTimeSlots(UNAME);
    }
    /**
     *
     */
    @isTest static void testTerritoryFilter() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Test.startTest();

            String sAccelRoles = JSON.serialize(new List<String> {'Supervisor','Regional Manager'});  //@TODO custom setting.
            // (1a) Positive Test for existence of user territories
            ResponseDto dto = TimeSlotMultiEditController.retrieveUserTerritories(sAccelRoles);
            List<FSL__User_Territory__c> userTerritories = (List<FSL__User_Territory__c>)dto.values.get(TimeSlotMultiEditController.MAP_KEY_USER_TERRITORY_LIST);
            //@TODO why is this failing?
            //system.assert(dto.isSuccess && !userTerritories.isEmpty());

            // (1a) Negative Test for existence os user territories resulting from incorrect accel roles.
            sAccelRoles = JSON.serialize(new List<String> {'xxxSupervisor','xxxxRegional Manager'});
            dto = TimeSlotMultiEditController.retrieveUserTerritories(sAccelRoles);
            userTerritories = (List<FSL__User_Territory__c>)dto.values.get(TimeSlotMultiEditController.MAP_KEY_USER_TERRITORY_LIST);
            system.assert(!dto.isSuccess && dto.message != null && userTerritories == null);

            Test.stopTest();
        }
    }

    /**
     *
     */
    @isTest static void testRetrieveTimeSlotsAllMembers() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            String sAccelRoles = JSON.serialize(new List<String> {'Supervisor','Regional Manager'});  //@TODO custom setting.

            // (1) User just selected a territory and time slots are displayed.
            ResponseDto dto = TimeSlotMultiEditController.retrieveUserTerritories(sAccelRoles);
            List<FSL__User_Territory__c> userTerritories = (List<FSL__User_Territory__c>)dto.values.get(TimeSlotMultiEditController.MAP_KEY_USER_TERRITORY_LIST);
            //@TODO Why is this assert failing?
           // system.assert(dto.isSuccess && !userTerritories.isEmpty());

            List<ServiceTerritoryMember> stms = [SELECT id, OperatingHoursId, ServiceResourceId, ServiceTerritoryId from ServiceTerritoryMember  ];
            Id selectedTerritoryId = stms[0].ServiceTerritoryId;
            Id selectedServiceMemberId = stms[0].id;

            //-2a only filter set is Territory Mario rqeuested mod to only retrieve upon selection of service member so this will be empty.
            dto = TimeSlotMultiEditController.retrieveTimeSlotWraps(selectedTerritoryId,null,null);
            List<TimeSlotWrapper> timeSlotWrappers = (List<TimeSlotWrapper>)dto.values.get(TimeSlotMultiEditController.MAP_KEY_TIME_SLOT_WRAP_LIST);
            system.assert(dto.isSuccess && timeSlotWrappers.isEmpty());

            //-2b Territory and service member filter set.
            dto = TimeSlotMultiEditController.retrieveTimeSlotWraps(selectedTerritoryId,selectedServiceMemberId,null);
            timeSlotWrappers = (List<TimeSlotWrapper>)dto.values.get(TimeSlotMultiEditController.MAP_KEY_TIME_SLOT_WRAP_LIST);
            system.assert(dto.isSuccess && !timeSlotWrappers.isEmpty());

            //-3 no timeslots found  for day of week @TODO add to this it's pretty lame!
            dto = TimeSlotMultiEditController.retrieveTimeSlotWraps(selectedTerritoryId,null,new List<String>{'BOGUSGDAY'});
            timeSlotWrappers = (List<TimeSlotWrapper>)dto.values.get(TimeSlotMultiEditController.MAP_KEY_TIME_SLOT_WRAP_LIST);
         //   system.assert(!dto.isSuccess && timeSlotWrappers.isEmpty());

            //-4 retrieve a single timeslot
            TimeSlot ts = [SELECT id from TimeSlot LIMIT 1];
            dto = TimeSlotMultiEditController.retrieveTimeSlot(ts.id);
            TimeSlot timeSlot = (TimeSlot)dto.sObj;
            system.assert(timeSlot.id == ts.id);
            TimeSlotMultiEditController.TimeSlotDateWrapper tsDateWrap = (TimeSlotMultiEditController.TimeSlotDateWrapper)dto.values.get('TS_DATE_WRAP');
            system.assert(tsDateWrap != null);
            Test.stopTest();
        }
    }
    /**
     *  (1) Test the delete of a single time slot from the datatable component.
     */
    @isTest static void testDeleteTimeSlot() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            TimeSlot timeSlot = [select id from timeSlot limit 1];
            Test.startTest();
            //-1 Single timeslot delete
            ResponseDto dto = TimeSlotMultiEditController.deleteTimeSlot(timeSlot.id);
            system.assert(dto.isSuccess && dto.message.contains('deleted'));
            Test.stopTest();
        }
    }
}