@isTest
private class ProductSearchControllerTest {
    private static final String PROJ_NAME = 'Test Project';
    private static final String PROJ_LINE_NAME = 'Test Project Line';
    private static final String PROJ_LINE_NAME_2 = 'Test Project Line 2';
    private static final String PROJ_LINE_NAME_3 = 'Test Project Line 3';
    private static final String ACC_NAME = 'Test Account';
    private static final String PRODUCT_NAME = 'Test Product';
    private static final String OPP_NAME = 'Test Opportunity';
    private static final String PRICEBOOK_NAME = 'Test Pricebook';
    private static final String PRICEBOOK_ENTRY_NAME = 'Test Pricebook Entry Name';

    @testSetup static void setup() {

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
        acc.Name = ACC_NAME;
        //acc.Assigned_RM__c = u.Id;
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Name = OPP_NAME;
        opp.AccountId = acc.Id;
        opp.StageName = 'New';
        opp.CloseDate = system.today().addDays(7);
        insert opp;

        Project__c proj = new Project__c();
        proj.Name = PROJ_NAME;
        proj.Account__c = acc.Id;
        proj.Opportunity__c = opp.Id;
        insert proj;

        Product2 product = new Product2();
        product.Name = PRODUCT_NAME;
        product.Family = 'GAMEPART';
        product.Manufacturer__c = acc.Id;
        insert product;

        //PriceBook2 pricebook = new PriceBook2();
        //pricebook.Name = PRICEBOOK_NAME;
        //insert pricebook;

        PricebookEntry pricebookEntry = new PricebookEntry();
        pricebookEntry.Product2Id = product.Id;
        pricebookEntry.UnitPrice = 0;
        pricebookEntry.Pricebook2Id = Test.getStandardPricebookId();
        //pricebookEntry.UseStandardPrice = true;
        insert pricebookEntry;

        Project_Line__c projLine = new Project_Line__c();
        ProjLine.Name = PROJ_LINE_NAME;
        ProjLine.Project__c = proj.Id;
        ProjLine.Product__c = product.Id;
        insert ProjLine;
    }
    
    @isTest static void test_getProjectLineItems_Insert() {
        Project__c proj = [SELECT Id FROM Project__c LIMIT 1];
        //system.debug(proj.Id);

        Test.startTest();
        List<Project_Line__c> projectLineItems = ProductSearchController.getProjectLineItems(proj.Id);
        Test.stopTest();

        system.assertEquals(1, projectLineItems.size());
    }
    
    @isTest static void test_saveProjectLines_Insert() {
        Project__c project = [SELECT Id, Name FROM Project__c LIMIT 1];
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];

        List<Project_Line__c> projectLines = new List<Project_Line__c>();
        projectLines.add(new Project_Line__c(
                Name = PROJ_LINE_NAME_2,
                Product__c = product.Id
            ));
        projectLines.add(new Project_Line__c(
                Name = PROJ_LINE_NAME_3,
                Product__c = product.Id
            ));

        Test.startTest();
        String result = ProductSearchController.saveProjectLines(projectLines, project.Id);
        Test.stopTest();

        system.assertEquals('SUCCESS',result);

        // rjn removed String expectedProjectLineName = project.Name + ' ' + product.Name;
        String expectedProjectLineName = product.Name;
        List<Project_Line__c> projectLinesResults = [SELECT Project__c, Id, Name
                                                    FROM Project_Line__c
                                                    WHERE Name = :expectedProjectLineName];

        system.assertEquals(2, projectLinesResults.size());                                                 
    }

    @isTest static void test_getProducts_Insert() {
        Product2 product = [SELECT Id, Name FROM Product2 LIMIT 1];
        String searchString = PRODUCT_NAME;
        Integer queryOffset = 0;

        //CREATE PRICEBOOK ENTRY


        system.debug(product);
        system.debug(product.Name);

        Test.startTest();
        ProductSearchController.ProductTableResponse result = ProductSearchController.getProducts(searchString, queryOffset);
        system.debug(result);
        system.debug(result.productData);
        //system.debug(result.productData);

        Test.stopTest();

        system.assertEquals(product.Name, result.productData[0].Name);

    }
    
}