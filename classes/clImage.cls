/**
  * Inherits from the Base and adds redemption specific  / ui specific attributes.
  */
public class clImage extends SfdcFile {

    @AuraEnabled public String displayTitle;
    @AuraEnabled public Boolean showThumb = false;
    @AuraEnabled public Boolean showCamLauncher = true;
    @AuraEnabled public String  userName;
    @AuraEnabled public Datetime lastModifiedDate;
    @AuraEnabled public String  rtImageType;
    @AuraEnabled public Integer viewCount;

    public clImage() { }
}