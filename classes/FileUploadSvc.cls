public with sharing class FileUploadSvc {

    @AuraEnabled
    public static Id saveTheChunkFile(Id parentId, String fileName, String base64Data, String contentType, String fileId,
                                     String redemptionImageType){

        base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        if ( String.isBlank(fileId) ) {
            fileId = saveFiles(parentId, fileName, base64Data, redemptionImageType );
        } else {
            appendToFile(fileId, base64Data);
        }

        return Id.valueOf(fileId);
    }

    @AuraEnabled
    public static Id saveFiles(Id recordId, String fileName, String base64Data, String redemptionImageType )  {

        ContentVersion contentVersion =new ContentVersion();
        contentVersion.Title =fileName;
        contentVersion.VersionData=EncodingUtil.base64Decode(base64Data);
        contentVersion.PathOnClient='/' + fileName ;
        contentVersion.IsMajorVersion = false;
        contentVersion.Cash_Logistics_Meter_Reading__c = true;
        if(redemptionImageType != null && redemptionImageType != '') {
            contentVersion.Redemption_Image_Type__c = redemptionImageType;
        }
        //contentVersion.FileExtension
        insert contentVersion;

        contentVersion = [
                select  id, ContentDocumentId,Title,ContentUrl,Redemption_Image_Type__c
                from    ContentVersion
                WHERE   Id =: contentVersion.Id
        ];

        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentVersion.ContentDocumentId;
        cl.LinkedEntityId = recordId;
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;


        ContentDistribution cd = new ContentDistribution();
        cd.ContentVersionId = contentVersion.Id;
        cd.Name = contentVersion.Title;
        cd.PreferencesAllowOriginalDownload = true;
        cd.PreferencesLinkLatestVersion = true;
        cd.PreferencesAllowViewInBrowser = true;
        cd.PreferencesNotifyOnVisit = false;
        cd.RelatedRecordId = recordId;
        insert cd;

        cd = [SELECT Id, DistributionPublicUrl, ContentDocumentId FROM ContentDistribution WHERE id = :cd.Id];

        if(recordId != null) {
            String sObjectApiName = recordId.getSobjectType().getDescribe().getName();
            if(sObjectApiName == 'Meter_Reading__c') {
                Meter_Reading__c mr = clMeterSvc.retrieveSingleMeterReading(recordId);
                if(mr != null) {
                    mr.Snapshot__c = '/lightning/r/ContentDocument/'+cd.ContentDocumentId+'/view';
                    update mr;
                }
            } else if(sObjectApiName == 'Route_Processing_Sheet__c') {
                Route_Processing_Sheet__c rps = retrieveRps(recordId);
                if(contentVersion.Redemption_Image_Type__c != null && contentVersion.Redemption_Image_Type__c.contains('Current')) {
                    rps.Snapshot_Cassette__c = '/lightning/r/ContentDocument/'+cd.ContentDocumentId+'/view';
                } else if (contentVersion.Redemption_Image_Type__c != null && contentVersion.Redemption_Image_Type__c.contains('New')) {
                    rps.Snapshot_New_Cassette__c = '/lightning/r/ContentDocument/'+cd.ContentDocumentId+'/view';
                }
                update rps;
            }
        }
        return contentVersion.Id;
    }

    /**
     * @param rpsId     The Route_Processing_Sheet__c.Id
     * @return          The Route_Processing_Sheet__c
     */
    @TestVisible
    private static Route_Processing_Sheet__c retrieveRps(Id rpsId) {
        Route_Processing_Sheet__c rps;

        List<Route_Processing_Sheet__c> rpss = [
                SELECT Id,Snapshot_Cassette__c,Snapshot_New_Cassette__c
                FROM   Route_Processing_Sheet__c
                WHERE  Id = :rpsId
        ];
        rps = !rpss.isEmpty() ? rpss[0] : rps;
        return rps;
    }



    @AuraEnabled
    public static void appendToFile(Id contentDocumentId, String base64Data) {
        //base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        ContentVersion versionData = [
                SELECT Id, VersionData,ContentDocumentId
                FROM ContentVersion
                WHERE Id = :contentDocumentId
        ];

        String existingBody     = EncodingUtil.base64Encode(versionData.VersionData);
        versionData.VersionData = EncodingUtil.base64Decode(existingBody + base64Data);

        update versionData;
    }


    @AuraEnabled
    public static ResponseDto deleteDoc(Id docId, Id parentRecordId) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'doc id attempted to delete: '+docId + ' for parentRecordId='+parentRecordId;
        try {
            ContentDocument deletedDoc = ContentManagerSvc.deleteDocument(docId);
            if(parentRecordId != null  && parentRecordId.getSobjectType() == Meter_Reading__c.getSObjectType()) {
                Meter_Reading__c mr = [SELECT Id, Reading_Status__c,Snapshot_Count__c FROM Meter_Reading__c WHERE Id = :parentRecordId];
                if (mr.Snapshot_Count__c != null && mr.Snapshot_Count__c > 0) {
                    mr.Snapshot_Count__c--;
                }
                // Removed 02/16/2022
                // mr.Reading_Status__c = 'In Progress';
                update mr;
            }
            dto.message = 'Document successfully deleted';
            dto.isSuccess = true;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
            dto.message = e.getMessage();
            dto.technicalMsg += 'error on delete ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
        }
        return dto;
    }
}