public with sharing class clFieldAuditController {

    public final static String MAP_KEY_FIELD_HISTORY_DATA       = 'MAP_KEY_FIELD_HISTORY_DATA';
    public final static String MAP_KEY_FIELD_HISTORY_MDT        = 'MAP_KEY_FIELD_HISTORY_MDT';
    public final static String MDT_DEV_NAME_CL_FIELD_HISTORY    = 'CL_Field_History';

    @AuraEnabled
    public static ResponseDto retrieveFieldHistoryByParams( Datetime startDate, Datetime endDate,
                                                            String historyObj, List<String> historyFields) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += '---> params: startDate=' + startDate + '.. endDate=' + endDate + '.. historyObj=' + historyObj + ' .. historyFields=' + historyFields;

        Set<String> setHistoryFields = new Set<String>(historyFields);
        List<FieldSetSvc.FieldAuditInfo> fieldAuditInfos = FieldSetSvc.retrieveFieldHistory(historyObj,setHistoryFields,startDate,endDate);
        fieldAuditInfos = buildResponse(fieldAuditInfos,historyObj);
        dto.isSuccess = !fieldAuditInfos.isEmpty();
        dto.values.put(MAP_KEY_FIELD_HISTORY_DATA,fieldAuditInfos);
        return dto;
    }

    public static List<FieldSetSvc.FieldAuditInfo> buildResponse(List<FieldSetSvc.FieldAuditInfo> fieldAuditInfos,String historyObj) {
        List<FieldSetSvc.FieldAuditInfo> cleansedHistories = new List<FieldSetSvc.FieldAuditInfo>();
        System.debug('---> size:'+fieldAuditInfos.size());

        String targetObjApiName;
        if(historyObj.containsIgnoreCase('__History')) {
            targetObjApiName = historyObj.replace('__History','__c');
        } else {
            targetObjApiName = historyObj.replace('History','');
        }
        SObjectType sObjectType = FieldSetSvc.getSObjectType(targetObjApiName);
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();


        for(Integer i=0; i<fieldAuditInfos.size(); i++) {
            Integer nextIdx = i+1;
            FieldSetSvc.FieldAuditInfo fai = fieldAuditInfos[i];
            SObjectField field = fields.get(fai.fieldName);
            fai.fieldLabel = field.getDescribe().label;
            if(fai.oldValue  == null || fai.oldValue == '') {
                fai.oldValue = '[New Record]';
            }
            if(fai.DataType == 'DateTime') {
                fai.newValue = ((DateTime)fai.newValue).format('yyyy/MM/dd hh:mm:ss');
            }
            if(fai.DataType == 'Text' && nextIdx < fieldAuditInfos.size()) {
                FieldSetSvc.FieldAuditInfo faiNext = fieldAuditInfos[nextIdx];
                if (faiNext.DataType == 'EntityId') {
                    fai.isLookup = true;
                    i++; // Skip dup next row.
                }
            }
            cleansedHistories.add(fai);
        }
        return cleansedHistories;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveFieldHistoryMetadata(String mdtDevName) {
        ResponseDto dto = new ResponseDto();
        Cash_Logistics_Security_Audit_Setting__mdt mdt;
        SObject sobj = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Security_Audit_Setting__mdt.getSObjectType(),mdtDevName);
        dto.values.put(MAP_KEY_FIELD_HISTORY_MDT,sobj);
        return dto;
    }
}