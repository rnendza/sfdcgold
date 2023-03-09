global class MailAction {

    @InvocableMethod(label='Send Municipality Emails' description='send municipality emails upon change of muni.')
    global static List<EmailActionResult> sendMuniEmails(List<Id> muniIds) {
        List<EmailActionResult> results = new List<EmailActionResult>();
        Id muniId = muniIds[0];
        List<Account> accounts = [select id, Relationship_Manager__c from account where municipalitylookup__c = :muniId];
        Set<Id> userIds = new Set<Id>();
        for(Account account : accounts) {
            if(account.Relationship_Manager__c != null) {
                userIds.add(account.Relationship_Manager__c);
            }
        }
        String templateDevName  = 'Accel_EmailTemplate_MunicipalityChange'; //@TODO custom setting
        sendTemplateEmailInFuture(muniId,userIds,templateDevName,'');
        return results;
    }
    @future
    global static void sendTemplateEmailInFuture(Id muniId, Set<Id> userIds, String templateDevName, String replyToAddy) {
        Boolean success =  MailSvc.sendCustomMailTemplates(muniId,userIds,templateDevName,null);
    }
    global class EmailActionResult {
        @InvocableVariable
        global Boolean isSuccess;
        @InvocableVariable
        global String errorMessage;
    }
}