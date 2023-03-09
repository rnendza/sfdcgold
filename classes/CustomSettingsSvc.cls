global class CustomSettingsSvc {


    /**
     * Gets SFDC Custom Boolean Setting (Accel_Time_Edit__c).
     * This is simply a convienence wrapper around grabbing any custom setting to as to not
     * require the client to do type casting on boolean settings.
     *
     * @param customSettingName
     * @return a boolean of true is the setting is checked, otherwise false.
     */
    global static boolean getAccelTimeEditBooleanSetting(String customSettingName) {
        Boolean booleanFlag = false;
        Object o = CustomSettingsSvc.getAccelTimeEditSetting(UserInfo.getUserId(), customSettingName);
        if (o != null) { // if it's null ie.. for some reason not found.. don't convert the type or Boom.
            booleanFlag = (Boolean) o;
        }
        return booleanFlag;
    }
    /**
     * Gets SFDC Custom Setting (Accel_Time_Edit__c).
     *
	 * This is a hierarchical setting and using the running user profile id for this setting
	 * is crucial as the different profiles may have different values.
	 *
	 * Note: It is the responsibility of the calling method to do type conversion.
     *
	 * @param	userProfileId	The Running user profile id.
	 * @param	fieldName		The api name of the custom setting.
     * @return  an object representing the custom setting..
     */
    global static object getAccelTimeEditSetting(Id userProfileId, string fieldName) {
        object value;
        Accel_Time_Edit__c customSetting = Accel_Time_Edit__c.getInstance(userProfileId);
        try {
            value = customSetting.get(fieldName);
        } catch (Exception e) {
            system.debug('Accel_Time_Edit__c.' + fieldName + ' not found!');
            System.debug(logginglevel.error, e);
        }
        return value;
    }
    /**
     * Gets an Accel_Time_Edit__c instance.
     *
     * @param userProfileId The Running user profile id or user id.
     * @return an Accel Time Edit sObject.
     */
    global  static Accel_Time_Edit__c getAccelTimeEditSettings(Id userProfileId) {
        Accel_Time_Edit__c customSetting = Accel_Time_Edit__c.getInstance(userProfileId);
        return customSetting;
    }
    global static Trigger_Settings__c getTriggerSettings(Id userId) {
        Trigger_Settings__c customSetting = Trigger_Settings__c.getInstance(userId);
        return customSetting;
    }
    global static Batch_Settings__c getBatchSettings(Id userId) {
        Batch_Settings__c customSetting = Batch_Settings__c.getInstance(userId);
        return customSetting;
    }
    global static Batch_Settings__c getBatchSettings() {
        Batch_Settings__c customSetting = Batch_Settings__c.getOrgDefaults();
        return customSetting;
    }
    /**
     * Gets an instance of Service_Utility_Bar_Config__c.
     *
     * @param userProfileId The Running user profile id or user id.
     * @return an Service_Utility_Bar_Config__c custom setting.
     */
    global static Service_Utility_Bar_Config__c getSvcUtilityBarConfig(Id userProfileId) {
        Service_Utility_Bar_Config__c customSetting = Service_Utility_Bar_Config__c.getInstance(userProfileId);
        return customSetting;
    }
    /**
     *
     *
     * @param userProfileId
     *
     * @return
     */
    global static Software_Assets_Config__c getSoftwareAssetsConfigSettings(Id userProfileId) {
        Software_Assets_Config__c customSetting = Software_Assets_Config__c.getInstance(userProfileId);
        return customSetting;
    }
}