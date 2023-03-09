public without sharing class CommunityUserSettingsSvc {

    public static final String MAP_KEY_SOBJECT              =   'COMMUNITY_USER_SETTING_SOBJECT';
    public static final String MAP_KEY_SETTINGS_FIELDS      =   'COMMUNITY_USER_SETTINGS_FIELDS';

   /**
    * @return a normal Community_User_Setting__c sObject with Id,Name and fields that are part of Any
    * Community_User_Setting Field Set;
    */
    public static Community_User_Setting__c retrieveCommunityUserSettings() {
        Map<String,Object> mKey_Obj = retrieveCommunitySettingsMap();
        return  (Community_User_Setting__c)mKey_Obj.get(MAP_KEY_SOBJECT);
    }
   /**
    * Just rips all field sets on Community_User_Setting__c and returns all fields within them.
    * @return a map of ''COMMUNITY_USER_SETTING_SOBJECT' => Contact  and 'COMMUNITY_USER_SETTING_FIELDS' => Set<String>
    */
    public static Map<String,Object> retrieveCommunitySettingsMap() {
        Map<String,FieldSet> mFieldSets = SObjectType.Community_User_Setting__c.fieldSets.getMap();
        return retrieveCommunitySettingsMap(mFieldSets);
    }
   /**
    *
    * @param communityUserSettings a Community_User_Setting__c sObject.
    * @throws InvalidUpdateParamsException
    * @throws DmlException.
    */
    public static void updateCommunityUserSettings(Community_User_Setting__c communityUserSettings) {
        Warnings.checkObjectUpdateValidity(communityUserSettings);
        update communityUserSettings;
    }
   /**
    *
    * @param mFieldSets   The particular FieldsSets on Contact you want settings for.
    * @return a map of ''COMMUNITY_USER_SETTING_SOBJECT' => Contact  and 'COMMUNITY_USER_SETTING_FIELDS' => Set<String>
    */
    public static Map<String,Object> retrieveCommunitySettingsMap(Map<String,FieldSet> mFieldSets) {
        Map<String,Object> mKey_Object = new Map<String,Object>();
        Community_User_Setting__c communityUserSetting;
        Id userId = UserInfo.getUserId();
        Id contactId = UserSvc.retrieveUserContactId(userId);
        Set<String> selectFields = getAllFieldSetsFields(mFieldSets);
        selectFields.add('User__c');selectFields.add('Contact__c');
        if(selectFields != null && !selectFields.isEmpty()) {
            communityUserSetting = (Community_User_Setting__c)retrieveSObjectDynamic(   Community_User_Setting__c.getSObjectType(),selectFields,
                                                                                        userId, contactId);
        }
        mKey_Object.put(MAP_KEY_SETTINGS_FIELDS,selectFields);
        mKey_Object.put(MAP_KEY_SOBJECT,communityUserSetting);
        return mKey_Object;
    }
   /**
    *
    *
    * @param mFieldSets
    * @return
    */
    public static Set<String> getAllFieldSetsFields(Map<String,FieldSet> mFieldSets) {
        Set<String> fields = new Set<String>();

        if(mFieldSets != null) {
            for(String key : mFieldSets.keySet()) {
                FieldSet fs = mFieldSets.get(key);
                for(Schema.FieldSetMember fsm : fs.getFields()){
                    fields.add(fsm.getFieldPath());
                }
            }
        }
        return fields;
    }
    /**
     *
     * @param sObjectType       The type of sObject.
     * @param selectFields      The additional fields to add to the select besides Id,Name
     * @param userId            The userId to filter.
     * @param contactId         The contactId to filter.
     *
     * @return  A single sObject that was found, otherwise null.
     */
    public static SObject retrieveSObjectDynamic(   SObjectType sObjectType, Set<String> selectFields,
                                                    Id userId, Id contactId) {
        Warnings.checkForValidCommunityUser(contactId,userId);
        Warnings.checkCommunityUserSettingsParams(contactId, userId,selectFields);

        String soql = '';
        List<String> lSelectFields = new List<String>();
        lSelectFields.addAll(selectFields);
        String soqlFields = String.join(lSelectFields, ',');
        String sObjectName = sObjectType.getDescribe().getName();
        System.debug('looking for user__c='+userId + '... and contact__c='+contactId+'.. in '+sObjectName);

        soql += ' SELECT Id, Name, ' + soqlFields;
        soql += ' FROM   '+sObjectName;
        soql += ' WHERE  Contact__c = :contactId ';
        soql += ' AND    User__c = :userId';
        soql += ' ORDER BY CreatedDate DESC ';

        List<SObject> sObjs = Database.query(soql);
        SObject SObj;
        /**
         * It's possible that dup records will be created with the same userId and contactId record.
         * If so.. warn. and return the last one. .ie we are not doing to hard DUP block on the sObject yet.
         */
        if(!sObjs.isEmpty()) {
            if(sObjs.size() > 1) {
                //  @todo log entry into community errors sObject.
                String msg = 'There are duplicate Community_User_Profile__c entries for User__c:'+userId +
                        '..Contact__c:'+contactId +'... pulling the most recently created one.';
                System.debug(LoggingLevel.ERROR, msg);
            }
            sObj = sObjs[sObjs.size()-1];
        }
        return sObj;
    }
    /**
     * Inserts a Community_User_Setting__c sObject.
     *
     * @param users            Minimally must have Id and ContactId populated.
     * @param defaultSetting   Default for the settings [True,False].
     *
     * @return an inserted Community_User_Setting__c sObject.
     */
    public static List<Community_User_Setting__c> createCommunityUserSettings(Set<User> users, Boolean defaultSetting) {
        //@TODO Check incoming params.
        List<Community_User_Setting__c> communityUserSettings = new List<Community_User_Setting__c>();
        for(User user : users) {
            communityUserSettings.add( buildCommunityUserDisplaySetting( user,user.ContactId,defaultSetting) );
        }
        insert communityUserSettings;
        return communityUserSettings;
    }

    /**
     * Builds a community_user_setting__c sObject using userId,contactId as the key and populates
     * all field names that have 'display' in the api name that exist on the field sets with true.
     *
     * @param  userId The Id of the user for the lookup.
     * @param  ContactId  The contact Id of the user for the lookup.
     * @param  defaultSetting   Default for the settings [True,False].
     * @return a Community_User_Setting__c sObject (not inserted / no id)
     */
    public static Community_User_Setting__c buildCommunityUserDisplaySetting(User user, Id contactId, Boolean defaultSetting) {

        Map<String,FieldSet> mFieldSets = SObjectType.Community_User_Setting__c.fieldSets.getMap();
        Set<String> allFsFields =  CommunityUserSettingsSvc.getAllFieldSetsFields(mFieldSets);
        Community_User_Setting__c cus = new Community_User_Setting__c();
        Contact contact  = [SELECT Id, Name FROM Contact WHERE Id = :contactId];

        cus.put('Name', contact.Name + ' Setting');
        cus.put('User__c',user.Id);
        cus.put( 'Contact__c',contactId);

        for(String field : allFsFields) {
            if(field.contains('Display') && !field.equalsIgnoreCase('Display_Location_Address__c')) {
                cus.put(field,defaultSetting);
            } else if (field.equalsIgnoreCase('Display_Location_Address__c')) {
                cus.put(field,false);
            }
        }
        return cus;
    }
}