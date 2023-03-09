public without sharing class FieldSetWrapper {

    @AuraEnabled public     String fieldSetSObjectApiName                           {get;set;}
    @AuraEnabled public     String fieldSetSObjectLabel                             {get;set;}
    @AuraEnabled public     Id     fieldSetSObjectRecordId                          {get;set;}
    @AuraEnabled public     String fieldSetName                                     {get;set;}
    @AuraEnabled public     String fieldSetApiName                                  {get;set;}
    @AuraEnabled public     String fieldSetNameSpace                                {get;set;}
    @AuraEnabled public     String fieldSetLabel                                    {get;set;}
    private                 String fieldSetDesc                                     {get;set;}
    @AuraEnabled public     String  fieldSetIconName                                {get;set;}
    @AuraEnabled public     Boolean displayFieldSetIcon                             {get;set;}
    @AuraEnabled public     List<FieldSetMemberWrapper> fieldSetMemberWrappers      {get;set;}
    @AuraEnabled public     Datetime wrapLastModifiedDateTime                       {get;set;}
    /**
     * 1 arg constructor which assumes we want child member wraps created.
     * @param fs  The Schema.FieldSet.
     */
    public FieldSetWrapper(Schema.FieldSet fs) {
        this(fs,true);
    }
    /**
     * 2 arg constructor allowing us to only populated field sets and not their child members if desired.
     * @param fs  The Schema.FieldSet.
     * @param populateMemberWraps  True if we want to look for child member, otherwise false.
     */
    public FieldSetWrapper(Schema.FieldSet fs, Boolean populateMemberWraps) {
        this.fieldSetSObjectApiName         = fs.getSObjectType().getDescribe().name;
        this.fieldSetSObjectLabel           = fs.getSObjectType().getDescribe().label;
        this.fieldSetName                   = fs.getName();
        String ns = '';
        if(fs.getNameSpace() != null) {
            ns+=fs.getNameSpace().toLowerCase()+'__';
        }
        this.fieldSetApiName                = ns + fieldSetName.toLowerCase();
        this.fieldSetNameSpace              = fs.getNameSpace();
        this.fieldSetLabel                  = fs.getLabel();
        this.fieldSetDesc                   = fs.getDescription();
        this.fieldSetIconName               = this.getFieldSetIconName(this.fieldSetDesc);
        if(fieldSetIconName == null || fieldSetIconName == '') {
            this.fieldSetIconName = getDefaultIconName(fieldSetSObjectApiName);
        }
        this.displayFieldSetIcon            = this.fieldSetIconName  != null && this.fieldSetIconName != '';
        if(populateMemberWraps) {
            this.fieldSetMemberWrappers = new List<FieldSetMemberWrapper>();
            for (Schema.FieldSetMember fsm : fs.getFields()) {
                this.fieldSetMemberWrappers.add(new FieldSetMemberWrapper(fsm));
            }
        }
        this.wrapLastModifiedDateTime = System.now();
    }
    /**
     *
     * Looks at the FS Desc and parses for ICON (icon:name).
     *
     * @param fieldSetDesc  The required description of the field set.
     * @return the icon name in a format like 'utility:iconName' otherwise null
     * @TODO replace with regex.
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
     * Uses the sObjectApiName to get the tab name to get the icon for that tab.
     * @param sObjectApiName the sObjectApiName
     * @return The NAme of the icon if found, otherwise null
     */
    private static String getDefaultIconName(String sObjectApiName) {
        String u;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();

        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }

        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectApiName == tr.getSobjectName() ) {
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    u = 'standard:' + sObjectApiName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return u;
    }
}