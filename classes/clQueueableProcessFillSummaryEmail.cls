/**
 * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/1739514537
 * (There aren't really detailed reqs but this is what we got to work with)
 */
public class clQueueableProcessFillSummaryEmail implements Queueable{

    //  Various defaults.
    @TestVisible private static String DEFAULT_TEMPLATE_DEV_NAME = 'CL_Processing_Fill_Summary';
    @TestVisible private static String FALLBACK_EMAIL_ADDRESS    = 'rick@chicagosalesforceconsulting.com';
    @TestVisible private final static String MDT_DEV_NAME_RPS_EMAIL = 'clQueueableProcessFillSummaryEmail';
    @TestVisible private Id jobId;
    @TestVisible private String templateDevName = DEFAULT_TEMPLATE_DEV_NAME;
    @TestVisible private Cash_Logistics_Automation_Setting__mdt automationMdt;
    @TestVisible private Cash_Logistics_Schedule_Setting__mdt scheduleMdt;
    @TestVisible private String region;            //  aka processing location;
    @TestVisible private String region_dev_name;   //  developer name of region


    /**
     * @param region The region.. aka processing location
     */
    public clQueueableProcessFillSummaryEmail(String region) {
        this.automationMdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_RPS_EMAIL);
        this.region = region;
        if(this.region != null) {
            this.region_dev_name = this.region.replaceAll(' ','_');
        }
        this.scheduleMdt =
                (Cash_Logistics_Schedule_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(
                        Cash_Logistics_Schedule_Setting__mdt.getSObjectType(),this.region_dev_name);
    }

    /**
     * Implements the queueable execute interface.
     * @param ctx The Queueable context.
     */
    public void execute(QueueableContext ctx) {
        this.jobId = ctx.getJobId();
        performExecute();
    }

    /**
     * Fire bus logic to get rps data, insert a dummy contact (to allow for sending of an email template to a
     * non user / contact. Build the dynamic email html.  Fire the SendMessage.
     */
    @TestVisible
    private void performExecute() {
        clRouteSvc.ProcessingFillSummary processingFillSummary = clRouteSvc.retrieveRpsFillDataResults(region);
        System.debug('---> processengingFillSummary Record: '+processingFillSummary);
        System.debug('---> automation Mdt= '+automationMdt);
        if(automationMdt.Send_Email__c) {
            Contact c = new Contact(LastName = 'dummy', Email='no-reply@accelentertainment.com');
            insert c;
            List<clRouteSvc.EmailData> emailDatas = buildEmails(processingFillSummary,c.Id);
            fireEmail(emailDatas,c.Id);
        }
    }

    /**
     * Send the email template and delete the bogus user.
     *
     * @param rsEmailDatas      EmailData used to fire the email off.
     * @param dummyRecipientId  A recently inserted contact id.
     */
    @TestVisible
    private void fireEmail(List<clRouteSvc.EmailData> emailDatas, Id dummyRecipientId) {

        List<Messaging.SendEmailResult> sendResults = clRouteSvc.sendEmailTemplates(emailDatas);
        System.debug('---> sendResults:'+sendResults);
        Contact c = [SELECT Id FROM Contact WHERE Id = :dummyRecipientId];
        delete c;
    }

    /**
     * @param processingFillSummary  A wrapper object around Route_Processing_Sheet__c data.
     * @param dummyRecipientId       A recently inserted contact Id.
     *
     * @return                       An object that wraps email data.
     */
    @TestVisible
    private List<clRouteSvc.EmailData> buildEmails(clRouteSvc.ProcessingFillSummary processingFillSummary, Id dummyRecipientId ) {

        List<clRouteSvc.EmailData> emails =  new List<clRouteSvc.EmailData>();

        EmailTemplate emailTemplate = EmailSvc.retrieveEmailTemplate(this.templateDevName);
        List<String> toAddresses = new List<String>();

        Set<String> publicGroupEmails = this.getPublicGroupEmails();
        if(publicGroupEmails != null && !publicGroupEmails.isEmpty()) {
            toAddresses.addAll(publicGroupEmails);
        } else if(this.scheduleMdt != null && this.scheduleMdt.External_Group_Email_Addresses__c != null) {
            String emailAddys = this.scheduleMdt.External_Group_Email_Addresses__c;
            toAddresses = emailAddys.split(',');
        } else {
            toAddresses.add(FALLBACK_EMAIL_ADDRESS);
        }



        if(emailTemplate != null) {
            clRouteSvc.EmailData data = new clRouteSvc.EmailData();

            data.templateId = emailTemplate.Id;

            data.dynamicHtml = this.buildEmailDynamicData(processingFillSummary);
            data.emailAddresses = toAddresses;
            data.dummyRecipientId = dummyRecipientId;
            data.dynamicSubject = 'Cash Logistics - ' + processingFillSummary.processingLocation + ' - Processing Fill Summaries';
            data.saveAsActivity = false;
            emails.add(data);
        } else {
            System.debug(LoggingLevel.ERROR,'Could not find email template: '+this.templateDevName);
        }

        return emails;
    }

    /**
     * @param processingFillSummary  A wrapper object around Route_Processing_Sheet__c data.
     * @return                       A String containing dynamic html to inject into the email template
     *
     * @todo better mobile / desktop adaptation
     */
    private String buildEmailDynamicData(clRouteSvc.ProcessingFillSummary processingFillSummary) {

        String html = '';
        if (processingFillSummary != null && processingFillSummary.errorMsg == null) {
            //  ---- GRAND TOTALS
            html += '<br/>';
            html += '<table border="0" cellpadding="2" cellspacing="1" width="100%">';
            html += '<tbody>';
            html += '<tr>';
            html += '<td colspan=2 bgcolor="#F3F2F2">';
            html += '  <span style="font-size:11px;">';
            html += '   <b>&nbsp;Grand Totals - '+processingFillSummary.processingLocation+'</b>';
            html += '  </span>';
            html += '</td>';
            html += '</tr>';
            html += '</tbody>';
            html += '</table>';

            html += '<table border="0" cellpadding="2" cellspacing="1" width="100%">';
            html += '<tbody>';
            for (clRouteSvc.NoteCount grandTotal : processingFillSummary.grandTotals) {
                html += '<tr>';
                html += '<td style="width:2%">&nbsp;</td>';
                html += '<td style="font-size:11px;"> $' + Integer.valueOf(grandTotal.denom) + ' Note Count</td>';
                html += '<td style="font-size:11px;">' + Integer.valueOf(grandTotal.value) + '</td>';
                html += '</tr>';
            }
            html += '</tbody>';
            html += '</table>';
            html += '<br/>';
            html += '<table border="0" cellpadding="2" cellspacing="1" width="100%">';
            html += '<tbody>';
            for(clRouteSvc.RouteNoteCount routeNoteCount : processingFillSummary.routeNoteCounts) {
                html += '<tr>';
                html += '<td colspan=3 bgcolor="#F3F2F2">';
                html += '  <span style="font-size:11px;">';
                html += '   <b>&nbsp;'+routeNoteCount.routeName + ' ' + routeNoteCount.processingLocation+'</b>';
                html += '  </span>';
                html += '</td>';
                html += '</tr>';
                html += '<tr>';
                html += '<td style="width:2%">&nbsp;</td>';
                html += '<td style="font-size:11px;"> $1 Note Count</td>';
                html += '<td style="font-size:11px;">' + Integer.valueOf(routeNoteCount.noteCount1.value) + '</td>';
                html += '</tr>';
                html += '<tr>';
                html += '<td style="width:2%">&nbsp;</td>';
                html += '<td style="font-size:11px;"> $5 Note Count</td>';
                html += '<td style="font-size:11px;">' + Integer.valueOf(routeNoteCount.noteCount5.value) + '</td>';
                html += '</tr>';
                html += '<tr>';
                html += '<td style="width:2%">&nbsp;</td>';
                html += '<td style="font-size:11px;"> $20 Note Count</td>';
                html += '<td style="font-size:11px;">' + Integer.valueOf(routeNoteCount.noteCount20.value) + '</td>';
                html += '</tr>';
                html += '<tr>';
                html += '<td style="width:2%">&nbsp;</td>';
                html += '<td style="font-size:11px;"> $50 Note Count</td>';
                html += '<td style="font-size:11px;">' + Integer.valueOf(routeNoteCount.noteCount50.value) + '</td>';
                html += '</tr>';
                html += '<tr>';
                html += '<td style="width:2%">&nbsp;</td>';
                html += '<td style="font-size:11px;"> $100 Note Count</td>';
                html += '<td style="font-size:11px;">' + Integer.valueOf(routeNoteCount.noteCount100.value) + '</td>';
                html += '</tr>';
            }
            html += '</tbody>';
            html += '</table>';
            html += '</tbody>';
            html += '</table>';
            html += '</br>';

        } else {
            html += '<div>';
            html +=  '<span style="color:red">';
            html +=  +processingFillSummary.errorMsg;
            html +=  '</span>';
            html += '</div>';
        }
        return html;
    }

    @TestVisible
    private Set<String> getPublicGroupEmails() {
        System.debug('----> getting public group emails with dev name='+region_dev_name);
        Cash_Logistics_Region__mdt regionMdt = (Cash_Logistics_Region__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Region__mdt.getSObjectType(),this.region_dev_name);
        List<String> publicMdtDevNames = regionMdt.Fill_Email_Public_Group_Dev_Names__c.split(',');
        System.debug('----> group dev names='+publicMdtDevNames);
        List<User> groupUsers = retrievePublicGroupsUsersRecords(publicMdtDevNames);
        System.debug('---> groupUsers='+groupUsers);

        Set<String> groupEmails = new Set<String>();
        for(User user : groupUsers) {
            groupEmails.add(user.email);
        }
        return groupEmails;
    }

    public List<User> retrievePublicGroupsUsersRecords(List<String> groupNames) {
        List<User> users = [
                SELECT Id,Email,userName
                FROM    User
                WHERE Id IN (
                        SELECT UserOrGroupId
                        FROM GroupMember
                        WHERE Group.DeveloperName IN :groupNames
                )];
        return users;
    }
}