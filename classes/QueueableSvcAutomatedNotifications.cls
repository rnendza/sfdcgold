/**
 * The class will run on an interval as determined by it's scheduling class (probably every minute).
 * It will looking for not dispatched SAs that have been available for 3-4 for minutes and send an automated
 * notification.
 *
 * @see Svc_Utility_Bar_Settings__mdt
 * @see Sch_QueueableSvcAutomationNotifications
 * @see CustomNotificationsSvc
 */
global class QueueableSvcAutomatedNotifications implements Queueable {

    static final String                         META_SETTING_NOT_DISPATCHED = 'Accepted_But_Not_En_route';
    static final String                         NOTIFICATION_API_NAME       = 'TEST_SERVICE_WATCHDOG_NOTIFICATION';
    static Svc_Utility_Bar_Settings__mdt        notDispatchedMdt;

    //  Mostly query defaults.
    static List<String>                         profileNamesToWatch   = new List<String>{'Accel Call Center'};
    static List<String>                         caseStatusesToExclude = new List<String>{'Closed'};
    static List<String>                         svcApptStatusesToFind = new List<String>{'Scheduled', 'None'};
    static String                               caseCreatedByOverride = null;
    static Integer                              iMaxMinutesBeforeSend = 2;
    static Date                                 svcApptCreatedDate    = Date.today().addDays(-1);
    static String                               notificationType      = 'Automated';
    static String                               alertType             = 'NOT_DISPATCHED';

    //  Retrieve MDT for dynamic query params
    static {
        notDispatchedMdt = (Svc_Utility_Bar_Settings__mdt) CustomMetadataSvc.retrieveCustomSearchMeta(
                Svc_Utility_Bar_Settings__mdt.getSObjectType(), META_SETTING_NOT_DISPATCHED);

        profileNamesToWatch     = notDispatchedMdt?.Profile_Names_to_Watch__c != null ? notDispatchedMdt.Profile_Names_to_Watch__c.split(',') : profileNamesToWatch;
        caseCreatedByOverride   = notDispatchedMdt?.Case_Created_Override__c != null ? notDispatchedMdt.Case_Created_Override__c : caseCreatedByOverride;
        iMaxMinutesBeforeSend   = notDispatchedMdt?.Notification_Msg_Send_Age_Mins__c != null ? Integer.valueOf(notDispatchedMdt.Notification_Msg_Send_Age_Mins__c) : iMaxMinutesBeforeSend;
    }

    /**
     * Implments the queueable execute interface.
     *
     * @param ctx The Queueable context.
     */
    global void execute(QueueableContext ctx){
        System.debug(LoggingLevel.INFO, '---> in queuableSvcAutomations with ctx: '+ctx + ' settings='+notDispatchedMdt);
        processNotDispatched();
    }

    /**
     * Retrieves not dispatched service appointments that have not already had automated sends and fit within the criteria.
     *
     * ie. Case status ['Closed'], Created date today or yesterday, Service Appointment Status ['Scheduled','None'],
     * Pending acceptance time >= dyna setting in MDT ie. 2 or 3 minutes (Because the scheduled job runs every 1 minute
     * so there is some lag time.
     *
     * Use these service appointments to send custom notifications and ultimately record the send
     * in Custom_Notifications_Sent__c
     *
     * @see ServiceAppointmentSvc
     * @see CustomNotificationsSvc
     */
    public void processNotDispatched() {

        List<ServiceAppointment> serviceAppointments = [
                SELECT Id,Work_Order__r.Case.Assigned_Resource__c
                FROM ServiceAppointment
                WHERE Status                        IN  :svcApptStatusesToFind
                AND CreatedDate                     >=  :svcApptCreatedDate
                AND Work_Order__r.Case.Status   NOT IN  :caseStatusesToExclude
                AND Pending_Acceptance_Time__c      >=  :iMaxMinutesBeforeSend
                AND (CreatedBy.Profile.Name IN :profileNamesToWatch OR CreatedBy.Name LIKE :caseCreatedByOverride )
                AND Id NOT IN (
                        SELECT Service_Appointment__c
                        FROM Custom_Notifications_Sent__c
                        WHERE Notification_Type__c = :notificationType
                )
                ORDER BY Work_Order__r.Case.Age_of_Case_Hours__c DESC
        ];
        System.debug(LoggingLevel.INFO, '----> queueable: found ' + serviceAppointments.size() +
                ' Service Appointments meeting initial not dispatched criteria : ' + serviceAppointments);

        if (!serviceAppointments.isEmpty()) {
            ServiceAppointmentSvc.sendServiceAppointmentAlerts( serviceAppointments,alertType, notificationType,
                                                                NOTIFICATION_API_NAME, notDispatchedMdt.Notification_Msg_Title__c,
                                                                notDispatchedMdt.Notification_Msg_Body__c);
        }
    }
}