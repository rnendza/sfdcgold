/**
 * A wrapper for ease of sending multiple emails at once.
 * @see EmailSvc.SendEmailTemplates
 */
public class BulkEmailExternalPayload {


    //  A Set<String> of external email addresses (no whoIds)
    public Set<String> externalEmailAddresses;

    //  The Id of the email template.
    public Id templateId;

    //  If your template contains a div with an Id of custom_dynamic_html the dynamicHtml
    //  String will be injected into that tags content. if null it will be ignored.
    public String dynamicHtml;

    //  The reply to email address (optional).
    public String replyTo;

    //  A Dummy Contact;
    public Id dummyRecipientId;

    //  The Org Wide Address email address. (optional but recommended to supply this)
    public String owaEmailAddy;

    //  True if we want to use the email signature, otherwise false.
    public Boolean useSignature;

    //  True if we want to set the bcc sender, otherwise false.
    public Boolean setBccSender;

    //  True if we want to save an activity, otherwise false.
    public Boolean setSaveAsActivity;

    public String dynamicSubject;

    //  Internal use.
    public OrgWideEmailAddress owa;

    public BulkEmailExternalPayload() {}
}