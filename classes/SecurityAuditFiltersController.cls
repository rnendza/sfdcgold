public with sharing class SecurityAuditFiltersController {

    public final static String MAP_KEY_PROFILES      = 'MAP_KEY_PROFILE_DATA';
    public final static String MAP_KEY_PERMSETS      = 'MAP_KEY_PERMSET_DATA';
    public final static String MAP_KEY_SOBJECTS      = 'MAP_KEY_SOBJECT_DATA';

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllProfiles() {
        ResponseDto dto = new ResponseDto();

        Map<Id,Profile> m = SecuritySvc.retrieveAllProfiles();
        m.values().sort();
        dto.isSuccess = !m.isEmpty();
        dto.values.put(MAP_KEY_PROFILES,m.values());

        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllPermissionSets() {
        ResponseDto dto = new ResponseDto();

        Map<Id,PermissionSet> m = SecuritySvc.retrieveAllPermissionSets(true,false);
        m.values().sort();
        dto.isSuccess = !m.isEmpty();
        dto.values.put(MAP_KEY_PERMSETS,m.values());

        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllSObjects() {
        ResponseDto dto = new ResponseDto();
        List<SObjectData> sObjectDatas = new List<SObjectData>();

        Map<String,String> m = FieldSetSvc.retrieveAllSObjects();
        m.values().sort();
        dto.isSuccess = !m.isEmpty();
        if(!m.isEmpty()) {
            for(String apiName : m.keySet()) {
                SObjectData sObjectData = new SObjectData();
                sObjectData.apiName = apiName;
                sObjectData.label = m.get(apiName);
                sObjectDatas.add(sObjectData);
            }
        }
        dto.values.put(MAP_KEY_SOBJECTS,sObjectDatas);

        return dto;
    }

    public class SObjectData{
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
    }
}