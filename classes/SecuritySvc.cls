public with sharing class SecuritySvc {

    /**
     * @param sObjectApiName    The sObject API Name.
     * @param permSetNames      A Set of permission set names (api name).
     * @param profileNames      A Set of profile names. (label).
     *
     * @return                  A List of FieldPermission sObjects.
     */
    public static List<FieldPermissions> retrieveSObjectSecurityInfo(String sObjectApiName, Set<String> permSetNames, Set<String> profileNames) {
        return retrieveSObjectSecurityInfo(new Set<String>{sObjectApiName}, permSetNames, profileNames);
    }

    /**
     * @param sObjectApiNames   A Set of sObject API Names.
     * @param permSetNames      A Set of permission set names (api name).
     * @param profileNames      A Set of profile names. (label).
     *
     * @return                  A List of FieldPermission sObjects.
     */
    public static List<FieldPermissions> retrieveSObjectSecurityInfo(List<String> sObjectApiNames, Set<String> permSetNames, Set<String> profileNames) {
        return retrieveSObjectSecurityInfo(new Set<String>(sObjectApiNames), permSetNames, profileNames);
    }

    /**
     * @param sObjectApiNames   A Set of sObject API Names.
     * @param permSetNames      A Set of permission set names (api name).
     * @param profileNames      A Set of profile names. (label).
     *
     * @return                  A List of FieldPermission sObjects.
     */
    public static List<FieldPermissions> retrieveSObjectSecurityInfo(Set<String> sObjectApiNames, Set<String> permSetNames, Set<String> profileNames) {
        List<FieldPermissions> fieldPermissions;

        Map<Id, Profile> mProfilesByIds = retrieveProfileInfo(profileNames);
        Map<Id, PermissionSet> mPermissionSetsByIds = retrievePermissionSetInfo(permSetNames);

        Set<Id> parentIds = new Set<Id>();
        parentIds.addAll(mPermissionSetsByIds.keySet());

        Map<Id, PermissionSet> m = new Map<Id, PermissionSet> ([
                SELECT Id
                FROM PermissionSet
                WHERE ProfileId IN :mProfilesByIds.keySet()
        ]);
        parentIds.addAll(m.keySet());

        fieldPermissions = retrieveFieldPermissions(sObjectApiNames, parentIds);
        return fieldPermissions;
    }

    /**
     * @param sObjectApiNames   A Set of sObject API Names.
     * @param parentIds         A set of FieldPermission.ParentId values.
     *
     * @return                  A List of FieldPermission sObjects.
     */
    public static List<FieldPermissions> retrieveFieldPermissions(Set<String> sObjectApiNames, Set<Id> parentIds) {
        List<FieldPermissions> fieldPerms;
        String q = '';
        q += ' SELECT   {0},Parent.Label ';
        q += ' FROM     FieldPermissions ';
        q += ' WHERE    SObjectType IN :sObjectApiNames ';
        q += ' AND      ParentId IN :parentIds ';
        q += ' ORDER BY Parent.Label ASC, ';
        q += '          SObjectType ASC,';
        q += '          Field ASC';
        String formattedQuery = String.format(q, getAllFields(FieldPermissions.getSObjectType()));

        fieldPerms = Database.query(formattedQuery);
        return fieldPerms;
    }

    public static Map<Id, PermissionSet> retrievePermissionSetInfo(Set<String> permSetNames) {
        Map<Id, PermissionSet> mPermissionSetsByIds;

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   PermissionSet ';
        q += 'WHERE  Name IN :permSetNames ';
        String formattedQuery = String.format(q, getAllFields(PermissionSet.SObjectType));

        mPermissionSetsByIds = new Map<Id, PermissionSet>((List<PermissionSet>) Database.query(formattedQuery));
        return mPermissionSetsByIds;
    }
    public static Map<Id, PermissionSet> retrieveAllPermissionSets() {
        Map<Id, PermissionSet> mPermissionSetsByIds = new Map<Id, PermissionSet>([
                SELECT Id,Name,Label,IsCustom,IsOwnedByProfile
                FROM PermissionSet
                ORDER BY Name ASC
        ]);
        return mPermissionSetsByIds;
    }

    public static Map<Id, PermissionSet> retrieveAllPermissionSets(Boolean isCustom, Boolean isOwnedByProfile) {
        Map<Id, PermissionSet> mPermissionSetsByIds = new Map<Id, PermissionSet>([
                SELECT Id,Name,Label,IsCustom,IsOwnedByProfile
                FROM PermissionSet
                WHERE IsCustom = :isCustom
                AND IsOwnedByProfile = :isOwnedByProfile
                ORDER BY Name ASC
        ]);
        return mPermissionSetsByIds;
    }

    public static Map<Id, PermissionSetAssignment> retrievePermissionSetAssignments(Set<String> psNames) {
        Map<Id, PermissionSetAssignment> mPsas = new Map<Id, PermissionSetAssignment>([
                SELECT Id,AssigneeId, PermissionSetId, PermissionSet.Name,PermissionSet.ProfileId, PermissionSet.Profile.Name,Assignee.Name,
                        Assignee.Username,PermissionSet.Label
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name IN :psNames
                AND   Assignee.IsActive = TRUE
                ORDER BY Assignee.Name ASC
        ]);
        return mPsas;
    }

//    public static void retrieveTrackedData(Map<String,Set<String>> mSobj_Fields) {
//
//        // 1. Validate that supplied field is, in fact, tracked.
//        Map<String,Map<String,FieldDefinition>> mAll = FieldSetSvc.retrieveTrackedFieldDefinitions(mSobj_Fields.keySet());
//        if(!mAll.isEmpty()) {
//            for(String sObj : mAll.keySet()) {
//                Map<String,FieldDefinition> mSObjFields = mAll.get(sObj);
//                if(!mSobj_Fields.isEmpty()) {
//
//                }
//            }
//        }
//
//    }

    public static Map<String, Map<Id, User>> retrievePermSetUsers(Set<String> psNames) {

        Map<STring, Map<Id, User>> m = new Map<String, Map<Id, User>>();
        Map<Id, PermissionSetAssignment> mPsas = retrievePermissionSetAssignments(psNames);
        Set<Id> userIds = new Set<Id>();
        for (PermissionSetAssignment psa : mPsas.values()) {
            userIds.add(psa.AssigneeId);
        }

        Map<Id, User> mUsers = new Map<Id, User>([
                SELECT Id, Name, ProfileId
                FROM User
                WHERE Id IN:userIds
                AND IsActive = TRUE
        ]);
        if (!mUsers.isEmpty() && !mPsas.isEmpty()) {
            for (PermissionSetAssignment psa : mPsas.values()) {
                User user = mUsers.get(psa.AssigneeId);
                if (!m.containsKey(psa.PermissionSet.Label)) {
                    m.put(psa.PermissionSet.LAbel, new Map<Id, User>{user.Id => user});
                } else {
                    Map<Id, User> mUsersTmp = m.get(psa.PermissionSet.Label);
                    mUsersTmp.put(user.Id, user);
                }
            }
        }
        return m;
    }

    public static Map<Id, ObjectPermissions> retrievePermissionForObject(Set<Id> parentIds, Set<String> sObjectApiNames) {
        Map<Id, ObjectPermissions> mOps = new Map<Id, ObjectPermissions>([
                SELECT Id, PermissionsRead,PermissionsEdit,PermissionsDelete,PermissionsCreate,PermissionsModifyAllRecords,SobjectType,
                        Parent.Name,ParentId
                FROM ObjectPermissions
                WHERE ParentId IN :parentIds
                AND SobjectType IN :sObjectApiNames
                ORDER BY SobjectType ASC
        ]);
        return mOps;
    }

    public static Map<Id, User> retrieveProfileUsers(Set<String> profileNames) {
        Map<Id, User> mUsers = new Map<Id, User>([
                SELECT Id,Name,Username,ProfileId,Profile.Name
                FROM User
                WHERE Profile.Name IN :profileNames
                AND IsActive = TRUE
                ORDER BY Name ASC
        ]);
        return mUsers;
    }

    public static Map<Id, Profile> retrieveAllProfiles() {
        Map<Id, Profile> mPermissionSetsByIds = new Map<Id, Profile>([
                SELECT Id,Name,Description
                FROM Profile
                ORDER BY Name ASC
        ]);
        return mPermissionSetsByIds;
    }
    public static Map<Id, Profile> retrieveProfileInfo(Set<String> profileNames) {
        Map<Id, Profile> mProfilesByIds;
        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Profile ';
        q += 'WHERE  Name IN :profileNames ';
        String formattedQuery = String.format(q, getAllFields(Profile.SObjectType));

        mProfilesByIds = new Map<Id, Profile>((List<Profile>) Database.query(formattedQuery));
        return mProfilesByIds;
    }

    public static Map<Id, Profile> retrieveProfileInfo(Set<Id> profileIds) {
        Map<Id, Profile> mProfilesByIds;
        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Profile ';
        q += 'WHERE  ID IN :profileIds ';
        String formattedQuery = String.format(q, getAllFields(Profile.SObjectType));

        mProfilesByIds = new Map<Id, Profile>((List<Profile>) Database.query(formattedQuery));
        return mProfilesByIds;
    }

    @TestVisible
    private static List<String> getAllFields(SObjectType sObjType) {
        Map<String, Schema.SObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{
                sfields
        };
        return fields;
    }
}