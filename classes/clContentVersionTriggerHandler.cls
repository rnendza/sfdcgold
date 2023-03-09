public class clContentVersionTriggerHandler {

    //public final static String ROUTE_IMPORT_RESULT_SUCCESS = 'Route Import Success';
    // @see fileupload cmp in clRelatedFiles.html
    // ie.  file-field-name="Cash_Logistics_Upload_Type_fileupload__c" file-field-value="Route Import"
    public final static String ROUTE_IMPORT_RESULT_SUCCESS = 'Route Import';

    public static void handleTriggerEvent(  List<ContentVersion> newCvs,
                                            Map<Id, ContentVersion>  mOldCvs,
                                            Map<Id, ContentVersion>  mNewCvs,
                                            System.TriggerOperation triggerOpp) {
        switch on triggerOpp {
            when AFTER_INSERT {
                pingClientForRouteSuccesses(mNewCvs.values(), PlatformEventSvc.DML_ACTION_INSERT);
            }
//            when AFTER_DELETE {
//               @todo must test delete on contentdoc!
//                pingClientForRouteSuccesses(mOldCvs.values(), PlatformEventSvc.DML_ACTION_DELETE);
//            }
        }
    }
    private static void pingClientForRouteSuccesses(List<ContentVersion> newCvs,String transactionType) {

        Set<Id> cdIds = new Set<Id>();
        for(ContentVersion cv : newCvs) {
            System.debug('---> cv retrieved = '+cv);
            if(cv.Cash_Logistics_Upload_Type_fileupload__c == ROUTE_IMPORT_RESULT_SUCCESS ) {
                cdIds.add(cv.ContentDocumentId);
            }
        }
        if(!cdIds.isEmpty()) {
            Map<Id, ContentVersion> mCvs = ContentManagerSvc.retrieveContentVersions(cdIds);
            System.debug('---> cvs='+mCvs);
            firePlatformEvents(mCvs.values(), transactionType);
        }
    }
    private static void firePlatformEvents(List<ContentVersion> cvs, String transactionType) {
        List<Content_Version_PE__e> events = new List<Content_Version_PE__e>();
        for(ContentVersion cv : cvs) {
            Content_Version_PE__e event = new Content_Version_PE__e();
            event.Record_Id__c = cv.Id;
            event.Transaction_Type__c = transactionType;
            events.add(event);
        }
        PlatformEventSvc.publishPlatformEvents(events);
    }
}