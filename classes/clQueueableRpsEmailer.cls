public class clQueueableRpsEmailer implements Queueable{

    //  Various defaults.
    @TestVisible private static String DEFAULT_TEMPLATE_DEV_NAME = 'CL_Route_Schedule_Completed';
    @TestVisible private static String DEFAULT_OWA_EMAIL_ADDRESS = 'crm@accelentertainment.com';
    @TestVisible private static String DEFAULT_NO_REPLY_ADDRESS  = 'no-reply@accelentertainment.com';
    @TestVisible private static String SURVEY_MDT_DEV_NAME       = 'RPSQuestions';
    @TestVisible private static String NO_SURVEY_VALUE_DISPLAY   = '[Field left Blank]';
    public final static String MDT_DEV_NAME_RPS_EMAIL = 'clQueueableRpsEmailer';
    @TestVisible private final static String MDT_DEV_NAME_RPS       = 'Route_Processing_Sheet';

    @TestVisible private Id jobId;
    @TestVisible private Id rsId;
    @TestVisible private String publicGroupDevName = 'Cash_Logistics_Managers';
    @TestVisible private List<String> publicMdtDevNames = new List<String>();
    @TestVisible private String templateDevName = 'CL_Route_Schedule_Completed';
    @TestVisible private  Cash_Logistics_Automation_Setting__mdt automationMdt;
    @TestVisible private  Cash_Logistics_Setting__mdt expCloudMdt;
    @TestVisible private  Cash_Logistics_Region__mdt regionMdt;


    public clQueueableRpsEmailer() {

    }
    /**
     * @param rsId  The Route_Schedule__c.Id.
     */
    public clQueueableRpsEmailer(Id rsId) {
        this.rsId = rsId;
        this.automationMdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_RPS_EMAIL);
        this.expCloudMdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.getSObjectType(),MDT_DEV_NAME_RPS);
        System.debug('---> expCloudMdt='+expCloudMdt);
        if(automationMdt.Email_Template_Dev_Name__c != null)  {
            templateDevName = automationMdt.Email_Template_Dev_Name__c;
        }
//        if(automationMdt.Public_Group_Dev_Names__c != null) {
//            publicMdtDevNames = automationMdt.Public_Group_Dev_Names__c.split(',');
//        }
       // System.debug('---> public mdt dev names:'+publicMdtDevNames);
    }

    /**
     * @param rsId                  The Route_Schedule__c.Id.
     * @param publicGroupDevName    The developer name of Group.
     * @param templateDevName       The Email Template Developer Name to use.
     */
    public clQueueableRpsEmailer(Id rsId,String publicGroupDevName,String templateDevName) {
        this.rsId = rsId;
        this.publicGroupDevName = publicGroupDevName;
        this.expCloudMdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.getSObjectType(),MDT_DEV_NAME_RPS);
        this.templateDevName = templateDevName;
        this.automationMdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_RPS_EMAIL);
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
     *  Find Route_Processing_Sheet__c records for the parent route schedule id.
     *  Build email data (whoIds,whatIds,template etc).
     *  Fire off the survey email.
     */
    @TestVisible
    private void performExecute() {
        List<Route_Processing_Sheet__c> rpss =  this.queryRpsChildren();
        if(automationMdt.Send_Email__c || expCloudMdt.Show_Send_Route_End_Email_Menu_Item__c) {
            // @see https://accel-entertainment.monday.com/boards/1300348967/pulses/2898284761  7/5/2022
            if(rsId != null) {
                List<Route_Schedule__c> routeSchedules = [
                        SELECT Id,Route_End_Email_Sent_Date__c,Route_End_Email_Sent_By__c
                        FROM   Route_Schedule__c
                        WHERE  Id = :rsId
                ];
                if(!routeSchedules.isEmpty()) {
                    Route_Schedule__c rs = routeSchedules[0];
                    rs.Route_End_Email_Sent_Date__c = System.now();
                    rs.route_End_Email_Sent_By__c = UserInfo.getUserId();
                    update rs;
                }
            }
            for(Route_Processing_Sheet__c rps :rpss) {
                rps.Route_End_Email_Sent_Date__c = System.now();
                rps.Route_End_Email_Sent_by__c = UserInfo.getUserId();
            }
            update rpss;
            List<clRouteScheduleSvc.EmailData> rsEmailDatas = buildEmails(rpss);
            fireEmail(rsEmailDatas);
        }
    }

    /**
     * @param rsEmailDatas  EmailData used to fire the email off.
     */
    @TestVisible
    private void fireEmail(List<clRouteScheduleSvc.EmailData> rsEmailDatas) {

        List<Messaging.SendEmailResult> sendResults = clRouteScheduleSvc.sendEmailTemplates(rsEmailDatas);
        System.debug('---> sendResults:'+sendResults);
        //return sendResults;
    }

    /**
     * @return a List of Route_Processing_Sheet__c sObjects.
     */
    @TestVisible
    private List<Route_Processing_Sheet__c> queryRpsChildren() {

        List<Route_Processing_Sheet__c> rpssToGenEmail = new List<Route_Processing_Sheet__c>();

        List<Route_Processing_Sheet__c> routeProcessingSheets =
                clRouteProcessingSheetSvc.retrieveRouteProcessingSheets(this.rsId);

        if(!routeProcessingSheets.isEmpty()) {
            for(Route_Processing_Sheet__c rps : routeProcessingSheets) {
               rpssToGenEmail.add(rps);
            }
        }
        return rpssToGenEmail;
    }

    /**
     * Build the email (used to propulate the template) and build the 1-N child location records by injecteding
     * dynamic Html.
     *
     * @param routeProcessingSheets a List of Route_Processing_Sheet__c sObjects.
     * @return                      a List of EmailData objects.
     */
    @TestVisible
    private List<clRouteScheduleSvc.EmailData> buildEmails(List<Route_Processing_Sheet__c> routeProcessingSheets) {
        EmailTemplate emailTemplate = EmailSvc.retrieveEmailTemplate(this.templateDevName);

        List<clRouteScheduleSvc.EmailData> emails =  new List<clRouteScheduleSvc.EmailData>();
        clRouteScheduleSvc.EmailData data = new clRouteScheduleSvc.EmailData();

        data.templateId = emailTemplate.Id;
        data.dynamicHtml = this.buildEmailDynamicChildData(routeProcessingSheets);
        data.recordId = this.rsId;
        data.whoIds = getWhoIds();
        data.saveAsActivity = false;
        emails.add(data);

        return emails;
    }
    /**
     * @param routeProcessingSheets  a List of Route_Processing_Sheet__c sObjects
     * @return                       they dynamic html to inject into the email template.
     */
    private String buildEmailDynamicChildData(List<Route_Processing_Sheet__c> routeProcessingSheets) {

        String html = '';
        if(!routeProcessingSheets.isEmpty()) {
            // dynamically find the RPS fields to use based on Cash_Logistics_Survey_Setting__mdt
            Set<String> surveyFields = retrieveSurveyFields();
            if(surveyFields.isEmpty()) {
                System.debug(LoggingLevel.WARN,' No Fields have been configured for the RPS Survey. Check Survey Metadata!');
                return html;
            }
            Map<String, Schema.SObjectField> mFields = Schema.SObjectType.Route_Processing_Sheet__c.fields.getMap();

            for(Route_Processing_Sheet__c rps : routeProcessingSheets) {
                String accountDisplay = getAccountDisplayValue(rps);
                html += '<br/>';
                html += '<table border="0" cellpadding="2" cellspacing="1" width="100%">';
                html += '<tbody>';
                html += '<tr>';
                html += '<td colspan=2 bgcolor="#F3F2F2">';
                html += '  <span style="font-size:12px;">';
                //  https://accel-entertainment.monday.com/boards/942883797/pulses/3015869903?notification=2101617472
                String rpsRtModel =  rps.Redemption_Asset__r?.Model__c; //  <-- a guess on what model type means?

                html += '   <b>&nbsp;'+accountDisplay+'</b> '
                        + '&nbsp;-&nbsp;' + rps.Collection_Type__c
                        + '&nbsp;-&nbsp;' + rpsRtModel
                        + '&nbsp;-&nbsp;Total VGTs:&nbsp;' + rps.Total_Meter_Readings__c
                        + '&nbsp;-&nbsp;' + rps.Redemption_Type__c;

                if(rps.Redemption_Type__c == 'Cash Fill') {
                    html += '<br/>'
                            + 'Unused Return: '+rps.Cash_Return_Unused__c;
                }

                html += '  </span>';
                html += '</td>';
                html += '</tr>';

                Boolean hasValidSurveyFields = false;
                for (String surveyFieldApiName : surveyFields) {
                    Schema.SObjectField sObjectField = mFields.get(surveyFieldApiName);
                    //  Spit out the field label and field value.
                    Schema.DescribeFieldResult field = sObjectField.getDescribe();
                    Object oFieldValue = getFieldValue(field, rps);
                    if (!isFieldBlank(oFieldValue)) { // @see https://accel-entertainment.monday.com/boards/1300348967/pulses/2757155735
                        html += '<tr>';
                        html += '<td style="width:2%">&nbsp;</td>';
                        html += '<td style="width:98%"><span style="font-size:12px;"><i><u>' + field.getLabel() + '</u></i></span></td>';
                        html += '</tr>';
                        html += '<tr>';
                        html += '<td style="width:2%">&nbsp;</td>';
                        html += '<td style="width:98%"><span style="font-size:12px;">&nbsp;&nbsp;' + oFieldValue + '</span></td>';
                        html += '</tr>';
                        hasValidSurveyFields = true;
                    } else {
                       // html += '<tr><td colspan="2">TEST TEST FIELD DEFINED AS BLANK='+field.getLabel() + ' ... apiname='+ field.getName() + ' ... value='+oFieldValue + '</td></tr>';

                        //html += '<tr><td>&nbsp;</td></tr>'; //@see https://accel-entertainment.monday.com/boards/1300348967/pulses/2757155735
                    }
                }
                if(rps.Status__c == 'Skipped') {
                    html += '<tr><td colspan="2">Location was Skipped</td></tr>';
                }
                if(!hasValidSurveyFields) {
                    html += '<tr><td colspan="2">&nbsp;</td></tr>';
                }
                html += '</tbody>';
                html += '</table>';
            }
        }
        return html;
    }
    /**
     * @param oFieldValue The value of the notes or survey field
     * @return true if blank or '[Field left Blank]' assigned, otherwise false;
     * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/2757155735
     */
    public  Boolean isFieldBlank(Object oFieldValue) {
        Boolean isBlank = false;
        if(oFieldValue != null) {
            if(oFieldValue == NO_SURVEY_VALUE_DISPLAY){
                isBlank = true;
            }
        } else {
            isBlank = true;
        }
        return isBlank;
    }

    /**
     * Use the public group name as defined by the group dev name in Cash_Logistics_Automation_Setting__mdt and
     * find all the users in that public group to act as the whoIds for the email.
     *
     * @return a Set of User.Id values.
     *
     */
    @TestVisible
    private Set<Id> getWhoIds() {
        Id routeId = [SELECT Id,Route__c FROM Route_Schedule__c WHERE Id = :this.rsId]?.Route__c;
        Route__c route = [SELECT Id,Name,Processing_Location__c FROM Route__c WHERE  Id = :routeId];
        String region = route.Processing_Location__c.replaceAll(' ','_');
        this.regionMdt = (Cash_Logistics_Region__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Region__mdt.getSObjectType(),region);
        this.publicMdtDevNames = regionMdt.Rps_Email_Public_Group_Dev_Names__c.split(',');
        System.debug('----> group dev names='+this.publicMdtDevNames);
        List<User> groupUsers = retrievePublicGroupsUsersRecords(publicMdtDevNames);
        System.debug('---> groupUsers='+groupUsers);
        Set<Id> whoIds = new Set<Id>();
        for(User user : groupUsers) {
            whoIds.add(user.Id);
        }
        return whoIds;
    }

    /**
     * @return a Set containing Field Api Names to use in inject the dynamic html with.
     */
    public Set<String> retrieveSurveyFields() {
        Set<String> surveyFieldApiNames = new Set<String>();

        List<Cash_Logistics_Survey_Setting__mdt> mdts = CustomMetadataSvc.retrieveSurveyMetadatas(SURVEY_MDT_DEV_NAME);
        for(Cash_Logistics_Survey_Setting__mdt mdt : mdts) {
            surveyFieldApiNames.add(mdt.Field_Api_Name__c);
        }
        return surveyFieldApiNames;

    }

    /**
     * @param rps   A Route Processing sheet sObject.
     * @return      The value to display for account name.
     */
    private static String getAccountDisplayValue(Route_Processing_Sheet__c rps) {
        String accountDisplay = '';
        if(rps.Stop_Number__c != null) {
            accountDisplay = '('+rps.Stop_Number__c+') '+rps.Account__r.Name;
        } else {
            accountDisplay = rps.Account__r.Name;
        }
        return accountDisplay;
    }

    /**
     * @param field   A Describe field result.
     * @param rps     A Route_Processing_Sheet__c sObject.
     *
     * @return        The value of the field on the RPS sObject to use to inject in the email.
     */
    private static String getFieldValue(Schema.DescribeFieldResult field, Route_Processing_Sheet__c rps) {
        String sFieldValue;
        Object oFieldValue = rps.get(field.getName());
        sFieldValue = oFieldValue == null ? NO_SURVEY_VALUE_DISPLAY : oFieldValue.toString();
        String soapType = field.getSoapType().name();

        if(oFieldValue != null) {
            //  @todo other types?
            switch on soapType {
                when 'DATE' {
                    sFieldValue = ((Date) oFieldValue).format();
                }
            }
        }
        return sFieldValue;
    }

    public static List<User> retrievePublicGroupsUsersRecords(List<String> groupNames) {
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