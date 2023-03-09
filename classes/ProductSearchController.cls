public with sharing class ProductSearchController {

  private static final List<String> FAMILY_VALUES = new List<String> {'ASSET','GENERALPART','GAMEPART','KIT COMPON','CONSUMABLE','REDEMPT','LOCKS'};

    @AuraEnabled
    public static List<Project_Line__c> getProjectLineItems(String recordId) {
        List<Project_Line__c> projectLineItems = [SELECT Id,
                                                         Name,
                                                         Project__c,
                                                         Product__c,
                                                         Product__r.Name,
                                                         Quantity__c,
                                                         Service_Date__c,
                                                         Description__c
                                                  FROM Project_Line__c
                                                  WHERE Project__c = :recordId];
        return projectLineItems;
    }

    @AuraEnabled
    public static String saveProjectLines(List<Project_Line__c> projectLines, String projectId) {
        List<Project_Line__c> projectLinesForUpdate = new List<Project_Line__c>();
        List<Project_Line__c> projectLinesForInsert = new List<Project_Line__c>();
        List<Project_Line__c> projectLinesForDelete = new List<Project_Line__c>();
        Set<Id> productIds = new Set<Id>();
        
        for(Project_Line__c projectLine : projectLines) {
            projectLine = projectLine.clone(false,false);
            if(projectLine.Project__c == null) {
                productIds.add(projectLine.Product__c);
                projectLine.Project__c = projectId;
                projectLinesForInsert.add(projectLine);
            } else {
                projectLinesForUpdate.add(projectLine);
            }
        }

        // Apply a name to the new project line
        String projectName = [SELECT Name FROM Project__c WHERE Id = :projectId].Name;
        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Id,
                                                                   Name
                                                            FROM Product2
                                                            WHERE Id IN :productIds]);
        for(Project_Line__c projectLine : projectLinesForInsert) {
            //rjn removed.   projectLine.Name = projectName + ' '
            projectLine.Name = products.get(projectLine.Product__c).Name;
        }
        insert projectLinesForInsert;
        //update projectLinesForUpdate;

        /*Map<Id, Project_Line__c> projectLineIdsToProjectLines = new Map<Id, Project_Line__c>(projectLinesForUpdate);
        for(Project_Line__c projectLine : [SELECT Id,
                                                  Name,
                                                  Project__c,
                                                  Product__c,
                                                  Product__r.Name,
                                                  Quantity__c,
                                                  Service_Date__c,
                                                  Description__c
                                           FROM Project_Line__c
                                           WHERE Project__c = :recordId]) {
            if(!projectLineIdsToProjectLines.containsKey(projectLine.Id)) {
                projectLinesForDelete.add(projectLine);
            }
        }
        delete projectLinesForDelete;*/

        return 'SUCCESS';
    }

    @AuraEnabled
    public static ProductTableResponse getProducts(String searchString, Integer queryOffset) {              
        ProductTableResponse response = new ProductTableResponse();

        searchString = '%' + searchString + '%';

        // Apparently this is necessary because errors are thrown without it
        queryOffset = Integer.valueOf(queryOffset);
        
        List<Product2> products = [SELECT Id,
                                          Name,
                                          ProductCode,
                                          Description,
                                          Family,
                                          (SELECT Id,
                                                  UnitPrice
                                           FROM PricebookEntries
                                           WHERE Pricebook2.IsStandard = true
                                           LIMIT 1)
                                   FROM Product2
                                   WHERE Name LIKE :searchString                                  
                                   AND Family IN :FAMILY_VALUES
                                   ORDER BY Name ASC
                                   LIMIT 20
                                   OFFSET :queryOffset];
        
        Map<String, PricebookEntry> productIdToPBEs = new Map<String, PricebookEntry>();
        for(Product2 product : products) {
            if(product.PricebookEntries.size() > 0) {
                productIdToPBEs.put(product.Id, product.PricebookEntries[0]);
            }
        }

        response.productData = products;
        response.priceData = productIdToPBEs;

        return response;
    }
    
    public class ProductTableResponse {
        @AuraEnabled
        public List<Product2> productData {get;set;}
        @AuraEnabled
        public Map<String, PricebookEntry> priceData {get;set;}
        
        public ProductTableResponse(){
            productData = new List<Product2>();
            priceData = new Map<String, PricebookEntry>();
        }
    }
}