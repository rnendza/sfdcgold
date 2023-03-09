/**
 * Created by ZacharyM on 3/14/2019.
 */

public with sharing class Accel_CommunityFilesController {
    public static final String MAP_KEY_ACCOUNT_LIST             = 'ACCOUNT_LIST';

    @AuraEnabled
    public static List<ContentDocument> getRevenueFiles(Id id, String startDate, String endDate){
        Date sstartDate = date.valueOf(startDate);
        Date eendDate = date.valueOf(endDate);
        List<ContentDocumentLink> fileLinks;
        List<Id> files = new List<Id>();
        List<ContentDocument> fileList;
        List<ContentDocument> finalFiles = new List<ContentDocument>();
        fileLinks = [Select ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId = :id and  contentdocument.title like 'Rev_2%' order by contentdocument.title DESC];
        for(ContentDocumentLink c : fileLinks){
            files.add(c.contentdocumentid);
        }
        Set<Id> fileSet= new Set<Id>(files);
        fileList = [select id, title from ContentDocument where id in :fileSet order by title DESC];
        for(ContentDocument cd : fileList){
            String startDateString = cd.title.substring(4,14).replace('.', '-')+' 00:00:00';
            String endDateString = cd.title.substring(17,27).replace('.', '-') +' 00:00:00';
            Date dstart = date.valueOf(startDateString);
            Date dend = date.valueOf(endDateString);
            if(dstart >= sstartDate && dend <= eendDate){
                finalFiles.add(cd);
            }
        }

        return finalFiles;

    }
    /**
     * This is a rewrite of the commented out method below (9/8/2021).
     *
     * Not really happy about this solution as we should have a flag on ContentVersion
     * but since this is an external integration. it's probably safer to do it this way.
     * We are merely filtering on a set description here.
     *
     * @todo refine external feeds
     * @todo Accel needs better classification of community files. ie. libraries / fields
     *       denoting community specific etc.
     *
     * @return a List of ContentDocumentLink sObjects if found / otherwise null
     */
    @AuraEnabled
    public static List<ContentDocumentLink> getOtherFiles(){

        //  Get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);

        //  Get content document links.
        Map<Id, ContentDocumentLink> mDocLinks = new Map<Id, ContentDocumentLink>([
                SELECT  ContentDocumentId,LinkedEntityId
                FROM    ContentDocumentLink
                WHERE   linkedentityid in :mAccountsByIds.keySet()
                AND     contentdocument.description like 'Analytics_%'
                AND     Contentdocument.Description != 'Analytics_Accel Location Summary'
                ORDER BY contentdocument.title DESC
        ]);
        return mDocLinks.values();
    }


//    @AuraEnabled
//    public static List<ContentDocumentLink> getOtherFiles(){
//        List<ContentDocumentLink> files;
//
//        //get accounts visible to the user.
//         Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
//
//        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
//
//
//            files = [Select ContentDocumentId, LinkedEntityId from ContentDocumentLink where linkedentityid in
//                    :visibleAccountIds  and contentdocument.description like 'Analytics_%' order by contentdocument.title DESC];
//
//        return files;
//    }

    @AuraEnabled
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();

        //@TODO Merge the below into 1 call!
        Integer iLimit = 30;
        String settingName = 'Application_Search_Limits';
        String fieldName = 'Max_Account_Results__c';
        Object oMaxAccounts = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName, fieldName);
        if (oMaxAccounts != null) {
            iLimit = ((Decimal) oMaxAccounts).intValue();
        }

        //@todo deprecate Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(accountTypes, iLimit);
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccountsIncludingHq( accountTypes, 100);

        List<Account> filteredAccounts = new List<Account>();
        for (Account account : mAccountsByIds.values()) {
                filteredAccounts.add(account);
        }
        dto.values.put(MAP_KEY_ACCOUNT_LIST, filteredAccounts);
        dto.isSuccess = true;
        return dto;
    }
}