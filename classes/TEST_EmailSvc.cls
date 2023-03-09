@IsTest
private class TEST_EmailSvc {

    private static String DEFAULT_OWA_EMAIL_ADDRESS = 'crm@accelentertainment.com';

    @TestSetup
    static void setup() {
        Test.startTest();
        User adminUser = TestUtils.getUserForTest('accelunittestblah@accelentertainment.com');
        Test.stopTest();
    }

    @IsTest
    static void test_sendEmail() {
        OrgWideEmailAddress owa = [SELECT Id,Address FROM OrgWideEmailAddress WHERE Address = :DEFAULT_OWA_EMAIL_ADDRESS];

        System.runAs( new User(Id=UserInfo.getUserId())) {
            Test.startTest();

            EmailSvc.sendEmail(new List<String>{'test@test.com'},'subj','body');
            EmailSvc.sendEmail(new List<String>{'test@test.com'},'replyto@test.com','subj','body');
            EmailSvc.sendEmail(new List<String>{'test@test.com'},'replyto@test.com','subj','body',null,owa.Address);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_getHpdEmailNotificationAddys() {

        System.runAs( new User(Id=UserInfo.getUserId())) {
            Test.startTest();

            EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ACCT_AGGREGATION_DEVNAME);

            Test.stopTest();
        }
    }

    @IsTest
    static void test_sendEmailEmailTemplate_positive() {
        Accel_Application_Error__c ae = new Accel_Application_Error__c();
        insert ae;

        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :BatchjobSvc.DEFAULT_EMAIL_TEMPLATE];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        System.runAs( new User(Id=UserInfo.getUserId())) {
            Test.startTest();

            Set<Id> whoIds = new Set<Id> {UserInfo.getUserId()};
            Id whatId = ae.id;
            List<Messaging.SendEmailResult> results1 = EmailSvc.sendEmailTemplate(whoIds,whatId,template.Id,null,owa.Address);
            for(Messaging.SendEmailResult result : results1) {
                System.assert(result.isSuccess());
            }

            List<Messaging.SendEmailResult> results2 = EmailSvc.sendEmailTemplate(whoIds,whatId,template.Id,null,null);
            for(Messaging.SendEmailResult result : results2) {
                System.assert(result.isSuccess());
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void test_sendEmailEmailTemplate_WithDynaHtml() {
        Accel_Application_Error__c ae = new Accel_Application_Error__c();
        insert ae;

        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :BatchjobSvc.DEFAULT_EMAIL_TEMPLATE];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        System.runAs( new User(Id=UserInfo.getUserId())) {
            Test.startTest();

            Set<Id> whoIds = new Set<Id> {UserInfo.getUserId()};
            Id whatId = ae.id;
            String dynaHtml = '<b>TEST DYNA HTML</b>';
            List<Messaging.SendEmailResult> results = EmailSvc.sendEmailTemplate(whoIds,whatId,template.Id,dynaHtml,null,owa.Address,false,false,false);
            for(Messaging.SendEmailResult result : results) {
                System.assert(result.isSuccess());
            }

            Test.stopTest();
        }
    }

    @IsTest
    static void test_sendEmailEmailTemplates_Bulk_WithDynaHtml() {

        List<Accel_Application_Error__c> logs = new List<Accel_Application_Error__c>();
        for(Integer i=0; i<20; i++) {
            logs.add(new Accel_Application_Error__c());
        }
        insert logs;

        OrgWideEmailAddress owa = EmailSvc.retrieveOwa(DEFAULT_OWA_EMAIL_ADDRESS);
        EmailTemplate template = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :BatchjobSvc.DEFAULT_EMAIL_TEMPLATE];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        System.runAs( new User(Id=UserInfo.getUserId())) {

            List<BulkEmailPayload> payloads = new List<BulkEmailPayload>();

            Set<Id> whoIds = new Set<Id> {UserInfo.getUserId()};

            Integer i = 0;
            for(Accel_Application_Error__c log: logs) {
                BulkEmailPayload payload = new BulkEmailPayload();
                payload.whatId = log.id;
                payload.whoIds = whoIds;
                payload.templateId = template.Id;
                payload.dynamicHtml =  i+'<b>TEST DYNA HTML</b>';
                payload.owaEmailAddy = owa.Address;
                payload.replyTo = null;
                payload.setBccSender = false;
                payload.setSaveAsActivity = false;
                payload.useSignature = false;
                payloads.add(payload);
                i++;
            }
            Test.startTest();

            List<Messaging.SendEmailResult> results = EmailSvc.sendEmailTemplates(payloads);
            for (Messaging.SendEmailResult result : results) {
                System.assert(result.isSuccess());
            }

            Test.stopTest();
        }
    }


    @IsTest
    static void test_sendEmailEmailTemplate_badtemplate() {
        Accel_Application_Error__c ae = new Accel_Application_Error__c();
        insert ae;

        EmailTemplate template = [SELECT Id,DeveloperName FROM EmailTemplate WHERE DeveloperName = :BatchjobSvc.DEFAULT_EMAIL_TEMPLATE];
        template = EmailSvc.retrieveEmailTemplate(template.DeveloperName);

        template.HtmlValue = 'hello im screwing this up.. {{{BogusObjectName.BogusFieldName}}}';
        update template;

        System.runAs( new User(Id=UserInfo.getUserId())) {
            Test.startTest();

            Set<Id> whoIds = new Set<Id> {UserInfo.getUserId()};
            Id whatId = ae.id;
            List<Messaging.SendEmailResult> results = EmailSvc.sendEmailTemplate(whoIds,whatId,template.Id,null,null);
            System.assert(results == null);

            Test.stopTest();
        }
    }


    @IsTest
    static void test_retrievePublicGroupUsers() {

        User adminUser = TestUtils.getUserForTest('accelunittestblah@accelentertainment.com');

        Group gp            = new Group();
        gp.Name             = 'Test Public Group';
        gp.DeveloperName    = 'Test_Public_Group';
        gp.Type             = 'Regular';
        insert gp;

        GroupMember gpMember = new GroupMember();
        gpMember.UserOrGroupId = adminUser.Id;
        gpMember.GroupId = gp.Id;
        insert gpMember;

        System.runAs( adminUser ) {
            Test.startTest();
            System.assert(!EmailSvc.retrievePublicGroupUsers(gp.DeveloperName).isEmpty());
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrievePublicGroupsUsers() {

        User adminUser = TestUtils.getUserForTest('accelunittestblah@accelentertainment.com');

        Group gp1 = new Group(Name = 'Test Public Group1', DeveloperName = 'Test_Public_Group1', Type = 'Regular');
        Group gp2 = new Group(Name = 'Test Public Group2', DeveloperName = 'Test_Public_Group2', Type = 'Regular');
        List<Group> groups = new List<Group> {gp1,gp2};
        insert groups;

        List<GroupMember> gpMembers = new List<GroupMember>();
        for(Group gp : groups) {
            gpMembers.add(new GroupMember(UserOrGroupId = adminUser.Id, GroupId = gp.Id));
        }
        insert gpMembers;
        Set<Id> groupIds = new Set<Id>();
        for(Group gp : groups) {
            groupIds.add(gp.Id);
        }

        System.runAs( adminUser ) {
            Test.startTest();
            System.assert(!EmailSvc.retrievePublicGroupsUsers(groupIds).isEmpty());
            Test.stopTest();
        }
    }
}