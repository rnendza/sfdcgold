/**
 * Contains business logic for Meter_Reading__c
 */
public with sharing class MeterReadingTriggerHandler {

    @TestVisible private static String COMPLETED_STATUS = 'Completed';  //  @todo get dynamically!
    @TestVisible private static String IN_PROGRESS_STATUS = 'In Progress';
    @TestVisible private static String CANNOT_COLLECT_STATUS = 'Cannot Collect';
    @TestVisible private static final String MDT_METER_READINGS_DEV_NAME = 'Meter_Readings';

    @TestVisible
    private static Cash_Logistics_Setting__mdt mdtMeterReadings =
            (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,MDT_METER_READINGS_DEV_NAME);

    /**
     * Main driver method takes in data passed from the Trigger on Meter_Reading__c.
     *
     * @param newMeterReadings      A List of Meter_Reading__c sObjects  (useful for before insert)
     * @param mOldMeterReadings     A Map of Trigger.Old Meter_Reading sObjects.
     * @param mNewMeterReadings     A Map of Trigger.New Meter_Reading sObjects.
     * @param triggerOpp            The Trigger Event.
     */
    public static void handleTriggerEvent(  List<Meter_Reading__c> newMeterReadings,
                                            Map<Id, Meter_Reading__c>  mOldMeterReadings,
                                            Map<Id, Meter_Reading__c>  mNewMeterReadings,
                                            System.TriggerOperation triggerOpp) {
        switch on triggerOpp {
            when BEFORE_DELETE {
                checkDeleteSecurity(mOldMeterReadings);
            }
            when BEFORE_UPDATE {
                modifyVoucherChanged(mOldMeterReadings,mNewMeterReadings);
                modifyReadingStatus(mOldMeterReadings,mNewMeterReadings);
                modifyProcessingStatus(mOldMeterReadings,mNewMeterReadings);
            }
            when AFTER_INSERT {
                createPrevMeterReadings(mNewMeterReadings);
            }
        }
    }

   /**
    * Checks CL Automation Custom Settings to determine if we wish to prevent delete for Meter_Reading__c.
    * If so, get the custom label to display a message to the user upon error (replace {0} token with dyna value)
    * and call addError on the sObject.
    *
    * @param  mOldMrs Map of Id => Meter_Reading__c
    */
    public static void checkDeleteSecurity(Map<Id,Meter_Reading__c> mOldMrs){

        Boolean preventDelete = clAutomationSvc.preventRecordDelete(clAutomationSvc.MR_TRIGGER_PREVENT_DELETE);

        if(preventDelete) {
            for(Meter_Reading__c mr : mOldMrs.values()) {
                String msg = String.format(Label.CL_Meter_Readings_Prevent_Delete, new List<String>{mr.Name});
                mr.addError(msg);
            }
        }
    }

    /**
     * Fire async job to update newly created Meter_Reading__c sObjects Previous_Meter_Reading__c values.
     *
     * @param mMeters  A Map of Id => Meter_Reading__c sObjects (Trigger.newMap)
     * @todo how do we prevent firing too many queueables here on mass inserts.
     */
    @TestVisible
    private static void createPrevMeterReadings(Map<Id,Meter_Reading__c> mMeters) {
        clQueueablePreviousMeters q = new clQueueablePreviousMeters(mMeters);
        Id jobId = System.enqueueJob(q);
        System.debug(LoggingLevel.INFO,'firing queueable to update prev meters jobId:'+jobId + ' and '+mMeters.size()+' meter records.');
    }

    /**
     * If the Current_Lifetime_Cash_In__c previous had a value and it was changed to something else,
     * Set the voucher change value to true.
     *
     * @param mOld
     * @param mNew
     */
    @TestVisible
    private static void modifyVoucherChanged(Map<Id, Meter_Reading__c> mOld, Map<Id, Meter_Reading__c> mNew) {

        for (Meter_Reading__c newMr : mNew.values()) {
            Meter_Reading__c oldMr = mOld.get(newMr.Id) ;
            if(newMr.Current_Lifetime_Cash_In__c != oldMr.Current_Lifetime_Cash_In__c && oldMr.Current_Lifetime_Cash_In__c != null) {
                newMr.Voucher_Changed__c = true;
            }
        }
    }

    /**
     * Checks if either the current lifetime cash in changed OR the Snapshot Count Changed
     * AND the status is still the same (allowing manual overrides of status).
     *
     * If there is a value in current lifetime cash in and there is an image attached, consider
     * this meter record completed. (Implicit Update)
     *
     * @param mOld The old records (Id => Meter_Reading__c).
     * @param mNew The new records (Id => Meter_Reading__c).
     *
     * @todo doc addition of custom mdt.Require_Meter_Image__c
     */
    @TestVisible
    private static void modifyReadingStatus(Map<Id, Meter_Reading__c> mOld, Map<Id, Meter_Reading__c> mNew) {

        for (Meter_Reading__c newMr : mNew.values()) {
            Meter_Reading__c oldMr = mOld.get(newMr.Id) ;

            if (anyMeterValueChanged(oldMr,newMr)) {

                if(!newMr.Cannot_Collect__c) {
                    if (!mdtMeterReadings.Require_Meter_Image__c) {
                        //  Custom mdt tells us not to check Shapshot__c value.
                        if (newMr.Current_Lifetime_Cash_In__c != null && newMr.Current_Lifetime_Cash_In__c != 0) {
                            newMr.Reading_Status__c = COMPLETED_STATUS;
                        } else {
                            newMr.Reading_Status__c = IN_PROGRESS_STATUS;
                        }
                    } else {
                        //  Make sure all required fields are filled in.
                        if (newMr.Current_Lifetime_Cash_In__c != null && newMr.Current_Lifetime_Cash_In__c != 0 && newMr.Snapshot__c != null) {
                            newMr.Reading_Status__c = COMPLETED_STATUS;
                        } else {
                            newMr.Reading_Status__c = IN_PROGRESS_STATUS;
                        }
                    }
                } else {
                    //  Cannot collect checkbox trumps all.
                    newMr.Reading_Status__c = CANNOT_COLLECT_STATUS;
                }
                newMr.Reading_Status_Last_Modified_By__c = UserInfo.getUserId();
                newMr.Reading_Status_Last_Modified_Date__c = System.now();
            }
        }
    }

    private static boolean anyMeterValueChanged(Meter_Reading__c oldMr, Meter_Reading__c newMr) {
        return (newMr.Current_Lifetime_Cash_In__c != oldMr.Current_Lifetime_Cash_In__c)
                || (newMr.Snapshot__c != oldMr.Snapshot__c || newMr.Cannot_Collect__c != oldMr.Cannot_Collect__c);
    }

    /**
     * Modifies Meter_Reading__c.Processing_Status. Called in Context of Before Update on a Meter_Reading__c sObject.
     *
     * Pseudo.
     * 1. If the actual drop value has changed
     *    a. If it's not null.. Rule says that it is considered completed
     *    b. If it is null. it's in progress
     * 2. The nasty cannot collect....
     *    a  If it's marked cannot collect then it's complete.
     *
     * @param mOld  The old Meter readings in context.
     * @param mNew  The new Meter readings in context.
     *
     * @todo full unit test case... Enjoy!
     */
    @TestVisible
    private static void modifyProcessingStatus(Map<Id, Meter_Reading__c> mOld, Map<Id, Meter_Reading__c> mNew) {

        for (Meter_Reading__c newMr : mNew.values()) {
            Meter_Reading__c oldMr = mOld.get(newMr.Id) ;
            if (( newMr.Actual_Drop__c != oldMr.Actual_Drop__c)) {
                /*
                 *  9/14/2022
                 *  I guess the business rule is that a zero is acceptable for Meter_Reading__c.Actual_Drop__c..
                 *  Commented out the zero check below.
                 *  https://accel-entertainment.monday.com/boards/942883797/pulses/3235121723/posts/1706844414
                 *    ie. removed. if(newMr.Actual_Drop__c != null && newMr.Actual_Drop__c != 0) {
                 */
                if(newMr.Actual_Drop__c != null) {
                    newMr.Processing_Status__c = COMPLETED_STATUS;
                } else {
                    newMr.Processing_Status__c = 'In Progress';
                }
                newMr.Processing_Status_Last_Modified_By__c = UserInfo.getUserId();
                newMr.Processing_Status_Last_Modified_Date__c = System.now();
            }
           /**
            *  Override all if the collector hit cannot collect!!
            *  https://accel-entertainment.monday.com/boards/1300348967/pulses/2762188800/posts/1544848314
            *  @todo reval this with conditionals above!
            */
            if(newMr.Cannot_Collect__c) {
                newMr.Processing_Status__c = COMPLETED_STATUS;
                newMr.Processing_Status_Last_Modified_By__c = UserInfo.getUserId();
                newMr.Processing_Status_Last_Modified_Date__c = System.now();
            }
        }
    }



}