public without sharing class clRouteProcessingSheetsController {

    @TestVisible public static final String MAP_KEY_RPS_DATA = 'RPS_WRAPS';
    @TestVisible private static final String MAP_KEY_ROUTE_DATA = 'ROUTE_DATA';
    @TestVisible private static final String MAP_KEY_MDT_RECORD = 'MDT_RECORD';
    @TestVisible private static final String MAP_KEY_SURVEY_MDTS = 'SURVEY_MDTS';
    @TestVisible private static String MAP_KEY_COLLECTION_DATE_FORMATTED = 'COLLECTION_DATE_FORMATTED';
    @TestVisible private static final String MDT_RPS_SURVEY_CUSTOM_DEV_NAME = 'RPSQuestions';
    @TestVisible public static final String MAP_KEY_ROUTE_SCHEDULE_DATA = 'ROUTE_SCHEDULE_DATA';
    @TestVisible private static final String MAP_KEY_ROUTE_SCHEDULE_ID = 'ROUTE_SCHEDULE_ID';
    @TestVisible private static final String MDT_RPS_DEV_NAME = 'Route_Processing_Sheet';
    @TestVisible private static final String MDT_RPS_FILL_DEV_NAME = 'Route_Processing_Fill';
    @TestVisible private static final String MDT_SCHEDULE_DEV_NAME = 'Schedule';
    @TestVisible private static final Integer LOC_NOTES_MAX_LEN = 20;
    @TestVisible private final static String MDT_DEV_NAME_RPS_EMAIL = 'clQueueableRpsEmailer';
    public static String jobName = 'clCustomMetadataUpdate'; // Important as your custom mdt is keyed by this.
    public static Batch_Job_Setting__mdt jobMdt;
    public static Accel_Application_Error__c log;
    //@todo replace with custom mdt.
    public static String RPS_PARTIALLY_COMPLETED_ROW_STYLE = 'background-color:rgb(254, 147, 57);';


    /**
     * @param allRpss   A List of Route_Processing_Sheet__c sObjects to update.
     * @return          A Response dto object with success info.
     */
    @AuraEnabled
    public static ResponseDto doUpdateStopNumbers(List<Route_Processing_Sheet__c> allRpss) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'allRps sent to server='+allRpss;
        Long mStart = SYSTEM.now().millisecond();
        Map<Id,Decimal> mRsaId_StopNumber = new Map<Id,Decimal>();
        if(allRpss != null && !allRpss.isEmpty()) {
            for(Route_Processing_Sheet__c rps : allRpss) {
                if(rps.Route_Schedule_Account__c != null) {
                    mRsaId_StopNumber.put(rps.Route_Schedule_Account__c,rps.Stop_Number__c);
                }
            }
            if(!mRsaId_StopNumber.isEmpty()) {
                List<Route_Schedule_Account__c> rsas = [
                        SELECT Id, Stop_Number__c
                        FROM Route_Schedule_Account__c
                        WHERE Id IN :mRsaId_StopNumber.keySet()
                ];
                for(Route_Schedule_Account__c rsa : rsas) {
                    if(mRsaId_StopNumber.containsKey(rsa.Id)) {
                        Decimal dStopNumber = (Decimal)mRsaId_StopNumber.get(rsa.Id);
                        rsa.Stop_Number__c = dStopNumber;
                    }
                }
                update rsas;
                Long mEnd = System.now().millisecond();
                dto.technicalMsg += '--> updated '+rsas.size() + ' rsa records for stop number. total upd time='+ (mEnd - mStart);
                dto.isSuccess = true;
            }
        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto doRouteProcessingSheetStatusUpdate(Id rpsId, String status) {
        ResponseDto dto = new ResponseDto();

        Route_Processing_Sheet__c rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet((rpsId));
        if(rps != null) {
            rps.Status__c = status;
//            if(status == 'In Progress') {
//                rps.Collection_Started_By__c = UserInfo.getUserId();
//                rps.Collection_Start_Date__c = System.now();
//                dto.technicalMsg += ' collection start date set to = ' + rps.Collection_Start_Date__c;
//            } else if (status == 'Complete') {
//                rps.Collection_Ended_By__c = UserInfo.getUserId();
//                rps.Collection_End_Date__c = System.now();
//                dto.technicalMsg += ' collection end date set to = ' + rps.Collection_End_Date__c;
//            }
            update rps;
            dto.isSuccess = true;
            dto.technicalMsg += ' rpsId= ' + rpsId;
            dto.message = ' Rps status updated to ' + rps.Status__c;
        }
        return dto;
    }

   /**
    * Update Route_Schedule__c.Route_Start_Timestamp__c with the current system timestamp.
    *
    * @param routeScheduleId   The Route_Schedule__c.Id
    * @return                  A dto containing success / failure info. ie dto.message and to.technicalMsg
    */
    @AuraEnabled
    public static ResponseDto doRouteScheduleStart(Id routeScheduleId) {
        return doRouteScheduleStart( routeScheduleId, System.now());
    }

    /**
     * Fire the queueable to send the Email and formulates toast message view custom labels.
     *
     * @param routeSchedule  A Route_Schedule__c sObject
     * @return a ResponseDto containing
     */
    @AuraEnabled
    public static ResponseDto doSendRouteEndEmail( Route_Schedule__c routeSchedule) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'Passed rs = '+ routeSchedule;

        Id jobId = clRouteScheduleSvc.sendRouteScheduleCompletedEmail(routeSchedule.Id);

        dto.technicalMsg += ' fired job id ='+dto.technicalMsg;
        dto.isSuccess = jobId != null;
        dto.severity = 'success';

        if(dto.isSuccess) {
            String label = Label.CL_Collector_Home_Action_Send_Email_Success_Toast;
            String msg = label;
            try {
                List<String> tokenReplacements = new List<String>();
                List<String> sendToEmails = findSendRouteEmailSendTos(routeSchedule);
                String sendToEmail = sendToEmails.toString();
                tokenReplacements.add(sendToEmail);
                tokenReplacements.add(routeSchedule.Name);
                msg = string.format(label, tokenReplacements);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }
            dto.message = msg;

        } else {
            dto.message = 'Error sending email.. no job submitted';
            dto.severity = 'error';
        }
        return dto;
    }


    private static List<String> findSendRouteEmailSendTos(Route_Schedule__c routeSchedule) {
        routeSchedule = [SELECT Id,Name,Route__c,Processing_Location__c FROM Route_Schedule__c WHERE Id = :routeSchedule.Id];
        System.debug('--> unit test rs='+routeSchedule);
        String region = routeSchedule.Processing_Location__c;
        List<String> mailTos = new List<String>();
        if(region != null) {
            String regionDevName = region.replaceAll(' ','_');
            Set<String> groupEmails = getPublicGroupEmails(regionDevName);
            if (groupEmails != null) {
                mailTos.addAll(groupEmails);
            }
//        Cash_Logistics_Automation_Setting__mdt automationMdt = CustomMetadataSvc.retrieveAutomationMetadata(MDT_DEV_NAME_RPS_EMAIL);
//        if(automationMdt.Public_Group_Dev_Names__c != null) {
//            mailTos = automationMdt.Public_Group_Dev_Names__c.split(',');
//        }
        }
        return mailTos;
    }

    /**
     * Update Route_Schedule__c.Route_Start_Timestamp__c with the passed timestamp.
     *
     * @param routeScheduleId   The Route_Schedule__c.Id
     * @param startDateTime     A Timestamp indicating the start datetime.
     * @return                  A dto containing success / failure info. ie dto.message and to.technicalMsg
     */
    public static ResponseDto doRouteScheduleStart(Id routeScheduleId, Datetime startDateTime) {
        ResponseDto dto = new ResponseDto();

        Route_Schedule__c routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);

        routeSchedule.Route_Start_Timestamp__c = startDateTime;
        Database.SaveResult saveResult = clRouteScheduleSvc.updateRouteSchedule(routeSchedule);
        dto.isSuccess = saveResult.isSuccess();
        if (!dto.isSuccess) {
            dto.message = 'Problem updating Route Schedule Start Timestamp!';
            dto.technicalMsg = getDmlErrorMessage(saveResult);
        } else {
            dto.technicalMsg += ' routeScheduleId= ' + routeScheduleId;
            dto.message = ' Route start time successfully set to ' + routeSchedule.Route_Start_Timestamp__c.format();

//  @todo possible future implementation to change from scheduled meter creation to user triggered meter creation
//            Set<Id> rpsIdsForMeterReadings = new Set<Id>(); // call query to get all rps for the schedule
//            clBatchMeterReadingsCreation b = new clBatchMeterReadingsCreation(rpsIdsForMeterReadings);
//            Database.executeBatch(b, 2);

        }
        return dto;
    }
    /**
     * Update Route_Schedule__c.Route_End_Timestamp__c with the current system timestamp.
     *
     * @param routeScheduleId   The Route_Schedule__c.Id
     * @return                  A dto containing success / failure info. ie dto.message and to.technicalMsg
     */
    @AuraEnabled
    public static ResponseDto doRouteScheduleEnd(Id routeScheduleId) {
        return doRouteScheduleEnd( routeScheduleId, System.now());
    }

    /**
     * Update Route_Schedule__c.Route_End_Timestamp__c with the passed timestamp.
     *
     * @param routeScheduleId   The Route_Schedule__c.Id
     * @param startDateTime     A Timestamp indicating the start datetime.
     * @return                  A dto containing success / failure info. ie dto.message and to.technicalMsg
     */
    public static ResponseDto doRouteScheduleEnd(Id routeScheduleId, Datetime startDateTime) {
        ResponseDto dto = new ResponseDto();

        Route_Schedule__c routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);

        routeSchedule.Route_End_Timestamp__c = startDateTime;
        Database.SaveResult saveResult = clRouteScheduleSvc.updateRouteSchedule(routeSchedule);
        dto.isSuccess = saveResult.isSuccess();
        if (!dto.isSuccess) {
            dto.message = 'Problem updating Route Schedule End Timestamp!';
            dto.technicalMsg = getDmlErrorMessage(saveResult);
        } else {
            dto.technicalMsg += ' routeScheduleId= ' + routeScheduleId;
            dto.message = ' Route end time successfully set to ' + routeSchedule.Route_End_Timestamp__c.format();
        }
        return dto;
    }
    @AuraEnabled
    public static ResponseDto deleteRpsAndMeters( Id routeScheduleId) {
        ResponseDto dto = new ResponseDto();

        Map<STring,Object> m = clRouteProcessingSheetSvc.deleteScheduleRpsAndMeterRecords(routeScheduleId);

        List<Route_Processing_Sheet__c> deletedRpsRecs = (List<Route_Processing_Sheet__c>)m.get('DELETED_RPS_RECS');
        List<Meter_Reading__c> deletedMeterReadings = (List<Meter_Reading__c>)m.get('DELETED_METER_RECS');

        if(deletedRpsRecs.isEmpty()) {
            dto.message = 'Unable to delete RPS Records as none were found to delete';
            dto.severity = 'error';
        } else {
            Route_Schedule__c rs = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
            rs.Route_Start_Timestamp__c = null;
            rs.Route_End_Timestamp__c = null;
            rs.Vehicle_License__c = null;
            rs.Starting_Vehicle_Milage__c = null;
            rs.Ending_Vehicle_Milage__c = null;
            rs.Vehicle__c = null;
            rs.Collection_Status__c = 'Collection Incomplete';
            rs.Processing_Status__c = 'Processing Incomplete';
            rs.Schedule_Status__c = 'Fill Incomplete';
            update rs;

            dto.isSuccess = true;
            dto.severity = 'success';
            dto.message = 'Successfully Deleted '+deletedRpsRecs.size() + ' RPS Records ';
            if(!deletedMeterReadings.isEmpty()) {
                dto.message += ' and '+deletedMeterReadings.size() + ' Meter Reading records.';
            }
            dto.message += '  and cleared associated Route Schedule Info';
        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto deleteMeters( Id routeScheduleId) {
        ResponseDto dto = new ResponseDto();

        List<Meter_Reading__c> deletedMeterReadings = clRouteProcessingSheetSvc.deleteScheduleMeterRecords(routeScheduleId);

        if(deletedMeterReadings.isEmpty()) {
            dto.message = 'Unable to delete Meter Records as none were found to delete';
            dto.severity = 'error';
        } else {
            dto.isSuccess = true;
            dto.severity = 'success';
            dto.message = 'Successfully Deleted '+deletedMeterReadings.size() + ' Meter Readings ';
        }
        return dto;
    }

    /**
     * @param routeScheduleId   Route_Schedule__c.Id to create RPS records for.
     * @param region            The region aka processing location.
     *
     * @return                  A dto containing success / failure info. 
     */
    @AuraEnabled
    public static ResponseDto createRpsAndMeters( Id routeScheduleId, String region) {
        ResponseDto dto = new ResponseDto();
        clBatchRouteProcessingSheetCreation b = new clBatchRouteProcessingSheetCreation(routeScheduleId, region);
        Id jobId = Database.executeBatch(b,50);
        dto.isSuccess = true;
        dto.severity = 'success';
        dto.message = 'Job '+jobId+' has been initiated to create rps and meter records. You will be prompted with status updates.';
        return dto;
    }

    @AuraEnabled
    public static ResponseDto createRouteSchedules( Integer nextCycleNumber, Date routeCollectionDate, Date routeFillDate) {
        ResponseDto dto = new ResponseDto();
        clBatchRouteScheduleCreation b = new clBatchRouteScheduleCreation(nextCycleNumber,false,50,routeCollectionDate, routeFillDate);
        Id jobId = Database.executeBatch(b,50);
        dto.isSuccess = true;
        dto.severity = 'success';
        dto.message = 'Job '+jobId+' has been initiated to create route schedule records for cycle #'+nextCycleNumber+
                ' and collection date ' + routeCollectionDate + ' and fill date: ' + routeFillDate+  '. You will be prompted with status updates.';
        return dto;
    }
    @AuraEnabled
    public static ResponseDto updateRpsStopNumbers(List<Route_Processing_Sheet__c> routeProcessingSheets) {
        ResponseDto dto = new ResponseDto();
        update routeProcessingSheets;
        dto.isSuccess = true;
        dto.message = 'Successfully updated stop numbers';
        return dto;
    }

    @AuraEnabled
    public static ResponseDto updateNextCycleNumber(Integer nextCycleNumber) {

        ResponseDto dto = new ResponseDto();

        String mdtName = 'Cash_Logistics_Setting__mdt';
        String recordDevName = 'Scheduler';
        String label = 'Scheduler';
        Map<String,Object> mFields = new Map<String,Object>();
        mFields.put('Next_Cycle__c',nextCycleNumber);

        Id jobId = updateCustomMetadata(mdtName,recordDevName,label,mFields);
        dto.isSuccess = true;
        dto.message = 'Running job ' + jobId + ' to update custom metadata. You will be notified when complete.';
        dto.severity = 'info';
        return dto;

    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveMdt(String mdtDevName) {
        ResponseDto dto = new ResponseDto();
        Cash_Logistics_Setting__mdt mdt;

        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        dto.technicalMsg += 'devname passeted='+mdtDevName;
        if(oMdt != null) {
            mdt = (Cash_Logistics_Setting__mdt)oMdt;
        }
        if(mdt != null) {
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_MDT_RECORD,mdt);
        return dto;
    }
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveMdtNoCache(String mdtDevName,Double cacheBust) {
        ResponseDto dto = new ResponseDto();
        Cash_Logistics_Setting__mdt mdt;

        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        dto.technicalMsg += 'devname passeted='+mdtDevName;
        if(oMdt != null) {
            mdt = (Cash_Logistics_Setting__mdt)oMdt;
        }
        if(mdt != null) {
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_MDT_RECORD,mdt);
        return dto;
    }

    /**
 * @param userId            The user id to bump up against the collector 1 or collector 2 fields on the associatd schedule.
 * @param collectionDate    The collection date to...xxx.
 *
 * @return                  A ResponseDto containing a List<RpsWrapper> in the values map.
 */
    @AuraEnabled
    public static ResponseDto retrieveRouteProcessingSheetsImperative(Id userId, Date collectionDate) {
        ResponseDto dto = new ResponseDto();

        if(collectionDate != null) {
            collectionDate = Date.newInstance(collectionDate.year(),collectionDate.month(),collectionDate.day());
        }
        List<Route_Processing_Sheet__c> rpsRecs = clRouteProcessingSheetSvc.retrieveRouteProcessingSheets(userId, collectionDate);
        List<RpsWrapper> rpsWrappers = buildResponse(rpsRecs,'collector','');

        Id routeScheduleId;
        Route_Schedule__c routeSchedule;
        Route__c route;
        if(!rpsWrappers.isEmpty()) {
            Id routeId = rpsWrappers[0].routeId;
            routeScheduleId = rpsWrappers[0].routeScheduleId;
            routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
            route = clRouteSvc.retrieveRoute(routeId);
            calcDistanceToStartingPoint(rpsWrappers,route);
        }

        dto.values.put(MAP_KEY_RPS_DATA, rpsWrappers);
        dto.isSuccess = !rpsWrappers.isEmpty();

        if (!dto.isSuccess) {
            String userFullName = [SELECT Id, Name FROM User WHERE Id = :userId]?.Name;
            String sDate = collectionDate.format();
            dto.message = 'No route processing sheets found for '+ userFullName + ' on date ' + sDate;
        } else {
            dto.values.put(MAP_KEY_ROUTE_DATA,route);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_ID,routeScheduleId);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_DATA,routeSchedule);
        }

        dto.technicalMsg += '---> params: userId='+userId + '.. collectionDate='+collectionDate;
        dto.technicalMsg += '.. number of rps records found:'+rpsRecs.size();
        return dto;
    }
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheets(Id userId, Date collectionDate, Double cacheBust) {
        return retrieveRouteProcessingSheetsNoCache(userId,collectionDate,cacheBust);
    }
    /**
     * @param userId            The user id to bump up against the collector 1 or collector 2 fields on the associatd schedule.
     * @param collectionDate    The collection date to...xxx.
     * @param cacheBust         A randome integer
     *
     * @return                  A ResponseDto containing a List<RpsWrapper> in the values map.
     */
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheetsNoCache(Id userId, Date collectionDate, Double cacheBust) {
        ResponseDto dto = new ResponseDto();


        if(collectionDate != null) {
            collectionDate = Date.newInstance(collectionDate.year(),collectionDate.month(),collectionDate.day());
        }

        List<Route_Processing_Sheet__c> rpsRecs = clRouteProcessingSheetSvc.retrieveRouteProcessingSheets(userId, collectionDate);
        List<RpsWrapper> rpsWrappers = buildResponse(rpsRecs,'collector','');

        Id routeScheduleId;
        Route_Schedule__c routeSchedule;
        Route__c route;

        // Note: this assumes only 1 route schedule per day for the assigned user. we must throw a warning if there was more then one.
        Set<Id> routeScheduleIds = new Set<Id>();
        for(RpsWrapper rpsWrapper : rpsWrappers) {
            routeScheduleIds.add(rpsWrapper.routeScheduleId);
        }

        if(!rpsWrappers.isEmpty()) {
            Id routeId = rpsWrappers[0].routeId;
            routeScheduleId = rpsWrappers[0].routeScheduleId;
            routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
            route = clRouteSvc.retrieveRoute(routeId);
            calcDistanceToStartingPoint(rpsWrappers,route);
        }

        dto.values.put(MAP_KEY_RPS_DATA, rpsWrappers);
        dto.isSuccess = !rpsWrappers.isEmpty();

        if (!dto.isSuccess) {
            String userFullName = [SELECT Id, Name FROM User WHERE Id = :userId]?.Name;
            String sDate = collectionDate.format();
            dto.message = 'No route processing sheets found for '+ userFullName + ' on date ' + sDate;
        } else {
            dto.values.put(MAP_KEY_ROUTE_DATA,route);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_ID,routeScheduleId);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_DATA,routeSchedule);
            if(routeScheduleIds.size() > 1) {
                dto.severity = 'warning';
                dto.message = routeScheduleIds.size() + ' route schedules were assigned to this user for today, only 1 is supported';
                dto.technicalMsg += '---> routeScheduleIDs='+routeScheduleIds;
            }
        }

        dto.technicalMsg += '---> params: userId='+userId + '.. collectionDate='+collectionDate+' ..cacheBust='+cacheBust;
        dto.technicalMsg += '.. number of rps records found:'+rpsRecs.size();
        return dto;
    }
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveAllRouteProcessingSheets() {
        ResponseDto dto = new ResponseDto();


        List<Route_Processing_Sheet__c> rpsRecs = clRouteProcessingSheetSvc.retrieveAllRouteProcessingSheets();
        List<RpsWrapper> rpsWrappers = buildResponse(rpsRecs,'collector','');

        Id routeScheduleId;
        Route_Schedule__c routeSchedule;
        Route__c route;

        // Note: this assumes only 1 route schedule per day for the assigned user. we must throw a warning if there was more then one.
        Set<Id> routeScheduleIds = new Set<Id>();
        for(RpsWrapper rpsWrapper : rpsWrappers) {
            routeScheduleIds.add(rpsWrapper.routeScheduleId);
        }

        if(!rpsWrappers.isEmpty()) {
            Id routeId = rpsWrappers[0].routeId;
            routeScheduleId = rpsWrappers[0].routeScheduleId;
            routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
            route = clRouteSvc.retrieveRoute(routeId);
            calcDistanceToStartingPoint(rpsWrappers,route);
        }

        dto.values.put(MAP_KEY_RPS_DATA, rpsWrappers);
        dto.isSuccess = !rpsWrappers.isEmpty();

        if (!dto.isSuccess) {
        } else {
            dto.values.put(MAP_KEY_ROUTE_DATA,route);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_ID,routeScheduleId);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_DATA,routeSchedule);
            if(routeScheduleIds.size() > 1) {
                dto.severity = 'warning';
                dto.message = routeScheduleIds.size() + ' route schedules were assigned to this user for today, only 1 is supported';
                dto.technicalMsg += '---> routeScheduleIDs='+routeScheduleIds;
            }
        }
        dto.technicalMsg += '.. number of rps records found:'+rpsRecs.size();
        return dto;
    }
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheetsForProcessorNoCache(String type, Id userId, Id routeScheduleId, Date collectionDate, Double cacheBust) {
        return retrieveRouteProcessingSheetsForProcessor(type,userId,routeScheduleId,collectionDate);
    }

    /**
     *
     * @param userId            The user id to bump up against the collector 1 or collector 2 fields on the associatd schedule.
     * @param routeScheduleId   Route_Schedule__c.Id.
     * @param collectionDate    The collection date to...xxx.
     *
     * @return                  A ResponseDto containing a List<RpsWrapper> in the values map.
     */
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheetsForProcessor(String type, Id userId, Id routeScheduleId, Date dDate) {
        ResponseDto dto = new ResponseDto();

        if(dDate != null) {
            dDate = Date.newInstance(dDate.year(),dDate.month(),dDate.day());
        }
        List<Route_Processing_Sheet__c> rpsRecs = clRouteProcessingSheetSvc.retrieveRouteProcessingSheetsForProcessor(type, userId, routeScheduleId, dDate);
        List<RpsWrapper> rpsWrappers = buildResponse(rpsRecs,'processing',type);

        Route_Schedule__c routeSchedule;
        Route__c route;
        if(!rpsWrappers.isEmpty()) {
            Id routeId = rpsWrappers[0].routeId;
            routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
            route = clRouteSvc.retrieveRoute(routeId);
            calcDistanceToStartingPoint(rpsWrappers,route);
        }

        dto.values.put(MAP_KEY_RPS_DATA, rpsWrappers);
        dto.values.put(MAP_KEY_COLLECTION_DATE_FORMATTED,dDate.format());
        dto.isSuccess = !rpsWrappers.isEmpty();

        if (!dto.isSuccess) {
            String userFullName = [SELECT Id, Name FROM User WHERE Id = :userId]?.Name;
            String rsName;
            if(routeScheduleId != null) {
                rsName = [SELECT Name FROM Route_Schedule__c WHERE Id = :routeScheduleId]?.Name;
            }
            String sDate = dDate.format();
            dto.message = 'No route processing sheets found for '+ userFullName + ' on date ' + sDate;
            if(rsName != null) {
                dto.message += ' for route schedule '+rsName;
            }
        } else {
            dto.values.put(MAP_KEY_ROUTE_DATA,route);
            dto.values.put(MAP_KEY_ROUTE_SCHEDULE_DATA,routeSchedule);
        }

        dto.technicalMsg += '---> params: userId='+userId + '.. date='+dDate;
        dto.technicalMsg += '.. number of rps records found:'+rpsRecs.size();
        return dto;
    }

    public static void retrieveRtInfo(List<RpsWrapper> rpsWrappers) {

        Map<Id,Id> mRpsId_AccountId = new Map<Id,Id>();

        for(RpsWrapper rpsWrap: rpsWrappers ) {
            mRpsId_AccountId.put(rpsWrap.rpsId,rpsWrap.locId);
        }
        Set<Id> accountIds = new Set<Id>(mRpsId_AccountId.values());
        Map<Id,List<Asset>> mAccountId_Assets = AssetSvc.retrieveAccountsRedemptionAssets(accountIds);

        if(!mAccountId_Assets.isEmpty()) {
            Map<Id, List<Asset>> mRpsId_Assets = new Map<Id, List<Asset>>();
            for (RpsWrapper rpsWrap : rpsWrappers) {
                if (mAccountId_Assets.containsKey(rpsWrap.locId)) {
                    List<Asset> rtAssets = mAccountId_Assets.get(rpsWrap.locId);
                    if(!rtAssets.isEmpty()) {

                        Map<String,List<Asset>> mX_Assets = new Map<String,List<Asset>>();
                        for(Asset asset : rtAssets) {
                            if(!mX_Assets.containsKey(asset.GP_Manufacturer__c)) {
                                mX_Assets.put(asset.GP_Manufacturer__c, new List<Asset>{asset});
                            } else {
                                List<Asset> assets = mX_Assets.get(asset.GP_Manufacturer__c);
                                assets.add(asset);
                            }
                        }
                        if(!mX_Assets.isEmpty()) {
                          //  for()
                        }

                    }
                }
            }
        }


    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteScheduleData( Id routeScheduleId, Double cacheBust) {
        ResponseDto dto = new ResponseDto();

        Route_Schedule__c routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
        dto.isSuccess = routeSchedule != null;
        dto.values.put(MAP_KEY_ROUTE_SCHEDULE_DATA,routeSchedule);
        dto.technicalMsg += ' routeScheduleId = '+routeScheduleId;
        
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveRouteScheduleDataImperative( Id routeScheduleId) {
        ResponseDto dto = new ResponseDto();

        Route_Schedule__c routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(routeScheduleId);
        dto.isSuccess = routeSchedule != null;
        dto.values.put(MAP_KEY_ROUTE_SCHEDULE_DATA,routeSchedule);
        dto.technicalMsg += ' routeScheduleId = '+routeScheduleId;

        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveSurveyMetadatas(String surveyDevName) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' Survey dev name param='+surveyDevName;
        List<Cash_Logistics_Survey_Setting__mdt> mdts = CustomMetadataSvc.retrieveSurveyMetadatas(surveyDevName);
        dto.isSuccess = !mdts.isEmpty();
        dto.values.put(MAP_KEY_SURVEY_MDTS,mdts);
        if(!dto.isSuccess) {
            dto.message = 'No survey metadata found';
        }
        return dto;
    }

    /**
     * @param rpsRecs
     * @return
     */
    @TestVisible
    private static List<RpsWrapper> buildResponse(List<Route_Processing_Sheet__c> rpsRecs,String rpsType, String type) {
        List<RpsWrapper> rpsWrappers = new List<RpsWrapper>();
        String mdtDevName;
        if(rpsType == 'Collector') {
            mdtDevName = MDT_RPS_DEV_NAME;
        } else {
            mdtDevName = MDT_RPS_FILL_DEV_NAME;
        }

        Map<String,String> mStatus_Style = buildRpsStyleMap( retrieveMdtLocal(mdtDevName) );

        for(Route_Processing_Sheet__c rps : rpsRecs) {
            rpsWrappers.add(new RpsWrapper(rpsType,rps,mStatus_Style,type));
        }
        return rpsWrappers;
    }

    public class RtInfo {
        @AuraEnabled public String gpManf;
        @AuraEnabled public Integer totalRts = 0;
        public RtInfo() {

        }
    }

    /**
     * A Wrapper on top of Route_Processing_Sheet__c for ease of display
     */
    public class RpsWrapper {
        @AuraEnabled public Route_Processing_Sheet__c rps;
        @AuraEnabled public String locName;
        @AuraEnabled public String locId;
        @AuraEnabled public String locFullName;
        @AuraEnabled public String locSecurityKey;
        @AuraEnabled public String locAccessTime;
        @AuraEnabled public String locRmName;
        @AuraEnabled public String locRmPhone;
        @AuraEnabled public String locRmMobilePhone;
        @AuraEnabled public String locCollectionContactName;
        @AuraEnabled public String locContactPhone;
        @AuraEnabled public String locCollectionNotes;
        @AuraEnabled public String locCollectionNotesTruncated;
        @AuraEnabled public String rpsName;
        @AuraEnabled public String routeName;
        @AuraEnabled public Id rpsId;
        @AuraEnabled public Integer rpsStopNumber = 0;
        @AuraEnabled public String rpsStatus;
        @AuraEnabled public String rpsProcessingStatus;
        @AuraEnabled public String rpsProcessingProcessStatus;
        @AuraEnabled public String rpsCollectionType;
        @AuraEnabled public String rpsReplenishmentType;
        @AuraEnabled public String rpsRtModel;
        @AuraEnabled public Decimal distanceMiles;
        @AuraEnabled public Double totalMeterReadings;
        @AuraEnabled public Double totalJcmBvType;
        @AuraEnabled public Double totalMeiBvType;
        @AuraEnabled public Double totalSmallMeiBvType;
        @AuraEnabled public Boolean hasBvTypes;
        @AuraEnabled public String redemptionType;
        @AuraEnabled public String rpsRowStyle;
        @AuraEnabled public String formattedAddressText;
        @AuraEnabled public String formattedAddressUrl;


        @AuraEnabled public RtInfo rtInfo;




        public Id routeId;
        public Id routeScheduleId;

        // Account Shipping Address
        public Decimal latitude;
        public Decimal longitude;
        public String address1;



        public RpsWrapper() {

        }


        public RpsWrapper(String rpsType,Route_Processing_Sheet__c rps, Map<String, String> mStatus_Style, String type) {
            this.rps = rps;
            String stopText = '';
            if(rps.Stop_Number__c != null && rps.Stop_Number__c != 0) {
                stopText = rps.Stop_Number__c != null ? '(' + rps.Stop_Number__c + ') ' : '';
            }

            this.locName = stopText + rps.Account__r.Name;

            /*
             * 3/8/2023 Added Account__r.IGB_License__c (append to locName)
             * @see https://accel-entertainment.monday.com/boards/1300348967/pulses/4106517832
             */
            if(rps.Account__r?.IGB_License__c != null) {
                if(this.locName != null) {
                    this.locName += ' - #'+rps.Account__r.IGB_License__c;
                }
            }

            this.locId = rps.Account__c;
            this.locFullName = rps.Account__r.Name;
            this.locSecurityKey = rps.Account__r.Location_Key_ID__c;
            this.locAccessTime = rps.Account__r.Access_Time__c;
            this.locRmName = rps.Account__r?.Relationship_Manager__r?.Name;
            this.locRmPhone = rps.Account__r?.Relationship_Manager__r?.Phone;
            this.locRmMobilePhone = rps.Account__r?.Relationship_Manager__r?.MobilePhone;
            this.locCollectionContactName = rps.Account__r.Collection_Contact_Name__c;
            this.locContactPhone = rps.Account__r.Collection_Contact_Number__c;
            if(this.locContactPhone != null) {
                this.locContactPhone = this.locContactPhone.replaceAll('N/A','');
            }
            this.rpsId = rps.Id;
            this.rpsName = rps.Name;
            this.routeName = rps.Route_Name__c;
            this.routeId = rps.Route_Schedule__r.Route__c;
            this.rpsStatus = rps.Status__c;
            this.rpsProcessingStatus = rps.Processing_Status__c;
            this.rpsProcessingProcessStatus = rps.Processing_Process_Status__c;
            this.rpsRtModel = rps.Redemption_Asset__r?.Model__c;
            this.rpsCollectionType = rps.Collection_Type__c;
            this.rpsReplenishmentType = rps.Replenishment_Type__c;
            this.locCollectionNotes = rps.Account__r.Collection_Notes__c;
            this.locCollectionNotesTruncated = truncateLocNotes(this.locCollectionNotes);

            //this.redemptionType = rps.Redemption_Type__c;
            this.redemptionType = rps.Redemption_Type_From_Asset__c;

            if(rpsType == 'Collector') {
                this.rpsRowStyle = mStatus_Style.get(this.rpsStatus);
                if(rpsStatus == 'In Progress') {
                    if(rps.Redemption_Terminal_Status__c == 'Complete') {
                        rpsStatus+= ' - RTs Completed';
                    } else if (rps.End_VGT_Collection_Date__c != null) {
                        rpsStatus+= ' - VGTs Completed';
                    }
                }
            } else  {
                if(type == 'fill') {
                    //processing - fill
                    this.rpsRowStyle = mStatus_Style.get(this.rpsProcessingStatus);
                } else {
                    // processing - process
                    this.rpsRowStyle = mStatus_Style.get(this.rpsProcessingProcessStatus);
                    Boolean partiallyComplete = false;
                    if(rpsProcessingProcessStatus == 'Processing Incomplete') {
                        if(rps.Processor_RT_Status__c == 'Complete') {
                            rpsProcessingProcessStatus += ' - RTs Completed';
                            partiallyComplete = true;
                        } else {
                            if(rps.Total_Processing_Completed_Meter_Reading__c >= rps.Total_Meter_Readings__c) {
                                rpsProcessingProcessStatus += ' - VGTs Completed';
                                partiallyComplete = true;
                            }
                        }
                    }
                    //@todo replace with custom mdt.
                    if(partiallyComplete) {
                        this.rpsRowStyle = RPS_PARTIALLY_COMPLETED_ROW_STYLE;
                    }

                }
            }

            this.latitude = rps.Account__r.ShippingLatitude;
            this.longitude = rps.Account__r.ShippingLongitude;
            this.formattedAddressText = formatAddress(rps);
            this.formattedAddressUrl = formattedAddressUrl(rps);
            this.routeScheduleId = rps.Route_Schedule__c;
            this.rpsStopNumber = rps.Stop_Number__c != null ? Integer.valueOf(rps.Stop_Number__c) : null;
            this.totalMeterReadings = rps.Total_Meter_Readings__c != null ? Integer.valueOf(rps.Total_Meter_Readings__c) : 0;
            this.totalJcmBvType = rps.Total_JCM_BV_Type__c != null ? Integer.valueOf(rps.Total_JCM_BV_Type__c) : 0;
            this.totalMeiBvType = rps.Total_MEI_BV_Type__c != null ? Integer.valueOf(rps.Total_MEI_BV_Type__c) : 0;
            this.totalSmallMeiBvType = rps.Total_MEI_Small_BV_Type__c != null ? Integer.valueOf(rps.Total_MEI_Small_BV_Type__c) : 0;
            this.hasBvTypes = this.totalJcmBvType != 0 || this.totalMeiBvType != 0 || this.totalSmallMeiBvType != 0;
        }
    }

    /**
     * @return
     */
    @TestVisible
    private static Cash_Logistics_Setting__mdt retrieveMdtLocal(String devName) {
        Cash_Logistics_Setting__mdt mdtRps =
                (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
        return mdtRps;
    }

    /**
     * Will return the first 3 words if location collection notes length is greater then 0,
     * otherwise will return the original value.
     *
     * @param locCollectionNotes The value of Account__r.Collection_Notes__c.
     * @return A truncated value if necessary.
     */
    @TestVisible
    private static String truncateLocNotes(String locCollectionNotes) {
        String locCollectionNotesTruncated;
        if(locCollectionNotes != null) {
            if(locCollectionNotes.length() > LOC_NOTES_MAX_LEN) {
                List<String> lTmp = locCollectionNotes.split(' ');
                if(lTmp != null && !lTmp.isEmpty()) {
                    locCollectionNotesTruncated = lTmp[0];
                    if(lTmp.size() > 1) {
                        locCollectionNotesTruncated += ' ' + lTmp[1];
                    }
                    if(lTmp.size() > 2) {
                        locCollectionNotesTruncated += ' ' + lTmp[2];
                    }
                }
            } else {
                locCollectionNotesTruncated = locCollectionNotes;
            }
        }
        return locCollectionNotesTruncated;
    }
    /**
     * @param mdt The Cash_Logistics_Setting__mdt custom mdt recorfd.
     * @return a Map of Status => Style
     */
    @TestVisible
    private static Map<String, String> buildRpsStyleMap(Cash_Logistics_Setting__mdt mdt) {

        Map<String, String> mStatus_Style = new Map<String, String>();
        mStatus_Style.put('Not Started', mdt.Status_Not_Started_Style__c);
        mStatus_Style.put('In Progress', mdt.Status_In_Progress_Style__c);
        mStatus_Style.put('Complete', mdt.Status_Complete_Style__c);

        mStatus_Style.put('Not Yet Filled', mdt.Status_Fill_Incomplete_Style__c);
        mStatus_Style.put('COMPLETED FILL', mdt.Status_Completed_Fill_Style__c);

        mStatus_Style.put('Processing Incomplete', mdt.Status_Processing_Incomplete_Style__c);
        mStatus_Style.put('COMPLETED PROCESSING', mdt.Status_Completed_Processing_Style__c);


        return mStatus_Style;
    }

    @TestVisible
    private static String getDmlErrorMessage(Database.SaveResult saveResult) {
        String errorMsg = '';
        for (Database.Error error : saveResult.getErrors()) {
            errorMsg += error.getStatusCode() + ' - ' + error.getMessage() + ' - ' + error.getFields();
            System.debug(LoggingLevel.ERROR, ' DML Error! ' +  errorMsg);
        }
        return errorMsg;
    }

    /**
     * @param rps
     * @return
     */
    @TestVisible
    private Static String formatAddress(Route_Processing_Sheet__c rps) {
        String addy = '';
        if (rps.Account__r != null) {
            addy += rps.Account__r.ShippingStreet;
            addy += ' - ' + rps.Account__r.ShippingCity;
            addy += ' ' + rps.Account__r.ShippingState;
        }
        return addy;
    }

    @TestVisible
    private Static String formattedAddressUrl(Route_Processing_Sheet__c rps) {
        String url = 'https://www.google.com/maps?q=';
        if(rps.Account__r != null) {
            String street = rps.Account__r.ShippingStreet;
            String city = rps.Account__r.ShippingCity;
            String state = rps.Account__r.ShippingState;
            String zip = rps.Account__r.ShippingPostalCode;

            if(street != null) {
                url+= street.replaceAll(' ','%20');
            }
            if(city != null) {
                url+= '%0A' + city.replaceAll(' ','%20');
            }
            if(state != null) {
                url+= '%0A' + state.replaceAll(' ','%20');
            }
            if(zip != null) {
                url += '%0A' + zip.replaceAll(' ', '%20');
            }
        }
        return url;
    }

    /**
     * Currently uses the starting point (ie geo location on the associated route) and calcs the distance from that
     * starting point to the lat/lng of the account of each RPS.
     *
     * @param rpsWrappers
     * @param route
     * @todo bulkify
     */
    @TestVisible
    private static void calcDistanceToStartingPoint(List<RpsWrapper> rpsWrappers, Route__c route) {
        try {
            GeoCoordinates originGeo = new GeoCoordinates();
            originGeo.latitude = route.Geolocation__Latitude__s;
            originGeo.longitude = route.Geolocation__Longitude__s;

            if (originGeo.latitude != null && originGeo.longitude != null) {
                for (RpsWrapper wrap : rpsWrappers) {
                    GeoCoordinates destinationGeo = new GeoCoordinates();
                    destinationGeo.latitude = wrap.latitude;
                    destinationGeo.longitude = wrap.longitude;
                    wrap.distanceMiles = GeolocationSvc.getDistance(originGeo, destinationGeo);
                    if (wrap.distanceMiles != null) {
                        wrap.distanceMiles = wrap.distanceMiles.setScale(1, System.RoundingMode.HALF_UP);
                    }
                }
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, e);
        }
    }

    public class CustomMetadataCallBack implements Metadata.DeployCallback {

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {

            jobMdt = BatchjobSvc.queryForMetadata(jobName);    //  Query Metadata for params.
            initLog();
            log.Execution_Details__c += '\n * ===== enqueuedeployment call completed metadata should be updated!  ===== \n';
            log.Execution_Details__c += '\n * in clRouteProcessingSheetsController.CustomMetadataCallback.handleResult callback for enqueuemetadatadeployment call.';
            log.Execution_Details__c += '\n * result = '+result;
            log.Execution_Details__c += '\n * context = '+context;
            String devName = 'Scheduler';
            Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
            log.Execution_Details__c += '\n * CURRENT CYCLE NUMBER (updated) = '+mdt.Next_Cycle__c;


            System.debug('---> result='+result);
            System.debug('----> context = '+context);
            String uiMessage = '';
            if (result.status == Metadata.DeployStatus.Succeeded) {
                uiMessage = 'Custom Metadata Update Successful!';
            } else {
                uiMessage = 'Custom Metadata Update Failed';
            }
            log.Initiating_Job_Id__c = context.getCallbackJobId();
            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Execution_Details__c += '* In finish of metdata deploy' + '\n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = 1;
            log.Total_Records_Updated__c =  result.numberComponentsDeployed;
            log.Total_Updates_Failed__c =  result.numberComponentErrors;
            log.Total_Records_Processed__c = 1;
            log.Execution_Details__c += '* Total Updated = '+log.Total_Records_Updated__c + '\n';
            log.Execution_Details__c += '* CURRENT CYCLE NUMBER (updated) = '+mdt.Next_Cycle__c;
            log.Overall_Job_Status__c  = 'Success';
            insert log;


            List <Route_Schedule_Change_PE__e> changePEs = new List<Route_Schedule_Change_PE__e>();
            Route_Schedule_Change_PE__e changePe    = new Route_Schedule_Change_PE__e();
            changePe.Operation_Type__c = PlatformEventSvc.MDT_ACTION_UPDATE;
            changePe.Ui_Message__c = uiMessage;
            changePe.Status__c = 'Complete';
            changePEs.add(changePe);
            PlatformEventSvc.publishPlatformEvents(changePes);
        }
    }

    /**
     * Enqueue job to use the Metadata.Deploy container to update the custom metadata record.
     * (A fancy version of a DML Update)  This will call back when done to handleResult.
     *
     * @param metdataName            The api Custom mdt name ie. (Cash_Logistics_Setting__mdt)
     * @param recordDevName          The record dev name ie. (Scheduler)
     * @param label                  The record label ie. (Scheduler)
     * @param metadataFieldValueMap  A map of Field_Api_Name => new field value ie. (Next_Cycle__c => 5)
     * @return                       The Job Id fired.
     *
     * @todo remove routeScheduleId to make generic.
     */
    public static Id updateCustomMetadata( String metdataName, String recordDevName, String label,
                                             Map<String, Object> metadataFieldValueMap){

        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;

        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key);
            cMetadata.values.add(cMetadataValue);
        }

        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        CustomMetadataCallBack callback = new CustomMetadataCallBack();
        Id jobId;


        if(!Test.isRunningTest()) {
            jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }

        System.debug('---> fire job:'+jobId);
        return jobId;
    }

    private static Set<String> getPublicGroupEmails(String regionDevName) {
        Cash_Logistics_Region__mdt regionMdt = (Cash_Logistics_Region__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Region__mdt.getSObjectType(),regionDevName);
        List<String> publicMdtDevNames = regionMdt.RPS_Email_Public_Group_Dev_Names__c.split(',');
        System.debug('----> group dev names='+publicMdtDevNames);
        List<User> groupUsers = retrievePublicGroupsUsersRecords(publicMdtDevNames);
        System.debug('---> groupUsers='+groupUsers);

        Set<String> groupEmails = new Set<String>();
        for(User user : groupUsers) {
            groupEmails.add(user.email);
        }
        return groupEmails;
    }

    public static List<User> retrievePublicGroupsUsersRecords(List<String> groupNames) {
        List<User> users = [
                SELECT Id,Email,userName
                FROM    User
                WHERE Id IN (
                        SELECT UserOrGroupId
                        FROM GroupMember
                        WHERE Group.DeveloperName IN :groupNames
                )];
        return users;
    }

    private static void initLog() {

        log = BatchjobSvc.buildLog(jobName);
        log.JobType__c = 'ApexToken';
        log.Overall_Job_Status__c = 'Processing';
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Execution_Details__c = ' ';

        //insert log;
       // log = log;
    }
}