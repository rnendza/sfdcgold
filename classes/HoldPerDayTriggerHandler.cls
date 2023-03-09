/**
 * Contains business logic backing Hold_Per_Day__c
 */
public class HoldPerDayTriggerHandler {
//    // @deprecated replace with BatchHpdMonthlyImport for CPU Timeout issues.

        public static List<Account> updateAccountMostRecentHPD(List<Hold_Per_Day__c> newHoldPerDays) {
            Integer i = 1; //only here so we can deploy
            return null;
        }


//    /**
//     * Update the account associated with the inserted hold per day. Updates Account.Most_Recent_Hold_Per_Day.
//     * We need to go through some hoops to sort as this could be batch and we can't rely on the ordering of the
//     * records in the batch.
//     *
//     * 1. Get the Monthly Hpd Record Type.
//     * 2. Created a Map of AccountId => List<HpdWrapper>.
//     * 3. Sort the List<HpdWrapper> DESC by CreatedDate.
//     * 4. Grab the top one in the list and create a map of Account Id => Latest Hpd Wrapper.
//     * 5. Query the accounts and update the most recent hpd lookup with the value from the map
//     *
//     * @param newHoldPerDays  Trigger.new (a List of Hold_Per_Day__c records inserted)
//     * @return a List of Account sObjects that were updated if any.
//     */
//    public static List<Account> updateAccountMostRecentHPD(List<Hold_Per_Day__c> newHoldPerDays) {
//
//        List<Account>              accountsToUpdate  =  new List<Account>();
//        Map<Id, List<HpdWrapper>>  mHoldPerDaysByAccountId  =  new Map<Id, List<HpdWrapper>>();
//        //0121I000000W9xMQAS  in process builder ie. this was daily.. should be monthly
//        Id monthlyHpdRtId = Schema.getGlobalDescribe().get('Hold_Per_Day__c').getDescribe()
//                .getRecordTypeInfosByDeveloperName().get('Monthly_HPD').getRecordTypeId();
//
//        for(Hold_Per_Day__c hpd : newHoldPerDays) {
//            if(hpd.RecordTypeId == monthlyHpdRtId) {
//                if (!mHoldPerDaysByAccountId.containsKey(hpd.Account__c)) {
//                    mHoldPerDaysByAccountId.put(hpd.Account__c,new List<HpdWrapper>{ new HpdWrapper(hpd)});
//                } else {
//                    List<HpdWrapper> accountHoldPerDayWrappers = mHoldPerDaysByAccountId.get(hpd.Account__c);
//                    accountHoldPerDayWrappers.add(new HpdWrapper(hpd));
//                }
//            }
//        }
//        if(!mHoldPerDaysByAccountId.isEmpty()) {
//            Map<Id,HpdWrapper> mHoldPerDayWrapperByAccountId = new Map<Id,HpdWrapper>();
//            for(Id accountId : mHoldPerDaysByAccountId.keySet()) {
//                List<HpdWrapper> holdPerDayWrappers = mHoldPerDaysByAccountId.get(accountId);
//                holdPerDayWrappers.sort(); //  Sort Descending
//                //--- Deduce to the latest one.
//                mHoldPerDayWrapperByAccountId.put(accountId,holdPerDayWrappers[0]);
//            }
//            Map<Id,Account> mAccountsByIds = new Map<Id,Account> ([
//                    SELECT  Id, Most_Recent_Hold_Per_Day__c
//                    FROM    Account
//                    WHERE   Id IN :mHoldPerDayWrapperByAccountId.keySet()
//            ]);
//            if(!mAccountsByIds.isEmpty()) {
//                for(Id accountId : mAccountsByIds.keySet()) {
//                    Account account = mAccountsByIds.get(accountId);
//                    HpdWrapper mostRecent  = mHoldPerDayWrapperByAccountId.get(account.Id);
//                    if(mostRecent != null) {
//                        account.Most_Recent_Hold_Per_Day__c = mostRecent.hpd.Id;
//                        accountsToUpdate.add(account);
//                    }
//                }
//                if(!accountsToUpdate.isEmpty()) {
//                    try {
//                        update accountsToUpdate;
//                    } catch (Exception e) {
//                        System.debug(LoggingLevel.ERROR,e);
//                    }
//                }
//            }
//        }
//        return accountsToUpdate;
//    }
//
//    /**
//     * Inner class implementing comparable used primarily for Sorting by
//     * Hold_Per_Day__c.CreatedDate DESC.
//     */
//    public class HpdWrapper implements Comparable {
//
//        public Hold_Per_Day__c hpd;
//
//        /**
//         * Constructor to store Hpd in inner class.
//         * @param pHpd
//         */
//        public HpdWrapper(Hold_Per_Day__c pHpd) {
//            this.hpd = pHpd;
//        }
//        /**
//         * Sorts the list in descending by Created Date.
//         * @param compareTo
//         * @return
//         */
//        public Integer compareTo(Object compareTo) {
//            HpdWrapper compareToHpd = (HpdWrapper)compareTo;
//            Integer iRet = 0;
//            if(hpd.CreatedDate  > compareToHpd.hpd.CreatedDate) {
//                iRet = 1;
//            } else {
//                iRet = -1;
//            }
//            return iRet;
//        }
//    }
}