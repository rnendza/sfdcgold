@isTest
private class TEST_TerritorySvc {

    public static String UNAME = 'acceltest@accel.com';

    /**
     * Setup test data.
     */
    @testSetup static void setup() {
        TestUtils.createMemberTimeSlots(UNAME);
    }

    @isTest static void testServiceTerritories() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            List<ServiceTerritory> serviceTerritories = TerritorySvc.retrieveServiceTerritories();
            system.assert(serviceTerritories.size() > 0);
            Test.stopTest();
        }
    }
    @isTest static void testServiceTerritoryMembers() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            List<ServiceTerritory> serviceTerritories = TerritorySvc.retrieveServiceTerritories();
            List<ServiceTerritoryMember> serviceTerritoryMembers = TerritorySvc.retrieveSvcTerritoryMembers(serviceTerritories, 'P');
            system.assert(serviceTerritoryMembers.size() > 0);
            Test.stopTest();
        }
    }
    @isTest static void testRetrieveOperatingHours() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            system.assert(TerritorySvc.retrieveOperatingHours().size() > 0);
            Test.stopTest();
        }
    }
    @isTest static void testRetrieveTimeSlots() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<OperatingHours> operatingHours = TerritorySvc.retrieveOperatingHours();
            List<String> daysOfWeek = new List<String>{
                    'Monday'
            };
            system.assert(TerritorySvc.retrieveTimeSlots(operatingHours, daysOfWeek).size() > 0);
            daysOfWeek.clear();
            List<TimeSlot> timeslots = TerritorySvc.retrieveTimeSlots(operatingHours,daysOfWeek);
            system.assert(!timeslots.isEmpty());
            TimeSlot ts = TerritorySvc.retrieveTimeSlot(timeslots[0].id);
            system.assert(ts != null);
        }
    }
    @isTest static void testRetrieveOppHourTimeSlots() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<OperatingHours> operatingHours = TerritorySvc.retrieveOperatingHours();
            List<String> daysOfWeek = new List<String>{
                    'Monday'
            };
            system.assert(TerritorySvc.retrieveOppHourTimeSlots(operatingHours, daysOfWeek).size() > 0);
        }
    }
    @isTest static void testRetrieveUserTerritories() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Set<String> accelRoles = new Set<String> {'Supervisor','Regional Manager'};
            List<FSL__User_Territory__c> userTerritories  = TerritorySvc.retrieveUserTerritories(u.id, accelRoles);
         //---@TODO check test data creation   system.assert(!userTerritories.isEmpty());

        }
    }
}