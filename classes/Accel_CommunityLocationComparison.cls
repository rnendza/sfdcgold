/**
 * Created by Zach on 4/8/2019.
 *
 * RJN Added oldest date override to pull dynamically.
 * @todo change client signitures to not pass date.
 */

public without sharing class Accel_CommunityLocationComparison {

    public static final String MAP_KEY_ACCOUNT_LIST     = 'ACCOUNT_LIST';
    public static final String RADIUS_HPDS = 'RADIUS_HPDS';
    public static final String CITY_HPDS = 'CITY_HPDS';
    public static final String CITY_YOY_HPDS = 'CITY_YOY_HPDS';
    public static final String RADIUS_YOY_HPDS = 'RADIUS_YOY_HPDS';
    public static final String ALL_HPDS = 'ALL_HPDS';
    public static final String ALL_YOY_HPDS = 'ALL_YOY_HPDS';
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

   // @AuraEnabled
   // public static List<String> retrieveLocTypes() {
    //}
    @AuraEnabled
    public static List<City__c> getCity(String city){
        List<City__c> c = new List<City__c>();
        c=[select name, CityCenter__Latitude__s, CityCenter__Longitude__s from City__c where name = :city];
        return c;
    }

    @AuraEnabled
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes    = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Integer iLimit              = 500; //@TODO Custom setting?
        dto.values.put(MAP_KEY_ACCOUNT_LIST,AccountSvc.retrieveAccounts( accountTypes,iLimit ).values() );
        dto.isSuccess = true;
        return dto;
    }

    @AuraEnabled
    public static ResponseDto getRadiusHpds(Id id, String accType, Double dist, Date oldest) {
        ResponseDto dto = new ResponseDto();
        List<Account> accAddr = new List<Account>();
        Double lat;
        Double llong;

        accAddr=[select ShippingLatitude, ShippingLongitude from Account where id = :id limit 1];
        lat=accAddr[0].ShippingLatitude;
        llong=accAddr[0].ShippingLongitude;

        //  Override the hardcoded oldest date passed from the client.
        oldest = getOldestHpdDate();

        Date startDate = Date.newInstance(oldest.year(), oldest.month(), 1);

        List<AggregateResult> ars;
        if(accType != 'All') {
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            MAX(Account__r.original_live_date__c) liveDate,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c = :accType
                    AND Account__r.Location_Type__c != null
                    AND DISTANCE(Account__r.ShippingAddress, GEOLOCATION(:lat, :llong), 'mi') < :dist
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0

            ];
        }else{
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            MAX(Account__r.original_live_date__c) liveDate,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c != null
                    AND DISTANCE(Account__r.ShippingAddress, GEOLOCATION(:lat, :llong), 'mi') < :dist
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0
            ];
        }
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountLat           =(Double)ar.get('lat');
            hpdWrapper.accountLong          =(Double)ar.get('llong');
            hpdWrapper.accountName          =(String)ar.get('accName');
            hpdWrapper.accountPhysicalCity  = (String)ar.get('city');
            hpdWrapper.accountPhysicalStreet = (String)ar.get('street');
            hpdWrapper.hpdDate = (Date)ar.get('liveDate');
            hpdWrapper.accountZip = (String)ar.get('zip');
            hpdWrapper.hpdName     =(String)ar.get('locType');
            hpdWrapper.hpd                 = (Decimal)ar.get('hpdSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('monthCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
            dto.technicalMsg += 'Oldest Date='+oldest + '';
        } else {
            dto.technicalMsg = 'Distance HPD calc errors';
        }
        dto.values.put(RADIUS_HPDS,holdPerDayWrappers);
        return dto;

    }

    @AuraEnabled
    public static ResponseDto getRadiusYoYHpds(Id id, String accType, Double dist, Date oldest) {
        ResponseDto dto = new ResponseDto();
        List<Account> accAddr = new List<Account>();
        Double lat;
        Double llong;

        accAddr=[select ShippingLatitude, ShippingLongitude from Account where id = :id limit 1];
        lat=accAddr[0].ShippingLatitude;
        llong=accAddr[0].ShippingLongitude;

        //  Override the hardcoded oldest date passed from the client.
        oldest = getOldestHpdDate();

        Date startDate = Date.newInstance(oldest.year()-1, oldest.month(), 1);
        Date endDate = Date.newInstance(oldest.year()-1, oldest.month()+3, 1);
        List<AggregateResult> ars;
        if(accType != 'All') {
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            MAX(Account__r.original_live_date__c) liveDate,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND Date__c < :endDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c = :accType
                    AND Account__r.Location_Type__c != null
                    AND DISTANCE(Account__r.ShippingAddress, GEOLOCATION(:lat, :llong), 'mi') < :dist
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0

            ];
        }else{
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            MAX(Account__r.original_live_date__c) liveDate,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND Date__c < :endDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c != null
                    AND DISTANCE(Account__r.ShippingAddress, GEOLOCATION(:lat, :llong), 'mi') < :dist
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0
            ];
        }
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountLat           =(Double)ar.get('lat');
            hpdWrapper.accountLong          =(Double)ar.get('llong');
            hpdWrapper.accountName          =(String)ar.get('accName');
            hpdWrapper.accountPhysicalCity  = (String)ar.get('city');
            hpdWrapper.accountPhysicalStreet = (String)ar.get('street');
            hpdWrapper.accountZip = (String)ar.get('zip');
            hpdWrapper.hpdName     =(String)ar.get('locType');
            hpdWrapper.hpdDate = (Date)ar.get('liveDate');
            hpdWrapper.hpd                 = (Decimal)ar.get('hpdSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('monthCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'RADIUS YOY HPD calc errors';
        }
        dto.values.put(RADIUS_YOY_HPDS,holdPerDayWrappers);
        return dto;

    }

    @AuraEnabled
    public static ResponseDto getCityHpds(String cityName, Date oldest) {
        ResponseDto dto = new ResponseDto();

        //  Override the hardcoded oldest date passed from the client.
        oldest = getOldestHpdDate();

        Date startDate = Date.newInstance(oldest.year(), oldest.month(), 1);
        List<AggregateResult> ars;
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            MAX(Account__r.original_live_date__c) liveDate,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c != null
                    AND (Account__r.ShippingCity = :cityName or Account__r.ShippingPostalCode = :cityName)
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0

            ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountLat           =(Double)ar.get('lat');
            hpdWrapper.accountLong          =(Double)ar.get('llong');
            hpdWrapper.accountName          =(String)ar.get('accName');
            hpdWrapper.accountPhysicalCity  = (String)ar.get('city');
            hpdWrapper.accountZip = (String)ar.get('zip');
            hpdWrapper.hpdDate = (Date)ar.get('liveDate');
            //hpdName not a good variable to store a type, too lazy to unschedule jobs to modify hpdWrapper
            hpdWrapper.hpdName     =(String)ar.get('locType');
            hpdWrapper.hpd                 = (Decimal)ar.get('hpdSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('monthCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'City HPD calc errors';
        }
        dto.values.put(CITY_HPDS,holdPerDayWrappers);
        return dto;

    }

    @AuraEnabled
    public static ResponseDto getCityYoYHpds(String cityName, Date oldest) {
        ResponseDto dto = new ResponseDto();

        //  Override the hardcoded oldest date passed from the client.
        oldest = getOldestHpdDate();

        Date startDate = Date.newInstance(oldest.year()-1, oldest.month(), 1);
        Date enddate = Date.newInstance(oldest.year()-1, oldest.month()+3, 1);
        List<AggregateResult> ars;
        ars = [
                SELECT
                        MAX(Account__r.ShippingLatitude) lat,
                        MAX(Account__r.ShippingLongitude) llong,
                        MAX(Account__r.Name) accName,
                        MAX(Account__r.ShippingCity) city,
                        MAX(Account__r.ShippingPostalCode) zip,
                        MAX(Account__r.Filtered_Location_Type__c) locType,
                        MAX(Account__r.original_live_date__c) liveDate,
                        SUM(HPD__c) hpdSum,
                        SUM(Funds_In__c) fundsIn,
                        COUNT_DISTINCT(Id) monthCount
                FROM Hold_Per_Day__c
                WHERE Date__c >= :startDate
                AND Date__c < :endDate
                AND RecordType.Name = 'Monthly HPD'
                AND Account__r.Location_Type__c != null
                AND (Account__r.ShippingCity = :cityName or Account__r.ShippingPostalCode = :cityName)
                group by Account__c
                HAVING COUNT_DISTINCT(Id) > 0

        ];
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountLat           =(Double)ar.get('lat');
            hpdWrapper.accountLong          =(Double)ar.get('llong');
            hpdWrapper.accountName          =(String)ar.get('accName');
            hpdWrapper.accountPhysicalCity  = (String)ar.get('city');
            hpdWrapper.accountZip = (String)ar.get('zip');
            hpdWrapper.hpdDate = (Date)ar.get('liveDate');
            //hpdName not a good variable to store a type, too lazy to unschedule jobs to modify hpdWrapper
            hpdWrapper.hpdName     =(String)ar.get('locType');
            hpdWrapper.hpd                 = (Decimal)ar.get('hpdSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('monthCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'City YOY HPD calc errors';
        }
        dto.values.put(CITY_YOY_HPDS,holdPerDayWrappers);
        return dto;

    }

    @AuraEnabled
    public static ResponseDto getAllHpds(String accType, Date oldest) {
        ResponseDto dto = new ResponseDto();

        //  Override the hardcoded oldest date passed from the client.
        oldest = getOldestHpdDate();

        Date startDate = Date.newInstance(oldest.year(), oldest.month(), 1);
        List<AggregateResult> ars;
        if(accType != 'All') {
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c = :accType
                    AND Account__r.Location_Type__c != null
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0

            ];
        }else{
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c != null
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0
            ];
        }
        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountLat           =(Double)ar.get('lat');
            hpdWrapper.accountLong          =(Double)ar.get('llong');
            hpdWrapper.accountName          =(String)ar.get('accName');
            hpdWrapper.accountPhysicalCity  = (String)ar.get('city');
            hpdWrapper.accountZip = (String)ar.get('zip');
            //hpdName not a good variable to store a type, too lazy to unschedule jobs to modify hpdWrapper
            hpdWrapper.hpdName     =(String)ar.get('locType');
            hpdWrapper.hpd                 = (Decimal)ar.get('hpdSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('monthCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'All HPD calc errors';
        }
        dto.values.put(ALL_HPDS,holdPerDayWrappers);
        return dto;

    }

    @AuraEnabled
    public static ResponseDto getAllYoYHpds(String accType, Date oldest) {
        ResponseDto dto = new ResponseDto();

        //  Override the hardcoded oldest date passed from the client.
        oldest = getOldestHpdDate();

        Date startDate = Date.newInstance(oldest.year()-1, oldest.month(), 1);
        Date endDate = Date.newInstance(oldest.year()-1, oldest.month()+3, 1);
        List<AggregateResult> ars;
        if(accType != 'All') {
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND Date__c < :endDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c = :accType
                    AND Account__r.Location_Type__c != null
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0

            ];
        }else{
            ars = [
                    SELECT
                            MAX(Account__r.ShippingLatitude) lat,
                            MAX(Account__r.ShippingLongitude) llong,
                            MAX(Account__r.Name) accName,
                            MAX(Account__r.ShippingCity) city,
                            MAX(Account__r.ShippingStreet) street,
                            MAX(Account__r.ShippingPostalCode) zip,
                            MAX(Account__r.Filtered_Location_Type__c) locType,
                            SUM(HPD__c) hpdSum,
                            SUM(Funds_In__c) fundsIn,
                            COUNT_DISTINCT(Id) monthCount
                    FROM Hold_Per_Day__c
                    WHERE Date__c >= :startDate
                    AND Date__c < :endDate
                    AND RecordType.Name = 'Monthly HPD'
                    AND Account__r.Location_Type__c != null
                    group by Account__c
                    HAVING COUNT_DISTINCT(Id) > 0
            ];
        }

        //---- throw ars in a wrapper for easier client consumption
        List<HpdWrapper> holdPerDayWrappers = new List<HpdWrapper>();
        for(AggregateResult ar : ars) {
            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountLat           =(Double)ar.get('lat');
            hpdWrapper.accountLong          =(Double)ar.get('llong');
            hpdWrapper.accountName          =(String)ar.get('accName');
            hpdWrapper.accountPhysicalCity  = (String)ar.get('city');
            hpdWrapper.accountZip = (String)ar.get('zip');
            //hpdName not a good variable to store a type, too lazy to unschedule jobs to modify hpdWrapper
            hpdWrapper.hpdName     =(String)ar.get('locType');
            hpdWrapper.hpd                 = (Decimal)ar.get('hpdSum');
            hpdWrapper.fundsIn                 = (Decimal)ar.get('fundsIn');
            hpdWrapper.distinctDateCount        = (Integer)ar.get('monthCount');
            holdPerDayWrappers.add(hpdWrapper);
        }
        if(!holdPerDayWrappers.isEmpty()) {
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'All YOY HPD calc errors';
        }
        dto.values.put(ALL_YOY_HPDS,holdPerDayWrappers);
        return dto;

    }

    /**
     * Query Hold_Per_Day__c and pull a single Monthly Hold_Per_Day__c
     * record sorted by Date__c DESC.
     *
     * @return The oldest (ie latest hpd date) minus 3 months
     */
    public static Date getOldestHpdDate() {
        Date oldestDate;

        List<Hold_Per_Day__c> holdPerDays = [
                SELECT Id, Date__c
                FROM Hold_Per_Day__c
                WHERE RecordType.Name = 'Monthly HPD'
                ORDER By Date__c DESC
                LIMIT 1
        ];
        if(!holdPerDays.isEmpty()) {
            oldestDate = holdPerDays[0].Date__c;
            //  Get 3 months of data
            oldestDate = oldestDate.addMonths(-3);
        }
        return oldestDate;
    }


}