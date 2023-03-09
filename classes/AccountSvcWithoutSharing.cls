public without sharing class AccountSvcWithoutSharing {

    public static Set<Id> retrieveVisibleAccountIds( Set<String> accountTypes, Integer iLimit, Id contactId ) {

        Map<Id, AccountContactRelation> mAccountsByIds = new Map<Id, AccountContactRelation>([
                SELECT  Id,AccountId, Account.Type, Account.ParentId, Account.HQ_Account__c
                FROM    AccountContactRelation
                WHERE   Account.Type IN :accountTypes
                AND     ContactId = :contactId
                LIMIT  :iLimit
        ]);
        System.debug('--- acrs:'+mAccountsByIds);
        Set<Id> accountIds = new Set<Id>();
        Set<Id> validParentIds = new Set<Id>();

        for(AccountContactRelation acr : mAccountsByIds.values()) {
            accountIds.add(acr.AccountId);
            //&& acr.Account.HQ_Account__c ==true
            if(acr.Account.ParentId != null ) {
                validParentIds.add(acr.AccountId);
            }
        }
        Map<Id,Account> maccountsWithHqParents = new Map<Id,Account>([
                SELECT Id
                FROM   Account
                WHERE  ParentId IN :validParentIds
        ]);
        System.debug('--- account with parents:'+maccountsWithHqParents);

        if(!maccountsWithHqParents.isEmpty()) {
            accountIds.addAll(maccountsWithHqParents.keySet());
        }

        return accountIds;
    }
}