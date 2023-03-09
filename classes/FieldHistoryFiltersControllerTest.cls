@IsTest
private class FieldHistoryFiltersControllerTest {

    @IsTest
    static void test_retrieveAllProfiles() {

        Test.startTest();
        String objType = 'custom';
        ResponseDto dto = FieldHistoryFiltersController.retrieveHistorySObjects(objType);

        objType = 'standard';
        dto = FieldHistoryFiltersController.retrieveHistorySObjects(objType);

        objType = null;
        dto = FieldHistoryFiltersController.retrieveHistorySObjects(objType);

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveAllFieldsTracked() {

        String objType = 'standard';
        ResponseDto dto = FieldHistoryFiltersController.retrieveHistorySObjects(objType);
        List<FieldHistoryFiltersController.SObjectData> l = (List<FieldHistoryFiltersController.SObjectData>)dto.values.get(FieldHistoryFiltersController.MAP_KEY_SOBJECTS);
        FieldHistoryFiltersController.SObjectData sObjectData = l[0];

        Test.startTest();

        FieldHistoryFiltersController.retrieveAllFieldsTracked(sObjectData.apiName.replace('History',''));

        Test.stopTest();
    }

    @IsTest
    static void test_retrieveFilteredHistoryObjects() {

        List<String> filtredHistoryObjects;
        SObject sobj = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Security_Audit_Setting__mdt.getSObjectType(),clFieldAuditController.MDT_DEV_NAME_CL_FIELD_HISTORY);
        Cash_Logistics_Security_Audit_Setting__mdt mdt = (Cash_Logistics_Security_Audit_Setting__mdt) sobj;
        filtredHistoryObjects = mdt.Field_History_Objects__c.split(',');

        Test.startTest();

        ResponseDto dto = FieldHistoryFiltersController.retrieveFilteredSObjects(filtredHistoryObjects);
        List<FieldHistoryFiltersController.SObjectData> l = (List<FieldHistoryFiltersController.SObjectData>)dto.values.get(FieldHistoryFiltersController.MAP_KEY_SOBJECTS);
        FieldHistoryFiltersController.SObjectData sObjectData = l[0];

        Test.stopTest();
    }
}