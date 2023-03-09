/**
 * Business Logic intended to back Opportunity Triggers.
 */
public with sharing class OppTriggerHandler {

    /**
     * Handles the insert or update of an Opp.
     * 1. If Insert. Checks to see if Opp.Patrons_Under_21_Allowed_to_Enter__c is populated if so updates the parent account.
     * 2. If Update. Checks to see if Opp.Patrons_Under_21_Allowed_to_Enter__c changed, if so update the parent account.
     *
     * @param oldOppMap     Trigger.Old if an update / otherwise null.
     * @param newOppMap     Trigger.New for an update or insert.
     *
     * @return a List of Updated Accounts if any.
     */
    public static List<Account> updateLocationUnder21(Map<Id, Opportunity> oldOppMap, Map<Id, Opportunity> newOppMap) {
        List<Account> updatedAccounts = new List<Account>();
        Map<Id, Opportunity> mOpportunitiesByIds = new Map<Id, Opportunity>();
        if (oldOppMap != null && !oldOppMap.isEmpty()) {
            //----This is an Update of an Opportunity.   See if the field was modified.
            for (Opportunity newOpp : newOppMap.values()) {
                Opportunity oldOpp = oldOppMap.get(newOpp.id);
                if (newOpp.Patrons_Under_21_Allowed_to_Enter__c != oldOpp.Patrons_Under_21_Allowed_to_Enter__c) {
                    mOpportunitiesByIds.put(newOpp.id, newOpp);
                }
            }
            if (!mOpportunitiesByIds.isEmpty()) {
                updatedAccounts = evalLocationUnder21(mOpportunitiesByIds);
            }
            //----- This is an insert of an Opportunity.
        } else {
            updatedAccounts = evalLocationUnder21(newOppMap);
        }
        return updatedAccounts;
    }
    /**
     *
     * @param mOpportunitiesByIds -  A Map of Opp Id ==> Opp
     *
     * @return a List of Updated Accounts if any.
     */
    @TestVisible
    private static List<Account> evalLocationUnder21(Map<Id, Opportunity> mOpportunitiesByIds) {
        List<Account> updatedAccounts = new List<Account>();
        Map<Id, Opportunity> mAccountId_Opp = new Map<Id, Opportunity> ();
        for (Opportunity newOpp : mOpportunitiesByIds.values()) {
            if (newOpp.AccountId != null && newOpp.Patrons_Under_21_Allowed_to_Enter__c != null) {
                mAccountId_Opp.put(newOpp.AccountId, newOpp);
            }
        }
        if (!mAccountId_Opp.isEmpty()) {
            updatedAccounts = updateLocationUnder21(mAccountId_Opp);
        }
        return updatedAccounts;
    }
    /**
     *
     *
     * @param mAccountId_Opp
     *
     * @return
     */
    public static List<Account> updateLocationUnder21(Map<Id, Opportunity> mAccountId_Opp) {
        List<Account> updatedAccounts = new List<Account>();
        List<Account> accounts = [
                SELECT Id, Patrons_Under_21_Allowed_to_Enter__c
                FROM Account
                WHERE Id IN :mAccountId_Opp.keySet()
        ];
        if (!accounts.isEmpty()) {
            for (Account account : accounts) {
                Opportunity opp = mAccountId_Opp.get(account.id);
                account.Patrons_Under_21_Allowed_to_Enter__c = opp.Patrons_Under_21_Allowed_to_Enter__c;
            }
            update accounts;
        }
        return accounts;
    }
}