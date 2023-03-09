global with sharing class BatchFixAccountMostRecentHpd implements Database.Batchable<Sobject>, Database.Stateful {
    public String rtName    {get;set;}
    public Date   hpdDate   {get;set;}

    global BatchFixAccountMostRecentHpd(String pRtName, Date pHpdDate) {
        this.rtName     = pRtName;
        this.hpdDate    = pHpdDate;
    }
    global database.querylocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
                SELECT  Id,Account__c
                FROM    Hold_Per_Day__c
                WHERE   RecordType.name = :rtName
                AND     Date__c         = :hpdDate
        ]);
    }
    global void execute(Database.BatchableContext bc, List<Hold_Per_Day__c> scope) {
        if(!scope.isEmpty()) {
            List<Account> accountsToUpd = new List<Account>();
            Map<Id,Hold_Per_Day__c> mAccountId_Hpd = new Map<Id,Hold_Per_Day__c>();
            for(Hold_Per_Day__c hpd : scope) {
                mAccountId_Hpd.put(hpd.Account__c,hpd);
            }
            Map<Id,Account> mAccountsByIds = new Map<Id,Account> ([
                    SELECT  Id, Most_Recent_Hold_Per_Day__c
                    FROM    Account
                    WHERE   Id IN :mAccountId_Hpd.keySet()
            ]);
            for(Account account : mAccountsByIds.values()) {
                account.Most_Recent_Hold_Per_Day__c = ((Hold_Per_Day__c)mAccountId_Hpd.get(account.id)).id;
                accountsToUpd.add(account);
            }
            update accountsToUpd;
        }
    }
     global void finish(Database.BatchableContext bc) {}
}