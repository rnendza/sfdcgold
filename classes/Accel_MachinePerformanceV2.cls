/**
 * Created by Zach on 3/28/2019.
 */

public with sharing class Accel_MachinePerformanceV2 {

    public static final String MAP_KEY_ACCOUNT_LIST     = 'ACCOUNT_LIST';
    public static final String MAP_KEY_HPD_MONTHS       = 'HPD_WRAPPER_MONTHS';
    public static final String MAP_KEY_HPD_MACHINE_DAILY       = 'HPD_WRAPPER_MACHINE_DAILY';
    public static final String MAP_KEY_HPD_MACHINE_AGGREGATE      = 'HPD_WRAPPER_MACHINE_AGGREGATE';
    public static final String YTD_DATA = 'YTD_DATA';
    public static final String MTD_DATA = 'MTD_DATA';
    public static final String EST_DATA = 'EST_DATA';
    public static final String MACHINE_IMAGE_DATA = 'MACHINE_IMAGE_DATA';
    public static final String PREV_MACHINE_IMAGE_DATA = 'PREV_MACHINE_IMAGE_DATA';
    public static final String CITY_MACHINE_IMAGE_DATA = 'CITY_MACHINE_IMAGE_DATA';
    public static final String PREV_CITY_MACHINE_IMAGE_DATA = 'PREV_CITY_MACHINE_IMAGE_DATA';
    public static final String HISTORICAL_DATA = 'HISTORICAL_DATA';

    //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
    public static final String  ESTIMATED_REVENUE_MONTH_NAME        = 'ESTIMATED_REVENUE_MONTH_NAME';
    public static final String  REVENUE_MTD_MONTH_NAME              = 'REVENUE_MTD_MONTH_NAME';
    public static final String  REVENUE_YTD_YEAR                    = 'REVENUE_YTD_YEAR';
    //-- BELOW MOSTLY FOR DEBUGGING / UNIT TESTING
    public static final String  ADJUSTED_MONTH_START_DATE           = 'ADJUSTED_MONTH_START_DATE';
    public static final String  ADJUSTED_ESTIMATED_REVENUE_MONTH    = 'ADJUSTED_ESTIMATED_REVENUE_MONTH';
    public static final String  REVENUE_YTD_YEARSTART               = 'REVENUE_YTD_YEARSTART';
    public static final String  YESTERDAY_DATE                      = 'YESTERDAY_DATE';
    //--- Below returned in DTO merely for debugging
    public static final String  IS_HPD_DARK_ZONE                    = 'IS_HPD_DARK_ZONE';
    //  override the below in apex unit test (a hack to get around no current method such asTEST.RunAsDateTime() )
    //  @See isHpdDarkZone method in this class. Note this seems to be 2 hours behind when running in test
    //  rather then real world. @TODO is it taking on the timezone of the running user? which can differ in test cases?
    @TestVisible static Time    UNIT_TEST_CURRENT_TIME_OVERRIDE     = System.now().time().addHours(2);
    //------------ End above enhancement block. ---------------------


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
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes    = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Integer iLimit              = 500; //@TODO Custom setting?
        dto.values.put(MAP_KEY_ACCOUNT_LIST,AccountSvc.retrieveAccounts( accountTypes,iLimit ).values() );
        dto.isSuccess = true;
        return dto;
    }

    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveMonthlyHpdDates(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();


        List<AggregateResult> ars = [
                SELECT
                        date__c         hpdDate
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     RecordType.Name = 'Monthly HPD'
                group by date__c
                order by date__c DESC
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.hpdDate                  = (Date)ar.get('hpdDate');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Monthly HPD Dates pull';
        }
        dto.values.put(MAP_KEY_HPD_MONTHS,holdPerDayWrappers);

        dto.values.put(YESTERDAY_DATE, CommunityUtils.getMostRecentHpdDate() );
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        // used by the ui on init
//        Date yesterday  = Date.today().addDays(-1);
//        Date twoDaysAgo = Date.today().addDays(-2);
//        Boolean isHpdDarkZone = isHpdDarkZone();
//        //yesterday = Date.today().addDays(-1);
//        yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
//        dto.values.put(YESTERDAY_DATE,yesterday);
        //--------------------------------------------------------------------------------
//        Community_User_Setting__c  communityUserSetting;
//        try {
//            communityUserSetting = CommunityUserSettingsSvc.retrieveCommunityUserSettings();
//        } catch (System.QueryException qex) {
//            System.debug(LoggingLevel.ERROR,qex.getStackTraceString());
//            dto.technicalMsg = qex.getMessage();
//            dto.message = 'Could not find community Setting for User';
//        } catch (Warnings.InvalidCommunityUserException icuEx) {
//            System.debug(LoggingLevel.ERROR,icuEx.getStackTraceString());
//            dto.technicalMsg = icuEx.getMessage();
//            dto.message = 'Please contact an admin about your community account.';
//            //@TODO log error in accel errors object.
//        }
//        dto.values.put(CommunityConstants.COMMUNITY_SETTINGS,communityUserSetting);


        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveHistoricalData(Id id, String startDate, String endDate, String freq) {
        ResponseDto dto = new ResponseDto();
        List<Hold_Per_Day__c> hpd;
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        if(freq == 'Daily'){
            Date startD = Date.valueOf(startDate);
            Date endD = Date.valueOf(endDate);
            hpd = [
                    SELECT
                            Id,
                            Date__c,
                            Location_Share__c,
                            Net_Revenue__c,
                            Funds_In__c,
                           Funds_Out__c,
                           Amount_Played__c,
                            Amount_Won__c
                    FROM    Hold_Per_Day__c
                    WHERE   account__c = :id
                    and     RecordType.Name = 'Daily Aggregate'
                    and     date__c >= : startD
                    and     date__c <= : endD
                   order by date__c desc
            ];
            for(Hold_Per_Day__c ar : hpd) {
                HpdWrapper hpdWrapper = new HpdWrapper();
                hpdWrapper.hpdId                    =ar.id;
                hpdWrapper.locShare                 = ar.location_share__c;
                hpdWrapper.hpdDate                  = ar.date__c;
                hpdWrapper.netRevenue               = ar.net_revenue__c;
                hpdWrapper.fundsIn                 = ar.funds_in__c;
                hpdWrapper.fundsOut                 = ar.funds_out__c;
                hpdWrapper.amtPlayed                = ar.amount_played__c;
                hpdWrapper.amtWon                   = ar.amount_won__c;
                holdPerDayWrappers.add(hpdWrapper);
            }
            if(!holdPerDayWrappers.isEmpty()) {
                dto.isSuccess = true;
            } else {
                dto.technicalMsg = 'No HPDS for account:'+id + ' for Daily Historical Data pull';
            }
            dto.values.put(HISTORICAL_DATA,holdPerDayWrappers);
        }else if (freq == 'Monthly'){
            hpd = [
                    SELECT
                            Id,
                            Location_Share__c,
                            Date__c,
                            Net_Revenue__c,
                            Funds_In__c,
                            Funds_Out__c,
                            Amount_Played__c,
                            Amount_Won__c
                    FROM    Hold_Per_Day__c
                    WHERE   account__c = :id
                    and     RecordType.Name = 'Monthly HPD'
                    order by date__c desc
            ];
            for(Hold_Per_Day__c ar : hpd) {
                HpdWrapper hpdWrapper = new HpdWrapper();
                hpdWrapper.hpdId                    = ar.id;
                hpdWrapper.locShare                 = ar.location_share__c;
                hpdWrapper.hpdDate                  = ar.date__c;
                hpdWrapper.netRevenue               = ar.net_revenue__c;
                hpdWrapper.fundsIn                 = ar.funds_in__c;
                hpdWrapper.fundsOut                 = ar.funds_out__c;
                hpdWrapper.amtPlayed                = ar.amount_played__c;
                hpdWrapper.amtWon                   = ar.amount_won__c;
                holdPerDayWrappers.add(hpdWrapper);
            }
            if(!holdPerDayWrappers.isEmpty()) {
                dto.isSuccess = true;
            } else {
                dto.technicalMsg = 'No HPDS for account:'+id + ' for Monthly Historical Data pull';
            }
            dto.values.put(HISTORICAL_DATA,holdPerDaywrappers);

        }else if(freq == 'Weekly'){

        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAggregateMachineData(Id id, String startDate, String endDate){
        ResponseDto dto = new ResponseDto();
        Date startD = Date.valueOf(startDate);
        Date endD = Date.valueOf(endDate);

        List<AggregateResult> ars = [
                SELECT
                        MAX(Account__c)              accId,
                        MAX(Account__r.Name)            accName,
                        MAX(Account__r.ShippingStreet)  accStreet,
                        MAX(Account__r.ShippingCity)    accCity,
                        MAX(Asset__r.Model__c)          model,
                        Asset__c                  assetId,
                        SUM(Net_Revenue__c)             revenueSum,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(Amount_Played__c)           amtPlayedSum,
                        SUM(Amount_Won__c)              amtWonSum
                FROM    Hold_Per_Day__c
                WHERE   account__c = :id
                and     RecordType.Name = 'Daily HPD'
                and     date__c >= : startD
                and     date__c <= : endD
                group by Asset__c
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.assetId                  =(Id)ar.get('assetId');
            hpdWrapper.assetModel               = (String)ar.get('model');
            hpdWrapper.netRevenue               = (Decimal)ar.get('revenueSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.fundsOut                 =(Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amtPlayedSum');
            hpdWrapper.amtWon                   = (Decimal)ar.get('amtWonSum');
            hpdWrapper.accountId                =(Id)ar.get('accId');
            hpdWrapper.accountName              =(String)ar.get('accName');
            hpdWrapper.accountPhysicalStreet    =(String)ar.get('accStreet');
            hpdWrapper.accountPhysicalCity      =(String)ar.get('accCity');

            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for account:'+id + ' for Aggregate Machine pull';
        }
        dto.values.put(MAP_KEY_HPD_MACHINE_AGGREGATE,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveDailyMachineData(Id id, String startDate, String endDate){
        ResponseDto dto = new ResponseDto();
        Date startD = Date.valueOf(startDate);
        Date endD = Date.valueOf(endDate);

        List<Hold_Per_Day__c> ars = [
                SELECT
                        Account__c,
                        Net_Revenue__c,
                        Location_Share__c,
                        Funds_In__c,
                        Funds_Out__c,
                        Amount_Played__c,
                        Amount_Won__c,
                        Date__c,
                        Asset__c,
                        Asset__r.Model__c
                FROM    Hold_Per_Day__c
                WHERE   Account__c = :id
                and     RecordType.Name = 'Daily HPD'
                and     Date__c >= : startD
                and     Date__c <= : endD
                order by asset__c ASC
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(Hold_Per_Day__c  ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.hpdDate                  =(Date)ar.Date__c;
            hpdWrapper.assetId                  =(Id)ar.Asset__c;
            hpdWrapper.assetModel               =(String)ar.Asset__r.Model__c;
            hpdWrapper.netRevenue               = (Decimal)ar.Net_Revenue__c;
            hpdWrapper.locShare                 = (Decimal)ar.Location_Share__c;
            hpdWrapper.fundsIn                 = (Decimal)ar.Funds_In__c;
            hpdWrapper.fundsOut                 =(Decimal)ar.Funds_Out__c;
            hpdWrapper.amtPlayed                = (Decimal)ar.Amount_Played__c;
            hpdWrapper.amtWon                   = (Decimal)ar.Amount_Won__c;
            hpdWrapper.accountId                =(Id)ar.Account__c;

            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for account:'+id + ' for Daily pull';
        }
        dto.values.put(MAP_KEY_HPD_MACHINE_DAILY,holdPerDayWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveMachineImageData(Id id, String startDate, String endDate){
        ResponseDto dto = new ResponseDto();
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        List<HpdWrapper> prevMachineData = new List<HpdWrapper>();
        List<HpdWrapper> cityMachineData = new List<HpdWrapper>();
        List<HpdWrapper> prevCityMachineData = new List<HpdWrapper>();
        Date yesterdayD ;
        Date endDateD;
        Date prevYearYesterday;
        Date prevYearEndDate;
        Boolean isHpdDarkZone = isHpdDarkZone();

//        yesterdayD = (isHpdDarkZone ? Date.today().addDays(-2) : Date.today().addDays(-1));
//        endDateD = (isHpdDarkZone ? Date.today().addDays(-92) : Date.today().addDays(-91));
        Date hpdDate = CommunityUtils.getMostRecentHpdDate();
        yesterdayD = hpdDate;
        endDateD = hpdDate.addDays(-91);
        //missing leap year calculations, how granular/import is it really though..
//        prevYearYesterday = (isHpdDarkZone ? Date.today().addDays(-367) : Date.today().addDays(-366));
//        prevYearEndDate = (isHpdDarkZone ? Date.today().addDays(-457) : Date.today().addDays(-456));
        prevYearYesterday = yesterdayD.addDays(-366);
        prevYearEndDate =  yesterdayD.addDays(-456);

        List<Account> accAddr;
        accAddr = [select ShippingCity, Filtered_Location_Type__c from Account where id = :id limit 1];
        String myCity = accAddr[0].ShippingCity;
        String myType = accAddr[0].Filtered_Location_Type__c;

        //first get the machines live at the location
        Map<Id, Asset> mAssets = new Map<Id, Asset>([
                select id
                from asset
                where id in (select asset__c from hold_per_day__c where date__c = :yesterdayD and account__c = :id and recordtype.name = 'Daily HPD')
        ]);
        Set<Id> machines = mAssets.keySet();
        List<String>models = new List<String>();

        for(Asset machine : [select model__c from asset where id in (select asset__c from hold_per_day__c where date__c = :yesterdayD and account__c = :id and recordtype.name = 'Daily HPD')]){
            models.add(machine.model__c);
        }


        //now get my machines 90d average
        List<AggregateResult> myThreeMonthAverages = [
                SELECT
                        count_distinct(id) numDays,
                        MAX(asset__r.model__c) model,
                        MAX(asset__r.name) igb,
                        MAX(asset__r.vgt_live_date__c) liveDate,
                        AVG(funds_In__c) fundsIn
                FROM    hold_per_day__c
                WHERE   account__c = :id
                and     date__c >= :endDateD
                and	date__c <= :yesterdayD
                and recordtype.name = 'Daily HPD'
                and asset__c in :machines
                group by asset__c

        ];
        //now get my machine 90d average last year
        List<AggregateResult> myThreeMonthAveragesLastYear = [
                SELECT
                        count_distinct(id) numDays,
                        MAX(asset__r.model__c) model,
                        MAX(asset__r.name) igb,
                        MAX(asset__r.vgt_live_date__c) liveDate,
                        AVG(funds_In__c) fundsIn
                FROM    hold_per_day__c
                WHERE   account__c = :id
                and     date__c >= :prevYearEndDate
                and	date__c <= :prevYearYesterday
                and recordtype.name = 'Daily HPD'
                and asset__c in :machines
                group by asset__c

        ];
        //now get city machines 90d average
        /*List<AggregateResult> cityThreeMonthAverages = [
                SELECT
                        asset__r.model__c model,
                        AVG(funds_In__c) fundsIn
                FROM    hold_per_day__c
                WHERE   Account__r.Filtered_Location_Type__c = :myType
                and     date__c >= :endDateD
                and	date__c <= :yesterdayD
                and recordtype.name = 'Daily HPD'
                and asset__r.model__c in :models
                group by asset__r.model__c
        ];
        */
        //now get city machines 90d average
        /* List<AggregateResult> cityThreeMonthAveragesLastYear = [
                SELECT
                        asset__r.model__c model,
                        AVG(funds_In__c) fundsIn
                FROM    hold_per_day__c
                WHERE   Account__r.Filtered_Location_Type__c = :myType
                and     date__c >= :prevYearEndDate
                and	date__c <= :prevYearYesterday
                and recordtype.name = 'Daily HPD'
                and asset__r.model__c in :models
                group by asset__r.model__c
        ];
        */
        for(AggregateResult ar : myThreeMonthAverages) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.distinctDateCount         = (Integer)ar.get('numDays');
            hpdWrapper.assetModel                = (String)ar.get('model');
            hpdWrapper.hpdDate                = (Date)ar.get('liveDate');
            hpdWrapper.vgtUid                    = (String)ar.get('igb');
            hpdWrapper.fundsIn                      =(Decimal)ar.get('fundsIn');
            holdPerDayWrappers.add(hpdWrapper);
        }

        for(AggregateResult ar : myThreeMonthAveragesLastYear) {
            HpdWrapper h = new HpdWrapper();
            h.distinctDateCount         = (Integer)ar.get('numDays');
            h.assetModel                = (String)ar.get('model');
            h.hpdDate               = (Date)ar.get('liveDate');
            h.vgtUid                    = (String)ar.get('igb');
            h.fundsIn                      =(Decimal)ar.get('fundsIn');
            prevMachineData.add(h);
        }
        for(AggregateResult ar : [
                SELECT
                        machine_model__c model,
                        AVG(funds_In__c) fundsIn
                FROM    hold_per_day__c
                WHERE   machine_location_type__c = :myType
                and recordtype.name = 'Model Metric'
                and metric_type__c = 'Statewide90DAverage'
                and machine_model__c in :models
                group by machine_model__c
        ]) {
            HpdWrapper c = new HpdWrapper();
            c.assetModel                = (String)ar.get('model');
            c.fundsIn                      =(Decimal)ar.get('fundsIn');
            cityMachineData.add(c);
        }
        for(AggregateResult ar : [
                SELECT
                        machine_model__c model,
                        AVG(funds_In__c) fundsIn
                FROM    hold_per_day__c
                WHERE   machine_location_type__c = :myType
                and recordtype.name = 'Model Metric'
                and metric_type__c = 'Statewide90DAveragePrevYear'
                and machine_model__c in :models
                group by machine_model__c
        ]) {
            HpdWrapper cl = new HpdWrapper();
            cl.assetModel                = (String)ar.get('model');
            cl.fundsIn                      =(Decimal)ar.get('fundsIn');
            prevCityMachineData.add(cl);
        }

        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Data missing for Machine Image Data calculations';
        }
        dto.values.put(MACHINE_IMAGE_DATA,holdPerDayWrappers);
        dto.values.put(PREV_MACHINE_IMAGE_DATA,prevMachineData);
        dto.values.put(CITY_MACHINE_IMAGE_DATA,cityMachineData);
        dto.values.put(PREV_CITY_MACHINE_IMAGE_DATA,prevCityMachineData);
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveYTDRevenue(Id id){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        Date yesterday ;
        Date yearStart;
        Date prevYesterday;
        Date prevStart;

        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        yesterday  = Date.today().addDays(-1);
        Date twoDaysAgo = Date.today().addDays(-2);
        Boolean isHpdDarkZone = isHpdDarkZone();
        //yesterday = Date.today().addDays(-1);
        //yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
        yesterday = CommunityUtils.getMostRecentHpdDate();
        //--

        yearStart = Date.newInstance(yesterday.year(), 1, 1);
        if(yesterday.day()==29 && yesterday.month()==2){
            prevYesterday = Date.newInstance(yesterday.year()-1, yesterday.month(), yesterday.day()-1);
        }else{
            prevYesterday = Date.newInstance(yesterday.year()-1, yesterday.month(), yesterday.day());
        }
        prevStart= Date.newInstance(yesterday.year()-1, 1, 1);

        List<AggregateResult> ars = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c  = :id
                and     date__c >= :yearStart
                and     date__c <= :yesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        List<AggregateResult> yars = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c  = :id
                and     date__c >= :prevStart
                and     date__c <= :prevYesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];



        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.netRevenue                 = (Decimal)ar.get('netRev');
            hpdWrapper.hpdYear                 = yesterday.year();
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : yars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.netRevenue                 = (Decimal)ar.get('netRev');
            hpdWrapper.hpdYear                 = prevYesterday.year();
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Data missing for YTD calculations';
        }
        dto.values.put(YTD_DATA,holdPerDayWrappers);
        //  8-21-2019  @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        dto.values.put(IS_HPD_DARK_ZONE,isHpdDarkZone);
        dto.values.put(YESTERDAY_DATE,yesterday);
        dto.values.put(REVENUE_YTD_YEARSTART,yearStart);
        dto.values.put(REVENUE_YTD_YEAR,yearStart.year());
        //---
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveMTDRevenue(Id id){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        Date yesterday ;
        Date monthStart;
        //used in % math
        Date prevStart;
        //used for raw value calc display
        Date prevYesterday;
        //used in % math
        Date validYesterday;
        Date validPrevStart;
        Date validPrevYesterday;

        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        yesterday  = Date.today().addDays(-1);
        Date twoDaysAgo = Date.today().addDays(-2);
        Boolean isHpdDarkZone = isHpdDarkZone();
        //yesterday = Date.today().addDays(-1);
        //yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
        yesterday = CommunityUtils.getMostRecentHpdDate();
        //--
        validYesterday=yesterday;
        monthStart = Date.newInstance(yesterday.year(), yesterday.month(), 1);
        if((yesterday.month()==3) && (yesterday.day()==29 || yesterday.day()==30 || yesterday.day()==31)){
            //feb broken
            Date prevMonth = Date.newInstance(yesterday.year(), yesterday.month()-1, 1);
            prevYesterday = Date.newInstance(yesterday.year(), yesterday.month()-1, Date.daysInMonth(prevMonth.year(), prevMonth.month()));
            validYesterday = Date.newInstance(yesterday.year(), yesterday.month(), Date.daysInMonth(prevMonth.year(), prevMonth.month()));
        }else if(yesterday.day()==31 && Date.daysInMonth(yesterday.year(), yesterday.month()-1)!= 31){
            //do math on just 30 days
            validYesterday = Date.newInstance(yesterday.year(), yesterday.month()-1, yesterday.day()-1);
            prevYesterday = Date.newInstance(yesterday.year(), yesterday.month()-1, yesterday.day()-1);
        }else{
            prevYesterday = Date.newInstance(yesterday.year(), yesterday.month()-1, yesterday.day());
        }

        prevStart= Date.newInstance(yesterday.year(), yesterday.month()-1, 1);

        if(yesterday.day()==29 && yesterday.month()==2){
            //yesterday was leap year, obviously previous year wont have a feb 29
            validPrevYesterday = Date.newInstance(yesterday.year()-1, yesterday.month(), yesterday.day()-1);
        }else{
            validPrevYesterday = Date.newInstance(yesterday.year()-1, yesterday.month(), yesterday.day());
        }
        validPrevStart = Date.newInstance(yesterday.year()-1, yesterday.month(), 1);

        List<AggregateResult> netRevenueValue = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c  = :id
                and     date__c >= :monthStart
                and     date__c <= :yesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        List<AggregateResult> netRevenueValidCalc = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c  = :id
                and     date__c >= :monthStart
                and     date__c <= :validYesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        List<AggregateResult> prevMonth = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c  = :id
                and     date__c >= :prevStart
                and     date__c <= :prevYesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        List<AggregateResult> prevYear = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c  = :id
                and     date__c >= :validPrevStart
                and     date__c <= :validPrevYesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];



        for(AggregateResult ar : netRevenueValue) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.netRevenue                 = (Decimal)ar.get('netRev');
            hpdWrapper.hpdMonth                 = yesterday.month();
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : netRevenueValidCalc) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.netRevenue                 = (Decimal)ar.get('netRev');
            hpdWrapper.hpdMonth                 = monthStart.month();
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : prevMonth) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.netRevenue                 = (Decimal)ar.get('netRev');
            hpdWrapper.hpdMonth                 = prevYesterday.Month();
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : prevYear) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.netRevenue                 = (Decimal)ar.get('netRev');
            hpdWrapper.hpdMonth                 = validPrevStart.month();
            holdPerDayWrappers.add(hpdWrapper);
        }
        /*
        dto array should look like this
        array[0]=raw total net revenue to display as text
        array[1]=raw total net revenue to be used in m/m calc
        array[2]=may not exist for new locations, if it does use it with array[1] for m/m calc
        array[3]=may not exist for newer locations, if it does use it with array[0] for y/y calc
        use .length() function ==3, ==4 to figure out what values exist, array[3] should not exist
        if array[2] doesnt, making the length function easier than doing any parsing
         */
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Data missing for YTD calculations';
        }
        dto.values.put(MTD_DATA,holdPerDayWrappers);
        //  8-21-2019 Translate month value from monthStart and push into monthName and push to UI.
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        //  can't translate a date on day1 to datetime as there is no time and utc / timezone
        //  will push it back to last month.. add 1 day to be sure!
        Date adjustedMonthStartMonth = monthStart.addDays(1);
        dto.values.put( ADJUSTED_MONTH_START_DATE, adjustedMonthStartMonth );
        dto.values.put(IS_HPD_DARK_ZONE,isHpdDarkZone);
        dto.values.put(YESTERDAY_DATE,yesterday);
        dto.values.put( REVENUE_MTD_MONTH_NAME, CommunityUtils.retrieveFullMonthNameDisplay( adjustedMonthStartMonth ) );
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveESTRevenue(Id id) {
        ResponseDto dto = new ResponseDto();
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        Date yesterday ;
        Date estMonth;
        Date estPrevMonth;
        Date estPrevMonthEnd;
        Date estPrevYearMonth;
        Date estPrevYearPrevMonth;
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        //yesterday  = Date.today().addDays(-1);

        Boolean isHpdDarkZone = isHpdDarkZone();
        //yesterday = Date.today().addDays(-1);
        //yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
        Date twoDaysAgo = Date.today().addDays(-2);
        yesterday = CommunityUtils.getMostRecentHpdDate();
        //--
        estMonth = Date.newInstance(yesterday.year(), yesterday.month(), 1);
        estPrevMonth = Date.newInstance(yesterday.year(), yesterday.month() - 1, 1);
        estPrevMonthEnd = Date.newInstance(yesterday.year(), yesterday.month() - 1, Date.daysInMonth(yesterday.year(), yesterday.month() - 1));
        estPrevYearMonth = Date.newInstance(yesterday.year() - 1, yesterday.month(), 1);
        estPrevYearPrevMonth = Date.newInstance(yesterday.year() - 1, yesterday.month() - 1, 1);

        List<AggregateResult> prevMonthRev = [
                select
                        max(account__r.name) accName,
                        sum(nti__c) netRevenue,
                        min(date__c) date
                from hold_per_day__c
                where date__c >= :estPrevMonth
                and date__c <= :estPrevMonthEnd
                and recordtype.name = 'Daily Aggregate'
                and account__c = :id
                group by account__c
        ];
        //@TODO Why no grouping here? defect or intended and just bad variable naming of ar on the assignment loop?
        //why no date range?
        System.debug('ACCEL rjn estPrevYearMonth='+estPrevYearMonth);
        List<Hold_Per_Day__c> prevYearMonthRev = [
                select
                        account__r.name,
                        nti__c, date__c
                from hold_per_day__c
                where date__c = :estPrevYearMonth
                and recordtype.name = 'Monthly HPD'
                and account__c = :id
        ];
        //@TODO Why no grouping here? defect or intended and just bad variable naming of ar on the assignment loop?
        System.debug('ACCEL rjn estPrevYearPrevMonth='+estPrevYearPrevMonth);
        //why no date range?
        List<Hold_Per_Day__c> prevYearPrevMonthRev = [
                select
                        account__r.name,
                        nti__c, date__c
                from hold_per_day__c
                where date__c = :estPrevYearPrevMonth
                and recordtype.name = 'Monthly HPD'
                and account__c = :id
        ];

        for (AggregateResult ar : prevMonthRev) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String) ar.get('accName');
            hpdWrapper.hpdDate = (Date) ar.get('date');
            hpdWrapper.netRevenue = (Decimal) ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }
        for (Hold_Per_Day__c ar : prevYearPrevMonthRev) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String) ar.account__r.name;
            hpdWrapper.hpdDate = (Date) ar.date__c;
            hpdWrapper.netRevenue = (Decimal) ar.nti__c;
            holdPerDayWrappers.add(hpdWrapper);
        }
        for (Hold_Per_Day__c ar : prevYearMonthRev) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String) ar.account__r.name;
            hpdWrapper.hpdDate = (Date) ar.date__c;
            hpdWrapper.netRevenue = (Decimal) ar.nti__c;
            holdPerDayWrappers.add(hpdWrapper);
        }

        //dto array should be
        //array[0] = last months value
        //array[1] = last year last months value
        //array[2] = last year month value

        //array[2]-array[1] should give you seasonality
        //apply seasonality to array[0] in javascript to estimate current month total revenue

        if (!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Data missing for EST Revenue calculations';
        }
        dto.values.put(EST_DATA, holdPerDayWrappers);
        //  8-20-2019 Translate month value from estMonth and push into monthName and push to UI.
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        //  Note. We can't translate a date on day1 to datetime as there is no time and utc / timezone
        //  will push it back to last month.. add 1 day to be sure!
        Date adjustedEstimatedRevenueMonth = estMonth.addDays(1);
        dto.values.put( ADJUSTED_ESTIMATED_REVENUE_MONTH, adjustedEstimatedRevenueMonth );
        dto.values.put(IS_HPD_DARK_ZONE,isHpdDarkZone);
        dto.values.put(YESTERDAY_DATE,yesterday);
        dto.values.put(ESTIMATED_REVENUE_MONTH_NAME, CommunityUtils.retrieveFullMonthNameDisplay(adjustedEstimatedRevenueMonth));
        //----------------------------------------

        return dto;
    }

    /* public static ResponseDto retrieveESTRevenue(Id id){
        ResponseDto dto = new ResponseDto();
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        Date yesterday ;
        Date estMonth;
        Date estMonthEnd;
        Date estPrevMonth;
        Date estPrevMonthEnd;
        Date estPrevYearMonth;
        Date estPrevYearMonthEnd;
        Date estPrevYearPrevMonth;
        Date estPrevYearPrevMonthEnd;

        yesterday = Date.today().addDays(-1);
        estMonth = Date.newInstance(yesterday.year(), yesterday.month(), 1);
        estMonthEnd = Date.newInstance(yesterday.year(), yesterday.month(), Date.daysInMonth(yesterday.year(), yesterday.month()));
        estPrevMonth = Date.newInstance(yesterday.year(), yesterday.month()-1, 1);
        estPrevMonthEnd = Date.newInstance(yesterday.year(), yesterday.month()-1, Date.daysInMonth(yesterday.year(), yesterday.month()-1));
        estPrevYearMonth = Date.newInstance(yesterday.year()-1, yesterday.month(), 1);
        estPrevYearMonthEnd = Date.newInstance(yesterday.year()-1, yesterday.month(), Date.daysInMonth(yesterday.year()-1, yesterday.month()));
        estPrevYearPrevMonth = Date.newInstance(yesterday.year()-1, yesterday.month()-1, 1);
        estPrevYearPrevMonthEnd = Date.newInstance(yesterday.year()-1, yesterday.month()-1, Date.daysInMonth(yesterday.year()-1, yesterday.month()-1));



        List<AggregateResult> prevMonthRev = [
                select
                        max(account__r.name) accName,
                        count(date__c) numRecords,
                        count_distinct(asset__c) numAssets,
                        SUM(nti__c) netRevenue,
                        max(day_of_week__c) day,
                        DAY_IN_WEEK(date__c) dayNum
                from hold_per_day__c
                where date__c >= :estPrevMonth
                and date__c <= :estPrevMonthEnd
                and recordtype.name = 'Daily HPD'
                and account__c=:id
                GROUP BY day_in_week(date__c)
        ];
        List<AggregateResult> prevYearMonthRev = [
                select
                        max(account__r.name) accName,
                        count(date__c) numRecords,
                        count_distinct(asset__c) numAssets,
                        SUM(nti__c) netRevenue,
                        max(day_of_week__c) day,
                        DAY_IN_WEEK(date__c) dayNum
                from hold_per_day__c
                where date__c >= :estPrevYearMonth
                and date__c <= :estPrevYearMonthEnd
                and recordtype.name = 'Daily HPD'
                and account__c=:id
                GROUP BY day_in_week(date__c)
        ];
        List<AggregateResult> prevYearPrevMonthRev = [
                select
                        max(account__r.name) accName,
                        count(date__c) numRecords,
                        count_distinct(asset__c) numAssets,
                        SUM(nti__c) netRevenue,
                        max(day_of_week__c) day,
                        DAY_IN_WEEK(date__c) dayNum
                from hold_per_day__c
                where date__c >= :estPrevYearPrevMonth
                and date__c <= :estPrevYearPrevMonthEnd
                and recordtype.name = 'Daily HPD'
                and account__c=:id
                GROUP BY day_in_week(date__c)
        ];

        for(AggregateResult ar : prevMonthRev){
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String)ar.get('accName');
            //distinctdatecount not really distinct, just using as integer variable BAD NEED FIX
            hpdWrapper.distinctDateCount = (Integer)ar.get('numRecords');
            //hpdyear not really year, just using as integer variable BAD NEED FIX
            hpdWrapper.hpdYear = (Integer)ar.get('numAssets');
            hpdWrapper.weekday = (String)ar.get('day');
            //hpdmonth not really month, just using as integer variable BAD NEED FIX
            hpdWrapper.hpdMonth = (Integer)ar.get('dayNum');
            hpdWrapper.netRevenue = (Decimal)ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : prevYearPrevMonthRev){
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String)ar.get('accName');
            //distinctdatecount not really distinct, just using as integer variable BAD NEED FIX
            hpdWrapper.distinctDateCount = (Integer)ar.get('numRecords');
            //hpdyear not really year, just using as integer variable BAD NEED FIX
            hpdWrapper.hpdYear = (Integer)ar.get('numAssets');
            hpdWrapper.weekday = (String)ar.get('day');
            //hpdmonth not really month, just using as integer variable BAD NEED FIX
            hpdWrapper.hpdMonth = (Integer)ar.get('dayNum');
            hpdWrapper.netRevenue = (Decimal)ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : prevYearMonthRev){
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String)ar.get('accName');
            //distinctdatecount not really distinct, just using as integer variable BAD NEED FIX
            hpdWrapper.distinctDateCount = (Integer)ar.get('numRecords');
            //hpdyear not really year, just using as integer variable BAD NEED FIX
            hpdWrapper.hpdYear = (Integer)ar.get('numAssets');
            hpdWrapper.weekday = (String)ar.get('day');
            //hpdmonth not really month, just using as integer variable BAD NEED FIX
            hpdWrapper.hpdMonth = (Integer)ar.get('dayNum');
            hpdWrapper.netRevenue = (Decimal)ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }

        //dto array should be
        //array[0-6] = last months values
        //array[7-13] = last year last months values
        //array[14-20] = last year months values

        //array[14-20]-array[7-13] should give you seasonality
        //apply seasonality to array[0-6] in javascript to estimate current month total revenue

        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Data missing for EST Revenue calculations';
        }
        dto.values.put(EST_DATA,holdPerDayWrappers);
        return dto;

    }
    */

    /**
     * @see CommunityUtils
     */
    @TestVisible
    private static Boolean isHpdDarkZone() {
        return  CommunityUtils.getHpdDark();
    }
}