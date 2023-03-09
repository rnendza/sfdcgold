/**
 * AppLogSvc provides for various operations supporting the logging to Accel_Application_Error__c.
 *
 * @see TEST_AppLogSvc
 * @see BatchjobSvc
 */
public with sharing class AppLogSvc {

    //  The max size of the long text field so as to ensure we don't exceed it upon update.
    @TestVisible private static Integer FIELD_SIZE_EXEC_DETAILS = 131072;
  
    public static final String JOB_TYPE_TRIGGER = 'Trigger';
    public static final String JOB_STATUS_PROCESSING = 'Processing';
    public static final String JOB_STATUS_SUCCESS = 'Success';
    public static final String JOB_STATUS_PARTIAL_SUCCESS = 'Partial Success';
    public static final String JOB_STATUS_FAILED = 'Failed';

   /**
    * @param  logId the Id of the Accel_Application_Error__c to find.
    * @return An Accel_Application_Error__c sObject with all fields.
    */
    public static Accel_Application_Error__c retrieveLog(Id logId) {
        Accel_Application_Error__c log;

        try {
            DescribeSObjectResult describeResult = Accel_Application_Error__c.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
            String q =  'SELECT ' + String.join(fieldNames, ',') + ' FROM  ' + describeResult.getName() + ' WHERE Id = :logId';
            log = Database.query(q);
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        return log;
    }

    /**
     * @param rtDevName     The DeveloperName of the record type on Accel_Application_Error__c
     * @param jobName       The Name of the job.
     *
     * @return              An instantiated, but not inserted Accel_Application_Error__c sObject
     */
    public static Accel_Application_Error__c buildLog(String rtDevName, String jobName) {

        Accel_Application_Error__c log = new Accel_Application_Error__c();
        Id rtId;
        Schema.RecordTypeInfo rtInfo =  SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName().get(rtDevName);

        if(rtInfo != null) {
            rtId = rtInfo.getRecordTypeId();
        } else {
            System.debug(LoggingLevel.WARN,'Could not find Application_Error__c rt for dev name='+rtDevName);
        }

        log.User__c = UserInfo.getUserId();
        log.Job_Name__c = jobName;
        log.RecordTypeId = rtId;
        log.Total_Executions__c = 1;
        log.Process_Start_Date__c = System.now();
        log.Execution_Details__c = '';

        return log;
    }

   /**
    * Merely calls an update on the log. Also protects against the exceeding the Execution_Details__c field size.
    *
    * @param log  An Application_Log__c sObject.
    * @return     The updated Application_Log__c sObject.
    */
    public static Accel_Application_Error__c updateLog(Accel_Application_Error__c log) {
        if(log.Execution_Details__c != null && log.Execution_Details__c.length() > FIELD_SIZE_EXEC_DETAILS) {
            log.Execution_Details__c = log.Execution_Details__c.left(FIELD_SIZE_EXEC_DETAILS);
        }
        update log;
        return log;
    }

}