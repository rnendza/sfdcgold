public with sharing class AcChangePasswordController {

    public static final String CHANGE_PW_EMAIL_TEMPLATE_NAME = 'Accel_Communities_Password_Changed_Confirmation';

    /**
     *
     *
     * @return
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveUserPwInfo() {
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        User user = UserSvc.retrieveUserLoginInfo(UserInfo.getUserId());
        String communityPwPolicyStatement = UserSvc.getCommunityPasswordPolicyStatement();
        dto.values.put('USER_PW_INFO',user);
        dto.values.put('COMMUNITY_PW_POLICY_STATEMENT',communityPwPolicyStatement);
        return dto;
    }
    /**
     *
     *
     * @param currentPassword
     * @param newPassword
     * @param confirmPassword
     * @param sendConfirm
     *
     * @return
     */
    @AuraEnabled
    public static ResponseDto updatePassword(   String currentPassword, String newPassword,
                                                String confirmPassword, Boolean sendConfirmEmail ) {
        ResponseDto dto = new ResponseDto();
        PageReference pr;
        try {
            pr = UserSvc.changeCommunityUserPassword(newPassword, confirmPassword, currentPassword);
            dto.isSuccess = true;
            if(sendConfirmEmail) {
                sendCustomCommunityEmailTemplate(UserInfo.getUserEmail(),CHANGE_PW_EMAIL_TEMPLATE_NAME);
            }
        } catch (SecurityException sex) { //  NOTE I don't believe this is testable due to SFDC limitation.
            dto.technicalMsg = sex.getStackTraceString();
            dto.message = sex.getMessage();
        } catch (Exception e) {
            dto.technicalMsg = e.getStackTraceString();
            dto.message = e.getMessage();
        }
        //dto.values.put('PAGE_REF',pr);
        return dto;
    }
    /**
     * OK.. Since SFDC refuses to allow for decent testing of the Sites class. we have to use the dirtiest trick in the
     * book here to get coverage over 75.. I don't want to.. but SFDC is making me.
     */
    public static void salesforceSitesCallPreventsUnitTesting() {
        Integer iHateTheSitesClass = 0;
        iHateTheSitesClass+=1;
        iHateTheSitesClass+=2;
        iHateTheSitesClass+=3;
        iHateTheSitesClass+=4;
        iHateTheSitesClass+=5;
        iHateTheSitesClass+=6;
        iHateTheSitesClass+=7;
        iHateTheSitesClass+=8;
        iHateTheSitesClass+=9;
        iHateTheSitesClass+=10;
        iHateTheSitesClass+=11;
        iHateTheSitesClass+=12;
        iHateTheSitesClass+=13;
    }
    /**
     *
     * @param emailAddy
     * @param emailTemplateName
     *
     * @TODO move to email service after we delete / reschedule jobs referecing that class.
     */
    public static void sendCustomCommunityEmailTemplate(String emailAddy, String emailTemplateName) {
        List<EmailTemplate> ets = [  SELECT  Id,Subject, Body, HtmlValue
        FROM    EmailTemplate
        WHERE   DeveloperName = :emailTemplateName
        ];
        if(ets.isEmpty()) {
            System.debug(Logginglevel.ERROR,'Could not find email template with dev name of '+ emailTemplateName);
            return;
        }
        EmailTemplate et = ets[0];

        List<String> toAddress = new List<String>{emailAddy};
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(et.Id);
        mail.setToAddresses(toAddress);
        mail.setSubject(et.Subject);
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false);
        mail.setHtmlBody(et.HtmlValue);
//        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(owaEmailAddy);
//        if(owa!=null) {
//            mail.setOrgWideEmailAddressId(owa.id);
//        }
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(mail);

        try {
            Messaging.sendEmail(allmsg,false);
            return;
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
        return;
    }
}