/**
 * A wrapper for ease of sending multiple emails at once.
 * @see EmailSvc.SendEmailTemplates
 */
public class BulkEmailPayload {

    //  An Id of the target object id ie. the Id of the Account sObject record.
    public Id whatId;

    //  A Set<Id> of SFDC UserIds to send the email to.
    public Set<Id> whoIds;

    //  The Id of the email template.
    public Id templateId;

    //  If your template contains a div with an Id of custom_dynamic_html the dynamicHtml
    //  String will be injected into that tags content. if null it will be ignored.
    public String dynamicHtml;

    //  The reply to email address (optional).
    public String replyTo;

    //  The Org Wide Address email address. (optional but recommended to supply this)
    public String owaEmailAddy;

    //  True if we want to use the email signature, otherwise false.
    public Boolean useSignature;

    //  True if we want to set the bcc sender, otherwise false.
    public Boolean setBccSender;

    //  True if we want to save an activity, otherwise false.
    public Boolean setSaveAsActivity;

    //  Internal use.
    public OrgWideEmailAddress owa;

    public BulkEmailPayload() {}
}