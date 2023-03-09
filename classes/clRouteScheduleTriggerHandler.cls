public class clRouteScheduleTriggerHandler {

    @TestVisible private final static String MDT_DEV_NAME_RPS_EMAIL = 'clQueueableRpsEmailer';

    public static void handleTriggerEvent(  List<Route_Schedule__c> newRss,
                                            Map<Id, Route_Schedule__c>  mOldRss,
                                            Map<Id, Route_Schedule__c>  mNewRss,
                                            System.TriggerOperation triggerOpp) {
        switch on triggerOpp {
            when BEFORE_UPDATE {
                setStatuses(mOldRss,mNewRss);
            }
            when AFTER_UPDATE {
                sendRouteScheduleCompletedEmail(mOldRss,mNewRss);
                checkScheduleAssignments(mOldRss,mNewRss);
            }
        }
    }

    public static void setStatuses( Map<Id,Route_Schedule__c> mOldRss, Map<Id,Route_Schedule__c> mNewRss) {

        for(Route_Schedule__c rsNew : mNewRss.values()) {
            Route_Schedule__c rsOld = mOldRss.get(rsNew.Id);
            setCollectionStatus(rsOld,rsNew);
            setFillStatus(rsOld,rsNew);
            setProcessingStatus(rsOld,rsNew);
        }
    }

    public static void checkScheduleAssignments( Map<Id,Route_Schedule__c> mOldRss, Map<Id,Route_Schedule__c> mNewRss) {
        Map<Id,Route_Schedule__c> mRsWithAssignmentsModified = new Map<Id,Route_Schedule__c>();
        for(Route_Schedule__c rsNew : mNewRss.values()) {
            Route_Schedule__c rsOld = mOldRss.get(rsNew.Id);
            if(rsNew.Collector_1__c != rsOld.Collector_1__c || rsNew.User__c != rsOld.User__c) {
                mRsWithAssignmentsModified.put(rsNew.Id,rsNew);
            }
        }
        if(!mRsWithAssignmentsModified.isEmpty()) {
            firePlatformEvent(mRsWithAssignmentsModified);
        }
    }
    @TestVisible
    private static void firePlatformEvent(Map<Id,Route_Schedule__c> mRouteSchedules) {
        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Set<String> sRsIds = new Set<String>();

        for(Route_Schedule__c rs : mRouteSchedules.values()) {
            sRsIds.add(rs.Id);
        }
        Route_Schedule_Change_PE__e changePe    = new Route_Schedule_Change_PE__e();
        changePe.Ui_Message__c                  = 'Route Schedule Assignments have been updated.';
        changePe.Route_Schedule_Ids__c          = String.join(new List<String>(sRsIds),',');
        changePe.Operation_Type__c              = PlatformEventSvc.DML_ACTION_UPDATE;
        changePe.Publishing_Process_Name__c     = 'clRouteScheduleTriggerHandler_checkScheduleAssignments';
        changePe.Status__c = 'Complete';
        changePEs.add(changePe);

        PlatformEventSvc.publishPlatformEvents( changePes );
    }

    public static void sendRouteScheduleCompletedEmail( Map<Id,Route_Schedule__c> mOldRss, Map<Id,Route_Schedule__c> mNewRss) {

        Cash_Logistics_Automation_Setting__mdt mdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_RPS_EMAIL);
        //  Make sure automation setting denotes this process is active.
        if(mdt.Active__c) {
            for (Route_Schedule__c rsNew : mNewRss.values()) {
                Route_Schedule__c rsOld = mOldRss.get(rsNew.Id);
                /*
                 *  User hits the end route button or admin toggles timestamp null / not null.
                 */
                if (rsNew.Route_End_Timestamp__c != rsOld.Route_End_Timestamp__c && rsNew.Route_End_Timestamp__c != null) {
                    Id jobId = clRouteScheduleSvc.sendRouteScheduleCompletedEmail(rsNew.Id);
                    System.debug('----> firing queuable rps email. jobId=' + jobId);
                }
            }
        }
    }

//    @TestVisible
//    private static void setCollectionStatus(Route_Schedule__c rsOld, Route_Schedule__c rsNew) {
//
//        if(rsNew.Total_Completed_Collections__c != rsOld.Total_Completed_Collections__c) {
//
//            if (rsNew.Total_Completed_Collections__c >= rsNew.Total_Processing_Sheets__c) {
//                rsNew.Collection_Status__c = 'COMPLETED COLLECTION';
//            } else {
//                rsNew.Collection_Status__c = 'Collection Incomplete';
//            }
//            if(rsOld.Collection_Status__c != null) {
//                rsNew.Collection_Status_Last_Modified_Date__c = System.now();
//                rsNew.Collection_Status_Last_Modified_By__c = UserInfo.getUserId();
//            }
//        }
//    }
    @TestVisible
    private static void setCollectionStatus(Route_Schedule__c rsOld, Route_Schedule__c rsNew) {

        if(rsNew.Total_Completed_Collections__c != rsOld.Total_Completed_Collections__c
                || (rsNew.Total_Skipped_Collections__c != rsold.Total_Skipped_Collections__c) ) {
            Integer iTotal = Integer.valueOf(rsNew.Total_Completed_Collections__c + rsNew.Total_Skipped_Collections__c);
            if (iTotal >= rsNew.Total_Processing_Sheets__c) {
                rsNew.Collection_Status__c = 'COMPLETED COLLECTION';
            } else {
                rsNew.Collection_Status__c = 'Collection Incomplete';
            }
            if(rsOld.Collection_Status__c != null) {
                rsNew.Collection_Status_Last_Modified_Date__c = System.now();
                rsNew.Collection_Status_Last_Modified_By__c = UserInfo.getUserId();
            }
        }
    }

    @TestVisible
    private static void setFillStatus(Route_Schedule__c rsOld, Route_Schedule__c rsNew) {

        if(rsNew.Total_Not_Yet_Filled_Processing_Sheets__c != rsOld.Total_Not_Yet_Filled_Processing_Sheets__c) {
            if (rsNew.Total_Not_Yet_Filled_Processing_Sheets__c == 0) {
                rsNew.Schedule_Status__c = 'COMPLETED FILL';
            } else {
                rsNew.Schedule_Status__c = 'Fill Incomplete';
            }
            if(rsOld.Schedule_Status__c != null) {
                rsNew.Fill_Status_Last_Modified_By__c = UserInfo.getUserId();
                rsNew.Fill_Status_Last_Modified_Date__c = System.now();
            }
        }
    }

    @TestVisible
    private static void setProcessingStatus(Route_Schedule__c rsOld, Route_Schedule__c rsNew) {

        if(rsNew.Total_Processing_Incomplete_RPS__c != rsOld.Total_Processing_Incomplete_RPS__c) {
            if (rsNew.Total_Processing_Incomplete_RPS__c == 0) {
                rsNew.Processing_Status__c = 'COMPLETED PROCESSING';
            } else {
                rsNew.Processing_Status__c = 'Processing Incomplete';
            }
            if(rsOld.Processing_Status__c != null) {
                rsNew.Processing_Status_Last_Modified_Date__c = System.now();
                rsNew.Processing_Status_Last_Modified_By__c = UserInfo.getUserId();
            }
        }
    }
}