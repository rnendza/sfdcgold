@IsTest
public with sharing class TestUtils {

    /**
     * Builds a community_user_setting__c sObject using userId,contactId as the key and populates
     * all field names that have 'display' in the api name that exist on the field sets with true.
     *
     * @param userId
     * @param ContactId
     * @return a Community_User_Setting__c sObject (not inserted / no id)
     */
    public static Community_User_Setting__c buildCommunityUserDisplaySetting(Id userId, Id ContactId) {

        Map<String,FieldSet> mFieldSets = SObjectType.Community_User_Setting__c.fieldSets.getMap();
        Set<String> allFsFields =  CommunityUserSettingsSvc.getAllFieldSetsFields(mFieldSets);
        Community_User_Setting__c cus = new Community_User_Setting__c();
        User u = [SELECT Id, Name FROM User where Id = :userId];
        cus.put('Name',u.Name + ' Setting');
        cus.put('User__c',userId);
        cus.put( 'Contact__c',contactId);
        for(String field : allFsFields) {
            if(field.contains('Display')) {
                cus.put(field,true);
            }
        }
        return cus;
    }

    /**
     * Originally meant to generate a globally unique User.CommunityNickName value but can, I guess, be used
     * for other fields assuming that field is large enough to hold the results.
     *
     * @param prefix A prefex. .if desired / otherwise replaces null with empty space ie ''.
     * @return a string with prefix  + org Id + timestamp + random value.
     * @see https://help.salesforce.com/articleView?id=000330466&language=en_US&type=1&mode=1
     */
    public static String  generateUniqueString( String prefix ) {
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        prefix = prefix == null ? '' : prefix;
        String uniqueName = prefix + orgId + dateString + randomInt;
        return uniqueName;
    }

    /**
     *
     *
     * @param dateToSearch  The date to start the leap year search with.
     * @return              The closest leap year to the date passed.
     */
    public static Integer findNextLeapYear( Date dateToSearch ) {
        Integer leapYear;
        if(dateToSearch == null) {
            return null;
        }
        Integer currentYear = dateToSearch.year();
        Boolean foundIt     = false;

        for( Integer i=0; !foundIt; i++ ) {
            if(Date.isLeapYear(currentYear)) {
                foundIt     = true;
                leapYear    = currentYear;
                break;
            } else {
                currentYear += 1;
            }
        }
        return leapYear;
    }
    /**
     *
     */
    public static void deleteAllHoldPerDays() {
        List<Hold_Per_Day__c> holdPerDays = [SELECT ID from Hold_Per_Day__c];
        delete holdPerDays;
    }
    /**
     * This is meant to be used for unit testing and replace logic in AggregateMachineHpd.
     * Beware if using in real world due to gov limits.
     *
     * @param startDate The Hold_Per_Day__c.Date__c to start with on the Daily HPD Record.
     * @param endDate   The Hold_Per_Day__c.Date__c to end with on the Daily HPD Record.
     *
     * @return          A List of newly inserted Hold_Per_Day__c sObjects.
     */
    public static List<Hold_Per_Day__c> aggregateDailyHoldPerDays(Date startDate, Date endDate) {

        List<AggregateResult> dailyArs          = new List<AggregateResult>();
        List<Hold_Per_Day__c> aggHoldPerDays    = new List<Hold_Per_Day__c>();

        Id dailyAggRtId = SObjectType.Hold_Per_Day__c.getRecordTypeInfosByDeveloperName().get('Daily_Aggregate').getRecordTypeId();
        Id dailyRtId    = SObjectType.Hold_Per_Day__c.getRecordTypeInfosByDeveloperName().get('Daily_HPD').getRecordTypeId();

        dailyArs = [
                SELECT      Account__c                  accountId,
                            Date__c                     hpdDate,
                            COUNT_DISTINCT(Asset__c)    assetCount,
                            SUM(NTI__c)                 revenueSum,
                            SUM(Funds_In__c)            fundsInSum,
                            SUM(Funds_Out__c)           fundsOutSum,
                            SUM(Amount_Played__c)       amtPlayedSum,
                            SUM(Amount_Won__c)          amtWonSum
                FROM        Hold_Per_Day__c
                WHERE       RecordTypeId            =  :dailyRtId
                AND         Date__c                 >= :startDate
                AND         Date__c                 <= :endDate
                GROUP BY    Account__c,
                            Date__c
        ];
        for (AggregateResult ar : dailyArs) {
            Hold_Per_Day__c holdPerDay = new Hold_Per_Day__c();
            holdPerDay.account__c       = (Id) ar.get('accountId');
            holdPerDay.Date__c          = (Date) ar.get('hpdDate');
            holdPerDay.vgt_count__c     = (Integer) ar.get('assetCount');
            holdPerDay.NTI__c           = (Decimal) ar.get('revenueSum');
            holdPerDay.Funds_In__c      = (Decimal) ar.get('fundsInSum');
            holdPerDay.Funds_Out__c     = (Decimal) ar.get('fundsOutSum');
            holdPerDay.Amount_Played__c = (Decimal) ar.get('amtPlayedSum');
            holdPerDay.Amount_Won__c    = (Decimal) ar.get('amtWonSum');
            holdPerDay.RecordTypeId     = dailyAggRtId;
            aggHoldPerDays.add(holdPerDay);
        }
        if(!aggHoldPerDays.isEmpty()) {
            insert aggHoldPerDays;
        }
        for(Hold_Per_Day__c aggHoldPerDay : aggHoldPerDays) {
            System.debug('accel dailyAgg='+aggHoldPerDay);
            System.debug(aggHoldPerDay);
        }
        return aggHoldPerDays;
    }

    /**
     * @param rtName    The record type name of the Hold_Per_Day__C sObjects in memory.
     * @param newDate   The new date to flag Hold_Per_Day__c.Date__c with.
     * @return          A List of newly updated Hold_Per_Day__c sObjects.
     */
    public static List<Hold_Per_Day__c> updateAllHoldPerDaysDate(String rtName, Date newDate) {
        List<Hold_Per_Day__c>  holdPerDays = [
                SELECT Id, Date__c, Account__c, RecordTypeId, HPD__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.Name = :rtName
        ];
        if(rtName.contains('Monthly')) {
            newDate = newDate.toStartOfMonth();
        }
        for(Hold_Per_Day__c holdPerDay : holdPerDays) {
            holdPerDay.Date__c = newDate;
        }
        update holdPerDays;
        return holdPerDays;
    }
    /**
     *
     *
     * @param rtName    The recordType name of the Hold_Per_Day__c sObjects to look for.
     * @param newDate   The new Date to set the cloned Hold_Per_Day__c.Date__c field with.
     *
     * @return          A list of newly inserted Hold_Per_Day__c records.
     */
    public static List<Hold_Per_Day__c> cloneAndCreateHoldPerDays(String rtName, Date newDate) {
        List<Hold_Per_Day__c> insertedHoldPerDays = new List<Hold_Per_Day__c>();

        List<Hold_Per_Day__c>  holdPerDays = [
                SELECT Id, Date__c, Account__c, RecordTypeId, HPD__c,Funds_In__c,Funds_Out__c,Location_Share__c,
                        Amount_Played__c,Amount_Won__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.Name = :rtName
        ];
        for(Hold_Per_Day__c holdPerDay : holdPerDays) {
            Hold_Per_Day__c clonedHpd = holdPerDay.clone(false, false, false, false);
            clonedHpd.Date__c = newDate;
            insertedHoldPerDays.add(clonedHpd);
        }
        insert insertedHoldPerDays;
        return insertedHoldPerDays;
    }

    /**
     * There is probably some process builder or Flow something ... grrrr. that is forcing a newly inserted
     * Live Accel Account back to a Prospect.. Annoying AF.. anyway update to get back to accel account.
     * @param accounts
     * @return updated accounts
     */
    public static List<Account> updateAccountsToLiveAccelAccount(List<Account> accounts) {
        for (Account account : accounts) {
            account.Accel_VGT_Live_Date__c = Date.today();
            account.Type = 'Accel Account';
        }
        update accounts;
        return accounts;
    }

    /**
     * Use sample solution data to build (not insert Soluntion__c sObjects)
     * @return a List of Solution__c sObjects (not yet inserted);
     * @TODO this needs to be made real but we can't do with Solution__c hanging around.
     */
    public static List<Solution__c> buildServiceSolutions() {
        List<Solution__c> solutions = new List<Solution__c>();
        Integer iNumSolutions = 1;

        for(Integer i = 0; i<iNumSolutions; i++) {
            String label = 'Turned printer on';
            solutions.add(new Solution__c(Name = label,  Status__c = 'Active'));
        }
        return solutions;
    }

    /**
     * Inserts a Role and and User and
     *
     * @param uName
     * @param roleName
     *
     * @return User record.
     */
    public static User createAdminUserWithRole(String uName, String roleName) {
        UserRole adminRole = new UserRole(DeveloperName = roleName, Name = roleName);
        insert adminRole;
        User adminUser = getUserForTest(uName);
        adminUser = [select id, userroleid,accountId,contactId from user where id = :adminUser.id];
        adminUser.userroleid = adminRole.id;
        update adminUser;
        return adminUser;
    }
    public static Account updateCommunityAccountWithTypeandIGBLicenseNumber(String profileName, String accountName, String uName) {
        User user = getPortalUserForTest(profileName,accountName,uName);
        Contact contact = [select id,accountId from contact where id = :user.contactId];
        Account account = [select id, IGB_License__c,type from account where id = :contact.AccountId];
        account.IGB_License__c = '6666666';
        account.type = 'Accel Account';
        update account;
        return account;
    }
    public static Contact buildContact(Id accountId, String lastName) {
        Contact contact  = new Contact();
        contact.LastName = lastName;
        contact.accountid = accountId;
        return contact;
    }
    /**
     * Creates a PermissonSet and PermissonSetAssignment sObject and guards against dups already existing in the target org.
     *
     * @param psLabel
     * @param psApiName
     * @param userId
     */
    public static PermissionSetAssignment createPermissionSetAndAssignment(String psLabel, String psApiName, Id userId) {
        PermissionSet ps = buildPermissionSet(psLabel,psApiName);
        try {
            insert ps;
        } catch (DmlException dmlEx) {
           if(dmlEx.getMessage().contains('DUPLICATE_DEVELOPER_NAME')) {
               ps = [SELECT Id,Name FROM PermissionSet WHERE Name = :psApiName];
           }
        }
        PermissionSetAssignment psa = buildPermissionSetAssignment(psApiName,userId);
        try {
            insert psa;
        }  catch (DmlException dmlEx) {
            if(dmlEx.getMessage().contains('DUPLICATE_VALUE')) {
                psa = [
                        SELECT  Id,AssigneeId,PermissionSetId
                        FROM    PermissionSetAssignment
                        WHERE   AssigneeId = :userId
                        AND     PermissionSetId  = :ps.Id
                ];
            }
        }
        return psa;
    }

    public static PermissionSet buildPermissionSet( String label, String apiName) {
        PermissionSet ps = new PermissionSet(Label=label,Name=apiName);
        return ps;
    }
    /**
     *
     * @param permissionSetApiName
     * @param userId
     *
     * @return
     */
    public static PermissionSetAssignment buildPermissionSetAssignment( String permissionSetApiName, Id userId) {
        PermissionSetAssignment psa;
        List<PermissionSet> pss = [SELECT Id FROM PermissionSet WHERE Name = :permissionSetApiName];
        if(!pss.isEmpty()) {
            PermissionSet ps = pss[0];
            psa = new PermissionSetAssignment(AssigneeId = userId, PermissionSetId = ps.Id);
        }
        return psa;
    }
    /**
     *
     *
     * @param cpProfileName
     * @param accountName
     * @param userName
     *
     * @return
     */
    public static User getPortalUserForTest(String cpProfileName, String accountName, String userName) {

        List<User> existingUsers = [select id, name, lastname,accountId,contactId from User where isactive = true and username = :userName];
        if(!existingUsers.isEmpty()) {
            return existingUsers[0];
        }

        Account account = new Account();
        account.name = accountName +generateRandomString(10);
        insert account;
        system.assertNotEquals(null, account.Id);
        system.debug('account created');

        // create test contact
        String userEmail = generateRandomString(5) + '@accelentertainment.com';
        system.debug('creating test contact...');
        Contact contact = new Contact();
        contact.firstName = generateRandomString(10);
        contact.lastName = generateRandomString(10);
        contact.email = userEmail;
        contact.accountid = account.id;
        insert contact;

        User user = new User();
        // populate the record
        user.emailencodingkey='UTF-8';
        user.languagelocalekey='en_US';
        user.localesidkey='en_US';
        user.timezonesidkey='America/Chicago';
        user.Alias = generateRandomString(5);
        user.email = userEmail;
        user.lastname = generateRandomString(10);
        user.username = userName;
        user.ContactId = contact.id;
        user.ProfileId = [select id from Profile where Name = :cpProfileName].Id;
        //-----------------------------------user.UserRoleId = [select id from UserRole where name = :roleName ].id;

        // insert the record
        insert user;
        System.assertNotEquals(null, user.Id);
        return user;
    }

    /**
     *
     *
     * @param cpProfileName
     * @param accountName
     * @param userName
     * @param iNumUsers
     *
     * @return
     */
    public static List<User> createPortalUsersForTest(String cpProfileName, String accountName, String userName,Integer iNumUsers) {
        Municipality__c muni = createMunicipalities('Test muni',1)[0];
        Account account = buildAccount(accountName,muni.Id);
        insert account;

        List<Contact> contacts = new List<Contact>();


        // create test contact
        for(Integer i=0; i<iNumUsers; i++) {
            String userEmail = generateRandomString(5) + '@accelentertainment.com';
            Contact contact = new Contact();
            contact.firstName = generateRandomString(10);
            contact.lastName = generateRandomString(10);
            contact.email = userEmail;
            contact.accountid = account.id;
            contacts.add(contact);
        }
        insert contacts;

        Map<Id,Profile> mProfilesByIds = new Map<Id,Profile> ([
           SELECT Id, Name
           FROM   Profile
        ]);
        Map<String,Id> mProfileIdByName = new Map<String,Id>();
        for(Id profileId : mProfilesByIds.keySet()) {
            Profile profile = mProfilesByIds.get(profileId);
            mProfileIdByName.put(profile.Name, profile.Id);
        }

        List<User> users = new List<User>();
        for(Contact contact : contacts) {
            User user = new User();
            user.emailencodingkey = 'UTF-8';
            user.languagelocalekey = 'en_US';
            user.localesidkey = 'en_US';
            user.timezonesidkey = 'America/Chicago';
            user.Alias = generateRandomString(5);
            user.email = contact.email;
            user.lastname = generateRandomString(10);
            user.username = generateRandomString(10) + userName;
            user.ContactId = contact.id;
            //user.ProfileId = [select id from Profile where Name = :cpProfileName].Id
            user.ProfileId = mProfileIdByName.get( cpProfileName );
            users.add(user);
        }
        insert users;
        return users;
    }
    /**
     * Ensures an actual insert of a user as opposed to trying to find an existing one
     * and returning that as opposed to insert.
     *
     * @param uname
     *
     * @return
     */
    public static User createUserForTest(String uname) {
        User user = new User();
        // populate the record
        user.emailencodingkey='UTF-8';
        user.languagelocalekey='en_US';
        user.localesidkey='en_US';
        user.timezonesidkey='America/Chicago';
        user.Alias = generateRandomString(5);
        user.email = uname;
        user.lastname = generateRandomString(10);
        user.username = uname;
        user.ProfileId = [select id from Profile where Name = 'System Administrator'].Id;
        //-----------------------------------user.UserRoleId = [select id from UserRole where name = :roleName ].id;

        // insert the record
        insert user;
        return user;
    }
    /**
     * Queries for the user for passed uName.
     *
     * @param uName the username.
     * @return A User Object if found, otherwise null.
     */
    public static User getUserForTest(String uName) {
        SecSettings sec = new SecSettings('',uName,'','','');
        return getUserForTest(sec,null);
    }
    /**
     * Defaults to an insert
     *
     * @param secSettings
     * @param dtTstStart
     * @param isActiveUser
     *
     * @return
     */
    public static User getUserForTest(SecSettings secSettings, Datetime dtTstStart, Boolean isActiveUser) {
        return getUserForTest(secSettings,dtTstStart,isActiveUser,true);
    }

    /**
     * Overload of legacy getUserForTest with addition of isActiveUser
     *
     * @param secSettings
     * @param dtTstStart
     * @param isActiveUser
     * @param doInsert       If true insert the user, if false merely return the sObject back for bulk insert later.
     *
     * @return
     */
    public static User getUserForTest(SecSettings secSettings, Datetime dtTstStart, Boolean isActiveUser, Boolean doInsert) {
        list<User> lstUsr = null;
        if (secSettings.us.length() == 0 && secSettings.uName.length() == 0 && secSettings.pr.length() == 0 && secSettings.rl.length() == 0 && secSettings.pm.length() == 0) {
            // for future use lstUsr = [select id, name, lastname from User where isactive = true and id = :UserInfo.getUserId()];
        } else if (secSettings.us.length() > 0) {
            // for future use lstUsr = [select id, name, lastname from User where isactive = true and id = :secSettings.us];
        } else if (secSettings.uName.length() > 0) {
            lstUsr = [select id, name, lastname from User where isactive = true and username = :secSettings.uName];
        }
        if (lstUsr != null && !lstUsr.isEmpty()) {
            return lstUsr[0];
        }
        Double x = Math.random() * 10000;
        String rd = String.valueOf(Integer.valueOf(x));
        User usr = new User();
        usr.FirstName = 'testfirstopmem';
        usr.LastName = 'testlastopmem';
        usr.EmailEncodingKey = 'ISO-8859-1';
        usr.Email = 'info@ext-it.com';
        usr.Alias = rd;
        usr.TimeZoneSidKey = 'America/Los_Angeles';
        if (secSettings.uName.length() > 0) {
            usr.username = secSettings.uName;
        } else {
            // for future use usr.Username = 'somenam' + rd + '@ext-it.com';
        }
        usr.LanguageLocaleKey = 'en_US';
        usr.LocaleSidKey = 'en_US';
        //  https://accel-entertainment.monday.com/boards/284140049/pulses/311330539
        usr.CommunityNickname = generateUniqueString('NN');
       // usr.CommunityNickname = 'NN' + rd;
        usr.IsActive = isActiveUser;
        if (secSettings.pr.length() > 0) {
            //for future use usr.ProfileId = secSettings.pr;
        } else {
            usr.ProfileId = UserSvc.getProfileByName('System Administrator').id;
        }
        if (secSettings.rl.length() > 0) {
            // for future use usr.UserRoleId = secSettings.rl;
        }
        if(doInsert) {
            insert usr;
        }
        if (secSettings.pm.length() > 0) {
            //for future use
//            PermissionSetAssignment psa = new PermissionSetAssignment();
//            psa.AssigneeId = usr.Id;
//            psa.PermissionSetId = secSettings.pm;
//            insert psa;
        }
        return usr;
    }
    /**
     * Retrieves user using SecSettings.uName
     *
     * @param secSettings - Nested class containing user information
     * @param dtTstStart
     *
     * @return A User object if found, otherwise null.
     */
    public static User getUserForTest(SecSettings secSettings, Datetime dtTstStart) {
        return getUserForTest(secSettings,dtTstStart,true);
    }

    public static EmailTemplate buildEmailTemplate(String name,String devName, String type, Id folderId,String subject) {
        EmailTemplate validEmailTemplate = new EmailTemplate();
        validEmailTemplate.isActive = true;
        validEmailTemplate.Name = name;
        validEmailTemplate.DeveloperName = devName;
        validEmailTemplate.TemplateType = type;
        validEmailTemplate.FolderId = folderId;
        validEmailTemplate.Subject = subject;
        return  validEmailTemplate;
    }
    /**
     * Creates Accel_Time_Edit__c instance for the passed user.
     * @param setupOwner  the user to create the heirarchical setting with.
     */
    public static void createAccelTimeEditSettings(User setupOwner) {
        LIST<sObject> sObjs = new LIST<sObject>();
        String settingName = 'Accel_Time_Edit__c ' + setupOwner.id;
        sObjs.add(new Accel_Time_Edit__c(Name = settingName, SetupOwnerId = setupOwner.Id, Debug_Console__c = true));
        insert sObjs;
    }
    /**
     * Creates Service_Utility_Bar_Config__c instance for the passed user.
     * @param setupOwner  the user to create the hierarchical setting with.
     */
    public static void createSvcWatchdogUtilityBarSettings(User setupOwner) {
        List<SObject> sObjs = new List<SObject>();
        String settingName = 'Service_Utility_Bar_Config__c ' + setupOwner.Id;
        sObjs.add(new Service_Utility_Bar_Config__c(Name = settingName, SetupOwnerId = setupOwner.Id, Debug_Console__c = true));
        insert sObjs;
    }
    /*
    public static Account buildAccount(String accountName) {
        return buildAccount(accountName,null);
    }
    */
    public static Account buildAccount(String accountName, Id muniId) {
      return buildAccount(accountName,muniId,null);
    }
    public static Account buildAccount(String accountName, Id muniId, String accountType) {
        Account a = new Account(name = accountName);
        a.MunicipalityLookup__c = muniId;
        a.type = accountType;
        return a;
    }
    public static Opportunity buildOpportunity(Account account) {
        String oppName = 'Opp for loc: ' + account.name;
        Id accountId = account.Id;
        String stageName = 'New';
        Date closeDate = System.today();
        return buildOpportunity(accountId,oppName,stageName,closeDate);
    }
    public static Opportunity buildOpportunity(Id accountId, String oppName, String stageName, Date closeDate) {
        Opportunity opp = new Opportunity();
        opp.Name = oppName;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        opp.StageName = stageName;
        opp.CloseDate = closeDate;
        opp.AccountId = accountId;
        return opp;
    }
    public static Case createCase(String caseSubject, Id assetId) {
        Id rtId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName().get('Call_Center').getRecordTypeId();
        Case cse = new Case(subject = caseSubject,recordtypeId = rtId, AssetId = assetId);
        insert cse;
        return cse;
    }
    public static Case buildCase(String caseSubject, String recordTypeDevName, Id assetId,Id accountId) {
        Id rtId = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosByDeveloperName()
                                            .get(recordTypeDevName).getRecordTypeId();
        Case cse = new Case(subject = caseSubject,recordtypeId = rtId, AssetId = assetId, AccountId = accountId);
        return cse;
    }
    public static Asset buildAsset(String assetName, Id accountId, String rtName) {
        Id rtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get(rtName).getRecordTypeId();
        Asset asset = new Asset(name = assetName,recordtypeId = rtId, model__c = 'asset model '+assetName);
        /**
         * RJN Added 9/29 to abide by new val rule added on Asset.SAS__c. ie
         * FIELD_CUSTOM_VALIDATION_EXCEPTION, SAS Positions are limited to &quot;1, 2, 3, 4, 5, 6, 7, 8, 9, 10, RT1,
         * RT2&quot;.: [SAS__c]
         */
        if(rtName == 'VGT') {   //  @TODO Is this value rule only for VGT RTs or for all Asset Record Types?
            asset.Sas__c = '1';
        }
        if(accountId != null) {
            asset.accountId  = accountId;
        }
        return asset;
    }

    public static Asset createAsset(String assetName) {
        Id rtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName().get('VGT').getRecordTypeId();
        Asset asset = new Asset(name = assetName,recordtypeId = rtId);
        /**
        * RJN Added 9/29 to abide by new val rule added on Asset.SAS__c. ie
        * FIELD_CUSTOM_VALIDATION_EXCEPTION, SAS Positions are limited to &quot;1, 2, 3, 4, 5, 6, 7, 8, 9, 10, RT1,
        * RT2&quot;.: [SAS__c]
        */
        //  @TODO Is this value rule only for VGT RTs or for all Asset Record Types?
        asset.Sas__c = '1';

        insert asset;
        return asset;
    }
    public static void createHpdAssociatedProducts(List<Hold_Per_Day__c> hpds) {
        List<Product2> newProducts = new List<Product2>();
        Integer i = 0;
        for(Hold_Per_Day__c hpd : hpds) {
            Product2 p = new Product2(name = 'Product '+i, asset_model_name__c = hpd.asset__r.model__c, family = 'ASSET');
            newProducts.add(p);
        }
        insert newProducts;
    }
    /*
    public static List<Account> createAccounts(String accountName, Integer iNumAccts) {
        List<Account> testAccts = new List<Account>();
        for (Integer i = 0; i < iNumAccts; i++) {
            testAccts.add(new Account(Name = accountName + i));
        }
        insert testAccts;
        return testAccts;
    }
    */
    public static List<Municipality__c> createMunicipalities(String muniName, Integer iNumMunis) {
        List<Municipality__c> municipalities = new List<Municipality__c>();
        for (Integer i = 0; i < iNumMunis; i++) {
            municipalities.add(new Municipality__c(Name = muniName + i, State__c = 'IL'));
        }
        insert municipalities;
        return municipalities;
    }
    /**
     *
     *
     * @param accountName  The Name of the account (will be suffixed by the increment inserted)
     * @param iNumAccts  The Number of accounts to create.
     * @param contactLastName The last name of the contact.
     */
    public static void createAccountsAndContacts(String accountName, Integer iNumAccts, String contactLastName) {
//        // Create common test Resellers
//        List<Account> testAccts = new List<Account>();
//        for (Integer i = 0; i < iNumAccts; i++) {
//            testAccts.add(new Account(Name = accountName + i));
//        }
//        insert testAccts;
//        // Create common test Contacts
//        List<Contact> testContacts = new List<Contact>();
//        for (Account acct : testAccts) {
//            Contact c = new Contact(lastname = contactLastName + acct.name, accountid = acct.id);
//            testContacts.add(c);
//        }
//        insert testContacts;
    }
    public static void createTestHoldPerDays() {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni',2);
        List<Account> accounts = new List<Account>();
        Integer i = 0;
        for(Municipality__c municipality : municipalities) {
            accounts.add(TestUtils.buildAccount('accel test acct:'+i + 'a', municipality.id,'Accel Account'));
            accounts.add(TestUtils.buildAccount('accel test acct:'+i + 'b', municipality.id,'Competitor Account'));
            i++;
        }
        insert accounts;
        List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(accounts, 1,'Monthly HPD');
        holdPerDays.addAll(TestUtils.buildAccountHoldPerDays(accounts,1,'Daily HPD'));
        system.debug('about to insert... hold per day num of recs='+holdPerDays);
        insert holdPerDays;
        system.debug('rick in createtesthpds. monthly hpds inserted=');
        system.debug(holdPerDays);

        List<Asset> assets = new List<Asset>();
        i = 0;
        for(Account account : accounts) {
            assets.add(buildAsset(account.name+' asset '+i,account.id, 'VGT'));
            i++;
        }
        insert assets;
        List<Hold_Per_Day__c> holdPerDaysAssets = TestUtils.buildAssetHoldPerDays(assets, 2,'Daily HPD');
        //holdPerDays.addAll(TestUtils.buildAccountHoldPerDays(accounts,1,'Daily HPD'));
        system.debug('about to insert... hold per day for assets num of recs='+holdPerDaysAssets);
        insert holdPerDaysAssets;
    }
    /**
     *
     *
     * @param iNumHpdsPerAccount  number of hold per day records per account to create
     * @TODO
     */
    public static void createTestHoldPerDays(Integer iNumHpdsPerAccount) {
        List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni',2);
        List<Account> accounts = new List<Account>();
        Integer i = 0;
        for(Municipality__c municipality : municipalities) {
            accounts.add(TestUtils.buildAccount('accel test acct:'+i + 'a', municipality.id,'Accel Account'));
            accounts.add(TestUtils.buildAccount('accel test acct:'+i + 'b', municipality.id,'Competitor Account'));
            i++;
        }
        insert accounts;
        List<Hold_Per_Day__c> holdPerDays = TestUtils.buildAccountHoldPerDays(accounts, iNumHpdsPerAccount,'Monthly HPD');
        holdPerDays.addAll(TestUtils.buildAccountHoldPerDays(accounts,iNumHpdsPerAccount,'Daily HPD'));
        system.debug('about to insert... hold per day num of recs='+holdPerDays);
        insert holdPerDays;
        system.debug('rick in createtesthpds. monthly hpds inserted=');
        system.debug(holdPerDays);

        List<Asset> assets = new List<Asset>();
        i = 0;
        for(Account account : accounts) {
            assets.add(buildAsset(account.name+' asset '+i,account.id, 'VGT'));
            i++;
        }
        insert assets;
        List<Hold_Per_Day__c> holdPerDaysAssets = TestUtils.buildAssetHoldPerDays(assets, 2,'Daily HPD');
        //holdPerDays.addAll(TestUtils.buildAccountHoldPerDays(accounts,1,'Daily HPD'));
        system.debug('about to insert... hold per day for assets num of recs='+holdPerDaysAssets);
        insert holdPerDaysAssets;
    }
    /**
     *
     *
     * @param accounts
     * @param iNumPerAcct
     * @param rtName
     *
     * @return
     */
    public static List<Hold_Per_Day__c> buildAccountHoldPerDays(List<Account> accounts, Integer iNumPerAcct, String rtName) {
        List<Hold_Per_Day__c> holdPerDays = new List<Hold_Per_Day__c>();
        Id rtId = Schema.SObjectType.Hold_Per_Day__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        for(Account account : accounts) {
            for(Integer i = 0; i<iNumPerAcct; i++) {
                Integer x = i+1; //get rid of zero idx
                Hold_Per_Day__c holdPerDay = new Hold_Per_Day__c();
                holdPerDay.RecordTypeId = rtId;
                holdPerDay.account__C = account.id;
                holdPerDay.Date__c = System.today().addMonths( -i );
                holdPerDay.VGT_Count__c = 5;
                holdPerDay.Amount_Played__c = x * 1000;
                holdPerDay.Amount_Won__c = holdPerDay.Amount_Played__c * .8;
                holdPerDay.Funds_In__c = holdPerDay.Amount_Played__c;
                holdPerDay.Funds_Out__c = holdPerDay.Amount_Won__c;
                holdPerDay.hpd__c = holdPerDay.Funds_In__c - holdPerDay.funds_out__c;

                holdPerDays.add(holdPerDay);
            }
        }
        return  holdPerDays;
    }
    public static List<Hold_Per_Day__c> buildAssetHoldPerDays(List<Asset> assets, Integer iNumPerAsset, String rtName) {
        List<Hold_Per_Day__c> holdPerDays = new List<Hold_Per_Day__c>();
        Id rtId = Schema.SObjectType.Hold_Per_Day__c.getRecordTypeInfosByName().get(rtName).getRecordTypeId();
        for(Asset asset : assets) {
            for(Integer i = 0; i<iNumPerAsset; i++) {
                Hold_Per_Day__c holdPerDay = new Hold_Per_Day__c();
                holdPerDay.RecordTypeId = rtId;
                holdPerDay.account__C = asset.accountId;
                holdPerDay.asset__c = asset.id;
                holdPerDay.Date__c = System.today().addMonths( -i );
                holdPerDay.Amount_Played__c = i * 1000;
                holdPerDay.Amount_Won__c = holdPerDay.Amount_Played__c * .8;
                holdPerDay.Funds_In__c = holdPerDay.Amount_Played__c;
                holdPerDay.Funds_Out__c = holdPerDay.Amount_Won__c;
                holdPerDays.add(holdPerDay);
            }
        }
        return  holdPerDays;
    }
    public static License__c buildLicense(  Id accountId, Id rtId, Date licenseExpDate,
                                            Date licenseOrigIssueDate, String licenseNumber) {
        License__c license = new License__c( location__c = accountId, expiration_date__c = licenseExpDate,
                                             license_original_issue_date__c = licenseOrigIssueDate, recordTypeId = rtId,
                                             name = licenseNumber ) ;
        return license;
    }
    public static License__c buildGenericIgbLicense(Id accountId) {
        Date licenseExpDate = Date.today().addMonths(12);
        Date licenseOrigIssueDate = Date.today().addMonths(-12);
        String igbLicenseNumber = generateRandomString(8);
        Id rtId = Schema.getGlobalDescribe().get('License__c').getDescribe().getRecordTypeInfosByDeveloperName().get('IGB_Gaming_License').getRecordTypeId();
        return buildLicense(accountId,rtId, licenseExpDate,licenseOrigIssueDate,igbLicenseNumber);
    }
    /**
     *
     *
     * @param expirationDate
     * @param recordTypeName
     *
     * @return  a Licence__c sObject (not inserted).
     */
    public static License__c buildLicense( Date expirationDate, String recordTypeName) {
        Id rtId = Schema.SObjectType.License__c.getRecordTypeInfosByName().get(recordTypeName).getRecordTypeId();
        return buildLicense(null,rtId,expirationDate,null,generateRandomString(8));
    }

    /**
     *
     *
     * @param name
     * @param timeZone
     * @param iNumRecords
     *
     * @return
     */
    public static List<OperatingHours> buildOppHours(String name, String timeZone, Integer iNumRecords) {
        List<OperatingHours> ohs = new List<OperatingHours> ();
        for(Integer i=0; i < iNumRecords; i++) {
            ohs.add(new OperatingHours( name=name+i,TimeZone=timeZone )) ;
        }
        return ohs;
    }
    public static List<WorkType> buildWorkTypes(Set<String> workTypeNames,Decimal estimatedDuration, String durationType) {
        List<WorkType> workTypes = new List<WorkType> ();
        for(String workTypeName : workTypeNames) {
            workTypes.add(new WorkType(name=workTypeName,estimatedDuration = estimatedDuration, durationType = durationType));
        }
        return workTypes;
    }
    /**
     *
     *
     * @param name
     * @param timeZone
     * @param iNumRecords
     *
     * @return
     */
    public static TimeSlot buildTimeSlot(OperatingHours oh, String dayOfWeek, Time startTime, Time endTime, String type) {
        TimeSlot timeSlot = new TimeSlot(OperatingHoursId = oh.id, DayOfWeek = dayOfWeek, StartTime = startTime, EndTime = endTime, Type = type);
        return timeSlot;
    }
    public static ServiceResource buildSingleServiceResource(String name, Id uId) {
        return new ServiceResource( name=name,Accel_User__c=uId,RelatedRecordId = uId, ResourceType = 'T',IsActive=true );
    }
    public static List<ServiceResource> buildServiceResource( String name, Id uId ) {
        List<ServiceResource> srs = new List<ServiceResource>();
        srs.add( buildSingleServiceResource(name,uId ));
        return srs;
    }
    public static List<ServiceTerritory> buildServiceTerritories(String name, Id oppHoursId, Integer iNumRecords) {
        List<ServiceTerritory> sts = new List<ServiceTerritory> ();
        for(Integer i=0; i < iNumRecords; i++) {
            sts.add(new ServiceTerritory(name = name + i, OperatingHoursId = oppHoursId, IsActive = true));
        }
        return sts;
    }
    public static List<FSL__User_Territory__c> buildUserTerritories(Id userId, Set<Id> serviceTerritoryIds, String accelRole) {
        List<FSL__User_Territory__c> userTerritories = new List<FSL__User_Territory__c>();
        for(Id stId : serviceTerritoryIds) {
            FSL__User_Territory__c ut = new FSL__User_Territory__c(FSL__User__c = userId, FSL__ServiceTerritory__c = stId, Accel_Role__c = accelRole);
            userTerritories.add(ut);
        }
        return userTerritories;
    }
    public static ServiceTerritoryMember buildServiceTerritoryMember(Id serviceResourceId, Id serviceTerritoryId, Id oppHoursId, String territoryType,
                                                                     DateTime startDatetime, DateTime endDatetime) {
        ServiceTerritoryMember stm = new ServiceTerritoryMember(ServiceResourceId=serviceResourceId, ServiceTerritoryId=serviceTerritoryId,
                                                                OperatingHoursId=oppHoursId, TerritoryType=territoryType,
                                                                EffectiveStartDate=startDatetime);
        //EffectiveEndDate = endDatetime
        return stm;
    }
    /**
     *  @TODO Lots of work to be done here. this is hacked up initially but really needs to be cleaned up.
     */
    public static void createMemberTimeSlots(String uName) {
        Datetime dtTstStart = Datetime.now();
        TestUtils.SecSettings sec = new TestUtils.SecSettings('', UNAME, '', '', '');
        User u = TestUtils.getUserForTest(sec, dtTstStart);
        List<OperatingHours> ohs = TestUtils.buildOppHours('Accel test opp hours', 'America/Chicago',2);
        insert ohs;
        List<ServiceResource> srs = TestUtils.buildServiceResource(u.firstname + ' ' + u.lastname, u.Id);
        insert srs;
        List<ServiceTerritory> sts = TestUtils.buildServiceTerritories('Accel Test Territory Name ',ohs[0].id,2);

        for(ServiceTerritory st : sts) {
            st.name = 'All Regions';
            break;
        }
        insert sts;
        set<id> stIds = new set<id>();
        for(ServiceTerritory st : sts) {
            stIds.add(st.id);
        }
        List<FSL__User_Territory__c> userTerritories = TestUtils.buildUserTerritories(u.id,stIDs,'Supervisor');
        insert userTerritories;

        List<ServiceTerritoryMember> serviceTerritoryMembers = new List<ServiceTerritoryMember>();
        Integer i = 0;
        // for(ServiceTerritory st : sts) {
        ServiceTerritory st = sts[0];
        DateTime startDatetime = System.now();
        DateTime endDateTime = startDatetime.addDays(1);
        serviceTerritoryMembers.add(TestUtils.buildServiceTerritoryMember(srs[0].id,st.id, ohs[0].id,'P',startDatetime,endDateTime));
        //   i++;
        //}
        insert serviceTerritoryMembers;
        List<TimeSlot> timeSlots = new List<TimeSlot>();
        TimeSlot ts = TestUtils.buildTimeSlot(ohs[0],'Monday',Time.newInstance(1, 2, 3, 0),Time.newInstance(6, 2, 3, 0),'Normal');
        insert ts;

        TestUtils.createAccelTimeEditSettings(u);
    }
    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * service appointments and ties them all together.
     *
     * If you desired defaults simply pass in a newly constructed TestSvcAppointmentsDataParams. If you need to customize,
     * construct TestSvcAppointmentDataParams and call it's settings to modify before calling this.
     *
     * @param params   A TestSvcAppointmentDataParms instance.
     */
    public static void createAllDataToServiceAppointments( TestSvcAppointmentDataParams params ) {
        System.assert(params != null);

        //---------- CREATE MUNIS
        List<Municipality__c> municipalities = TestUtils.createMunicipalities(params.muniNamePrefix, params.iNumMunis);

        List<Account> accounts = new List<Account>();
        for (Municipality__c municipality : municipalities) {
            for (Integer i = 0; i < params.iNumAccountsPerMuni; i++) {
                Account account = TestUtils.buildAccount(   params.accountNamePrefix + i + 'a', municipality.id,
                                                            params.accountType);
                account.Accel_VGT_Live_Date__c = Date.today();
                accounts.add(account);
            }
        }
        //---------- CREATE ACCOUNTS
        insert accounts;
        accounts = [SELECT Id,Name from Account];
        System.assert(accounts.size() == params.iNumAccountsPerMuni * params.iNumMunis);

        List<WorkType> workTypes = TestUtils.buildWorkTypes(params.workTypeNames, params.workTypeEstDuration,
                                                            params.workOrderDurationType);
        //---------- CREATE WORKTYPES
        insert workTypes;
        workTypes = [SELECT Id FROM WorkType];
        System.assert(workTypes.size() == params.workTypeNames.size());

        List<Asset> assets = new List<Asset>();
        for (Account account : accounts) {
            for(Integer i = 0; i<params.iNumAssetsPerAccount; i++) {
                Asset ass = TestUtils.buildAsset(params.assetNamePrefix, account.id, params.assetRecordTypeName);
                assets.add(ass);
            }
        }
        //---------- CREATE ASSETS
        insert assets;
        assets = [SELECT Id, AccountId,Name FROM Asset];
        system.assert(assets.size() == params.iNumAccountsPerMuni * params.iNumMunis * params.iNumAssetsPerAccount);
        Map<Id, List<Asset>> mAccountId_Assets = new Map<Id, List<Asset>>();
        for (Asset ass : assets) {
            if (!mAccountId_Assets.containsKey(ass.AccountId)) {
                mAccountId_Assets.put(ass.accountId, new List<Asset>{ass});
            } else {
                List<Asset> accountAssets = mAccountId_Assets.get(ass.AccountId);
                accountAssets.add(ass);
            }
        }
        //---------- CREATE OPERATING HOURS
        List<OperatingHours> ohs = TestUtils.buildOppHours(params.oppHrNameNamePrefix,params.timeZone, params.iNumOppHours);
        insert ohs;
        ohs = [SELECT Id,Name from OperatingHours];
        system.assert(ohs.size() == params.iNumOppHours);

        //---------- CREATE SERVICE TERRITORIES
        List<ServiceTerritory> serviceTerritories = new List<ServiceTerritory>();
        for (OperatingHours oh : ohs) {
            serviceTerritories.addAll(TestUtils.buildServiceTerritories(params.serviceTerritoryNamePrefix + ' :'+ oh.Name,
                    oh.id, params.iNumServiceTerritoriesPerOppHours));
        }
        insert serviceTerritories;
        serviceTerritories = [SELECT Id From ServiceTerritory];
        System.assert(serviceTerritories.size() == params.iNumOppHours * params.iNumServiceTerritoriesPerOppHours);

        //---------- CREATE CASES
        List<Case> cases = new List<Case>();
        String caseRtDevName = params.caseRecordTypeName;
        for (Account a : accounts) {
            List<Asset> accountAssets = mAccountId_Assets.get(a.id);
            for (Asset ass : accountAssets) {
                Case cse = TestUtils.buildCase( params.caseSubjectPrefix +' for act:' + a.name + '.asset=' + ass.name,
                                                caseRtDevName, ass.id, a.id);
                // cse.Service_Category__c = 'Vgt';
                cse.Status = params.caseStatus;
                cse.Work_Type__c = workTypes[0].Id;
                cases.add(cse);
            }
        }
        insert cases;
        cases = [SELECT Id,AccountId,CreatedById FROM Case];


        Id workOrderRtId = Schema.getGlobalDescribe().get('WorkOrder').getDescribe().getRecordTypeInfosByDeveloperName()
                .get(params.workOrderRecordTypeName).getRecordTypeId();

        //---------- CREATE WORK ORDERS
        List<WorkOrder> workOrders = new List<WorkOrder>();

        for (Case cse : cases) {
            for (Integer i = 0; i < params.iNumWorkOrdersPerCase; i++) {
                WorkOrder workOrder = new WorkOrder();
                workOrder.AccountId = cse.AccountId;
                workOrder.CaseId = cse.id;
                workOrder.RecordTypeId = workOrderRtId;
                List<Asset> accountAssets = mAccountId_Assets.get(cse.AccountId);
                workOrder.AssetId = accountAssets[0].Id;
                workOrder.Status = params.workOrderStatus;
                workOrder.Site_Grade__c = params.workOrderSiteGrade;
                workOrder.ServiceTerritoryId = serviceTerritories[0].Id;
                workOrders.add(workOrder);
            }
        }
        insert workOrders;
        workOrders = [SELECT Id, CaseId, AssetId,AccountId FROM WorkOrder];
        System.assert(!workOrders.isEmpty());

        Id saRtId = Schema.getGlobalDescribe().get('ServiceAppointment').getDescribe().getRecordTypeInfosByDeveloperName()
                .get(params.serviceAppointmentRecordTypeName).getRecordTypeId();
        List<ServiceAppointment> serviceAppointments = new List<ServiceAppointment>();
        for (WorkOrder workOrder : workOrders) {
            ServiceAppointment sa = new ServiceAppointment();
            //sa.Account = workOrder.AccountId;
            sa.Work_Order__c = workOrder.Id;
            sa.RecordTypeId = saRtId;
            sa.EarliestStartTime = System.now();
            sa.DueDate = Date.today().addDays(2);
            sa.ParentRecordId = workOrder.Id;
            sa.Status = params.serviceAppointmentStatus; // @see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            ////Needed for validation rule  https://accelentertainment--uat.lightning.force.com/lightning/setup/ObjectManager/ServiceAppointment/ValidationRules/03d7A00000006uYQAQ/view
            sa.Machine_Down_Upon_Arrival__c = 'Yes';
            sa.ServiceTerritoryId = serviceTerritories[0].id;
            serviceAppointments.add(sa);
        }
        insert serviceAppointments;
        System.assert(!serviceAppointments.isEmpty());
        List<Solution__c> solutions = buildServiceSolutions();
        insert solutions;
    }
    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * service appointments and ties them all together.
     */
    public static void createAllDataToServiceAppointments() {
        createAllDataToServiceAppointments( new TestSvcAppointmentDataParams() );
    }
    /**
     *
     *
     * @param numChars
     *
     * @return
     */
    public static String generateRandomString(Integer numChars) {

        //declare local vars
        String randomNumString = '';
        String returnVal = '';
        List <String> charArray = new String [] {'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','0','1','2','3','4','5','6','7','8','9','-','$','#','!','@','+','=','%'};


        // generate the requisite random number strings
        for (Integer x = 0; x < 100; x++) {
            // generate a random number
            String tempStr = String.valueOf(Math.random());
            // take all of the digits to the right of the decimal point
            randomNumString += tempStr.substring(2);

            // determine if we have enough characters
            if (randomNumString.length() >= numChars) {
                x = 101;
            }
        }
        // trim the string if we ran over
        if (randomNumString.length() > numChars) {
            randomNumString = randomNumString.substring(0,numChars);
        }

        // build the random character string
        for (Integer x = 0; x < randomNumString.length(); x++) {

            // declare local vars
            String currentNum = '';
            String newChar = '';
            String randomNum = String.valueOf(Math.random());
            Integer ndxMultiplier = 0;

            // get a handle on the current character
            currentNum = randomNumString.substring(x,x+1);

            // get the multiplier from the new random number string
            for (Integer y = 2; y < randomNum.length(); y++) {
                ndxMultiplier = Integer.valueOf(randomNum.substring(y,y+1));
                if (ndxMultiplier < 8) {
                    newChar = charArray[ndxMultiplier * Integer.valueOf(currentNum)];
                    y = randomNum.length();
                }
            }
            returnVal += newChar;
        }
        // return the random character string
        return returnVal;
    }
    public class SecSettings {
        public String us    {get; set;}	    //User Id
        public String uName {get; set;}	    //User Name
        public String pr    {get; set;}	    //Profile Id
        public String rl    {get; set;}	    //Role Id
        public String pm    {get; set;}	    //Permission Set Id

        public SecSettings(String sUser, String sUserName, String sProf, String sRole, String sPM) {
            this.us = sUser;
            this.uName = sUserName;
            this.pr = sProf;
            this.rl = sRole;
            this.pm = sPm;
        }
    }
    /**s
     *
     *
     * @param mFieldSetWrappersByApiName
     */
    public static void debugFieldSetWrappersAndFieldSetMembers(Map<String,FieldSetWrapper> mFieldSetWrappersByApiName ) {
        System.debug('_____ number of field set wrappers found='+mFieldSetWrappersByApiName.size());
        for(String fsApiName : mFieldSetWrappersByApiName.keySet()) {
            System.debug('==========================================================');
            System.debug('fsApiName ----> '+fsApiName);
            FieldSetWrapper fsw = mFieldSetWrappersByApiName.get(fsApiName);
            System.debug('FieldSetWrapper SobjectName -----> '+ fsw.fieldSetSObjectApiName);
            System.debug('FieldSetWrapper SObjectRecordId--->' + fsw.fieldSetSObjectRecordId);
            System.debug('FieldSetWrapper Label       -----> '+ fsw.fieldSetLabel);
            List<FieldSetMemberWrapper> fsMemberWrappers = fsw.fieldSetMemberWrappers;
            System.debug('->>>>>>>>>  Field Set Member Wrappers <<<<<<<<<<');
            for(FieldSetMemberWrapper fsm : fsMemberWrappers) {
                System.debug('fieldApiName-->'+fsm.fieldApiName);
                System.debug('fieldValue-->'+fsm.fieldValue);
            }
            System.debug('==========================================================');
        }
    }
}