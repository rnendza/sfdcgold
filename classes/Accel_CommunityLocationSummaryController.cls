/**
 *
 */
public with sharing class Accel_CommunityLocationSummaryController {
    public static final String  MAP_KEY_LOCATION_WRAPPERS               = 'LOCATION_HPD_EXP_WRAPPER_LIST';
    public static final String  MAP_KEY_ALL_LOCATION_MONTHLY            = 'All_LOCATIONS_MONTHLY';
    public static final String  MAP_KEY_LOCATION_LIFETIME_WRAPPERS      = 'LOCATION_LIFETIME_WRAPPER_LIST';
    public static final String  MAP_KEY_LOCATION_MONTHLY_HPDS           = 'LOCATION_MONTHLY_HPDS';
    public static Integer       MAX_NUMBER_OF_ACCOUNTS                  = getMaxAccountResults();
    public static Set<String>   ACCOUNT_TYPES                           = CustomMetaDataSvc.retrieveCommunityAccountTypes();
    //https://accel-entertainment.monday.com/boards/286658657/pulses/311009951
    public static final String  CONTACT_PROFILE_SETTINGS                = 'CONTACT_PROFILE_SETTINGS';


    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveUserHpdAndExpDate() {
        ResponseDto dto = new ResponseDto();
        List<LocationWrapper> locationWrappers  = new List<LocationWrapper>();
        List<Account> accounts = new List<Account>();
//        Set<String> accountTypes = new Set<String>();
//        accountTypes.add('Accel Account');
        Set<String> accountTypes = ACCOUNT_TYPES;
        Integer iMaxResultsInternal = getMaxAccountResults();
        try {
            accounts = [
                    SELECT Id, Name, ShippingCity, IGB_License__c,ParentId, ShippingStreet,Hold_Per_Day_Total__c,
                            Active_DOJ_License__r.Expiration_Date__c,
                            Active_IBA_License__r.Expiration_Date__c,
                            Active_Local_Gaming_License__r.Expiration_Date__c,
                            Active_State_Liquor_License__r.Expiration_Date__c,
                            Active_Local_Liquor_License__r.Expiration_Date__c,
                            Active_IGB_Gaming_License__r.Expiration_Date__c,
                            Active_IGB_Gaming_License__r.License_Original_Issue_Date__c,Accel_VGT_Live_Date__c,
                            Hold_Per_Day_Total__r.Most_Recent_HPD__r.Date__c,
                            Hold_Per_Day_Total__r.Four_Week_HPD__c,Hold_Per_Day_Total__r.HPD_Amount_Played_4_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_Amount_Won_4_Weeks__c,HPD_Funds_In_Total_4_Weeks__c,HPD_Funds_Out_Total_4_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_Location_Share_4_Weeks__c,Hold_Per_Day_Total__r.HPD_Revenue_Total_4_Weeks__c,
                            Hold_Per_Day_Total__r.Eight_Week_HPD__c,Hold_Per_Day_Total__r.HPD_Amount_Played_8_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_Amount_Won_8_Weeks__c,HPD_Funds_In_Total_8_Weeks__c,HPD_Funds_Out_Total_8_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_Location_Share_8_Weeks__c,Hold_Per_Day_Total__r.HPD_Revenue_Total_8_Weeks__c,
                            Hold_Per_Day_Total__r.Twelve_Week_HPD__c,Hold_Per_Day_Total__r.HPD_Amount_Played_12_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_Amount_Won_12_Weeks__c,HPD_Funds_In_Total_12_Weeks__c,HPD_Funds_Out_Total_12_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_Location_Share_12_Weeks__c,Hold_Per_Day_Total__r.HPD_Revenue_Total_12_Weeks__c,
                            Hold_Per_Day_Total__r.HPD_TTM_Avg__c,Hold_Per_Day_Total__r.HPD_TTM_Amount_Played__c,
                            Hold_Per_Day_Total__r.HPD_TTM_Amount_Won__c,Hold_Per_Day_Total__r.HPD_TTM_Funds_In_Total__c,Hold_Per_Day_Total__r.HPD_TTM_Funds_Out_Total__c,
                            Hold_Per_Day_Total__r.HPD_TTM_Location_Share__c,Hold_Per_Day_Total__r.HPD_TTM_Revenue_Total__c
                    FROM    Account
                    WHERE   Type in :accountTypes
                    AND     IGB_License__c != null
                    /*and  Active_IGB_Gaming_License__r.License_Original_Issue_Date__c != null*/
                    ORDER BY
                           Account.ParentId NULLS FIRST, Account.Name ASC, ShippingCity ASC, IGB_License__c DESC
                    LIMIT :iMaxResultsInternal
            ];
            dto.isSuccess = true;
        } catch (Exception e) {
            dto.isSuccess = false;
            dto.technicalMsg = e.getCause() + e.getMessage();
        }
        for(Account account : accounts) {
            locationWrappers.add(new LocationWrapper(account));
        }
        dto.values.put(MAP_KEY_LOCATION_WRAPPERS, locationWrappers);

        return dto;
    }

    /**
     *
     *
     * @param sFreq - null for lifetime.. or 1YR currently supported.
     * @return
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveLocationMonthlyHpds(String sFreq) {
        ResponseDto dto = new ResponseDto();
        //--- find accounts visible to the user.
        system.debug(logginglevel.info,'--- max number of accounts='+MAX_NUMBER_OF_ACCOUNTS);
        Map<Id, Account> m = new Map<Id,Account>([
                select  id,Active_IGB_Gaming_License__r.License_Original_Issue_Date__c
                from    account
                where   Type in :ACCOUNT_TYPES
                //   and Active_IGB_Gaming_License__r.License_Original_Issue_Date__c != null
                order by Active_IGB_Gaming_License__r.License_Original_Issue_Date__c ASC NULLS LAST
                LIMIT   :MAX_NUMBER_OF_ACCOUNTS
        ]);
        if (!m.isEmpty()) {
            List<Id> accountIds = new List<Id>();
            Date minDate;
            accountIds.addAll(m.keySet());
            system.debug(m);

            minDate             = ((Account) m.values()[0]).Active_IGB_Gaming_License__r.License_Original_Issue_Date__c.toStartOfMonth();
            if(sFreq != null) {
                if(sFreq == '1YR') {
                    minDate     = Date.today().addMonths(-13).toStartOfMonth();
                }
            }
            Date endDate        = Date.today().addMonths(1).toStartOfMonth();
            String sStartDate   = JSON.serialize(minDate);
            String sEndDate     = JSON.serialize(endDate);
            ResponseDto dtoTmp  = retrieveHoldPerDayByAccountsLifetimeAggregates(accountIds,sStartDate,sEndDate);

            List<HpdWrapper> hpdWraps = (List<HpdWrapper>)dtoTmp.values.get(MAP_KEY_LOCATION_LIFETIME_WRAPPERS);
            dto.values.put( MAP_KEY_LOCATION_MONTHLY_HPDS, hpdWraps );
        }
        return dto;
    }

    /**
     *
     *
     * @return
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveAllLocationMonthlyWrappersLast12() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Integer iMaxResults = getMaxAccountResults();
        Map<Id, Account> m = new Map<Id,Account>([
                select id
                from account
                where Type in :accountTypes
             //   and Active_IGB_Gaming_License__r.License_Original_Issue_Date__c != null
                order by Active_IGB_Gaming_License__r.License_Original_Issue_Date__c ASC
                LIMIT :iMaxResults
        ]);
        List<Id> accountIds = new List<Id>();
        Date minDate;
        if (!m.isEmpty()) {
            accountIds.addAll(m.keySet());
            minDate = Date.today().addMonths(-13).toStartOfMonth();
            Date endDate = Date.today().addMonths(1);
            String sStartDate = JSON.serialize(minDate);
            String sEndDate = JSON.serialize(endDate);
            ResponseDto dtoTmp = retrieveHoldPerDayByAccountsLifetimeAggregates(accountIds,sStartDate,sEndDate);
            List<HpdWrapper> hpdWrappersAccountsByMonth = (List<HpdWrapper>)dtoTmp.values.get(MAP_KEY_LOCATION_LIFETIME_WRAPPERS);
            dto.values.put(MAP_KEY_LOCATION_LIFETIME_WRAPPERS,hpdWrappersAccountsByMonth);
        }
        return dto;
    }

    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveAllLocationMonthlyWrappers() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Integer iMaxResults = getMaxAccountResults();
        Map<Id, Account> m = new Map<Id,Account>([
                select id, Active_IGB_Gaming_License__r.License_Original_Issue_Date__c
                from account
                where Type in :accountTypes
                and Active_IGB_Gaming_License__r.License_Original_Issue_Date__c != null
                order by Active_IGB_Gaming_License__r.License_Original_Issue_Date__c ASC
                LIMIT :iMaxResults
        ]);
        List<Id> accountIds = new List<Id>();
        Date minIgbLicenseDate;
        if (!m.isEmpty()) {
            accountIds.addAll(m.keySet());
            minIgbLicenseDate = ((Account) m.values()[0]).Active_IGB_Gaming_License__r.License_Original_Issue_Date__c.toStartOfMonth();
            Date endDate = Date.today().addMonths(1);
            String sStartDate = JSON.serialize(minIgbLicenseDate);
            String sEndDate = JSON.serialize(endDate);
            ResponseDto dtoTmp = retrieveHoldPerDayByAccountsLifetimeAggregates(accountIds,sStartDate,sEndDate);
            List<HpdWrapper> hpdWrappersAccountsByMonth = (List<HpdWrapper>)dtoTmp.values.get(MAP_KEY_LOCATION_LIFETIME_WRAPPERS);
            dto.values.put(MAP_KEY_LOCATION_LIFETIME_WRAPPERS,hpdWrappersAccountsByMonth);
        }
        return dto;
    }
    /**
     *
     *
     * @return
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveLocationAllMonthlyWrappers() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Integer iMaxResults = getMaxAccountResults();
        Map<Id, Account> m = new Map<Id,Account>([
                select id, Active_IGB_Gaming_License__r.License_Original_Issue_Date__c
                from account
                where Type in :accountTypes
                and Active_IGB_Gaming_License__r.License_Original_Issue_Date__c != null
                order by Active_IGB_Gaming_License__r.License_Original_Issue_Date__c ASC
                LIMIT :iMaxResults
        ]);
        List<Id> accountIds = new List<Id>();
        Date minIgbLicenseDate;
        if (!m.isEmpty()) {
            accountIds.addAll(m.keySet());
            minIgbLicenseDate = ((Account) m.values()[0]).Active_IGB_Gaming_License__r.License_Original_Issue_Date__c.toStartOfMonth();
            Date endDate = Date.today().addMonths(1);
            String sStartDate = JSON.serialize(minIgbLicenseDate);
            String sEndDate = JSON.serialize(endDate);
            ResponseDto dtoTmp = retrieveHpdAllLocationsMonthly(accountIds, sStartDate, sEndDate);
            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>) dtoTmp.values.get(MAP_KEY_ALL_LOCATION_MONTHLY);
            dto.values.put(MAP_KEY_ALL_LOCATION_MONTHLY, hpdWrappers);
        }
        return dto;
    }
    /**
     *
     *
     * @param iMaxResults
     *
     * @return
     * @TODO move to Svc
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveUserLocations(Integer iMaxResults) {
        ResponseDto dto = new ResponseDto();
        List<Account> accounts = new List<Account>();
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        //Integer iMaxResultsInternal = 100; //@TODO the param was coming as a string in mollysdev thus crashing this?
        //@TODO ignore iMaxResults for now and use custome meta

        Integer iMaxResultsInternal = 30;
        String settingName = 'Application_Search_Limits';
        String fieldName = 'Max_Account_Results__c';
        Object oMaxAccounts = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName,fieldName);
        if(oMaxAccounts != null) {
            //@TODO try catch or type check?
            iMaxResultsInternal = ((Decimal)oMaxAccounts).intValue();
        }
        /*
         *  Get pre calculated monthly Hold Per Day Totals for perf reasons. (run at night ie Hold_Per_Day_Total__c)/
         *  should probably precal other data besides 12 / 3 and 1 month intervals to make other things faster.
         */
        try {
            accounts = [
                    SELECT Id, Name, ShippingCity, IGB_License__c,ParentId, ShippingStreet,Hold_Per_Day_Total__c,
                            Active_DOJ_License__r.Expiration_Date__c,
                        Active_IBA_License__r.Expiration_Date__c,
                        Active_Local_Gaming_License__r.Expiration_Date__c,
                        Active_State_Liquor_License__r.Expiration_Date__c,
                        Active_Local_Liquor_License__r.Expiration_Date__c,
                        Active_IGB_Gaming_License__r.Expiration_Date__c,
                        Active_IGB_Gaming_License__r.License_Original_Issue_Date__c,Accel_VGT_Live_Date__c,
                        Hold_Per_Day_Total__r.Most_Recent_HPD__r.Date__c,
                        Hold_Per_Day_Total__r.Four_Week_HPD__c,Hold_Per_Day_Total__r.HPD_Amount_Played_4_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_Amount_Won_4_Weeks__c,HPD_Funds_In_Total_4_Weeks__c,HPD_Funds_Out_Total_4_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_Location_Share_4_Weeks__c,Hold_Per_Day_Total__r.HPD_Revenue_Total_4_Weeks__c,
                        Hold_Per_Day_Total__r.Eight_Week_HPD__c,Hold_Per_Day_Total__r.HPD_Amount_Played_8_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_Amount_Won_8_Weeks__c,HPD_Funds_In_Total_8_Weeks__c,HPD_Funds_Out_Total_8_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_Location_Share_8_Weeks__c,Hold_Per_Day_Total__r.HPD_Revenue_Total_8_Weeks__c,
                        Hold_Per_Day_Total__r.Twelve_Week_HPD__c,Hold_Per_Day_Total__r.HPD_Amount_Played_12_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_Amount_Won_12_Weeks__c,HPD_Funds_In_Total_12_Weeks__c,HPD_Funds_Out_Total_12_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_Location_Share_12_Weeks__c,Hold_Per_Day_Total__r.HPD_Revenue_Total_12_Weeks__c,
                        Hold_Per_Day_Total__r.HPD_TTM_Avg__c,Hold_Per_Day_Total__r.HPD_TTM_Amount_Played__c,
                        Hold_Per_Day_Total__r.HPD_TTM_Amount_Won__c,Hold_Per_Day_Total__r.HPD_TTM_Funds_In_Total__c,Hold_Per_Day_Total__r.HPD_TTM_Funds_Out_Total__c,
                        Hold_Per_Day_Total__r.HPD_TTM_Location_Share__c,Hold_Per_Day_Total__r.HPD_TTM_Revenue_Total__c
                    FROM Account
                    WHERE Type in :accountTypes
                    and IGB_License__c != null
                    ORDER BY
                            Account.ParentId NULLS FIRST, Account.Name ASC, ShippingCity ASC, IGB_License__c DESC
                    LIMIT :iMaxResultsInternal
            ];
            dto.isSuccess = true;
        } catch (Exception e) {
            dto.isSuccess = false;
            dto.technicalMsg = e.getCause() + e.getMessage();
        }

        List<LocationWrapper> locationWrappers  = new List<LocationWrapper>();

        List<Id> accountIds = new List<Id>();
        List<Date> origIbgLicenseDates = new List<Date>();
        for(Account account : accounts) {
            locationWrappers.add(new LocationWrapper(account));
            accountIds.add(account.Id);
            if(account.Active_IGB_Gaming_License__r.License_Original_Issue_Date__c != null) {
                //Is this right? who the hell knows.. hello BA??
                origIbgLicenseDates.add(account.Active_IGB_Gaming_License__r.License_Original_Issue_Date__c);
            }
        }
        Date minIgbLicenseDate;
        if(!origIbgLicenseDates.isEmpty()) {
            origIbgLicenseDates.sort();
            minIgbLicenseDate = origIbgLicenseDates.get(0).toStartOfMonth();
           // Date endDate   = Date.today().addMonths(1).addDays(-1);
            Date endDate   = Date.today().addMonths(1);
            String sStartDate = JSON.serialize(minIgbLicenseDate);
            String sEndDate = JSON.serialize(endDate);
            system.debug('--------------   min original igb license date ='+minIgbLicenseDate);
            system.debug('--------------   max search end date ='+endDate);
            dto.values.put(MAP_KEY_LOCATION_WRAPPERS, locationWrappers);

            ResponseDto dto2 = retrieveHpdAllLocationsMonthly(accountIds, sStartDate, sEndDate );
            List<HpdWrapper> hpdWrappers = (List<HpdWrapper>)dto2.values.get(MAP_KEY_ALL_LOCATION_MONTHLY);
            dto.values.put(MAP_KEY_ALL_LOCATION_MONTHLY,hpdWrappers);

            ResponseDto dto3 = retrieveHoldPerDayByAccountsLifetimeAggregates(accountIds,sStartDate,sEndDate);
            List<HpdWrapper> hpdWrappersAccountsByMonth = (List<HpdWrapper>)dto3.values.get(MAP_KEY_LOCATION_LIFETIME_WRAPPERS);
            dto.values.put(MAP_KEY_LOCATION_LIFETIME_WRAPPERS,hpdWrappersAccountsByMonth);
        }
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveAccountRevenue(Id accountId, Date startDate, Date endDate) {
        return new ResponseDto();
    }
    public class LocationWrapper{
        @AuraEnabled public String      fullLocationName {get;set;}
        @AuraEnabled public String      shippingStreet  {get;set;}
        @AuraEnabled public String      shippingCity    {get;set;}
        @AuraEnabled public String      name            {get;set;}
        @AuraEnabled public String      id              {get;set;}

        @AuraEnabled public HpdDetail   hpd4Week        {get;set;}
        @AuraEnabled public HpdDetail   hpd8Week        {get;set;}
        @AuraEnabled public HpdDetail   hpd12Week       {get;set;}
        @AuraEnabled public HpdDetail   hpdTtm          {get;set;}

        @AuraEnabled public Boolean isAnyLicenseExpiring       {get;set;}
        @AuraEnabled public Date    dojLicenseExpDate          {get;set;}
        @AuraEnabled public Date    igbGamingLicenseExpDate    {get;set;}
        @AuraEnabled public Date    ibaLicenseExpDate          {get;set;}
        @AuraEnabled public Date    localGamingLicenseExpDate  {get;set;}
        @AuraEnabled public Date    localLiquorLicenseExpDate  {get;set;}
        @AuraEnabled public Date    stateLiquorLicenseExpDate  {get;set;}

        public LocationWrapper(Account account) {
            this.name               = account.Name;
            this.id                 = account.Id;
            this.shippingStreet     = account.ShippingStreet;
            this.shippingCity       = account.ShippingCity;
            this.hpd4Week           = new HpdDetail(account,4);
            this.hpd8Week           = new HpdDetail(account,8);
            this.hpd12Week          = new HpdDetail(account,12);
            this.hpdTtm             = new HpdDetail(account,52);
            this.fullLocationName = this.name;
            //this.fullLocationName = '';
            if(this.shippingStreet != null) {
                this.fullLocationName += ' - ' + this.shippingStreet;
            }
            if(this.shippingCity != null) {
                this.fullLocationName += ' - ' + this.shippingCity;
            }
            //this.isAnyLicenseExpiring = account.Is_Any_License_Expiring__c;
            dojLicenseExpDate = account.Active_DOJ_License__r.Expiration_Date__c;
            igbGamingLicenseExpDate = account.Active_IGB_Gaming_License__r.Expiration_Date__c;
            ibaLicenseExpDate = account.Active_IBA_License__r.Expiration_Date__c;
            localGamingLicenseExpDate = account.Active_Local_Gaming_License__r.Expiration_Date__c;
            localLiquorLicenseExpDate = account.Active_Local_Liquor_License__r.Expiration_Date__c;
            stateLiquorLicenseExpDate = account.Active_State_Liquor_License__r.Expiration_Date__c;
        }
    }
    public class HpdDetail {
        @AuraEnabled public Decimal fundsOut        { get; set; }
        @AuraEnabled public Decimal fundsIn         { get; set; }
        @AuraEnabled public Decimal amtPlayed       { get; set; }
        @AuraEnabled public Decimal amtWon          { get; set; }
        @AuraEnabled public Decimal revenue         { get; set; }
        @AuraEnabled public Decimal locShare        { get; set; }
        @AuraEnabled public Decimal hpdAvg          { get; set; }

        public HpdDetail(Account account,Integer timePeriod) {
            switch on timePeriod {
                when 4 {
                    this.fundsOut = account.HPD_Funds_Out_Total_4_Weeks__c;
                    this.fundsIn = account.HPD_Funds_In_Total_4_Weeks__c;
                    this.amtPlayed = account.Hold_Per_Day_Total__r.HPD_Amount_Played_4_Weeks__c;
                    this.amtWon = account.Hold_Per_Day_Total__r.HPD_Amount_Won_4_Weeks__c;
                    this.revenue = account.Hold_Per_Day_Total__r.HPD_Revenue_Total_4_Weeks__c;
                    this.locShare = account.Hold_Per_Day_Total__r.HPD_Location_Share_4_Weeks__c;
                    this.hpdAvg = account.Hold_Per_Day_Total__r.Four_Week_HPD__c;
                }
                when 8 {
                    this.fundsOut = account.HPD_Funds_Out_Total_8_Weeks__c;
                    this.fundsIn = account.HPD_Funds_In_Total_8_Weeks__c;
                    this.amtPlayed = account.Hold_Per_Day_Total__r.HPD_Amount_Played_8_Weeks__c;
                    this.amtWon = account.Hold_Per_Day_Total__r.HPD_Amount_Won_8_Weeks__c;
                    this.revenue = account.Hold_Per_Day_Total__r.HPD_Revenue_Total_8_Weeks__c;
                    this.locShare = account.Hold_Per_Day_Total__r.HPD_Location_Share_8_Weeks__c;
                    this.hpdAvg = account.Hold_Per_Day_Total__r.Eight_Week_HPD__c;
                }
                when 12 {
                    this.fundsOut = account.HPD_Funds_Out_Total_12_Weeks__c;
                    this.fundsIn = account.HPD_Funds_In_Total_12_Weeks__c;
                    this.amtPlayed = account.Hold_Per_Day_Total__r.HPD_Amount_Played_12_Weeks__c;
                    this.amtWon = account.Hold_Per_Day_Total__r.HPD_Amount_Won_12_Weeks__c;
                    this.revenue = account.Hold_Per_Day_Total__r.HPD_Revenue_Total_12_Weeks__c;
                    this.locShare = account.Hold_Per_Day_Total__r.HPD_Location_Share_12_Weeks__c;
                    this.hpdAvg = account.Hold_Per_Day_Total__r.Twelve_Week_HPD__c;
                }
                when 52 {
                    this.fundsOut = account.Hold_Per_Day_Total__r.HPD_TTM_Funds_Out_Total__c;
                    this.fundsIn = account.Hold_Per_Day_Total__r.HPD_TTM_Funds_In_Total__c;
                    this.amtPlayed = account.Hold_Per_Day_Total__r.HPD_TTM_Amount_Played__c;
                    this.amtWon = account.Hold_Per_Day_Total__r.HPD_TTM_Amount_Won__c;
                    this.revenue = account.Hold_Per_Day_Total__r.HPD_TTM_Revenue_Total__c;
                    this.locShare = account.Hold_Per_Day_Total__r.HPD_TTM_Location_Share__c;
                    this.hpdAvg = account.Hold_Per_Day_Total__r.HPD_TTM_Avg__c;
                }
                when else {

                }
            }
        }
    }
    public Class LocationDetail{
        @AuraEnabled public Object hpd4Week;
        @AuraEnabled public Object hpd8Week;
        @AuraEnabled public Decimal hpd12Week;

        public LocationDetail(Account account) {
            this.hpd4Week = account.Hold_Per_Day_Total__r.Four_Week_HPD__c;
            this.hpd8Week = account.Hold_Per_Day_Total__r.Eight_Week_HPD__c;
            this.hpd12Week = account.Hold_Per_Day_Total__r.Twelve_Week_HPD__c;
        }
    }
    /**
     *
     *
     * @return
     */
    @AuraEnabled
    public static ResponseDto retrieveUserLocations() {
        return retrieveUserLocations(50000);
    }


    @AuraEnabled
    public static ResponseDto retrieveHoldPerDayByAccountsLifetimeAggregates( List<Id>  accountIds, String  startDate, String endDate ) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();


        //--- SFDC Hack the framework sucks at passing dates server side.
        Date dStartDate = (Date) JSON.deserialize(startDate,Date.class);
        Date dEndDate = (Date) JSON.deserialize(endDate,Date.class);
        //--- SFDC hack since the framework can't pass sets
        Set<Id> accountIdsSet = new Set<Id>();
        accountIdsSet.addAll(accountIds);
        //@TODO Custom meta / pass as param?
        String hpdRtName    = 'Monthly HPD';
        String assetRtName  = 'VGT';
        Decimal defaultTaxRate = 30.0000;
        Decimal defaultAdminRate = 0.8513;

        hpdWrappers         = HpdSvc.retrieveHpdAccountLifetimeResults( accountIdsSet,hpdRtName,dStartDate,dEndDate,defaultTaxRate,defaultAdminRate );
        ResponseDto dto     = new ResponseDto();
        dto.isSuccess       = true;
        dto.values.put(MAP_KEY_LOCATION_LIFETIME_WRAPPERS,hpdWrappers);
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveHpdAllLocationsMonthly( List<Id> accountIds, String startDate, String endDate) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        //--- SFDC Hack the framework sucks at passing dates server side.
        Date dStartDate = (Date) JSON.deserialize(startDate,Date.class);
        Date dEndDate = (Date) JSON.deserialize(endDate,Date.class);
        //--- SFDC hack since the framework can't pass sets
        Set<Id> accountIdsSet = new Set<Id>();
        accountIdsSet.addAll(accountIds);

        hpdWrappers = HpdSvc.retrieveHpdAllAccountsMonthlyResults(accountIdsSet,'Monthly HPD',dStartDate,dEndDate);
        ResponseDto dto     = new ResponseDto();
        dto.isSuccess       = true;
        dto.values.put(MAP_KEY_ALL_LOCATION_MONTHLY,hpdWrappers);
        return dto;
    }

    @AuraEnabled
    public static Integer getMaxAccountResults() {
        Integer iMaxResultsInternal = 30;
        String settingName = 'Application_Search_Limits';
        String fieldName = 'Max_Account_Results__c';
        Object oMaxAccounts = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName,fieldName);
        if(oMaxAccounts != null) {
            iMaxResultsInternal = ((Decimal)oMaxAccounts).intValue();
        }
        return iMaxResultsInternal;
    }
}