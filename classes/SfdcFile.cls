/**
 * a BASE class common to any sfdc file.
 */
public virtual class SfdcFile {

    @AuraEnabled public String title;
    @AuraEnabled public String size;
    @AuraEnabled public String previewUrl;
    @AuraEnabled public String downloadUrl;
    @AuraEnabled public String contentVersionId;
    @AuraEnabled public String contentDocumentId;

}