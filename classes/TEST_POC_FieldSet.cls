/**
 * Note. APEX has a testing hole where they do not allow you to create a field set in a unit test. (LAME)
 * So basically we are dependent on a field set existing in the org which is generally a bad thing but we have
 * no other options. That being the case we will assume a test Account field set existing in the target org and has
 * at least one FieldSet.
 */
@IsTest
private class TEST_POC_FieldSet{

    public static final String      USERNAME_ADMIN                           = 'acceltestadmin@accelentertainment.com';
    public static final String      ACCOUNT_NAME                             = 'Blah Random UT Account';
    public static final String      KNOWN_SOBJECT_API_NAME                   = 'Account';
    public static final String      KNOWN_FIELDSET_API_NAME                  = 'test_lookup';
    public static final Set<String> KNOWN_FIELDSET_USER_LOOKUP_FIELDS        = new Set<String> {'Relationship_Manager__c'};

    /**
     * Obviously.. initiate UT data. Create a Muni and an account.
     */
    @TestSetup static void setup() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('Test Muni',2);
        List<Account> accounts = new List<Account>();
        for(Municipality__c muni : munis) {
            accounts.add(TestUtils.buildAccount(ACCOUNT_NAME,muni.Id));
        }
        insert accounts;
    }
    /**
     * Tests an account fieldset. Tests that:
     *
      * 1. We found the fieldset as expected.
      * 2. The fieldset contains members.
      * 3. If it's a lookup field and we inserted a value for the lookup, it contains the value and the associated
      * name value of the reference field.
     */
    
    
    @IsTest
    static void test_retrieveSpecificFieldSetWrappersAndFieldSetMember_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount(ACCOUNT_NAME, null);

        Map<String, Id> mUserLookups = new Map<String, Id>();
        for(String fieldName : KNOWN_FIELDSET_USER_LOOKUP_FIELDS) {
            mUserLookups.put(fieldName,UserInfo.getUserId());
            account.put(fieldName,UserInfo.getUserId());
        }
        insert account;

        System.runAs(adminUser) {
            String recId = account.Id;
            ResponseDto dto  = POC_FieldSetController.retrieveSpecificFieldSetWrappersAndFieldSetMembers(   KNOWN_SOBJECT_API_NAME,
                                                                                                            recId,
                                                                                                            new List<String>{KNOWN_FIELDSET_API_NAME});

            List<FieldSetWrapper> fsWraps = (List<FieldSetWrapper>)dto.values.get(POC_FieldSetController.MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS);
            FieldSetWrapper fsWrap = fsWraps[0];

            System.assert(fsWrap.fieldSetApiName == KNOWN_FIELDSET_API_NAME);

            List<FieldSetMemberWrapper> fields = fsWrap.fieldSetMemberWrappers;
            System.assert(fields != null && !fields.isEmpty());

            // @todo refine this.
            for(FieldSetMemberWrapper field : fields) {
                if(field.fieldType == FieldSetSvc.LOOKUP_FIELD_TYPE) {
                    if(mUserLookups.containsKey(field.fieldApiName)) {
                        System.assert(field.fieldValue != null);
                        System.assert(field.sObjectReferenceToNameFieldValue != null);
                    }
                }
            }
        }
    }
    /**
     * Test that a field set was *Not* found.
     */
    @IsTest
    static void test_retrieveSpecificFieldSetWrappersAndFieldSetMember_Negative_Notfound() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount(ACCOUNT_NAME, null);
        insert  account;

        System.runAs(adminUser) {
            String recId = account.Id;
            ResponseDto dto = POC_FieldSetController.retrieveSpecificFieldSetWrappersAndFieldSetMembers(KNOWN_SOBJECT_API_NAME,
                                                                                                        recId,
                                                                                                        new List<String>{'bogus_api_name'});
            System.assert(!dto.isSuccess);
            System.assert(dto.technicalMsg != null);
            System.assert(dto.message != null);
        }
    }
    /**
     *  Simulates the user editing a fieldset in the ui.
     */
    @IsTest
    static void test_updateSObj_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount(ACCOUNT_NAME, null);

        Map<String, Id> mUserLookups = new Map<String, Id>();
        for(String fieldName : KNOWN_FIELDSET_USER_LOOKUP_FIELDS) {
            mUserLookups.put(fieldName,UserInfo.getUserId());
            account.put(fieldName,UserInfo.getUserId());
        }
        insert account;

        System.runAs(adminUser) {
            String recId = account.Id;
            //  Simulate initial load of page with a pre-selected field set.
            ResponseDto dto  = POC_FieldSetController.retrieveSpecificFieldSetWrappersAndFieldSetMembers(   KNOWN_SOBJECT_API_NAME,
                                                                                                            recId,
                                                                                                            new List<String>{KNOWN_FIELDSET_API_NAME});

            List<FieldSetWrapper> fsWraps = (List<FieldSetWrapper>)dto.values.get(POC_FieldSetController.MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS);
            FieldSetWrapper fsWrap = fsWraps[0];
            List<FieldSetMemberWrapper> fields = fsWrap.fieldSetMemberWrappers;

            //  Roll through the wraps (just like the ui would in the client controller and update a field.
            for(FieldSetMemberWrapper field : fields) {
                if(field.fieldApiName == 'Name') {
                    field.fieldValue = ACCOUNT_NAME + ' - Form Updated';
                }
            }
            Account updatedAccount = new Account();
            updatedAccount.Id = account.Id;

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(KNOWN_SOBJECT_API_NAME);
            Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

            for(FieldSetMemberWrapper fieldWrap : fields) {
                if(!fieldWrap.isFormulaField) {
                    Schema.SObjectField field = fieldMap.get(fieldWrap.fieldApiName);
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    if(dfr.isUpdateable()) {
                        updatedAccount.put(fieldWrap.fieldApiName, fieldWrap.fieldValue);
                    }
                }
            }
            //1a..  test update with no refresh of sObject returned
            ResponseDto updateDto = POC_FieldSetController.updateSObject(updatedAccount);
            System.assert(updateDto.isSuccess);
            SObject dbUpdatedSobject = FieldSetSvc.retrieveAllSObjectFieldsAndData(updatedAccount.Id,KNOWN_SOBJECT_API_NAME);
            System.assert(dbUpdatedSobject instanceof Account);
            System.assert( ((Account)dbUpdatedSobject).Name == ACCOUNT_NAME + ' - Form Updated');

            //1b.. test update with refresh of sObject returned.
            String updateNameTo = 'UpdatedWithRefresh Account Name';
            updatedAccount.Name = updateNameTo;
            Boolean doRefresh = true;
            ResponseDto updateWithRefreshDto = POC_FieldSetController.updateSObject(updatedAccount,doRefresh);
            SObject sObj = updateWithRefreshDto.sObj;
            System.assert(sObj.get('Name') == updateNameTo);
        }
    }
    /**
     * Cause an exception by updating the name field so something that is too long.
     * @todo test business val rules.
     */
    @IsTest
    static void test_updateSObj_Negative() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount('TEST Account', null);

        Map<String, Id> mUserLookups = new Map<String, Id>();
        for (String fieldName : KNOWN_FIELDSET_USER_LOOKUP_FIELDS) {
            mUserLookups.put(fieldName, UserInfo.getUserId());
            account.put(fieldName, UserInfo.getUserId());
        }
        insert account;

        System.runAs(adminUser) {
            String recId = account.Id;
            ResponseDto dto = POC_FieldSetController.retrieveSpecificFieldSetWrappersAndFieldSetMembers(KNOWN_SOBJECT_API_NAME,
                                                                                                        recId,
                                                                                                        new List<String>{KNOWN_FIELDSET_API_NAME});

            List<FieldSetWrapper> fsWraps = (List<FieldSetWrapper>) dto.values.get(POC_FieldSetController.MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS);
            FieldSetWrapper fsWrap = fsWraps[0];

            List<FieldSetMemberWrapper> fields = fsWrap.fieldSetMemberWrappers;

            for (FieldSetMemberWrapper field : fields) {
                if (field.fieldApiName == 'Name') { //exceed max field size on name which will cause a dml error.
                    for(Integer i=0; i<300; i++) {
                        field.fieldValue += String.valueOf(i);
                    }
                }
            }
            Account updatedAccount = new Account();
            updatedAccount.Id = account.Id;

            Schema.SObjectType objectType = Schema.getGlobalDescribe().get(KNOWN_SOBJECT_API_NAME);
            Map<String, SObjectField> fieldMap = objectType.getDescribe().fields.getMap();

            for (FieldSetMemberWrapper fieldWrap : fields) {
                if (!fieldWrap.isFormulaField) {
                    Schema.SObjectField field = fieldMap.get(fieldWrap.fieldApiName);
                    Schema.DescribeFieldResult dfr = field.getDescribe();
                    if (dfr.isUpdateable()) {
                        updatedAccount.put(fieldWrap.fieldApiName, fieldWrap.fieldValue);
                    }
                }
            }
            //(1) Test dML Ex
            ResponseDto updateDto = POC_FieldSetController.updateSObject(updatedAccount);
            System.assert(!updateDto.isSuccess);
            System.debug('rjn dto='+updateDto);
            //(2) Test Ex
            ResponseDto updateDtoEx = POC_FieldSetController.updateSObject(null);
            System.assert(!updateDto.isSuccess);
        }
    }
    /**
     * Not really sure what the higher level purpose of this is but test code is needed.
     */
    @IsTest
    static void test_serverecho_positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            String sObjectName = POC_FieldSetController.serverecho(account.Id);
            //  Test that the proper api name was returned.
            System.assertEquals( FieldSetSvc.getSObjectType(sObjectName), Schema.Account.SObjectType);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_serverecho_negative() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Exception e;
            try {
                POC_FieldSetController.serverecho(null); //method should be modified to have Defensive checks.
            } catch (NullPointerException npe) {
                e = npe;
            }
            System.assert(e instanceof  NullPointerException);
            Test.stopTest();
        }
    }
    /**
     * Not really sure what the higher level purpose of this is but test code is needed.
     */
    @IsTest
    static void test_GetRecord_positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            System.assertEquals(POC_FieldSetController.GetRecord(account.id,KNOWN_SOBJECT_API_NAME).Id,account.Id);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_GetRecord_negative() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Account account = [SELECT Id FROM Account LIMIT 1];

        System.runAs(adminUser) {
            Test.startTest();
            Exception e;
            try {
                POC_FieldSetController.GetRecord(null, KNOWN_SOBJECT_API_NAME); //method should be changed.
            } catch ( QueryException qe) {
                e = qe;
            }
            System.assert(e instanceof QueryException );
            Test.stopTest();
        }
    }
}