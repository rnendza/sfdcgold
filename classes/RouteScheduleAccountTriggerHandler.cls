public class RouteScheduleAccountTriggerHandler {

    @TestVisible private final static String MDT_DEV_NAME_ADDITIONAL_FILL = 'createRsasAndMetersForAdditionalFill';

    /**
     * A general handler called by the Route_Schedule_Account__c Trigger.
     *
     * @param newRsas       A List of Trigger.new Route_Schedule_Account__c sObjects.
     * @param mOldRsas      A Map of Trigger.oldMap Id => Route_Schedule_Account__c.
     * @param mNewRsas      A Map of Trigger.newMap Id => Route_Schedule_Account__c.
     * @param triggerOpp    The Trigger operation. ie. AFTER / BEFORE / UPDATE / DELETE / INSERT etc.
     *
     * @implNotes  Some of these params may be null depending on Trigger Context.
     */
    public static void handleTriggerEvent(  List<Route_Schedule_Account__c> newRsas,
                                            Map<Id, Route_Schedule_Account__c>  mOldRsas,
                                            Map<Id, Route_Schedule_Account__c>  mNewRsas,
                                            System.TriggerOperation triggerOpp) {
        switch on triggerOpp {
            when BEFORE_INSERT {
                setRedemptionAssets(newRsas);
            }
            when AFTER_INSERT {
                createRsasAndMetersForAdditionalFill(mNewRsas);
            }
            when AFTER_UPDATE {
                cascadeStopNumberChangeToRps(mOldRsas,mNewRsas);
            }
            when BEFORE_UPDATE {
                updateRedemptionAssets(mOldRsas,mNewRsas);
            }
            when BEFORE_DELETE {
                /**
                 *  Modified from AFTER DELETE to BEFORE Deleted to support PROD Defect
                 *  @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4000610475
                 */
                cascadeDeleteToRps(mOldRsas);
            }
        }
    }
    /**
     * Sets Route_Schedule_Account__c.Redemption_Type_From_Asset__c (by reference) based on searching the assets
     * for the account.
     *
     * @param newRsas  A List of Route_Schedule_Account__c sObjects.
     */
    public static void setRedemptionAssets(List<Route_Schedule_Account__c> newRsas) {
        clRouteSvc.tagRedemptionAssets(newRsas);
    }

    /**
     * If The manual override has not been checked on the RSA and the new Redemption_Terminal__c value != old Redemption_Terminal__c
     * value (ie RT1 / RT2 Picklist) then call automatic logic to figure out RT Asset.
     *
     * @param mOldRsas      A Map of Trigger.oldMap Id => Route_Schedule_Account__c.
     * @param mNewRsas      A Map of Trigger.newMap Id => Route_Schedule_Account__c.
     */
    public static void updateRedemptionAssets(Map<Id, Route_Schedule_Account__c>  mOldRsas, Map<Id, Route_Schedule_Account__c>  mNewRsas) {

        List<Route_Schedule_Account__c> routeScheduleAccountsToUpd = new List<Route_Schedule_Account__c>();

        for(Route_Schedule_Account__c newRsa: mNewRsas.values()) {
            Route_Schedule_Account__c oldRsa = mOldRsas.get(newRsa.Id);
            if(newRsa.Redemption_Asset_Manual_Override__c != TRUE && newRsa.Redemption_Terminal__c != oldRsa.Redemption_Terminal__c) {
                routeScheduleAccountsToUpd.add(newRsa);
            }
        }
        if(!routeScheduleAccountsToUpd.isEmpty()) {
            System.debug('----> rsa trigger BU tagRedemptionAssets ');
            clRouteSvc.tagRedemptionAssets(routeScheduleAccountsToUpd);
        }
    }

    /**
     * For that passed Route_Schedule_Account__c sObjects, this will roll through them and determine if the Collection_Type__c
     * is = 'Additional Fill'. If so, it will create RPS and Meter Records for that account(s). It will also fire a platform
     * event indicated it's result if any clients wish to be notified.
     *
     * @param mNewRsas  A map of Id => Route_Schedule_Account__c sObjects.
     *
     * @implNote        Kill switch is stored in custom metadata. Not if this ends up being used on mass imports, we
     *                  should probably create a queueable and fire this async but the original design is just a few at a time
     *                  and UI driven.
     *
     * @see clFillSvc
     * @see https://accelentertainment--fulldev.lightning.force.com/lightning/setup/CustomMetadata/page?address=%2Fm0U%3Fsetupid%3DCustomMetadata
     */
    public static void createRsasAndMetersForAdditionalFill(Map<Id,Route_Schedule_Account__c> mNewRsas) {

        Set<Id> routeScheduleAccountIdsToProcess = new Set<Id>();

        for(Route_Schedule_Account__c rsa : mNewRsas.values()) {
            if(clFillSvc.ADDITIONAL_FILL_COLLECTION_TYPES.contains(rsa.Collection_Type__c)) {
                routeScheduleAccountIdsToProcess.add(rsa.Id);
            }
        }
        if(!routeScheduleAccountIdsToProcess.isEmpty()) {
            Cash_Logistics_Automation_Setting__mdt automationMdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_ADDITIONAL_FILL);
            if(automationMdt.Active__c) {
                List<Route_Processing_Sheet__c> routeProcessingSheets = clFillSvc.createAdditionalFillRps(routeScheduleAccountIdsToProcess);
                if (!routeProcessingSheets.isEmpty()) {
                    fireChangeAdditionalFillPlatformEvent(routeProcessingSheets);
                }
            }
        }
    }

    /**
     * When Parent Route_Schedule_Account__c sObjects are deleted, it finds the created Route_Processing_Sheet__c
     * and deletes that as well. We also fire a Platform Event in case a client needs to be notified and create a
     * task to keep audit history.
     *
     * @param mDeletedRsas  A Map of Trigger.oldMap Id => Route_Schedule_Account__c.
     * @return              A List of Route_Processing_Sheet__c sObject that were deleted.
     */
    public static List<Route_Processing_Sheet__c> cascadeDeleteToRps(Map<Id,Route_Schedule_Account__c> mDeletedRsas) {

        List<Route_Processing_Sheet__c> rpssToDelete = findChildRps(mDeletedRsas);
        List<Route_Processing_Sheet__c> rpssDeleted = rpssToDelete.deepClone(true);
        delete rpssToDelete;

        fireChangePlatformEvent(rpssDeleted);
        createTasks(rpssDeleted);
        return rpssDeleted;
    }

    /**
     * When Parent Route_Schedule_Account__c sObjects are updated, it finds the created Route_Processing_Sheet__c sObjects.
     * that for those Route_Schedule_Account__c sObject that had Stop_Number__c modified and sets the appropriate
     * Route_Processing_Sheet__c.Stop_Number__c value.
     *
     * @param mOldRsas
     * @param mNewRsas
     *
     * @return
     */
    public static List<Route_Processing_Sheet__c> cascadeStopNumberChangeToRps( Map<Id,Route_Schedule_Account__c> mOldRsas,
                                                                                Map<Id,Route_Schedule_Account__c> mNewRsas) {

        Map<Id,Route_Schedule_Account__c> mRsasUpdated = findModifiedRsaStopNumbers(mOldRsas,mNewRsas);
        List<Route_Processing_Sheet__c> rpssToUpd = new List<Route_Processing_Sheet__c>();

        if(!mRsasUpdated.isEmpty()) {
            List<Route_Processing_Sheet__c> routeProcessingSheets = findChildRps(mNewRsas);

            for(Route_Processing_Sheet__c rps : routeProcessingSheets) {
                Route_Schedule_Account__c rsa = mNewRsas.get(rps.Route_Schedule_Account__c);
                if(rsa != null) {
                    rps.Stop_Number__c = rsa.Stop_Number__c;
                    rpssToUpd.add(rps);
                }
            }
            update rpssToUpd;
        }
        return rpssToUpd;
    }

    /**
     * Filter through updated Route_Schedule_Account__c sObjects and find only those where the Stop_Number__c is changed.
     *
     * @param mOldRsas
     * @param mNewRsas
     *
     * @return          A List of Route_Schedule_Account__c sObject that had Stop_Number__c updated.
     */
    @TestVisible
    private static Map<Id,Route_Schedule_Account__c> findModifiedRsaStopNumbers( Map<Id,Route_Schedule_Account__c> mOldRsas,
                                                                                 Map<Id,Route_Schedule_Account__c> mNewRsas) {

        Map<Id,Route_Schedule_Account__c> mRsasUpdated = new Map<Id,Route_Schedule_Account__c>();

        for(Route_Schedule_Account__c rsaNew : mNewRsas.values()) {
            Route_Schedule_Account__c rsaOld = mOldRsas.get(rsaNew.Id);
            if(rsaNew.Stop_Number__c != rsaOld.Stop_Number__c) {
                mRsasUpdated.put(rsaNew.Id,rsaNew);
            }
        }
        return mRsasUpdated;
    }

    /**
     * @param mRsas         A Map of Id => Route_Schedule_Account__c sObjects.
     * @return              A List of Route_Processing_Sheet__c child sObjects.
     */
    @TestVisible
    private static List<Route_Processing_Sheet__c> findChildRps(Map<Id,Route_Schedule_Account__c> mRsas) {

        Set<Id> routeScheduleIds = new Set<Id>();
        Set<Id> allRsaIds = new Set<Id>();

        for(Route_Schedule_Account__c rsa : mRsas.values()) {
            routeScheduleIds.add(rsa.Route_Schedule__c);
            allRsaIds.add(rsa.Id);

        }
        //  Find all affected RPS Sheets keying in by RPS Ids and RSA Ids!

        //  2/20/23 Changed to filter by RSA Ids as opposed to Account Ids.
        //  @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4000610475
        List<Route_Processing_Sheet__c> rpss = [
                SELECT  Id,Account__c,Name,Account__r.Name,Route_Schedule__c, Route_Schedule__r.Name,Route_Schedule_Account__c
                FROM    Route_Processing_Sheet__c
                WHERE   Route_Schedule__c   IN :routeScheduleIds
                AND     Route_Schedule_Account__c  IN :allRsaIds
        ];
        return rpss;
    }

    /**
     * This is a way to keep some audit history for RPS Records that were deleted due to deletes of
     * parent Route_Schedule_Account__c sObjects.
     *
     * @param rpsDeleted The cloned deleted Route_Processing_Sheet__c sObjects.
     */
    public static void createTasks(List<Route_Processing_Sheet__c> rpsDeleted) {
        List<Task> tasks = new List<Task>();

        for(Route_Processing_Sheet__c rps : rpsDeleted) {
            String accountName = rps.Account__r.Name;
            Task t = new Task();
            t.Account__c = rps.Account__c;
            t.WhatId = rps.Route_Schedule__c;
            t.ActivityDate = Date.today();
            t.Subject = 'Removed '+accountName+' and deleted '+ rps.Name;
            t.Description = 'You removed '+accountName+' from Route Schedule '+ rps.Route_Schedule__r.Name;
            t.OwnerId = UserInfo.getUserId();
            t.Status = 'Completed';
            t.Type = 'Note';
            tasks.add(t);
        }
        insert tasks;
    }

    /**
     * Fire off a platform event so the client can be informed of the delete.
     * @param rpsDeleted  The cloned Route_Processing_Sheet__c sObjects.
     */
    public static void fireChangePlatformEvent(List<Route_Processing_Sheet__c> rpsDeleted) {

        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Set<String> sAccountIds = new Set<String>();
        Set<String> sRpsIds = new Set<String>();

        for(Route_Processing_Sheet__c rps : rpsDeleted) {
            sAccountIds.add(rps.Account__c);
            sRpsIds.add(rps.Id);
        }
        Route_Schedule_Change_PE__e changePe    = new Route_Schedule_Change_PE__e();
        changePe.Account_Ids__c                 = String.join(new List<String>(sAccountIds),',');
        changePe.Route_Processing_Sheet_Ids__c  = String.join(new List<String>(sRpsIds),',');
        changePe.Operation_Type__c              = PlatformEventSvc.DML_ACTION_DELETE;
        changePEs.add(changePe);

        PlatformEventSvc.publishPlatformEvents( changePes );
    }

    /**
     * @param rpss
     * @TODO wrap with automation kill switch
     */
    public static void fireChangeAdditionalFillPlatformEvent(List<Route_Processing_Sheet__c> rpss) {

        List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();

        Set<String> sAccountIds = new Set<String>();
        Set<String> sRpsIds = new Set<String>();

        for(Route_Processing_Sheet__c rps : rpss) {
            sAccountIds.add(rps.Account__c);
            sRpsIds.add(rps.Id);
        }
        Route_Schedule_Change_PE__e changePe    = new Route_Schedule_Change_PE__e();
        changePe.Account_Ids__c                 = String.join(new List<String>(sAccountIds),',');
        changePe.Route_Processing_Sheet_Ids__c  = String.join(new List<String>(sRpsIds),',');
        changePe.Operation_Type__c              = PlatformEventSvc.DML_ACTION_INSERT;
        changePe.Publishing_Process_Name__c     = 'RouteScheduleAccountTriggerHandler_AdditionalFill';
        changePEs.add(changePe);

        PlatformEventSvc.publishPlatformEvents( changePes );
    }
}