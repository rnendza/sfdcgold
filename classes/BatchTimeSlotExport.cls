/**
 * Service Resource: Schedules report (export from Gantt)
 * https://accelentertainment.atlassian.net/browse/SAM-212
 *
 * Each week, the RSM's update the expected schedules of their technicians. This translates into an area on the Gantt
 * chart, denoted in white, that shows the availability versus the scheduled jobs. The Call Center would like to find
 * where this information is held, and export it on a daily basis.
 */
global class BatchTimeSlotExport implements Database.Batchable<Sobject>, Database.Stateful {

    global final static String  SETTING_NAME            = 'Time_Slot_Export';
    global final static String  DAYOFWEEK_FORMAT        = 'EEEE';
    global final static String  ATTACHMENT_CONTENT_TYPE = 'text/csv';
    global final static String  ATTACHMENT_FILE_EXT     = '.csv';
    global final static String  OWA_EMAIL_ADDY          = 'crm@accelentertainment.com';
    global final static String  RSM_APP_HOME_URL        = '/lightning/n/RSM_App_Home';

    global String                           sTerritoryType      = '';
    global Map<Id, List<TimeSlot>>          mOhId_TimeSlots     = new Map<Id,List<TimeSlot>>();
    global Map<Id, ServiceTerritoryMember>  mOhId_Stm           = new Map<Id, ServiceTerritoryMember>();
    global List<TimeSlotWrapper>            timeSlotWrappers    = new List<TimeSlotWrapper>();
    global List<String>                     daysOfWeek          = new List<String>();
    global Export_Settings__mdt             exportSettings      = null;
    @TestVisible static Integer             numTimeSlotWraps    = 0;

    /**
     * Simple no-arg constructor.. Grab metadata.
     */
    global BatchTimeSlotExport() {
        this.initSettings();
    }
    /**
     * Inits settings from custom metadata.
     * @param pTerritoryType the TerritoryType on ServiceMemberTerritory.
     */
    @TestVisible
    private void initSettings() {

        exportSettings = (Export_Settings__mdt)CustomMetadataSvc.retrieveCustomSearchMeta(
                Export_Settings__mdt.getSObjectType(),SETTING_NAME
        );
        this.sTerritoryType = exportSettings.Default_Service_Member_Territory_Type__c;
        //-------------------daysOfWeek.add( System.now().format( DAYOFWEEK_FORMAT ) );
        daysOfWeek = buildDaysOfWeek( exportSettings );
    }
    /**
     * Retrieves all Active Service Territory Members with Operating Hours Ids and of the Territory
     * Type set in custom metadata.
     *
     * @param bc
     * @return a query locator with a list of ServiceTerritoryMembers.
     */
    global database.querylocator start(Database.BatchableContext bc) {

        return Database.getQueryLocator([
                SELECT  Id, EffectiveStartDate, EffectiveEndDate,
                        ServiceResource.Accel_User__c,ServiceResource.Accel_User__r.Name,
                        ServiceResource.Accel_User__r.FirstName,ServiceResource.Accel_User__r.LastName,
                        ServiceTerritory.Name,OperatingHoursId,OperatingHours.Name, TerritoryType
                FROM    ServiceTerritoryMember
                WHERE   OperatingHoursId                        != NULL
                AND     TerritoryType                           = :sTerritoryType
                AND     ServiceResource.Accel_User__r.IsActive  = TRUE
                ORDER BY
                        ServiceTerritory.Name                   ASC,
                        ServiceResource.Accel_User__r.FirstName ASC
        ]);
    }
    /**
     * Parse out Service Territory Members into a map of operating hours id => ServiceTerritoryMember.
     * Retrieve Operating Hour Time Slots with operating hours Ids for daysOfWeek.
     * Create a map of operating hours ids =>  List<TimeSlots>
     *
     * @param bc
     * @param stms  a list of ServiceTerritoryMembers.
     */
    global void execute( Database.BatchableContext bc, List<ServiceTerritoryMember> stms ) {

        for(ServiceTerritoryMember stm : stms ) {
            mOhId_Stm.put(stm.OperatingHoursId, stm);
        }
        mOhId_TimeSlots.putAll(TerritorySvc.retrieveOppHourTimeSlots(mOhId_Stm.keySet(), daysOfWeek));
    }
    /**
     * Build the list of TimeSlotWrappers, Convert to CSV and attach to an email and send.
     *
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {

        timeSlotWrappers = FSLUtils.buildTimeSlotWrappers( mOhId_TimeSlots,mOhId_Stm );
        numTimeSlotWraps = timeSlotWrappers.size();
        sendEmail();
    }
    /**
     * Build the subject, body, and csv attachment and send the email.
     */
    global void sendEmail() {

        String subject = exportSettings.Email_Subject__c;
        String body = buildEmailBody();
        List<Messaging.EmailFileAttachment> emailFileAttachments;
        Messaging.EmailFileAttachment csvAttc = buildCsvAttachment();
        if(csvAttc != null && csvAttc.getBody() != null) {
            emailFileAttachments = new List<Messaging.EmailFileAttachment>();
            emailFileAttachments.add( csvAttc );
        }
        EmailSvc.sendEmail( getEmailAddys(),null,subject,body,emailFileAttachments,OWA_EMAIL_ADDY );
    }
    /**
     *
     * @return an EmailFileAttachment with csv content if results are retrieved.
     */
    global Messaging.EmailFileAttachment buildCsvAttachment() {

        Messaging.EmailFileAttachment csvAttc   = new Messaging.EmailFileAttachment();
        String csvName                          = exportSettings.Export_File_Prefix__c+'_'+System.now()+ATTACHMENT_FILE_EXT;
        TimeSlotWrapperCsv csvBuilder           = new TimeSlotWrapperCsv();
        String csvData                          = csvBuilder.generateTimeSlotWrapperCsv( timeSlotWrappers );

        if(csvData != null && csvData != '') {
            Blob csvBlob = Blob.valueOf(csvData);
            csvAttc.setFileName(csvName);
            csvAttc.setContentType( ATTACHMENT_CONTENT_TYPE );
            csvAttc.setBody(csvBlob);
        }
        return csvAttc;
    }
   /**
    * @return a string of the body of the email.
    */
    global String buildEmailBody() {

        String body = '';
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String col2Style = '';
        body += '<div>';
        body += '<div>';
        body += '<span>Attached is an export of todays timeslot records.</span>';
        body += '</div>';
        body += '<br/><br/><b> ========= Run Time Stats ========= </b><br/>';
        body += '<table style="" padding="1">';
        body += '<tr>';
        body += '<td style="">RSM App Home:</td>';
        body += '<td style="' + col2Style + '">' + baseUrl + RSM_APP_HOME_URL + '</td>';
        body += '</tr>';
        body += '<tr>';
        body += '<td style=""># of records exported:</td>';
        body += '<td style="' + col2Style + '">' + numTimeSlotWraps + '</td>';
        body += '</tr>';
        body += '<tr>';
        String colHeading = daysOfWeek.size() > 1 ? 'TimeSlot Days Queried:' : 'TimeSlot Day Queried:';
        body += '<td style="">'+colHeading+'</td>';
        body += '<td style="' + col2Style + '">' + daysOfWeek + '</td>';
        body += '</tr>';
        body += '</table>';
        body += '</div>';
        return body;
    }
    /**
     * @return a List of email addresses to send the email to (set in custom metadata)
     */
    global List<String> getEmailAddys() {

        List<String> emailAddys = new List<String>();
        String sEmailAddys = exportSettings.Distribution_Email_Addys__c;
        emailAddys = sEmailAddys.split(',');
        return emailAddys;
    }
    /*
     *
     * @return
     */
    @TestVisible
    private List<String> buildDaysOfWeek( Export_Settings__mdt exportSettings )  {
        List<String> daysOfWeek = new List<String>();
        String dayOfWeekOverride = exportSettings.Day_of_Week_Override__c;
        if(dayOfWeekOverride != null && dayOfWeekOverride!='') {
            daysOfWeek  = dayOfWeekOverride.split(',');
        } else  {
            daysOfWeek.add( System.now().format( DAYOFWEEK_FORMAT ) );
        }
        return daysOfWeek;
    }
}