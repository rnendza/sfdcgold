/**
 * @TODO Running without sharing for now as having issues with the Indirect Profile.
 * @TODO uncomment negative use cases (SFDC Bizarro world with modifying users / contacts in ut classes )
 */
public without sharing class Accel_CommunityInfoController {

    public static final String MAP_KEY_TERM_OF_USE_TEXT = 'TERMS_OF_USE_TEXT';
    public static final String MAP_KEY_PRIVACY_TEXT = 'PRIVACY_TEXT';
    public static final String MAP_KEY_CONTACT = 'CONTACT_SOBJECT';
    public static final String MAP_KEY_RELEASE_NOTES = 'RELEASE_NOTES';
    public static final String MAP_KEY_COMMUNITY_METADATA = 'COMMUNITY_METADATA';
    public static final String MAP_KEY_CURRENT_SESSION = 'CURRENT_SESSION';

    /**
     * Retrieves text from custom meta data. Community_Setting__mdt containing terms of use.
     * @return  a DTO containing containing the text / rich text.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveTermsOfUse() {
        ResponseDto dto = new ResponseDto();
        String settingName = 'Terms_of_Service', fieldName='Terms_of_Service_Text__c';
        Object o = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName,fieldName);
        String text = (String)o;

        dto.values.put(MAP_KEY_TERM_OF_USE_TEXT,text);
        dto.isSuccess = text!=null&& text!='';
        return dto;
    }
    /**
     * Retrieves privacy html from custom meta data. Community_Setting__mdt containing privacy info
     * @return  a DTO containing containing the text / rich text.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrievePrivacy() {
        ResponseDto dto = new ResponseDto();
        String settingName = 'Bottom_Nav_Bar', fieldName='Privacy_Text__c';
        Object o = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName,fieldName);
        String text = (String)o;

        dto.values.put(MAP_KEY_PRIVACY_TEXT,text);
        dto.isSuccess = text!=null&& text!='';
        return dto;
    }
    /**
     * Retrieves the Users Contact Record
     * @return a DTO containing the Contact SObject.
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveUserContact() {
        ResponseDto dto = new ResponseDto();
        Id runningUserId = UserInfo.getUserId();
        User User = [SELECT ContactId FROM USER WHERE id= :runningUserId];
        List<Contact> contacts = [ SELECT Id, Community_Terms_Accepted_Date__c FROM CONTACT WHERE Id = :user.ContactId];
        if(!contacts.isEmpty()) {
            Contact contact = contacts[0];
            dto.values.put(MAP_KEY_CONTACT,contact);
            dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Contact Not Found for userId: '+ UserInfo.getUserId();
            dto.severity = 'error';
            dto.message = dto.technicalMsg;
            dto.title = 'error';
            dto.isSuccess = false;
        }
        ResponseDto dtoMeta = retrieveCommunityMetadata();
        if(dtoMeta.isSuccess) {
            dto.values.put(MAP_KEY_COMMUNITY_METADATA,(Community_Setting__mdt)dtoMeta.values.get(MAP_KEY_COMMUNITY_METADATA));
        }
        if(!Test.isRunningTest()) {  //  This is lame but SFDC Will blow up in a Test Context if we call this.
            dto.values.put(MAP_KEY_CURRENT_SESSION, Auth.SessionManagement.getCurrentSession());
        }
        return dto;
    }
    /**
     * Updates the users Contact.Community_Terms_Accepted_Date__c field.
     * @param accept  If true, set the date on Contact.Community_Terms_Accepted_Date__c, otherwise null it out.
     * @return a DTO containing a Contact SObject if successful, otherwise containing the error message.
     */
    @AuraEnabled
    public static ResponseDto updateContactTermsAcceptance( Boolean accept ) {
        ResponseDto dto = new ResponseDto();
        Id runningUserId = UserInfo.getUserId();
        User User = [SELECT ContactId FROM USER WHERE id= :runningUserId];
        List<Contact> contacts = [ SELECT Id, Community_Terms_Accepted_Date__c FROM CONTACT WHERE Id = :user.ContactId];
        if(!contacts.isEmpty()) {
            Contact contact = contacts[0];
            if(accept) {
              contact.Community_Terms_Accepted_Date__c = System.now();
            } else {
              contact.Community_Terms_Accepted_Date__c = null;
            }
            try {
                update contact;
                dto.isSuccess = true;
                String termsLabel = 'Terms of Service accepted on ';
                if(accept) {
                    dto.message = termsLabel += contact.Community_Terms_Accepted_Date__c.format();
                }
                dto.severity = 'success';
                dto.title = 'success';
                dto.values.put(MAP_KEY_CONTACT,contact);
            } catch (Exception e) {
                dto.message = 'contact='+contact.id + e.getMessage();
                dto.severity = 'error';
                dto.title = 'error';
                System.debug(LoggingLevel.ERROR,e);
            }
        } else {
            dto.technicalMsg = 'Contact Not Found for userId: '+ UserInfo.getUserId();
            dto.severity = 'error';
            dto.message = dto.technicalMsg;
            dto.title = 'error';
        }
        return dto;
    }
    @AuraEnabled
    public static ResponseDto retrieveCommunityMetadata() {
        ResponseDto dto = new ResponseDto();
        dto.values.put(MAP_KEY_COMMUNITY_METADATA, CustomMetadataSvc.retrieveCustomSearchMeta(Community_Setting__mdt.getSObjectType(), 'Bottom_Nav_Bar'));
        dto.isSuccess = true;
        return dto;
    }
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveCommunityReleaseNotes() {
        ResponseDto dto = new ResponseDto();
        List<Community_Release_Note__c> notes = retrieveCommunityReleaseNotes(true);
        dto.values.put(MAP_KEY_RELEASE_NOTES,notes);
        if(!notes.isEmpty()) {
            dto.isSuccess = true;}
        return dto;
    }

    public static List<Community_Release_Note__c> retrieveCommunityReleaseNotes(Boolean activeOnly) {
        List<Community_Release_Note__c> notes;
        DescribeSObjectResult describeResult = Community_Release_Note__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String q = 'SELECT '+String.join(fieldNames,',')+' FROM  '+describeResult.getName() +' WHERE active__c = :activeOnly ORDER By Change_Date__c DESC ';
        notes = DataBase.query(q);
        return notes;
    }
}