global class MailSvc {

    /**
     * @param whatId            - the what Id. .ie custom object id, account id, opp id etc.
     * @param recipientIds      - the recipient ids.. ie user / contact / group etc.
     * @param templateDevName   - the dev name of the template.
     * @param senderDisplayName - @TODO what do we want this to use?
     *
     * @return true if send succeeds / otherwise false.
     */
    global static boolean sendCustomMailTemplates(Id whatId, Set<Id> recipientIds, String templateDevName, String senderDisplayName) {

        List<EmailTemplate>ets = [SELECT id FROM EmailTemplate WHERE developerName = :templateDevName];
        EmailTemplate et;
        if (ets.isEmpty()) {
            System.debug(' template Dev NAME:' + templateDevName + ' not found on the EmailTemplate Object');
            return false;
        } else {
            et = ets[0];
        }
        system.debug('whatId=' + whatId);
        system.debug('recipient ids=' + recipientIds);
        List<Messaging.SingleEmailMessage>mails = new List<Messaging.SingleEmailMessage>();
        //OrgWideEmailAddress owa = retrieveOWA('owaname');

        //build a list of singleemailmessages so we only count as 1 send against gov limits.
        for (Id recipientId : recipientIds) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.saveAsActivity = false;
            //if(owa != null) {
            //    mail.setOrgWideEmailAddressId(owa.id);
            //} else {
            if (senderDisplayName != null && senderDisplayName != '') {
                //mail.setSenderDisplayName(senderDisplayName);
            }
            //}
            mail.setTargetObjectId(recipientId); // Specify who the email should be sent to.
            mail.setTemplateId(et.id);
            mail.setWhatId(whatId);
            mails.add(mail);
        }
        try {
            Messaging.sendEmail(mails);
        } catch (System.Emailexception ex) {
            System.debug(' Exception caught sending email-->' + ex.getMessage());
            return false;
        }
        return true;
    }
}