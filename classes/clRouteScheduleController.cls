public without sharing class clRouteScheduleController {

    public final static String MAP_KEY_RS_WRAPS = 'RS_WRAPS';
    public final static String MAP_KEY_COLLECTION_DATE_FORMATTED = 'COLLECTION_DATE_FORMATTED';
    public final static String MAP_KEY_RS_GROUP_WRAPS = 'RS_GROUP_WRAPS';

    @TestVisible private static final String MDT_RS_DEV_NAME = 'Route_Schedule';


    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheetsGroupedForProcessor(Id userId,Double cacheBust) {
        ResponseDto dto = new ResponseDto();
        List<RsGroupWrapper> rsWrappers  = new List<RsGroupWrapper>();

        List<clRouteScheduleSvc.RouteScheduleGrouping> rsGroupings = clRouteScheduleSvc.retrieveRouteSchedulesForProcessorGroups(new Set<Id>{userId},Date.today());

        if(rsGroupings != null && !rsGroupings.isEmpty()) {
            rsWrappers = buildRsGroupResponse( rsGroupings );
        }

        dto.values.put(MAP_KEY_RS_GROUP_WRAPS, rsWrappers);
        dto.isSuccess = !rsWrappers.isEmpty();

        if(!dto.isSuccess) {
            String soql = 'SELECT Id, Name,Processing_Location__c,UserName FROM User WHERE Id = :userId';
            User user = Database.query(soql);
            dto.message = 'No Incomplete Route schedules found for '+ user.name + '.<br/>';
            if( user.get(clRouteScheduleSvc.REGION_FIELD_NAME) == null) {
                dto.message += ' Please assign the user '+ user.username + ' to a processing location.';
            } else {
                // 10/12 Changed all refs to User.Processing_Location__c to dynamic to assist with probably deployment issues to prod.
                dto.message += ' The processing location of the user is : '+user.get(clRouteScheduleSvc.REGION_FIELD_NAME);
            }
        }
        return dto;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteSchedulesGroupedForFiller(Id userId,Integer numOfDaysBackForRouteSchedules,Double cacheBust) {
        ResponseDto dto = new ResponseDto();
        List<RsGroupWrapper> rsWrappers  = new List<RsGroupWrapper>();

        List<clRouteScheduleSvc.RouteScheduleFillGrouping> rsGroupings =
                clRouteScheduleSvc.retrieveRouteSchedulesForFillersGroups(new Set<Id>{userId},numOfDaysBackForRouteSchedules,Date.today());

        if(rsGroupings != null && !rsGroupings.isEmpty()) {
            rsWrappers = buildRsGroupResponse( rsGroupings );
        }

        dto.values.put(MAP_KEY_RS_GROUP_WRAPS, rsWrappers);
        dto.isSuccess = !rsWrappers.isEmpty();

        if(!dto.isSuccess) {
            String soql = 'SELECT Id, Name,Processing_Location__c,UserName FROM User WHERE Id = :userId';
            User user = Database.query(soql);
            dto.message = 'No Incomplete Route schedules found for '+ user.name + '.<br/>';
            if( user.get(clRouteScheduleSvc.REGION_FIELD_NAME) == null) {
                dto.message += ' Please assign the user '+ user.username + ' to a processing location.';
            } else {
                // 10/12 Changed all refs to User.Processing_Location__c to dynamic to assist with probably deployment issues to prod.
                dto.message += ' The processing location of the user is : '+user.get(clRouteScheduleSvc.REGION_FIELD_NAME);
            }
        }
        return dto;
    }

    @AuraEnabled(cacheable=true)
    //{type:'process',userId: '$_userId', collectionDate: '$_collectionDate', cacheBust: '$_cacheBust'})
    public static ResponseDto retrieveRouteProcessingSheetsForProcessorNoCache(Id userId, Date collectionDate, String type, Double cacheBust) {
        return retrieveRouteProcessingSheetsForProcessor(userId,collectionDate,type);
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheetsForProcessor(Id userId, Date dDate, String type) {
        ResponseDto dto = new ResponseDto();
        List<RsWrapper> rsWrappers  = new List<RsWrapper>();

        if(dDate != null) {
            dDate = Date.newInstance(dDate.year(),dDate.month(),dDate.day());
        }
        List<Route_Schedule__c> routeSchedules = clRouteScheduleSvc.retrieveRouteSchedulesForProcessor(userId,dDate,type);
        if(routeSchedules != null && !routeSchedules.isEmpty()) {
            rsWrappers = buildResponse( routeSchedules,type);
        }

        dto.values.put(MAP_KEY_RS_WRAPS, rsWrappers);
        dto.values.put(MAP_KEY_COLLECTION_DATE_FORMATTED,dDate.format());
        dto.isSuccess = !routeSchedules.isEmpty();

        if(!dto.isSuccess) {
            String soql = 'SELECT Id, Name,Processing_Location__c,UserName FROM User WHERE Id = :userId';
            User user = Database.query(soql);
            String sDate = dDate.format();
            dto.message = 'No route schedules found for '+ user.name + ' on date ' + sDate+'.<br/>';
            if(user.get(clRouteScheduleSvc.REGION_FIELD_NAME) == null) {
                dto.message += ' Please assign the user '+ user.username + ' to a processing location.';
            } else {
                dto.message += ' The processing location of the user is : '+user.get(clRouteScheduleSvc.REGION_FIELD_NAME);
            }
        }
        return dto;
    }

   /**
    * @param rsRecs
    * @return
    */
    @TestVisible
    private static List<RsGroupWrapper> buildRsGroupResponse(List<clRouteScheduleSvc.RouteScheduleGrouping> rsGroupings) {
        List<RsGroupWrapper> rsWrappers = new List<RsGroupWrapper>();
        Map<String,String> mStatus_Style = buildRsStyleMap( retrieveMdt() );

        for(clRouteScheduleSvc.RouteScheduleGrouping rsGrouping : rsGroupings) {
            rsWrappers.add(new RsGroupWrapper(rsGrouping,mStatus_Style));
        }
        return rsWrappers;
    }

    @TestVisible
    private static List<RsGroupWrapper> buildRsGroupResponse(List<clRouteScheduleSvc.RouteScheduleFillGrouping> rsGroupings) {
        List<RsGroupWrapper> rsWrappers = new List<RsGroupWrapper>();
        Map<String,String> mStatus_Style = buildRsStyleMap( retrieveMdt() );

        for(clRouteScheduleSvc.RouteScheduleFillGrouping rsGrouping : rsGroupings) {
            rsWrappers.add(new RsGroupWrapper(rsGrouping,mStatus_Style));
        }
        return rsWrappers;
    }


    /**
     * @param rsRecs
     * @return
     */
    @TestVisible
    private static List<RsWrapper> buildResponse(List<Route_Schedule__c> rsRecs, String type) {
        List<RsWrapper> rsWrappers = new List<RsWrapper>();
        Map<String,String> mStatus_Style = buildRsStyleMap( retrieveMdt() );

        for(Route_Schedule__c rs : rsRecs) {
            rsWrappers.add(new RsWrapper(rs,mStatus_Style,type));
        }
        return rsWrappers;
    }

   /**
    * A Wrapper on top of Route Schedule Grouping Aggregate Results for display
    */
    public class RsGroupWrapper {

        public clRouteScheduleSvc.RouteScheduleGrouping rsGroup;
        public clRouteScheduleSvc.RouteScheduleFillGrouping rsFillGroup;
        @AuraEnabled public String  rsGroupName;
        @AuraEnabled public Date    rsGroupDate;
        @AuraEnabled public String  rsGroupStatus = 'Processing Incomplete';
        @AuraEnabled public String  rsGroupStatusDesc;
        @AuraEnabled public String  rsGroupRowStyle = '';
        @AuraEnabled public Integer rsGroupTotal;


        public RsGroupWrapper(clRouteScheduleSvc.RouteScheduleGrouping rsGrouping,Map<String, String> mStatus_Style) {
            this.rsGroup = rsGrouping;
            this.rsGroupDate = rsGroup.collectionDate;
            this.rsGroupTotal = rsGroup.totalRouteSchedules;
            this.rsGroupName = rsGroupDate.format() + ' Route Collection ';
            this.rsGroupRowStyle = mStatus_Style.get(this.rsGroupStatus);
            if(rsGroupDate == Date.today()) {
                this.rsGroupName += ' (Today)';
            }
            this.rsGroupStatusDesc = this.rsGroupTotal + ' Incomplete Route';
            if(this.rsGroupTotal > 1) {
                this.rsGroupStatusDesc += 's';
            }
        }

        public RsGroupWrapper(clRouteScheduleSvc.RouteScheduleFillGrouping rsGrouping,Map<String, String> mStatus_Style) {
            this.rsFillGroup = rsGrouping;
            this.rsGroupDate = rsFillGroup.fillDate;
            this.rsGroupTotal = rsFillGroup.totalRouteSchedules;
            this.rsGroupName = rsGroupDate.format() + ' Route Fill ';
            this.rsGroupRowStyle = mStatus_Style.get(this.rsGroupStatus);
            if(rsGroupDate == Date.today()) {
                this.rsGroupName += ' (Today)';
            }
            this.rsGroupStatusDesc = this.rsGroupTotal + ' Incomplete Route';
            if(this.rsGroupTotal > 1) {
                this.rsGroupStatusDesc += 's';
            }
        }
    }

   /**
    * A Wrapper on top of Route_Schedule for ease of display
    */
    public class RsWrapper {

        public Route_Schedule__c rs;
        @AuraEnabled public String rsId;
        @AuraEnabled public String rsName;
        @AuraEnabled public String rsStatus = '';
        @AuraEnabled public String rsProcessingStatus = '';
        @AuraEnabled public String rsCollectionStatus = '';
        @AuraEnabled public String rsRowStyle = '';
        @AuraEnabled public Double rsTotalRps = 0;
        @AuraEnabled public Double rsTotalAccounts = 0;
        @AuraEnabled public Boolean rsHasNoAccounts = false;


        public RsWrapper(Route_Schedule__c rs, Map<String, String> mStatus_Style, String type) {
            this.rs = rs;
            this.rsId = rs.Id;
            this.rsName = rs.Name;
            this.rsStatus = rs.Schedule_Status__c;
            this.rsProcessingStatus = rs.Processing_Status__c;
            this.rsCollectionStatus = rs.Collection_Status__c;
            this.rsTotalAccounts = rs.Total_Accounts__c != null ? rs.Total_Accounts__c : 0;
            if(type == 'fill') {
                if(rsTotalAccounts > 0) {
                    this.rsRowStyle = mStatus_Style.get(this.rsStatus);
                } else {
                    this.rsHasNoAccounts = true;
                }
            } else {
                //this.rsRowStyle = mStatus_Style.get(this.rsProcessingStatus);
                if(rsTotalAccounts > 0) {
                    this.rsRowStyle = mStatus_Style.get(this.rsProcessingStatus);
                } else {
                    this.rsHasNoAccounts = true;
                }
            }
        }
    }
    /**
     * @return
     */
    @TestVisible
    private static Cash_Logistics_Setting__mdt retrieveMdt() {
        Cash_Logistics_Setting__mdt mdtRps =
                (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,MDT_RS_DEV_NAME);
        return mdtRps;
    }
    /**
     * @param mdt The Cash_Logistics_Setting__mdt custom mdt recorfd.
     * @return a Map of Status => Style
     */
    @TestVisible
    private static Map<String, String> buildRsStyleMap(Cash_Logistics_Setting__mdt mdt) {

        Map<String, String> mStatus_Style = new Map<String, String>();
        mStatus_Style.put('Fill Incomplete', mdt.Status_Fill_Incomplete_Style__c);
        mStatus_Style.put('COMPLETED FILL', mdt.Status_Completed_Fill_Style__c);
        mStatus_Style.put('COMPLETED PROCESSING', mdt.Status_Completed_Processing_Style__c);
        mStatus_Style.put('Processing Incomplete', mdt.Status_Processing_Incomplete_Style__c);
        return mStatus_Style;
    }
}