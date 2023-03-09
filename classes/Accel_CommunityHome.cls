//---- @TODO what is this limit of 1825 and how was this specific number determined??
//---- how can this data possibly be accurate? To me, barring the use of grax... one should limit the
//---- the visible accounts as opposed to limiting the data within each account in order to ensure all data
//---- for said accounts was retrieved and 'crunched' appropriately.. albeit hard as we are not sure
//---- how much data exists for each account but still. I don't see how this can be accurate if we are going after
//---- say 50 or so accounts..
//--- specifically related to the retrieveHpdData call in ACV2_Home that is going after all daily data from the
//----start of time.. (LIMIT on aggregate is not on what is returned but rather a limit against the amount of rows
//----that are attempted to be aggregated. additionally 2k is the top amount returned by that is not driven by this limit.
//--- @see sfdcfox  https://salesforce.stackexchange.com/questions/212238/aggregated-query-too-many-query-rows

public with sharing class Accel_CommunityHome {

    public static final String MAP_KEY_ACCOUNT_LIST     = 'ACCOUNT_LIST';
    public static final String MAP_KEY_HPD_LIST         = 'HPD_WRAPPER_LIST';
    public static final String MAP_KEY_MONTHLY_HPD_LIST         = 'HPD_MONTHLY_WRAPPER_LIST';
    public static final String MAP_KEY_ACCOUNT_CLOSEST    = 'ACCOUNT_CLOSEST';
    public static final String MAP_KEY_HPD_CLOSEST        = 'HPD_WRAPPER_CLOSEST';
    public static final String MAP_KEY_HPD_CLOSEST_MONTHLY        = 'HPD_WRAPPER_CLOSEST_MONTHLY';
    public static final String MAP_KEY_ACCOUNT_DAILY_HPD   = 'ACCOUNT_DAILY_HPD';
    public static final String MAP_KEY_ACCOUNT_MONTHLY_HPD   = 'ACCOUNT_MONTHLY_HPD';
    public static final String MAP_KEY_ACCOUNT_ALL_YOY_HPD   = 'ACCOUNT_ALL_YOY_HPD';
    public static final String MAP_KEY_ACCOUNT_SINGLE_YOY_HPD   = 'ACCOUNT_SINGLE_YOY_HPD';

    @AuraEnabled (Cacheable=true)
    public static ResponseDto getClosestAccounts(Id id, String accType) {
        ResponseDto dto = new ResponseDto();
        List<Account> accList = new List<Account>();

        accList=AdminSvc.getClosestAccounts(id, accType);

        dto.values.put(MAP_KEY_ACCOUNT_CLOSEST, accList );
        dto.isSuccess = true;
        return dto;
    }



    @AuraEnabled
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes    = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Community_User_Setting__c  communityUserSetting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();
        Integer iLimit              = 500; //@TODO Custom setting?
        dto.values.put(MAP_KEY_ACCOUNT_LIST,AccountSvc.retrieveAccounts( accountTypes,iLimit ).values() );
        dto.values.put(CommunityConstants.COMMUNITY_SETTINGS,communityUserSetting);
        dto.isSuccess = true;
        return dto;
    }
    /**
     * Calls the service to retrieve the user community settings.
     * @return a ResponseDto object containing a Map of CONTACT_PROFILE_SETTINGS => Community_User_Settings__c sObject.
     * @see CommunityUserSettingsSvc
     */
    @AuraEnabled
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
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveHpdData(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        Date startDate = Date.newInstance(2017,1,1);
        Date endDate = Date.today();

        List<AggregateResult> ars = [
                SELECT
                        Date__c                         hpdDate,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum
                FROM    Hold_Per_Day__c
                WHERE   Date__c >= :startDate
                and     Date__c < :endDate
                and     account__c in :visibleAccountIds
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY Date__c
                order by Date__c DESC
                limit 1825
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Daily pull';
        }
        dto.values.put(MAP_KEY_HPD_LIST,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveMonthlyHpdData(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();


        List<AggregateResult> ars = [
                SELECT
                        Date__c                         hpdDate,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     RecordType.Name = 'Monthly HPD'
                GROUP BY Date__c
                order by Date__c DESC
                limit 1825
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Monthly pull';
        }
        dto.values.put(MAP_KEY_MONTHLY_HPD_LIST,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto getClosestMonthlyHpds(List<Id> accIds){
        ResponseDto dto = new ResponseDto();
        Set<Id> closestAccountIds = new Set<Id>();
        closestAccountIds.addAll(accIds);
        List<AggregateResult> ars = [
                SELECT
                        Date__c                         hpdDate,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        COUNT_DISTINCT(Account__c)      numAccs
                FROM    Hold_Per_Day__c
                WHERE   account__c in :closestAccountIds
                and     Date__c != null
                and     RecordType.Name = 'Monthly HPD'
                GROUP BY Date__c
                order by Date__c DESC
                limit 1825
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            hpdWrapper.distinctAccountCount     =(Integer)ar.get('numAccs');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+accIds + ' for Monthly Avg pull';
        }
        dto.values.put(MAP_KEY_HPD_CLOSEST_MONTHLY ,holdPerDayWrappers);
        return dto;
    }

    @AuraEnabled (Cacheable=true)
    public static ResponseDto getClosestHpds(List<Id> accIds){
        ResponseDto dto = new ResponseDto();
        Set<Id> closestAccountIds = new Set<Id>();
        closestAccountIds.addAll(accIds);
        List<AggregateResult> ars = [
                SELECT
                        Date__c                         hpdDate,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        COUNT_DISTINCT(Account__c)      numAccs
                FROM    Hold_Per_Day__c
                WHERE   account__c in :closestAccountIds
                and     Date__c != null
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY Date__c
                order by Date__c DESC
                limit 1825
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            hpdWrapper.distinctAccountCount     =(Integer)ar.get('numAccs');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+accIds + ' for Daily Avg pull';
        }
        dto.values.put(MAP_KEY_HPD_CLOSEST,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto getAccountDailyData(Id id){
        ResponseDto dto = new ResponseDto();

        List<AggregateResult> ars = [
                SELECT
                        Date__c                         hpdDate,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        MAX(account__r.name)                 accName
                FROM    Hold_Per_Day__c
                WHERE   account__c = :id
                and     RecordType.Name = 'Daily Aggregate'
                and     date__c != null
                GROUP BY Date__c
                order by Date__c DESC
                limit 1825
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            hpdWrapper.accountName              =(String)ar.get('accName');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for account:'+id + ' for Daily Single Account pull';
        }
        dto.values.put(MAP_KEY_ACCOUNT_DAILY_HPD,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto getAccountMonthlyData(Id id){
        ResponseDto dto = new ResponseDto();

        List<AggregateResult> ars = [
                SELECT
                        Date__c                         hpdDate,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        MAX(account__r.name)                 accName
                FROM    Hold_Per_Day__c
                WHERE   account__c = :id
                and     RecordType.Name = 'Monthly HPD'
                and     date__c != null
                GROUP BY Date__c
                order by Date__c DESC
                limit 1825
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            hpdWrapper.accountName              =(String)ar.get('accName');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for account:'+id + ' for Monthly Single Account pull';
        }
        dto.values.put(MAP_KEY_ACCOUNT_MONTHLY_HPD,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveAllAccountsYoyData(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();

        List<AggregateResult> ars = [
                SELECT  MAX(date__c)                    hpdDate,
                        CALENDAR_YEAR(date__c)          hpdYear,
                        CALENDAR_MONTH(date__c)         hpdMonth,
                        SUM( Location_Share__c )        locShare,
                        SUM( Funds_In__c )              fundsIn
                FROM    Hold_Per_Day__c
                Where   account__c      in  :visibleAccountIds
                and     RecordType.Name =   'Monthly HPD'
                GROUP BY CALENDAR_YEAR(date__c), CALENDAR_MONTH(date__c)
                ORDER BY CALENDAR_YEAR(date__c) DESC, CALENDAR_MONTH(date__c) DESC


        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShare');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            hpdWrapper.hpdMonth                 = (Integer)ar.get('hpdMonth');
            hpdWrapper.hpdYear                  = (Integer)ar.get('hpdYear');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for YoY pull';
        }
        dto.values.put(MAP_KEY_ACCOUNT_ALL_YOY_HPD,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveSingleAccountYoyData(Id id){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.

        List<AggregateResult> ars = [
                SELECT  MAX(date__c)                    hpdDate,
                        CALENDAR_YEAR(date__c)          hpdYear,
                        CALENDAR_MONTH(date__c)         hpdMonth,
                        SUM( Location_Share__c )        locShare,
                        SUM( Funds_In__c )              fundsIn
                FROM    Hold_Per_Day__c
                Where   account__c       = :id
                and     RecordType.Name =   'Monthly HPD'
                GROUP BY CALENDAR_YEAR(date__c), CALENDAR_MONTH(date__c)
                ORDER BY CALENDAR_YEAR(date__c) DESC, CALENDAR_MONTH(date__c) DESC


        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShare');
            hpdWrapper.hpdDate                 = (Date)ar.get('hpdDate');
            hpdWrapper.hpdMonth                 = (Integer)ar.get('hpdMonth');
            hpdWrapper.hpdYear                  = (Integer)ar.get('hpdYear');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for account:'+id + ' for Single YoY pull';
        }
        dto.values.put(MAP_KEY_ACCOUNT_SINGLE_YOY_HPD,holdPerDayWrappers);
        return dto;
    }
}