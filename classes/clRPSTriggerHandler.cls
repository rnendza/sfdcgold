public class clRPSTriggerHandler {

    public final static String RPS_COLLECTION_STATUS_COMPLETE = 'Complete';
    public final static String RPS_COLLECTION_STATUS_SKIPPED = 'Skipped';
    public final static String RPS_COLLECTION_STATUS_NOT_STARTED = 'Not Started';
    public final static String RPS_COLLECTION_STATUS_IN_PROGRESS = 'In Progress';

    public final static String RPS_COLLECTOR_RT_STATUS_COMPLETE = 'Complete';
    public final static String RPS_COLLECTOR_RT_STATUS_NOT_STARTED = 'Not Started';
    public final static String RPS_COLLECTOR_RT_STATUS_IN_PROGRESS = 'In Progress';

    public final static String MR_READING_STATUS_COMPLETED = 'Completed';
    public final static String MR_READING_STATUS_CANNOT_COLLECT= 'Cannot Collect';
    public final static Set<String> RPS_NO_RT_COLLECTION_TYPES = new Set<String>{
       'Additional Fill – VGT Only','Regular - VGT Only'
    };
    public final static Set<String> RPS_NO_VGT_COLLECTION_TYPES = new Set<String>{
            'Additional Fill – RT Only','Regular - RT Only'
    };


    public static void handleTriggerEvent(  List<Route_Processing_Sheet__c> newRpss,
                                            Map<Id, Route_Processing_Sheet__c>  mOldRpss,
                                            Map<Id, Route_Processing_Sheet__c>  mNewRpss,
                                            System.TriggerOperation triggerOpp) {
        switch on triggerOpp {
            when BEFORE_DELETE {
                checkDeleteSecurity(mOldRpss);
            }
            when BEFORE_UPDATE {
                System.debug('--- rps handler before update');
                setStatuses(mOldRpss,mNewRpss);
                truncateFields(mOldRpss,mNewRpss);
            }
            when AFTER_INSERT {
                /**
                 * OBSOLETE as of 1/27/2022
                 * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/2168458401
                 */
                //createPrevRps(mNewRpss);
            }
        }
    }

   /**
    * Checks CL Automation Custom Settings to determine if we wish to prevent delete for Route_Processing_Sheet__c.
    * If so, get the custom label to display a message to the user upon error (replace {0} token with dyna value)
    * and call addError on the sObject.
    *
    * @param  mOldsRpss Map of Id => Route_Processing_Sheet__c
    */
    public static void checkDeleteSecurity(Map<Id,Route_Processing_Sheet__c> mOldsRpss){
        
        Boolean preventDelete = clAutomationSvc.preventRecordDelete(clAutomationSvc.RPS_TRIGGER_PREVENT_DELETE);

        if(preventDelete) {
            for(Route_Processing_Sheet__c rps : mOldsRpss.values()) {
                String msg = String.format(Label.CL_RPS_Prevent_Delete, new List<String>{rps.Name});
                rps.addError(msg);
            }
        }
    }

//    /**
//     * Fire async job to update newly created Route_Processing_Sheet__c sObjects
//     * Previous_RT_Collection__c and Previous_VGT_Collection__c values.
//     *
//     * @param mRps  A Map of Id => Route_Processing_Sheet__c sObjects (Trigger.newMap)
//     * @todo how do we prevent firing too many queueables here on mass inserts.
//     */
//    @TestVisible
//    private static void createPrevRps(Map<Id,Route_Processing_Sheet__c> mRps) {
//        clQueueablePreviousRps q = new clQueueablePreviousRps(mRps);
////        clQueueablePreviousRps_20 q = new clQueueablePreviousRps_20(mRps);
//        Id jobId = System.enqueueJob(q);
//        System.debug(LoggingLevel.INFO,'firing queueable to update prev rps jobId:'+jobId);
//    }



    public static void setStatuses( Map<Id,Route_Processing_Sheet__c> mOldRpss, Map<Id,Route_Processing_Sheet__c> mNewRpss) {

        //Formula.recalculateFormulas(mNewRpss.values());
        Set<Id> rpsIdsNotCompletedMeters = findRpsWithNotCompletedMeterReadings(mNewRpss);
        for(Route_Processing_Sheet__c rpsNew : mNewRpss.values()) {
            Route_Processing_Sheet__c rpsOld = mOldRpss.get(rpsNew.Id);
            setProcessorFillStatus(rpsOld,rpsNew);
            setProcessorProcessingStatus(rpsOld,rpsNew);
            setCollectionStatus(rpsOld,rpsNew,rpsIdsNotCompletedMeters);
        }
    }

    public static void truncateFields( Map<Id,Route_Processing_Sheet__c> mOldRpss, Map<Id,Route_Processing_Sheet__c> mNewRpss) {
        for(Route_Processing_Sheet__c rpsNew : mNewRpss.values()) {
            Route_Processing_Sheet__c rpsOld = mOldRpss.get(rpsNew.Id);
            truncateNotes(rpsOld,rpsNew);
        }
    }

    @TestVisible
    private static void  setProcessorFillStatus( Route_Processing_Sheet__c rpsOld, Route_Processing_Sheet__c rpsNew) {
        if(rpsNew.Processing_Status__c != rpsOld.Processing_Status__c) {
            rpsNew.Processing_Status_Changed_By__c = UserInfo.getUserId();
            rpsNew.Processing_Status_Changed_Date__c = System.now();
        }
    }

    /**
     * Called in BEFORE_UPDATE. Potentially sets Processor_RT_Status__c and Processing_Process_Status__c.
     *
     * @param rpsOld  The old Route_Processing_Sheet__c sObject.
     * @param rpsNew  The new Route_Processing_Sheet__c sObject.
     *
     * @see Accel_RPSTriggerTest.test_updateProcessorProcessStatus
     */
    @TestVisible
    private static void  setProcessorProcessingStatus(  Route_Processing_Sheet__c rpsOld,
                                                        Route_Processing_Sheet__c rpsNew ) {

        //   1/3 if there are no RT Fields to Enter.. Set the RT processing status to Complete so  that the
        //   overall processing status gets set to COMPLETED PROCESSING if meter readings are processed correctly
        if(RPS_NO_RT_COLLECTION_TYPES.contains(rpsNew.Collection_Type__c)) {
            rpsNew.Processor_RT_Status__c = 'Complete';
        }

//        //  1/6 if there are no VGT Fields to Enter Do not check the count of complete meter readings and
//        //  just set the processing status to COMPLETED PROCESSING.
//        if (rpsNew.Processor_RT_Status__c == 'Complete'
//                && (rpsNew.Total_Processing_Completed_Meter_Reading__c >= rpsNew.Total_Meter_Readings__c) ||
//                (RPS_NO_VGT_COLLECTION_TYPES.contains(rpsNew.Collection_Type__c))) {
//
//            rpsNew.Processing_Process_Status__c = 'COMPLETED PROCESSING';
//            rpsNew.Processing_Process_Changed_Date__c = System.now();
//            rpsNew.Processing_Process_Changed_By__c = UserInfo.getUserId();
//        }
        // 2/7 PATCH Fix for the above
        Boolean hasNoVgts = RPS_NO_VGT_COLLECTION_TYPES.contains(rpsNew.Collection_Type__c);
        Boolean meterReadingsCompleted =  rpsNew.Total_Processing_Completed_Meter_Reading__c >= rpsNew.Total_Meter_Readings__c;
        Boolean rtStatusCompleted = rpsNew.Processor_RT_Status__c == 'Complete';

        if(rtStatusCompleted) {
            if(hasNoVgts || meterReadingsCompleted) {
                rpsNew.Processing_Process_Status__c = 'COMPLETED PROCESSING';
                rpsNew.Processing_Process_Changed_Date__c = System.now();
                rpsNew.Processing_Process_Changed_By__c = UserInfo.getUserId();
            }
        }
        if(rpsNew.Processor_RT_Status__c != rpsOld.Processor_RT_Status__c) {
            rpsNew.Processor_RT_Status_Last_Modified_By__c = UserInfo.getUserId();
            rpsNew.Processor_RT_Status_Last_Modified_Date__c = System.now();
        }
    }

    /**
     * Tags various status fields (client must update / but be implicit update event)
     *
     * @param rpsOld The old Route_Processing_Sheet__c sObject.
     * @param rpsNew The new Route_Processing_Sheet__c sObject.
     *
     */
    static void setCollectionStatus(Route_Processing_Sheet__c rpsOld, Route_Processing_Sheet__c rpsNew, Set<Id> rpsIdsNotCompletedMeters) {
        /*
         * Collection Status
         * @todo this is a headache!
         */
        System.debug('---> setCollectionStatus all meters complete?='+!rpsIdsNotCompletedMeters.contains(rpsNew.Id));
        System.debug('---> setCollectionStatus all rts complete?='+(isAllRtsComplete(rpsNew)));

        // 10/1/2022 added Regular VGT Only RPS Autostatus set https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
        if(rpsNew.Collection_Type__c == 'Additional Fill – VGT Only' || rpsNew.Collection_Type__c == 'Regular - VGT Only') {
                System.debug('---> Additional Fill VGT Use Case AND Regular VGT Only Use Case');
                rpsNew.Redemption_Terminal_Status__c = RPS_COLLECTOR_RT_STATUS_COMPLETE;
                if(!rpsIdsNotCompletedMeters.contains(rpsNew.Id)) {
                    rpsNew.Status__c = RPS_COLLECTION_STATUS_COMPLETE;
                    rpsNew.Collection_Status_Last_Modified_By__c = UserInfo.getUserId();
                    rpsNew.Collection_Status_Last_Modified_Date__c = System.now();
                }
        } else {
            if (((!rpsIdsNotCompletedMeters.contains(rpsNew.Id))
                    || (rpsNew.Collection_Type__c == 'Additional Fill – RT Only'))
                    && rpsNew.Status__c != RPS_COLLECTION_STATUS_SKIPPED
                    && (isAllRtsComplete(rpsNew))) {
                //  RPS Does NOT have incomplete Meter Readings and the Status is not Skipped and All Rts Or Complete
                //  or it's an Additional Fill
                System.debug('---> Set collecton status complete');
                rpsNew.Status__c = RPS_COLLECTION_STATUS_COMPLETE;
                rpsNew.Collection_Status_Last_Modified_By__c = UserInfo.getUserId();
                rpsNew.Collection_Status_Last_Modified_Date__c = System.now();
            } else {
                System.debug('---> no funky additional fill or not completed meter stuff');
                if (rpsNEw.Status__c != RPS_COLLECTION_STATUS_NOT_STARTED) {
                    System.debug('---> branch a');
                    if (rpsNew.Status__c != RPS_COLLECTION_STATUS_SKIPPED
                            && rpsNew.Status__c != RPS_COLLECTION_STATUS_COMPLETE) {
                        System.debug('---> branch a1');
                        //  When status is NOT Skipped and not Complete it must be in progress.
                        if(!rpsIdsNotCompletedMeters.contains(rpsNew.Id)
                                && isAllRtsComplete(rpsNew)) {
                            System.debug('---> branch a1a');
                            rpsNew.Status__c = RPS_COLLECTION_STATUS_COMPLETE;
                        } else {
                            System.debug('---> branch a1b');
                            rpsNew.Status__c = RPS_COLLECTION_STATUS_IN_PROGRESS;
                        }
                    } else if (rpsNew.Status__c == RPS_COLLECTION_STATUS_SKIPPED
                            && rpsOld.Status__c != RPS_COLLECTION_STATUS_SKIPPED) {
                        System.debug('---> branch b');
                        //  When status is CHANGED to Skipped set child meter readings to cannot collect.
                        System.debug('---> Meter readings cannot collect logic');
                        setRpsMeterReadingsToCannotCollect(rpsNew.Id);
                        // https://accel-entertainment.monday.com/boards/1300348967/pulses/2762188800
                        rpsNew.Processor_RT_Status__c = 'Complete';
                    }
                    rpsNew.Collection_Status_Last_Modified_By__c = UserInfo.getUserId();
                    rpsNew.Collection_Status_Last_Modified_Date__c = System.now();
                }
            }
            /*
             *  Collector RT Status
             */
            if(isAllRtsComplete(rpsNew)) {
                System.debug('---> all rts complete check passed');
                //if()
                if (rpsNew.Redemption_Terminal_Status__c != RPS_COLLECTOR_RT_STATUS_COMPLETE) {
                    System.debug('---> branch rt a');
                    rpsNew.Redemption_Terminal_Status__c = RPS_COLLECTOR_RT_STATUS_COMPLETE;
                }
//                } else {
//                    System.debug('---> branch rt b');
//                    rpsNew.Redemption_Terminal_Status__c = RPS_COLLECTOR_RT_STATUS_NOT_STARTED;
//                }
            } else {
                System.debug('---> all rts complete check failed');
                rpsNew.Redemption_Terminal_Status__c = RPS_COLLECTOR_RT_STATUS_IN_PROGRESS;
            }

            if (rpsNew.Redemption_Terminal_Status__c != rpsOld.Redemption_Terminal_Status__c) {
                rpsNew.Collector_RT_Status_Last_Modified_By__c = UserInfo.getUserId();
                rpsNew.Collector_RT_Status_Last_Modified_Date__c = System.now();
            }

        }


        System.debug('---> setCollectionStatus Status__c='+rpsNew.Status__c);
    }
    /**
     * Sets all child Meter_Reading__c sObject records to 'Cannot_Collect__c' = true. Does an explicit update!
     * Uses future call to step out of current context to guard against recursion of meter reading mods running this
     * trigger again.
     *
     * @param rpsId  The route processing sheet id.
     */
    @Future
    public static void setRpsMeterReadingsToCannotCollect(Id rpsId) {
        Map<Id,Meter_Reading__c> rpsMeterReadings = clMeterSvc.retrieveRpsMeterReadings(rpsId);

        if(!rpsMeterReadings.isEmpty()) {
            for(Meter_Reading__c mr : rpsMeterReadings.values()) {
                mr.Cannot_Collect__c = true;
            }
            update rpsMeterReadings.values();  //  @todo partial commit / error handling ?
        }
    }

    @TestVisible
    private static void truncateNotes(Route_Processing_Sheet__c rpsOld, Route_Processing_Sheet__c rpsNew) {
        if(rpsNew.Notes__c != rpsOld.Notes__c) {
            String truncatedValue = null;
            if(rpsNew.Notes__c != null) {
                truncatedValue = rpsNew.Notes__c.length() > 254 ?  rpsNew.Notes__c.substring(0,254) : rpsNew.Notes__c;
            }
            rpsNew.Notes_Text_Area__c = truncatedValue;
        }
    }

    /**
     * This is meant to take the place of the Formula Field RPS.Collector_RT_Fields_Completed__c since Formula
     * fields cannot be re-evaluated in record triggered automation on update until commit and reselect. ie.
     * There is an OOE (Order Of Execution) issue.
     *
     * @param rps The Route_Processing_Sheet__c sObject.
     * @return    True if complete, otherwise false.
     *
     * @todo Are these business assumptions correct?
     * @todo Move to service layer.
     */
    @TestVisible
    private static Boolean isAllRtsComplete(Route_Processing_Sheet__c rps) {
        Boolean isComplete = false;
        if(rps.Status__c != RPS_COLLECTION_STATUS_SKIPPED) {
            if (rps.Redemption_Type_From_Asset__c != null) {
                switch on rps.Redemption_Type_From_Asset__c {
                    when 'NRT','Safe Cash' {
                        isComplete = isNotBlank(rps.Cassette_1_Note_Count__c)
                                && isNotBlank(rps.Cassette_2_Note_Count__c)
                                && isNotBlank(rps.Cassette_3_Note_Count__c)
                                && isNotBlank(rps.Cassette_4_Note_Count__c)
                                && isNotBlank(rps.BV_Value__c);
                    }
                    when 'M3T' {
                        isComplete = isNotBlank(rps.Cassette_1_Value__c)
                                && isNotBlank(rps.Cassette_2_Value__c)
                                && isNotBlank(rps.Cassette_3_Value__c)
                                && isNotBlank(rps.Cassette_4_Value__c)
                                && isNotBlank(rps.Cassette_5_Value__c);
                    }
                    when else {
                        System.debug(LoggingLevel.WARN, 'INVALID RPS REDEMPTION TYPE OF ' + rps.Redemption_Type_From_Asset__c);
                    }
                }
            }
        } else {
            isComplete = true;
        }
        return isComplete;
    }
    /**
     * We have an OOE Order of Execution issue in evaluating formulas dependent on DLRS updates on the RPS
     * Record while within a BEFORE UPDATE trigger so we must require all RPS In text as
     * RPS.Total_Completed_Meter_Readings__c may not be updated yet when we need it to be.
     *
     * This will look for all route processing sheets that have at lease one Meter_Reading__c record
     * that is not Completed.
     *
     * @param mRps  A Map of all the Rps Id => Route_Processing_Sheet__c sObjects in Context.
     * @return      A Map of Rps Id => Route_Processing_Sheet__c for which at least 1 Meter Reading is Not Completed.
     *
     * @todo  Move to service layer.
     */
    private static Set<Id> findRpsWithNotCompletedMeterReadings(Map<Id,Route_Processing_Sheet__c> mRps) {

        Map<Id,Route_Processing_Sheet__c> mRpsNotCompleted = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id
                FROM   Route_Processing_Sheet__c
                WHERE  Id IN :mRps.keySet()
                AND    Id IN (
                        SELECT Route_Processing_Sheet__c
                        FROM   Meter_Reading__c
                        Where  Reading_Status__c            != :MR_READING_STATUS_COMPLETED
                        AND    Reading_Status__c            != :MR_READING_STATUS_CANNOT_COLLECT
                        AND    Route_Processing_Sheet__c    IN :mRps.keySet()
                )

        ]);
        return mRpsNotCompleted.keySet();
    }
    /**
     * Simply a convience method on != null for now.
     *
     * @param d A Decimal
     * @return  True if not null
     */
    @TestVisible
    private static Boolean isNotBlank(Decimal d) {
        return d != null;
    }

}