@IsTest
private class TEST_OppTrigger {
    
    public static String UNAME = 'acceltest@accel.com';
    public static String OPP_RT_DEV_NAME = 'AE_Video_Gaming';

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

            List<String> stageApiValues = new List<String>();

            Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
            List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

            for( Schema.PicklistEntry v : values) {
                System.debug('----> v'+v);
                if(v.active) {
                    stageApiValues.add(v.getValue());
                }
            }

            RecordTypeInfo rti =  Opportunity.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get(OPP_RT_DEV_NAME);
            Id rtId = rti.recordTypeId;

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
    static void testSingleOppInsert_Positive() {

        //  We have to do this as there is some similar opp flow blowing up if we dont.
        DELETE [SELECT Id FROM Opportunity];

        User u = TestUtils.getUserForTest(UNAME);


        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            if(v.active) {
                stageApiValues.add(v.getValue());
            }
        }
        RecordTypeInfo rti =  Opportunity.getSObjectType().getDescribe().getRecordTypeInfosByDeveloperName().get(OPP_RT_DEV_NAME);
        Id rtId = rti.recordTypeId;


        System.runAs(u) {
            Account account = [SELECT Id, Name FROM Account LIMIT 1];

            Test.startTest();
            Opportunity opp = TestUtils.buildOpportunity(account);
            opp.Patrons_Under_21_Allowed_to_Enter__c = 'Yes';
            opp.StageName = stageApiValues[0];
            opp.Type = 'New Business';
            opp.RecordTypeId = rtId;
            insert opp;

            account = [SELECT Id, Name, Patrons_Under_21_Allowed_to_Enter__c FROM Account LIMIT 1];
            System.assert(account.Patrons_Under_21_Allowed_to_Enter__c == 'Yes');
            Test.stopTest();
        }
    }

    @IsTest
    static void testSingleOppInsert_Negative() {

        //  We have to do this as there is some similar opp flow blowing up if we dont.
        DELETE [SELECT Id FROM Opportunity];

        User u = TestUtils.getUserForTest(UNAME);
        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            System.debug('----> v'+v);
            if(v.active) {
                stageApiValues.add(v.getValue());
            }
        }

        System.runAs(u) {
            Account account = [SELECT Id, Name FROM Account LIMIT 1];

            Test.startTest();
            Opportunity opp = TestUtils.buildOpportunity(account);
            opp.Patrons_Under_21_Allowed_to_Enter__c = 'BAD VALUE';
            opp.StageName = stageApiValues[0];
            try {
                insert opp;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST'));
            }
            account = [SELECT Id, Name, Patrons_Under_21_Allowed_to_Enter__c FROM Account WHERE Id = :account.Id];
            System.assert(account.Patrons_Under_21_Allowed_to_Enter__c == null);
            Test.stopTest();
        }
    }

    @IsTest
    static void testSingleOppUpdate_Positive() {

        //  We have to do this as there is some similar opp flow blowing up if we dont.
        DELETE [SELECT Id FROM Opportunity];

        User u = TestUtils.getUserForTest(UNAME);
        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            System.debug('----> v'+v);
            if(v.active) {
                stageApiValues.add(v.getValue());
            }
        }

        System.runAs(u) {
            Account account = [SELECT Id, Name FROM Account LIMIT 1];
            Opportunity opp = TestUtils.buildOpportunity(account);
            opp.StageName = stageApiValues[0];

            opp.Patrons_Under_21_Allowed_to_Enter__c = 'Yes';
            insert opp;

            Test.startTest();
            opp.Patrons_Under_21_Allowed_to_Enter__c = 'No';
            update opp;
            account = [SELECT Id, Name, Patrons_Under_21_Allowed_to_Enter__c FROM Account LIMIT 1];
            System.assert(account.Patrons_Under_21_Allowed_to_Enter__c == 'No');
            Test.stopTest();
        }
    }

    @IsTest
    static void testSingleOppUpdate_Negative() {
        //  We have to do this as there is some similar opp flow blowing up if we dont.
        DELETE [SELECT Id FROM Opportunity];

        User u = TestUtils.getUserForTest(UNAME);

        List<String> stageApiValues = new List<String>();

        Schema.DescribeFieldResult fieldResult = Opportunity.StageName.getDescribe();
        List<Schema.PicklistEntry> values = fieldResult.getPicklistValues();

        for( Schema.PicklistEntry v : values) {
            System.debug('----> v'+v);
            if(v.active) {
                stageApiValues.add(v.getValue());
            }
        }

        System.runAs(u) {
            Account account = [SELECT Id, Name FROM Account LIMIT 1];
            Opportunity opp = TestUtils.buildOpportunity(account);
            opp.Patrons_Under_21_Allowed_to_Enter__c = 'Yes';
            opp.StageName = stageApiValues[0];
            insert opp;

            Test.startTest();
            try {
                opp.Patrons_Under_21_Allowed_to_Enter__c = 'BAD VALUE';
                update opp;
            } catch (Exception e) {
                System.assert(e.getMessage().contains('INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST'));
            }
            account = [SELECT Id, Name, Patrons_Under_21_Allowed_to_Enter__c FROM Account WHERE Id = :account.Id];
            System.assert(account.Patrons_Under_21_Allowed_to_Enter__c == 'Yes');
            Test.stopTest();
        }
    }
}