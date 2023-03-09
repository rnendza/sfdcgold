public class FslPocQuickActionController {

    public static final String MAP_KEY_NOTIFICATION_WRAPS = 'NOTIFICATION_WRAPS';

    /**
     * @param saId  The Service_Appointment__c.Id.
     * @return      A ResponseDto containing A List of Notification Wrapper objs in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveSaCustomNotifications(Id saId) {
        ResponseDto dto = new ResponseDto();

        List<Custom_Notifications_Sent__c> recs = [
                SELECT  Id,User__c,User__r.Name,Msg_Title__c,Msg_Body__c,Alert_Type__c,Notification_Type__c,
                        CreatedDate,Name
                FROM    Custom_Notifications_Sent__c
                WHERE   Service_Appointment__c = :saId
                ORDER BY CreatedDate DESC
        ];
        List<Notification> notificationWraps = buildNotificationWrappers(recs);

        dto.isSuccess = !notificationWraps.isEmpty();
        dto.values.put(MAP_KEY_NOTIFICATION_WRAPS,notificationWraps);

        return dto;
    }

    /**
     * @param recs  A list of Custom_Notification_Sent__c sObjects.
     * @return      A list of Notification wrapper objects.
     */
    private static List<Notification> buildNotificationWrappers(List<Custom_Notifications_Sent__c> recs) {
        List<Notification> wraps = new List<Notification>();

        for(Custom_Notifications_Sent__c rec : recs){
            wraps.add(new Notification(rec));
        }
        return wraps;
    }

    /**
     * A Wrapper class on top of Custom_Notification_Sent__c sObjects.
     */
    public class Notification {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String recordName;
        @AuraEnabled public String recordUrl;
        @AuraEnabled public Id recipientId;
        @AuraEnabled public String recipientName;
        @AuraEnabled public Datetime sentDate;
        @AuraEnabled public String alertType;
        @AuraEnabled public String msgTitle;

        public Notification(Custom_Notifications_Sent__c sentNotification) {
            this.recordId = sentNotification.Id;
            this.recordName = sentNotification.Name;
            this.recordUrl =  '/'+recordId;
            this.recipientId = sentNotification.User__c;
            this.recipientName = sentNotification.User__r.Name;
            this.sentDate = sentNotification.CreatedDate;
            this.alertType = sentNotification.Alert_Type__c;
            this.msgTitle = sentNotification.Msg_Title__c;
        }
    }
}