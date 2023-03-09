/**
 * clRedemptionController is a UI Orientated class generally meant to community with the redemption readings lwc.
 *
 * @see ContentManagerSvc
 * @see clRouteSvc
 */
public class clRedemptionController {

    public static String MAP_KEY_RPS_RECORD = 'RPS_RECORD';
    public static String MSG_FAILED_RPS_RT_START_DATE = 'Unable to update RPS RT Start Date!';
    public static String MSG_FAILED_RPS_RT_END_DATE = 'Unable to update RPS RT End Date!';
    @TestVisible private static Boolean TEST_TRIGGER_DML_EX = false;

    //  @todo the below date updates should be merged at some point.

    /**
     * Sets the RPS RT Start Date and Start Date User Value to the current Datetime and running user.
     *
     * @param rpsId The Route_Processing_Sheet__c.Id
     * @return      A ResponseDto containing the updated Route_Processing_Sheet__c record in the values map.
     */
    @AuraEnabled
    public static ResponseDto updateRpsRtStartReplenishmentDate(Id rpsId) {
        ResponseDto dto = new ResponseDto();
        String failMessage = MSG_FAILED_RPS_RT_START_DATE;
        if(rpsId != null) {
            dto.technicalMsg = 'rpsId:' + rpsId;
            Route_Processing_Sheet__c rpsRecord = clRouteSvc.retrieveRouteProcessingSheet(rpsId);
            if(rpsRecord != null) {
                rpsRecord = clRouteSvc.tagRpsUtilizationDates(rpsRecord, clRpsDateEnum.START_RT_REPLENISHMENT_DATE);
                if(TEST_TRIGGER_DML_EX) {  rpsRecord.Collection_Type__c = 'Bogus'; }
                update rpsRecord;
                dto.message = 'RT Start Date successfully set to '+rpsRecord.Start_RT_Replenishment_Date__c.format();
                dto.severity = 'success';
                dto.isSuccess = true;
                dto.values.put(MAP_KEY_RPS_RECORD, rpsRecord);
            } else {
                dto.message = failMessage;
                dto.severity = 'error';
                dto.technicalMsg += ' No RPS Record found for Id: '+rpsId;
            }
        } else {
            dto.technicalMsg += 'Invalid rpsId = '+rpsId;
            dto.message = failMessage;
            dto.severity = 'error';
        }
        return dto;
    }

    /**
     * Sets the RPS RT End Date and End Date User Value to the current Datetime and running user.
     *
     * @param rpsId The Route_Processing_Sheet__c.Id
     * @return      A ResponseDto containing the updated Route_Processing_Sheet__c record in the values map.
     */
    @AuraEnabled
    public static ResponseDto updateRpsRtEndReplenishmentDate(Id rpsId) {
        ResponseDto dto = new ResponseDto();
        String failMessage = MSG_FAILED_RPS_RT_END_DATE;
        if(rpsId != null) {
            dto.technicalMsg = 'rpsId:' + rpsId;
            Route_Processing_Sheet__c rpsRecord = clRouteSvc.retrieveRouteProcessingSheet(rpsId);
            if(rpsRecord != null) {
                rpsRecord = clRouteSvc.tagRpsUtilizationDates(rpsRecord, clRpsDateEnum.END_RT_REPLENISHMENT_DATE);
                if(TEST_TRIGGER_DML_EX) {  rpsRecord.Collection_Type__c = 'Bogus'; }
                update rpsRecord;
                dto.message = 'RT End Date successfully set to '+rpsRecord.End_RT_Replenishment_Date__c.format();
                dto.severity = 'success';
                dto.isSuccess = true;
                dto.values.put(MAP_KEY_RPS_RECORD, rpsRecord);
            } else {
                dto.message = failMessage;
                dto.severity = 'error';
                dto.technicalMsg += ' No RPS Record found for Id: '+rpsId;
            }
        } else {
            dto.technicalMsg += 'Invalid rpsId = '+rpsId;
            dto.message = failMessage;
            dto.severity = 'error';
        }
        return dto;
    }


    @AuraEnabled
    public static ResponseDto deleteDoc(Id docId, Id rpsId) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'doc id attempted to delete: '+docId + ' for rps='+rpsId;
        try {
            ContentDocument deletedDoc = ContentManagerSvc.deleteDocument(docId);
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
     * Retrieves an Existing Rps Record (RpsWrapper) for the Route_Processing_Sheet__c.Id.
     *
     * @param       rpsId              The Route_Processing_Sheet__c.Id.
    *
     * @return      A ResponseDto containing a single RpsWrapper object
     *
     * @implnotes   Build response method and match methods are bulk ready in case we want to run
     *              then for more then 1 rps but in reality the ui is only feeding us one for the
     *              Redemption screen.
     */
    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRpsWrapper(Id rpsId) {
        ResponseDto dto = new ResponseDto();

        Route_Processing_Sheet__c rpsRecord = clRouteSvc.retrieveRouteProcessingSheet(rpsId);
        RpsWrapper rpsWrapper = new RpsWrapper();

        if(rpsRecord != null) {
            dto.technicalMsg += ' have rps record..';
            // Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//            Map<Id, List<ContentVersion>> mRpsId_Cvs = matchContentVersionToRps(rpsRecord);
//            Map<Id,List<ContentDistribution>> mRpsId_Cds = new Map<Id,List<ContentDistribution>>();
//            if(mRpsId_Cvs != null && !mRpsId_Cvs.isEmpty()) {
//                dto.technicalMsg += '... have content versions';
//                mRpsId_Cds = matchContentDistToRps(mRpsId_Cvs);
//                if(mRpsId_Cds != null && !mRpsId_Cds.isEmpty()) {
//                    dto.technicalMsg += '.. have content distributions';
//                }
//            }
            List<RpsWrapper> rpsWrappers =buildRpsResponse(new List<Route_Processing_Sheet__c> {rpsRecord});
                    // // Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
                    //buildRpsResponse(new List<Route_Processing_Sheet__c>{rpsRecord},  mRpsId_Cvs, mRpsId_Cds);
            if(!rpsWrappers.isEmpty()) {
                rpsWrapper = rpsWrappers[0];
            }
            dto.isSuccess = true;
        }
        dto.values.put('RPS_WRAPPER_DATA',rpsWrapper);
        return dto;
    }

    public static List<RpsWrapper> buildRpsResponse(  List<Route_Processing_Sheet__c> rpss) {

        List<RpsWrapper> rpsWrappers = new List<RpsWrapper>();

        for(Route_Processing_Sheet__c rps: rpss) {
            RpsWrapper wrap = new RpsWrapper(rps);
            rpsWrappers.add(wrap);
        }
        return rpsWrappers;
    }


    /**
     *
     * Simply a UI Helper wrapping Route_Processing_Sheet__c sObjects.
     * Find all contentversion and contentdistribution records related to the rps.
     * Build image objects based on this data for use in the UI.
     *
     * @param rpss              A List pf Route_processing_sheet__c sObjects
     * @param mRpsId_Cvs        A Map of Rps Id => List<ContentVersion>
     * @param mRpsId_Cds        A Map of Rps Id => List<ContentDistribution>
     *
     * @return                  A List of RpsWWrapper objects. (should only be 1)
     */
//  Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//    public static List<RpsWrapper> buildRpsResponse(  List<Route_Processing_Sheet__c> rpss,
//            Map<Id,List<ContentVersion>> mRpsId_Cvs, Map<Id,List<ContentDistribution>> mRpsId_Cds) {
//
//        List<RpsWrapper> rpsWrappers = new List<RpsWrapper>();
//
//        for(Route_Processing_Sheet__c rps: rpss) {
//            RpsWrapper wrap = new RpsWrapper(rps);
//            if(mRpsId_Cvs != null && !mRpsId_Cvs.isEmpty()) {
//                wrap.contentVersions = mRpsId_Cvs.get(rps.Id);
//            }
//            if(mRpsId_Cds != null && !mRpsId_Cds.isEmpty()) {
//                wrap.contentDistributions = mRpsId_Cds.get(rps.Id);
//            }
//
//            if(wrap.contentVersions != null && !wrap.contentVersions.isEmpty()) {
//                buildImageData(wrap.contentVersions,wrap.contentDistributions,wrap);
//            }
//            rpsWrappers.add(wrap);
//        }
//        return rpsWrappers;
//    }

//    Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//    /**
//     * Find all the ContentVersion records (files) associated with this RPS Record.
//     *
//     * @param rpsRecord  A Route_Processing_Sheet__c sObject.
//     * @return           A Map of RPS ID => List<ContentVersion>
//     */
//    @TestVisible
//    private static Map<Id,List<ContentVersion>> matchContentVersionToRps(Route_Processing_Sheet__c rpsRecord) {
//        Map<Id,List<ContentVersion>> mRpsId_Versions = new Map<Id,List<ContentVersion>>();
//        Id rpsId = rpsRecord.Id;
//
//        Map<Id,ContentDocumentLink> mDocLinks =
//                ContentManagerSvc.retrieveContentDocLinks(new Set<Id> {rpsId},'Route_Processing_Sheet__c');
//
//        Map<Id,ContentVersion> mVersions =
//                ContentManagerSvc.retrieveContentVersions(new Set<Id> {rpsId},'Route_Processing_Sheet__c');
//
//        Map<Id,ContentDistribution> mContentDistributions =
//                ContentManagerSvc.retrieveContentDistributions( new Set<Id> {rpsId} );
//        System.debug('----> mContentDistributions='+mContentDistributions);
//
//        Map<Id,ContentDocumentLink> mContentDocId_DocLink = new Map<Id,ContentDocumentLink>();
//        for(ContentDocumentLink docLink : mDocLinks.values()) {
//            mContentDocId_DocLink.put(docLink.ContentDocumentId,docLink);
//        }
//
//        for(ContentVersion contentVersion : mVersions.values()) {
//            ContentDocumentLink docLink = mContentDocId_DocLink.get(contentVersion.ContentDocumentId);
//            if(docLink != null) {
//                if(!mRpsId_Versions.containsKey(rpsId)) {
//                    mRpsId_Versions.put(rpsId, new List<ContentVersion>{contentVersion});
//                } else {
//                    List<ContentVersion> cvs = mRpsId_Versions.get(rpsId);
//                    cvs.add(contentVersion);
//                }
//            }
//        }
//        return mRpsId_Versions;
//    }

    /**
     * Find all the ContentDistribution records (files) associated with this RPS Record.
     *
     * @param mRpsId_Cvs      A Map of RPS ID => List<ContentVersion>
     * @return               A Map of RPS ID => List<ContentDistribution>
     */
//    Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//    @TestVisible
//    private static Map<Id,List<ContentDistribution>> matchContentDistToRps(Map<Id,List<ContentVersion>> mRpsId_Cvs) {
//        Map<Id,List<ContentDistribution>> mRpsId_Distribution = new Map<Id,List<ContentDistribution>>();
//
//        Map<Id,Id> mCvId_RpsId = new Map<Id,Id>();
//        for(Id rpsId : mRpsId_Cvs.keySet()) {
//            List<ContentVersion> cvs = mRpsId_Cvs.get(rpsId);
//            if(cvs!=null && !cvs.isEmpty()) {
//                for(ContentVersion cv : cvs) {
//                    mCvId_RpsId.put(cv.Id,rpsId);
//                }
//            }
//        }
//
//        Map<Id,ContentDistribution> mContentDistributions =
//                ContentManagerSvc.retrieveContentDistributions(mCvId_RpsId.keySet());
//        System.debug('----> mContentDistributions='+mContentDistributions);
//
//        if(mContentDistributions != null && !mContentDistributions.isEmpty()) {
//            for (ContentDistribution cd : mContentDistributions.values()) {
//                Id rpsId = mCvId_RpsId.get(cd.ContentVersionId);
//                if(mRpsId_Distribution.containsKey(rpsID)) {
//                    List<ContentDistribution> cds = mRpsId_Distribution.get(rpsId);
//                    cds.add(cd);
//                } else {
//                    mRpsId_Distribution.put(rpsId, new List<ContentDistribution> {cd});
//                }
//            }
//        }
//        return mRpsId_Distribution;
//    }

    /**
     *  The main wrapper object for use in the UI.
     */
    public class RpsWrapper {

        @AuraEnabled public String rpsId;
        @AuraEnabled public String rpsName;
        @AuraEnabled public String rpsAccountName;
        @AuraEnabled public String rpsAccountFundsInField;
        @AuraEnabled public String rtStatus;
        @AuraEnabled public String rpsCollectionStatus;


        @AuraEnabled public Datetime  rpsRtStartReplenishmentDate;
        @AuraEnabled public Datetime  rpsRtEndReplenishmentDate;
        @AuraEnabled public String    rpsReplenishmentType;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Boolean  lastModNotEqualCreated = false;
        @AuraEnabled public String  lastModDateTextClass = 'accel-redemption_notcompleted';
        @AuraEnabled public String  lastModDateIconClass = 'accel-redemption_last_mod_icon_notcompleted';

        @AuraEnabled public String  snapshotCassette = '';
        @AuraEnabled public String  snapshotNewCassette = '';

        @AuraEnabled public clImage   currentCassetteImg  = new clImage();
        @AuraEnabled public clImage   currentCoinImg      = new clImage();
        @AuraEnabled public clImage   newCassetteImg      = new clImage();
        @AuraEnabled public clImage   newCoinImg          = new clImage();


        //  The below are intentionally not made visible to the front end to lower band width.
        public Route_Processing_Sheet__c rpsRecord;
        // Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//        public List<ContentVersion>   contentVersions;
//        public List<ContentDistribution> contentDistributions;

        public RpsWrapper() {
// Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//            this.contentVersions = new List<ContentVersion>();
//            this.contentDistributions = new List<ContentDistribution>();
        }

        /**
         * Builds initial image title info on each type of image so the camlauncher has some initial title to use.
         *
         * @param rpsRecord  A Route_Processing_Sheet__c sObject.
         */
        public RpsWrapper(Route_Processing_Sheet__c rpsRecord) {
            this.rpsRecord = rpsRecord;
            this.rpsId = rpsRecord.Id;
            this.rpsName = rpsRecord.Name;
            this.rpsAccountName = rpsRecord.Account__r.Name;
            this.rpsAccountFundsInField = rpsRecord.Account__r.Funds_in_Field__c;
            this.rpsRtStartReplenishmentDate = rpsRecord.Start_RT_Replenishment_Date__c;
            this.rpsRtEndReplenishmentDate = rpsRecord.End_RT_Replenishment_Date__c;
            this.rpsReplenishmentType = rpsRecord.Replenishment_Type__c;
            this.lastModifiedDate = rpsRecord.LastModifiedDate;
            this.createdDate = rpsRecord.createdDate;
            this.lastModNotEqualCreated = lastModifiedDate != createdDate;
            this.rtStatus = rpsRecord.Redemption_Terminal_Status__c;
            this.rpsCollectionStatus  = rpsRecord.Status__c;
            this.snapshotCassette = rpsRecord.Snapshot_Cassette__c;
            this.snapshotNewCassette = rpsRecord.Snapshot_New_Cassette__c;

            if(this.rtStatus == 'Complete') {
                lastModDateTextClass = 'accel-redemption_completed';
                lastModDateIconClass = 'accel-redemption_last_mod_icon_completed';
            }
// Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//            this.contentVersions = new List<ContentVersion>();
//            this.contentDistributions = new List<ContentDistribution>();
            buildImgTitleInfo('Current Cassette',this.currentCassetteImg,this.rpsRecord);
            buildImgTitleInfo('Current Coin',this.currentCoinImg,this.rpsRecord);
            buildImgTitleInfo('New Cassette',this.newCassetteImg,this.rpsRecord);
            buildImgTitleInfo('New Coin', this.newCoinImg, this.rpsRecord);
            if(this.snapshotCassette != null && this.snapshotCassette != '') {
                this.currentCassetteImg.showCamLauncher = false;
                this.currentCassetteImg.showThumb = true;
            }
            if(this.snapshotNewCassette != null && this.snapshotNewCassette != '') {
                this.newCassetteImg.showCamLauncher = false;
                this.newCassetteImg.showThumb = true;
            }
        }
    }

    /**
     * UI Specific. creates a short version of the title for display using account name, rt type, rps #
     * by truncated the account name as we are unsure how long it will be.
     *
     * Also creates an longer version (for use in the actual save of the file)
     *
     * @param rtImageType   The rtImageType [Current Cassette, Current Coin, New Cassette, New Coin].
     * @param img           The empty clImage Object.
     * @param rpsRecord     The Route_Processing_Sheet__c sObject.
     */
    @TestVisible
    private static void buildImgTitleInfo(String rtImageType, clImage img, Route_Processing_Sheet__c rpsRecord) {
        String title = rpsRecord.Account__r.Name;
        title = title.replaceAll(' ','_');
        string rtImageTypeCleansed = rtImageType.replaceAll(' ','_');
        img.title =  title + '_RT_'+ rtImageTypeCleansed + '_'+rpsRecord.Name;
        img.rtImageType = rtImageType;
        if(title.length() > 10) {
            title = title.substring(0,10) + '...';
            img.displayTitle = title + '_RT_'+rtImageTypeCleansed;
            img.displayTitle = img.displayTitle.replaceAll('_',' ');
        }
    }
//    // Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//    /**
//     * Roll through cv records and find the one based on cv.Redemption_Image_Type__c.
//     *
//     * @param cvss                  A List<ContentVersion> objects to search.
//     * @param redemptionImageType   The rtImageType [Current Cassette, Current Coin, New Cassette, New Coin].
//     *
//     * @return                      A single ContentVersion object if found, otherwise null.
//     */
//    @TestVisible
//    private static ContentVersion findContentVersion(List<ContentVersion> cvss, String redemptionImageType) {
//        ContentVersion foundCv;
//        if(cvss != null && !cvss.isEmpty()) {
//            for(ContentVersion cv: cvss) {
//                if(cv.Redemption_Image_Type__c == redemptionImageType) {
//                    foundCv = cv;
//                    break;
//                }
//            }
//        }
//        return foundCv;
//    }

//    // Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//    /**
//     * Roll through ContentDistribution  records and find the one based on cv.Redemption_Image_Type__c.
//     *
//     * @param cds                   A List<ContentDistribution> objects to search.
//     * @param redemptionImageType   The rtImageType [Current Cassette, Current Coin, New Cassette, New Coin].
//     *
//     * @return                      A single ContentDistribution object if found, otherwise null.
//     */
//    @TestVisible
//    private static ContentDistribution findContentDistribution(List<ContentDistribution> cds, String redemptionImageType) {
//        ContentDistribution foundCd;
//        if(cds != null && !cds.isEmpty()) {
//            for(ContentDistribution cd: cds) {
//                if(cd.ContentVersion.Redemption_Image_Type__c == redemptionImageType) {
//                    foundCd = cd;
//                    break;
//                }
//            }
//        }
//        return foundCd;
//    }

//    // Obsolete per https://accel-entertainment.monday.com/boards/1300348967/pulses/2818920534
//    /**
//     * Build wrapper image data for each type of image (set by reference) on the rpswrapper.
//     *
//     * @param contentVersions           A List<ContentVersion> objects.
//     * @param contentDistributions      A List<ContentDisctibution> objects.
//     * @param wrap                      The RpsWrapper object.
//     */
//    private static void buildImageData(List<ContentVersion> contentVersions, List<ContentDistribution> contentDistributions, RpsWrapper wrap) {
//
//        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
//
//        String rtImageType = 'Current Cassette';
//        ContentVersion currentCassetteCv = findContentVersion(wrap.contentVersions,rtImageType);
//        ContentDistribution currentCassetteCd = findContentDistribution(wrap.contentDistributions,rtImageType);
//        if(currentCassetteCv != null) {
//            wrap.currentCassetteImg.contentVersionId = currentCassetteCv.Id;
//            wrap.currentCassetteImg.contentDocumentId = currentCassetteCv.ContentDocumentId;
//            wrap.currentCassetteImg.showThumb = true;
//            wrap.currentCassetteImg.showCamLauncher = false;
//            wrap.currentCassetteImg.downloadUrl =  currentCassetteCd.ContentDownloadUrl.remove(baseUrl);
//            wrap.currentCassetteImg.previewUrl =  currentCassetteCd.DistributionPublicUrl;
//            Integer iSize = currentCassetteCv.ContentDocument.ContentSize;
//            wrap.currentCassetteImg.size = ContentManagerSvc.formatBytes(iSize,1);
//            wrap.currentCassetteImg.userName = currentCassetteCv.ContentDocument.CreatedBy.Name;
//            wrap.currentCassetteImg.lastModifiedDate = currentCassetteCv.ContentDocument.LastModifiedDate;
//            wrap.currentCassetteImg.rtImageType = rtImageType;
//            wrap.currentCassetteImg.viewCount = currentCassetteCd.ViewCount;
//        }
//
//        rtImageType  = 'Current Coin';
//        ContentVersion currentCoinCv = findContentVersion(wrap.contentVersions,rtImageType);
//        ContentDistribution currentCoinCd = findContentDistribution(wrap.contentDistributions,rtImageType);
//        if(currentCoinCv != null) {
//            wrap.currentCoinImg.contentVersionId = currentCoinCv.Id;
//            wrap.currentCoinImg.contentDocumentId = currentCoinCv.ContentDocumentId;
//            wrap.currentCoinImg.showThumb = true;
//            wrap.currentCoinImg.showCamLauncher = false;
//            wrap.currentCoinImg.downloadUrl =  currentCoinCd.ContentDownloadUrl.remove(baseUrl);
//            wrap.currentCoinImg.previewUrl =  currentCoinCd.DistributionPublicUrl;
//            Integer iSize = currentCoinCv.ContentDocument.ContentSize;
//            wrap.currentCoinImg.size = ContentManagerSvc.formatBytes(iSize,1);
//            wrap.currentCoinImg.userName = currentCoinCv.ContentDocument.CreatedBy.Name;
//            wrap.currentCoinImg.lastModifiedDate = currentCoinCv.ContentDocument.LastModifiedDate;
//            wrap.currentCoinImg.rtImageType = rtImageType;
//            wrap.currentCoinImg.viewCount = currentCoinCd.ViewCount;
//        }
//
//        rtImageType  = 'New Cassette';
//        ContentVersion newCassetteCv = findContentVersion(wrap.contentVersions,rtImageType);
//        ContentDistribution newCassetteCd = findContentDistribution(wrap.contentDistributions,rtImageType);
//        if(newCassetteCv != null) {
//            wrap.newCassetteImg.contentVersionId = newCassetteCv.Id;
//            wrap.newCassetteImg.contentDocumentId = newCassetteCv.ContentDocumentId;
//            wrap.newCassetteImg.showThumb = true;
//            wrap.newCassetteImg.showCamLauncher = false;
//            wrap.newCassetteImg.downloadUrl =  newCassetteCd.ContentDownloadUrl.remove(baseUrl);
//            wrap.newCassetteImg.previewUrl =  newCassetteCd.DistributionPublicUrl;
//            Integer iSize = newCassetteCv.ContentDocument.ContentSize;
//            wrap.newCassetteImg.size = ContentManagerSvc.formatBytes(iSize,1);
//            wrap.newCassetteImg.userName = newCassetteCv.ContentDocument.CreatedBy.Name;
//            wrap.newCassetteImg.lastModifiedDate = newCassetteCv.ContentDocument.LastModifiedDate;
//            wrap.newCassetteImg.rtImageType = rtImageType;
//            wrap.newCassetteImg.viewCount = newCassetteCd.ViewCount;
//        }
//
//        rtImageType  = 'New Coin';
//        ContentVersion newCoinCv = findContentVersion(wrap.contentVersions,rtImageType);
//        ContentDistribution newCoinCd = findContentDistribution(wrap.contentDistributions,rtImageType);
//        if(newCoinCv != null) {
//            wrap.newCoinImg.contentVersionId = newCoinCv.Id;
//            wrap.newCoinImg.contentDocumentId = newCoinCv.ContentDocumentId;
//            wrap.newCoinImg.showThumb = true;
//            wrap.newCoinImg.showCamLauncher = false;
//            wrap.newCoinImg.downloadUrl =  newCoinCd.ContentDownloadUrl.remove(baseUrl);
//            wrap.newCoinImg.previewUrl =  newCoinCd.DistributionPublicUrl;
//            Integer iSize = newCoinCv.ContentDocument.ContentSize;
//            wrap.newCoinImg.size = ContentManagerSvc.formatBytes(iSize,1);
//            wrap.newCoinImg.userName = newCoinCv.ContentDocument.CreatedBy.Name;
//            wrap.newCoinImg.lastModifiedDate = newCoinCv.ContentDocument.LastModifiedDate;
//            wrap.newCoinImg.rtImageType = rtImageType;
//            wrap.newCoinImg.viewCount = newCoinCd.ViewCount;
//        }
//    }
}