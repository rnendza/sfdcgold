public without sharing class clMeterReadingsController {

    @TestVisible private static final String MAP_KEY_METER_READINGS = 'METER_READING_WRAPS';
    @TestVisible private static final String MAP_KEY_METER_READING_WRAP = 'METER_READING_WRAP';
    @TestVisible private static final String MAP_KEY_METER_READING_RECORD = 'METER_READING_RECORD';
    @TestVisible private static final String MAP_KEY_ROUTE_PROCESSING_SHEET = 'RPS_RECORD';
    @TestVisible private static final String MAP_KEY_RPS_RECORD = 'RPS_RECORD';
    @TestVisible private static final String MAP_KEY_METER_READINGS_SUMMARY = 'MAP_KEY_METER_READINGS_SUMMARY';

    @TestVisible private static final String MAP_KEY_RPS_DATA = 'ROUTE_PROCESSING_SHEET_DATA';
    @TestVisible private static final String MAP_KEY_MDT_METER_READINGS = 'MDT_METER_READINGS';

    @TestVisible private static final String MDT_METER_READINGS_DEV_NAME = 'Meter_Readings';

    @TestVisible private static final String  MR_IN_PROGRESS_STATUS = 'In Progress';
    @TestVisible private static final String  MR_COMPLETED_STATUS = 'Completed';
    @TestVisible private static final String  MR_CANNOT_COLLECT_STATUS = 'Cannot Collect';

    public static String MSG_FAILED_RPS_VGT_START_DATE = 'Unable to update RPS VGT Start Date!';
    public static String MSG_FAILED_RPS_VGT_END_DATE = 'Unable to update RPS VGT End Date!';


    /**
     * @param rpsId     The Route_Processing_Sheet__c.Id
     * @return          A ResponseDto containing success / failure info.
     */
    @AuraEnabled
    public static ResponseDto updateAllMeterReadingsToCannotCollect(Id rpsId) {
        ResponseDto dto = new ResponseDto();
        List<Meter_Reading__c> meterReadings = [
                SELECT Id,Cannot_Collect__c
                FROM   Meter_Reading__c
                WHERE  Route_Processing_Sheet__c = :rpsId
        ];
        if(!meterReadings.isEmpty()) {
            for(Meter_Reading__c mr : meterReadings) {
                mr.Cannot_Collect__c = true;
            }
            update meterReadings;
            dto.isSuccess = true;
            dto.technicalMsg +=' Updated '+meterReadings.size() + ' meter readings to cannot collect';
        } else {
            dto.technicalMsg = 'No meters found for rpsId:'+rpsId + ' to update to cannot collect';
        }
        return dto;
    }

   /**
    * @param rpsRecord             xx
    * @param collectionStatus  xx
    *
    * @return
    */
    @AuraEnabled
    public static ResponseDto updateRpsCollectionStatus(Route_Processing_Sheet__c rpsRecord,String collectionStatus ) {
        ResponseDto dto = new ResponseDto();
        rpsRecord.Status__c = collectionStatus;
        dto.technicalMsg += 'setting rps '+rpsRecord.Name + ' to status__c of '+rpsRecord.Status__c;
        try {
            update rpsRecord;
            dto.isSuccess = true;
            if(collectionStatus == 'Skipped') {
                dto.message = string.format(Label.CL_Collector_Meters_Action_Skip_Success_Toast,new List<String>{rpsRecord.Account__r.Name});
            } else {
                dto.message = 'Successfully updated ' + rpsRecord.Name + ' collection status to ' + collectionStatus + '.';
            }
            dto.severity = 'success';
        } catch (DmlException dmlEx) {
            dto.message = 'Failed to update collection status for '+rpsRecord.Account__r.Name + ': '+dmlEx.getMessage();
            dto.severity = 'error';
            dto.technicalMsg += dmlEx.getCause() + ' ' + dmlEx.getLineNumber() + ' ' + dmlEx.getStackTraceString();
        }
        dto.values.put(MAP_KEY_RPS_DATA,rpsRecord);
        return dto;
    }

    /**
     * Sets the RPS VGT Start Date and Start Date User Value to the current Datetime and running user.
     *
     * @param rpsRecord  The Route_Processing_Sheet__c sObject.
     * @return           A ResponseDto containing the updated Route_Processing_Sheet__c record in the values map.
     */
    @AuraEnabled
    public static ResponseDto updateRpsVgtCollectionStartDate(Route_Processing_Sheet__c rpsRecord) {

        ResponseDto dto = new ResponseDto();
        String failMessage = MSG_FAILED_RPS_VGT_START_DATE;

        if (rpsRecord != null) {
            dto.technicalMsg = 'rpsRecord.Id:' + rpsRecord.Id;
            rpsRecord = clRouteSvc.tagRpsUtilizationDates(rpsRecord, clRpsDateEnum.START_VGT_COLLECTION_DATE);
            update rpsRecord;
            dto.message = 'VGT Start Date successfully set to ' + rpsRecord.Start_VGT_Collection_Date__c.format();
            dto.severity = 'success';
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_RPS_DATA, rpsRecord);
        } else {
            dto.technicalMsg += 'Invalid rpsRecord param = ' + rpsRecord;
            dto.message = failMessage;
            dto.severity = 'error';
        }
        return dto;
    }

    /**
     * Sets the RPS VGT End Date and End Date User Value to the current Datetime and running user.
     *
     * @param rpsRecord  The Route_Processing_Sheet__c sObject.
     * @return           A ResponseDto containing the updated Route_Processing_Sheet__c record in the values map.
     */
    @AuraEnabled
    public static ResponseDto updateRpsVgtCollectionEndDate(Route_Processing_Sheet__c rpsRecord) {

        ResponseDto dto = new ResponseDto();
        String failMessage = MSG_FAILED_RPS_VGT_END_DATE;

        if (rpsRecord != null) {
            dto.technicalMsg = 'rpsRecord.Id:' + rpsRecord.Id;
            rpsRecord = clRouteSvc.tagRpsUtilizationDates(rpsRecord, clRpsDateEnum.END_VGT_COLLECTION_DATE);
            update rpsRecord;
            dto.message = 'VGT End Date successfully set to ' + rpsRecord.End_VGT_Collection_Date__c.format();
            dto.severity = 'success';
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_RPS_DATA, rpsRecord);
        } else {
            dto.technicalMsg += 'Invalid rpsRecord param = ' + rpsRecord;
            dto.message = failMessage;
            dto.severity = 'error';
        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto deleteDoc(Id docId, Id meterId) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'doc id attempted to delete: '+docId + ' for meterId='+meterId;
        try {
            ContentDocument deletedDoc = ContentManagerSvc.deleteDocument(docId);
            Meter_Reading__c mr = [SELECT Id, Reading_Status__c,Snapshot_Count__c,Snapshot__c FROM Meter_Reading__c WHERE Id = :meterId];
            if(mr.Snapshot_Count__c != null && mr.Snapshot_Count__c > 0) {
                mr.Snapshot_Count__c--;
            }
            mr.Snapshot__c = null;
            //mr.Reading_Status__c = 'In Progress';
            update mr;
            dto.message = 'blah good';
            dto.isSuccess = true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'error on delete ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }

    /**
     * Updates  Meter_Reading__c sObjects and it's parent Route_Processing_Sheet__c sObject (if necessary).
     *
     * @param  meterReadings        A list of Meter_Reading__c sObjects to update.
     * @param  routeProcessingSheet The parent Route_Processing_Sheet__c to update.
     * @return                      A ResponseDto containing the success / failure info of the update
     */
    @AuraEnabled
    public static ResponseDto updateProcessorMeterReadings(List<Meter_Reading__c> meterReadings, Route_Processing_Sheet__c routeProcessingSheet) {

        ResponseDto dto = new ResponseDto();
        dto.technicalMsg +=' meterReadings param: '+meterReadings + ' .. routeProcessingSheet param:'+routeProcessingSheet;

        try {
            String msg = '';
            if(meterReadings != null && !meterReadings.isEmpty()){
                update meterReadings;
                msg+= meterReadings.size() + ' meter readings ';
            }
            if(routeProcessingSheet != null && routeProcessingSheet.Id != null && routeProcessingSheet.BV_Drop_Total__c != null) {
                update routeProcessingSheet;
                msg+= ' and BV Value updated ';
            }
            msg+= 'successfully!';
            dto.values.put(MAP_KEY_ROUTE_PROCESSING_SHEET,routeProcessingSheet);
            dto.message = msg;
            dto.isSuccess = true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'error on update ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }

   /**
    * Upserts a Meter_Reading__c sObject.
    *
    * @param meterReading     An Meter_Reading__c to Insert / Update a Meter_Reading__c sObject.
    * @return                 A ResponseDto containing the AccountMachineWrapper with meter id inserted.
    */
    @AuraEnabled
    public static ResponseDto upsertMeterReading(Meter_Reading__c meterReading) {

        ResponseDto dto = new ResponseDto();

        try {
            if(meterReading.Id == null || meterReading.Current_Lifetime_Cash_In__c == null){
                meterReading.Reading_Status__c = MR_IN_PROGRESS_STATUS;
            }
            upsert meterReading;
            dto.technicalMsg +=' called upsert with: '+meterReading;
            dto.isSuccess = true;
            meterReading = clMeterSvc.retrieveSingleMeterReading(meterReading.Id);
            dto.values.put(MAP_KEY_METER_READING_RECORD,meterReading);
            MeterReadingWrapper wrap = new MeterReadingWrapper(meterReading);
            dto.values.put(MAP_KEY_METER_READING_WRAP,wrap);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'meter attempted to insert: '+meterReading;
            dto.technicalMsg += 'error on upsert ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }
    /**
     * Inserts a Meter_Reading__c sObject or Updates one if a meterId exists on the passed wrapper param.
     *
     * @param meterReading    An List of Meter_Reading__c sObjs to Insert / Update a Meter_Reading__c sObject.
     * @return                A ResponseDto
     */
    @AuraEnabled
    public static ResponseDto upsertMeterReadings(List<Meter_Reading__c> meterReadings) {

        ResponseDto dto = new ResponseDto();

        try {
//            if(meterReading.Id == null || meterReading.Current_Lifetime_Cash_In__c == null){
//                meterReading.Reading_Status__c = MR_IN_PROGRESS_STATUS;
//            }
            upsert meterReadings;
            dto.technicalMsg +=' called upsert with: '+meterReadings;
            dto.isSuccess = true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'meter attempted to insert: '+meterReadings;
            dto.technicalMsg += 'error on upsert ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }
   /**
    * @param rpsId Route_Processing_Sheet__c.Id
    * @return      A ResponseDto with a Route_Processing_Sheet__c sObject.
    */
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRouteProcessingSheet(Id rpsId) {
        ResponseDto dto = new ResponseDto();
        Route_Processing_Sheet__c routeProcessingSheet;

        if(rpsId != null) {
            routeProcessingSheet = clRouteSvc.retrieveRouteProcessingSheet(rpsId);
            dto.isSuccess = routeProcessingSheet != null;
            if(!dto.isSuccess) {
                dto.message = 'No data found for route processing sheet';
            }
        } else {
            dto.message = 'No data found for route processing sheet';
        }
        dto.values.put(MAP_KEY_RPS_DATA, routeProcessingSheet);
        dto.technicalMsg = 'rpsId='+rpsId;

        return dto;
    }


//    @AuraEnabled
//    public static ResponseDto createRpsMeters(Id rpsId) {
//        //@todo for future use.
//        Route_Processing_Sheet__c rpsClicked = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rpsId);
//        ResponseDto dto = new ResponseDto();
//
//        if(rpsClicked.Total_Meter_Readings__c == null || rpsClicked.Total_Meter_Readings__c == 0) {
//            if (!clBatchRouteProcessingSheetCreation.COL_TYPES_NO_METER_CREATION.contains(rpsClicked.Collection_Type__c)) {
//                List<Meter_Reading__c> newMeterReadings = clMeterSvc.initMeterReadings(rpsClicked);
//                dto.technicalMsg+= '---> '+newMeterReadings.size() + ' meters created ';
//                dto.isSuccess = true;
//            }
//        }
//        return dto;
//    }
    /**
     * Retrieves existing meter reading records (MeterReadingWrappers) for the Route_Processing_Sheet__c.Id.
     *
     * @param       rpsId              The Route_Processing_Sheet__c.Id.
     * @param       assetRecordType    The Route_Processing_Sheet__c.Asset__r.RecordType.DeveloperName value.
     * @return      A ResponseDto containing a List of MeterReading Wrapper objects.
     */
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRpsMeterReadings(Id rpsId,String assetRecordType) {
        ResponseDto dto = new ResponseDto();

        List<MeterReadingWrapper> meterReadingWrappers = new List<MeterReadingWrapper>();

        Map<Id,Meter_Reading__c> mMeterReadings = clMeterSvc.retrieveRpsMeterReadings(rpsId,assetRecordType);
        if(mMeterReadings != null && !mMeterReadings.isEmpty()) {
            // OBSOLETE PER https://accel-entertainment.monday.com/boards/1300348967/pulses/2788659595
//            dto.technicalMsg += ' have readings..';
//            Map<Id, ContentVersion> mMeterReadingId_Version = matchContentVersionToMeterReading(mMeterReadings);
//            dto.technicalMsg += 'have versions';
//            Map<Id, ContentDistribution> mMeterReadingId_Distribution = matchContentDistToMeterReading(mMeterReadingId_Version);
//           // meterReadingWrappers = buildMetersResponse(mMeterReadings.values(), mMeterReadingId_Version, mMeterReadingId_Distribution);
            meterReadingWrappers = buildMetersResponseNoContentDoc(mMeterReadings.values());
            meterReadingWrappers.sort();
        } else {
            dto.message = 'No Meter readings found for this route processing sheet.';
            List<Route_Processing_Sheet__c> rpss = [SELECT Id, Account__c, Account__r.Name FROM  Route_Processing_Sheet__c WHERE Id = :rpsId];
            if(!rpss.isEmpty()) {
                Route_Processing_Sheet__c rps = rpss[0];
                Id accountId = rps.Account__c;
                List<Asset> vgts = AssetSvc.retrieveAccountVgts(accountId);
                if(vgts == null || vgts.isEmpty()) {
                    dto.message += ' ' + rps.Account__r.Name + ' has no vgt assets.';
                }
            }
        }
        Cash_Logistics_Setting__mdt mdtMeterReadings =
                (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,MDT_METER_READINGS_DEV_NAME);

        dto.technicalMsg += '..rpsId='+rpsId +'..assetRecordType='+assetRecordType;
        dto.values.put(MAP_KEY_METER_READINGS,meterReadingWrappers);
        dto.values.put(MAP_KEY_MDT_METER_READINGS,mdtMeterReadings);

        dto.isSuccess = !MeterReadingWrappers.isEmpty();
        return dto;
    }
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRpsMeterReadingsForProcessor(Id rpsId,String assetRecordType) {
        ResponseDto dto = new ResponseDto();

        List<MeterReadingWrapper> meterReadingWrappers = new List<MeterReadingWrapper>();

        Map<Id,Meter_Reading__c> mMeterReadings = clMeterSvc.retrieveRpsMeterReadings(rpsId,assetRecordType);
        if(mMeterReadings != null && !mMeterReadings.isEmpty()) {
            meterReadingWrappers = buildMetersResponse(mMeterReadings.values());
            meterReadingWrappers.sort();
        } else {
            dto.message = 'No Meter readings found for this route processing sheet.';
            List<Route_Processing_Sheet__c> rpss = [SELECT Id, Account__c, Account__r.Name FROM  Route_Processing_Sheet__c WHERE Id = :rpsId];
            if(!rpss.isEmpty()) {
                Route_Processing_Sheet__c rps = rpss[0];
                Id accountId = rps.Account__c;
                List<Asset> vgts = AssetSvc.retrieveAccountVgts(accountId);
                if(vgts == null || vgts.isEmpty()) {
                    dto.message += ' ' + rps.Account__r.Name + ' has no vgt assets.';
                }
            }
        }
        dto.technicalMsg += '..rpsId='+rpsId +'..assetRecordType='+assetRecordType;
        dto.values.put(MAP_KEY_METER_READINGS,meterReadingWrappers);
        dto.isSuccess = !MeterReadingWrappers.isEmpty();
        return dto;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRpsMeterReadingsSummary(Id rpsId) {
        ResponseDto dto = new ResponseDto();

        List<MeterReadingSummary> meters = new List<MeterReadingSummary>();

        Map<Id,Meter_Reading__c> mMeterReadings = clMeterSvc.retrieveRpsMeterReadingsSummary(rpsId);
        if(mMeterReadings != null && !mMeterReadings.isEmpty()) {
            meters = buildMetersSummaryResponse(mMeterReadings.values());
            meters.sort();
        } else {
            dto.message = 'No Meter readings found for this route processing sheet.';
            List<Route_Processing_Sheet__c> rpss = [SELECT Id, Account__c, Account__r.Name FROM  Route_Processing_Sheet__c WHERE Id = :rpsId];
            if(!rpss.isEmpty()) {
                Route_Processing_Sheet__c rps = rpss[0];
                Id accountId = rps.Account__c;
                List<Asset> vgts = AssetSvc.retrieveAccountVgts(accountId);
                if(vgts == null || vgts.isEmpty()) {
                    dto.message += ' ' + rps.Account__r.Name + ' has no vgt assets.';
                }
            }
        }
        dto.technicalMsg += '..rpsId='+rpsId;
        dto.values.put(MAP_KEY_METER_READINGS_SUMMARY,meters);
        dto.isSuccess = !meters.isEmpty();
        return dto;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveCollectorMeterDetail(Id meterId) {
        ResponseDto dto = new ResponseDto();

        clMeterReadingDetail meterDetail;

        Meter_Reading__c  meterReading = clMeterSvc.retrieveCollectorMeterDetail(meterid);
        if(meterReading != null) {
            meterDetail = buildMeterCollectorDetailResponse(meterReading);
        } else {
            dto.message = 'No Meter readings found for this meter';
        }
        dto.technicalMsg += '..meterId='+meterId;
        dto.values.put('MAP_KEY_METER_READING_COLLECTOR_DETAIL',meterDetail);
        dto.isSuccess = meterDetail != null;
        return dto;
    }
    /**
     *
     * @param meterReading  A List of Meter_Reading__c sObjects.
     * @return              The Meter reading wrappers for UI Display.
     */
    public static List<MeterReadingWrapper> buildMetersResponseNoContentDoc(  List<Meter_Reading__c> meterReading) {

        List<MeterReadingWrapper> meterReadingWrappers = new List<MeterReadingWrapper>();
        for(Meter_Reading__c mr : meterReading) {
            MeterReadingWrapper wrap = new MeterReadingWrapper(mr);
            String title = mr.Route_Processing_Sheet__r.Account__r.Name;
            title = title.replaceAll(' ','_');
            wrap.imgTitle = title + '_' + mr.Asset__r.RecordType.Name +
                    '_'+mr.Asset__r.SAS__c + '_'+mr.Asset__r.SerialNumber;
            wrap.imgTitleDisplay = wrap.imgTitle;
            if(title.length() > 10) {
                title = title.substring(0,10) + '...';
                wrap.imgTitleDisplay = title + '_' + mr.Asset__r.RecordType.Name +
                        '_'+mr.Asset__r.SAS__c + '...';
                wrap.imgTitleDisplay = wrap.imgTitleDisplay.replaceAll('_', ' ');
            }
            if(mr.Snapshot__c != null && mr.Snapshot__c != '') {
                wrap.showImageThumb = true;
                wrap.showCamLauncher = false;
                wrap.showPicStencil = false;
            }
            meterReadingWrappers.add(wrap);
        }
        return meterReadingWrappers;
    }
    //  OBSOLETE PER https://accel-entertainment.monday.com/boards/1300348967/pulses/2788659595
//    /**
//     * Simply a UI Helper wrapping Meter_Reading__c sObjects.
//     *
//     * @param meterReading A Meter_Reading__c sObj.
//     * @param mMeterReadingId_Cv xx
//     * @param mMeterReadingId_Cd xx
//     *
//     * @return             A List of MeterWrapper objects.
//     */
//    public static List<MeterReadingWrapper> buildMetersResponse(  List<Meter_Reading__c> meterReading,
//            Map<Id,ContentVersion> mMeterReadingId_Cv,
//            Map<Id,ContentDistribution> mMeterReadingId_Cd) {
//
//        List<MeterReadingWrapper> meterReadingWrappers = new List<MeterReadingWrapper>();
//        //String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
//        String baseUrl = 'https://accelentertainment--uat.my.salesforce.com';
//
//        for(Meter_Reading__c mr : meterReading) {
//            MeterReadingWrapper wrap = new MeterReadingWrapper(mr);
//            String title = mr.Route_Processing_Sheet__r.Account__r.Name;
//            title = title.replaceAll(' ','_');
//            wrap.imgTitle = title + '_' + mr.Asset__r.RecordType.Name +
//                    '_'+mr.Asset__r.SAS__c + '_'+mr.Asset__r.SerialNumber;
//            wrap.imgTitleDisplay = wrap.imgTitle;
//            if(title.length() > 10) {
//                title = title.substring(0,10) + '...';
//                wrap.imgTitleDisplay = title + '_' + mr.Asset__r.RecordType.Name +
//                        '_'+mr.Asset__r.SAS__c + '...';
//                wrap.imgTitleDisplay = wrap.imgTitleDisplay.replaceAll('_', ' ');
//            }
//            if(mMeterReadingId_Cv != null && !mMeterReadingId_Cv.isEmpty()) {
//                wrap.contentVersion = mMeterReadingId_Cv.get(mr.Id);
//                wrap.contentDistribution = mMeterReadingId_Cd.get(mr.Id);
//                if(wrap.contentVersion != null && wrap.contentDistribution != null) {
//                    wrap.contentVersionId = wrap.contentVersion.Id;
//                    wrap.contentDocumentId = wrap.contentVersion.ContentDocumentId;
//                    wrap.imgDownloadUrl = /*'/cash' + */wrap.contentDistribution.ContentDownloadUrl.remove(baseUrl);
//                    //wrap.imgDownloadUrl = 'https://accelentertainment--fulldev.lightning.force.com/sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId='+wrap.contentVersionId;
//
//
//                    wrap.imgPreviewUrl =  wrap.contentDistribution.DistributionPublicUrl;
//                    Integer iSize = wrap.contentVersion.ContentDocument.ContentSize;
//                    wrap.imgSize = ContentManagerSvc.formatBytes(iSize,1);
//                    wrap.imgUserName = wrap.contentVersion.contentDocument.CreatedBy.Name;
//                    wrap.showImageThumb = true;
//                    wrap.showCamLauncher = false;
//                    wrap.showPicStencil = false;
//                    wrap.imgLastModifiedDate = wrap.contentVersion.LastModifiedDate;
//                    wrap.download = wrap.contentVersion.Title;
//                }
//            }
//            meterReadingWrappers.add(wrap);
//        }
//        return meterReadingWrappers;
//    }
    /**
     * Simply a UI Helper wrapping Meter_Reading__c sObjects.
     *
     * @param meterReading A Meter_Reading__c sObj.
     *
     * @return             A List of MeterWrapper objects.
     */
    public static List<MeterReadingWrapper> buildMetersResponse(  List<Meter_Reading__c> meterReading) {

        List<MeterReadingWrapper> meterReadingWrappers = new List<MeterReadingWrapper>();
        //String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        String baseUrl = 'https://accelentertainment--uat.my.salesforce.com';


        Integer i = 1;
        for(Meter_Reading__c mr : meterReading) {
            MeterReadingWrapper wrap = new MeterReadingWrapper(mr);
            String tileStyle = '';
            if(Math.mod(i,2) ==0) { //even rows
                tileStyle = 'background-color:#F3F2F2';
            }
            wrap.placeHolder = 'Enter total '+mr.Asset__r.RecordType.Name + ' ' + mr.Asset__r.SAS__c +' drop';
            wrap.actualDropFieldLabel = mr.Asset__r.RecordType.Name + ' ' + mr.Asset__r.SAS__c + ' total drop';
            wrap.tileStyle = tileStyle;
            meterReadingWrappers.add(wrap);
            i++;
        }
        return meterReadingWrappers;
    }

    public static List<MeterReadingSummary> buildMetersSummaryResponse(  List<Meter_Reading__c> meterReading) {

        List<MeterReadingSummary> meters = new List<MeterReadingSummary>();

        Integer i = 1;
        for(Meter_Reading__c mr : meterReading) {
            MeterReadingSummary meter = new MeterReadingSummary(mr);
            meters.add(meter);
            i++;
        }
        return meters;
    }

    public static clMeterReadingDetail buildMeterCollectorDetailResponse(  Meter_Reading__c meterReading) {
        clMeterReadingDetail meterDetail = new clMeterReadingDetail(meterReading);
        return meterDetail;
    }

    /*
    OBSOLETE PER https://accel-entertainment.monday.com/boards/1300348967/pulses/2788659595
    @TestVisible
    private static Map<Id,ContentVersion> matchContentVersionToMeterReading(Map<Id,Meter_Reading__c> mMeterReadings) {
        Map<Id,ContentVersion> mMeterReadingId_Version = new Map<Id,ContentVersion>();

        Map<Id,ContentDocumentLink> mDocLinks =
                ContentManagerSvc.retrieveContentDocLinks(mMeterReadings.keySet(),'Meter_Reading__c');

        Map<Id,ContentVersion> mVersions =
                ContentManagerSvc.retrieveContentVersions(mMeterReadings.keySet(),'Meter_Reading__c');

        Map<Id,ContentDistribution> mContentDistributions =
                ContentManagerSvc.retrieveContentDistributions(mMeterReadings.keySet());
        System.debug('----> mContentDistributions='+mContentDistributions);

        Map<Id,ContentDocumentLink> mContentDocId_DocLink = new Map<Id,ContentDocumentLink>();
        for(ContentDocumentLink docLink : mDocLinks.values()) {
            mContentDocId_DocLink.put(docLink.ContentDocumentId,docLink);
        }

        for(ContentVersion contentVersion : mVersions.values()) {
            ContentDocumentLink docLink = mContentDocId_DocLink.get(contentVersion.ContentDocumentId);
            if(docLink != null) {
                mMeterReadingId_Version.put(docLink.LinkedEntityId, contentVersion);
            }
        }
        return mMeterReadingId_Version;
    }

    @TestVisible
    private static Map<Id,ContentDistribution> matchContentDistToMeterReading(Map<Id,ContentVersion> mMrId_Cv) {
        Map<Id,ContentDistribution> mMeterReadingId_Distribution = new Map<Id,ContentDistribution>();

        Map<Id,Id> mCvId_MrId = new Map<Id,Id>();
        for(Id mrId : mMrId_Cv.keySet()) {
            mCvId_MrId.put(mMrId_Cv.get(mrId).Id,mrId);
        }

        Map<Id,ContentDistribution> mContentDistributions =
                ContentManagerSvc.retrieveContentDistributions(mCvId_MrId.keySet());
        System.debug('----> mContentDistributions='+mContentDistributions);

        if(mContentDistributions != null && !mContentDistributions.isEmpty()) {
            for (ContentDistribution cd : mContentDistributions.values()) {
                mMeterReadingId_Distribution.put(mCvId_MrId.get(cd.ContentVersionId), cd);
            }
        }
        return mMeterReadingId_Distribution;
    }
     */

    public class ActualNoteCount {
        @AuraEnabled public Decimal oneNoteCount;
        @AuraEnabled public Decimal fiveNoteCount;
        @AuraEnabled public Decimal twentyNoteCount;
        @AuraEnabled public Decimal oneHundredNoteCount;

        public ActualNoteCount(Meter_Reading__c mr) {
            this.oneNoteCount = mr.Actual_1_Note_Count__c != null ? mr.Actual_1_Note_Count__c : 0;
            this.fiveNoteCount = mr.Actual_5_Note_Count__c != null ? mr.Actual_5_Note_Count__c : 0;
            this.twentyNoteCount = mr.Actual_20_Note_Count__c != null ? mr.Actual_20_Note_Count__c : 0;
            this.oneHundredNoteCount = mr.Actual_100_Note_Count__c != null ? mr.Actual_100_Note_Count__c : 0;
        }
    }
    public class MeterReadingWrapper implements Comparable {

        @AuraEnabled public String meterId;
        @AuraEnabled public String meterName;
        @AuraEnabled public Boolean reqDataEntered = false;
        @AuraEnabled public Boolean cannotCollect = false;
        @AuraEnabled public String tileStyle;
        @AuraEnabled public String placeHolder;
        @AuraEnabled public String actualDropFieldLabel;
        @AuraEnabled public DateTime meterLastModifiedDate;
        @AuraEnabled public Double actualDrop = 0;
        @AuraEnabled public String meterStatus;
        @AuraEnabled public String meterIconClass = 'accel-machine_icon-not-completed';
        @AuraEnabled public String meterBadgeClass = 'accel-mtr_badge-not-completed';
        @AuraEnabled public String meterReadingCompletedTextClass = 'accel-meter-reading_completed';
        @AuraEnabled public ActualNoteCount actualNoteCount;


        @AuraEnabled public String machineName = '';
        @AuraEnabled public String machineSerialNumber = '';
        @AuraEnabled public String machineModel = '';
        @AuraEnabled public String machineAssetId = '';
        @AuraEnabled public Integer machineSas;
        @AuraEnabled public Double lifeTimeCashInAmount = 0;

        @AuraEnabled public Boolean showPicStencil = true;
        @AuraEnabled public Boolean showCamLauncher = false;
        @AuraEnabled public Boolean showImageThumb = false;
        @AuraEnabled public Boolean allowCamLaunch = true;
        @AuraEnabled public String contentVersionId = '';
        @AuraEnabled public String contentDocumentId = '';
        @AuraEnabled public String imgDownloadUrl;
        @AuraEnabled public String imgPreviewUrl;
        @AuraEnabled public String imgTitle = '';
        @AuraEnabled public String imgTitleDisplay = '';
        @AuraEnabled public String imgSize = '';
        @AuraEnabled public String imgUserName = '';
        @AuraEnabled public Datetime imgLastModifiedDate;
        @AuraEnabled public String  download = '';
        @AuraEnabled public String  href = '';
        @AuraEnabled public String imgBase64 = '';
        @AuraEnabled public Datetime mtrLastModDt;
        @AuraEnabled public Decimal cashInAmount;
        @AuraEnabled public Boolean isLoading = false;
        @AuraEnabled public Boolean isDeleting = false;
        @AuraEnabled public String snapShot = '';

        //  The below are intentionally not made visible to the front end to lower band width.
        public Meter_Reading__c meterReading;
        public ContentVersion   contentVersion;
        public ContentDistribution contentDistribution;


        public MeterReadingWrapper(Meter_Reading__c meterReading) {
            this.meterReading = meterReading;
            this.actualNoteCount = new ActualNoteCount(meterReading);
            this.reqDataEntered = meterReading.Required_Data_Entered__c;
            this.cannotCollect = meterReading.Cannot_Collect__c;
            this.meterStatus = meterReading.Reading_Status__c;
            this.setUiCssClasses(this.meterReading);
            this.snapShot = meterReading.Snapshot__c;

            this.meterId = meterReading.Id;
            this.meterName = meterReading.Name;
            //  Dont show last modified date on first load of record...
            this.meterLastModifiedDate = meterReading.LastModifiedDate != meterReading.CreatedDate ? meterReading.LastModifiedDate : null;
            this.cashInAmount = meterReading.Current_Lifetime_Cash_In__c;
            this.actualDrop = meterReading.Actual_Drop__c != null ? meterReading.Actual_Drop__c : 0;
            this.mtrLastModDt = meterReading.LastModifiedDate;
            this.lifeTimeCashInAmount = meterReading.Current_Lifetime_Cash_In__c;


            if(this.lifeTimeCashInAmount != null && this.lifeTimeCashInAmount != 0) {
                this.showCamLauncher = true;
                this.showPicStencil = false;
            }
            readAssetInfo(meterReading);
        }


        private void setUiCssClasses(Meter_Reading__c meterReading) {
            if(this.meterStatus != MR_CANNOT_COLLECT_STATUS) {
                this.meterIconClass = this.meterStatus != MR_COMPLETED_STATUS ? 'accel-machine_icon-not-completed' : 'accel-machine_icon-completed';
                this.meterBadgeClass = this.meterStatus != MR_COMPLETED_STATUS ? 'accel-mtr_badge-not-completed' : 'accel-mtr_badge-completed';
                this.meterReadingCompletedTextClass = this.meterStatus != MR_COMPLETED_STATUS ? 'accel-meter-reading_notcompleted' : 'accel-meter-reading_completed';
            } else {
                this.meterIconClass = 'accel-machine_icon-cannot-collect';
                this.meterBadgeClass = 'accel-mtr_badge-cannot-collect';
                this.meterReadingCompletedTextClass = 'accel-meter-reading_cannot-collect';
            }
        }

        private void readAssetInfo(Meter_Reading__c meterReading) {
            if(meterReading.Asset__r != null) {
                this.machineName = meterReading.Asset__r.RecordType.DeveloperName + ' '
                        + meterReading.Asset__r.SAS__c;
                this.machineSas = meterReading.Asset__r.SAS__c != null ?  Integer.valueOf(meterReading.Asset__r.SAS__c) : null;
                this.machineName = removeRedemptionText(this.machineName);
                this.machineSerialNumber = meterReading.Asset__r.SerialNumber;
                this.machineModel = meterReading.Asset__r.Model__c;
                this.machineAssetId = meterReading.Asset__c;
            }
        }

        private String removeRedemptionText(String machineName) {
            return machineName.remove('Redemption');
        }
        /**
         * Since Asset.SAS__c is a string field, but typically contains numeric data for VGTs.. We must first
         * convert the value to an Integer as a natural Order By Sort will not work correctly. Then we use this
         * custom sort.
         *
         * @param objToCompare The MeterReadingWrapper object to compare to
         * @return Integer value of sort order
         */
        public Integer compareTo(Object objToCompare) {
            MeterReadingWrapper compareToWrap = (MeterReadingWrapper) objToCompare;
            if(machineSas == compareToWrap.machineSas) return 0;
            if(machineSas > compareToWrap.machineSas) return 1;
            return -1;
        }
    }

    public class MeterReadingSummary implements Comparable {

        @AuraEnabled public Id meterId;
        @AuraEnabled public String meterName;
        @AuraEnabled public String meterStatus;
        @AuraEnabled public String machineName = '';
        @AuraEnabled public Integer machineSas;
        @AuraEnabled public String machineSerial = '';
        @AuraEnabled public String machineModel = '';


        public MeterReadingSummary(Meter_Reading__c meterReading) {
            this.meterStatus = meterReading.Reading_Status__c;
            this.meterId = meterReading.Id;
            this.meterName = meterReading.Name;
            readAssetInfo(meterReading);
        }

        private void readAssetInfo(Meter_Reading__c meterReading) {
            if(meterReading.Asset__r != null) {
                this.machineName = meterReading.Asset__r.RecordType.DeveloperName + ' '
                        + meterReading.Asset__r.SAS__c;
                this.machineSas = meterReading.Asset__r.SAS__c != null ?  Integer.valueOf(meterReading.Asset__r.SAS__c) : null;
                this.machineName = removeRedemptionText(this.machineName);
                this.machineSerial = meterReading.Asset__r.SerialNumber;
                this.machineModel = meterReading.Asset__r.Model__c;
            }
        }

        private String removeRedemptionText(String machineName) {
            return machineName.remove('Redemption');
        }
        /**
         * Since Asset.SAS__c is a string field, but typically contains numeric data for VGTs.. We must first
         * convert the value to an Integer as a natural Order By Sort will not work correctly. Then we use this
         * custom sort.
         *
         * @param objToCompare The MeterReadingWrapper object to compare to
         * @return Integer value of sort order
         */
        public Integer compareTo(Object objToCompare) {
            MeterReadingSummary compareToWrap = (MeterReadingSummary) objToCompare;
            if(machineSas == compareToWrap.machineSas) return 0;
            if(machineSas > compareToWrap.machineSas) return 1;
            return -1;
        }
    }
}