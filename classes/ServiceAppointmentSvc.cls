/**
 * ServiceAppointmentsSvc will provide for all operations around a ServiceAppointment
 */
public with sharing class ServiceAppointmentSvc {

    /**
     * Sends a service appointment custom notification and records the send in Customer_Notifications_Sent__c
     *
     * @param serviceAppointments   A List of ServiceAppointment sObjects.
     * @param alertType             The alert type. [NOT_DISPATCHED].
     * @param notificationType      The notification type [Automated,Manual].
     * @param apiName               The api name of the custom notification.
     * @param msgTitle              The notification msg Title.
     * @param msgBody               The notification msg Body.
     */
    public static void sendServiceAppointmentAlerts(    List<ServiceAppointment> serviceAppointments,String alertType,
                                                        String notificationType, String apiName, String msgTitle, String msgBody) {

        String debugMsg = 'Sending Notifications for '+serviceAppointments.size() + ' service appointments';
        debugMsg += '\n alertType ='+alertType + '..notificationType ='+notificationType + '..apiName ='+apiName;
        debugMsg += '\n msgTitle ='+msgTitle + '..msgBody='+msgBody;
        System.debug(LoggingLevel.DEBUG,debugMsg);

        List<Custom_Notifications_Sent__c> notificationsSent = new List<Custom_Notifications_Sent__c>();

        //  Rolls through and sends one by one (requirements of current SFDC api )
        for(ServiceAppointment sa : serviceAppointments) {
            if(sa.Work_Order__r.Case.Assigned_Resource__c != null) {
                Set<String> recipientIds = new Set<String> {sa.Work_Order__r.Case.Assigned_Resource__c};

                Custom_Notifications_Sent__c notificationSent = CustomNotificationsSvc.sendNotification
                        (recipientIds, sa.Id, apiName, alertType, notificationType, msgTitle, msgBody);

                if(notificationSent != null ) {
                    notificationsSent.add(notificationSent);
                }
            }
        }
        //  Insert into Custom_Notifications_Sent__c
        if(!notificationsSent.isEmpty()) {
            // This assumes the send was successful (there is no way to know for sure)
            insert notificationsSent;
        }
        System.debug(LoggingLevel.DEBUG,'--> Saved notifications sent='+notificationsSent);
    }
}