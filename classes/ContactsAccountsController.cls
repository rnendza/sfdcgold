public without sharing class ContactsAccountsController {

    public static final String MAP_KEY_CONTACT_ACCOUNTS = 'MAP_KEY_CONTACT_ACCOUNTS';
    public static final String MAP_KEY_ACR_CREATED      = 'MAP_KEY_ACR_CREATED';
    public static final String MAP_KEY_ACR_DELETED      = 'MAP_KEY_ACR_DELETED';

    public static final Set<String> USER_PERMISSION_SET_NAMES = new Set<String> {'Community_Access'};

    // @deprecated Allow the Trigger on User to do this stuff...
    public static final String PORTAL_USER_DEFAULT_PW   = 'accel1wins'; //  @todo custom setting / encrypted ?
    public static final Integer AES_KEY_SIZE             = 256;
    public static final Integer PW_LENGTH                = 12;

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveContactAccounts(Id contactId) {
        ResponseDto dto = new ResponseDto();
        List<ContactSvc.ContactAccount> contactAccounts = ContactSvc.retrieveContactAccounts(contactId,true);
        if(contactAccounts.isEmpty()) {
            dto.isSuccess = false;
            dto.technicalMsg = 'no AccountContactRecords found for contactId'+contactId;
            return dto;
        }
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_CONTACT_ACCOUNTS, contactAccounts);
        return dto;
    }
    @AuraEnabled(Cacheable=true)
    public static List<Profile> retrievePortalProfiles() {

        Set<String> profileNames = new Set<String>{'Individual User Community Standard','Grouped User Community Standard'};
        List<Profile> profiles = [
                SELECT Id, Name
                FROM   Profile
                WHERE  Name IN :profileNames
        ];
        return profiles;
    }
    @AuraEnabled(Cacheable=true)
    public static Trigger_Settings__c retrieveTriggerSettings(Id userId) {
        return CustomSettingsSvc.getTriggerSettings(userId);
    }
    @AuraEnabled(Cacheable=true)
    public static Batch_Settings__c retrieveOrgBatchSettings() {
        return CustomSettingsSvc.getBatchSettings();
    }
    @AuraEnabled
    public static ResponseDto updateTriggerSettings(Trigger_Settings__c triggerSettings) {
        ResponseDto dto = new ResponseDto();
        try {
            Trigger_Settings__c ts = retrieveTriggerSettings(UserInfo.getUserId());
            ts.Portal_User_SetPassword_Active__c = triggerSettings.Portal_User_SetPassword_Active__c;
            upsert ts;
            dto.values.put('ts',ts);
            dto.message = 'Successfully updated Trigger Settings to Portal_User_SetPassword_Active = '
                    +ts.Portal_User_SetPassword_Active__c;
            dto.isSuccess = true;
        } catch (Exception e) {
            dto.message = e.getMessage();
        }
        return dto;
    }
    @AuraEnabled
    public static ResponseDto updateBatchSettings(Batch_Settings__c batchSettings) {
        ResponseDto dto = new ResponseDto();
        try {
            Batch_Settings__c batch = retrieveOrgBatchSettings();
            batch.Most_Recent_Hpd_Date__c = batchSettings.Most_Recent_Hpd_Date__c;
            upsert batch;
            batch = CustomSettingsSvc.getBatchSettings();
            dto.values.put('batch',batch);
            dto.message = 'Successfully updated Batch Settings';
            dto.isSuccess = true;
        } catch (Exception e) {
            dto.message = e.getMessage();
        }
        return dto;
    }

//    SELECT Id, Name
//            FROM RecentlyViewed
//    WHERE Type IN ('Account', 'Contact', 'Plan__c')
//            ORDER BY LastViewedDate DESC

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrievePortalUsers() {
        ResponseDto dto = new ResponseDto();
        List<User> users = [
            SELECT  Id,Name,Username,Email,LastLoginDate,Address,Phone,NumberOfFailedLogins,
                    Contact.Account.Name
            FROM    User
            WHERE   IsActive = TRUE
            AND     ContactId != null
            AND     Contact.Community_Contact__c = TRUE
            ORDER BY Name ASC
        ];
        System.debug(users);
        dto.values.put('portalUsers',users);
        dto.isSuccess = true;
        return dto;
    }
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrievePortalAccounts() {
        ResponseDto dto = new ResponseDto();
        List<Account> accounts = [
              SELECT Id, Name, IGB_License__c, IGB_License_Status__c,
                     ShippingAddress, Relationship_Manager__r.Name,Regional_Manager__c
              FROM   Account
              WHERE  Id IN (
                      SELECT AccountId
                      FROM   AccountContactRelation
                      WHERE  Contact.Community_Contact__c = TRUE
              )
              ORDER BY Name ASC
              LIMIT 500
        ];
        dto.values.put('portalAccounts',accounts);
        dto.isSuccess = true;
        return dto;
    }
    @AuraEnabled
    public static ResponseDto createAccountContactRelationship(Id contactId, Id accountId ) {
        ResponseDto dto = new ResponseDto();
        AccountContactRelation acr = new AccountContactRelation();
        acr.ContactId = contactId;
        acr.AccountId = accountId;
        insert acr;
        acr = [SELECT Id, ContactId, AccountId, Contact.Name, Account.Name, Account.HQ_Account__c from AccountContactRelation WHERE ID = :acr.Id];

        if(acr.Account.HQ_Account__c == true) {
            List<Account> childAccounts = ContactSvc.findHqChildren(new Set<Id> { accountId });
            if(!childAccounts.isEmpty()) {
                List<AccountContactRelation> acrs = new List<AccountContactRelation>();
                for(Account account: childAccounts) {
                    AccountContactRelation acrChild = new AccountContactRelation(ContactId=contactId, AccountId = account.Id);
                    acrs.add(acrChild);
                }
                if(!acrs.isEmpty()) {
                    insert acrs;
                }
            }
        }

        dto.isSuccess = true;
        dto.values.put(MAP_KEY_ACR_CREATED,acr);
        ResponseDto dtoContactAccounts = retrieveContactAccounts(contactId);
        if(dto.isSuccess) {
            dto.values.put(MAP_KEY_CONTACT_ACCOUNTS,dtoContactAccounts.values.get(MAP_KEY_CONTACT_ACCOUNTS));
        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto deleteAccountContactRelationship(Id accountContactRelationId ) {
        ResponseDto dto = new ResponseDto();
        List<AccountContactRelation> acr = [
                SELECT  Id,Account.Name, Contact.Name, ContactId
                FROM    AccountContactRelation
                WHERE   Id = :accountContactRelationId
        ];
        AccountContactRelation acrDeleted;
        if(!acr.isEmpty()) {
            acrDeleted = acr[0];
            Id contactId  = acrDeleted.ContactId;
            delete acr;
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_ACR_DELETED,acrDeleted);
            ResponseDto dtoContactAccounts = retrieveContactAccounts(contactId);
            if(dtoContactAccounts.isSuccess) {
                dto.values.put(MAP_KEY_CONTACT_ACCOUNTS,dtoContactAccounts.values.get(MAP_KEY_CONTACT_ACCOUNTS));
            }
        }
        return dto;
    }
    /**
     * Creates a portal user sObject.
     *
     * @param contact
     * @param userName
     *
     * @return
     */
    @AuraEnabled
    public static ResponseDto insertPortalUser(  Contact contact, String userName) {
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        User portalUser = ContactSvc.buildPortalUser(contact.accountId,contact.firstName,contact.lastname,contact.email,userName);
        try {
            portalUser.ContactId = contact.Id;
            portalUser.IsActive = true;
            insert portalUser;
            dto.isSuccess = true;
        } catch(Exception ex) {
            dto.message = ex.getMessage();
        }
        dto.values.put('portalUser',portalUser);
        return dto;
    }
    @AuraEnabled
    public static ResponseDto assignPermissionSets(Id userId) {
        ResponseDto dto = new ResponseDto();
        List<PermissionSet> permissionSets = [
                SELECT Id
                FROM PermissionSet
                WHERE Name IN :USER_PERMISSION_SET_NAMES
        ];
        if (!permissionSets.isEmpty()) {
            List<PermissionSetAssignment> permissionSetAssignments = new List<PermissionSetAssignment>();
            for (PermissionSet ps : permissionSets) {
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
                permissionSetAssignments.add(psa);
            }
            try {
                insert permissionSetAssignments;
                dto.isSuccess = true;
                dto.technicalMsg = 'Assigned permissionSets: ' + permissionSets + ' to user: ' + userId;
                dto.values.put('psas',permissionSetAssignments);
            } catch (Exception e) {
                dto.technicalMsg = e.getStackTraceString();
                dto.message = 'Error assigning permission set: ' + e.getMessage();
                System.debug(LoggingLevel.ERROR, e);
            }
        } else {
            dto.technicalMsg = 'No Permission Sets found with dev name(s):' + USER_PERMISSION_SET_NAMES;
        }
        return dto;
    }
    /**
     *
     * @param accountId
     * @param firstName
     * @param lastName
     * @param emailAddress
     * @param userName
     *
     * @return
     */
    @AuraEnabled
    public static ResponseDto insertPortalContact(  Id accountId,String firstName, String lastName,
                                                    String emailAddress, String userName ) {
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        User portalUser = ContactSvc.buildPortalUser(accountId,firstName,lastName,emailAddress,userName);
        Contact portalContact = ContactSvc.buildPortalContact(accountId,portalUser);

        try {
            insert portalContact;
            dto.isSuccess = true;
        } catch(Exception ex) {
            dto.message = ex.getMessage();
        }
        dto.values.put('portalContact',portalContact);
        return dto;
    }
    /**
     *
     * @param userId  The Id of the user to set.
     * @param pwType  [predefined, random, namedcred, storedencrypted]
     * @param emailAddresses if no email just send null.
     *
     * @return

     * @todo currently only support predefined type with no email sent.
     */
    @AuraEnabled
    public static ResponseDto setUserDefaultPwFuture(  Id userId, String pwType, List<String> emailAddresses) {
        ResponseDto dto = new ResponseDto();
        String pw;
        switch on pwType {

            when 'predefined' {
                pw = PORTAL_USER_DEFAULT_PW;
                setUserPassword( userId,pw,emailAddresses );
                dto.isSuccess = true;
                dto.technicalMsg = 'Fired setUserPassword as future invocation for userId:'+userId;
            }
            when 'random' {
                //  @todo probably better shit to do but depends on reqs.
                Blob blobKey = Crypto.generateAesKey(AES_KEY_SIZE );
                String key = EncodingUtil.convertToHex(blobKey);
                pw = key.substring(PW_LENGTH);
                if(emailAddresses != null && !emailAddresses.isEmpty()) {
                    setUserPassword(userId, pw, emailAddresses);
                } else {
                    dto.technicalMsg = 'You must supplied email addresses for type of predefined password';
                }
            }
            when 'namedcred' {
                //  @todo implemented named cred stuff Can we get the pw back on this?
            }
            when 'storedencrypted' {
                //  @todo assume it's stored somewhere encrypted. get key / unencrypt  / send
            }
            when else {
                dto.technicalMsg = 'unsupported pwType of : '+pwType;
            }
        }
        return dto;
    }

    /**
     *
     *
     * @param userId
     * @param pw
     * @param emailAddresses
     */
    @Future
    private static void setUserPassword( Id userId, String pw, List<String> emailAddresses) {
        try {
            System.setPassword(userId,pw);
            if(emailAddresses != null) {
                //@TODO fire email send via template or simple apex email
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,e);
        }
    }
}