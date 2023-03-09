@IsTest
private class TEST_OppValRules {

    public static String UNAME = 'acceltest@accel.com';
    public static String OPP_RT_DEV_NAME = 'AE_Video_Gaming';
    public static String VAL_ERROR_DATE_AGREEMENT_SIGNED_API_NAME = 'Date_Agreement_Signed__c';

    @TestSetup
    static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni', 1);
            List<Account> accounts = new List<Account>();
            Integer numAccounts = 2;
            for (Municipality__c municipality : municipalities) {
                for (Integer i = 0; i < numAccounts; i++) {
                    accounts.add(TestUtils.buildAccount('accel test acct:' + i + 'a',
                            municipality.Id, 'Accel Account'));
                    accounts.add(TestUtils.buildAccount('accel test acct:' + i + 'b',
                            municipality.Id, 'Competitor Account'));
                }
            }
            insert accounts;
            accounts = [SELECT Id,Name FROM Account];
            System.assert(accounts.size() == numAccounts * 2);

            RecordTypeInfo rti =  Opportunity.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get(OPP_RT_DEV_NAME);
            Id rtId = rti.recordTypeId;
            List<String> stageApiValues = new List<String>();

            Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
            List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

            for( Schema.PicklistEntry v : values) {
                System.debug('----> v'+v);
                if(v.active) {
                    stageApiValues.add(v.getValue());
                }
            }



            List<Opportunity> opps = new List<Opportunity>();
            for (Account account : accounts) {
                Opportunity opp = TestUtils.buildOpportunity(account);
                opp.StageName = stageApiValues[0];
                opp.RecordTypeId = rtId;
                opps.add(opp);
            }
            insert opps;
            opps = [SELECT Id FROM Opportunity];
            System.assert(opps.size() == accounts.size());
        }
    }

    @IsTest
    static void test_Opp_DateAgreementSigned_No_Error() {

        List<Opportunity> opps = [
          SELECT Id, StageName,Date_Agreement_Signed__c,RecordType.Name
          FROM   Opportunity
        ];
        Opportunity opp = opps[0];

        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            if(v.active) {
                stageApiValues.add(v.getValue());
            }
        }

        Test.startTest();

        opp.Date_Agreement_Signed__c = Date.today();
        update opp;

        opp.StageName = stageApiValues[1]; //  'Customer Meeting/Proposal';
        update opp;
        opp.StageName = stageApiValues[2]; //  'Negotiation/Handling Objections';
        update opp;
        opp.StageName = stageApiValues[3];  //  'Eligibility';
        update opp;

        Test.stopTest();
    }


    @IsTest
    static void test_Opp_DateAgreementSigned_Close_OppLost_No_Agreement_Signed_No_Error() {

        List<Opportunity> opps = [
                SELECT Id, StageName,Date_Agreement_Signed__c,RecordType.Name
                FROM   Opportunity
        ];
        Opportunity opp = opps[0];

        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            if(v.active) {
                stageApiValues.add(v.getValue());
                System.debug('--->'+v.getValue());
            }
        }

        Test.startTest();
        opp.StageName =stageApiValues[ stageApiValues.size() - 1 ];  // 'Closed Lost'
        System.debug('--> updating stage name to:'+opp.StageName);
        update opp;

        opp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals(opp.StageName, stageApiValues [ stageApiValues.size() - 1 ]);

        Test.stopTest();
    }

    @IsTest
    static void test_Opp_DateAgreementSigned_Eligibility_No_Agreement_Signed_Error() {
        List<Opportunity> opps = [
                SELECT Id, StageName,Date_Agreement_Signed__c,RecordType.Name
                FROM   Opportunity
        ];
        Opportunity opp = opps[0];


        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            if(v.active) {
                stageApiValues.add(v.getValue());
            }
        }

        Test.startTest();

        opp.StageName = stageApiValues[1]; //  'Customer Meeting/Proposal';
        update opp;
        opp.StageName = stageApiValues[2]; //  'Negotiation/Handling Objections';
        update opp;

        // Salesforce GO BOOOM!
        try {
            opp.StageName = stageApiValues[3];  //  'Eligibility';
            update opp;
        } catch (DmlException dmlEx) {
            system.debug('--->'+dmlEx);
            Boolean foundValError = false;
            for(Integer i = 0; i<dmlEx.getNumDml(); i++) {
                if(dmlEx.getDmlStatusCode(i) == 'FIELD_CUSTOM_VALIDATION_EXCEPTION') {
                    List<String> dmlFieldNames = dmlEx.getDmlFieldNames(i);
                    if(!dmlFieldNames.isEmpty()) {
                        for(String fieldName : dmlFieldNames) {
                            IF(fieldName.equalsIgnoreCase(VAL_ERROR_DATE_AGREEMENT_SIGNED_API_NAME)) {
                                foundValError = true;
                            }
                        }
                    }

                }
            }
            System.assertEquals(
                    true,foundValError,'A validation error was not thrown for '+VAL_ERROR_DATE_AGREEMENT_SIGNED_API_NAME
                                + ' And it should have been!'
            );
        }
        Test.stopTest();
    }

}