/**
 *
 */
public with sharing class AcGrowthMetricsController {

    public static final Integer MAX_NUM_ACCOUNTS                    = 500;
    private final static Integer MAX_RESULTS = 5;
    public static final String  MAP_KEY_HPD_MONTHS                  = 'HPD_WRAPPER_MONTHS';
    public static final String  MAP_KEY_HPD_COMPARE_DATA            = 'HPD_COMPARE_DATA';
    public static final String  MAP_KEY_DEFAULT_DATE_SUGGESTIONS    = 'DEFAULT_DATE_SUGGESTIONS';
    public static final String  MAP_KEY_ACCOUNT_LIST                = 'ACCOUNT_LIST';

    public static Set<Id> accountIds =  retrieveVisibleAccountIds(  CustomMetaDataSvc.retrieveCommunityAccountTypes()
            ,MAX_NUM_ACCOUNTS);

   /**
    * Calls the service to retrieve the user community settings.
    * @return a ResponseDto object containing a Map of CONTACT_PROFILE_SETTINGS => Community_User_Settings__c sObject.
    * @see CommunityUserSettingsSvc
    */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveCommunityUserSettings() {
        ResponseDto dto = new ResponseDto();
        Community_User_Setting__c communityUserSetting;
        try {
            communityUserSetting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();
        } catch (Warnings.InvalidCommunityUserException icueEx) {
            System.debug(LoggingLevel.ERROR, icueEx.getStackTraceString());
            dto.technicalMsg = icueEx.getMessage();
            dto.message = icueEx.getMessage();
        }
        dto.values.put(CommunityConstants.COMMUNITY_SETTINGS, communityUserSetting);
        return dto;
    }

    /**
     *
     *
     * @param startMonth
     * @param endMonth
     *
     * @return
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveRevComparisonData(String locType, Date startMonth, Date endMonth) {
        ResponseDto dto = retrieveMonthlyHpdDates();
        boolean fireQuery = false;
        if (dto.isSuccess) {
            if(startMonth == null || endMonth == null) {
                if (dto.values.containsKey(MAP_KEY_DEFAULT_DATE_SUGGESTIONS)) {
                    SuggestedDefaultDates suggestedDefaultDates = (SuggestedDefaultDates) dto.values.get(MAP_KEY_DEFAULT_DATE_SUGGESTIONS);
                    if (suggestedDefaultDates.isValidStartAndEndDate) {
                        if(startMonth == null) {
                            startMonth = suggestedDefaultDates.suggestedDefaultMonthlyStartDate;
                        }
                        if(endMonth == null) {
                            endMonth = suggestedDefaultDates.suggestedDefaultMonthlyEndDate;
                        }
                        fireQuery = true;
                    }
                }
            } else {
                fireQuery = true;
            }
            if(fireQuery) {
                List<HpdWrapper> hpdWraps = retrieveMonthlyHpds(locType, startMonth, endMonth);
                System.debug(LoggingLevel.DEBUG,'retrieveRevComp number of wraps retured='+hpdWraps.size());


                dto.values.put(MAP_KEY_HPD_COMPARE_DATA, hpdWraps);
            }

        }
        return dto;
    }
    /**
     *
     * @param locType
     * @param startMonth
     * @param endMonth
     *
     * @return a List of HpdWrapper objects.. purged of evil.  generally should be
     * Account  Date
     * 111      startdate
     * 111      enddate
     * 222      startdate
     * 222      enddate
     * @TODO clean this pile of DUNG.. HOT GARBAGE CURRENTLY!
     */
    public static List<HpdWrapper> retrieveMonthlyHpds( String locType, Date startMonth, Date endMonth ) {
        List<HpdWrapper> allHpdWrappers = new List<HpdWrapper>();

        String rtDevName = 'Monthly_HPD';
        List<Hold_Per_Day__c> holdPerDaysStartDate = retrieveHoldPerDays(locType,accountIds,startMonth,rtDevName);
        List<Hold_Per_Day__c> holdPerDaysEndDate   = retrieveHoldPerDays(locType,accountIds,endMonth,rtDevName);

        for (Integer i = 0; i < holdPerDaysStartDate.size(); i++) {
            allHpdWrappers.add(copyHpdToWrap( holdPerDaysStartDate[i]) );
        }
        for (Integer i = 0; i < holdPerDaysEndDate.size(); i++) {
            allHpdWrappers.add(copyHpdToWrap( holdPerDaysEndDate[i]) );
        }
        /**
         * Here is where the shit really stinks.  Build a map of AccountId => List<HpdWrappers>
         * Roll through the list and make sure that we have 2 records tied to the accountId
         * and that hpd_date is not null and no funds in is null. if so.. good to go! otherwise.. trash it.
         */
        Map<Id, List<HpdWrapper>> mAccountId_Hpds = new Map<Id, List<HpdWrapper>>();
        for (HpdWrapper hpdWrap : allHpdWrappers) {
            if (!mAccountId_Hpds.containsKey(hpdWrap.accountId)) {
                mAccountId_Hpds.put(hpdWrap.accountId, new List<HpdWrapper>{ hpdWrap });
            } else {
                List<HpdWrapper> hpdWrapsTmp = mAccountId_Hpds.get(hpdWrap.accountId);
                hpdWrapsTmp.add(hpdWrap);
                mAccountId_Hpds.put(hpdWrap.accountId, hpdWrapsTmp);
            }
        }
        List<HpdWrapper> cleanHpdWrappers = new List<HpdWrapper>();
        for (Id accountId : mAccountId_Hpds.keySet()) {
            List<HpdWrapper> accountHpdWrappers = mAccountId_Hpds.get(accountId);
            Boolean useIt = true;
            if (accountHpdWrappers != null && accountHpdWrappers.size() == 1) {
                useIt = false;
            } else {
                //I mean technically nothing should hit here. but lets let UT code figure it out!
                for (HpdWrapper accountHpdWrapper : accountHpdWrappers) {
                    if (accountHpdWrapper.hpdDate == null || accountHpdWrapper.fundsIn == 0 || accountHpdWrapper.fundsIn == null) {
                        useIt = false;
                    }
                }
            }
            if (useIt) {
                cleanHpdWrappers.addAll(accountHpdWrappers);
            }
        }
        //---- End of Major Ass Fart
        return cleanHpdWrappers;
    }
    /**
     *
     *
     * @param locType      The location type (will be translated in the filter) ie. Account.Filtered_Location_Type__c
     *                     => Account.Location_Type__c.
     * @param accountIds   The account Ids the user has visibility to.
     * @param month        Note this currently assumes the month is date passed with the first day of the month. ie.
     *                     05-01-2019  Since a query of prod shows that for all monthlies the hpd date does indicated the
     *                     first of the month this should be ok.  Doing this as opposed to a date function is probably
     *                     quicker so we might as well.
     * @param rtDevName    The record type developer name.
     *
     * @return              A List of Hold_Per_Day__c sObjects for the given loc type, accounts, Date (Month) and Record type.
     */
    @TestVisible
    private static List<Hold_Per_Day__c> retrieveHoldPerDays(    String locType, Set<Id> accountIds,
                                                                    Date month, String rtDevName) {
        String  soql = '';
        soql += '   SELECT  Account__c,                              ' +
                '           Date__c,                                 ' +
                '           Account__r.Name,                         ' +
                '           Account__r.NickName__c,                  ' +
                '           Account__r.ShippingStreet,               ' +
                '           Account__r.ShippingCity,                 ' +
                '           Account__r.Filtered_Location_Type__c,    ' +
                '           Net_Revenue__c,                          ' +
                '           Location_Share__c,                       ' +
                '           Funds_In__c,                             ' +
                '           Funds_Out__c                             ' +
                '   FROM    Hold_Per_Day__c                          ' +
                '   WHERE   Account__c               IN :accountIds  ' +
                '   AND     RecordType.DeveloperName =  :rtDevName   ' +
                '   AND     Date__c                  =  :month       ' +
                '   AND     Funds_In__c             !=  NULL         ' +
                '   AND     Funds_In__c             != 0             ' +
                            getLocTypeFilter(locType)                  +
                '  ORDER BY Account__c,                              ' +
                '           Date__c ASC                              ';
        return Database.query(soql);
    }
    /**
     *
     *
     * @param locType
     * @return
     */
    @TestVisible
    private static String getLocTypeFilter(String locType) {
        String filter = '';
        Set<String> ignoredValues = new Set<String>{'','All','all','All Types', 'all types'};
        if(locType != null && !ignoredValues.contains(locType) ) {
            filter = ' AND Account__r.Filtered_Location_Type__c = \''+locType+'\'';
        }
        return filter;
    }
    /**
     *
     *
     * @param hpd
     * @return
     */
    @TestVisible
    private static HpdWrapper copyHpdToWrap(Hold_Per_Day__c hpd) {
        HpdWrapper hpdWrapper = new HpdWrapper();
        hpdWrapper.accountId = hpd.Account__c;
        hpdWrapper.accountNickname = hpd.Account__r.Nickname__c; //@TODO Deprecate this.
        hpdWrapper.hpdDate = hpd.Date__c;
        hpdWrapper.accountName = hpd.Account__r.Name;
        hpdWrapper.accountPhysicalStreet = hpd.Account__r.ShippingStreet;
        hpdWrapper.accountPhysicalCity = hpd.Account__r.ShippingCity;
        hpdWrapper.fundsIn = hpd.Funds_In__c;
        hpdWrapper.locShare = hpd.Location_Share__c;
        hpdWrapper.netRevenue = hpd.Net_Revenue__c;
        hpdWrapper.fundsOut = hpd.Funds_Out__c;
        return hpdWrapper;
    }
    /**
     * Retrieves a distinct list of all available filtered location types for the accounts visible to the user.
     *
     * @return a List<String> of Avail
     */
    @AuraEnabled (Cacheable=true)
    public static List<String> retrieveAvailableLocTypes() {
        List<String> availableLocTypes = new List<String>();
        List<AggregateResult> ars = [
                SELECT      Location_Type__c            locType
                FROM        Account
                WHERE       Id                          IN  :accountIds
                GROUP BY    Location_Type__c
        ];
        Set<String> locTypes = new Set<String>();
        for(AggregateResult ar : ars) {
            if(ar.get('locType') != null) {
                String locType = (String)ar.get('locType');
                String filteredLocType = getFilteredLocTypeValue(locType);
                if(filteredLocType == null) {
                    //  If we hit this,  FF field or the mapping here wasn't kept up to date just return normal value.
                    filteredLocType = locType;
                }
                locTypes.add(filteredLocType);
            }
        }
        availableLocTypes.addAll(locTypes);
        System.debug(LoggingLevel.DEBUG,'---- all available loc types='+availableLocTypes);
        return availableLocTypes;
    }
    /**
     * Retrieves all available Hpd Monthly Dates for all Visible Accounts.
     * @return a ResponseDto contain a List<HoldPerDayWrapper> with just the hpd Date field populated.
     *
     * @TODO Optimize! For 500 Accounts as of 9-16 the number of queried rows (prior to agg) would be around 22000 which is way too much
     * This query really does suck but I can't think of a better way of getting it around it other then a table that
     * stores accountId and a string field of say Jan 2018,Feb 2018 etc which is populated via trigger on insert of a monthly record.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveMonthlyHpdDates(){
        ResponseDto dto     = new ResponseDto();
        System.debug(LoggingLevel.DEBUG,'--- retrieveMonthlyHpdDates = LIMIT SOQL Query Rows prior to query='+Limits.getQueryRows());
        List<AggregateResult> ars = [
                SELECT      Date__c                     hpdDate
                FROM        Hold_Per_Day__c
                WHERE       Account__c                  IN  :accountIds
                AND         RecordType.DeveloperName    =   'Monthly_HPD'
                GROUP BY    Date__c
                ORDER BY    Date__c DESC
        ];
        System.debug(LoggingLevel.DEBUG,'--- retrieveMonthlyHpdDates = LIMIT SOQL Query AFTER query='+Limits.getQueryRows());
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper   = new HpdWrapper();
            hpdWrapper.hpdDate      = (Date)ar.get('hpdDate');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_DEFAULT_DATE_SUGGESTIONS,new SuggestedDefaultDates(holdPerDayWrappers));
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+accountIds+' for Monthly HPD Dates';
        }
        dto.values.put(MAP_KEY_HPD_MONTHS,holdPerDayWrappers);
        return dto;
    }
    /**
     * Inner class to assist the front end upon initial page load while showing default results before the user
     * has selected months.
     */
    public class SuggestedDefaultDates {

        @AuraEnabled public Date    suggestedDefaultMonthlyStartDate    {get;set;}
        @AuraEnabled public Date    suggestedDefaultMonthlyEndDate      {get;set;}
        @AuraEnabled public Boolean isValidStartAndEndDate              {get;set;}
        /**
         *
         * @param hpdWrappers
         */
        public SuggestedDefaultDates(List<HpdWrapper> hpdWrappers) {
            this.isValidStartAndEndDate = false;
           if(hpdWrappers != null && !hpdWrappers.isEmpty()) {
               this.suggestedDefaultMonthlyEndDate = hpdWrappers[0].hpdDate;
               if(hpdWrappers.size() > 11) {
                   this.isValidStartAndEndDate = true;
                   this.suggestedDefaultMonthlyStartDate = hpdWrappers[12].hpdDate;
               } else {
                   if (hpdWrappers.size() > 1) {
                       this.isValidStartAndEndDate = true;
                       this.suggestedDefaultMonthlyStartDate = hpdWrappers[1].hpdDate;
                   }
               }
           }
        }
    }
    /**
     * We need to do this because SOQL will let you group by formula fields.
       @param locType  Account.Location_Type__c
     * @return the filtered location type value. Account.Filtered_Location_Type__c.
     */
    public static String getFilteredLocTypeValue(String locType) {
        String filteredValue;
        Map<String, String> mTypeName_FilteredName = new Map<String, String> {
                'Adult Entertainment' => 'Other',
                'American Legion' => 'Fraternal/VFW',
                'Bar' => 'Bar',
                'Bar & Grill' => 'Bar',
                'Bowling Alley' =>'Other',
                'C-Store' => 'C-Store',
                'C-Store W/O Gas' => 'C-Store',
                'Fraternal'=> 'Fraternal/VFW',
                'Gaming Parlor'=> 'Gaming Parlor',
                'Golf Course'=> 'Other',
                'Hotel'=> 'Other',
                'Liquor Store'=> 'C-Store',
                'OTB'=> 'Other',
                'Private Club'=> 'Fraternal/VFW',
                'Recreation (Comedy=>Billiards)'=> 'Other',
                'Restaurant'=> 'Restaurant',
                'Truck Stop'=> 'Truck Stop',
                'Grocery Store'=> 'Grocery Store',
                'VFW'=> 'Fraternal/VFW'
        };
        if(mTypeName_FilteredName.containsKey(locType)) {
            filteredValue = mTypeName_FilteredName.get(locType);
        }
        return filteredValue;
    }


   /**
    *
    * @param accountTypes
    * @param iLimit
    *
    * @return a Set of Just AccountIds
    * @T
    */
    public static Set<Id> retrieveVisibleAccountIds( Set<String> accountTypes, Integer iLimit ) {
        Map<Id, Account> mAccountsByIds = new Map<Id, Account>([
                SELECT  Id
                FROM    Account
                WHERE   Type IN :accountTypes
                LIMIT   :iLimit
        ]);
        return mAccountsByIds.keySet();
    }
}