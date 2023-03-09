public class AccountTriggerHandler {

    static HPD_Total_Setting__mdt hpdTotalAccountSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME);

    /**
     * Checks CL Automation Custom Settings to determine if we wish to prevent delete for Accounts.
     * Adds a secondary check to see if the account has Route_Processing_Sheet__c children.
     * If so, get the custom label to display a message to the user upon error (replace {0} token with dyna value)
     * and call addError on the sObject.
     *
     * @param  mOldAccounts Map of Id => Account
     */
    public static void checkDeleteSecurity(Map<Id,Account> mOldAccounts){

        Boolean preventDelete = clAutomationSvc.preventRecordDelete(clAutomationSvc.ACCOUNT_TRIGGER_PREVENT_DELETE);

        if(preventDelete) {

            Map<Id,List<Route_Processing_Sheet__c>> mAccount_Rpss = clAutomationSvc.mapRpsToAccount(mOldAccounts.keySet());

            if(!mAccount_Rpss.isEmpty()) {
                for(Id accountId : mAccount_Rpss.keySet()) {
                    if(mOldAccounts.containsKey(accountId)) {
                        Account account = mOldAccounts.get(accountId);
                        String msg = String.format(Label.CL_Account_Prevent_Delete, new List<String>{account.Name});
                        account.addError(msg);
                    }
                }
            }
        }
    }

//   /**
//    * Checks CL Automation Custom Settings to determine if we wish to prevent delete for Accounts.
//    * Adds a secondary check to see if the account has Route_Processing_Sheet__c children.
//    * If so, get the custom label to display a message to the user upon error (replace {0} token with dyna value)
//    * and call addError on the sObject.
//    *
//    * @param  mOldAccounts Map of Id => Account
//    */
//    public static void checkDeleteSecurity(Map<Id,Account> mOldAccounts){
//
//        Boolean preventDelete = clAutomationSvc.preventRecordDelete(clAutomationSvc.ACCOUNT_TRIGGER_PREVENT_DELETE);
//
//        if(preventDelete) {
//            for(Account account : mOldAccounts.values()) {
//                if(account.Total_Route_Processing_Sheets__c > 0) {
//                    String msg = String.format(Label.CL_Account_Prevent_Delete, new List<String>{account.Name});
//                    account.addError(msg);
//                }
//            }
//        }
//    }

    /** 
     * If Shipping address is null, copy billing address to shipping address.
     *
     * @param accounts - a lst of s objects
     * @returns a list of account sObjects with Shipping Address (if billing address was populated)
     *
     * @note this is generally intended to operate on a list of accounts passed in via Trigger.New
      *      (Implicit update) but can be used a generic method as well as it returns the modified list.
     */
    public static List<Account> copyBillingToShipping(List<Account> accounts) {
        for (Account account : accounts) {
            if (account.ShippingCity == null && account.ShippingPostalCode == null
                    && account.ShippingState == null && account.ShippingCountry == null) {
                account.ShippingCity = account.BillingCity;
                account.ShippingCountry = account.BillingCountry;
                account.ShippingPostalCode = account.BillingPostalCode;
                account.ShippingState = account.BillingState;
                account.ShippingStreet = account.BillingStreet;
            }
        }
        return accounts;
    }
    /**
     * @param oldAccountMap Trigger.old
     * @param newAccountMap Trigger.new
     *
     * @todo protect against a bulk update of 200 accounts in which we updated addresses to conform to 100 callout limit.
     */
    public static void assignMuniLookup(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {

        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());

        if (mdt.Fire_Callout_on_Update__c) {
            try {
                Set<Id> accountIdsForMuniUpdate = new Set<Id>();
                for (Account newAccount : newAccountMap.values()) {
                    Account oldAccount = oldAccountMap.get(newAccount.id);
                    if ((newAccount.ShippingLatitude != oldAccount.ShippingLatitude && newAccount.ShippingLatitude != null)
                            || (newAccount.ShippingLongitude != oldAccount.ShippingLongitude && newAccount.ShippingLatitude != null)) {
                        accountIdsForMuniUpdate.add(newAccount.Id);
                    } else {
                        System.debug('---> no lat long changes!');
                    }
                }
                if (!accountIdsForMuniUpdate.isEmpty()) {
                    // @todo we can only do 100 callouts max per queueable. we might  have up to 200 records in this Trigger trans
                    QueueableMuniUpdater q = new QueueableMuniUpdater(Trigger.newMap.keySet(), false);
                    Id jobId = System.enqueueJob(q);
                    System.debug('----> Firing queueable jobId=' + jobId);
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, e);
            }
        }
    }


//  @todo deprecate logic moved to QueueableCountyUpdaterLive
//   /**
//    * @param oldAccountMap Trigger.old
//    * @param newAccountMap Trigger.new
//    *
//    * @todo protect against a bulk update of 200 accounts in which we updated addresses to conform to 100 callout limit.
//    */
//    public static void assignCountyLookup(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
//
//        //Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
//
//        //if (mdt.Fire_Callout_on_Update__c) {
//            try {
//                Set<Id> accountIdsForCountyUpdate = new Set<Id>();
//                for (Account newAccount : newAccountMap.values()) {
//                    Account oldAccount = oldAccountMap.get(newAccount.id);
//                    if ((newAccount.ShippingLatitude != oldAccount.ShippingLatitude && newAccount.ShippingLatitude != null)
//                            || (newAccount.ShippingLongitude != oldAccount.ShippingLongitude && newAccount.ShippingLatitude != null)) {
//                        accountIdsForCountyUpdate.add(newAccount.Id);
//                    } else {
//                        System.debug('---> no lat long changes for county');
//                    }
//                }
//                if (!accountIdsForCountyUpdate.isEmpty()) {
//                    // @todo we can only do 100 callouts max per queueable. we might  have up to 200 records in this Trigger trans
//                    QueueableCountyUpdaterLive q = new QueueableCountyUpdaterLive(Trigger.newMap.keySet(), false);
//                    Id jobId = System.enqueueJob(q);
//                    System.debug('----> Firing queueable county updater live.. jobId=' + jobId);
//                }
//            } catch (Exception e) {
//                System.debug(LoggingLevel.ERROR, e);
//            }
//        //}
//    }

    /**
     * If An account becomes a live access account.. create a location assessment record. (Vetting_Questionnaire__c).
     *
     * @param oldAccountMap a Map of old account recs prior to change.
     * @param newAccountMap a Map of new account recs after change.
     *
     * @return a List of Vetting_Questionnaire__c objects
     */
    public static List<Vetting_Questionnaire__c> potentiallyCreateLocationAssessment( Map<Id, Account> oldAccountMap,
                                                                                      Map<Id, Account> newAccountMap) {
        List<Vetting_Questionnaire__c> vqsCreated = new List<Vetting_Questionnaire__c>();

        try {
            Id rtId = Schema.SObjectType.Vetting_Questionnaire__c.getRecordTypeInfosByDeveloperName()
                    .get('Location_Specific_Organic_Assessment').getRecordTypeId();
            Map<Id, Account> mAccountsByIds = new Map<Id, Account>();

            for (Account newAccount : newAccountMap.values()) {
                Account oldAccount = oldAccountMap.get(newAccount.id);
                if (newAccount.Accel_VGT_Live_Date__c != null && oldAccount.Accel_VGT_Live_Date__c == null) {
                    mAccountsByIds.put(newAccount.id, newAccount);
                }
            }
            if (!mAccountsByIds.isEmpty()) {

                Map<Id, Account> mAccountsToCreateLocAsses = new Map<Id, Account>();
                List<Vetting_Questionnaire__c> vettingQuestionnaires = [
                        SELECT Id, Account__c
                        FROM Vetting_Questionnaire__c VQ
                        WHERE Account__c in :mAccountsByIds.keySet()
                        AND RecordTypeId = :rtId

                ];
                if (vettingQuestionnaires.isEmpty()) {
                    mAccountsToCreateLocAsses = mAccountsByIds;
                } else { //@TODO Will this ever happen?
                }
                if (!mAccountsToCreateLocAsses.isEmpty()) {
                    vqsCreated = createLocationAssessments(mAccountsToCreateLocAsses);
                }
            }
        } catch (Exception e) {
            system.debug(logginglevel.error,e);
        }
        return  vqsCreated;
    }
    /**
     *
     *
     * @param mAccountsByIds
     *
     * @return
     */
    public static List<Vetting_Questionnaire__c> createLocationAssessments(Map<Id, Account> mAccountsByIds) {
        Id rtId = Schema.SObjectType.Vetting_Questionnaire__c.getRecordTypeInfosByDeveloperName()
                .get('Location_Specific_Organic_Assessment').getRecordTypeId();

        String locAssessmentType = 'Location';
        List<Vetting_Questionnaire__c> vqsToInsert = new List<Vetting_Questionnaire__c>();
        for (Account account : mAccountsByIds.values()) {
            String locName = account.name;
            Integer iMaxNameLength = 57;
            if (locName.length() > iMaxNameLength) {
                locName = locName.subString(0, iMaxNameLength);
            }
            Vetting_Questionnaire__c vq = new Vetting_Questionnaire__c();
            vq.RecordTypeId = rtId;
            vq.Name = locName + ' - Location Assessment';
            vq.Account__c = account.Id;
            vq.Assessment_Type__c = locAssessmentType;
            vqsToInsert.add(vq);
        }
        if (!vqsToInsert.isEmpty()) {
            insert vqsToInsert;
        }
        return vqsToInsert;
    }

    /**
     * @param oldAccountMap
     * @param newAccountMap
     */
    public static void potentiallyCreateHpdTotals(Map<Id,Account> oldAccountMap, Map<Id,Account> newAccountMap) {
        List<String> accountTypes = HpdStatsHelper.hpdTotalAccountSetting.HPD_Account_Types__c.split(',');
        Set<Id> accountIdsToSearch = new Set<Id>();
        try {
            for (Account newAccount : newAccountMap.values()) {
                Account oldAccount = oldAccountMap.get(newAccount.id);
                if (accountTypes.contains(newAccount.Type) && !accountTypes.contains(oldAccount.Type)) {
                    accountIdsToSearch.add(newAccount.id);
                }
            }
            if (!accountIdsToSearch.isEmpty()) {
                Map<Id, Account> m = new Map<Id, Account>([
                        SELECT ID,type,hold_per_day_total__c,hold_per_day_total_daily__c
                        FROM Account
                        WHERE Id in :accountIdsToSearch
                ]);
                if (!m.isEmpty()) {
                    system.debug('craeting hold per day totals for ' + m);
                    createHpdTotals(m);
                }
            }
        } catch (Exception e) {
            system.debug(logginglevel.error,e);

        }
    }
    /**
     * Creates a blank entry in Hold per data totals sObject for purposes of future update in aggregation batch jobs.
     * Will also update account records lookup ntrefs to HPD Totals with new values created in HPD Totals.
     *
     * @param mAccountsByIds
     */
    public static void createHpdTotals(Map<Id, Account> mAccountsByIds) {

        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        Map<Id, Account> mAccountsByIdsProcessed = new Map<Id, Account>();
        Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe()
                .getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
        List<String> accountTypes = hpdTotalAccountSetting.HPD_Account_Types__c.split(',');

        for (Account account : mAccountsByIds.values()) {
            if (accountTypes.contains(account.type)) {
                Hold_Per_Day_Total__c holdPerDayTotal = new Hold_Per_Day_Total__c();
                holdPerDayTotal.frequency__c = 'Monthly';
                holdPerDayTotal.recordtypeid = rtId;
                holdPerDayTotal.account__c = account.id;
                holdPerDayTotals.add(holdPerDayTotal);
                mAccountsByIdsProcessed.put(account.id, account);
            }
        }
        if (!holdPerDayTotals.isEmpty()) {
            insert holdPerDayTotals;
            updateAccountHpdTotalLookups(holdPerDayTotals, mAccountsByIdsProcessed);
        }
    }
    /**
     * So now we take the hold per day totals that were inserted (daily and monthly) and must tag the lookup back on this account record.
     * We must clone the current account that we are processing to avoid read only errors.
     *
     * @param newHoldPerDayTotals
     * @param mAccountsByIds
     */
    public static void updateAccountHpdTotalLookups(List<Hold_Per_Day_Total__c> newHoldPerDayTotals, Map<Id,Account> mAccountsByIds)  {
        Map<Id,List<Hold_Per_Day_Total__c>> mHoldPerDayTotalsByAccountIds = new Map<Id,List<Hold_Per_Day_Total__c>>();
        for(Hold_Per_Day_Total__c holdPerDayTotal : newHoldPerDayTotals) {
            if(!mHoldPerDayTotalsByAccountIds.containsKey(holdPerDayTotal.account__c)) {
                mHoldPerDayTotalsByAccountIds.put(holdPerDayTotal.account__c,new List<Hold_Per_Day_Total__c>{holdPerDayTotal});
            } else {
                List<Hold_Per_Day_Total__c> hpdts = mHoldPerDayTotalsByAccountIds.get(holdPerDayTotal.account__c);
                hpdts.add(holdPerDayTotal);
            }
        }
        List<Account> accountsToUpd = new List<Account>();
        for(Id accountId : mHoldPerDayTotalsByAccountIds.keySet()) {
            Account account = mAccountsByIds.get(accountId);
            if(account != null) {
                Account accountClone = account.clone(true,true);
                List<Hold_Per_Day_Total__c> holdPerDayTotals = mHoldPerDayTotalsByAccountIds.get(accountClone.id);
                for(Hold_Per_Day_Total__c hpdTotal: holdPerDayTotals) {
                    if(hpdTotal.frequency__c == 'Monthly') {
                        accountClone.hold_per_day_total__c = hpdTotal.id;
                    } else if (hpdTotal.frequency__c == 'Daily') {
                        accountClone.hold_per_day_total_daily__c = hpdTotal.id;
                    }
                }
                accountsToUpd.add(accountClone);
            }
        }
        if (!accountsToUpd.isEmpty()) {
            update accountsToUpd;
            system.debug('------ updated ' +accountsToUpd.size() + ' account recs');
        }
    }

    /**
     * Checks if andy of the fields in ShippingAddress changed.. If so sets Account.County_Auto_Updated__c
     * to false;
     *
     * Perform in before update to lessen stress on Account updates (Implicit update)
     *
     * @param oldAccountMap a Map of old account recs prior to change.
     * @param newAccountMap a Map of new account recs after change.
     *
     * @todo check Data.com settings. is it set to bypass triggers.. if so this might now work.
     */
    public static void checkShippingAddressUpdates(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {

        Map<Id, Account> mAccountsByIds = accountsWithShippingAddressChanged(oldAccountMap,newAccountMap);
        if(!mAccountsByIds.isEmpty()) {
            for(Account account : mAccountsByIds.values()) {
                account.County_Auto_Updated__c = false;
            }
        }
    }

    public static Map<Id, Account> accountsWithShippingAddressChanged(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
        Map<Id, Account> mAccountsByIds = new Map<Id, Account>();
        for (Account newAccount : newAccountMap.values()) {
            Account oldAccount = oldAccountMap.get(newAccount.id);

            //  Note triggers won't see computed fields such as ShippingAddress so we must break it down.
            if ((newAccount.ShippingStreet != null && newAccount.ShippingStreet != oldAccount.ShippingStreet)
                    || (newAccount.ShippingCity != null && newAccount.ShippingCity != oldAccount.ShippingCity)
                    || (newAccount.ShippingState != null && newAccount.ShippingState != oldAccount.ShippingState)
                    || (newAccount.ShippingPostalCode != null && newAccount.ShippingPostalCode != oldAccount.ShippingPostalCode)
                    || (newAccount.ShippingCountry != null && newAccount.ShippingCountry != oldAccount.ShippingCountry)
                    ) {
                mAccountsByIds.put(newAccount.id, newAccount);
            }
        }
        return mAccountsByIds;
    }


//  @todo deprecated logic moved to QueuableCountyUpdaterLive
//  ==========  tags Account.County_LU__c and Account.Covid_Region__c on BEFORE UPDATE ===========
//    /**
//     * @param oldAccountMap  Trigger.oldMap
//     * @param newAccountMap  Trigger.newMap
//     *
//     * @return               A List of Account sObjects that were implicitly updated.
//     */
//    public static List<Account> tagCountyLuAndRegionLu(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
//        List<Account> accountsChanged;
//        List<Account> accountsWithCountyLuChanged;
//        List<Account> accountsUpdated = new List<Account>();
//
//        if(Trigger.operationType == TriggerOperation.BEFORE_UPDATE) {
//            accountsChanged = accountsWithCountyChanged( oldAccountMap, newAccountMap);
//            if(!accountsChanged.isEmpty()) {
//                accountsUpdated = updateCountyLuAndRegionLu(accountsChanged);
//                System.debug(LoggingLevel.DEBUG,'---> updateCountyLuAndRegionLU  '+accountsUpdated.size() + ' changed county');
//            } else {
//                accountsWithCountyLuChanged = accountsWithCountyLuChanged(oldAccountMap, newAccountMap);
//                if(!accountsWithCountyLuChanged.isEmpty()) {
//                    Set<Id> countyIds = new Set<Id>();
//                    for(Account account: accountsWithCountyLuChanged) {
//                        countyIds.add(account.County_LU__c);
//                    }
//                    Map<Id,County__c> mCountiesByIds = new Map<Id,County__c>([SELECT Id,Covaid_Region__c,Name FROM County__c WHERE Id IN :countyIds]);
//                    for(Account account : accountsWithCountyLuChanged) {
//                        account.County__c = mCountiesByIds.get(account.County_LU__c).Name;
//                        account.Covid_Region_LU__c = mCountiesByIds.get(account.County_LU__c).Covaid_Region__c;
//                    }
//                }
//            }
//
//
//
//        }
//        return accountsUpdated;
//    }

    // @TODO deprecate logic moved to QueableCoiuntyUpdaterLive
//    /**
//     * @param accounts  A List of account sObjects to implicitly update.
//     * @return          The list of Account sObjects implicitly updated (if any) otherwise empty.
//     */
//    @TestVisible
//    private static List<Account> updateCountyLuAndRegionLu(List<Account> accounts) {
//        List<Account> accountsUpdated = new List<Account>();
//
//        Map<Id,County__c> mCountiesByIds = new Map<Id,County__c>([
//            SELECT Id,Name,Covaid_Region__c,State__c
//            FROM   County__c
//        ]);
//
//        Map<String,County__c> mCountiesByNames = new Map<String,County__c>();
//        for(County__c county : mCountiesByIds.values()) {
//            mCountiesByNames.put(county.Name + '_'+county.State__c, county);
//        }
//
//        for(Account account : accounts) {
//            if(account.County__c != null && account.ShippingState != null) {
//                String concatKey = account.County__c+'_'+account.ShippingState;
//                County__c county = mCountiesByNames.get(concatKey);
//                if(county != null) {
//                    account.County_LU__c = county.Id;
//                    account.Covid_Region_LU__c = county.Covaid_Region__c;
//                    account.County_LU_Auto_Update__c = TRUE;
//                    accountsUpdated.add(account);
//                }
//            }
//        }
//        return accountsUpdated;
//    }


//   @todo deprecate logic moved to QueueableCountyUpdaterLive
//    /**
//     * @param oldAccountMap  Trigger.oldMap
//     * @param newAccountMap  Trigger.newMap
//     *
//     * @return               A List of Account sObjects for which the county__c value changed.
//     */
//    @TestVisible
//    private static List<Account> accountsWithCountyChanged(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
//        List<Account> accounts = new List<Account>();
//        for (Account newAccount : newAccountMap.values()) {
//            Account oldAccount = oldAccountMap.get(newAccount.id);
//            if (newAccount.County__c != null && newAccount.County__c != oldAccount.County__c) {
//                accounts.add(newAccount);
//            }
//        }
//        return accounts;
//    }
//    @TestVisible
//    private static List<Account> accountsWithCountyLuChanged(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
//        List<Account> accounts = new List<Account>();
//        for (Account newAccount : newAccountMap.values()) {
//            Account oldAccount = oldAccountMap.get(newAccount.id);
//            if (newAccount.County_LU__c != null && newAccount.County_LU__c != oldAccount.County_LU__c) {
//                accounts.add(newAccount);
//            }
//        }
//        return accounts;
//    }
    //==============================================================================================================

//    //  ==========  tags Account.Municipality_Lookup__c AFTER INSERT ===========
//    /**
//     * @param oldAccountMap  Trigger.oldMap
//     * @param newAccountMap  Trigger.newMap
//     *
//     * @return               A List of Account sObjects that were implicitly updated.
//     */
//    public static List<Account> tagCountyLuAndRegionLu(Map<Id, Account> oldAccountMap, Map<Id, Account> newAccountMap) {
//        List<Account> accountsChanged;
//        List<Account> accountsWithCountyLuChanged;
//        List<Account> accountsUpdated = new List<Account>();
//
//        if(Trigger.operationType == TriggerOperation.BEFORE_UPDATE) {
//            accountsChanged = accountsWithCountyChanged( oldAccountMap, newAccountMap);
//            if(!accountsChanged.isEmpty()) {
//                accountsUpdated = updateCountyLuAndRegionLu(accountsChanged);
//                System.debug(LoggingLevel.DEBUG,'---> updateCountyLuAndRegionLU  '+accountsUpdated.size() + ' changed county');
//            } else {
//                accountsWithCountyLuChanged = accountsWithCountyLuChanged(oldAccountMap, newAccountMap);
//                if(!accountsWithCountyLuChanged.isEmpty()) {
//                    Set<Id> countyIds = new Set<Id>();
//                    for(Account account: accountsWithCountyLuChanged) {
//                        countyIds.add(account.County_LU__c);
//                    }
//                    Map<Id,County__c> mCountiesByIds = new Map<Id,County__c>([SELECT Id,Covaid_Region__c,Name FROM County__c WHERE Id IN :countyIds]);
//                    for(Account account : accountsWithCountyLuChanged) {
//                        account.County__c = mCountiesByIds.get(account.County_LU__c).Name;
//                        account.Covid_Region_LU__c = mCountiesByIds.get(account.County_LU__c).Covaid_Region__c;
//                    }
//                }
//            }
//
//
//
//        }
//        return accountsUpdated;
//    }


}