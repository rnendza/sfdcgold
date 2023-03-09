@IsTest
private class TEST_AccountTrigger{

    public static String UNAME = 'acceltest@accel.com';

    /**
     * Setup test data.
     */
    @TestSetup
    static void setup() {
        TestUtils.createMunicipalities('accel test muni',2);

        List<Municipality__c> munis = TestUtils.createMunicipalities('Carol Stream', 1);
        for(Municipality__c muni : munis) {
            muni.Name = muni.Name.replace('0','');
        }
        update munis;
    }


    @IsTest
    static void test_Account_Delete() {
        User u = TestUtils.getUserForTest(UNAME);
        
        List<Route__c> routes = clTESTUTILS.createRoutes(1,1);
        List<Route_Schedule__c> routeSchedules = clTESTUTILS.createRouteSchedules(routes,Date.today()+1,Date.today(),u.Id);

        System.runAs(u) {

            Test.startTest();


            //=== (1) delete of account with no restrictions.
            String name = 'Test New Account With Bufu Billing City';
            Account account = TestUtils.buildAccount(name,null,'Accel Account');
            account.BillingStreet = '123 spring';account.BillingCity = 'Bufu';account.BillingState = '';
            account.BillingCountry = 'Egypt';account.BillingPostalCode = '234243';
            insert account;

            delete account;
            System.assert([SELECT Id FROM Account WHERE Name = :name].isEmpty());


            //=== (2) delete of account with RPS children.
            account = TestUtils.buildAccount(name,null,'Accel Account');
            account.BillingStreet = '123 spring';account.BillingCity = 'Bufu';account.BillingState = '';
            account.BillingCountry = 'Egypt';account.BillingPostalCode = '234243';
            insert account;

            Route_Processing_Sheet__c rps = new Route_Processing_Sheet__c(Account__c = account.Id,Route_Schedule__c = routeSchedules[0].Id);
            insert rps;

            DmlException dmlEx;
            try {
                delete account;
            } catch (DmlException ex) {
                dmlEx = ex;
            }
            System.assert(dmlEx != null);

            Test.stopTest();
        }
    }

    /**
     * (1) Test for billing data populated but no shipping data populated. result => shipping data = billing data.
     * (2) Test for billing data and shipping data populated.  result => no change to shipping data and billing created.
     * (3) Test for shipping data but not billing data populated. result => no change to shipping data and no billing data created.
     */
    @IsTest
    static void testAccountAddressCreation() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();

            //=== (1) Test pop of billing data and copy to shipping data.
            Account account = TestUtils.buildAccount('Test New Account With Bufu Billing City ',null,'Accel Account');
            account.BillingStreet = '123 spring';account.BillingCity = 'Bufu';account.BillingState = '';
            account.BillingCountry = 'Egypt';account.BillingPostalCode = '234243';
            insert account;
            account = AccountSvc.retrieveFullAccount(account.Id);
            System.assert(account.ShippingCity == account.BillingCity);
            System.assert(account.ShippingStreet == account.BillingStreet);

            //=== (2) Populate both billing and shipping.
            Account account2  = account.clone(false);
            account2.ShippingCity = 'dont overwrite me';
            account2.Name = 'blah account 2';
            insert account2;
            account2 = AccountSvc.retrieveFullAccount(account2.Id);
            System.assert(account2.ShippingCity == 'dont overwrite me');
            System.assert(account2.BillingCity != null);

            //=== (3) Populate only shipping data.
            Account account3 = TestUtils.buildAccount('Test New Account no bd but sd',null,'Accel Account');
            account3.ShippingCity = 'I MUST EXIST';
            insert account3;
            account3 = AccountSvc.retrieveFullAccount(account3.Id);
            System.assert(account3.BillingCity == null);
            System.assert(account3.ShippingCity == 'I MUST EXIST');

            Test.stopTest();
        }
    }

    @IsTest
    static void testAccountUpdateForHpdTotalCreation() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Municipality__c municipality = [SELECT Id FROM Municipality__c LIMIT 1][0];
            Account newAccount = TestUtils.buildAccount('Test New Account',municipality.Id,'Prospect');
            insert newAccount;

            Test.startTest();

            List<Hold_Per_Day_Total__c> hpd = [SELECT Id, Account__c FROM Hold_Per_Day_Total__c WHERE Account__c = :newAccount.Id];
            System.assert(hpd.isEmpty());

            newAccount.Type = 'Accel Account';
            update newAccount;

            Account a = [SELECT Id, Hold_Per_Day_Total__c FROM Account WHERE Id = :newAccount.Id];
            System.assert(a.Hold_Per_Day_Total__c != null);

            Test.stopTest();
        }
    }

    @IsTest
    static void testAccountUpdateForLocationAssessmentCreation() {
        User u = TestUtils.getUserForTest(UNAME);

        System.runAs(u) {
            Municipality__c municipality = [SELECT Id FROM Municipality__c LIMIT 1][0];
            Account newAccount = TestUtils.buildAccount('Test New Account Test New Account Test New Account Test New Account Test New AccountTest New Account ',
                                                        municipality.Id,'Accel Account');
            Account newAccount2 = TestUtils.buildAccount('Test New Account2',municipality.Id,'Accel Account');
            Id locRtId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
            newAccount.RecordTypeId = locRtId;
            insert newAccount;

            Test.startTest();

            List<Vetting_Questionnaire__c> vqs = [SELECT Id, Account__c FROM Vetting_Questionnaire__c WHERE Account__c = :newAccount.Id];
            System.assert(vqs.isEmpty());

            newAccount.Accel_VGT_Live_Date__c = Date.today();
            update newAccount;
            vqs.clear();
            vqs = [SELECT Id, Account__c FROM Vetting_Questionnaire__c WHERE Account__c = :newAccount.Id];
            System.assert(!vqs.isEmpty() && vqs.size() == 1);

            insert newAccount2;
            List<Account> bothAccounts = new List<Account>();
            bothAccounts.add(newAccount);
            bothAccounts.add(newAccount2);
            update bothAccounts;

            vqs.clear();
            vqs = [SELECT Id, Account__c FROM Vetting_Questionnaire__c WHERE Account__c = :newAccount.Id];
            System.assert(!vqs.isEmpty() && vqs.size() == 1);

            newAccount2.Accel_VGT_Live_Date__c = Date.today();
            newAccount.Accel_VGT_Live_Date__c = Date.today();
            bothAccounts.clear();
            bothAccounts.add(newAccount);
            bothAccounts.add(newAccount2);
            update bothAccounts;

            vqs.clear();
            vqs = [SELECT Id, Account__c FROM Vetting_Questionnaire__c ];
            System.assert(!vqs.isEmpty() && vqs.size() == 2);

            Test.stopTest();
        }
    }
    /**
     *
     */
    @IsTest
    static void testNewAccountCreation() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Municipality__c municipality = [SELECT Id FROM Municipality__c LIMIT 1][0];

            Test.startTest();

            Account newAccount = TestUtils.buildAccount('Test New Account',municipality.Id,'Accel Account');
            insert newAccount;
            List<Hold_Per_Day_Total__c> hpd = [SELECT Id, Account__c FROM Hold_Per_Day_Total__c WHERE Account__c = :newAccount.Id];
            System.assert(!hpd.isEmpty());

            Test.stopTest();
        }
    }


    @IsTest
    static void test_ShippingAddressChange() {
        User u = TestUtils.getUserForTest(UNAME);

        Region__c region = new Region__c(Name= 'Region 8',State__c = 'IL');
        insert region;
        County__c county = new County__c(Name = 'DuPage',State__c = 'IL', Covaid_Region__c = region.Id);
        insert county;

        Municipality__c municipality = [SELECT Id FROM Municipality__c LIMIT 1][0];
        Account newAccount = TestUtils.buildAccount('Test New Account', municipality.Id,'Accel Account');
        newAccount.ShippingStreet = '4619 Main';
        newAccount.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
        newAccount.ShippingPostalCode = '60532';
        newAccount.ShippingCountry = 'US';
        newAccount.ShippingLatitude = 42.795778000000000;
        newAccount.ShippingLongitude = -87.075013000000000;
        insert newAccount;

        String censusResponse = QueueableCountyUpdaterLive.TEST_JSON_RESPONSE;
        String ep = QueueableCountyUpdaterLive.BASE_EP+newAccount.ShippingLatitude+'&longitude=' + newAccount.ShippingLongitude + '&format=json';


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', censusResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(u) {

            Test.startTest();

            newAccount.County_Auto_Updated__c = true;
            update newAccount;
            newAccount.ShippingStreet = '4716 Reidy';
            update newAccount;
            newAccount = [SELECT Id, ShippingStreet,County_Auto_Updated__c FROM Account where Id = :newAccount.Id];
            System.assert(newAccount.County_Auto_Updated__c == FALSE);

            QueueableCountyUpdaterLive q = new QueueableCountyUpdaterLive(new Set<Id>{newAccount.Id},FALSE);
            System.enqueueJob(q);
            Test.stopTest();

            newAccount = [SELECT Id, County_LU__c, Covid_Region_LU__c,County_LU_Auto_Update__c FROM Account WHERE Id = :newAccount.Id];
            System.assertEquals(county.Id, newAccount.County_LU__c);
            System.assertEquals(region.Id, newAccount.Covid_Region_LU__c);
        }
    }

    @IsTest
    static void test_MuniAutoPopulate() {
        User u = TestUtils.getUserForTest(UNAME);

        Municipality__c municipality = [SELECT Id FROM Municipality__c LIMIT 1][0];
        Account newAccount = TestUtils.buildAccount('Test New Account', municipality.Id,'Accel Account');
        newAccount.ShippingStreet = '4619 Main';
        newAccount.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
        newAccount.ShippingPostalCode = '60532';
        newAccount.ShippingCountry = 'US';
        newAccount.ShippingLatitude = 42.795778000000000;
        newAccount.ShippingLongitude = -87.075013000000000;
        insert newAccount;

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);

        String ep = httpRequest.getEndpoint() + '&latlng='+newAccount.ShippingLatitude + ',' + newAccount.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(u) {

            Test.startTest();
            QueueableMuniUpdater.doChainJob = false;

            //Simulate data.com
            newAccount.ShippingLatitude = 41.795778000000000;
            newAccount.ShippingLongitude = -88.075013000000000;
            update newAccount;

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :newAccount.Id ];
            System.assert(a.MunicipalityLookup__c != null);
            System.assert(a.Muni_Auto_Updated__c);
        }
    }
}