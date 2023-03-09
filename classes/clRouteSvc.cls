public class clRouteSvc {

    //  Various defaults.
    @TestVisible private static String DEFAULT_OWA_EMAIL_ADDRESS = 'crm@accelentertainment.com';
    @TestVisible private static String DEFAULT_NO_REPLY_ADDRESS = 'no-reply@accelentertainment.com';
    //  Searches for this string in a template and replaces it.
    @TestVisible private static String CUSTOM_DYNAMIC_HMTL_TOKEN = '<div style="display:none">[[[custom_dynamic_html]]]</div>';
    @TestVisible private static String DEFAULT_SENDER_DISPLAY_NAME = '- Salesforce Automation -';
    @TestVisible private static String DEFAULT_REDEMPTION_TYPE = 'NRT';
    @TestVisible private static String ASSET_SAS_RT_POSITION_2 = 'RT2';
    @TestVisible private static STring ASSET_SAS_RT_POSITION_1 = 'RT1';
    @TestVisible private static Set<String> IGNORED_RT_TYPES = new Set<String> {'Safe Cash'};
    @TestVisible private static Set<String> MANUAL_SECOND_RT_COLLECTION_TYPES = new Set<String> {clFillSvc.REGULAR_2ND_RT_COLLECTION_TYPE};

    /**
     * @param rps          A Route_Processing_Sheet__c sObject.
     * @param rpsDateEnum  An enum of the type of date we wish to set.
     *
     * @return             The modified rps (not updated but modified)
     */
    public static Route_Processing_Sheet__c tagRpsUtilizationDates(Route_Processing_Sheet__c rps,clRpsDateEnum rpsDateEnum) {

        DateTime dtCurrent = System.now();
        Id userIdCurrent = UserInfo.getUserId();

        switch on rpsDateEnum {
            when START_VGT_COLLECTION_DATE {
                rps.Start_VGT_Collection_Date__c = dtCurrent;
                rps.Start_VGT_Collection_User__c = userIdCurrent;
            }
            when END_VGT_COLLECTION_DATE {
                rps.End_VGT_Collection_Date__c = dtCurrent;
                rps.End_VGT_Collection_User__c = userIdCurrent;
            }
            when START_RT_REPLENISHMENT_DATE {
                rps.Start_RT_Replenishment_Date__c = dtCurrent;
                rps.Start_RT_Replenishment_User__c = userIdCurrent;
            }
            when END_RT_REPLENISHMENT_DATE {
                rps.End_RT_Replenishment_Date__c = dtCurrent;
                rps.End_RT_Replenishment_User__c = userIdCurrent;
            }
        }
        return rps;
    }

    /**
     * Finds the Redemption Type value to set on Route_Schedule_Account__c.Redemption_Type_From_Asset__c via
     * querying the Assets associated with the Account and using the Asset.GP_Manufacturer__c value.
     *
     * @param rsas  A List of Route_Schedule__c sObjects without an Id associated with them. Note this will`
     *              be MODIFIED BY REFERENCE!
     * @implNotes   These are processed on a BEFORE Insert thus no rsa Id to use for map so tag that the original
     *              Route_Schedule_Account__c.Redemption_Type_From_Asset__c (Labeled Redemption Type) prior to insert.
     *
     * @todo       Still a mess. this really is still convoluted business use case wise!
     */
    public static void tagRedemptionAssets(List<Route_Schedule_Account__c> rsas) {

        //  (1)  Get all the account ids associated with all the Route_Schedule_Account__c records.
        Set<Id> accountIds = new Set<Id>();
        for (Route_Schedule_Account__c rsa : rsas) {
            accountIds.add(rsa.Account__c);
        }
        //  (2)  Call the asset service to get all Redemption Terminal Assets for each Account.
        Map<Id, List<Asset>> mAcctId_RedemptionAssets = AssetSvc.retrieveAccountsRedemptionAssets(accountIds);

        //  (3)  Roll through and perform custom business logic to determine a single redemption type and asset
        for (Route_Schedule_Account__c rsa : rsas) {
            if (mAcctId_RedemptionAssets != null && !mAcctId_RedemptionAssets.isEmpty()) {

                if (mAcctId_RedemptionAssets.containsKey(rsa.Account__c)) {

                    List<Asset> redemptionAssets = (List<Asset>) mAcctId_RedemptionAssets.get(rsa.Account__c);
                    rsa.Total_RTs__c = redemptionAssets.size();
                    rsa.Redemption_Type_From_Asset__c = DEFAULT_REDEMPTION_TYPE;
                    debugRsa(rsa, redemptionAssets);

                    //  More then 1 RT And the User Selected RT1 OR RT2 in picklist. ( Regular 2nd RT Situation)
                    if (rsa.Total_RTs__c > 1  && MANUAL_SECOND_RT_COLLECTION_TYPES.contains(rsa.Collection_Type__c)) {
                        rsa.Redemption_Terminal__c = 'RT2';
                        Asset foundAsset = searchForRtAsset(rsa,redemptionAssets);
                        if (foundAsset != null) {
                            rsa.Redemption_Type_From_Asset__c = foundAsset.GP_Manufacturer__c;
                            rsa.Redemption_Asset__c = foundAsset.Id;
                        } else {
                            //  Ok user selected either RT1 or RT2 and no RT asset could be found!
                            System.debug(LoggingLevel.ERROR, 'Could not find RT for rsa:' + rsa);
                            debugRsa(rsa, redemptionAssets);
                        }
                    } else {
                        //  Either only 1 RT exists or this is scheduler created.
                        if (rsa.Total_RTs__c == 1) {
                            //  Only 1 RT.. Life is Good .. assign it if it exists
                            Asset foundAsset = searchForRtAsset(rsa,redemptionAssets);
                            if(foundAsset != null) {
                                rsa.Redemption_Type_From_Asset__c = foundAsset.GP_Manufacturer__c;
                                rsa.Redemption_Asset__c = foundAsset.Id;
                            }
                        } else {
                            //  2 RTs exist. no value
                            String msg;
                            System.debug(LoggingLevel.INFO, msg);
                            //  Regular 2nd rt collection type
                            if(rsa.Collection_Type__c == clFillSvc.REGULAR_2ND_RT_COLLECTION_TYPE) {
                                rsa.Redemption_Terminal__c = ASSET_SAS_RT_POSITION_2;
                                Asset foundAsset = searchForRtAsset(rsa,redemptionAssets);
                                if(foundAsset != null) {
                                    rsa.Redemption_Type_From_Asset__c = foundAsset.GP_Manufacturer__c;
                                    rsa.Redemption_Asset__c = foundAsset.Id;
                                } else {
                                    System.debug(LoggingLevel.ERROR, 'Could not find RT2 for rsa:' + rsa);
                                    debugRsa(rsa, redemptionAssets);
                                }
                            } else {
                                //  Not regular 2nd rt collection type. not safecash
                                if (!IGNORED_RT_TYPES.contains(rsa.Redemption_Type_From_Asset__c)) {
                                    Asset foundAsset = searchForRtAsset(rsa,redemptionAssets);
                                    if(foundAsset != null) {
                                        rsa.Redemption_Type_From_Asset__c = foundAsset.GP_Manufacturer__c;
                                        rsa.Redemption_Asset__c = foundAsset.Id;
                                    } else {
                                        System.debug(LoggingLevel.ERROR, 'Could not find RT2 for rsa:' + rsa);
                                        debugRsa(rsa, redemptionAssets);
                                    }
                                }
                            }
                        }
                    }
                    System.debug('---> fillcheck final rsa:'+rsa);
                }
            }
        }
    }
    @TestVisible
    private static Asset searchForRtAsset(Route_Schedule_Account__c rsa, List<Asset> redemptionAssets) {
        Asset rtAsset;
        for (Asset redemptionAsset : redemptionAssets) {
            // We Got a match on Asset__c.SAS__c for the pl value of either RT1 or RT2
            if (redemptionAsset.SAS__c == rsa.Redemption_Terminal__c) {
                rtAsset = redemptionAsset;
                break;
            }
        }
        return rtAsset;
    }
    /**
     * @param rsa               The Route_Schedule_Account__c sObject.
     * @param redemptionAssets  A List of Asset (Redemption) sObjects Associated with the Account.
     */
    private static void debugRsa(Route_Schedule_Account__c rsa,List<Asset> redemptionAssets) {
        System.debug('---> fillcheck: Redemption Assets for Account '+rsa.Account__c+' :'+redemptionAssets);
        System.debug('---> fillcheck: totals rts:'+rsa.Total_RTs__c);
        System.debug('---> fillcheck: redemption terminal type'+rsa.Redemption_Terminal__c);
        System.debug('---> fillcheck: collection type type'+rsa.Collection_Type__c);
    }
    public static Route_Processing_Sheet__c  retrieveRouteProcessingSheet(Id rpsId) {
        Route_Processing_Sheet__c routeProcessingSheet;

        List<Route_Processing_Sheet__c> routeProcessingSheets = [
                SELECT  Status__c,Id,Name,LastModifiedDate,Redemption_Terminal_Status__c,
                        Account__r.Name,Account__r.ShippingLatitude,CreatedDate,
                        Account__r.ShippingLongitude,Account__r.ShippingStreet,Account__r.ShippingCity,
                        Account__r.ShippingPostalCode,Account__r.ShippingCountry,BV_Value__c,
                        BV_Drop_Total__c,
                        Account__r.Redemption_1_Info__c,Redemption_Type__c,Collection_Type__c,
                        Account__r.Funds_in_Field__c,
                        Redemption_Type_From_Asset__c,
                        X1_Note_Count_Grand_Total__c,X5_Note_Count_Grand_Total__c,X20_Note_Count_Grand_Total__c,
                        X50_Note_Count_Grand_Total__c,X100_Note_Count_Grand_Total__c,All_Note_Count_Grand_Total__c,
                        Redemption_Asset__c,Redemption_Asset__r.Name,Redemption_Asset__r.Unit_Id__c,
                        Start_VGT_Collection_Date__c,Start_VGT_Collection_User__c,
                        End_VGT_Collection_Date__c,End_VGT_Collection_User__c,
                        Start_RT_Replenishment_Date__c,Start_RT_Replenishment_User__c,
                        End_RT_Replenishment_Date__c,End_RT_Replenishment_User__c,
                        Total_Completed_Meter_Readings__c,Total_Meter_Readings__c,
                        Replenishment_Type__c,Snapshot_Cassette__c,Snapshot_New_Cassette__c
                FROM Route_Processing_Sheet__c
                WHERE Id = :rpsId
                LIMIT 1
        ];
        routeProcessingSheet = !routeProcessingSheets.isEmpty() ? routeProcessingSheets[0] : null;

        return routeProcessingSheet;
    }

    public static List<Route__c> retrieveRoutes(Id userId) {
        List<Route__c> routes = [
                SELECT Id,Name
                FROM   Route__c
                Order By Name ASC
        ];
        return routes;
    }

    public static Route__c retrieveRoute( Id routeId ) {
        Route__c route;

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Route__c ';
        q += 'WHERE  Id = :routeId ';
        String formattedQuery = String.format(q,getAllRouteFields());

        List<Route__c> routes = Database.query(formattedQuery);
        Map<Id,Route__c> m = new Map<Id,Route__c>( routes );
        if(!m.isEmpty()) {
            route = m.values()[0];
        }
        return route;
    }

    public static List<Route__c> retrieveAllRoutes() {

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Route__c ';
        String formattedQuery = String.format(q,getAllRouteFields());

        List<Route__c> routes = Database.query(formattedQuery);
        return routes;
    }

    public static List<Route__c> retrieveAllRoutesWithRpsRecordsWithCollectionDates() {

        Map<Id,Route_Processing_Sheet__c> m = new Map<Id,Route_Processing_Sheet__c>([
           SELECT Route_Schedule__r.Route__c
           FROM   Route_Processing_Sheet__c
           WHERE  Collection_Date__c != NULL
        ]);
        Set<Id> routeIds = new Set<Id>();
        if(!m.isEmpty()) {
            for(Route_Processing_Sheet__c rps : m.values()) {
                routeIds.add(rps.Route_Schedule__r.Route__c);
            }
        }

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Route__c ';
        q += 'WHERE  Id In :routeIds ';
        //q += 'AND    Id IN :routeIds ';
//                ' SELECT Route_Schedule__r.Route__c ';
//        q += '               FROM   Route_Processing_Sheet__c ';
//        q += '               WHERE  Collection_Date__c != NULL ) ';
        String formattedQuery = String.format(q,getAllRouteFields());

        List<Route__c> routes = Database.query(formattedQuery);
        return routes;
    }

    public static Set<Date> retrieveAllRouteRpsCollectionDates(Id routeId) {
        Set<Date> dates = new Set<Date>();
        List<AggregateResult> ars = [
                SELECT Collection_Date__c colDate
                FROM   Route_Processing_Sheet__c
//                WHERE  Route__c = :routeId
//                AND    Collection_Date__c != NULL
                WHERE  Collection_Date__c != NULL
                Group by Collection_Date__c
                Order By Collection_Date__c
        ];
        for(AggregateResult ar : ars) {
            Date d = (Date)ar.get('colDate');
            dates.add(d);
        }
        return dates;
    }

    @TestVisible
    private static List<String>  getAllRouteFields() {
        Map<String, Schema.SObjectField> fieldsMap = Route__c.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }

    /**
     * Retrieves route processing sheets for the provided processing locations and Route_Fill_Date__c.
     * Aggregates Cassette x note count outbound totals by route.
     *
     * @param processingLocations  A Set of Processing Locations__c ie 'Burr Ridge'
     * @param routeFillDate        The Date of Route_Processing_Sheet__c.Route_Fill_Date__c
     *
     * @return a List of raw Aggregate Results by Route Id.
     */
    public static List<AggregateResult> retrieveRpsFillData(Set<String> processingLocations, Date routeFillDate) {

        //  @todo there is no cassette 10 field! SUM(Cassette_10_Note_Count_Outbound__c)   c10NoteCountOutbound

        List<AggregateResult> routeRpsAgr =  [
            SELECT   Route_Schedule__r.Route__r.Name, Route_Schedule__r.Route__c, Processing_Location__c,
                     SUM( Cassette_1_Note_Count_Outbound__c )      c1NoteCountOutbound,
                     SUM( Cassette_5_Note_Count_Outbound__c )      c5NoteCountOutbound,
                     SUM( Cassette_20_Note_Count_Outbound__c )     c20NoteCountOutbound,
                     SUM( Cassette_50_Note_Count_Outbound__c )     c50NoteCountOutbound,
                     SUM( Cassette_100_Note_Count_Outbound__c )    c100NoteCountOutbound,
                     SUM( Outbound_Total__c )                      outboundTotal
            FROM     Route_Processing_Sheet__c
            WHERE    Route_Schedule__r.Processing_Location__c IN  :processingLocations
            AND      Route_Fill_Date__c                        =  :routeFillDate
            GROUP BY Route_Schedule__r.Route__r.Name,
                     Route_Schedule__r.Route__c,
                     Processing_Location__c
            ORDER BY Route_Schedule__r.Route__r.Name ASC
        ];
        return routeRpsAgr;
    }

    /**
     * Retrieves all rps for Burr Ridge and today and creates an object that will be stripped apart into HTML.
     *
     * @param  region aka processing location
     * @return a ProcessingFillSummary instance to be consumed by the client.
     * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/1739514537
     */
    public static ProcessingFillSummary retrieveRpsFillDataResults(String region) {

        ProcessingFillSummary processingFillSummary = new ProcessingFillSummary();

        Date routeFillDate = Date.today();
        processingFillSummary.processingLocation = region;

        List<AggregateResult> routeRpsAggregateResults = retrieveRpsFillData(new Set<String> {region}, routeFillDate);

        for (AggregateResult ar : routeRpsAggregateResults) {

            Id routeId = (Id) ar.get('Route__c');
            String routeName = (String) ar.get('Name');
            String processingLocation = (String) ar.get('Processing_Location__c');
            Decimal c1NoteCountOutbound = (Decimal) ar.get('c1NoteCountOutbound');
            Decimal c5NoteCountOutbound = (Decimal) ar.get('c5NoteCountOutbound');
            Decimal c20NoteCountOutbound = (Decimal) ar.get('c20NoteCountOutbound');
            //  Changed below from 20 to 50
            Decimal c50NoteCountOutbound = (Decimal) ar.get('c50NoteCountOutbound');
            Decimal c100NoteCountOutbound = (Decimal) ar.get('c100NoteCountOutbound');
            Decimal outboundTotal = (Decimal) ar.get('outboundTotal');

            RouteNoteCount rnc = new RouteNoteCount(routeId, routeName, processingLocation);
            rnc.noteCount1 = new NoteCount(1, c1NoteCountOutbound,processingLocation);
            rnc.noteCount5 = new NoteCount(5, c5NoteCountOutbound,processingLocation);
            rnc.noteCount20 = new NoteCount(20, c20NoteCountOutbound,processingLocation);
            rnc.noteCount50 = new NoteCount(50, c50NoteCountOutbound,processingLocation);
            rnc.noteCount100 = new NoteCount(100, c100NoteCountOutbound,processingLocation);
            rnc.totalValue = outboundTotal;

            processingFillSummary.routeNoteCounts.add(rnc);
        }
        if(!routeRpsAggregateResults.isEmpty()) {
            NoteCount totalNoteCount1 = new NoteCount(1, 0);
            NoteCount totalNoteCount5 = new NoteCount(5, 0);
            NoteCount totalNoteCount20 = new NoteCount(20, 0);
            NoteCount totalNoteCount50 = new NoteCount(50, 0);
            NoteCount totalNoteCount100 = new NoteCount(100, 0);

            for (RouteNoteCount rnc : processingFillSummary.routeNoteCounts) {
                totalNoteCount1.value += rnc?.noteCount1?.value != null ? rnc?.noteCount1?.value : 0;
                totalNoteCount5.value += rnc?.noteCount5?.value != null ? rnc?.noteCount5?.value : 0;
                totalNoteCount20.value += rnc?.noteCount20?.value != null ? rnc?.noteCount20?.value : 0;
                totalNoteCount50.value += rnc?.noteCount50?.value != null ? rnc?.noteCount50?.value : 0;
                totalNoteCount100.value += rnc?.noteCount100?.value != null ? rnc?.noteCount100?.value : 0;
            }
            processingFillSummary.grandTotals.add(totalNoteCount1);
            processingFillSummary.grandTotals.add(totalNoteCount5);
            processingFillSummary.grandTotals.add(totalNoteCount20);
            processingFillSummary.grandTotals.add(totalNoteCount50);
            processingFillSummary.grandTotals.add(totalNoteCount100);
        } else {
            processingFillSummary.errorMsg = ' No Route processing sheets found for '+ routeFillDate.format();
        }

        return processingFillSummary;
    }

    public class ProcessingFillSummary {
        @AuraEnabled public String processingLocation;
        @AuraEnabled public String errorMsg;
        @AuraEnabled public List<NoteCount> grandTotals;
        @AuraEnabled public List<RouteNoteCount> routeNoteCounts;

        public ProcessingFillSummary() {
            this.grandTotals = new List<NoteCount>();
            this.routeNoteCounts = new List<RouteNoteCount>();
        }
    }

    public class RouteNoteCount {

        @AuraEnabled public Id        routeId;
        @AuraEnabled public String    routeName;
        @AuraEnabled public String    processingLocation;
        @AuraEnabled public NoteCount noteCount1;
        @AuraEnabled public NoteCount noteCount5;
        @AuraEnabled public NoteCount noteCount20;
        @AuraEnabled public NoteCount noteCount50;
        @AuraEnabled public NoteCount noteCount100;
        @AuraEnabled public Decimal   totalValue;

        public RouteNoteCount(Id routeId, String routeName, String processingLocation) {
            this.routeID = routeId;
            this.routeName = routeName;
            this.processingLocation = processingLocation;
            this.noteCount1 = new NoteCount(1,0);
            this.noteCount5 = new NoteCount(5,0);
            this.noteCount20 = new NoteCount(20,0);
            //  Changed below from 20 to 50
            this.noteCount50 = new NoteCount(50,0);
            this.noteCount100 = new NoteCount(100,0);
        }
    }

    public class NoteCount {
        @AuraEnabled public String processingLocation;
        @AuraEnabled public Integer denom;
        @AuraEnabled public Decimal value;

        public NoteCount(Integer pDenom,Decimal pValue,String processingLocation) {
            this.processingLocation = processingLocation;
            this.denom = pDenom != null ? pDenom : 0;
            this.value = pValue != null ? pValue : 0;
        }
        public NoteCount(Integer pDenom,Decimal pValue) {
            this.denom = pDenom != null ? pDenom : 0;
            this.value = pValue != null ? pValue : 0;
        }
    }
    /**
     * An object wrapping email data.
     */
    public class EmailData {
        public Id dummyRecipientId;
        public List<String> emailAddresses;
        public Id templateId;
        public String dynamicHtml;
        public String dynamicSubject;
        public Boolean saveAsActivity = false;
    }
    /**
     * Create a payload using external email addresses and a dummy recipient address (dummy contact)
     * Fire the send method.
     *
     * @param emailDatas  A List of EmailData objects.
     * @return            A List of the result of sending emails
     */
    public static List<Messaging.SendEmailResult> sendEmailTemplates(List<EmailData> emailDatas) {

        List<BulkEmailExternalPayload> payloads = new List<BulkEmailExternalPayload>();
        for(EmailData data : emailDatas ) {
            BulkEmailExternalPayload payload = new BulkEmailExternalPayload();

            payload.owaEmailAddy = DEFAULT_OWA_EMAIL_ADDRESS;
            payload.dummyRecipientId = data.dummyRecipientId;
            payload.externalEmailAddresses = new Set<String>();
            for(String emailAddy : data.emailAddresses) {
                payload.externalEmailAddresses.add(emailAddy);
            }
            payload.replyTo = DEFAULT_NO_REPLY_ADDRESS;
            payload.templateId = data.templateId;
            payload.dynamicHtml = data.dynamicHtml;
            payload.dynamicSubject = data.dynamicSubject;
            payload.setSaveAsActivity = data.saveAsActivity;
            payload.setBccSender = false;
            payload.useSignature = false;

            payloads.add(payload);
        }
        List<Messaging.SendEmailResult> sendResults = sendEmailTemplatesExternal(payloads);
        return sendResults;
    }

    /**
     * Get org wide address for the sender, Fake a rendering of the template so that we can inject html into it.
     * Set the subject and other key info and fire send.
     *
     * @param payloads  A List of BulkEmailExternalPayload objects.
     * @return          A List of results of the email send(s).
     */
    public static List<Messaging.SendEmailResult> sendEmailTemplatesExternal( List<BulkEmailExternalPayload> payloads  ) {

        Messaging.SendEmailResult[] results;
        List<Messaging.SingleEmailMessage> msgs = new List<Messaging.SingleEmailMessage>();

        //  Preps OWAs if any.
        Set<String> owaEmailAddys = new Set<String>();
        for(BulkEmailExternalPayload payload : payloads) {
            if(!String.isBlank(payload.owaEmailAddy)) {
                owaEmailAddys.add(payload.owaEmailAddy);
            }
        }
        Map<String,OrgWideEmailAddress> mOwasByEmailAddy = new Map<String,OrgWideEmailAddress>();
        if(!owaEmailAddys.isEmpty()) {
            mOwasByEmailAddy = EmailSvc.retrieveOwas(owaEmailAddys);
        }

        //  Main msg building iteration.
        for(BulkEmailExternalPayload payload : payloads) {

            if( String.isNotBlank(payload.replyTo)) {
                payload.replyTo = DEFAULT_NO_REPLY_ADDRESS;
            }
            if( String.isNotBlank(payload.owaEmailAddy)) {
                if(!mOwasByEmailAddy.isEmpty()) {
                    payload.owa = mOwasByEmailAddy.get(payload.owaEmailAddy);
                }
            }
            for(String emailAddress: payload.externalEmailAddresses) {
                System.debug('emailADdress='+emailAddress);

                Messaging.SingleEmailMessage msg;
                try {
                    //  Replace all merge fields.
                    msg = Messaging.renderStoredEmailTemplate(payload.templateId, payload.dummyRecipientId, null);
                    String dynaHtml = payload.dynamicHtml;

                    if(msg.getHtmlBody() != null && msg.getHtmlBody().contains(CUSTOM_DYNAMIC_HMTL_TOKEN) && dynaHtml != null) {
                        String newBody = injectCustomHtmlInBody( msg.getHtmlBody(), dynaHtml);
                        msg.setHtmlBody(newBody);
                    }
                    msg.toAddresses = new List<String>();
                    msg.setToAddresses(new List<String> {EmailAddress});
                    //msg.

                    //  Build the basic email msg.
                    //msg.setSubject(msg.getSubject());
                    msg.setSubject(payload.dynamicSubject);
                    msg.setHtmlBody(msg.getHtmlBody());
                    if(payload.owa != null) {
                        msg.setOrgWideEmailAddressId(payload.owa.Id);
                    } else {
                        msg.setSenderDisplayName(DEFAULT_SENDER_DISPLAY_NAME);
                    }
                    msg.setReplyTo(payload.replyTo);
                    msg.setUseSignature(payload.useSignature);
                    msg.setBccSender(payload.setBccSender);
                    msg.setSaveAsActivity(payload.setSaveAsActivity);
                    msg.setTemplateId(payload.templateId);

                    msgs.add(msg);

                } catch (Exception e) {
                    //   Most likely user put a bad merge variable in the template!
                    System.debug(LoggingLevel.ERROR,'Error rendering template:' + e.getStackTraceString());
                    continue;
                }
            }
        }
        if(!msgs.isEmpty()) {
            System.debug(LoggingLevel.DEBUG,'---> sending '+msgs.size() + ' email messages');
            results = Messaging.sendEmail( msgs );
        }
        return results;
    }

   /**
    * @param sBody         The original html body.
    * @param dynamicHtml   The html to replace the token with in the Email Template.
    *
    * @return              The new html body replacing the token found with the dynamic html passed in.
    */
    private static String injectCustomHtmlInBody(String sBody, String dynamicHtml) {
        if(sBody != null) {
            sBody = sBody.replace(CUSTOM_DYNAMIC_HMTL_TOKEN,dynamicHtml);
        }
        return sBody;
    }

}