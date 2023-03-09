/**
 * Performs all ops on User.
 */
trigger Accel_UserTrigger on User (after insert) {


    if(Trigger.isAfter && Trigger.isInsert) {
        try {
            //  Only creates if User.ContactId Is populated.
            UserTriggerHandler.createCommunityUserSettings(Trigger.newMap);
            //  Only created for certain profiles as defined by CL Mdt settings.
            UserTriggerHandler.createClUserSettings(Trigger.newMap);
 

            //-------------> UserTriggerHandler.assignPermissionSets(Trigger.newMap);
            //Fire future version of method instead
            //@see https://accel-entertainment.monday.com/boards/286658657/pulses/696117182/posts/821349308
            UserTriggerHandler.assignPermissionSets( Trigger.newMap.keySet() );




            //  Only execute of custom setting allows us. then ensure it's a portal user.
            Trigger_Settings__c triggerSettings = CustomSettingsSvc.getTriggerSettings(UserInfo.getUserId());
            if(triggerSettings != null) {
                if(triggerSettings.Portal_User_SetPassword_Active__c) {
                    UserTriggerHandler.setPwAndSendEmail(Trigger.newMap);
                }
                if(triggerSettings.Portal_Send_User_Created_RM_Email__c) {
                    UserTriggerHandler.sendRmEmailsOnPortalUserCreated(Trigger.newMap);
                }
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
        }
    }
}