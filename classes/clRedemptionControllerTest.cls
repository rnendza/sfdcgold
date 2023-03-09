@IsTest
private class clRedemptionControllerTest {

    /**
     * NOTE start / stop test merely there to reset gov limits as creating non cl data takes forever given
     * all the processors / flows and eventually will bust cpu time outs on it's own.
     */
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
        List<Route_Processing_Sheet__c> routeProcessingSheets = (List<Route_Processing_Sheet__c>) mClData.get(clTESTUTILS.SFDCRPS);

        Id rpsId = routeProcessingSheets[0].Id;
        Route_Processing_Sheet__c rps = [SELECT Id, Name FROM  Route_Processing_Sheet__c WHERE Id = :rpsId];

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);

        System.runAs(collector) {
            Set<String> redemptionImageTypes = new Set<String> {'Current Cassette','Current Coin','New Cassette','New Coin'};
            List<ContentVersion> contentVersions = clTESTUTILS.createRpsFiles(rps,redemptionImageTypes);
            System.assert(!contentVersions.isEmpty());
        }
    }

    @IsTest
    static void test_updateRpsRtStartDate() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        //User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id FROM Route_Processing_Sheet__c
        ]);
        Route_Processing_Sheet__c rps = mAllRps.values()[0];

        Test.startTest();

        //System.runAs(collector) {  @todo cross reference on entity error is this a real issue?
            //  Success.
            ResponseDto dto = clRedemptionController.updateRpsRtStartReplenishmentDate(rps.Id);
            System.assert(dto.isSuccess);
            Route_Processing_Sheet__c rpsRecord = (Route_Processing_Sheet__c)dto.values.get(clRedemptionController.MAP_KEY_RPS_RECORD);
            System.assert(rpsRecord.Start_RT_Replenishment_Date__c.date() == Date.today());
            System.assert(rpsRecord.Start_RT_Replenishment_User__c == UserInfo.getUserId());

            //  Null Rps Id.
            dto = clRedemptionController.updateRpsRtStartReplenishmentDate(null);
            System.assert(!dto.isSuccess);
            System.assert(dto.severity == 'error');
            System.assert(dto.message.contains(clRedemptionController.MSG_FAILED_RPS_RT_START_DATE));

            //  RPS Record not found.
            Id badAccountId = [SELECT Id FROM Account LIMIT 1].Id;
            dto = clRedemptionController.updateRpsRtStartReplenishmentDate(badAccountId);
            System.assert(!dto.isSuccess);
            System.assert(dto.severity == 'error');
            System.assert(dto.message.contains(clRedemptionController.MSG_FAILED_RPS_RT_START_DATE));

            //  RPS Record update failed.
            rpsRecord = mAllRps.values()[1];
            DmlException dmlEx;
            try {
                dto.isSuccess = false;
                clRedemptionController.TEST_TRIGGER_DML_EX = true; //  Fake a val rule error.
                dto = clRedemptionController.updateRpsRtStartReplenishmentDate(rps.Id);
                System.assert(!dto.isSuccess);
            } catch (DmlException ex) {
                dmlEx = ex;
            }
            System.assert(dmlEx != null);
        //}

        Test.stopTest();
    }

    @IsTest
    static void test_updateRpsRtEndDate() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        //User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id FROM Route_Processing_Sheet__c
        ]);
        Route_Processing_Sheet__c rps = mAllRps.values()[0];

        Test.startTest();

        //System.runAs(collector) {  @todo cross reference on entity error is this a real issue?
        //  Success.
        ResponseDto dto = clRedemptionController.updateRpsRtEndReplenishmentDate(rps.Id);
        System.assert(dto.isSuccess);
        Route_Processing_Sheet__c rpsRecord = (Route_Processing_Sheet__c)dto.values.get(clRedemptionController.MAP_KEY_RPS_RECORD);
        System.assert(rpsRecord.End_RT_Replenishment_Date__c.date() == Date.today());
        System.assert(rpsRecord.End_RT_Replenishment_User__c == UserInfo.getUserId());

        //  Null Rps Id.
        dto = clRedemptionController.updateRpsRtEndReplenishmentDate(null);
        System.assert(!dto.isSuccess);
        System.assert(dto.severity == 'error');
        System.assert(dto.message.contains(clRedemptionController.MSG_FAILED_RPS_RT_END_DATE));

        //  RPS Record not found.
        Id badAccountId = [SELECT Id FROM Account LIMIT 1].Id;
        dto = clRedemptionController.updateRpsRtEndReplenishmentDate(badAccountId);
        System.assert(!dto.isSuccess);
        System.assert(dto.severity == 'error');
        System.assert(dto.message.contains(clRedemptionController.MSG_FAILED_RPS_RT_END_DATE));

        //  RPS Record update failed.
        rpsRecord = mAllRps.values()[1];
        DmlException dmlEx;
        try {
            dto.isSuccess = false;
            clRedemptionController.TEST_TRIGGER_DML_EX = true; //  Fake a val rule error.
            dto = clRedemptionController.updateRpsRtEndReplenishmentDate(rps.Id);
            System.assert(!dto.isSuccess);
        } catch (DmlException ex) {
            dmlEx = ex;
        }
        System.assert(dmlEx != null);
        //}

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRpsWrapper() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        //  Just get a single RPS THAT has files (contentDoclinks) associated with it
        Route_Processing_Sheet__c rps = findRpssWithFiles()[0];

        Test.startTest();

        System.runAs(collector) {
            ResponseDto dtoRps = clRedemptionController.retrieveRpsWrapper(rps.Id);
            System.assertEquals(dtoRps.isSuccess,true);
        }

        Test.stopTest();
    }

    @IsTest
    static void test_deleteDoc() {

        Map<String,Object> mUser = clTESTUTILS.getClUsers();
        User collector = (User)mUser.get(clTESTUTILS.COLLECTOR);
        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id FROM Route_Processing_Sheet__c
        ]);
        Map<Id,ContentDocumentLink> mDocLinks = new Map<Id,ContentDocumentLink>([
                SELECT   ContentDocumentId,LinkedEntityId
                FROM     ContentDocumentLink
                WHERE    LinkedEntityId IN :mAllRps.keySet()
                AND      LinkedEntity.Type = 'Route_Processing_Sheet__c'
        ]);

        ContentDocumentLink singleCdl = mDocLinks.values()[0];
        Test.startTest();

        System.runAs(collector) {
            ResponseDto dto = clRedemptionController.deleteDoc(singleCdl.ContentDocumentId, singleCdl.LinkedEntityId);
            System.assert(dto.isSuccess);
        }

        Test.stopTest();
    }

    private static List<Route_Processing_Sheet__c> findRpssWithFiles() {

        Map<Id,Route_Processing_Sheet__c> mAllRps = new Map<Id,Route_Processing_Sheet__c>([
           SELECT Id FROM Route_Processing_Sheet__c
        ]);
        Map<Id,ContentDocumentLink> mDocLinks = new Map<Id,ContentDocumentLink>([
           SELECT   ContentDocumentId,LinkedEntityId
           FROM     ContentDocumentLink
           WHERE    LinkedEntityId IN :mAllRps.keySet()
           AND      LinkedEntity.Type = 'Route_Processing_Sheet__c'
        ]);
        Set<Id> rpsIds = new Set<Id>();
        for(ContentDocumentLink cdl : mDocLinks.values()) {
            rpsIds.add(cdl.LinkedEntityId);
        }
        List<Route_Processing_Sheet__c> routeProcessingSheets = [
                SELECT Id, Name
                FROM   Route_Processing_Sheet__c
                WHERE  Id IN :rpsIds
        ];
        return routeProcessingSheets;
    }

}