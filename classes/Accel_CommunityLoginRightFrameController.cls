/**
 * Created by rnend on 1/6/2019.
 */

global class Accel_CommunityLoginRightFrameController {
    @AuraEnabled
    global static String getExperienceId() {
        return Site.getExperienceId();
    }
    @AuraEnabled
    global static String setExperienceId(String expId) {
        // Return null if there is no error, else it will return the error message
        try {
            if (expId != null) {
                Site.setExperienceId(expId);
            }
            return null;
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }
}