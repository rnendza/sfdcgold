/**
 * Controller that backs the SvcWatchdogTimerContainer component.
 */
public with sharing class SvcWatchdogTimerContainerController {
    /**
     * Finds the Service Utility Bar Config custom setting for the running user.
     * @return a instance of Service_Utility_Bar_Config__c
     */
    @AuraEnabled
    public static Service_Utility_Bar_Config__c retrieveSvcWatchdogUtilityBarSettings() {
        Service_Utility_Bar_Config__c configSetting = CustomSettingsSvc.getSvcUtilityBarConfig( UserInfo.getUserId() );
        return configSetting;
    }
    /**
     * 
     * @param permissionSetApiName
     * @return
     */
    @AuraEnabled (Cacheable=true)
    public static Boolean isUserInPermissionSet(String permissionSetApiName){
        return PermissionSetSvc.isUserInPermissionSet(permissionSetApiName);
    }
}