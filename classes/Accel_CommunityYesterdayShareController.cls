/**
 * Notes:
 *
 * @TODO Map<Id, Account> mAccountsByIds should probably only be run once onload and then passed back up from the
 * client as a list of ids to the methods assuming we are not calling these methods from some other SS Apex.
 * One would have to run some query diagnotics but seems a waste to call the same thing over and over again.
 */
public with sharing class Accel_CommunityYesterdayShareController {

    public static final String ALL_LOC_YESTERDAY_SUM = 'ALL_LOC_YESTERDAY_SUM';
    public static final String ALL_LOC_CURR_WEEK_SUM = 'ALL_LOC_CURR_WEEK_SUM';
    public static final String ALL_LOC_LAST_WEEK_SUM = 'ALL_LOC_LAST_WEEK_SUM';
    public static final String ALL_LOC_WEEKDAY_AVERAGE = 'ALL_LOC_WEEKDAY_AVERAGE';
    public static final String YTD_DATA = 'YTD_DATA';
    public static final String MTD_DATA = 'MTD_DATA';
    public static final String EST_DATA = 'EST_DATA';

    //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
    public static final String  REVENUE_MTD_MONTHNAME           = 'REVENUE_MTD_MONTHNAME';
    public static final String  REVENUE_YTD_YEAR                = 'REVENUE_YTD_YEAR';
    public static final String  REVENUE_MTD_YEAR                = 'REVENUE_MTD_YEAR';
    public static final String  VALID_YESTERDAY_DATE            = 'VALID_YESTERDAY_DATE';
    public static final String  YESTERDAY_DATE                  = 'YESTERDAY_DATE'; // unit test only
    public static final String CURR_WEEK_LABEL                  = 'CURR_WEEK_LABEL';
    public static final String LAST_WEEK_LABEL                  = 'LAST_WEEK_LABEL';
    //--- Below returned in DTO merely for debugging
    public static final String  IS_HPD_DARK_ZONE                = 'IS_HPD_DARK_ZONE';
    public static final String ADJUSTED_MONTH_START_DATE        = 'ADJUSTED_MONTH_START_DATE';

    //  override the below in apex unit test (a hack to get around no current method such asTEST.RunAsDateTime() )
    //  @See isHpdDarkZone method in this class. Note this seems to be 2 hours behind when running in test
    //  rather then real world. @TODO is it taking on the timezone of the running user? which can differ in test cases?
    @TestVisible static Time    UNIT_TEST_CURRENT_TIME_OVERRIDE = System.now().time().addHours(2);
    //Holds Date.today() as opposed to using Date.today() everywhere (allows for override for testing)
    @TestVisible static Date    CURRENT_DATE_OVERRIDE           = Date.today();
    //------------ End above enhancement block. ---------------------
    //https://accel-entertainment.monday.com/boards/286658657/pulses/294459025
    public static final String  CONTACT_PROFILE_SETTINGS        = 'CONTACT_PROFILE_SETTINGS';
    //--------

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
        } catch (System.QueryException qex) {
            System.debug(LoggingLevel.ERROR, qex.getStackTraceString());
            dto.technicalMsg = qex.getMessage();
            dto.message = 'Could not find community Setting for User';
        }
        dto.values.put(CommunityConstants.COMMUNITY_SETTINGS, communityUserSetting);
        return dto;
    }
    /**
     * Sample of aggregate query. your gonna have to play the same yesterday bs probably here as well.
     *
     * Returning HpdWrapper will abstract the client from Hold_Per_Day__c so that no client mods need to be made
     * when searching data source. ie. external object / grax etc.etc.
     *
     * @see TEST_CommunityYesterdayShareController for usage.
     *
     * @return ResponseDto containing a list of HpdWrappers grouped by accountId
     * @see ResponseDto
     * @see HpdWrapper
     */
    @AuraEnabled
    public static ResponseDto retrieveYesterdaysAggregatedLocationTotals() {
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();

        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        Date yesterday          = CURRENT_DATE_OVERRIDE.addDays(-1);
        Date twoDaysAgo         = CURRENT_DATE_OVERRIDE.addDays(-2);
//        Boolean isHpdDarkZone   = isHpdDarkZone();
        Boolean isHpdDarkZone   = CommunityUtils.getHpdDark();
//        Date hpdDate            = ( isHpdDarkZone ? twoDaysAgo : yesterday );
//        yesterday               = hpdDate; //<-- important for unit test
        yesterday = CommunityUtils.getMostRecentHpdDate();
        Date hpdDate = yesterday;
        //-------------------------------------------------------------------------------
        List<AggregateResult> ars = [
                SELECT
                        Account__c,
                        MAX(Account__r.name)            accName,
                        MAX(Account__r.ShippingStreet)  accountPhysicalStreet,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(NTI__c)                     ntiSum,
                        SUM(Amount_Played__c)           amountPlayedSum,
                        SUM(Amount_Won__c)              amountWonSum,
                        MAX(Date__c)                    hpdDate
                FROM    Hold_Per_Day__c
                WHERE   Date__c = :hpdDate
                and     account__c in :visibleAccountIds
                // and     RecordType.Name = 'Daily HPD' https://accel-entertainment.monday.com/boards/286658657/pulses/318958909
                AND     RecordType.Name = 'Daily Aggregate'
                GROUP BY Account__c
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                = (Id)ar.get('Account__c');
            hpdWrapper.accountPhysicalStreet    = (String)ar.get('accountPhysicalStreet'); //may have to check for nulls?
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                  = (Date)ar.get('hpdDate');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.fundsOut                 = (Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amountPlayedSum');
            hpdWrapper.amtWon                 = (Decimal)ar.get('amountWonSum');
            hpdWrapper.netRevenue                = (Decimal)ar.get('ntiSum');
            hpdWrapper.accountName              = (String)ar.get('accName');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for YESTERDAY';
        }
        dto.values.put(ALL_LOC_YESTERDAY_SUM,holdPerDayWrappers);
        //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        dto.values.put(IS_HPD_DARK_ZONE,isHpdDarkZone);
        dto.values.put(YESTERDAY_DATE, yesterday);             //returned for debugging / unit testing.
        //---------------
        return dto;
    }

    @AuraEnabled
    public static Integer getNumAccounts(){
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        return visibleAccountIds.size();
    }
    @AuraEnabled
    public static ResponseDto retrieveCurrWeekAggregatedLocationTotals(String d) {
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        Date hpdDate = Date.parse(d);
        Date weekStart =hpdDate.toStartOfWeek();
        Date weekEnd = weekStart.addDays(6);
        String currWeekLabel = weekStart.format()+' - '+weekEnd.format();
        //-------------------------------------------------------------------------------
        List<AggregateResult> ars = [
                SELECT
                        Account__c,
                        MAX(Account__r.name)            accName,
                        MAX(Account__r.ShippingStreet)  accountPhysicalStreet,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(NTI__c)                     ntiSum,
                        SUM(Amount_Played__c)           amountPlayedSum,
                        SUM(Amount_Won__c)              amountWonSum,
                        MAX(Date__c)                    hpdDate
                FROM    Hold_Per_Day__c
                WHERE   Date__c >= :weekStart
                and     Date__c <= :weekEnd
                and     account__c in :visibleAccountIds
                // and     RecordType.Name = 'Daily HPD' https://accel-entertainment.monday.com/boards/286658657/pulses/318958909
                AND     RecordType.Name = 'Daily Aggregate'
                GROUP BY Account__c
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                = (Id)ar.get('Account__c');
            hpdWrapper.accountPhysicalStreet    = (String)ar.get('accountPhysicalStreet'); //may have to check for nulls?
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                  = (Date)ar.get('hpdDate');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.fundsOut                 = (Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amountPlayedSum');
            hpdWrapper.amtWon                 = (Decimal)ar.get('amountWonSum');
            hpdWrapper.netRevenue                = (Decimal)ar.get('ntiSum');
            hpdWrapper.accountName              = (String)ar.get('accName');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Curr Week Totals';
        }
        dto.values.put(CURR_WEEK_LABEL, currWeekLabel);
        dto.values.put(ALL_LOC_CURR_WEEK_SUM,holdPerDayWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveLastWeekAggregatedLocationTotals(String d) {
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();

        Date hpdDate = Date.parse(d).addDays(-7);
        Date weekStart =hpdDate.toStartOfWeek();
        Date weekEnd = weekStart.addDays(6);
        String lastWeekLabel = weekStart.format()+' - '+weekEnd.format();
        //-------------------------------------------------------------------------------
        List<AggregateResult> ars = [
                SELECT
                        Account__c,
                        MAX(Account__r.name)            accName,
                        MAX(Account__r.ShippingStreet)  accountPhysicalStreet,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(NTI__c)                     ntiSum,
                        SUM(Amount_Played__c)           amountPlayedSum,
                        SUM(Amount_Won__c)              amountWonSum,
                        MAX(Date__c)                    hpdDate
                FROM    Hold_Per_Day__c
                WHERE   Date__c >= :weekStart
                and     Date__c <= :weekEnd
                and     account__c in :visibleAccountIds
                // and     RecordType.Name = 'Daily HPD' https://accel-entertainment.monday.com/boards/286658657/pulses/318958909
                AND     RecordType.Name = 'Daily Aggregate'
                GROUP BY Account__c
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                = (Id)ar.get('Account__c');
            hpdWrapper.accountPhysicalStreet    = (String)ar.get('accountPhysicalStreet'); //may have to check for nulls?
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.hpdDate                  = (Date)ar.get('hpdDate');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.fundsOut                 = (Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amountPlayedSum');
            hpdWrapper.amtWon                 = (Decimal)ar.get('amountWonSum');
            hpdWrapper.netRevenue                = (Decimal)ar.get('ntiSum');
            hpdWrapper.accountName              = (String)ar.get('accName');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Last Week Totals';
        }
        dto.values.put(LAST_WEEK_LABEL, lastWeekLabel);
        dto.values.put(ALL_LOC_LAST_WEEK_SUM,holdPerDayWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveYesterdayAverageTotals() {
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        Set<Date> ds = new Set<Date>();
        Date d ;
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        //  note yesterday stays the same in this one as opposed to other methods due to different internal calcs
        //  in the original controller method.
        Date yesterday = CURRENT_DATE_OVERRIDE.addDays(-1);
        Boolean isHpdDarkZone = isHpdDarkZone();
        //-------------------------------------------------------------------------------

        //add last 14 same weekdays (91 days in the past) to date set, inclusive of yesterday (i=0)
        for (Integer i = 0; i <= 91; i = i + 7) {
            if (!isHpdDarkZone) {
                //original which had Date.today()
                d = CURRENT_DATE_OVERRIDE.addDays(-(i + 1));
            } else {
                //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
                d = yesterday.addDays(-(i + 1));
                //-------------------------------------------------------------------------------
            }
            ds.add(d);
        }
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        Date dy;
        if (!isHpdDarkZone) {
            //original
            dy = CURRENT_DATE_OVERRIDE.addDays(-1);
        } else {
            dy = yesterday.addDays(-1);
        }
        //---
        Datetime dt = Datetime.newInstance(dy.year(), dy.month(), dy.day());
        String dow = dt.format('EEEE');
        List<AggregateResult> ars = [
                SELECT
                        Date__c hpdDate,
                        SUM(Funds_In__c) fundsInSum
                FROM Hold_Per_Day__c
                WHERE Date__c in :ds
                and account__c in :visibleAccountIds
                //and RecordType.Name = 'Daily HPD'
                // and     RecordType.Name = 'Daily HPD' https://accel-entertainment.monday.com/boards/286658657/pulses/318958909
                AND     RecordType.Name = 'Daily Aggregate'
                GROUP BY Date__c
                order by Date__c DESC
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for (AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.fundsIn = (Decimal) ar.get('fundsInSum');
            hpdWrapper.hpdDate = (Date) ar.get('hpdDate');
            hpdWrapper.weekday = dow;
            holdPerDayWrappers.add(hpdWrapper);
        }
        if (!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:' + visibleAccountIds + ' for Average Funds in Calculations';
        }
        dto.values.put(ALL_LOC_WEEKDAY_AVERAGE, holdPerDayWrappers);
        //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        dto.values.put(IS_HPD_DARK_ZONE, isHpdDarkZone());
        dto.values.put(YESTERDAY_DATE, yesterday);             //returned for debugging / unit testing.
        //----------------------------------
        return dto;
    }
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/304530782
     *
     *
     * @return
     *
     * @see retrieveYTDRevenue()
     * @see https://accelentertainment.my.salesforce.com/analytics/wave/wave.apexp?tsid=02u1I000000Rz95#dashboard/0FK1I00000074ytWAA/view
     *      Note the above only uses 1 year + 1 month but at least provides a guide.
     * @TODO For future use.
     */
//    @AuraEnabled
//    public static ResponseDto retrieveSameStoreSales() {
//        ResponseDto dto = new ResponseDto();
//
//        //Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 75);
//        Date yesterday;
//        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
//        yesterday               = CURRENT_DATE_OVERRIDE.addDays(-1);
//        Date twoDaysAgo         = CURRENT_DATE_OVERRIDE.addDays(-2);
//        Boolean isHpdDarkZone   = isHpdDarkZone();
//        yesterday               = (isHpdDarkZone ? twoDaysAgo : yesterday);
//        //--------------------------------------------------------------------------------
//      //  Date start = yesterday.toStartOfMonth().addMonths(  - (yesterday.month()+12) );
//        Date start = yesterday.toStartOfMonth().addMonths(-12);
////        Map<Id,Account> mAccountsWithEnoughRevenue = new Map<Id,Account>([
////                SELECT  Id
////                FROM    Account
////                WHERE   Id IN ( SELECT  Account__c
////                                FROM    Hold_Per_Day__c
////                                WHERE   Date__c = :start
////                                AND     Account__c IN :mAccountsByIds.keySet() )
////        ]);
//        Map<Id,Account> mAccountsWithEnoughRevenue = new Map<Id,Account>([
//                SELECT  Id
//                FROM    Account
//                WHERE   Hpd_TTM__C != 0
//                AND     Hpd_TTM__c != NULL
//        ]);
//        System.debug('Found '+mAccountsWithEnoughRevenue.size()+' accounts with enough rev visible to running user');
//        //------ @TODO Why can't we use precomputed values?
//        List<AggregateResult> holdPerDayAggregateResults = [
//                SELECT  SUM( Net_Revenue__c )                     netRev
//                FROM    Hold_Per_Day__c
//                WHERE   Account__c      IN  :mAccountsWithEnoughRevenue.keySet()
//                AND     Date__c         >=  :start
//                AND     RecordType.Name = 'Daily Aggregate'
//                GROUP BY  RecordTypeId
//        ];
//        if(!holdPerDayAggregateResults.isEmpty()) {
//            System.debug('Found '+holdPerDayAggregateResults.size()
//                    +' hpd aggregates');
//            dto.isSuccess = true;
//        }
////        dto.values.put('TEST_BLAH',holdPerDayAggregateResults);
//        dto.values.put('TEST Aggs',holdPerDayAggregateResults);
//        dto.values.put('TEST_BLAH',mAccountsWithEnoughRevenue);
//        dto.values.put('start filter',start);
//        return dto;
//    }

    @AuraEnabled
    public static ResponseDto retrieveYTDRevenue(){
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
        yesterday               = CURRENT_DATE_OVERRIDE.addDays(-1);
        Date twoDaysAgo         = CURRENT_DATE_OVERRIDE.addDays(-2);
        Boolean isHpdDarkZone   = isHpdDarkZone();
        //yesterday = Date.today().addDays(-1);
        yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
        yesterday = CommunityUtils.getMostRecentHpdDate();
        //--------------------------------------------------------------------------------

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
                WHERE   account__c in :visibleAccountIds
                and     date__c >= :yearStart
                and     date__c <= :yesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        List<AggregateResult> yars = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
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
        //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        dto.values.put(IS_HPD_DARK_ZONE,isHpdDarkZone());
        dto.values.put(YESTERDAY_DATE, yesterday);             //returned for debugging / unit testing.
        //----------------------------------------------------------------------------------------
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveMTDRevenue(){
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
        yesterday  = CURRENT_DATE_OVERRIDE.addDays(-1);
        Date twoDaysAgo = CURRENT_DATE_OVERRIDE.addDays(-2);
        Boolean isHpdDarkZone = isHpdDarkZone();
        //yesterday = Date.today().addDays(-1);
       // yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
        yesterday = CommunityUtils.getMostRecentHpdDate();
        // End enhancement -------------------------------------------------------------

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
                WHERE   account__c in :visibleAccountIds
                and     date__c >= :monthStart
                and     date__c <= :yesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        List<AggregateResult> netRevenueValidCalc = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     date__c >= :monthStart
                and     date__c <= :validYesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        //RJN  Note. prevStart = the 1st day of last month. prevYesterday =  yesterdays date - 1 month!
        System.debug(LoggingLevel.DEBUG,'prevStart='+prevStart);
        System.debug(LoggingLevel.DEBUG,'prevYesterday='+prevYesterday);
        List<AggregateResult> prevMonth = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     date__c >= :prevStart
                and     date__c <= :prevYesterday
                and     RecordType.Name = 'Daily Aggregate'
                GROUP BY recordtypeId
        ];
        //RJN  Note. validPrevStart     = the 1st of yesterdays month minus 1 year
        //RJN  Note. validPrevYesterday = Yesterday minus 1 day minus 1 year
        //RJN Note.  prevYesterday      = Yesterday minus 1 day minus 1 month.
        List<AggregateResult> prevYear = [
                SELECT
                        SUM(net_revenue__c)             netRev
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
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
        //  8-20-2019 Translate month value from  validYesterday and push into monthName and push to UI.

        //  can't translate a date on day1 to datetime as there is no time and utc / timezone
        //  will push it back to last month.. add 1 day to be sure!
        Date adjustedMonthStartMonth = monthStart.addDays(1);
        dto.values.put( ADJUSTED_MONTH_START_DATE, adjustedMonthStartMonth );
        dto.values.put( REVENUE_MTD_MONTHNAME, CommunityUtils.retrieveFullMonthNameDisplay(adjustedMonthStartMonth) );

        dto.values.put( REVENUE_MTD_YEAR, validYesterday.year() );
        dto.values.put( VALID_YESTERDAY_DATE, validYesterday);  //returned for debugging / unit testing.
        dto.values.put( YESTERDAY_DATE, yesterday);             //returned for debugging / unit testing.
        dto.values.put( IS_HPD_DARK_ZONE, isHpdDarkZone() );
        //-------------------------------------------------------------------------------------------------
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveESTRevenue(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
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
        //  @see https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
        yesterday  = Date.today().addDays(-1);
        Date twoDaysAgo = Date.today().addDays(-2);
        Boolean isHpdDarkZone = isHpdDarkZone();
        //yesterday = Date.today().addDays(-1);
        yesterday = (isHpdDarkZone ? twoDaysAgo : yesterday);
        yesterday = CommunityUtils.getMostRecentHpdDate();
        //--

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
                        sum(nti__c) netRevenue,
                        min(date__c) date
                from hold_per_day__c
                where date__c >= :estPrevMonth
                and date__c <= :estPrevMonthEnd
                and recordtype.name = 'Daily Aggregate'
                and account__c in :visibleAccountIds
                group by recordtypeid
        ];
        List<AggregateResult> prevYearMonthRev = [
                select
                        max(account__r.name) accName,
                        sum(nti__c) netRevenue,
                        min(date__c) date
                from hold_per_day__c
                where date__c >= :estPrevYearMonth
                and date__c <= :estPrevYearMonthEnd
                and recordtype.name = 'Monthly HPD'
                and account__c in :visibleAccountIds
                group by recordtypeid
        ];
        List<AggregateResult> prevYearPrevMonthRev = [
                select
                        max(account__r.name) accName,
                        sum(nti__c) netRevenue,
                        min(date__c) date
                from hold_per_day__c
                where date__c >= :estPrevYearPrevMonth
                and date__c <= :estPrevYearPrevMonthEnd
                and recordtype.name = 'Monthly HPD'
                and account__c in :visibleAccountIds
                group by recordtypeid
        ];

        for(AggregateResult ar : prevMonthRev){
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String)ar.get('accName');
            hpdWrapper.hpdDate = (Date)ar.get('date');
            hpdWrapper.netRevenue = (Decimal)ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : prevYearPrevMonthRev){
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String)ar.get('accName');
            hpdWrapper.hpdDate = (Date)ar.get('date');
            hpdWrapper.netRevenue = (Decimal)ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }
        for(AggregateResult ar : prevYearMonthRev){
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountName = (String)ar.get('accName');
            hpdWrapper.hpdDate = (Date)ar.get('date');
            hpdWrapper.netRevenue = (Decimal)ar.get('netRevenue');
            holdPerDayWrappers.add(hpdWrapper);
        }

        //dto array should be
        //array[0] = last months value
        //array[1] = last year last months value
        //array[2] = last year month value

        //array[2]-array[1] should give you seasonality
        //apply seasonality to array[0] in javascript to estimate current month total revenue

        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Data missing for EST Revenue calculations';
        }
        dto.values.put(EST_DATA,holdPerDayWrappers);
        //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        dto.values.put(IS_HPD_DARK_ZONE,isHpdDarkZone());
        dto.values.put( YESTERDAY_DATE, yesterday);             //returned for debugging / unit testing.
        //-----------------------------------------------------------------------------------------
        return dto;
    }
    /**
     * An abstraction around CommunityUtils.isHpdDarkZone so that we can more easily unit test this as there is no
     * say.. Test.runAsDateTime() method. So without this it be impossible to fully test this without
     * say running tests twice a day.  Note branching code with Test.isRunningTest is normally considered
     * bad practice but currently (as of Summer 19) SFDC gives us no choice here.
     *
     * @return   True if we are in a window where we do not have HPD Data for the current day yet..
     *           ie Midnight thru 9am of the current day, otherwise False.
     * @see CommunityUtils
     */
    @TestVisible
    private static Boolean isHpdDarkZone() {
        Boolean isHpdDarkZone = CommunityUtils.getHpdDark();
        System.debug('-----------rick isHpdDark in ctrl='+isHpdDarkZone);
//        if(!Test.isRunningTest()) {
//            isHpdDarkZone = CommunityUtils.isHpdDarkZone(System.now().time());
//        } else {
//            System.debug('==== unit test time='+UNIT_TEST_CURRENT_TIME_OVERRIDE);
//            isHpdDarkZone = CommunityUtils.isHpdDarkZone(UNIT_TEST_CURRENT_TIME_OVERRIDE);
//        }
       return isHpdDarkZone;
    }
}