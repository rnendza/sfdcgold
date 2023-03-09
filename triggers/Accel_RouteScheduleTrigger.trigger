trigger Accel_RouteScheduleTrigger on Route_Schedule__c (before update,after update) {

    //  @todo store in trigger settings custom mdt to allow easy switch on / off
    Boolean runTrigger = true;

    if (runTrigger) {
        clRouteScheduleTriggerHandler.handleTriggerEvent(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.operationType);
    }

//    @TestVisible private final static String MDT_DEV_NAME_RPS_EMAIL = 'clQueueableRpsEmailer';
//
//    switch on Trigger.operationType {
//
//        when BEFORE_UPDATE {
//
//            for(Route_Schedule__c rsNew : Trigger.new) {
//                Route_Schedule__c rsOld = Trigger.oldMap.get(rsNew.Id);
//
//                if(rsNew.Total_Completed_Collections__c != rsOld.Total_Completed_Collections__c) {
//                    if (rsNew.Total_Completed_Collections__c >= rsNew.Total_Processing_Sheets__c) {
//                        rsNew.Collection_Status__c = 'COMPLETED COLLECTION';
//                    } else {
//                        rsNew.Collection_Status__c = 'Collection Incomplete';
//                    }
//                    rsNew.Collection_Status_Last_Modified_Date__c = System.now();
//                    rsNew.Collection_Status_Last_Modified_By__c = UserInfo.getUserId();
//                }
//                if(rsNew.Total_Not_Yet_Filled_Processing_Sheets__c != rsOld.Total_Not_Yet_Filled_Processing_Sheets__c) {
//                    if (rsNew.Total_Not_Yet_Filled_Processing_Sheets__c == 0) {
//                        rsNew.Schedule_Status__c = 'COMPLETED FILL';
//                    } else {
//                        rsNew.Schedule_Status__c = 'Fill Incomplete';
//                    }
//                    rsNew.Fill_Status_Last_Modified_By__c = UserInfo.getUserId();
//                    rsNew.Fill_Status_Last_Modified_Date__c = System.now();
//                }
//                if(rsNew.Total_Processing_Incomplete_RPS__c != rsOld.Total_Processing_Incomplete_RPS__c) {
//
//                    if (rsNew.Total_Processing_Incomplete_RPS__c == 0) {
//                        rsNew.Processing_Status__c = 'COMPLETED PROCESSING';
//                    } else {
//                        rsNew.Processing_Status__c = 'Processing Incomplete';
//                    }
//                    rsNew.Processing_Status_Last_Modified_Date__c = System.now();
//                    rsNew.Processing_Status_Last_Modified_By__c = UserInfo.getUserId();
//                }
//            }
//        }
//
//        when AFTER_UPDATE {
//            Cash_Logistics_Automation_Setting__mdt mdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_RPS_EMAIL);
//            //  Make sure automation setting denotes this process is active.
//            if(mdt.Active__c) {
//                for (Route_Schedule__c rsNew : Trigger.new) {
//                    Route_Schedule__c rsOld = Trigger.oldMap.get(rsNew.Id);
//                   /*
//                    *  User hits the end route button or admin toggles timestamp null / not null.
//                    */
//                    if (rsNew.Route_End_Timestamp__c != rsOld.Route_End_Timestamp__c && rsNew.Route_End_Timestamp__c != null) {
//                        Id jobId = clRouteScheduleSvc.sendRouteScheduleCompletedEmail(rsNew.Id);
//                        System.debug('----> firing queuable rps email. jobId=' + jobId);
//                    }
//                }
//            }
//        }
//    }

}