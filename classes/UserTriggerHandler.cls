public with sharing class UserTriggerHandler {

    public final static String CUSTOMER_PORTAL_LICENSE_USER_TYPE = 'CspLitePortal';
    //@todo below all moved to custom settings.
    public final static String PASSWORD_EMAIL_TEMPLATE_DEV_NAME  = 'Accel_Communities_Password_Created_Email';
    public final static String PW_GENERATION_TYPE_RANDOM         = 'random';
    public final static Integer PW_LENGTH                        = 8;
    public final static String  GEN_USER_PERM_SET_API_NAME = 'View_All_Custom_Settings_And_CRM_Specific_Metadata';
    public final static String  DEFAULT_CL_MACHINE_TYPE          = 'VGT';

    /**
     * Calls System.setPassword in a @future method call as well as parses an email template and sends an email
     * if it is a community user, AND an active user AND the userType is CspLitePortal. (Customer Portal User)
     *
     * @param usersByIds  a map of UserId ==> User  (Trigger.newMap)
     * @return a set of User sObjects that were used to set passwords, otherwise empty.
     *
     * @see UserSvc.sendPasswordEmails
     * @see UserSvc.retrieveEmailTemplate
     * @see https://salesforce.stackexchange.com/questions/3889/what-are-the-possible-options-for-usertype
     */
    public static Set<Id> setPwAndSendEmail( Map<Id,User> usersByIds ) {
        Set<Id> userIds = new Set<Id>();
        for(User user : usersByIds.values()) {
            if(user.ContactId != null
                    && user.UserType == CUSTOMER_PORTAL_LICENSE_USER_TYPE
                    && user.IsActive) {
                userIds.add(user.Id);
            }
        }
        if(!userIds.isEmpty()) {
            Id emailTemplateId;
            EmailTemplate emailTemplate = UserSvc.retrieveEmailTemplate(PASSWORD_EMAIL_TEMPLATE_DEV_NAME);
            if(emailTemplate != null){
                emailTemplateId = emailTemplate.Id;
            }
            UserSvc.setUsersPasswords( userIds, PW_GENERATION_TYPE_RANDOM, PW_LENGTH, emailTemplateId);
        }
        return userIds;
    }
    /**
     * Sends Relationship managers a simple email to notify them a portal user was created as well as the
     * accounts the portal user has access to.
     *
     * usersByIds  a map of UserId ==> User  (Trigger.newMap)
     * @return a List of Messaging.SingleEmailMessage objects if successful.
     */
    public static List<Messaging.SingleEmailMessage> sendRmEmailsOnPortalUserCreated(Map<Id,User> usersByIds) {
        List<Messaging.SingleEmailMessage> emailMessages;

        Set<Id> userIds = new Set<Id>();
        for(User user : usersByIds.values()) {
            if(user.ContactId != null
                    && user.UserType == CUSTOMER_PORTAL_LICENSE_USER_TYPE
                    && user.IsActive) {
                userIds.add(user.Id);
            }
        }
        if(!userIds.isEmpty()) {
            emailMessages = UserSvc.buildPortalUserCreateRmEmails(userIds);
            Messaging.sendEmail( emailMessages ); //  @todo error handling.
        }
        return emailMessages;
    }

    /**
     * Rolls through the list of inserted users.. if there is a contactId attached (ie they are a community user)
     * then insert a row in Community_User_Setting__c.
     *
     * @param mUsersByIds       A Map of UserId => USer (Trigger.newMap)
     * @return                  A list of Community_User_Setting__c sObjects that were added (if any)
     */
    public static List<Community_User_Setting__c> createCommunityUserSettings( Map<Id,User> mUsersByIds ) {
        List<Community_User_Setting__c> communityUserSettings = new List<Community_User_Setting__c>();

        Set<User> users = new Set<User>();
        for(User user : mUsersByIds.values()) {
            if(user.ContactId != null) {
                users.add(user);
            }
        }
        if(!users.isEmpty()) {
            System.debug(LoggingLevel.DEBUG,'CommUserCreation--> attempting to create comm settings for '+users.size() + ' users.');
            communityUserSettings = CommunityUserSettingsSvc.createCommunityUserSettings(users,true);
        }
        return communityUserSettings;
    }

    /**
     * Based on profile names in the Cash Logistics Meta-data, if the user being inserted has a profile, that finds
     * a match with that profile name, create a Cl_User_Setting__c record.
     *
     * @param mUsersByIds A Map of User.Id => User sObject (recently inserted)
     * @return A List of Cl_User_Setting__c sObjects that were inserted, otherwise null.
     *
     * @implNotes This will be a no-opp unless it's a user being added with a profile defined in Cash Logistics meta-data.
     */
    public static List<Cl_User_Setting__c> createClUserSettings( Map<Id,User> mUsersByIds ) {

        List<CL_User_Setting__c> newSettings = new List<CL_User_Setting__c>();

        //  Find the user profiles we need to be concerned with.
        Cash_Logistics_Setting__mdt mdt =
                (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.getSObjectType(),'User');

        if(mdt != null && mdt.Profiles_For_User_Settings__c != null) {
            List<String> profileNames = mdt.Profiles_For_User_Settings__c.split(',');
            if(profileNames != null && !profileNames.isEmpty()) {

                //  Find only the users we need to be concerned with. ( Profile.Name is not in context )
                Map<Id,Profile> mProfiles = new Map<Id,Profile>([SELECT Id, Name FROM PRofile WHERE Name IN :profileNames]);

                if(!mProfiles.isEmpty()) {
                    Set<User> users = new Set<User>();
                    for (User user : mUsersByIds.values()) {
                        if (mProfiles.containsKey(user.ProfileId)) {
                            users.add(user);
                        }
                    }
                    //  Create settings for these users.
                    if (!users.isEmpty()) {
                        for (User user : users) {
                            CL_User_Setting__c setting = new CL_User_Setting__c(
                                    Name =  user.Name + ' setting',
                                    User__c = user.Id,
                                    Selected_Machine_Type__c = DEFAULT_CL_MACHINE_TYPE
                            );
                            newSettings.add(setting);
                        }
                        Database.insert(newSettings);  //  @todo error handling.
                    }
                }
            }
        }
        return newSettings;
    }

    /**
     * @param usersByIds  a set of user ids passed in by Trigger.new upon insert
     *
     * @implNotes  merely an override to insert into PermissionSetAssignment using a future async call to avoid
     *             mixed DML Issues.
     *
     * @see  https://accel-entertainment.monday.com/boards/286658657/pulses/696117182/posts/821349308
     */
    @Future
    public static void assignPermissionSets(Set<Id> usersByIds) {
        if(!usersByIds.isEmpty()) {
            Map<Id,User> mUsersByIds = new Map<Id,User>([ SELECT Id From User where Id IN :usersByIds] );
            assignPermissionSets( mUsersByIds);
        }
    }

    /**
     * Assigns a permission set to allow a user visibility to custom settings and metadata as required by Spring 2020.
     *
     * @param usersByIds A Map of User Id ==> User as passed in by Trigger.new on insert.
     * @see https://accel-entertainment.monday.com/boards/284140049/pulses/463200247/posts/664453955
     * @todo this shouldn't be necessary technically. Remove ref to CS / MDT object in JS and pass down as normal js object.
     */
    public static void assignPermissionSets( Map<Id, User> usersByIds ){

        Set<Id> userIds = new Set<Id>();
        //  Permission Set with Api Name View_All_Custom_Settings_And_CRM_Specific_Metadata required in tgt org
        List<PermissionSet> permissionSets = [SELECT Id FROM PermissionSet WHERE Name = :GEN_USER_PERM_SET_API_NAME ];
        PermissionSet permissionSet;
        if(!permissionSets.isEmpty()) {
            permissionSet = permissionSets[0];
        } else {
            //  BUG OUT SOMEONE REMOVED FROM TARGET ORG.
            return;
        }
        //   Any non Admin, Chatter, or Community User should get the permission set assigned.
        Map<Id, User> usersByIdsWithProfileInfo  = new Map<Id, User>([
                SELECT Id, Name, Profile.Name
                FROM User
                WHERE IsActive = TRUE
                AND  Id IN :usersByIds.keySet()         //  Passed in the trigger and NOT 1 of the below
                AND ( NOT Profile.Name LIKE '%Admin%' )
                AND ( NOT Profile.Name LIKE '%Chatter%' )
                //--------------   I do believe we want this for community users! AND ( NOT Profile.Name LIKE '%Community%' )
        ]);
        for( User createdUser: usersByIdsWithProfileInfo.values() ) {
            User validUser = usersByIdsWithProfileInfo.get( createdUser.Id );
            if( validUser !=null && createdUser.Id == validUser.Id ) {  // Defensive null check needed.
                //  The user created in the trigger has a profile that we want to add a permission set to..
                userIds.add( createdUser.Id );
            }
        }
        if (!userIds.isEmpty()) {
            List<PermissionSetAssignment> assignmentsToInsert = new List<PermissionSetAssignment>();
            for (Id uid : userIds) {
                assignmentsToInsert.add( new PermissionSetAssignment(PermissionSetId = permissionSet.Id, AssigneeId = uid) );
            }
            insert assignmentsToInsert;    //  Insert them in bulk
        }
    }
}