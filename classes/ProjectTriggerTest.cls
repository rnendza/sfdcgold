@isTest
private class ProjectTriggerTest {

    static final String OPPTY_NAME = 'TEST_CLASS_PROJECT';
    static final String PRODUCT_NAME = 'Test Product';
    static final STring TEST_RM_REGION = 'Lincoln';
    
    @isTest static void testCreateProjectLines() {
        User u = new User(
                             ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
                             LastName = 'last',
                             Email = 'puser000@amamama.com',
                             Username = 'puser000@amamama.com' + System.currentTimeMillis(),
                             CompanyName = 'TEST',
                             Title = 'title',
                             Alias = 'alias',
                             TimeZoneSidKey = 'America/Los_Angeles',
                             EmailEncodingKey = 'UTF-8',
                             LanguageLocaleKey = 'en_US',
                             LocaleSidKey = 'en_US'
                        );
        insert u;

        Account acc = new Account();
        acc.Name = 'Test Account';

        //--- RJN Added RM_Region__c 3/5/2020.. not sure of business reason but it appears to be needed to prevent the following
        //---18:29:58:880 FLOW_ELEMENT_ERROR The flow failed to access the value for myVariable_current.Account__r.RM_Region__c
        // because it hasn't been set or assigned.|FlowDecision|myDecision2. This test class is not currently failing
        // in UAT but is failing in prod (there are some version differences in things being kicked off)
        acc.RM_Region__c = TEST_RM_REGION;
        insert acc;

        Opportunity oppty = new Opportunity();
        oppty.Name = OPPTY_NAME;
        oppty.Pricebook2Id = Test.getStandardPricebookId();
        oppty.StageName = 'New';
        oppty.CloseDate = System.today();
        oppty.AccountId = acc.Id;
        insert oppty;

        Product2 product = new Product2();
        product.Name = PRODUCT_NAME;
        product.Manufacturer__c = acc.Id;
        insert product;

        PricebookEntry pricebookEntry = new PricebookEntry();
        pricebookEntry.Product2Id = product.Id;
        pricebookEntry.UnitPrice = 0;
        pricebookEntry.Pricebook2Id = Test.getStandardPricebookId();
        pricebookEntry.IsActive = true;
        insert pricebookEntry;

        OpportunityLineItem opptyLine = new OpportunityLineItem();
        opptyLine.Quantity = 2;
        opptyLine.Product2Id = product.Id;
        opptyLine.OpportunityId = oppty.Id;
        insert opptyLine;

        Id organicRtId = SObjectType.Project__c.getRecordTypeInfosByDeveloperName().get('Organic').getRecordTypeId();
        Project__c project = new Project__c();
        project.Name = oppty.Name;
        project.Opportunity__c = oppty.Id;
        project.Account__c = acc.id;
        //RJN Added record type to conform to stuff added onto project since this trigger was last maintained by Penrod
        project.RecordTypeId = organicRtId;


        Test.startTest();

        insert project;
        update project;
        Test.stopTest();

        List<Project_Line__c> projectLines = [SELECT Id, Name FROM Project_Line__c WHERE Project__c = :project.Id];
        System.assertEquals(1, projectLines.size());
        //System.assertEquals(OPPTY_NAME + ' ' + PRODUCT_NAME, projectLines[0].Name);
        System.assertEquals(PRODUCT_NAME, projectLines[0].Name);
    }

}