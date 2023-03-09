public with sharing class CustomLookUpController {
    @AuraEnabled
    public static List<sObject> fetchRecentlyViewed(String objectName) {
        List<sObject> returnList = new List <sObject>();

        String realObjectName = String.escapeSingleQuotes(objectName);
        String soql = 'SELECT Id, Name FROM RecentlyViewed  WHERE Type :realObjectName ORDER BY LastViewedDate DESC';
        try {
            List <sObject> lstOfRecords = Database.query(soql);
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
        } catch (Exception e) {
            throw new AuraHandledException('That didn\'n work:'+soql+'\n'+e.getMessage());
        }
        return returnList;
    }
    @AuraEnabled
    public static List<sObject> fetchLookUpValues(String searchKeyWord, String objectName) {
        String fieldsToReturn = 'id, Name';
        return CustomLookUpController.fetchExtendedLookUpValues(searchKeyWord, objectName, fieldsToReturn);
    }

    @AuraEnabled
    public static List<sObject> fetchExtendedLookUpValues(String searchKeyWord, String objectName,String fieldsToQuery) {
        String realObjectName = String.escapeSingleQuotes(objectName);
        String realFieldsToQuery = String.escapeSingleQuotes(fieldsToQuery);
        String searchKey = searchKeyWord + '%';

        List<sObject> returnList = new List <sObject>();

        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5
        String sQuery =  'select '+  realFieldsToQuery +' from ' + realObjectName +
                ' where Name LIKE :searchKey order by createdDate DESC limit 10';

        try {
            List <sObject> lstOfRecords = Database.query(sQuery);
            for (sObject obj: lstOfRecords) {
                returnList.add(obj);
            }
        } catch (Exception e) {
            throw new AuraHandledException('That didn\'n work:'+sQuery+'\n'+e.getMessage());
        }
        return returnList;
    }
}