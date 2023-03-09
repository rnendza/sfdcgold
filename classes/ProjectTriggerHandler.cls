public with sharing class ProjectTriggerHandler {
    public static void createProjectLines(List<Project__c> projects) {
        createProjectLines(projects, null);
    }

    public static void createProjectLines(List<Project__c> projects, Map<Id, Project__c> oldMap) {
        Set<Id> opptyIds = new Set<Id>();
        Map<Id, Project__c> projectsNeedingLines = new Map<Id, Project__c>();
        for(Project__c project : projects) {
            if(project.Opportunity__c != null) {
                if(oldMap == null || oldMap.get(project.Id).Opportunity__c != project.Opportunity__c) {
                    opptyIds.add(project.Opportunity__c);
                    projectsNeedingLines.put(project.Id, project);
                }
            }
        }

        Map<Id, Opportunity> opptyIdToOpptyWithLines = new Map<Id, Opportunity>([SELECT Id,
                                                                                       (SELECT Id,
                                                                                               Description,
                                                                                               Product2Id,
                                                                                               Quantity
                                                                                        FROM OpportunityLineItems)
                                                                                 FROM Opportunity
                                                                                 WHERE Id IN :opptyIds]);

        List<Project_Line__c> projectLines = new List<Project_Line__c>();
        Set<Id> productIds = new Set<Id>();
        for(Project__c project : projectsNeedingLines.values()) {
            Opportunity oppty = opptyIdToOpptyWithLines.get(project.Opportunity__c);
            for(OpportunityLineItem opptyLine : oppty.OpportunityLineItems) {
                Project_Line__c projectLine = new Project_Line__c();
                projectLine.Description__c = opptyLine.Description;
                projectLine.Product__c = opptyLine.Product2Id;
                projectLine.Quantity__c = opptyLine.Quantity;
                projectLine.Project__c = project.Id;
                projectLines.add(projectLine);

                productIds.add(opptyLine.Product2Id);
            }
        }

        Map<Id, Product2> products = new Map<Id, Product2>([SELECT Id,
                                                                   Name
                                                            FROM Product2
                                                            WHERE Id IN : productIds]);
        for(Project_Line__c projectLine : projectLines) {
            Product2 product = products.get(projectLine.Product__c);
            Project__c project = projectsNeedingLines.get(projectLine.Project__c);
           // projectLine.Name = project.Name + ' ' + product.Name;
            projectLine.Name = product.Name;
        }

        insert projectLines;
    }
}