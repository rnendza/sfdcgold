public with sharing class FieldHistoryFiltersController {

    public final static String MAP_KEY_SOBJECTS      = 'MAP_KEY_SOBJECT_DATA';
    public final static String MAP_KEY_FIELDS        = 'MAP_KEY_FIELD_DATA';

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveFilteredSObjects(List<String> historyObjects) {
        ResponseDto dto = new ResponseDto();
        List<SObjectData> sObjectDatas = new List<SObjectData>();

        Map<String,String> m = FieldSetSvc.retrieveHistorySObjects(historyObjects);
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


    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveHistorySObjects(String objectType) {
        ResponseDto dto = new ResponseDto();
        List<SObjectData> sObjectDatas = new List<SObjectData>();

        Map<String,String> m = FieldSetSvc.retrieveHistorySObjects(objectType);
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
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllFieldsTracked( String sObjectApiName) {
        ResponseDto dto = new ResponseDto();
        List<FieldData> fieldDatas = new List<FieldData>();

        Set<String> setSObjectApiNames = new Set<String>{sObjectApiName};
        Map<String,Map<String,FieldDefinition>> mSObjects = FieldSetSvc.retrieveTrackedFieldDefinitions(setSObjectApiNames);
        if(!mSObjects.isEmpty()) {
            Map<String, FieldDefinition> mFields = mSObjects.get(sObjectApiName);
            for(String fieldApiName : mFields.keySet()) {
                FieldDefinition fd = mFields.get(fieldApiName);
                FieldData fieldData = new FieldData(fd);
                fieldDatas.add(fieldData);
            }
        }
        dto.isSuccess = !fieldDatas.isEmpty();
        dto.values.put(MAP_KEY_FIELDS,fieldDatas);

        return dto;
    }

    public class SObjectData{
        @AuraEnabled public String apiName;
        @AuraEnabled public String label;
    }

    public class FieldData{
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldApiName;

        @AuraEnabled public FieldDefinition fieldDefinition;
        public FieldData( FieldDefinition fd) {
            this.fieldDefinition = fd;
            this.fieldLabel = fd.Label;
            this.fieldApiName = fd.QualifiedApiName;
        }
    }
}