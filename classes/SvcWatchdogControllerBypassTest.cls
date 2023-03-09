@IsTest
private class SvcWatchdogControllerBypassTest {

    @IsTest
    static void test_retrieveAssignedResourceToBypassManualNotification() {

        List<String> profileNamesToBypass = new List<String> {
                'Accel Regional Service Management V2',
                'Accel Service User V2'
        };
 
        Test.startTest();

        ResponseDto dto = SvcWatchdogControllerBypass.retrieveAssignedResourceToBypassManualNotification(profileNamesToBypass);
        System.assert(dto.isSuccess);
        Set<Id> userIds = (Set<Id>)dto.values.get(SvcWatchdogControllerBypass.MAP_KEY_USERS_TO_BYPASS);
        System.assert(!userIds.isEmpty());

        Test.stopTest();
    }
}