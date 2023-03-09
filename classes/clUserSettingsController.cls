/**
 * View based controller for Cash Logistics User Settings.
 * @see clUserSettingsSvc
 */
public with sharing class clUserSettingsController {

    @TestVisible private final static String MAP_KEY_USER_SETTING = 'USER_SETTING';

    /**
     * @param userId   The User.Id value
     * @return         A CL_User_Setting__c sObject with only Id and Selected_Machine_Type__c populated.
     */
    @AuraEnabled
    public static ResponseDto retrieveUserSettings(Id userId) {

        ResponseDto dto = new ResponseDto();
        CL_User_Setting__c viewSetting;

        CL_User_Setting__c setting = clUserSettingsSvc.retrieveSetting(userId);
        if(setting != null) {
            //  Deliver a subset of values to client to save bandwidth
            viewSetting = new CL_User_Setting__c(
                    Id = setting.Id,
                    User__c = setting.User__c,
                    Selected_Machine_Type__c = setting.Selected_Machine_Type__c
            );
        }
        dto.isSuccess = setting != null;
        dto.technicalMsg = dto.isSuccess ? 'success' : 'notfound';

        dto.values.put(MAP_KEY_USER_SETTING,viewSetting);
        return dto;
    }

    /**
     * @param id            The Cl_User_Setting__c.Id value.
     * @param machineType   The Cl_User_Setting__c.Selected_Machine_Type__c value.
     *
     * @return              A ResponseDto with the updated values.
     */
    @AuraEnabled
    public static ResponseDto updateSetting(Id id, String machineType) {
        ResponseDto dto = new ResponseDto();

        CL_User_Setting__c userSetting = new CL_User_Setting__c(Id = id, User__c = UserInfo.getUserId(),Selected_Machine_Type__c = machineType);
        try {
            update userSetting;
            dto.technicalMsg +=' called update with: '+userSetting;
            dto.isSuccess = true;
            userSetting = clUserSettingsSvc.retrieveSetting(userSetting.User__c);
            //  Deliver a subset of values to client to save bandwidth
            CL_User_Setting__c viewSetting = new CL_User_Setting__c(
                    Id = userSetting.Id,
                    User__c = userSetting.User__c,
                    Selected_Machine_Type__c = userSetting.Selected_Machine_Type__c
            );
            dto.values.put(MAP_KEY_USER_SETTING,viewSetting);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'user setting attempted to update: '+userSetting;
            dto.technicalMsg += 'error on update ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }

    /**
     * @param userId        The User.Id value.
     * @param machineType   The Cl_User_Setting__c.Selected_Machine_Type__c value.
     *
     * @return              A ResponseDto with the inserted values.
     */
    @AuraEnabled
    public static ResponseDto insertSetting(Id userId, String machineType) {
        ResponseDto dto = new ResponseDto();

        CL_User_Setting__c userSetting = new CL_User_Setting__c(
                Name = UserInfo.getName() + ' setting',
                User__c = userId,
                Selected_Machine_Type__c = machineType
        );
        try {
            insert userSetting;
            dto.technicalMsg +=' called insert with: '+userSetting;
            dto.isSuccess = true;
            userSetting = clUserSettingsSvc.retrieveSetting(userSetting.User__c);
            //  Deliver a subset of values to client to save bandwidth
            CL_User_Setting__c viewSetting = new CL_User_Setting__c(
                    Id = userSetting.Id,
                    User__c = userSetting.User__c,
                    Selected_Machine_Type__c = userSetting.Selected_Machine_Type__c
            );
            dto.values.put(MAP_KEY_USER_SETTING,viewSetting);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'user setting attempted to insert: '+userSetting;
            dto.technicalMsg += 'error on update ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }
}