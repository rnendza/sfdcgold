/**
 * Created by rnend on 5/24/2021.
 */

public with sharing class ContentManagerSvc {


    /**
     * Since Redemption Images have the same parentId we need to go after the Redemption_Image_Type__c
     * to key on the specific doc.
     *
     * @param docId   the ContentDocument.Id
     * @param rtType  The ContentVersion.Redemption_Terminal_Type__c
     *
     * @return        The Deleted Document.
     */
    public static ContentDocument deleteRtDocument(Id docId,String rtType) {
        ContentDocument deletedDoc;
        List<ContentDocument> docsToDel = [
                SELECT Id
                FROM   ContentDocument
                WHERE  Id = :docId
                AND    Id IN (
                        SELECT ContentDocumentId
                        FROM   ContentVersion
                        WHERE  Redemption_Image_Type__c = :rtType
                )
        ];
        if(!docsToDel.isEmpty()) {
            //@todo use Database.delete..
            delete docsToDel;
            deletedDoc = docsToDel[0];
        }
        return deletedDoc;
    }


    public static ContentDocument deleteDocument(Id docId) {
        ContentDocument deletedDoc;
        List<ContentDocument> deletedDocs = deleteDocuments(new Set<Id> {docID});
        deletedDoc = deletedDocs[0];
        return deletedDoc;
    }


    public static List<ContentDocument> deleteDocuments(Set<Id> ids) {
        List<ContentDocument> docsToDel = [
                SELECT Id,Title
                FROM   ContentDocument
                WHERE  Id IN :ids
        ];
        //@todo use Database.delete..
        delete docsToDel;
        return docsToDel;
    }


    public static Map<Id,ContentDocumentLink> retrieveContentDocLinks(Set<Id> parentIds, String parentType) {

        Map<Id,ContentDocumentLink> mDocLinks = new Map<Id,ContentDocumentLink>([
                SELECT Id, ContentDocumentId, LinkedEntityId,
                        LinkedEntity.Name
                FROM   ContentDocumentLink
                WHERE  LinkedEntityId IN :parentIds
                AND    LinkedEntity.Type = :parentType
        ]);
        return mDocLinks;
    }

    public static Map<Id,ContentVersion> retrieveContentVersionsByIds(Set<Id> contentVersionIds) {

        Map<Id,ContentVersion> mVersions = new Map<Id,ContentVersion>([
                SELECT  Id,FileType,Title,FileExtension,CreatedDate,CreatedBy.Name,
                        ContentDocumentId,VersionData,VersionNumber,
                        ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,ContentDocument.FileType,
                        ContentDocument.LastModifiedDate,LastModifiedDate,Redemption_Image_Type__c,CreatedById,
                        ContentDocument.ParentId,
                        Cash_Logistics_Upload_Type_fileupload__c
                FROM    ContentVersion
                WHERE   Id IN :contentVersionIds
        ]);
        return mVersions;
    }

    public static Map<Id,ContentVersion> retrieveContentVersionsByTitle(String title) {

        Map<Id,ContentVersion> mVersions = new Map<Id,ContentVersion>([
                SELECT  Id,FileType,Title,FileExtension,CreatedDate,CreatedBy.Name,
                        ContentDocumentId,VersionNumber,
                        ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,ContentDocument.FileType,
                        ContentDocument.LastModifiedDate,LastModifiedDate,Redemption_Image_Type__c,CreatedById,
                        ContentDocument.ParentId,CL_Upload_Status__c,
                        Cash_Logistics_Upload_Type_fileupload__c
                FROM    ContentVersion
                WHERE   Title = :title
                AND     IsLatest = TRUE
        ]);
        return mVersions;
    }

    public static ContentVersion retrieveContentVersionNoVersionData(Id contentDocId) {
        ContentVersion cv;

        Map<Id,ContentVersion> mVersions = new Map<Id,ContentVersion>([
                SELECT  Id,FileType,Title,FileExtension,CreatedDate,CreatedBy.Name,
                        ContentDocumentId,VersionNumber,
                        ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,ContentDocument.FileType,
                        ContentDocument.LastModifiedDate,LastModifiedDate,Redemption_Image_Type__c,CreatedById,
                        Cash_Logistics_Upload_Type_fileupload__c,CL_Upload_Status__c,
                        LastModifiedById,LastModifiedBy.Username,
                        ContentDocument.ParentId
                FROM    ContentVersion
                WHERE   ContentDocumentId = :contentDocId
        ]);
        if(!mVersions.isEmpty()) {
            cv = mVersions.values()[0];
        }
        return cv;
    }
    public static ContentVersion retrieveContentVersion(Id contentDocId) {
        ContentVersion cv;

        Map<Id,ContentVersion> m = retrieveContentVersions(new Set<Id> {contentDocId});
        if(!m.isEmpty()) {
            cv = m.values()[0];
        }
        return cv;
    }

    public static Map<Id,ContentVersion> retrieveContentVersions(Set<Id> contentDocumentIds) {

        Map<Id,ContentVersion> mVersions = new Map<Id,ContentVersion>([
                SELECT  Id,FileType,Title,FileExtension,CreatedDate,CreatedBy.Name,
                        ContentDocumentId,VersionData,VersionNumber,
                        ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,ContentDocument.FileType,
                        ContentDocument.LastModifiedDate,LastModifiedDate,Redemption_Image_Type__c,CreatedById,
                        Cash_Logistics_Upload_Type_fileupload__c,CL_Upload_Status__c,
                        LastModifiedById,LastModifiedBy.Username,
                        ContentDocument.ParentId
                FROM    ContentVersion
                WHERE   ContentDocumentId IN :contentDocumentIds
        ]);
        return mVersions;
    }
    /**
     * @param contentDocumentIds
     *
     * @return
     * @todo unit test
     */
    public static Map<Id,ContentVersion> retrieveContentVersionsNoVersionData(Set<Id> contentDocumentIds) {

        Map<Id,ContentVersion> mVersions = new Map<Id,ContentVersion>([
                SELECT  Id,FileType,Title,FileExtension,CreatedDate,CreatedBy.Name,
                        ContentDocumentId,VersionNumber,
                        ContentDocument.CreatedBy.Name, ContentDocument.ContentSize,ContentDocument.FileType,
                        ContentDocument.LastModifiedDate,LastModifiedDate,Redemption_Image_Type__c,CreatedById,
                        Cash_Logistics_Upload_Type_fileupload__c,CL_Upload_Status__c,
                        LastModifiedById,LastModifiedBy.Username,
                        ContentDocument.ParentId
                FROM    ContentVersion
                WHERE   ContentDocumentId IN :contentDocumentIds
        ]);
        return mVersions;
    }

    public static Map<Id,ContentVersion> retrieveContentVersions(Set<Id> parentIds,String parentType) {
        Map<Id,ContentDocumentLink> mDocLinks = retrieveContentDocLinks(parentIds,parentType);

        Set<Id> contentDocumentIds = new Set<Id>();
        for(ContentDocumentLink docLink : mDocLinks.values()) {
            contentDocumentIds.add(docLink.ContentDocumentId);
        }

        Map<Id,ContentVersion> mContentVersions = retrieveContentVersions( contentDocumentIds );
        return mContentVersions;
    }

    /**
     * @param parentIds
     * @param parentType
     *
     * @return
     * @todo unit test
     */
    public static Map<Id,ContentVersion> retrieveContentVersionsNoVersionData(Set<Id> parentIds,String parentType) {
        Map<Id,ContentDocumentLink> mDocLinks = retrieveContentDocLinks(parentIds,parentType);

        Set<Id> contentDocumentIds = new Set<Id>();
        for(ContentDocumentLink docLink : mDocLinks.values()) {
            contentDocumentIds.add(docLink.ContentDocumentId);
        }

        Map<Id,ContentVersion> mContentVersions = retrieveContentVersionsNoVersionData( contentDocumentIds );
        return mContentVersions;
    }

    /**
     * @param contentVersionIds A Set of Content Version Ids
     * @return A Map of ContentDistribution Id => ContentDistribution
     */
    public static Map<Id,ContentDistribution> retrieveContentDistributions(Set<Id> contentVersionIds) {

        Map<Id,ContentDistribution> mDistributions = new Map<Id,ContentDistribution>([
           SELECT Id,ContentVersionId,Name,ContentDownloadUrl,DistributionPublicUrl,ViewCount,
                   ContentVersion.Redemption_Image_Type__c
           FROM   ContentDistribution
           WHERE  ContentVersionId IN :contentVersionIds
        ]);

        return mDistributions;
    }

    public static String formatBytes(Double bytes,Integer decimals) {
        String displayValue = '';

        if(bytes == 0) return '0 Bytes';
        if(bytes < 1024) {
            displayValue =  bytes + ' Bytes';
        } else {
            if(bytes >= 1024 && bytes < (1024 *1024)) {
                //kb
                Decimal kb = Decimal.valueOf(bytes);
                kb = kb.divide(1024,decimals);
                displayValue = kb + ' Kb';
            } else {
                if(bytes >= (1024*1024) && bytes < (1024*1024*1024)) {
                    //MB
                    Decimal mb = Decimal.valueOf(bytes);
                    mb = mb.divide((1024*1024),1);
                    displayValue = mb + ' Mb';
                } else {
                    // should not get here!
                }
            }
        }
        return displayValue;
    }

//    public static string ContentType(String fileType) {
//
//        switch on fileType.toLowerCase(){
//            when 'docx' {
//                return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
//            }
//            when 'csv' {
//                return 'application/vnd.ms-excel';
//            }
//            when 'wav' {
//                return 'audio/wav';
//            }
//            when 'wmv' {
//                return 'video/x-ms-wmv';
//            }
//            when 'mp3' {
//                return 'audio/mpeg';
//            }
//            when 'mp4' {
//                return 'video/mp4';
//            }
//            when 'png' {
//                return 'image/png';
//
//            }
//            when 'pdf' {
//                return 'application/pdf';
//
//            }
//            when else {
//                return 'image/jpeg';
//            }
//        }
//
//    }
}