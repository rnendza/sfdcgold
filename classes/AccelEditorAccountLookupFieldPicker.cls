/**
 * Used for the lighting app builder. Provides a picklist for all lookup fields on an account
 * for the given object in context.
 * 
 * @see AccelEditorAccountLookupFieldPickerTest
 */
global with sharing class AccelEditorAccountLookupFieldPicker extends VisualEditor.DynamicPickList{

    private final static String ACCOUNT_REFERENCE_LABEL = '(Account)';
    private final static Set<String> EXCLUDE_LOOKUP_FIELDS = new Set<String>{'Master Record ID'};
    private VisualEditor.DesignTimePageContext context;

    /**
     * Context contains the object of the app builder and the page type.
     * @param context The Context passed by the App builder.
     * @see VisualEditor.DesignTimePageContext
     */
    global AccelEditorAccountLookupFieldPicker(VisualEditor.DesignTimePageContext context) {
        this.context = context;
    }

    /**
     * Just uses the first lookup field retrieved on Account as the default.
     * @return the default value of the picklist
     */
    global override VisualEditor.DataRow getDefaultValue() {

        VisualEditor.DataRow defaultValue;
        VisualEditor.DynamicPickListRows rowValues = retrieveAccountLookupRows();

        if(rowValues != null && rowValues.size() > 0) {
            VisualEditor.DataRow firstDataRow = rowValues.get(0);
            defaultValue = firstDataRow;
        }
        return defaultValue;
    }

    /**
     * Gets all lookups to account besides core / hidden lookups ie. Master Record ID
     * @return The Picklist values in an object the app builder can user to display cmp properties.
     * @see VisualEditor.DynamicPickListRows
     */
    global override VisualEditor.DynamicPickListRows getValues() {
        return retrieveAccountLookupRows();
    }

    /**
     * Get all sObjectFields for the object in context. Filter our that that are lookup to account,
     * and not part of the exclude lookup fields set.
     *
     * @return The dynamic picklist rows that are lookups on the parent object to account.
     */
    private VisualEditor.DynamicPickListRows retrieveAccountLookupRows() {
        VisualEditor.DynamicPickListRows rowValues = new VisualEditor.DynamicPickListRows();

        Set<Schema.SObjectField> sObjectFields = FieldSetSvc.retrieveAllSObjectFields(this.context.entityName);

        for (Schema.SObjectfield sObjectfield : sObjectFields) {
            DescribeFieldResult dfr = sObjectfield.getDescribe();

            if (String.valueOf(dfr.getReferenceTo()) == ACCOUNT_REFERENCE_LABEL
                    && !EXCLUDE_LOOKUP_FIELDS.contains(dfr.getLabel())) {
                rowValues.addRow(new VisualEditor.DataRow(dfr.label, dfr.name));
            }
        }
        return rowValues;
    }
}