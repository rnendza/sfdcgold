/**
 * BatchjobSvc provides for various operations supporting the execution of a Batch Apex Job.
 * It wraps various logging an email methods tuning them specially for calling from a  BatchJob
 *
 * @see AppLogSvc           For Job Logging to Accel_Application_Error__c.
 * @see EmailSvc            For Sending of an Email Template.
 * @see BatchSample         For usage of these methods.
 * @see TEST_BatchSample    For usage of these methods.
 */
public without sharing class BatchjobSvc {

    public static String DEFAULT_EMAIL_TEMPLATE     = 'Salesforce_Job_Notification';

    //  Various defaults.
    @TestVisible private static String DEFAULT_OWA_EMAIL_ADDRESS = 'crm@accelentertainment.com';
    @TestVisible private static String DEFAULT_NO_REPLY_ADDRESS = 'no-reply@accelentertainment.com';

    /**
     * @param ql    A Database.QueryLocator object.
     * @return      The size of the iterator. ie. total number of results.
     */
    public static Integer findQueryLocatorSize(Database.QueryLocator ql) {
        Integer iSize = 0;

        Database.QueryLocatorIterator itr = ql.iterator();
        while(itr.hasNext()) {
            iSize++;
            itr.next();
        }
        return iSize;
    }

    /**
     * @param developerName   The DeveloperName of the custom metadata record.
     * @return                An instance of the Batch_Job_Setting__mdt if found, otherwise null.
     */
    public static Batch_Job_Setting__mdt queryForMetadata(String developerName) {
        Batch_Job_Setting__mdt mdt;
        SObject sObj = CustomMetadataSvc.retrieveCustomMetadata(Batch_Job_Setting__mdt.getSobjectType(), developerName);
        if(sObj != null) {
            mdt = (Batch_Job_Setting__mdt)sObj;
        }
        return mdt;
    }

    /**
     * @param jobName  The name of the Batch Job.
     * @return         An Accel_Application_Error__c sObject (not inserted)
     */
    public static Accel_Application_Error__c buildLog(String jobName) {
        String rtDevName ='Salesforce_Jobs';
        return AppLogSvc.buildLog(rtDevName,jobName);
    }

    /**
     * @param log   An Accel_Application_Error_Log__c sObject.
     * @return      List<Messaging.SendEmailResult>  results of the send.
     */
    public static  List<Messaging.SendEmailResult> sendEmail(Accel_Application_Error__c log) {
        EmailTemplate template = EmailSvc.retrieveEmailTemplate(DEFAULT_EMAIL_TEMPLATE);
        Id whoId = log.OwnerId;
        List<Messaging.SendEmailResult> sendResults = sendEmail(log,new Set<Id>{whoId},template.Id);
        return sendResults;
    }

    /**
     * @param log               An Accel_Application_Error_Log__c sObject.
     * @param templateDevName   The developername of the EmailMessage sObject record.
     * @return                  List<Messaging.SendEmailResult>  results of the send.
     */
    public static  List<Messaging.SendEmailResult> sendEmail(Accel_Application_Error__c log,Set<Id> whoIds,String templateDevName) {
        EmailTemplate template = EmailSvc.retrieveEmailTemplate(templateDevName);
        Id whoId = log.OwnerId;
        List<Messaging.SendEmailResult> sendResults = sendEmail(log,whoIds,template.Id);
        return sendResults;
    }

    /**
     * @param log           An Accel_Application_Error_Log__c sObject.
     * @param whoIds        The Set of User Ids of the user to send the email to.
     * @param templateId    The Id of the EmailTemplate to send.
     *
     * @return              List<Messaging.SendEmailResult>  results of the send.
     */
    public static List<Messaging.SendEmailResult> sendEmail(Accel_Application_Error__c log, Set<Id> whoIds,Id templateId) {
        List<Messaging.SendEmailResult> sendResults =
                EmailSvc.sendEmailTemplate(whoIds,log.Id,templateId,DEFAULT_NO_REPLY_ADDRESS,DEFAULT_OWA_EMAIL_ADDRESS);
        return sendResults;
    }

   /**
    * @param log           An Accel_Application_Error_Log__c sObject.
    * @param whoIds        The Set of User Ids of the user to send the email to.
    * @param templateId    The Id of the EmailTemplate to send.
    * @param dynaHtml      Dynamic html to inject in template.
    *
    * @return              List<Messaging.SendEmailResult>  results of the send.
    */
    public static List<Messaging.SendEmailResult> sendEmail(Accel_Application_Error__c log, Set<Id> whoIds,Id templateId, String dynaHtml) {
        List<Messaging.SendEmailResult> sendResults =
                EmailSvc.sendEmailTemplate(whoIds,log.Id,templateId,dynaHtml,DEFAULT_NO_REPLY_ADDRESS,DEFAULT_OWA_EMAIL_ADDRESS,false,false,false);
        return sendResults;
    }


   /**
    * Bulkified version of sendEmail!
    *
`   * @param emailDatas     A List<BatchEmailData> of wrapper classes to translate into a bulk payload.
    * @return              List<Messaging.SendEmailResult>  results of the send.
    *
    * @see BatchEmailData
    */
    public static List<Messaging.SendEmailResult> sendEmailTemplates(List<BatchEmailData> emailDatas) {

        List<BulkEmailPayload> payloads = new List<BulkEmailPayload>();
        for(BatchEmailData data : emailDatas ) {
            BulkEmailPayload payload = new BulkEmailPayload();

            payload.owaEmailAddy = DEFAULT_OWA_EMAIL_ADDRESS;
            payload.replyTo = DEFAULT_NO_REPLY_ADDRESS;
            payload.templateId = data.templateId;
            payload.whatId = data.log.Id;
            payload.whoIds = data.whoIds;

            payload.dynamicHtml = data.dynamicHtml;
            payload.setSaveAsActivity = false;
            payload.setBccSender = false;
            payload.useSignature = false;

            payloads.add(payload);
        }
        List<Messaging.SendEmailResult> sendResults = EmailSvc.sendEmailTemplates(payloads);
        return sendResults;
    }

    /**
     * @todo doc
     */
    public class BatchEmailData {
        public Accel_Application_Error__c log;
        public Set<Id> whoIds;
        public Id templateId;
        public String  dynamicHtml;
    }
}