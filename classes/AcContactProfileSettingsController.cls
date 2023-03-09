global without sharing class AcContactProfileSettingsController {

    public static final String          COMMUNITY_USER_PROFILE_SETTINGS         = 'COMMUNITY_USER_PROFILE_SETTINGS';
    public static final String          COMMUNITY_USER_DISPLAY_SETTINGS         = 'COMMUNITY_USER_DISPLAY_SETTINGS';
    public static Map<String,Object>    mFieldApiName_Value                     = new Map<String,Object>();

    /**
     * Retrieves... xx @TODO DOC
     *
     * @TODO call overload of retrieveContactControlledCommunitySettingsMap with only community field sets.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveCommunityUserSettings() {
        ResponseDto dto = new ResponseDto();

        Map<String, Object> mKey_Object = CommunityUserSettingsSvc.retrieveCommunitySettingsMap();
        Community_User_Setting__c communityUserSetting = (Community_User_Setting__c) mKey_Object
                .get(CommunityUserSettingsSvc.MAP_KEY_SOBJECT);

        if (communityUserSetting != null) {
            Set<String> selectFields = (Set<String>) mKey_Object.get(CommunityUserSettingsSvc.MAP_KEY_SETTINGS_FIELDS);
            for (String fieldApiName : selectFields) {
                mFieldApiName_Value.put(fieldApiName, communityUserSetting.get(fieldApiName));
            }
            List<SettingsDisplayWrapper> settingsDisplayWrappers = buildSettingDisplayWrappers();
            dto.values.put(COMMUNITY_USER_PROFILE_SETTINGS, communityUserSetting);
            dto.values.put(COMMUNITY_USER_DISPLAY_SETTINGS, settingsDisplayWrappers);dto.isSuccess = true;
        } else {
            dto.technicalMsg = 'Could not find Community_User_Settings__c';
            dto.message = 'Unable to find your community setting values.  We are looking into it!';
        }
        return dto;
    }
    /**
     * @return
     */
    private static List<SettingsDisplayWrapper> buildSettingDisplayWrappers() {
        List<SettingsDisplayWrapper> settingsDisplayWrappers = new List<SettingsDisplayWrapper>();
        if(SObjectType.Community_User_Setting__c.fieldSets != null) {
            Map<String,FieldSet> mFieldSet = SObjectType.Community_User_Setting__c.fieldSets.getMap();
            for(String key : mFieldSet.keySet()) {
                FieldSet fs = mFieldSet.get(key);
                if (fs.getFields().isEmpty()) {
                    continue; //  FieldSet has Zero fields .. Trash it!
                } else {
                    settingsDisplayWrappers.add(new SettingsDisplayWrapper(fs));
                }
            }
            settingsDisplayWrappers.sort();
        }
        return settingsDisplayWrappers;
    }
    /**
     *
     */
    public class SettingsDisplayWrapper implements Comparable {
        @AuraEnabled public     String fieldSetName                         { get; set; }
        @AuraEnabled public     String fieldSetLabel                        { get; set; }
                     private    String fieldSetDesc                         { get; set; }
        @AuraEnabled public     Integer fieldSetSortOrder                   { get; set; }
        @AuraEnabled public     String  fieldSetIconName                    { get; set; }
        @AuraEnabled public     Boolean displayFieldSetIcon                 { get; set; }
        @AuraEnabled public     List<SettingFieldWrapper> fieldWrappers     { get; set; }

        public SettingsDisplayWrapper(Schema.FieldSet fs) {
            this.fieldSetName = fs.getName();
            this.fieldSetLabel = fs.getLabel();
            this.fieldSetDesc = fs.getDescription();
            this.fieldSetSortOrder = this.getSortOrder(this.fieldSetDesc);
            this.fieldSetIconName = this.getFieldSetIconName(this.fieldSetDesc);
            this.displayFieldSetIcon = this.fieldSetIconName !=null && this.fieldSetIconName != '' ? true : false;
            this.fieldWrappers = new List<SettingFieldWrapper>();
            for (Schema.FieldSetMember fsm : fs.getFields()) {
                this.fieldWrappers.add(new SettingFieldWrapper(fsm));
            }
        }
        /**
         * Basically searches for SORT[i] in the field set description and then uses that to Sort the Field
         * Sets on the community page.
         *
         * @param fieldSetDesc
         * @return an Integer value to sort by if found, otherwise zero.
         * @TODO Replace with Real RegEx
         */
        @TestVisible
        private Integer getSortOrder(String fieldSetDesc) {
            Integer iSortOrder = 0;
            if(fieldSetDesc!=null && fieldSetDesc.containsIgnoreCase('SORT')) {
                Integer startIdx =  fieldSetDesc.indexOf('[',fieldSetDesc.indexOf('SORT'));
                startIdx = startIdx + 1;
                Integer endIdx =  fieldSetDesc.indexOf(']',startIdx);
                String sSort = '0';

                if(endIdx > startIdx && endIdx < fieldSetDesc.length()) {
                    sSort = fieldSetDesc.substring(startIdx, endIdx);
                    if (sSort.isNumeric()) {
                        iSortOrder = Integer.valueOf(sSort);
                    }
                }
            }
            return iSortOrder;
        }
        /**
         *S
         *
         * @param fieldSetDesc
         * @return the iconName if one can be parsed.
         */
        @TestVisible
        private String getFieldSetIconName(String fieldSetDesc) {
            String iconName;
            if(fieldSetDesc!=null && fieldSetDesc.containsIgnoreCase('ICON')) {
                Integer startIdx =  fieldSetDesc.lastIndexOfIgnoreCase('ICON (');
                startIdx = startIdx + 6;
                Integer endIdx =  fieldSetDesc.indexOf(')',startIdx);
                if(endIdx > startIdx && endIdx < fieldSetDesc.length()) {
                    iconName = fieldSetDesc.substring(startIdx, endIdx);
                    if(iconName != null) {
                        if(!iconName.contains(':')) {
                            iconName = '';
                        }
                    }
                }
            }
            return iconName;
        }
        /**
         *
         * @param objToCompare
         * @return
         */
        public Integer compareTo(Object objToCompare) {
            SettingsDisplayWrapper compareToWrap = (SettingsDisplayWrapper)objToCompare;
            if(fieldSetSortOrder == compareToWrap.fieldSetSortOrder) return 0;
            if(fieldSetSortOrder > compareToWrap.fieldSetSortOrder) return 1;
            return -1;
        }
    }
    public class SettingFieldWrapper {
        @AuraEnabled public String  fieldLabel    {get;set;}
        @AuraEnabled public String  fieldHelp     {get;set;}
        @AuraEnabled public String  msgToggleActive {get;set;}
        @AuraEnabled public String  msgToggleInactive {get;set;}
        @AuraEnabled public String  fieldApiName  {get;set;}
        @AuraEnabled public Object  fieldValue    {get;set;}
        @AuraEnabled public Boolean fieldRequired {get;set;}
        @AuraEnabled public Boolean dbRequired    {get;set;}
        @AuraEnabled public Boolean displayFieldHelp {get;set;}

        public SettingFieldWrapper(Schema.FieldSetMember fsm) {
            this.fieldApiName = fsm.getFieldPath();
            this.fieldLabel = fsm.getSObjectField().getDescribe().getLabel();
            this.fieldHelp = fsm.getSObjectField().getDescribe().getInlineHelpText();
            this.displayFieldHelp = this.fieldHelp != null && this.fieldHelp != '' ? true : false;
            this.fieldRequired = fsm.getRequired();
            this.dbRequired    = fsm.getDbRequired();
            this.fieldValue = mFieldApiName_Value.get(fieldApiName);
            this.setMessageToggleDisplayValues(this.fieldApiName);
        }
        /**
         * This is not the preferred way buy SFDC gives us nowwhere on the field itself to store this info so we must
         * cheat as there is no other fast way to grab this!
         *
         * @param fsm
         * @TODO replace with labels / Custom meta.
         */
        public void setMessageToggleDisplayValues(String fieldApiName) {
            if(fieldApiName == 'Display_Location_Address__c') {
                this.msgToggleActive = 'Address';
                this.msgToggleInactive = 'DBA Name';
            } else {
                this.msgToggleActive ='Display';
                this.msgToggleInactive = 'Hide';
            }
        }
    }
    /**
     *
     * @param communityUserSetting a Community_User_Setting__c sObject.
     * @return A dto containing info about the status of the update.
     */
    @AuraEnabled
    public static ResponseDto updateCommunityUserSettings( Community_User_Setting__c communityUserSetting ) {
        ResponseDto dto = new ResponseDto();
        try {
           CommunityUserSettingsSvc.updateCommunityUserSettings(communityUserSetting);
            dto.isSuccess = true;
        } catch (Warnings.InvalidUpdateParamsException invalidUpdateParamsException ) {
            dto.technicalMsg = 'params communityUserSetting='+communityUserSetting+ '.....'+invalidUpdateParamsException.getMessage();
        } catch (Exception ex) {
            dto.technicalMsg = ex.getMessage() + ex.getCause() + ex.getTypeName() + ex.getStackTraceString();
        }
        return dto;
    }
}