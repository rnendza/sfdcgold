public with sharing class POCDumpAllMonthliesController {

    @AuraEnabled(Cacheable=true)
    public static List<Hold_Per_Day__c> retrieveAllMonthliesForAccounts(Id contactId) {
        Set<Id> accountIds =
                AccountSvcWithoutSharing.retrieveVisibleAccountIds(
                        CustomMetaDataSvc.retrieveCommunityAccountTypes(), 5000, contactId);

        return ContactSvc.retrieveAllMonthliesForAccounts(accountIds);
    }
}