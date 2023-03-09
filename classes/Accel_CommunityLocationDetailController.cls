/**
 *  Controller backing the Accel Location Detail Page.
 *
 *  This is intended to deprecate the  one method used in the old controller / simplify it.
 *  @see Accel_CommunityLocationSummaryController (retrieveUserHpdAndExpDate)
 */
public with sharing class Accel_CommunityLocationDetailController {

    public static final String  MAP_KEY_ACCOUNT_LICENSE_WRAPPERS        = 'ACCOUNT_LICENSE_WRAPPERS';
    public static final String  MAP_KEY_ACCOUNT_LICENSE_SUMMARY         = 'ACCOUNT_LICENSE_SUMMARY';
    public static Integer       MAX_NUMBER_OF_ACCOUNTS                  = 300; //@TODO Get from Custom Metadata.
    public static Set<String>   ACCOUNT_TYPES                           = CustomMetaDataSvc.retrieveCommunityAccountTypes();
    public static Integer       NUM_DAYS_TILL_LICENSE_EXPIRATION        = 30;  //@TODO Get from Custom Metadata.
    /**
     * Retrieves Account and Associated License Info. Keys off the Active Licenses on the Account.
     * Looks for record type Location.. The Types that are in the community account custom meta data.
     * And those with a VGT Live Date or those that are portal dummy accounts.
     *
     * @return a ResponseDto object containing a map keyed by ACCOUNT_LICENSE_WRAPPERS which contains a
     *         List of AccountLicenseWrapper objects AND a map keyed by MAP_KEY_ACCOUNT_LICENSE_SUMMARY which
     *         contains a single AccountLicenseSummary instance.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveAccountLicenses() {
        ResponseDto dto = new ResponseDto();

        List<Account> accounts = [
                SELECT  Id, Name, ShippingCity, IGB_License__c,ParentId, ShippingStreet,Accel_VGT_Live_Date__c,
                        Active_DOJ_License__r.Expiration_Date__c,
                        Active_IBA_License__r.Expiration_Date__c,
                        Active_Local_Gaming_License__r.Expiration_Date__c,
                        Active_State_Liquor_License__r.Expiration_Date__c,
                        Active_Local_Liquor_License__r.Expiration_Date__c,
                        Active_IGB_Gaming_License__r.Expiration_Date__c
                FROM    Account
                WHERE   Type                IN :ACCOUNT_TYPES
                AND     RecordType.Name     =   'Location'
                AND     (Accel_VGT_Live_Date__c != NULL OR Legal_Name__c = 'Portal Dummy Account')
                ORDER BY
                        ParentId NULLS FIRST, Account.Name ASC, ShippingCity ASC, IGB_License__c DESC
                LIMIT   :MAX_NUMBER_OF_ACCOUNTS
        ];
        if(!accounts.isEmpty()) {
            dto.isSuccess = true;
            List<AccountLicenseWrapper> wraps = new List<AccountLicenseWrapper>();
            //  https://accel-entertainment.monday.com/boards/286658657/pulses/311323513  Added license summary retrieval
            List<License__c> expiredOrExpiringLicenses  =   LicenseSvc.retrieveAccountsExpiringOrExpiredLicenses(accounts,
                    NUM_DAYS_TILL_LICENSE_EXPIRATION);

            for(Account account : accounts) {
                AccountLicenseWrapper wrap = new AccountLicenseWrapper(account, NUM_DAYS_TILL_LICENSE_EXPIRATION);
                wraps.add( wrap );
            }
            dto.values.put(MAP_KEY_ACCOUNT_LICENSE_WRAPPERS,wraps);

            if(!expiredOrExpiringLicenses.isEmpty()) {
                AccountLicenseSummary licenseSummary = new AccountLicenseSummary();
                for(License__c license : expiredOrExpiringLicenses) {
                    if(LicenseSvc.isLicenseExpired(license.Expiration_Date__c)) {
                        licenseSummary.iNumExpiredLicenses++;
                    } else if (LicenseSvc.isLicenseExpiring(license.Expiration_Date__c,NUM_DAYS_TILL_LICENSE_EXPIRATION)) {
                        licenseSummary.iNumExpiringLicenses++;
                    }
                }
                licenseSummary.anyExpiredOrExpiring = licenseSummary.iNumExpiringLicenses >0 || licenseSummary.iNumExpiredLicenses > 0;
                dto.values.put(MAP_KEY_ACCOUNT_LICENSE_SUMMARY,licenseSummary);
            }
        } else {
            dto.technicalMsg += 'no accounts found for user id  '+UserInfo.getUserId() + '..recordtype=Location'
                    + '..accountTypes='+ACCOUNT_TYPES;
        }
        return dto;
    }
    /**
     * Wrapper class in order to assist the UI with Display in an accordion.
     */
    public class AccountLicenseWrapper {
        @AuraEnabled public String      accountName                     {get;set;}
        @AuraEnabled public String      accountId                       {get;set;}
        @AuraEnabled public String      shippingStreet                  {get;set;}
        @AuraEnabled public String      shippingCity                    {get;set;}
        @AuraEnabled public Date        accelVgtLiveDate                {get;set;}

        @AuraEnabled public Date        dojLicenseExpDate               {get;set;}
        @AuraEnabled public Date        igbLicenseExpDate               {get;set;}
        @AuraEnabled public Date        ibaLicenseExpDate               {get;set;}
        @AuraEnabled public Date        localGamingLicenseExpDate       {get;set;}
        @AuraEnabled public Date        localLiquorLicenseExpDate       {get;set;}
        @AuraEnabled public Date        stateLiquorLicenseExpDate       {get;set;}

        @AuraEnabled public Boolean     dojLicenseExpired               {get; private set;}
        @AuraEnabled public Boolean     igbLicenseExpired               {get; private set;}
        @AuraEnabled public Boolean     ibaLicenseExpired               {get; private set;}
        @AuraEnabled public Boolean     localGamingLicenseExpired       {get; private set;}
        @AuraEnabled public Boolean     localLiquorLicenseExpired       {get; private set;}
        @AuraEnabled public Boolean     stateLiquorLicenseExpired       {get; private set;}
        @AuraEnabled public Boolean     anyLicenseExpired               {get; private set;}

        @AuraEnabled public Boolean     dojLicenseExpiring              {get; private set;}
        @AuraEnabled public Boolean     igbLicenseExpiring              {get; private set;}
        @AuraEnabled public Boolean     ibaLicenseExpiring              {get; private set;}
        @AuraEnabled public Boolean     localGamingLicenseExpiring      {get; private set;}
        @AuraEnabled public Boolean     localLiquorLicenseExpiring      {get; private set;}
        @AuraEnabled public Boolean     stateLiquorLicenseExpiring      {get; private set;}
        @AuraEnabled public Boolean     anyLicenseExpiring              {get; private set;}
        /**
         * Constructor sets public properties, and calcs expired / expiring booleans.
         *
         * @param account               An Account sObject.
         * @param numDaysToExpiration   The # of days until license expiration used to warn this user of an expiring license.
         */
        AccountLicenseWrapper( Account account, Integer numDaysToExpiration ) {
            this.accountName                =   account.Name;
            this.accountId                  =   account.Id;
            this.shippingCity               =   account.ShippingCity;
            this.shippingStreet             =   account.ShippingStreet;
            this.accelVgtLiveDate           =   account.Accel_VGT_Live_Date__c;

            this.dojLicenseExpDate          =   account.Active_DOJ_License__r.Expiration_Date__c;
            this.igbLicenseExpDate          =   account.Active_IGB_Gaming_License__r.Expiration_Date__c;
            this.ibaLicenseExpDate          =   account.Active_IBA_License__r.Expiration_Date__c;
            this.localGamingLicenseExpDate  =   account.Active_Local_Gaming_License__r.Expiration_Date__c;
            this.localLiquorLicenseExpDate  =   account.Active_Local_Liquor_License__r.Expiration_Date__c;
            this.stateLiquorLicenseExpDate  =   account.Active_State_Liquor_License__r.Expiration_Date__c;

            this.dojLicenseExpired          =   LicenseSvc.isLicenseExpired(this.dojLicenseExpDate);
            this.igbLicenseExpired          =   LicenseSvc.isLicenseExpired(this.igbLicenseExpDate);
            this.ibaLicenseExpired          =   LicenseSvc.isLicenseExpired(this.ibaLicenseExpDate);
            this.localGamingLicenseExpired  =   LicenseSvc.isLicenseExpired( this.localGamingLicenseExpDate);
            this.localLiquorLicenseExpired  =   LicenseSvc.isLicenseExpired( this.localLiquorLicenseExpDate);
            this.stateLiquorLicenseExpired  =   LicenseSvc.isLicenseExpired( this.stateLiquorLicenseExpDate);
            this.anyLicenseExpired          =   this.isAnyLicenseExpired();

            this.dojLicenseExpiring         =   LicenseSvc.isLicenseExpiring(this.dojLicenseExpDate , numDaysToExpiration);
            this.igbLicenseExpiring         =   LicenseSvc.isLicenseExpiring(this.igbLicenseExpDate, numDaysToExpiration);
            this.ibaLicenseExpiring         =   LicenseSvc.isLicenseExpiring(this.ibaLicenseExpDate, numDaysToExpiration);
            this.localGamingLicenseExpiring =   LicenseSvc.isLicenseExpiring( this.localGamingLicenseExpDate, numDaysToExpiration);
            this.localLiquorLicenseExpiring =   LicenseSvc.isLicenseExpiring( this.localLiquorLicenseExpDate, numDaysToExpiration);
            this.stateLiquorLicenseExpiring =   LicenseSvc.isLicenseExpiring( this.stateLiquorLicenseExpDate, numDaysToExpiration);
            this.anyLicenseExpiring         =   this.isAnyLicenseExpiring();
        }
        /**
         * If Any license is expired return true.
         * @param expirationDate
         * @return  true if ANY license is expired, otherwise false.
         */
        @TestVisible
        private Boolean isAnyLicenseExpired() {
            return (dojLicenseExpired || igbLicenseExpired || ibaLicenseExpired || localLiquorLicenseExpired || localGamingLicenseExpired || stateLiquorLicenseExpired);
        }
        /**
         * If Any license is expiring return true.
         * @param expirationDate
         * @return  true if ANY license is expiring, otherwise false.
         */
        @TestVisible
        private Boolean isAnyLicenseExpiring() {
            return (dojLicenseExpiring || igbLicenseExpiring || ibaLicenseExpiring || localLiquorLicenseExpiring || localGamingLicenseExpiring || stateLiquorLicenseExpiring);
        }
    }
}