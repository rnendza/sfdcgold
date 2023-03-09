/**
 * Note. APEX has a testing hole where they do not allow you to create a field set in a unit test. (LAME)
 * So basically we are dependent on a field set existing in the org which is generally a bad thing but we have
 * no other options. That being the case we will assume a test Account field set existing in the target org and has
 * at least one FieldSet.
 */
@IsTest
private class TEST_FieldSetSvc{

    public static final String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';
    public static final String ACCOUNT_NAME               = 'Blah Random UT Account';

    public static final String KNOWN_SOBJECT_API_NAME     = 'Account';
    public static final String KNOWN_FIELDSET_API_NAME    = 'test_lookup';
    public static final String KNOWN_FIELDSET_FIELD_NAME  = 'Type';
    /**
     *
     */
    @TestSetup static void setup() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('Test Muni',2);
        List<Account> accounts = new List<Account>();
        for(Municipality__c muni : munis) {
            accounts.add(TestUtils.buildAccount(ACCOUNT_NAME,muni.Id));
        }
        insert accounts;
    }

    @IsTest
    static void test_getSObjectRequiredFields_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount('TEST Account', null);
        account.Relationship_Manager__c = UserInfo.getUserId();
        insert account;

        System.runAs(adminUser) {
            Map<String,FieldSetMemberWrapper> m = FieldSetSvc.getSObjectRequiredFields(KNOWN_SOBJECT_API_NAME);
            System.assert(m.containsKey('Name'));
            FieldSetMemberWrapper fsmName = m.get('Name');
            System.assert(fsmName.fieldApiName == 'Name');
        }
    }

    @IsTest
    static void test_getAllFieldSetWrappers_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount('TEST Account', null);
        account.Relationship_Manager__c = UserInfo.getUserId();
        insert account;

        System.runAs(adminUser) {
            Map<String,FieldSetWrapper> m = FieldSetSvc.getAllFieldSetWrappers(KNOWN_SOBJECT_API_NAME);
            System.assert(m.containsKey(KNOWN_FIELDSET_API_NAME));
        }
    }

    @IsTest
    static void test_retrieveAllSObjectsFieldsAndData_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount('TEST Account', null);
        account.Relationship_Manager__c = UserInfo.getUserId();
        insert account;

        System.runAs(adminUser) {
            SObject sObj = FieldSetSvc.retrieveAllSObjectFieldsAndData(account.Id,Account.getSObjectType().getDescribe().getName());
            System.assertEquals(sObj.Id, account.Id);
            Account acc = (Account)sObj;
            System.assertEquals(acc.Relationship_Manager__c, account.Relationship_Manager__c);
        }
    }

    @IsTest
    static void test_getAllFieldSetWrappersAndFieldSetMembers_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            Map<String,FieldSetWrapper> mFieldSetWrappersByApiName = FieldSetSvc.getAllFieldSetWrappersAndFieldSetMembers(KNOWN_SOBJECT_API_NAME);
            System.debug(mFieldSetWrappersByApiName);
            System.assert(mFieldSetWrappersByApiName.containsKey(KNOWN_FIELDSET_API_NAME));
            FieldSetWrapper fsw = mFieldSetWrappersByApiName.get(KNOWN_FIELDSET_API_NAME);
            System.assertEquals(fsw.fieldSetSObjectApiName,KNOWN_SOBJECT_API_NAME);
            TestUtils.debugFieldSetWrappersAndFieldSetMembers(mFieldSetWrappersByApiName);
            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void test_getAllFieldSetWrappersAndFieldSetMembers_WithValues_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Account account = TestUtils.buildAccount('TEST Account',null);
        account.Relationship_Manager__c = UserInfo.getUserId();
        insert account;

        System.runAs(adminUser) {
            Test.startTest();
            Map<String,FieldSetWrapper> mFieldSetWrappersByApiName =
                    FieldSetSvc.getAllFieldSetWrappersAndFieldSetMembersWithValues(KNOWN_SOBJECT_API_NAME,account.id);
            TestUtils.debugFieldSetWrappersAndFieldSetMembers(mFieldSetWrappersByApiName);

            System.assert(!mFieldSetWrappersByApiName.isEmpty());
            System.assert(mFieldSetWrappersByApiName.containsKey(KNOWN_FIELDSET_API_NAME));

            Test.stopTest();
        }
    }
    @IsTest
    static void test_getSpecificFieldSetWrappersAndFieldSetMembers_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Integer amountToTest = 1;
        //  Get superset of FieldSets  for the sObject.
        Map<String,FieldSet> mFieldSetsByApiNames = FieldSetSvc.getAllFieldSets(KNOWN_SOBJECT_API_NAME);
        //  Now cut those down to to grab say 1.
        Set<String> fieldSetApiNames = new Set<String>();
        List<String> lFieldSetApiNames = new List<String>(mFieldSetsByApiNames.keySet());
        if(mFieldSetsByApiNames.size() > amountToTest) {
            fieldSetApiNames.add(lFieldSetApiNames[0]);
        }

        System.runAs(adminUser) {
            Test.startTest();
            //now test that the service properly returned the field sets for the api names we are looking for.
            if(!fieldSetApiNames.isEmpty()) {
                Map<String,FieldSetWrapper> mFieldSetWrappersByApiName =
                        FieldSetSvc.getSpecificFieldSetWrappersAndFieldSetMembers(fieldSetApiNames,KNOWN_SOBJECT_API_NAME);
                for(String requestedApiName : fieldSetApiNames) {
                    System.assert(mFieldSetWrappersByApiName.containsKey(requestedApiName));
                }
            }
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getSpecificFieldSetWrappersAndFieldSetMembers_With_Values_Positive() {
        Asset ass = TestUtils.createAsset('TEST ATM');

        Map<String,Id> lookupApiName_Value = new Map<String,Id>();
        lookupApiName_Value.put('Relationship_Manager__c',UserInfo.getUserId());
        lookupApiName_Value.put('Key_Account_Manager__c',UserInfo.getUserId());

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Account account = TestUtils.buildAccount('TEST Account',null);
        for(String apiName : lookupApiName_Value.keySet()) {
            account.put(apiName,  (Id) lookupApiName_Value.get(apiName));
        }
        insert account;

        System.runAs(adminUser) {
            Test.startTest();
            Map<String,FieldSetWrapper> mFieldSetWrappersByApiName =
                    FieldSetSvc.getAllFieldSetWrappersAndFieldSetMembersWithValues(KNOWN_SOBJECT_API_NAME,account.id);
            TestUtils.debugFieldSetWrappersAndFieldSetMembers(mFieldSetWrappersByApiName);

            System.assert(!mFieldSetWrappersByApiName.isEmpty());
            System.assert(mFieldSetWrappersByApiName.containsKey(KNOWN_FIELDSET_API_NAME));
            FieldSetWrapper fsw = mFieldSetWrappersByApiName.get(KNOWN_FIELDSET_API_NAME);

            Integer iCountValueMatchers = 0;
            for(FieldSetMemberWrapper fsm : fsw.fieldSetMemberWrappers) {
                if(lookupApiName_Value.containsKey(fsm.fieldApiName)) {
                    System.assert(fsm.fieldValue == lookupApiName_Value.get(fsm.fieldApiName));
                    iCountValueMatchers++;
                }
            }
            System.assertEquals(iCountValueMatchers,lookupApiName_Value.size());

            Test.stopTest();
        }
    }
    @IsTest
    static void test_getAllFieldSets_byApiName_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            Map<String,FieldSet> mFieldSetsByApiName = FieldSetSvc.getAllFieldSets(KNOWN_SOBJECT_API_NAME);
            System.assert(mFieldSetsByApiName.containsKey(KNOWN_FIELDSET_API_NAME));
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getAllFieldSets_byApiName_Negative() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            Exception ex;
            try {
                FieldSetSvc.getAllFieldSets('bogus soject api name');
            } catch (Warnings.InvalidSObjectApiNameException customEx) {
                ex = customEx;
            }
            System.assert(ex != null);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getAllFieldSetsFields_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            Set<String> fieldApiNames =FieldSetSvc.getAllFieldSetsFields(FieldSetSvc.getAllFieldSets(KNOWN_SOBJECT_API_NAME));
            System.assert(fieldApiNames.contains(KNOWN_FIELDSET_FIELD_NAME));
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getAllFieldSetsFields_Negative() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            System.assert(FieldSetSvc.getAllFieldSetsFields(null).isEmpty());
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveSObjectDynamic_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Account account = [SELECT Id, Name,RecordTypeId FROM Account LIMIT  1];
        System.runAs(adminUser) {
            Test.startTest();
            Set<String> fieldApiNames = FieldSetSvc.retrieveAllSObjectFieldApiNames('Account');
            SObject sObj = FieldSetSvc.retrieveSObjectDynamic('Account',fieldApiNames,account.Id);
            System.assertEquals(sObj.Id,account.Id);
            Account retrievedAccount = (Account)sObj;
            System.assertEquals(retrievedAccount.Name,account.Name);
            System.assertEquals(retrievedAccount.RecordTypeId,account.RecordTypeId);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveSObjectDynamic_Negative_No_Data() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            Set<String> fieldApiNames = FieldSetSvc.retrieveAllSObjectFieldApiNames('Asset');
            System.assertEquals(FieldSetSvc.retrieveSObjectDynamic('Asset',fieldApiNames,null),null);
            Test.stopTest();
        }
    }
    @IsTest
    static void test_retrieveSObjectDynamic_Negative_BadApiName() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();

            Exception ex;
            try {
                FieldSetSvc.retrieveAllSObjectFieldApiNames('BOGUS_API_NAME');
            } catch (Warnings.InvalidSObjectApiNameException customEx) {
                ex = customEx;
            }
            System.assert(ex != null);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_getFieldLabel() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            String label = FieldSetSvc.getFieldLabel(Account.SObjectType.getDescribe().name,Account.Name.getDescribe().name);
            System.assertEquals(label,Account.Name.getDescribe().label);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_getSObjectTypesWithFieldSets_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        System.runAs(adminUser) {
            Test.startTest();
            List<SObjectType> sObjectTypes = FieldSetSvc.getSObjectTypesWithFieldSets();
            System.assert(sObjectTypes.contains( FieldSetSvc.getSObjectType(KNOWN_SOBJECT_API_NAME)));
            Test.stopTest();
        }
    }
    /**
     * This will test the ability to query only N fieldsets (as opposed to all FieldSets on a given sObject
     * by API Name.  This assumes the client knows what fields set api names it is going after.
     */
    @IsTest
    static void test_getSpecificFieldSets_Positive() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Integer amountToTest = 2;
        //  Get superset of FieldSets  for the sObject.
        Map<String,FieldSet> mFieldSetsByApiNames = FieldSetSvc.getAllFieldSets(KNOWN_SOBJECT_API_NAME);
        //  Now cut those down to to grab say 2.
        Set<String> fieldSetApiNames = new Set<String>();
        List<String> lFieldSetApiNames = new List<String>(mFieldSetsByApiNames.keySet());
        if(mFieldSetsByApiNames.size() > amountToTest) {
            fieldSetApiNames.add(lFieldSetApiNames[0]);
            fieldSetApiNames.add(lFieldSetApiNames[1]);
        }
        System.runAs(adminUser) {
            Test.startTest();
            //now test that the service properly returned the field sets for the api names we are looking for.
            if(!fieldSetApiNames.isEmpty()) {
                Map<String, FieldSet> mSpecificFieldSets = FieldSetSvc.getSpecificFieldSets(fieldSetApiNames, KNOWN_SOBJECT_API_NAME);
                for(String requestedApiName : fieldSetApiNames) {
                    System.assert(mFieldSetsByApiNames.containsKey(requestedApiName));
                }
            }
            Test.stopTest();
        }
    }
    @IsTest
    static void test_getSpecificFieldSets_Negative() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
        Integer amountToTest = 2;
        //  Get superset of FieldSets  for the sObject.
        Map<String,FieldSet> mFieldSetsByApiNames = FieldSetSvc.getAllFieldSets(KNOWN_SOBJECT_API_NAME);
        //  Now cut those down to to grab say 2.
        Set<String> fieldSetApiNames = new Set<String>();
        List<String> lFieldSetApiNames = new List<String>(mFieldSetsByApiNames.keySet());
        if(mFieldSetsByApiNames.size() > amountToTest) {
            fieldSetApiNames.add(lFieldSetApiNames[0]);
            fieldSetApiNames.add(lFieldSetApiNames[1]);
        }
        System.runAs(adminUser) {
            Test.startTest();
            //now test that the service returned an empty map for a bogus api name.
            if(!fieldSetApiNames.isEmpty()) {
                System.assert(FieldSetSvc.getSpecificFieldSets(fieldSetApiNames, 'BOGUS API NAME').isEmpty());
            }
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveAllSObjects() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Map<String,String> m = FieldSetSvc.retrieveAllSObjects();
            System.assert(m.containsKey('Account'),'Could not find account sObject!');
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveSObjDescribeResults() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Map<String,DescribeSObjectResult> m = FieldSetSvc.retrieveSObjDescribeResults(new Set<String>{'Account'});
            System.assert(m.containsKey('Account'.toLowerCase()),'Could not find account sObject!');
            Test.stopTest();
        }
    }


    @IsTest
    static void test_retrieveHistorySObjects() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Boolean isCustom = true;
            Map<String,String> m = FieldSetSvc.retrieveHistorySObjects('custom');
            isCustom = false;
            m = FieldSetSvc.retrieveHistorySObjects('standard');
            m = FieldSetSvc.retrieveHistorySObjects('bogus');
            m = FieldSetSvc.retrieveHistorySObjects(new List<String>{'Account'});
            //System.assert(m.containsKey('Account'),'Could not find account sObject!');
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveFieldDefs() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Map<String,String> m = FieldSetSvc.retrieveAllSObjects();
            System.assert(m.containsKey('Account'),'Could not find account sObject!');
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveFieldDescriptions() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Set<String> sObjectApiNames = new Set<String> {'Contact','Account'};
            Map<String,FieldDefinition> m = FieldSetSvc.retrieveFieldDescriptions(sObjectApiNames);
            //@todo asserts
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveFieldDescribeResults() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Set<String> sObjectApiNames = new Set<String> {'Contact','Account'};
            Map<String,Map<String,DescribeFieldResult>>  m = FieldSetSvc.retrieveFieldDescribeResults(sObjectApiNames);
            //@todo asserts
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveTrackedFieldDefs() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        System.runAs(adminUser) {
            Test.startTest();
            Set<String> sObjectApiNames = new Set<String> {'Route_Processing_Sheet__c','Route_Schedule__c','Meter_Reading__c'};
            Map<String,Map<String,FieldDefinition>> m  = FieldSetSvc.retrieveTrackedFieldDefinitions(sObjectApiNames );
            //@todo asserts
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveFieldHistory() {
        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);

        String historyObject = 'Route_Schedule__history';
        Set<String> fields = new Set<String>{'Processing_Status__c'};
        Datetime dtStart = System.now().addDays(-2);
        Datetime dtEnd = System.now();
        Map<Id,Route_Schedule__c> mRs = new Map<Id,Route_Schedule__c> ([
                Select Id
                FROM   Route_Schedule__c
                WHERE  CreatedDate >= :dtStart
                AND    CreatedDate <= :dtEnd
                LIMIT  2
        ]);
        Map<Id,Account> mAccounts = new Map<Id,Account> ([
                Select Id
                FROM   Account
                WHERE  CreatedDate >= :dtStart
                AND    CreatedDate <= :dtEnd
                LIMIT  2
        ]);

        Route_Schedule__History routeScheduleHistory = new Route_Schedule__History(
                Field = 'Processing_Status__c', ParentId = mRs.values().get(0).Id
        );
        insert routeScheduleHistory;
//
//         AccountHistory accountHistory = new AccountHistory(
//                Field = 'Name', AccountId = mAccounts.values().get(0).Id
//        );
//        insert accountHistory;


        System.runAs(adminUser) {
            Test.startTest();
            List<FieldSetSvc.FieldAuditInfo> histories1 = FieldSetSvc.retrieveFieldHistory(historyObject,fields);
            List<FieldSetSvc.FieldAuditInfo> histories1a = FieldSetSvc.retrieveFieldHistory(historyObject,fields,System.now().addDays(-1),System.now());
            List<FieldSetSvc.FieldAuditInfo> histories2 = FieldSetSvc.retrieveFieldHistory(historyObject,fields,mRs.keySet());
            List<FieldSetSvc.FieldAuditInfo> histories3 = FieldSetSvc.retrieveFieldHistory(historyObject,fields,dtStart,dtEnd,mRs.keySet(), new Set<Id>{adminUser.Id});
            List<FieldSetSvc.FieldAuditInfo> histories4 = FieldSetSvc.retrieveFieldHistory('AccountHistory',new SEt<String> {'Name'});
            List<FieldSetSvc.FieldAuditInfo> histories5 = FieldSetSvc.retrieveFieldHistory('ServiceAppointmentHistory',new SEt<String> {'Status'});
            //@todo asserts
            Test.stopTest();
        }
    }
}