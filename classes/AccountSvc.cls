/**
 * AccountSvc provides for all operations around the Account sObject.
 */
public with sharing class AccountSvc {

    public static Set<String>   COMMUNITY_ACCOUNT_TYPES             = CustomMetaDataSvc.retrieveCommunityAccountTypes();
    public static String        COMMUNITY_LOCATION_RECORDTYPE_NAME  = 'Location';


    /**
     * Gets all accounts visible to the user that are accel live locations or portal dummy accounts.
     *
     * @param iMaxNumberOfAccounts  The max number of accounts to retrieve.
     * @return                      A List of account sObjects.
     */
    public static List<Account> retrieveAccounts( Integer iMaxNumberOfAccounts ) {
        Warnings.checkQueryLimits(iMaxNumberOfAccounts);
        List<Account> visibleAccounts = [
                SELECT  Id
                FROM    Account
                WHERE   Type                IN  :COMMUNITY_ACCOUNT_TYPES
                AND     RecordType.Name     =   :COMMUNITY_LOCATION_RECORDTYPE_NAME
                AND     (Accel_VGT_Live_Date__c != NULL OR Legal_Name__c = 'Portal Dummy Account')
                LIMIT   :iMaxNumberOfAccounts
        ];
        return visibleAccounts;
    }

    /**
     * retrieves a list of accounts for a given RM user id and Muni Id.
     *
     * @param rmId    - the relationship manager id.
     * @param muniId  = the muni id.
     *
     * @return a list of account objects.
     */
    public static List<Account> retrieveAccounts(Id rmId, Id muniId) {
        List<Account> accounts = new List<Account>();
        accounts = [
                select  id, name,org_url__c
                from    account
                where relationship_manager__c = :rmId
                and   municipalitylookup__c   = :muniId];
        return accounts;
    }

    /**
     * Retrieves a single account (and every field on the account object)
     *
     * @param accountId An account Id
     * @return          An Account sObject.
     */
    public static Account retrieveFullAccount(Id accountId) {
        Account account;
        DescribeSObjectResult describeResult = accountId.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String q = 'SELECT '+String.join(fieldNames,',')+' FROM  '+describeResult.getName() +' WHERE id = :accountId';
        account = DataBase.query(q);
        return account;
    }

    /**
     * Retrieves a list of old per day objects for a given account.
     * NOTE this limits to 18 monthly hold per days
     *
     * @param accountId
     * @TODO remove hardcoded query limit and put in custom metadata type.
     * @return
     */
    public static List<Hold_Per_Day__c> retrieveAccountHpd(Id accountId) {
        List<Hold_Per_Day__c> hpds = new List<Hold_Per_Day__c>();
        hpds = [    SELECT  id, name,date__c,HPD__c,VGT_Count__c,NTI__c,Funds_In__c,Location_Share__c
                    FROM    hold_per_day__c
                    WHERE   account__c      =   :accountId
                    and     recordtype.name = 'Monthly HPD'
                    ORDER BY date__c desc limit 18];
        return hpds;
    }

//    public static Hold_Per_Day_Total__c retrieveAccountHpdTotal( Id accountId ) {
//        Hold_Per_Day_Total__c holdPerDayTotal;
//        List<Hold_Per_Day_Total__c> holdPerDayTotals = [select id from Hold_Per_Day_Total__c where account__c = :accountId];
//        if(!holdPerDayTotals.isEmpty()) {
//            holdPerDayTotal = holdPerDayTotals[0];
//        }
//        return holdPerDayTotal;
//    }
   /**
    * Gets a single Hold_Per_Day_Total__c record for an account based on
    * Account.Hold_Per_Day_Total__C (as opposed to to looking for a hpd total record by
    * account id and record type) This is to be used record in an aura record view form
    * for formatting purposes.
    *
    * @param accountId The account Id.
    * @return          A Hold_Per_Day_Total__c sObject.
    *
    * @todo            Parameterize for record type
    */
    public static Hold_Per_Day_Total__c retrieveAccountHpdTotal( Id accountId ) {

        //  Find the hold_per_day_total__c id attached to the account in context.
        Account account = [
                SELECT Id, Hold_Per_Day_Total__c
                FROM   Account
                WHERE  Id = :accountId
        ];

        //  Get the hold per day total record id for the account.
        Hold_Per_Day_Total__c holdPerDayTotal;
        List<Hold_Per_Day_Total__c> holdPerDayTotals = [
                select id
                from   Hold_Per_Day_Total__c
                where  account__c = :accountId
                and    Id = :account.Hold_Per_Day_Total__c
        ];
        
        if(!holdPerDayTotals.isEmpty()) {
            holdPerDayTotal = holdPerDayTotals[0];
        }
        return holdPerDayTotal;
    }
    /**
     * @param accountId An Account Id.
     * @param rtName    The record type name of the account.
     *
     * @return          A Map of Account Id => Asset.
     */
    public static Map<Id,Asset> retrieveAccountAssets( Id accountId, String rtName )   {
        return retrieveAccountAssets( accountId, new Set<String> {rtName} );
    }

    /**
     * @param accountIds A Set of Account Ids.
     * @param rtName     The record type name of the account.
     *
     * @return           A Map of Account Id => Asset.
     */
    public static Map<Id,Asset> retrieveAccountAssets( Set<Id> accountIds, String rtName ) {
        return retrieveAccountAssets(accountIds, new Set<String>{rtName});
    }

    /**
     * @param accountId  An account Id
     * @param rtNames    A Set of record type names of the account.
     *
     * @return           A Map of Account Id => Asset.
     */
    public static Map<Id,Asset> retrieveAccountAssets( Id accountId, Set<String> rtNames ) {
        return retrieveAccountAssets(new Set<Id>{accountId},rtNames);
    }

    /**
     * @param accountIds A Set of account Ids
     * @param rtNames    A Set of record type names of the account.
     *
     * @return           A Map of Account Id => Asset.
     */
    public static Map<Id,Asset> retrieveAccountAssets( Set<Id> accountIds, Set<String> rtNames ) {
        Map<Id,Asset> m = new Map<Id,Asset>( [
                select  id
                from    asset
                where   accountId       in :accountIds
                and     recordtype.name in :rtNames
                order by accountId desc] );
        return m;
    }

    /**
     * @param accountTypes A Set of the types of accounts
     * @param iLimit       The Max Number of accounts to retrieve.
     *
     * @return             A Map of Account Id => Account
     */
    public static Map<Id,Account> retrieveAccounts( Set<String> accountTypes, Integer iLimit ) {
        Map<Id, Account> mAccountsByIds = new Map<Id, Account>([
                SELECT  Id,Name,ShippingCity,ShippingStreet,ShippingLatitude, ShippingLongitude,IGB_License__c,Location_Type__c,
                        Active_DOJ_License__r.Expiration_Date__c,
                        Active_IBA_License__r.Expiration_Date__c,
                        Active_Local_Gaming_License__r.Expiration_Date__c,
                        Active_State_Liquor_License__r.Expiration_Date__c,
                        Active_IGB_Gaming_License__r.Expiration_Date__c
                FROM    Account
                WHERE   Type in :accountTypes
                LIMIT   :iLimit
        ]);
        return mAccountsByIds;
    }
    /**
     * The will return all Accounts within given account types that have Account.HQ_Account__c checked.
     * Initially created for the Community - File Archive Module.
     *
     * @param accountTypes  Values to search Account.Type field values such as ['Accel Account','Other']. this is
     *                      pulled from Custom Metadata Community_Setting.Account_Types__c.
     * @param iLimit        The maximum # of accounts to retrieve.
     *
     * @return              A map of AccountId => Account if criteria matches, otherwise an empty Map.
     * @see                 CustomMetadataSvc.retrieveCommunityAccountTypes
     */
    public static Map<Id,Account> retrieveAccountsIncludingHq( Set<String> accountTypes, Integer iLimit ) {

        return  new Map<Id, Account>([
                SELECT  Id,Name,ShippingCity,ShippingStreet,ShippingLatitude, ShippingLongitude,
                        IGB_License__c,Location_Type__c,
                        Active_DOJ_License__r.Expiration_Date__c,
                        Active_IBA_License__r.Expiration_Date__c,
                        Active_Local_Gaming_License__r.Expiration_Date__c,
                        Active_State_Liquor_License__r.Expiration_Date__c,
                        Active_IGB_Gaming_License__r.Expiration_Date__c,
                        HQ_Account__c
                FROM    Account
                WHERE   Type            IN :accountTypes
                OR      HQ_Account__c   = TRUE
                ORDER BY HQ_Account__c DESC
                LIMIT   :iLimit
        ]);
    }
//    /**
//     *
//     * @param accountId     The Account.Id to search for.
//     * @param iNumVgts      The total number of VGTs.
//     *
//     * @return              A Map of Position => Asset
//     */
//    public static Map<Integer,Asset> retrieveAccountMachinesByPos(Id accountId,Integer iNumVgts) {
//
//        Map<Integer,Asset> mPos_Asset = new Map<Integer,Asset>();
//
//        List<Account> accounts = [
//                SELECT  Id, VGT_1__c,VGT_2__c,VGT_3__c,VGT_4__c,VGT_5__c,VGT_6__c,
//                        VGT_7__c,VGT_8__c,VGT_9__c,VGT_10__c
//                FROM    Account
//                WHERE   Id = :accountId
//        ];
//        Account  account = !accounts.isEmpty() ? accounts[0] : null;
//
//        if(account != null) {
//            Map<Id, Integer> mAssetId_Pos = new Map<Id, Integer>();
//
//            for (Integer i = 1; i < iNumVgts + 1; i++) {
//                Object obj = account.get('VGT_' + i + '__c');
//                if (obj != null) {
//                    mAssetId_Pos.put((String) obj, i);
//                }
//            }
//            List<Asset> assets = [
//                    SELECT Id, Name, Model__c,SerialNumber,RecordType.Name
//                    FROM Asset
//                    WHERE Id IN :mAssetId_Pos.keySet()
//                    ORDER BY Model__c
//            ];
//
//            for (Asset asset : assets) {
//                mPos_Asset.put(mAssetId_Pos.get(asset.Id), asset);
//            }
//        }
//
//        return mPos_Asset;
//    }
    
    public static Map<Id,Account> retrieveAccountGeoInfos(Set<Id> accountsIds) {
        Map<Id,Account> mAccountsByIds = new Map<Id,Account> ([
                SELECT  Id,Name,ShippingStreet,ShippingCity,ShippingPostalCode,ShippingCountry,
                        ShippingLatitude,ShippingLongitude
                FROM    Account
                WHERE   Id IN :accountsIds
                ORDER BY Name ASC
        ]);
        return mAccountsByIds;
    }
}