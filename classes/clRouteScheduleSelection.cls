public class clRouteScheduleSelection {

    @TestVisible private static final String MAP_KEY_ROUTE_SCHEDULE_WRAPPERS    = 'ROUTE_SCHEDULE_WRAPPERS';
    @TestVisible private static final String MAP_KEY_RPS_WRAPPERS               = 'RPS_WRAPPERS';
    @TestVisible private static final String MAP_KEY_COLLECTOR_LOC_WRAPPERS     = 'COLLECTOR_LOC_WRAPPERS';
    @TestVisible private static final String MAP_KEY_MDT_RECORD = 'MDT_RECORD';
    @TestVisible private static Boolean TEST_HIDE_INVALID_ROUTES = false;

    /**
     * Finds Region Picklist Values for the supplied userId.
     * If the user is a system admin profile, allows region names of DEV TEST to be included.
     * If the user is not a system admin profile, pulls all values from the Processing Location Global PL Value set.
     * If suppressed values is not null or empty, eliminates the passed PL value from the result set.
     *
     * @param uid               The userId
     * @param suppressedValues  Null if nothing to suppress, otherwise PL values to eliminate.
     * @return                  A responseDto containing a List of RegionPlWrapper objects in the values map.
     */
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveCollectorLocationInfo(Id uid,List<String> suppressedValues) {

        ResponseDto dto = new ResponseDto();
        User user = clRouteScheduleSvc.retrieveUserInfo(uid);
        List<Schema.PicklistEntry> ples = clRouteScheduleSvc.retrievePlValues('User','Default_Collector_Location__c');
        List<RegionPlWrapper> regionPlWrappers = new List<RegionPlWrapper>();
        List<Profile> adminProfiles = [SELECT Id,Name FROM Profile WHERE Name LIKE '%System Admin%'];
        dto.technicalMsg += '--> param uid='+uid;
        dto.technicalMsg +=  '--> param suppressedValues='+suppressedValues;
        dto.technicalMsg +=' ---> user default collector location:'+user.Default_Collector_Location__c;

        Boolean isSystemAdmin = false;
        for(Profile p : adminProfiles) {
            if(p.Id == user.ProfileId) {
                isSystemAdmin = true;
                break;
            }
        }
        for (Schema.PicklistEntry ple : ples) {
            Boolean addIt = (!ple.value.contains('DEV TEST') || isSystemAdmin);
            if (suppressedValues != null && !suppressedValues.isEmpty() ) {
                if (suppressedValues.contains(ple.value)) {
                    addIt = false;
                }
            }
            if (addIt) {
                RegionPlWrapper plWrapper = new RegionPlWrapper();
                plWrapper.value = ple.value;
                plWrapper.label = ple.label;
                plWrapper.selected = user.Default_Collector_Location__c == ple.value ? true : false;
                regionPlWrappers.add(plWrapper);
            }
        }
        dto.values.put(MAP_KEY_COLLECTOR_LOC_WRAPPERS,regionPlWrappers);
        dto.isSuccess = true;
        return dto;
    }


    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveMdt(String mdtDevName) {

        ResponseDto dto = new ResponseDto();
        Cash_Logistics_Setting__mdt mdt;

        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        dto.technicalMsg += 'devname passeted='+mdtDevName;
        if(oMdt != null) {
            mdt = (Cash_Logistics_Setting__mdt)oMdt;
        }
        if(mdt != null) {
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_MDT_RECORD,mdt);
        return dto;
    }

    @TestVisible
    private static Cash_Logistics_Setting__mdt retrieveMdt() {
        ResponseDto dto = retrieveMdt('Route_Selection');
        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)dto.values.get(MAP_KEY_MDT_RECORD);
        return mdt;
    }

    /**
     * @param collectionDate The collection date of the Route_Schedule__c sObjects.
     * @return  a ResponseDto containing RouteScheduleWrappers in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveRouteSchedules(Date collectionDate) {

        Cash_Logistics_Setting__mdt mdt = retrieveMdt();

        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' collection date param1: '+collectionDate;
        List<RouteScheduleWrapper> rsWrappers = new List<RouteScheduleWrapper>();

        if(collectionDate != null) {
            collectionDate = Date.newInstance(collectionDate.year(),collectionDate.month(),collectionDate.day());
            dto.technicalMsg += ' collection date param2: '+collectionDate;
        }

        Map<Id,Route_Schedule__c> routeSchedules = clRouteScheduleSvc.retrieveRouteSchedules(collectionDate);
        for(Route_Schedule__c routeSchedule : routeSchedules.values()) {
            if(mdt.Show_Invalid_Routes__c != true || TEST_HIDE_INVALID_ROUTES) {
                if(routeSchedule.Total_Accounts__c < 1) {
                    continue;
                }
            }
            rsWrappers.add(new RouteScheduleWrapper(routeSchedule));
        }
        dto.isSuccess = !rsWrappers.isEmpty();
        dto.values.put(MAP_KEY_ROUTE_SCHEDULE_WRAPPERS,rsWrappers);
        return dto;
    }

    /**
     * @param collectionDate The collection date of the Route_Schedule__c sObjects.
     * @param region  The Processing_Location__c of the route schedule.
     * @param suppressedValues The regions (Processing_Location__c to suppress (ie if region value is * (all regions)).
     *
     * @return  a ResponseDto containing RouteScheduleWrappers in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveRegionRouteSchedules(Date collectionDate,String region,List<String> suppressedValues) {

        Cash_Logistics_Setting__mdt mdt = retrieveMdt();

        ResponseDto dto = new ResponseDto();
        List<RouteScheduleWrapper> rsWrappers = new List<RouteScheduleWrapper>();

        if(collectionDate != null) {
            collectionDate = Date.newInstance(collectionDate.year(),collectionDate.month(),collectionDate.day());
        }
        dto.technicalMsg += ' collection date param: '+collectionDate;
        dto.technicalMsg += ' region param: '+region;
        dto.technicalMsg += ' suppressed values param: '+suppressedValues;

        Set<String> sSuppressedValues = new Set<String> ();
        if(suppressedValues != null) {
            sSuppressedValues.addAll(suppressedValues);
        }
        Map<Id,Route_Schedule__c> routeSchedules = clRouteScheduleSvc.retrieveRegionRouteSchedules(collectionDate,region,sSuppressedValues);
        for(Route_Schedule__c routeSchedule : routeSchedules.values()) {
            if(mdt.Show_Invalid_Routes__c != true || TEST_HIDE_INVALID_ROUTES) {
                if(routeSchedule.Total_Accounts__c < 1) {
                    continue;
                }
            }
            rsWrappers.add(new RouteScheduleWrapper(routeSchedule));
        }
        dto.isSuccess = !rsWrappers.isEmpty();
        dto.values.put(MAP_KEY_ROUTE_SCHEDULE_WRAPPERS,rsWrappers);
        return dto;
    }

    /**
     * @param routeScheduleId  The Route_Processing_Sheet__c.Route_Schedule__c id value.
     * @return a map containing RPSWrappers.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheets(Id routeScheduleId) {

        ResponseDto dto = new ResponseDto();
        List<RpsWrapper> rpsWrappers = new List<RpsWrapper>();

        List<Route_Processing_Sheet__c> routeProcessingSheets = clRouteProcessingSheetSvc.retrieveRouteProcessingSheets(routeScheduleId);

        for(Route_Processing_Sheet__c rps : routeProcessingSheets) {
            rpsWrappers.add(new RpsWrapper(rps));
        }
        dto.isSuccess = !rpsWrappers.isEmpty();
        dto.values.put(MAP_KEY_RPS_WRAPPERS,rpsWrappers);

        dto.isSuccess = !rpsWrappers.isEmpty();
        return dto;
    }

    @AuraEnabled
    public static ResponseDto doRouteScheduleSelection(Id userId, Id routeScheduleId) {
        ResponseDto dto = new ResponseDto();
        Route_Schedule__c routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
        Boolean notFullyAssigned = false;
        if(routeSchedule.Collector_1__c == null) {
            routeSchedule.Collector_1__c = userId;
            notFullyAssigned = true;
        } else if (routeSchedule.User__c == null) {
            routeSchedule.User__c = userId;
            notFullyAssigned = true;
        }
        if(notFullyAssigned) {
            update routeSchedule;
            dto.message = 'You have been assigned to route ' + routeSchedule.name;
            dto.isSuccess = true;
        } else {
            dto.message += 'There was a problem assigning you to the route schedule.  ';
            dto.message += 'Both '+routeSchedule.Collector_1__r.Name + ' and ' + routeSchedule.User__r.Name;
            dto.message += ' are already assigned to this schedule!';
            dto.isSuccess = false;
        }

        return dto;
    }


    /**
     * Wrapper for client consumption of Route_Processing_Sheet__c.
     */
    public class RouteScheduleWrapper {

        @AuraEnabled public Id rsId;
        @AuraEnabled public String rsName;
        @AuraEnabled public Boolean rsFullyAssigned;
        @AuraEnabled public Boolean rsPartiallyAssigned;
        @AuraEnabled public String rsCollector1Name;
        @AuraEnabled public String rsCollector2Name;
        @AuraEnabled public Integer rsTotalLocs;
        @AuraEnabled public Integer rsTotalRps;


        public RouteScheduleWrapper(Route_Schedule__c rs) {
            this.rsId = rs.Id;
            this.rsName = rs.Name;
            if(rs.Collector_1__c != null && rs.User__c != null) {
                this.rsFullyAssigned = true;
            }
            if((rs.Collector_1__c != null && rs.User__c == null)
                    || (rs.Collector_1__c == null && rs.User__c != null)) {
                this.rsPartiallyAssigned = true;
            }
            this.rsCollector1Name = rs.Collector_1__r.Name;
            this.rsCollector2Name = rs.User__r.Name;
            this.rsTotalLocs = rs.Total_Accounts__c != null ? Integer.valueof(rs.Total_Accounts__c) : 0;
            this.rsTotalRps = rs.Total_Processing_Sheets__c != null ? Integer.valueOf(rs.Total_Processing_Sheets__c) : 0;
        }
    }

   /**
    * Wrapper for client consumption of Route_Schedule__c.
    */
    public class RpsWrapper {

        @AuraEnabled public Id rpsId;
        @AuraEnabled public String rpsName;
        @AuraEnabled public Integer rpsStopNumber;
        @AuraEnabled public String  rpsLocName;
        @AuraEnabled public String  rpsLocAddy;
        @AuraEnabled public String  rpsLocAccessTime;
        @AuraEnabled public String  routeScheduleName;

        public RpsWrapper(Route_Processing_Sheet__c rps) {
            this.rpsId = rps.Id;
            this.rpsName = rps.Name;
            this.rpsStopNumber = rps.Stop_Number__c != null ? Integer.valueOf(rps.Stop_Number__c) : null;
            this.routeScheduleName = rps.Route_Schedule__r != null ? rps.Route_Schedule__r.Name : null;
            this.rpsLocName = rps.Account__r.Name;
            this.rpsLocAddy = formatAddress(rps);
            this.rpsLocAccessTime = rps.Account__r.Access_Time__c;

        }
    }

    public class RegionPlWrapper {
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public Boolean selected {get;set;}
        public RegionPlWrapper() {
            this.selected = false;
        }
    }

    private Static String formatAddress(Route_Processing_Sheet__c rps) {
        String addy = '';
        if(rps.Account__r != null) {
            addy += rps.Account__r.ShippingStreet;
            addy += ' - ' + rps.Account__r.ShippingCity;
            addy  += ' ' + rps.Account__r.ShippingState;
        }
        return addy;
    }


}