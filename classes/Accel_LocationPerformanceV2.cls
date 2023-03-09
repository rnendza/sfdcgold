public with sharing class Accel_LocationPerformanceV2 {

    public static final String MAP_KEY_ACCOUNT_LIST     = 'ACCOUNT_LIST';
    public static final String MAP_KEY_HPD_LIST         = 'HPD_WRAPPER_LIST';
    public static final String MAP_KEY_HPD_MONTHS       = 'HPD_WRAPPER_MONTHS';
    public static final String MAP_KEY_HPD_MONTHLY_DATA       = 'HPD_WRAPPER_MONTHLY_DATA';
    public static final String MAP_KEY_HPD_CUSTOM_DATA       = 'HPD_WRAPPER_CUSTOM_DATA';
    public static final String MAP_KEY_HPD_MONTHLY_AVERAGES       = 'HPD_WRAPPER_MONTHLY_AVERAGES';
    public static final String MAP_KEY_HPD_SINGLE_MONTHLY_AVERAGES       = 'HPD_WRAPPER_SINGLE_MONTHLY_AVERAGES';
    //https://accel-entertainment.monday.com/boards/286658657/pulses/311009951
    public static final String  CONTACT_PROFILE_SETTINGS                = 'CONTACT_PROFILE_SETTINGS';

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
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts( CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
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
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAggregateLifetimeHpdData(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();

        List<AggregateResult> ars = [
                SELECT
                        account__c                      accId,
                        MAX(Account__r.Name)            accName,
                        MAX(Account__r.ShippingStreet)  accStreet,
                        MAX(Account__r.ShippingCity)    accCity,
                        MAX(Account__r.Accel_Vgt_Live_Date__c)     vgtLiveDate,   //  RJN 8-12-2019 SFCOMM-291515455
                        SUM(Net_Revenue__c)             revenueSum,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(Amount_Played__c)           amtPlayedSum,
                        SUM(Amount_Won__c)              amtWonSum
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     RecordType.Name = 'Monthly HPD'
                group by account__c
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                =(Id)ar.get('accId');
            hpdWrapper.accountName              =(String)ar.get('accName');
            hpdWrapper.accountPhysicalStreet    =(String)ar.get('accStreet');
            hpdWrapper.accountPhysicalCity      =(String)ar.get('accCity');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.netRevenue               = (Decimal)ar.get('revenueSum');
            hpdWrapper.fundsOut                 =(Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amtPlayedSum');
            hpdWrapper.amtWon                   = (Decimal)ar.get('amtWonSum');
            hpdWrapper.dateValue                = 'Lifetime';
            //  RJN 8-12-2019 SFCOMM-291515455
            Object oLiveDate = ar.get( 'vgtLiveDate');
            if(oLiveDate != null && oLiveDate instanceof Date) {
                hpdWrapper.accountAccelVgtLiveDate = (Date)oLiveDate;
            }

            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Monthly Lifetime pull';
        }
        dto.values.put(MAP_KEY_HPD_LIST,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveAggregateMonthlyHpdData(String dateString){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        Date d = Date.valueOf(dateString);
        Integer numberOfDays = Date.daysInMonth(d.year(), d.month());
        Date endDate =date.newInstance(d.year(), d.month(), numberOfDays);

        List<AggregateResult> ars = [
                SELECT
                        account__c                accId,
                        MAX(Account__r.Name)            accName,
                        MAX(Account__r.ShippingStreet)  accStreet,
                        MAX(Account__r.ShippingCity)    accCity,
                        MAX(Account__r.Accel_Vgt_Live_Date__c)     vgtLiveDate,   //  RJN 8-12-2019 SFCOMM-291515455
                        SUM(Net_Revenue__c)             revenueSum,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(Amount_Played__c)           amtPlayedSum,
                        SUM(Amount_Won__c)              amtWonSum
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     RecordType.Name = 'Monthly HPD'
                and     date__c >= : d
                and     date__c <= : endDate
                group by account__c
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                =(Id)ar.get('accId');
            hpdWrapper.accountName              =(String)ar.get('accName');
            hpdWrapper.accountPhysicalStreet    =(String)ar.get('accStreet');
            hpdWrapper.accountPhysicalCity      =(String)ar.get('accCity');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.netRevenue               = (Decimal)ar.get('revenueSum');
            hpdWrapper.fundsOut                 =(Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amtPlayedSum');
            hpdWrapper.amtWon                   = (Decimal)ar.get('amtWonSum');
            hpdWrapper.dateValue                = dateString;
            //  RJN 8-12-2019 SFCOMM-291515455
            Object oLiveDate = ar.get( 'vgtLiveDate');
            if(oLiveDate != null && oLiveDate instanceof Date) {
                hpdWrapper.accountAccelVgtLiveDate = (Date)oLiveDate;
            }

            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Single Month pull';
        }
        dto.values.put(MAP_KEY_HPD_MONTHLY_DATA ,holdPerDayWrappers);
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveAggregateCustomHpdData(String startDate, String endDate){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();
        Date startD = Date.valueOf(startDate);
        Date endD = Date.valueOf(endDate);

        List<AggregateResult> ars = [
                SELECT
                        account__c                accId,
                        MAX(Account__r.Name)            accName,
                        MAX(Account__r.ShippingStreet)  accStreet,
                        MAX(Account__r.ShippingCity)    accCity,
                        SUM(Net_Revenue__c)             revenueSum,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(Amount_Played__c)           amtPlayedSum,
                        SUM(Amount_Won__c)              amtWonSum,
                        MAX(Account__r.Accel_Vgt_Live_Date__c)     vgtLiveDate   //  RJN 8-12-2019 SFCOMM-291515455
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     RecordType.Name = 'Daily HPD'
                and     date__c >= : startD
                and     date__c <= : endD
                group by account__c
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                =(Id)ar.get('accId');
            hpdWrapper.accountName              =(String)ar.get('accName');
            hpdWrapper.accountPhysicalStreet    =(String)ar.get('accStreet');
            hpdWrapper.accountPhysicalCity      =(String)ar.get('accCity');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.netRevenue               = (Decimal)ar.get('revenueSum');
            hpdWrapper.fundsOut                 =(Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amtPlayedSum');
            hpdWrapper.amtWon                   = (Decimal)ar.get('amtWonSum');
            hpdWrapper.dateValue                = startDate + ' - '+endDate;
            //  RJN 8-12-2019 SFCOMM-291515455
            Object oLiveDate = ar.get( 'vgtLiveDate');
            if(oLiveDate != null && oLiveDate instanceof Date) {
                hpdWrapper.accountAccelVgtLiveDate = (Date)oLiveDate;
            }

            holdPerDayWrappers.add(hpdWrapper);
        }

        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Single Month pull';
        }
        dto.values.put(MAP_KEY_HPD_CUSTOM_DATA,holdPerDayWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAggregateMonthlyAverages(){
        ResponseDto dto = new ResponseDto();
        //get accounts visible to the user.
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(CustomMetaDataSvc.retrieveCommunityAccountTypes(), 100);
        Set<Id> visibleAccountIds = mAccountsByIds.keySet();

        List<AggregateResult> ars = [
                SELECT
                        account__c                accId,
                        MAX(Account__r.Name)            accName,
                        MAX(Account__r.ShippingStreet)  accStreet,
                        MAX(Account__r.ShippingCity)    accCity,
                        SUM(Net_Revenue__c)             revenueSum,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(Amount_Played__c)           amtPlayedSum,
                        SUM(Amount_Won__c)              amtWonSum,
                        COUNT_DISTINCT(date__c)              hpdCount
                FROM    Hold_Per_Day__c
                WHERE   account__c in :visibleAccountIds
                and     RecordType.Name = 'Monthly HPD'
                group by account__c
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                =(Id)ar.get('accId');
            hpdWrapper.accountName              =(String)ar.get('accName');
            hpdWrapper.accountPhysicalStreet    =(String)ar.get('accStreet');
            hpdWrapper.accountPhysicalCity      =(String)ar.get('accCity');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.netRevenue               = (Decimal)ar.get('revenueSum');
            hpdWrapper.fundsOut                 =(Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amtPlayedSum');
            hpdWrapper.amtWon                   = (Decimal)ar.get('amtWonSum');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('hpdCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for accounts:'+visibleAccountIds + ' for Average Monthly pull';
        }
        dto.values.put(MAP_KEY_HPD_MONTHLY_AVERAGES,holdPerDayWrappers);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveSingleAccountAggregateMonthlyAverages(Id accId){
        ResponseDto dto = new ResponseDto();

        List<AggregateResult> ars = [
                SELECT
                        account__c                accId,
                        MAX(Account__r.Name)            accName,
                        MAX(Account__r.ShippingStreet)  accStreet,
                        MAX(Account__r.ShippingCity)    accCity,
                        SUM(Net_Revenue__c)             revenueSum,
                        SUM(Location_Share__c)          locShareSum,
                        SUM(Funds_In__c)                fundsInSum,
                        SUM(Funds_Out__c)               fundsOutSum,
                        SUM(Amount_Played__c)           amtPlayedSum,
                        SUM(Amount_Won__c)              amtWonSum,
                        COUNT_DISTINCT(date__c)              hpdCount
                FROM    Hold_Per_Day__c
                WHERE   account__c = :accId
                and     RecordType.Name = 'Monthly HPD'
                group by account__c
                limit 3000
        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId                =(Id)ar.get('accId');
            hpdWrapper.accountName              =(String)ar.get('accName');
            hpdWrapper.accountPhysicalStreet    =(String)ar.get('accStreet');
            hpdWrapper.accountPhysicalCity      =(String)ar.get('accCity');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsInSum');
            hpdWrapper.locShare                 = (Decimal)ar.get('locShareSum');
            hpdWrapper.netRevenue               = (Decimal)ar.get('revenueSum');
            hpdWrapper.fundsOut                 =(Decimal)ar.get('fundsOutSum');
            hpdWrapper.amtPlayed                = (Decimal)ar.get('amtPlayedSum');
            hpdWrapper.amtWon                   = (Decimal)ar.get('amtWonSum');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('hpdCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'No HPDS for account:'+accId + ' for Single Account Average Monthly pull';
        }
        dto.values.put(MAP_KEY_HPD_SINGLE_MONTHLY_AVERAGES,holdPerDayWrappers);
        return dto;
    }
}