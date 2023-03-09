/**
 * EmailSvc provides for wrappers around Messaging.sendEmail
 */
public without sharing class EmailSvc {

    @TestVisible private static String DEFAULT_NO_REPLY_ADDRESS = 'no-reply@accelentertainment.com';
    @TestVisible private static String DEFAULT_SENDER_DISPLAY_NAME = '- Salesforce Automation -';

    //  Searches for this string in a template and replaces it.
    @TestVisible private static String CUSTOM_DYNAMIC_HMTL_TOKEN = '<div style="display:none">[[[custom_dynamic_html]]]</div>';

    /**
     * @param emailAddys        An array of email addresses to send to.
     * @param subject           The subject of the email.
     * @param body              The body of the email.
     */
    public static void sendEmail(String[] emailAddys, string subject,string body){
        sendEmail(emailAddys,null,subject,body);
    }

    /**
     * @param emailAddys        An array of email addresses to send to.
     * @param replyTo           The replyTo address (optional).
     * @param subject           The subject of the email.
     * @param body              The body of the email.
     */
    public static void sendEmail(String[] emailAddys, String replyTo, string subject,string body){
        sendEmail(emailAddys,replyTo,subject,body,null,null);
    }

    /**
     * @param emailAddys        An array of email addresses to send to.
     * @param replyTo           The replyTo address (optional).
     * @param subject           The subject of the email.
     * @param body              The body of the email.
     * @param attachments       Any attachments for the email (optional).
     * @param owaEmailAddy      The Org Wide Address email address. (optional but recommended to supply this).
     */
    public static void sendEmail(   String[] emailAddys, String replyTo, string subject,string body,
                                    List<Messaging.EmailFileAttachment> attachments,String owaEmailAddy){

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = emailAddys;
        mail.setToAddresses(toAddresses);
        if(replyTo != null) {
            mail.setReplyTo(replyTo);
        }
        if(owaEmailAddy == null) {
            mail.setSenderDisplayName('- Accel Salesforce Automation -');
        } else {
            OrgWideEmailAddress owa = retrieveOwa(owaEmailAddy);
            if(owa!=null) {
                mail.setOrgWideEmailAddressId(owa.id);
            }
        }
        mail.setSubject(subject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(body);
        mail.setHtmlBody(body);
        if(attachments != null && !attachments.isEmpty()) {
            mail.setFileAttachments(attachments);
        }
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }

    /**
     * @param devName   The developername of HPD_Total_Setting_mdt record to find the notification address.
     * @return          A List of email addresses if found, otherwise an empty list.
     */
    public static List<String> getHpdEmailNotificationAddys( String devName ) {
        List<String> emailAddys = new List<String>();
        HPD_Total_Setting__mdt hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(devName);
        if (hpdTotalSetting != null) {
            String sEmailAddy = hpdTotalSetting.Notification_Email_Addresses__c;
            if (sEmailAddy != null) {
                emailAddys = sEmailAddy.split(',');
            }
        }
        if (emailAddys.isEmpty()) {
            emailAddys.add('rick@chicagosalesforceconsulting.com');
        }
        return emailAddys;
    }

    /**
     * @param emailAddy     The Address of the OrgWideEmailAddress record.
     * @return              The OrgWideEmailAddress sObject record.
     */
    public static OrgWideEmailAddress retrieveOwa( String emailAddy ) {
        OrgWideEmailAddress owa;
        List<OrgWideEmailAddress> orgWideEmailAddresses = [
                SELECT  Id,Address
                FROM    OrgWideEmailAddress
                WHERE Address = :emailAddy
        ];
        if(!orgWideEmailAddresses.isEmpty()) {
            owa = orgWideEmailAddresses[0];
        }
        return owa;
    }

   /**
    * @param emailAddys    A Set<String> of Address values of the OrgWideEmailAddress record.
    * @return              A Map of String email => OrgWideEmailAddress .
    */
    public static Map<String,OrgWideEmailAddress> retrieveOwas( Set<String> emailAddys ) {

        Map<String,OrgWideEmailAddress> m = new Map<String,OrgWideEmailAddress>();

        Map<Id,OrgWideEmailAddress> orgWideEmailAddresses = new Map<Id,OrgWideEmailAddress>([
                SELECT  Id,Address
                FROM    OrgWideEmailAddress
                WHERE   Address IN :emailAddys
        ]);

        if(!orgWideEmailAddresses.isEmpty()) {
            for(OrgWideEmailAddress owa : orgWideEmailAddresses.values()) {
                m.put(owa.Address,owa);
            }
        }
        return m;
    }

   /**
    * Sends an email to the salesforce user(s) (not external email addresses) so as not to go against outbound
    * email gov limits. Also injects dynamic html into the custom_dynamic_html div if the template contains one.
    *
    * @param whoIds        A Set<Id> of SFDC UserIds to send the email to.
    * @param whatId        An Id of the target object id ie. the Id of the Account sObject record.
    * @param templateId    The Id of the email template.
    * @param replyTo       The reply to email address (optional).
    * @param owaEmailAddy  The Org Wide Address email address. (optional but recommended to supply this)
    *
    * @return              A List of Messaging.SendEmailResults for the result for each whoId.
    *
    */
    public static List<Messaging.SendEmailResult> sendEmailTemplate( Set<Id> whoIds, Id whatId, Id templateId,
            String replyTo, String owaEmailAddy ) {
        System.debug('-->whoIds='+whoIds);
        return sendEmailTemplate(whoIds,whatId,templateId,null,replyTo,owaEmailAddy,false,false,false);
    }

    /**
     * Sends an email to the salesforce user(s) (not external email addresses) so as not to go against outbound
     * email gov limits.
     *
     * @param whoIds             A Set<Id> of SFDC UserIds to send the email to.
     * @param whatId             An Id of the target object id ie. the Id of the Account sObject record.
     * @param templateId         The Id of the email template.
     * @param dynamicHtml        If your template contains a div with an Id of custom_dynamic_html the dynamicHtml
     *                           String will be injected into that tags content. if null it will be ignored.
     * @param replyTo            The reply to email address (optional).
     * @param owaEmailAddy       The Org Wide Address email address. (optional but recommended to supply this)
     * @param useSignature       True if we want to use the email signature, otherwise false.
     * @param bSetBccSender      True if we want to set the bcc sender, otherwise false.
     * @param bSetSaveAsActivity True if we want to save an activity, otherwise false.
     *
     * @return              A List of Messaging.SendEmailResults for the result for each whoId.
     */
    public static List<Messaging.SendEmailResult> sendEmailTemplate( Set<Id> whoIds, Id whatId, Id templateId,String dynamicHtml,
            String replyTo, String owaEmailAddy, Boolean useSignature,Boolean bSetBccSender, Boolean bSetSaveAsActivity  ) {

        Messaging.SendEmailResult[] results;
        OrgWideEmailAddress owa;
        if(replyTo == null) {
            replyTo = DEFAULT_NO_REPLY_ADDRESS;
        }
        if(owaEmailAddy != null) {
            try {
                owa = EmailSvc.retrieveOwa(owaEmailAddy);
            } catch (Exception e) {
                //may happen if running user doesn't have access to OWA
                System.debug(e);
            }
        }
        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();
        for(Id whoId : whoIds) {

            //  Replace all merge fields.
            Messaging.SingleEmailMessage msg;
            try {
                msg = Messaging.renderStoredEmailTemplate(templateId, whoId, whatId);

                if(msg.getHtmlBody() != null && msg.getHtmlBody().contains(CUSTOM_DYNAMIC_HMTL_TOKEN) && dynamicHtml != null) {
                    String newBody = injectCustomHtmlInBody( msg.getHtmlBody(), dynamicHtml);
                    msg.setHtmlBody(newBody);
                }
            } catch (Exception e) {
                //   Most likely user put a bad merge variable in the template!
                System.debug(LoggingLevel.ERROR,'Error rendering template:' + e);
                continue;
            }
            msg.setSubject(msg.getSubject());
            msg.setHtmlBody(msg.getHtmlBody());
            if(owa != null) {
                msg.setOrgWideEmailAddressId(owa.Id);
            } else {
                msg.setSenderDisplayName(DEFAULT_SENDER_DISPLAY_NAME);
            }
            msg.setReplyTo(replyTo);
            msg.setUseSignature(useSignature);
            msg.setBccSender(bSetBccSender);
            msg.setSaveAsActivity(bSetSaveAsActivity);
            msg.setTemplateId(templateId);

            msgs.add(msg);
            System.debug(LoggingLevel.FINE,'----> msg='+msg);
        }

        if(!msgs.isEmpty()) {
            results = Messaging.sendEmail( msgs );
        }
        return results;
    }

    /**
     * Sends email(s) to the salesforce user(s) (not external email addresses) so as not to go against outbound
     * email gov limits.  This is the bulkified version of this. Use this if initiated from a Flow, Trigger, Queueable,
     * etc.
     *
     * @param payloads      A List<BulkEmailPayload> of all required info to send an email.
     * @return              A List of Messaging.SendEmailResults for the result for each whoId.
     *
     * @see BulkEmailPayload
     */
    public static List<Messaging.SendEmailResult> sendEmailTemplates( List<BulkEmailPayload> payloads  ) {

        Messaging.SendEmailResult[] results;
        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();

        //  Preps OWAs if any.
        Set<String> owaEmailAddys = new Set<String>();
        for(BulkEmailPayload payload : payloads) {
            if(!String.isBlank(payload.owaEmailAddy)) {
                owaEmailAddys.add(payload.owaEmailAddy);
            }
        }
        Map<String,OrgWideEmailAddress> mOwasByEmailAddy = new Map<String,OrgWideEmailAddress>();
        if(!owaEmailAddys.isEmpty()) {
            mOwasByEmailAddy = retrieveOwas(owaEmailAddys);
        }

        //  Main msg building iteration.
        for(BulkEmailPayload payload : payloads) {

            if( String.isNotBlank(payload.replyTo)) {
                payload.replyTo = DEFAULT_NO_REPLY_ADDRESS;
            }
            if( String.isNotBlank(payload.owaEmailAddy)) {
                if(!mOwasByEmailAddy.isEmpty()) {
                    payload.owa = mOwasByEmailAddy.get(payload.owaEmailAddy);
                }
            }
            for(Id whoId : payload.whoIds) {

                Messaging.SingleEmailMessage msg;
                try {
                    //  Replace all merge fields.
                    msg = Messaging.renderStoredEmailTemplate(payload.templateId, whoId, payload.whatId);
                    String dynaHtml = payload.dynamicHtml;

                    if(msg.getHtmlBody() != null && msg.getHtmlBody().contains(CUSTOM_DYNAMIC_HMTL_TOKEN) && dynaHtml != null) {
                        String newBody = injectCustomHtmlInBody( msg.getHtmlBody(), dynaHtml);
                        msg.setHtmlBody(newBody);
                    }

                    //  Build the basic email msg.
                    msg.setSubject(msg.getSubject());
                    msg.setHtmlBody(msg.getHtmlBody());
                    if(payload.owa != null) {
                        msg.setOrgWideEmailAddressId(payload.owa.Id);
                    } else {
                        msg.setSenderDisplayName(DEFAULT_SENDER_DISPLAY_NAME);
                    }
                    msg.setReplyTo(payload.replyTo);
                    msg.setUseSignature(payload.useSignature);
                    msg.setBccSender(payload.setBccSender);
                    msg.setSaveAsActivity(payload.setSaveAsActivity);
                    msg.setTemplateId(payload.templateId);

                    msgs.add(msg);
                    System.debug(LoggingLevel.FINE,'----> msg='+msg);

                } catch (Exception e) {
                    //   Most likely user put a bad merge variable in the template!
                    System.debug(LoggingLevel.ERROR,'Error rendering template:' + e);
                    continue;
                }
            }
        }
        if(!msgs.isEmpty()) {
            System.debug(LoggingLevel.DEBUG,'---> sending '+msgs.size() + ' email messages');
            results = Messaging.sendEmail( msgs );
        }
        return results;
    }

    /**
     * @param sBody         The original html body.
     * @param dynamicHtml   The html to replace the token with in the Email Template.
     *
     * @return              The new html body replacing the token found with the dynamic html passed in.
     */
    private static String injectCustomHtmlInBody(String sBody, String dynamicHtml) {
        if(sBody != null) {
            sBody = sBody.replace(CUSTOM_DYNAMIC_HMTL_TOKEN,dynamicHtml);
        }
        return sBody;
    }

    /**
     * @param devName   The developerName of the template.
     * @return          An EmailTemplate sObject if found / otherwise null.
     */
    public static EmailTemplate retrieveEmailTemplate(String devName) {
        EmailTemplate template;

        List<EmailTemplate> templates = [
                SELECT Id, DeveloperName,Name
                FROM   EmailTemplate
                WHERE  DeveloperName = :devName
        ];
        if(!templates.isEmpty()) {
            template = templates[0];
        }
        return template;
    }
 
    public static Map<Id,User> retrievePublicGroupsUsers(Set<Id> publicGroupIds) {
        Map<Id,User> mUsers = new Map<Id,User> ([
                SELECT  Id,Email,Username
                FROM    User
                WHERE   Id IN (
                                SELECT  UserOrGroupId
                                FROM    GroupMember
                                WHERE   GroupId IN :publicGroupIds
                              )
        ]);
        return mUsers;
    }

    public static List<User> retrievePublicGroupUsers(String groupName) {
        List<User> users = [SELECT Id,Email,userName FROM User WHERE Id IN (
                SELECT UserOrGroupId
                FROM GroupMember
                WHERE Group.DeveloperName = :groupName
        )];
        return users;
    }

}