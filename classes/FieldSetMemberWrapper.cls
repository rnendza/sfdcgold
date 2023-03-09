/**
 * A general wrapper for use by clients in order to avoid serialization issues with Schema.FieldSetMember.
 * @see Schema.FieldSetMember
 */
public class FieldSetMemberWrapper  {

    @AuraEnabled public String  fieldSetApiName                     {get;set;}
    @AuraEnabled public String  sObjectApiName                      {get;set;}
    //----- lookup helper props
    @AuraEnabled public String  sObjectReferenceToLabel             {get;set;}
    @AuraEnabled public String  sObjectReferenceToApi               {get;set;}
    @AuraEnabled public String  sObjectReferenceToNameFieldValue    {get;set;}

    //------
    @AuraEnabled public String  fieldLabel                          {get;set;}
    @AuraEnabled public String  fieldHelp                           {get;set;}
    @AuraEnabled public String  fieldApiName                        {get;set;}
    @AuraEnabled public String  fieldType                           {get;set;}
    @AuraEnabled public Object  fieldValue                          {get;set;}
    @AuraEnabled public Boolean fieldRequired                       {get;set;}
    @AuraEnabled public Boolean dbRequired                          {get;set;}
    @AuraEnabled public Boolean displayFieldHelp                    {get;set;}
    @AuraEnabled public Boolean isFormulaField                      {get;set;}
    @AuraEnabled public String  sObjectApiIconName                  {get;set;}

            /**
             * @param fsm - The FieldSetMember  (for a new field set member (no values)
             */
    public FieldSetMemberWrapper(Schema.FieldSetMember fsm) {
  
        DescribeFieldResult dr          = fsm.getSObjectField().getDescribe();
        this.sObjectApiName             = '';
        this.fieldApiName               = fsm.getFieldPath();
        this.fieldLabel                 = dr.getLabel();
        this.fieldHelp                  = dr.getInlineHelpText();
        this.fieldRequired              = fsm.getRequired();
        this.dbRequired                 = fsm.getDbRequired();
        this.isFormulaField             = dr.isCalculated();
        this.fieldValue                 = null;
        this.fieldType                  = String.valueOf(fsm.getType());

        if(fieldType == FieldSetSvc.LOOKUP_FIELD_TYPE) {
            this.sObjectReferenceToLabel            = dr.referenceTo[0].getDescribe().label;
            this.sObjectReferenceToApi              = dr.referenceTo[0].getDescribe().name;
            this.sObjectReferenceToNameFieldValue   = null;
            this.sObjectApiIconName                 = null;
        }
        this.displayFieldHelp           = this.fieldHelp != null && this.fieldHelp != '' ? true : false;
    }
    /**
     * Overloaded constructor used to set the parent field set api name if needed,
     * @param fieldSetApiName   The api name of the Parent Field Set.
     * @param fsm               The FieldSetMember  (for a new field set member (no values)
     */
    public FieldSetMemberWrapper(Schema.FieldSetMember fsm, String fieldSetApiName) {

        DescribeFieldResult dr          = fsm.getSObjectField().getDescribe();
        this.fieldSetApiName            = fieldSetApiName;
        this.sObjectApiName             = '';
        this.fieldApiName               = fsm.getFieldPath();
        this.fieldLabel                 = dr.getLabel();
        this.fieldHelp                  = dr.getInlineHelpText();
        this.fieldRequired              = fsm.getRequired();
        this.dbRequired                 = fsm.getDbRequired();
        this.isFormulaField             = dr.isCalculated();
        this.fieldValue                 = null;
        this.fieldType                  = String.valueOf(fsm.getType());

        if(fieldType == FieldSetSvc.LOOKUP_FIELD_TYPE) {
            this.sObjectReferenceToLabel            = dr.referenceTo[0].getDescribe().label;
            this.sObjectReferenceToApi              = dr.referenceTo[0].getDescribe().name;
            this.sObjectReferenceToNameFieldValue   = null;
        }
        this.displayFieldHelp           = this.fieldHelp != null && this.fieldHelp != '' ? true : false;
    }
    /**
    *  Overloaded constructor used to flag fields required at a database level.
     * @param sObjectField- The Schema.SObjectField - used to flag dbRequired
     */
    public FieldSetMemberWrapper(Schema.SObjectField field,Boolean dbRequired) {

        DescribeFieldResult dr          = field.getDescribe();
        this.sObjectApiName             = '';
        this.fieldApiName               = dr.getName();
        this.fieldLabel                 = dr.getLabel();
        this.fieldHelp                  = dr.getInlineHelpText();
        this.dbRequired                 = dbRequired;
        this.fieldValue                 = null;
        this.fieldType                  = String.valueOf(dr.getType());

        if(fieldType == FieldSetSvc.LOOKUP_FIELD_TYPE) {
            this.sObjectReferenceToLabel            = dr.referenceTo[0].getDescribe().label;
            this.sObjectReferenceToApi              = dr.referenceTo[0].getDescribe().name;
            this.sObjectReferenceToNameFieldValue   = null;
        }
        this.displayFieldHelp           = this.fieldHelp != null && this.fieldHelp != '' ? true : false;
    }
}