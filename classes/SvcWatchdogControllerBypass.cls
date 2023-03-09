public class SvcWatchdogControllerBypass {

    public static final String MAP_KEY_USERS_TO_BYPASS = 'MAP_KEY_USERS_TO_BYPASS';

    /**
     * @param profilesToBypass  list of profile names to bypass ie. .....V2
     * @return  A List of User Ids to (for the assigned resource) to bypass via filtering in on the front end.
     *
     * @todo this is a hack. we need to fix the entire legacy test data creation harness to do this right!
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAssignedResourceToBypassManualNotification(List<String> profilesToBypass) {
        ResponseDto dto = new ResponseDto();

        Map<Id,Profile> mProfiles = new Map<Id,Profile>([SELECT Id FROM Profile WHERE Name IN :profilesToBypass]);

        if(!mProfiles.isEmpty()) {
            Map<Id,User> musers = new Map<Id,User>([
                    SELECT Id
                    FROM   User
                    WHERE  ProfileId IN :mProfiles.keySet()
                    AND    IsActive = TRUE
            ]);
            dto.values.put(MAP_KEY_USERS_TO_BYPASS,musers.keySet());
            dto.isSuccess = !musers.keySet().isEmpty();
        }
        return dto;
    }
}