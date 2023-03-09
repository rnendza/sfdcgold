public without sharing class clRouteScheduleSvc {

    public final Static String MDT_SCHEDULER = 'Scheduler';
    public final static String REGION_FIELD_NAME = 'Processing_Location__c'; // User.Processing_Location__c

    //  Various defaults.
    @TestVisible private static String DEFAULT_OWA_EMAIL_ADDRESS = 'crm@accelentertainment.com';
    @TestVisible private static String DEFAULT_NO_REPLY_ADDRESS = 'no-reply@accelentertainment.com';



    /**
     * Retrieves all route schedules for the route collection date (probably tomorrow) and the passed userId.
     * (The route processor)
     *
     * @param userId              A single userId for the 'Processor'.
     * @param dDate               The date of the Route_Schedule__c.Route_Collection_Date__c field.
     * @param type
     * @return                    A Map of Id => Route_Schedule__c sObjects.
     */
    public static List<Route_Schedule__c> retrieveRouteSchedulesForProcessor( Id userId, Date dDate, String type ) {
        return retrieveRouteSchedulesForProcessor(new Set<Id>{userId},dDate,type);
    }


   /**
    * Retrieves all route schedules for the route collection date and the passed userIds (The route processor) that
    * have RPS Child Records.
    *
    * @param userIds             A Set<Id> of userIds for the 'Processor'.
    * @param routeFillDate      The date of the Route_Schedule__c.Route_Fill_Date field.
    * @return                    A Map of Id => Route_Schedule__c sObjects.
    */
    public static List<Route_Schedule__c> retrieveRouteSchedulesForProcessor( Set<Id> userIds, Date routeFillDate ) {
        return retrieveRouteSchedulesForProcessor(userIds,routeFillDate,'fill');
    }

    /**
     * Retrieves all route schedules for the route collection date and the passed userIds (The route processor) that
     * has RPS Child Records.  Coded for multiple processors but will probably only be 1 userId passed.
     * We can't really use the UserId to bump up against Route_Schedule__c so we have to use processing locations to zone in.
     *
     * @param userIds             A Set<Id> of userIds for the 'Processor'.
     * @param dDate               The date of the Route_Schedule__c.Route_Collection_Date__c or Route_Schedule__c.Route_Fill_Date__c pending type.
     * @param type                The type ie processor or fill
     * @return                    A Map of Id => Route_Schedule__c sObjects.
     *
     * 10/12 Changed query to handle change of User.Processing_Location__c from Picklist to Multiselect.
     * 10/12 Changed all refs to User.Processing_Location__c to dynamic to assist with probably deployment issues to prod.
     */
    public static List<Route_Schedule__c> retrieveRouteSchedulesForProcessor( Set<Id> userIds, Date dDate, String type ) {

        //  Get all processing locations for all userIds passed (probably only 1 userId but can be more)
        String soql = 'SELECT Id,'+REGION_FIELD_NAME+' FROM User WHERE Id IN :userIds';
        List<User> users = Database.query(soql);

        //  User can have 0=>M Processing Locations (Evil Multi-Select)
        List<String> processingLocations = new List<String>();
        for(User user : users) {
            if(user.get(REGION_FIELD_NAME) != null) {
                List<String> allUserProcessingLocations = ((String)user.get(REGION_FIELD_NAME)).split(';');
                processingLocations.addAll(allUserProcessingLocations);
            }
        }
        //   Note: Route_Schedule__C.Processing_Location__c is not a multi-select so we can use a dynamic BIND IN clause.
        String q = '';
        q += 'SELECT {0} ';+
        q += 'FROM   Route_Schedule__c ';
        q += 'WHERE  '+REGION_FIELD_NAME+ '  IN :processingLocations ';
        if( type == 'fill') {
            q += ' AND    Route_Fill_Date__c = :dDate ';
        } else {
            q += ' AND    Route_Collection_Date__c = :dDate ';
        }
        q += 'ORDER BY Name ASC ';

        System.debug('---> filter region = ' + processingLocations);
        System.debug('---> filter date = ' + dDate);
        System.debug('---> filter type = ' + type);
        System.debug('---> routeSchedulesForProcessor soql: '+q);

        String formattedQuery = String.format(q,getAllRouteScheduleFields());
        List<Route_Schedule__c> routeSchedules = Database.query(formattedQuery);

        return routeSchedules;
    }
    /**
     * @param userIds                   The user Id(s) of the processor.
     * @param startRouteCollectionDate  The collection date to go back from (probably will be TODAY)
     *
     * @return
     *
     * 10/12 Changed query to handle change of User.Processing_Location__c from Picklist to Multiselect.
     * 10/12 Changed all refs to User.Processing_Location__c to dynamic to assist with probably deployment issues to prod.
     */
    public static List<RouteScheduleGrouping> retrieveRouteSchedulesForProcessorGroups( Set<Id> userIds, Date startRouteCollectionDate ) {

        List<RouteScheduleGrouping> routeScheduleGroupings = new List<RouteScheduleGrouping>();

        //  Get all processing locations for all userIds passed (probably only 1 userId but can be more)
        String soql = 'SELECT Id,'+REGION_FIELD_NAME+' FROM User WHERE Id IN :userIds';
        List<User> users = Database.query(soql);

//        Set<String> processingLocations = new Set<String>();
//        for(User user : users) {
//            processingLocations.add(user.Processing_Location__c);
//        }
        //  User can have 0=>M Processing Locations (Evil Multi-Select)
        List<String> processingLocations = new List<String>();

        for(User user : users) {
            if(user.get(REGION_FIELD_NAME) != null) {
                List<String> allUserProcessingLocations = ((String)user.get(REGION_FIELD_NAME)).split(';');
                processingLocations.addAll(allUserProcessingLocations);
            }
        }
        System.debug(' locations='+processingLocations);
        System.debug(' start date='+startRouteCollectionDate.format());
        List<AggregateResult> ars = [
                SELECT Route_Collection_Date__c collectionDate,Count(Id) totalRouteSchedules
                FROM   Route_Schedule__c
                WHERE  Processing_Location__c       IN :processingLocations
                AND    Route_Collection_Date__c     <= :startRouteCollectionDate
                AND    Id IN (
                        Select Route_Schedule__c
                        From   Route_Processing_Sheet__c
                        Where  Processing_Process_Status__c = 'Processing Incomplete' //  [ COMPLETED PROCESSING, Processing Incomplete ]
                )
                //AND    Route_Collection_Date__c     = LAST_N_DAYS:7  //  @todo Last n days somewhat arb.. how long to go back?
                GROUP BY Route_Collection_Date__c
                ORDER BY Route_Collection_Date__c DESC
        ];
        for(AggregateResult ar : ars) {
            routeScheduleGroupings.add(new RouteScheduleGrouping(ar));
        }
        return routeScheduleGroupings;
    }
 

    public static List<RouteScheduleFillGrouping> retrieveRouteSchedulesForFillersGroups(   Set<Id> userIds,
                                                                                            Integer numDaysBackForRouteSchedules,
                                                                                            Date startRouteFillDate ) {

        List<RouteScheduleFillGrouping> routeScheduleFillGroupings = new List<RouteScheduleFillGrouping>();

        //  Get all processing locations for all userIds passed (probably only 1 userId but can be more)
        String soql = 'SELECT Id,'+REGION_FIELD_NAME+' FROM User WHERE Id IN :userIds';
        List<User> users = Database.query(soql);

        //  User can have 0=>M Processing Locations (Evil Multi-Select)
        List<String> processingLocations = new List<String>();
        for(User user : users) {
            if(user.get(REGION_FIELD_NAME) != null) {
                List<String> allUserProcessingLocations = ((String)user.get(REGION_FIELD_NAME)).split(';');
                processingLocations.addAll(allUserProcessingLocations);
            }
        }
        Date initialRouteFillDate = startRouteFillDate.addDays(-Integer.valueOf(numDaysBackForRouteSchedules));
        List<AggregateResult> ars = [
                SELECT Route_Fill_Date__c fillDate,Count(Id) totalRouteSchedules
                FROM   Route_Schedule__c
                WHERE  Processing_Location__c       IN :processingLocations
                AND    Route_Fill_Date__c     <= :startRouteFillDate
                AND    Id IN (
                        Select Route_Schedule__c
                        From   Route_Processing_Sheet__c
                        Where  Processing_Status__c = 'Not Yet Filled'
                )
               //AND Route_Fill_Date__c = LAST_N_DAYS:
                AND Route_Fill_Date__c >= :initialRouteFillDate
                GROUP BY Route_Fill_Date__c
                ORDER BY Route_Fill_Date__c DESC
        ];
        for(AggregateResult ar : ars) {
            routeScheduleFillGroupings.add(new RouteScheduleFillGrouping(ar));
        }
        return routeScheduleFillGroupings;
    }
    /**
     * Wrapper class to make an Aggregate result more Route_Schedule__c specific.
     */
    public class RouteScheduleGrouping {
        public Date collectionDate;
        public Integer totalRouteSchedules;

        public RouteScheduleGrouping( AggregateResult arRsGroup) {
            this.collectionDate = (Date)arRsGroup.get('collectionDate');
            this.totalRouteSchedules = Integer.valueOf((Decimal)arRsGroup.get('totalRouteSchedules'));
        }
    }


    public class RouteScheduleFillGrouping {
        public Date fillDate;
        public Integer totalRouteSchedules;

        public RouteScheduleFillGrouping( AggregateResult arRsGroup) {
            this.fillDate = (Date)arRsGroup.get('fillDate');
            this.totalRouteSchedules = Integer.valueOf((Decimal)arRsGroup.get('totalRouteSchedules'));
        }
    }

    /**
     * Retrieves all route schedules for today for the passed userIds and date.
     *
     * @param userIds             A Set<Id> of userIds for the Assigned Driver, or the Collector 1 or Collector 2.
     * @param routeCollectionDate The date of the Route_Schedule__c.Route_Collection_Date__c field.
     * @return                    A Map of Id => Route_Schedule__c sObjects.
     */
    public static Map<Id,Route_Schedule__c> retrieveRouteSchedules( Set<Id> userIds, Date routeCollectionDate ) {

        String q = '';
        q += 'SELECT {0} ,';
        q += '       Collector_1__r.Name, User__r.Name ';
        q += 'FROM   Route_Schedule__c ';
        if(userIds != null && !userIds.isEmpty()) {
            q += 'WHERE  ( ' +
                    '      User__c               In :userIds ' +
                    '      or Collector_1__c     In :userIds ' +
                    '      or Assigned_Driver__c In :userIds ' +
                    '    ) ';
            q += 'AND    Route_Collection_Date__c = :routeCollectionDate ';
        } else {
            q += 'WHERE  Route_Collection_Date__c = :routeCollectionDate ';
        }
        q += 'ORDER BY NAME ASC ';

        String formattedQuery = String.format(q,getAllRouteScheduleFields());
        List<Route_Schedule__c> routeSchedules = Database.query(formattedQuery);

        Map<Id,Route_Schedule__c> m = new Map<Id,Route_Schedule__c>();
        for(Route_Schedule__c routeSchedule : routeSchedules) {
            m.put(routeSchedule.Id,routeSchedule);
        }
        return m;
    }

    public static Map<Id,Route_Schedule__c> retrieveRegionRouteSchedules( Date routeCollectionDate,String region,
                                                                    Set<String>suppressedValues ) {
        String q = '';
        q += 'SELECT {0} ,';
        q += '       Collector_1__r.Name, User__r.Name ';
        q += 'FROM   Route_Schedule__c ';

        q += 'WHERE  Route_Collection_Date__c = :routeCollectionDate ';
        if(region != '*') {
            q += ' AND Processing_Location__c = :region  ';
        } else {
            if(suppressedValues != null && !suppressedValues.isEmpty()) {
                q+= ' AND Processing_Location__c NOT IN :suppressedValues ';
            }
        }
        q += 'ORDER BY NAME ASC ';

        String formattedQuery = String.format(q,getAllRouteScheduleFields());
        List<Route_Schedule__c> routeSchedules = Database.query(formattedQuery);

        Map<Id,Route_Schedule__c> m = new Map<Id,Route_Schedule__c>();
        for(Route_Schedule__c routeSchedule : routeSchedules) {
            m.put(routeSchedule.Id,routeSchedule);
        }
        return m;
    }

    /**
     * Retrieves all route schedules for today for the passed userId and date.
     *
     * @param userId               A User.Id for the Assigned Driver, or the Collector 1 or Collector 2.
     * @param routeCollectionDate The date of the Route_Schedule__c.Route_Collection_Date__c field.
     * @return                    A Map of Id => Route_Schedule__c sObjects.
     *
     * @see clRouteScheduleSvc.retrieveRouteSchedules(Set<Id,Date)
     */
    public static Map<Id,Route_Schedule__c> retrieveRouteSchedules( Id userId, Date routeCollectionDate ) {
        return retrieveRouteSchedules(new Set<Id>{userId}, routeCollectionDate);
    }


   /**
    * Retrieves all route schedules for today
    *
    * @param routeCollectionDate The date of the Route_Schedule__c.Route_Collection_Date__c field.
    * @return                    A Map of Id => Route_Schedule__c sObjects.
    *
    * @see clRouteScheduleSvc.retrieveRouteSchedules(Set<Id,Date)
    */
    public static Map<Id,Route_Schedule__c> retrieveRouteSchedules(Date routeCollectionDate ) {
        return retrieveRouteSchedules(new Set<Id>(), routeCollectionDate);
    }

    /**
     * @param   routeScheduleId   The Route_Schedule__c.Id value.
     * @return                    A Route_Schedule__c sObject.
     */
    public static Route_Schedule__c retrieveRouteSchedule( Id routeScheduleId ) {
        Route_Schedule__c routeSchedule;

        String q = '';
        q += 'SELECT {0} ';
        q += '       ,Collector_1__r.Name, User__r.Name ';
        q += 'FROM   Route_Schedule__c ';
        q += 'WHERE  Id = :routeScheduleId ';

        String formattedQuery = String.format(q,getAllRouteScheduleFields());
        List<Route_Schedule__c> routeSchedules = Database.query(formattedQuery);

        if(!routeSchedules.isEmpty()) {
            routeSchedule = routeSchedules[0];
        }
        return routeSchedule;
    }

    public static User retrieveUserInfo( Id uid ) {
        User user;

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   User ';
        q += 'WHERE  Id = :uid ';

        String formattedQuery = String.format(q,getAllUserFields());
        List<User> users = Database.query(formattedQuery);

        if(!users.isEmpty()) {
            user  = users[0];
        }
        return user;
    }

    public static List<Schema.PicklistEntry> retrievePlValues(String sObjectName, String fieldApiName) {
        SObjectType sObjectType = FieldSetSvc.getSObjectType(sObjectName);
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();

        Map<String,Schema.SObjectField> fields = describeResult.fields.getMap() ;
        Schema.DescribeFieldResult fieldResult = fields.get(fieldApiName).getDescribe();
        List<Schema.PicklistEntry> ples = fieldResult.getPicklistValues();
        return ples;
    }


    public static Database.SaveResult updateRouteSchedule( Route_Schedule__c routeSchedule) {
        Database.SaveResult saveResult = Database.update(routeSchedule);
        return saveResult;
    }

    @TestVisible
    private static List<String>  getAllRouteScheduleFields() {
        Map<String, Schema.SObjectField> fieldsMap = Route_Schedule__c.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }

    @TestVisible
    private static List<String>  getAllUserFields() {
        Map<String, Schema.SObjectField> fieldsMap = User.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }

    public static  Cash_Logistics_Setting__mdt retrieveSetting(String devName) {
        Cash_Logistics_Setting__mdt mdt =
                (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
        return mdt;
    }

    public static Id sendRouteScheduleCompletedEmail(Id routeScheduleId) {
        clQueueableRpsEmailer q = new clQueueableRpsEmailer(routeScheduleId);
        Id jobId = System.enqueueJob(q);
        return jobId;
    }


    //  ===================  EMAIL RELATED ===========================================




    public static List<Messaging.SendEmailResult> sendEmailTemplates(List<EmailData> emailDatas) {

        List<BulkEmailPayload> payloads = new List<BulkEmailPayload>();
        for(EmailData data : emailDatas ) {
            BulkEmailPayload payload = new BulkEmailPayload();

            payload.owaEmailAddy = DEFAULT_OWA_EMAIL_ADDRESS;
            payload.replyTo = DEFAULT_NO_REPLY_ADDRESS;
            payload.templateId = data.templateId;
            payload.whatId = data.recordId;
            payload.whoIds = data.whoIds;

            payload.dynamicHtml = data.dynamicHtml;
            payload.setSaveAsActivity = data.saveAsActivity;
            payload.setBccSender = false;
            payload.useSignature = false;

            payloads.add(payload);
        }
        List<Messaging.SendEmailResult> sendResults = EmailSvc.sendEmailTemplates(payloads);
        return sendResults;
    }

    /**
     * @todo doc
     */
    public class EmailData {
        public Id recordId;
        public Set<Id> whoIds;
        public Id templateId;
        public String  dynamicHtml;
        public Boolean saveAsActivity = false;
    }
}