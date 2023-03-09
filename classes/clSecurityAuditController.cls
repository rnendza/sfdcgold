/**
 * clSecurityAuditController is the backing class for Cash Logistics Security Audit Data exports.
 *
 * @see SecuritySvc
 * @see Cash_Logistics_Security_Audit_Setting__mdt
 */
public with sharing class clSecurityAuditController {

    public final static String MAP_KEY_FIELD_PERM_DATA      = 'MAP_KEY_FIELD_PERM_DATA';
    public final static String MAP_KEY_USER_PERM_DATA       = 'MAP_KEY_USER_PERM_DATA';
    public final static String MAP_KEY_SECURITY_AUDIT_MDT   = 'MAP_KEY_SECURITY_AUDIT_MDT';
    public final static String MAP_KEY_USER_PERM_MDT        = 'MAP_KEY_USER_PERM_MDT';
    public final static String MAP_KEY_GOV_LIMITS           = 'MAP_KEY_GOV_LIMITS';
    public final static String MDT_FIELD_AUDIT_DEV_NAME     = 'Field_Audit';
    public final static String MDT_USER_PERM_AUDIT_DEV_NAME = 'User_Perm_Audit';
    public static Boolean      DEBUG_MAP                    = false;

    //  The below overridden with custom mdt.
    public static Set<String>  SPECIAL_FIELDS               = new Set<String> {'id','lastactivitydate','lastreferenceddate','lastvieweddate','lastmodifiedbyid','systemmodstamp','ownerid','createddate','createdbyid','isdeleted','lastmodifieddate'};
    public static String       SPECIAL_FIELDS_LABEL         = 'SECURE:READ';
    public static String       NO_PERMISSIONS_LABEL         = 'None';

    /**
     * Use this if we just want to rely on custom mdt for sObjectApi Names, profile names, perm set names etc.
     *
     * @return A ResponseDto object containing field perm info and sObject api info in the values map.
     *          Map<String, Map<String, Map<String, CustomFieldPerm>>>
     *          Security Entity Name => Map<SObjectApiName => Map<FieldApiName => CustomFieldPerm>>>
     * @see clSecurityAuditController.retrieveFieldPermissionsForProfilesAndPermSets
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveFieldPermissions() {
        ResponseDto dto = new ResponseDto();

        ResponseDto dtoMdt = retrieveSecurityAuditMetadata(MDT_FIELD_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);


        List<String> profileNames = mdt.Profile_Names__c.split(',');
        List<String> permSetNames = mdt.Permission_Set_Names__c.split(',');
        List<String> sObjectApiNames = mdt.sObject_Api_Names__c.split(',');

        dto = clSecurityAuditController.retrieveFieldPermissionsForProfilesAndPermSets(sObjectApiNames,permSetNames,profileNames);
        dto.values.put(MAP_KEY_SECURITY_AUDIT_MDT,mdt);
        dto.values.put(MAP_KEY_GOV_LIMITS,new CustomLimits());

        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveUserPermissions() {
        ResponseDto dto = new ResponseDto();

        ResponseDto dtoMdt = retrieveSecurityAuditMetadata(MDT_USER_PERM_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);

        List<String> profileNames = mdt.Profile_Names__c.split(',');
        List<String> permSetNames = mdt.Permission_Set_Names__c.split(',');
        Set<String> sPermSetNames = new Set<String>(permSetNames);
        Set<String> sProfileNames = new Set<String>(profileNames);


        Map<String, Map<String,CustomUserPerm>> m = groupUserPermsByUser(sPermSetNames, sProfileNames);

        dto.values.put(MAP_KEY_USER_PERM_DATA,m);
        dto.values.put(MAP_KEY_SECURITY_AUDIT_MDT,mdt);
        dto.values.put(MAP_KEY_GOV_LIMITS,new CustomLimits());
        dto.isSuccess = true;
        return dto;
    }

    /**
     * Use this to retrieve with user defined parameters;
     *
     * @return A ResponseDto object containing field perm info and sObject api info in the values map.
     *          Map<String, Map<String, Map<String, CustomFieldPerm>>>
     *          Security Entity Name => Map<SObjectApiName => Map<FieldApiName => CustomFieldPerm>>>
     * @see clSecurityAuditController.retrieveFieldPermissionsForProfilesAndPermSets
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveFieldPermissionsByParams( List<String> profileNames,
                                                                List<String> permSetNames,
                                                                List<String> sObjectApiNames) {
        ResponseDto dto = new ResponseDto();

        ResponseDto dtoMdt = retrieveSecurityAuditMetadata(MDT_FIELD_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);

        dto = clSecurityAuditController.retrieveFieldPermissionsForProfilesAndPermSets(sObjectApiNames,permSetNames,profileNames);
        dto.values.put(MAP_KEY_SECURITY_AUDIT_MDT,mdt);
        dto.values.put(MAP_KEY_GOV_LIMITS,new CustomLimits());

        return dto;
    }
    /**
     * Use this to retrieve with user defined parameters;
     *
     * @return A ResponseDto object containing field perm info and sObject api info in the values map.
     *          Map<String, Map<String, Map<String, CustomFieldPerm>>>
     *          Security Entity Name => Map<SObjectApiName => Map<FieldApiName => CustomFieldPerm>>>
     * @see clSecurityAuditController.retrieveFieldPermissionsForProfilesAndPermSets
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveUserPermissionsByParams( List<String> profileNames, List<String> permSetNames) {
        ResponseDto dto = new ResponseDto();

        ResponseDto dtoMdt = retrieveSecurityAuditMetadata(MDT_USER_PERM_AUDIT_DEV_NAME);
        Cash_Logistics_Security_Audit_Setting__mdt mdt =
                (Cash_Logistics_Security_Audit_Setting__mdt)dtoMdt.values.get(clSecurityAuditController.MAP_KEY_SECURITY_AUDIT_MDT);

        Set<String> sPermSetNames = new Set<String>(permSetNames);
        Set<String> sProfileNames = new Set<String>(profileNames);

        Map<String, Map<String,CustomUserPerm>> m = groupUserPermsByUser(sPermSetNames, sProfileNames);

        dto.values.put(MAP_KEY_USER_PERM_DATA,m);
        dto.values.put(MAP_KEY_SECURITY_AUDIT_MDT,mdt);
        dto.values.put(MAP_KEY_GOV_LIMITS,new CustomLimits());
        dto.isSuccess = true;
        return dto;
    }

    /**
     * Main execution method.
     *
     * @param sObjectApiNames A List of sObject Api Names.
     * @param permSetNames    A List of Perm Set Developer Names.
     * @param profileNames    A List of Profile Names.
     *
     * @return A ResponseDto object containing field perm info in the values map.
     *          Map<String, Map<String, Map<String, CustomFieldPerm>>>
     *          Security Entity Name => Map<SObjectApiName => Map<FieldApiName => CustomFieldPerm>>>
     * @see clSecurityAuditController.groupFieldPermsByParent
     */
    public static ResponseDto retrieveFieldPermissionsForProfilesAndPermSets (  List<String> sObjectApiNames,
                                                                                List<String> permSetNames,
                                                                                List<String> profileNames) {
        ResponseDto dto = new ResponseDto();

        Set<String> sPermSetNames = new Set<String>(permSetNames);
        Set<String> sProfileNames = new Set<String>(profileNames);
        Set<String> setSObjectApiNames = new Set<String>(sObjectApiNames);

        Map<String, Map<String, Map<String, CustomFieldPerm>>> mCustomFieldPerms = groupFieldPermsByParent(     setSObjectApiNames,
                                                                                                                sPermSetNames,
                                                                                                                sProfileNames);
        dto.values.put(MAP_KEY_FIELD_PERM_DATA,mCustomFieldPerms);
        return dto;
    }

    /**
     * We have to skip through hoops given SFDCs FieldPermission.Label sometimes results in an SFDC Id for Profile
     * Name and not label. We basically need to use the profile Id and look for it for the corresponding
     * record in the permission set object.
     *
     * @param sObjectApiNames A Set of sObject Api Names.
     * @param permSetNames    A Set of Perm Set Developer Names.
     * @param profileNames    A Set of Profile Names.
     *
     * @return A ResponseDto object containing field perm info in the values map
     *         Map<String, Map<String, Map<String, CustomFieldPerm>>>
     *         Security Entity Name => Map<SObjectApiName => Map<FieldApiName => CustomFieldPerm>>>
     * @see SecuritySvc
     */
    public static Map<String, Map<String, Map<String, CustomFieldPerm>>> groupFieldPermsByParent(   Set<String> sObjectApiNames,
                                                                                                    Set<String> permSetNames,
                                                                                                    Set<String> profileNames) {

        List<FieldPermissions> fieldPerms = securitySvc.retrieveSObjectSecurityInfo(sObjectApiNames,permSetNames,profileNames);
        Map<String,Map<String,DescribeFieldResult>> mSObjectFields = FieldSetSvc.retrieveFieldDescribeResults(sObjectApiNames);
        Map<String,Set<String>> mSobjectFieldsbySObject = retrieveAllSObjectfields(sObjectApiNames);
        Map<String,DescribeSObjectResult> mSObjects = FieldSetSvc.retrieveSObjDescribeResults(sObjectApiNames);

        Set<Id> profileIds = new Set<Id>();
        for(FieldPermissions fp : fieldPerms) {
            if(fp.Parent.Label instanceof Id) {
                //  Weird SFDC Profile Label legacy quirk
                profileIds.add(fp.Parent.Label);
            }
        }
        Map<Id,Profile> mProfilesByIds = SecuritySvc.retrieveProfileInfo(profileIds);
        Map<String,PermissionSet> mPs_ByLabel = retrievePermissionSetInfo(permSetNames);

        Set<String> securityEntities = new Set<String>();
        securityEntities.addAll(profileNames);
        securityEntities.addAll(mPs_ByLabel.keySet());

        Map<String, Map<String, Map<String, CustomFieldPerm>>> mCustomFieldPerms = retrieveSObjectTemplate( securityEntities,
                                                                                                            sObjectApiNames,
                                                                                                            mSobjectFieldsbySObject,
                                                                                                            mSObjectFields);
        for(FieldPermissions fp : fieldPerms) {
            String securityEntity, sObjectApiName;
            if (fp.Parent.Label instanceof Id) {
                securityEntity = mProfilesByIds.get(fp.Parent.Label).Name;
            } else {
                securityEntity = fp.Parent.Label;
            }
            sObjectApiName = fp.SobjectType.toLowerCase() ;
            String fieldApiName = fp.Field.toLowerCase().replace(sObjectApiName+'.','').toLowerCase();

            CustomFieldPerm customFieldPerm = mCustomFieldPerms.get(securityEntity)?.get(sObjectApiName)?.get(fieldApiName);
            if(customFieldPerm != null) {  // this should not be null since mCustomFieldPerms contains superset!
                customFieldPerm.permissionRead = fp.PermissionsRead;
                customFieldPerm.permissionEdit = fp.PermissionsEdit;
                customFieldPerm.permissionDisplay = getPermissionDisplay(fp);
                customFieldPerm.sObjLabel = mSObjects.get(sObjectApiName).getLabel();
            }
        }
        if(DEBUG_MAP) {
            debugFieldAuditMap(mCustomFieldPerms);
        }
        return mCustomFieldPerms;
    }
    /**
     * @param permSetNames xx
     * @param profileNames xx
     *
     * @return xx
     */
    public static Map<String, Map<String,CustomUserPerm>> groupUserPermsByUser(Set<String> permSetNames, Set<String> profileNames) {

        Map<String,PermissionSet> mPs_ByLabel = retrievePermissionSetInfo(permSetNames);
        Map<Id,Profile> mProfilesByIds = SecuritySvc.retrieveProfileInfo(profileNames);

        Set<String> securityEntities = new Set<String>();
        securityEntities.addAll(profileNames);
        securityEntities.addAll(mPs_ByLabel.keySet());

        Map<Id,PermissionSetAssignment> m = SecuritySvc.retrievePermissionSetAssignments(permSetNames);
        Set<Id> objectParentIds = new Set<Id>();
        Map<Id,User> mAllUsers = new Map<Id,User>();

        for(PermissionSetAssignment psa : m.values()) {
            objectParentIds.add(psa.PermissionSetId);
        }
        Map<Id,User> mProfileUsers = SecuritySvc.retrieveProfileUsers(profileNames);
        Map<String,Map<Id,User>> mPermSetUsers = SecuritySvc.retrievePermSetUsers(permSetNames);

        Map<String,Map<Id,User>> mSecurityEntity_Users = new Map<String,Map<Id,User>>();
        //  Roll through incoming permission set names
        for(String psName : mPermSetUsers.keySet()) {
            Map<Id,User> mUsers = mPermSetUsers.get(psName);
            for(Id userId : mUsers.keySet()) {
                User user = mUsers.get(userId);
                mAllUsers.put(user.Id,user);
                if (!mSecurityEntity_Users.containsKey(psName)) {
                    mSecurityEntity_Users.put(psName, new Map<Id, user>{user.Id => user});
                } else {
                    Map<Id,User> mTmp = mSecurityEntity_Users.get(psName);
                    mTmp.put(user.Id,user);
                }
            }

        }
        // Roll through incoming profile names.
        for(Profile profile : mProfilesByIds.values()) {
            for (User user : mProfileUsers.values()) {
                if(user.ProfileId == profile.Id) {
                    mAllUsers.put(user.Id,user);
                    if (!mSecurityEntity_Users.containsKey(profile.Name)) {
                        mSecurityEntity_Users.put(profile.Name,new Map<Id,user>{user.Id => user});
                    } else {
                        Map<Id,User> mU = mSecurityEntity_Users.get(profile.Name);
                        mU.put(user.Id,user);
                    }
                }
            }
        }
        //  Ensure user is assigned to incoming permission set names.
        for(PermissionSetAssignment psa : m.values()) {
            for(User user : mProfileUsers.values()) {
                if(psa.AssigneeId == user.Id) {
                    if (!mSecurityEntity_Users.containsKey(psa.PermissionSet.Label)) {
                        mSecurityEntity_Users.put(psa.PermissionSet.Label,new Map<Id,user>{user.Id => user});
                    } else {
                        Map<Id,User> mU = mSecurityEntity_Users.get(psa.PermissionSet.Label);
                        mU.put(user.Id,user);
                    }
                }
            }
        }

        Map<String,Map<String,CustomUserPerm>> mTemplate = retrieveUserTemplate(securityEntities,mAllUsers);

        for(String secEntity : mTemplate.keySet()) {
            Map<String,CustomUserPerm> mSecTemplateUsers = mTemplate.get(secEntity);
            Map<Id,User> mSecEntityUsers = mSecurityEntity_Users.get(secEntity);
            for(String userId : mSecTemplateUsers.keySet()) {
                if(mSecEntityUsers.containsKey(userId)) {
                    CustomUserPerm cup = mSecTemplateUsers.get(userId);
                    cup.hasAccess = true;
                }
            }
        }
        if(DEBUG_MAP) {
            debugUserSecMap(mTemplate);
        }
        return mTemplate;
    }

    /**
     * @param securityEntities xx
     * @param mUsers xx
     *
     * @return xx
     */
    public static Map<String, Map<String, CustomUserPerm>> retrieveUserTemplate(   Set<String> securityEntities,
                                                                                   Map<Id,User> mUsers) {

        Map<String,Map<String, CustomUserPerm>> mCustomUserPerms = new Map<String, Map<String, CustomUserPerm>>();

        for (String securityEntity : securityEntities) {
            //  Roll through profile / perm set name.
            if (!mCustomUserPerms.containsKey(securityEntity)) {
                mCustomUserPerms.put(securityEntity, new  Map<String, CustomUserPerm>());
            }
            Map<String,CustomUserPerm> m = mCustomUserPerms.get(securityEntity);
            //  Add template for every user for security entity.
            for (String userName : mUsers.keySet()) {
                String userNameKey = userName;
                if (!m.containsKey(userNameKey)) {
                    User user = mUsers.get(userNameKey);
                    m.put(userNameKey, new CustomUserPerm(user,securityEntity));
                }
            }
        }
        return mCustomUserPerms;
    }

    /**
     * @param securityEntities           xx
     * @param sObjectApiNames     xx
     * @param mSobjectFieldsbySObject xx
     * @param mSobjectFields xx
     *
     * @return xx
     */
    public static Map<String, Map<String, Map<String, CustomFieldPerm>>> retrieveSObjectTemplate(   Set<String> securityEntities,
                                                                                                    Set<String> sObjectApiNames,
                                                                                                    Map<String, Set<String>> mSobjectFieldsbySObject,
                                                                                                    Map<String, Map<String, DescribeFieldResult>> mSobjectFields) {

        Map<String, Map<String, Map<String, CustomFieldPerm>>> mCustomFieldPerms =
                new Map<String, Map<String, Map<String, CustomFieldPerm>>>();

        Map<String,DescribeSObjectResult> mSObjects = FieldSetSvc.retrieveSObjDescribeResults(sObjectApiNames);
        Map<String,FieldDefinition> mFieldDefs = FieldSetSvc.retrieveFieldDescriptions(sObjectApiNames);

        for (String securityEntity : securityEntities) {
            //  Roll through profile / perm set name.
            if (!mCustomFieldPerms.containsKey(securityEntity)) {
                mCustomFieldPerms.put(securityEntity, new Map<String, Map<String, CustomFieldPerm>>());
            }
            Map<String, Map<String, CustomFieldPerm>> mSObjCpfs = mCustomFieldPerms.get(securityEntity);
            for (String sObj : mSobjectFieldsbySObject.keySet()) {
                String sObjLc = sObj.toLowerCase();
                //  Roll through sObject Api Name
                if (!mSObjCpfs.containsKey(sObjLc)) {
                    mSObjCpfs.put(sObjLc, new Map<String, CustomFieldPerm>());
                }
                Map<String, DescribeFieldResult> mSobjDescribes = mSobjectFields.get(sObjLc);
                Map<String, CustomFieldPerm> m = mSObjCpfs.get(sObjLc);
                //  Roll through all the field describes for security entity / sObjApiName combo.
                for (String fieldApiName : mSobjDescribes.keySet()) {
                    fieldApiName = fieldApiName.toLowerCase();
                    if (!m.containsKey(fieldApiName)) {
                        DescribeFieldResult describeFieldResult = mSobjDescribes.get(fieldApiName);
                       // FieldDefinition fieldDefinition = mFieldDefs.get(sObj);
                        FieldDefinition fieldDefinition = mFieldDefs.get(fieldApiName);
                        CustomFieldPerm cfp = new CustomFieldPerm(securityEntity, sObjLc, describeFieldResult, fieldDefinition);
                        cfp.sObjLabel = mSObjects.get(sObjLc).getLabel();
                        m.put(fieldApiName.toLowerCase(), cfp);
                    }
                }
            }
        }
        return mCustomFieldPerms;
    }
    /**
     * @param sObjectApiNames xx
     *
     * @return xx
     */
    public static Map<String,Set<String>> retrieveAllSObjectfields(Set<String> sObjectApiNames) {

        Map<String,Set<String>> mSobjectFieldsbySObject = new Map<String,Set<String>>();
        for(String sObjectApiName : sObjectApiNames) {
            mSobjectFieldsbySObject.put(sObjectApiName,FieldSetSvc.retrieveAllSObjectFieldApiNames(sObjectApiName));
        }
        return mSobjectFieldsbySObject;
    }
    /**
     * @param permSetApiNames xx
     *
     * @return xx
     */
    public static Map<String,PermissionSet> retrievePermissionSetInfo(Set<String> permSetApiNames) {

        Map<String,PermissionSet> m = new Map<String,PermissionSet>();
        Map<Id,PermissionSet> mPermissionSetsByIds = SecuritySvc.retrievePermissionSetInfo(permSetApiNames);
        for(PermissionSet ps : mPermissionSetsByIds.values()) {
            m.put(ps.Label,ps);
        }
        return m;
    }

    /**
     * Simply find the custom metdata for security audits.
     *
     * @param mdtDevName  The mdt record developer name
     * @return            A ResponseDto containing the Mdt record in its values map.
     *
     * @see Cash_Logistics_Security_Audit_Setting__mdt
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveSecurityAuditMetadata(String mdtDevName) {
        ResponseDto dto = new ResponseDto();
        Cash_Logistics_Security_Audit_Setting__mdt mdt;
        SObject sobj = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Security_Audit_Setting__mdt.getSObjectType(),mdtDevName);
        mdt = sobj != null ? (Cash_Logistics_Security_Audit_Setting__mdt)sobj : null;
        if(mdt != null) {
            List<String> specialFields  = mdt.Special_Fields__c.split(',');
            if(specialFields != null && !specialFields.isEmpty()) {
                SPECIAL_FIELDS = new Set<String>(specialFields);
            }
            SPECIAL_FIELDS_LABEL = mdt.Special_Fields_Label__c != null ? mdt.Special_Fields_Label__c  : SPECIAL_FIELDS_LABEL;
            NO_PERMISSIONS_LABEL = mdt.No_Permissions_Label__c != null ? mdt.No_Permissions_Label__c : NO_PERMISSIONS_LABEL;
        }
        dto.values.put(MAP_KEY_SECURITY_AUDIT_MDT,mdt);
        return dto;
    }
    /**
     * @param fp xx
     *
     * @return xx
     */
    public static String getPermissionDisplay(FieldPermissions fp ) {
        String displayValue = '';
        if (fp.PermissionsRead) {
            displayValue = 'Read';
        }
        if (fp.PermissionsEdit) {
            displayValue += '/Edit';
        }
        return displayValue;
    }
    /**
     * xx
     */
    public class CustomFieldPerm {
        @AuraEnabled public String securityEntity;
        @AuraEnabled public String sObjApiName;
        @AuraEnabled public String sObjLabel;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldKey;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public String fieldDesc;
        @AuraEnabled public String fieldHelpText;
        @AuraEnabled public Boolean permissionRead;
        @AuraEnabled public Boolean permissionEdit;
        @AuraEnabled public String  permissionDisplay;

        public CustomFieldPerm(String securityEntity, String sObjApiName,DescribeFieldResult dfr, FieldDefinition fieldDefinition) {
            this.securityEntity = securityEntity;
            this.sObjApiName = sObjApiName;
            this.fieldApiName = dfr.getName().toLowerCase();
            this.fieldLabel = dfr.getLabel();
            this.fieldHelpText = dfr.getInlineHelpText();
            this.fieldKey = this.sObjApiName+'.'+this.fieldApiName;
            this.permissionEdit = false;
            this.permissionRead = false;
            this.permissionDisplay = NO_PERMISSIONS_LABEL;
            if(securityEntity == 'System Administrator') {
                this.permissionDisplay = 'Read/Edit';
            }
            if(SPECIAL_FIELDS.contains(this.fieldApiName)) {
                this.permissionDisplay = SPECIAL_FIELDS_LABEL;
            } else {
                if (fieldDefinition != null) {
                    this.fieldDesc = fieldDefinition.Description;
                    if (fieldDefinition.Description != null && fieldDefinition.Description.contains(SPECIAL_FIELDS_LABEL)) {
                        this.permissionDisplay = SPECIAL_FIELDS_LABEL;
                    }
                }
            }
        }
    }

    public class CustomUserPerm {
        @AuraEnabled public String securityEntity;
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public Boolean hasAccess = false;

        public CustomUserPerm(User user, String securityEntity) {
            this.userId = user.Id;
            this.userName = user.Name;
            this.hasAccess = false;
            this.securityEntity = securityEntity;
        }
    }

    public class CustomLimits {

        @AuraEnabled public Integer cpuTimeUsed;
        @AuraEnabled public Integer maxCpuTime;
        @AuraEnabled public Integer heapSizeUsed;
        @AuraEnabled public Integer maxHeapSize;
        @AuraEnabled public Integer queriesUsed;
        @AuraEnabled public Integer maxQueries;
        @AuraEnabled public Integer queryRows;
        @AuraEnabled public Integer maxQueryRows;

        public CustomLimits() {
            this.cpuTimeUsed = Limits.getCpuTime();
            this.maxCpuTime = Limits.getLimitCpuTime();
            this.heapSizeUsed = Limits.getHeapSize();
            this.maxHeapSize = Limits.getLimitHeapSize();
            this.queriesUsed = Limits.getQueries();
            this.maxQueries = Limits.getLimitQueries();
            this.queryRows = Limits.getQueryRows();
            this.maxQueryRows = Limits.getLimitQueryRows();
        }
    }

    public static void debugFieldAuditMap( Map<String,Map<String, Map<String,CustomFieldPerm>>> mCustomFieldPerms) {
        String msg = '\n\n';
        msg+='\n---> ====== Field Audit Security Map Details ====== ';
        msg+='\n---> # of security entities ='+mCustomFieldPerms.size();
        msg+='\n--->  security entities:'+mCustomFieldPerms.keySet();
        for(String key : mCustomFieldPerms.keySet()) {
            msg+='\n--->  security entity key= '+key;
            Map<String, Map<String,CustomFieldPerm>> mSObjCfps = mCustomFieldPerms.get(key);
            msg+='\n--->      # of sObjects ='+mSObjCfps.size();
            for(String key2 : mSObjCfps.keySet()) {
                msg+='\n--->          sObjApiName ='+key2;
                Map<String,CustomFieldPerm> mCfps = mSObjCfps.get(key2);
                msg+='\n--->          # of fields ='+mCfps.size();
                for(String key3 : mCfps.keySet()) {
                    msg+='\n--->            field key: ='+key3;
                    msg+='\n--->               '+mCfps.get(key3);
                }
            }
        }
        System.debug(msg +'\n\n');
    }

    public static void debugUserSecMap( Map<String,Map<String,CustomUserPerm>> mUserSec) {
        String msg = '\n\n';
        msg+='\n---> ====== User Perm Security Map Details ====== ';
        msg+='\n---> # of security entities ='+mUserSec.size();
        msg+='\n--->  security entities:'+mUserSec.keySet();
        for(String key : mUserSec.keySet()) {
            msg+='\n--->  security entity key= '+key;
            Map<String,CustomUserPerm> mSecUsers = mUserSec.geT(key);
            msg+='\n--->      # of Users ='+mSecUsers.size();
            for(String key2 : mSecUsers.keySet()) {
                msg+='\n--->          userId ='+key2;
                CustomUserPerm cup = mSecUsers.get(key2);
                msg+='\n--->            customuserperm: ='+cup;
            }
        }
        System.debug(msg +'\n\n');
    }




}