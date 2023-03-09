@isTest
private with sharing class AccelEditorAccountLookupFieldPickerTest {

    @isTest
    static void test_getDefaultValue() {

        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Account';
        AccelEditorAccountLookupFieldPicker picker = new AccelEditorAccountLookupFieldPicker(context);

        Test.startTest();
        VisualEditor.DataRow defaultValue = picker.getDefaultValue();
        Test.stopTest();

        System.assertNotEquals(null,defaultValue);
    }

    @isTest
    static void test_getValues_for_Case() {

        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Case';
        AccelEditorAccountLookupFieldPicker picker = new AccelEditorAccountLookupFieldPicker(context);

        Test.startTest();
        VisualEditor.DynamicPickListRows plValues = picker.getValues();
        Test.stopTest();

        System.assert(plValues.size() > 0, 'No parent picklist values found for Account');

        Boolean foundAccountId = false;
        for(VisualEditor.DataRow dataRow : plValues.getDataRows()) {
            if(dataRow.getValue() == 'AccountId') {
                foundAccountId = true;
            }
        }
        System.assert(foundAccountId,' Could not find accountId on case');
    }

    @isTest
    static void test_getValues_for_Project() {

        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'Project__c';
        AccelEditorAccountLookupFieldPicker picker = new AccelEditorAccountLookupFieldPicker(context);

        Test.startTest();
        VisualEditor.DynamicPickListRows plValues = picker.getValues();
        Test.stopTest();

        System.assert(plValues.size() > 0, 'No parent picklist values found for Account');

        Boolean foundAccountId = false;
        for(VisualEditor.DataRow dataRow : plValues.getDataRows()) {
            if(dataRow.getValue() == 'Account__c') {
                foundAccountId = true;
            }
        }
       System.assert(foundAccountId,' Could not find account__c on project');
    }

    @isTest
    static void test_getValues_for_EmailStatus() {

        VisualEditor.DesignTimePageContext context = new VisualEditor.DesignTimePageContext();
        context.entityName = 'EmailStatus';

        AccelEditorAccountLookupFieldPicker picker = new AccelEditorAccountLookupFieldPicker(context);

        Test.startTest();
        VisualEditor.DynamicPickListRows plValues = picker.getValues();
        Test.stopTest();

        System.assert(plValues.size() == 0, 'We should have no account lookups on EmailStatus');
        
    }
}