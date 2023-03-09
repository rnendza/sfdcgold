@IsTest
private class FileUploadSvcTest {

    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }

    @IsTest
    static void test_saveTheChunkFile() {

        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Total_Meter_Readings__c > 0 LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Name FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
        String contentType = 'png';
        Blob blobImg = Blob.valueOf('A pretty picture');
        String base64Data = EncodingUtil.base64Encode(blobImg);

        Test.startTest();
        Id fileId = null;
        for(Meter_Reading__c meterReading : meterReadings) {
            fileId = FileUploadSvc.saveTheChunkFile(meterReading.Id,meterReading.Name,base64Data,contentType,fileId,null);
        }
        List<Meter_Reading__c> processedMeterReadings = [
                SELECT Id, Snapshot__c
                FROM   Meter_Reading__c
                WHERE   Id in :meterReadings
        ];
        for(Meter_Reading__c tmpMr : processedMeterReadings) {
            System.debug('---> processed mr= '+tmpMr);
        }


        Test.stopTest();
    }

    @IsTest
    static void test_saveRpsImage() {

        Route_Processing_Sheet__c rps = [SELECT Id,Name FROM Route_Processing_Sheet__c WHERE Total_Meter_Readings__c > 0 LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Name FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
        String contentType = 'png';
        Blob blobImgCassette = Blob.valueOf('A pretty picture cassette');
        String base64DataCassette = EncodingUtil.base64Encode(blobImgCassette);
        Blob blobImgNewCassette = Blob.valueOf('A pretty picture new cassette');
        String base64DataNewCassette = EncodingUtil.base64Encode(blobImgNewCassette);

        Test.startTest();
        Id fileIdCassette = null;
        Id fileIdNewCassette = null;
        fileIdCassette = FileUploadSvc.saveTheChunkFile(rps.Id,rps.Name,base64DataCassette,contentType,fileIdCassette,'Current Cassette');
        fileIdNewCassette = FileUploadSvc.saveTheChunkFile(rps.Id,rps.Name,base64DataNewCassette,contentType,fileIdNewCassette,'New Cassette');

        rps = clRouteProcessingSheetSvc.retrieveRouteProcessingSheet(rps.Id);
        System.assert(rps.Snapshot_New_Cassette__c != null);
        System.assert(rps.Snapshot_Cassette__c != null);

        Test.stopTest();
    }

    @IsTest
    static void test_deleteDoc() {

        Route_Processing_Sheet__c rps = [SELECT Id FROM Route_Processing_Sheet__c WHERE Total_Meter_Readings__c > 0 LIMIT 1];
        List<Meter_Reading__c> meterReadings = [SELECT Id, Name FROM Meter_Reading__c WHERE Route_Processing_Sheet__c = :rps.Id];
        String contentType = 'png';
        Blob blobImg = Blob.valueOf('A pretty picture');
        String base64Data = EncodingUtil.base64Encode(blobImg);

        Set<Id> cvIds = new Set<Id>();
        for(Meter_Reading__c meterReading : meterReadings) {
            cvIds.add(FileUploadSvc.saveTheChunkFile(meterReading.Id,meterReading.Name,base64Data,contentType,null,null));
        }

        ContentDocumentLink cdl = [
                SELECT Id,LinkedEntityId,ContentDocumentId
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :meterReadings[0].Id
                LIMIT 1
        ];

        Test.startTest();
        ResponseDto dto = FileUploadSvc.deleteDoc(cdl.ContentDocumentId, cdl.LinkedEntityId);
        System.assert(dto.isSuccess);
        dto = FileUploadSvc.deleteDoc(null, cdl.LinkedEntityId);
        System.assert(!dto.isSuccess);
        Test.stopTest();
    }

}