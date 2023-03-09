public with sharing class CustomNotificationsSvc {

    static String DEFAULT_TARGET_ID = '000000000000000AAA';

    /**
     * This will use the sObjectApiName to determine the proper query filter to utilize and find all the
     * Custom_Notifications_Sent__c records for the given targetId.
     *
     * @param sobjectApiName the api name of the sObject (Not case sensitive).
     * @param targetId the target record id.. ie ServiceAppointment.Id or other objects when added.
     *
     * @return a List of Custom_Notifications_Sent__c sObjects.
     */
    public static List<Custom_Notifications_Sent__c> retrieveNotificationsSent( String sObjectApiName, Id targetId) {
        List<Custom_Notifications_Sent__c> customNotifications;
        switch on sObjectApiName.toLowerCase() {
            when 'serviceappointment' {
                customNotifications = retrieveNotificationsByServiceAppointments(targetId);
            }
        }
        return customNotifications;
    }

    /**
     * Retrieves Custom_Notifications_Sent__c sObjects for a particular service appointment Id.
     *
     * @param svcApptId  The Id of the ServiceAppointment to filter the results by.
     * @return a List of Custom_Notifications_Sent__c sObjects.
     *
     */
    public static List<Custom_Notifications_Sent__c> retrieveNotificationsByServiceAppointments(Id svcApptId) {
        List<Custom_Notifications_Sent__c> customNotifications = [
                SELECT Id, Name, Alert_Type__c, Custom_Notification_Api_Name__c, User__c, CreatedDate, Notification_Type__c
                FROM   Custom_Notifications_Sent__c
                WHERE  Service_Appointment__c = :svcApptId
        ];
        return customNotifications;
    }

    /**
     * Sends a custom notification using the messaging api. Builds (not inserts) a Custom_Notification_Sent__c
     * sObject to return to the client.
     *
     * @param recipientIds      The userIds to send the custom notification to.
     * @param targetId          The targetId ie. service appointment id of the notification or any other sObject Id.
     * @param apiName           The developer name of the notification type. ie. CustomNotificationType.DeveloperName.
     * @param alertType         The type of alert ['NOT_DISPATCHED']
     * @param notificationType  The notification type ['Automated','Manual]
     * @param msgTitle          The title of the message being sent.
     * @param msgBody           The body of the message being sent.
     *
     * @return  Custom_Notification_Sent__c sObject.
     *
     * @see https://developer.salesforce.com/docs/atlas.en-us.228.0.apexcode.meta/apexcode/apex_class_Messaging_CustomNotification.htm
     *
     * @todo void return on Messaging Api. how do we confirm success / how to we send in batch?
     */
    public static Custom_Notifications_Sent__c sendNotification(Set<String> recipientIds, Id targetId,String apiName,
                                                                 String alertType, String notificationType,
                                                                 String msgTitle, String msgBody) {

        Custom_Notifications_Sent__c notificationSent = new Custom_Notifications_Sent__c();

        Messaging.CustomNotification customNotification = new Messaging.CustomNotification();
        CustomNotificationType type = retrieveNotificationType(apiName);
        if(type != null) {
            String userId;
            if(targetId == null) targetId = DEFAULT_TARGET_ID; // prevent api exception.
            customNotification.setNotificationTypeId(type.Id);
            customNotification.setTargetId(targetId);
            customNotification.setTitle(msgTitle);
            customNotification.setBody(msgBody);
            customNotification.send(recipientIds);
            if(!recipientIds.isEmpty()) {
                userId = (new list<string>(recipientIds) )[0];
            }
            notificationSent = buildCustomNotificationSent(targetId,apiName,alertType,notificationType,userId,msgTitle,msgBody);
        }
        return notificationSent;
    }

    /**
     * Builds (but not inserts) a Custom_Notifications_Sent__c sObject.
     *
     * @param targetId          The service appointment Id otherwise null.
     * @param apiName           The developer name of the notification type. ie. CustomNotificationType.DeveloperName.
     * @param alertType         The type of alert ['NOT_DISPATCHED']
     * @param notificationType  The notification type ['Automated','Manual]
     * @param userId            The recipient id (ie user id) to send the notification to.
     * @param msgTitle          The title of the message being sent.
     * @param msgBody           The body of the message being sent.
     *
     * @return                  A non-inserted Custom_Notifications_Sent__c sObject.
     */
    public static Custom_Notifications_Sent__c buildCustomNotificationSent( Id targetId, String apiName, String alertType,
                                                                            String notificationType, Id userId,
                                                                            String msgTitle, String msgBody) {

        Custom_Notifications_Sent__c record = new Custom_Notifications_Sent__c();

        record.Custom_Notification_Api_Name__c = apiName;
        record.Alert_Type__c = alertType;
        record.Notification_Type__c = notificationType;
        record.Msg_Title__c = msgTitle;
        record.User__c = userId;
        record.Msg_Body__c = msgBody;

        if(targetId != DEFAULT_TARGET_ID) {
            if (targetId.getSObjectType() == ServiceAppointment.getSObjectType()) {
                record.Service_Appointment__c = targetId;
            }
        }
        return record;
    }

    /**
     * Retrieves a CustomNotificationType sObject (set in the SFDC UI).
     *
     * @param  apiName The api name. ie developer name of the custom notification type.
     * @return A Custom_Notification_Type__c sObject if found, otherwise null.
     */
    public static CustomNotificationType retrieveNotificationType(String apiName) {
        CustomNotificationType notificationType;

        List<CustomNotificationType> types = [
                SELECT Id,Description,CustomNotifTypeName,Language,Desktop,Mobile
                FROM   CustomNotificationType
                WHERE  DeveloperName = :apiName
        ];
        if(!types.isEmpty()) {
            notificationType = types[0];
        }
        return notificationType;
    }
}