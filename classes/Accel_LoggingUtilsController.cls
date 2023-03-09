/**
 * Generally logging utils...
 */
public without sharing class Accel_LoggingUtilsController {

    public static final String APP_ERROR_LOG_RT_COMMUNITY_DEVNAME       = 'Community';
    public static final String APP_ERROR_LOG_RT_Salesforce_CRM_DEVNAME  = 'Salesforce_CRM';

    /**
     * Logs an error message to Accel_Application_Error__c. If no recordtype Id, gets if we are in a community context
     * and uses community as the record type. It is the clients responsibility to pass a valid record type Id.
     *
     * @param msg           The Message to Log.
     * @param recordTypeId  Pass this if we are not in a community.
     * @return              A ResponseDto object containing result information.
     */
    @AuraEnabled
    public static ResponseDto logErrorMessage( String msg, String recordTypeId ) {

        ResponseDto dto = new ResponseDto();
        try {
            Accel_Application_Error__c err = new Accel_Application_Error__c();
            String rtDevName;
            String communitySiteId = Site.getSiteId();

            if(recordTypeId == null) {
                if (communitySiteId != null) {
                    rtDevName = APP_ERROR_LOG_RT_COMMUNITY_DEVNAME; //Cant Unit Test this line. due to SFDC Lameness
                } else {
                    rtDevName = APP_ERROR_LOG_RT_Salesforce_CRM_DEVNAME;
                }
                recordTypeId =  SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName().get(rtDevName)
                        .getRecordTypeId();
            }
            err.RecordTypeId = recordTypeId;
            err.Stack_Trace__c = msg;
            err.User__c = UserInfo.getUserId();
            insert err;
            dto.isSuccess = true;
            dto.technicalMsg = 'logged msg:'+msg+'..for suser='+UserInfo.getUserId()+'rtId='+recordTypeId;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.technicalMsg = e.getMessage() + e.getStackTraceString();
        }
        return dto;
    }
}