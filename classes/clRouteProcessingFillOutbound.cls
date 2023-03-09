public without sharing class clRouteProcessingFillOutbound {

    @TestVisible private static final String MAP_KEY_RPS_DATA = 'RPS_WRAPPER_DATA';

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveRpsWrapper(Id rpsId) {

        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' rpsId param='+rpsId;
        Route_Processing_Sheet__c rpsRecord = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rpsId);
        RpsWrapper rpsWrapper;

        if(rpsRecord != null) {
            dto.technicalMsg += ' have rps record..';
            rpsWrapper = buildRpsResponse(rpsRecord);
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_RPS_DATA,rpsWrapper);
        return dto;
    }

    @AuraEnabled(cacheable=true) 
    public static ResponseDto retrieveRpsWrapperNoCache(Id rpsId, Double cacheBust) {

        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' rpsId param='+rpsId;
        Route_Processing_Sheet__c rpsRecord = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rpsId);
        RpsWrapper rpsWrapper;

        if(rpsRecord != null) {
            dto.technicalMsg += ' have rps record..';
            rpsWrapper = buildRpsResponse(rpsRecord);
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_RPS_DATA,rpsWrapper);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto updateRpsStatus(Route_Processing_Sheet__c rps) {

        ResponseDto dto = new ResponseDto();
        String techMsg = 'calling update with rps='+rps;
        try {
            update rps;
            dto = retrieveRpsWrapper(rps.Id);
            RpsWrapper rpsWrapper = (RpsWrapper)dto.values.get(MAP_KEY_RPS_DATA);
            techMsg += '.. update complete';
            dto.technicalMsg = techMsg;
            dto.isSuccess = true;
            dto.message = 'Successfully changed to '+rpsWrapper.rps.Processing_Status__c + '.';
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg = techMsg + 'error on update ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }

    /**
     * @param rpsRecord
     * @return
     */
    private static RpsWrapper buildRpsResponse(Route_Processing_Sheet__c rpsRecord) {
        RpsWrapper rpsWrapper = new RpsWrapper(rpsRecord);
        return rpsWrapper;
    }


    public class RpsWrapper {
        @AuraEnabled public Route_Processing_Sheet__c rps;
        @AuraEnabled public Id rpsId;
        @AuraEnabled public String rpsName;
        @AuraEnabled public Id routeScheduleId;
        @AuraEnabled public String accountName;
        @AuraEnabled public Date collectionDate;
        @AuraEnabled public Date fillDate;
        @AuraEnabled public String collectionDateFormatted;
        @AuraEnabled public String fillDateFormatted;
        @AuraEnabled public String redemptionType;
        @AuraEnabled public String replenishmentType;
        @AuraEnabled public String processingFillStatus;

        public RpsWrapper(Route_Processing_Sheet__c rpsRecord) {
            this.rps = rpsRecord;
            this.rpsId = rpsRecord.Id;
            this.rpsName = rpsRecord.Name;
            this.routeScheduleId = rpsRecord.Route_Schedule__c;
            this.accountName = rpsRecord.Account__r.Name;
            this.collectionDate = rpsRecord.Collection_Date__c;
            if(this.collectionDate != null) {
                this.collectionDateFormatted = this.collectionDate.format();
            }
            this.fillDate = rpsRecord.Route_Fill_Date__c;
            if(this.fillDate != null) {
                this.fillDateFormatted = this.fillDate.format();
            }
            this.redemptionType = rpsRecord.Redemption_Type__c;
            this.replenishmentType = rpsRecord.Replenishment_Type__c;
            this.processingFillStatus = rpsRecord.Processing_Status__c;
        }
    }

}