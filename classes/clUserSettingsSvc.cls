public with sharing class clUserSettingsSvc {

    public static CL_User_Setting__c retrieveSetting(Id userId) {
        CL_User_Setting__c setting;
        List<CL_User_Setting__c> settings = retrieveSettings( new Set<Id> {userId});
        if(!settings.isEmpty()) {
            setting = settings[0];
        }
        return setting;
    }

    public static List<CL_User_Setting__c> retrieveSettings(Set<Id> userIds) {

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   CL_User_Setting__c ';
        q += 'WHERE  User__c IN :userIds ';
        String formattedQuery = String.format(q,getAllUserSettingsFields());

        List<CL_User_Setting__c> settings = Database.query(formattedQuery);
        return settings;
    }

    /**
     * @return Get all fields (doesn't span relationships)
     */
    @TestVisible
    private static List<String>  getAllUserSettingsFields() {
        Map<String, Schema.SObjectField> fieldsMap = CL_User_Setting__c.sObjectType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }
}