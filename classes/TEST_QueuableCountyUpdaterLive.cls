@IsTest
private class TEST_QueuableCountyUpdaterLive {
    public static String ADMINUNAME = 'acceltestadmin@accel.com';
    public static User uAdmin = TestUtils.getUserForTest(ADMINUNAME);

    @testSetup
    static void setup() {

        System.runAs(uAdmin) {
            Test.startTest();

            List<Municipality__c> munis = TestUtils.createMunicipalities('Carol Stream', 1);
            for(Municipality__c muni : munis) {
                muni.Name = muni.Name.replace('0','');
            }
            update munis;

            Account account = TestUtils.buildAccount('account name', munis[0].id);
            account.MunicipalityLookup__c = null;
            account.ShippingStreet = '4916 Main Street Unit 2';
            account.ShippingCity = 'Lisle';
            account.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
            account.ShippingPostalCode = '60532';
            account.ShippingCountry = 'US';
            account.ShippingLatitude = 41.795778000000000;
            account.ShippingLongitude = -88.075013000000000;
            account.County_Auto_Updated__c = true;
            insert account;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_Queueable_County_Updater_Live_Insert_Positive() {

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
        insert newAccount;

        String censusResponse = QueueableCountyUpdaterLive.TEST_JSON_RESPONSE;
        String ep = QueueableCountyUpdaterLive.BASE_EP+newAccount.ShippingLatitude+'&longitude=' + newAccount.ShippingLongitude + '&format=json';


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', censusResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            //simulate data.com but avoid the triggers since we can't chain queueables in unit test code.
            QueueableMuniUpdater.doChainJob = false;
            newAccount.ShippingLatitude = 42.795778000000000;
            newAccount.ShippingLongitude = -87.075013000000000;
            update newAccount;

            QueueableCountyUpdaterLive q = new QueueableCountyUpdaterLive(new Set<Id>{newAccount.Id},false);
            System.enqueueJob(q);

            Test.stopTest();

            newAccount = [SELECT Id, County_LU__c, Covid_Region_LU__c,County_LU_Auto_Update__c FROM Account WHERE Id = :newAccount.Id];
            System.assertEquals(county.Id, newAccount.County_LU__c);
            System.assertEquals(region.Id, newAccount.Covid_Region_LU__c);
        }
    }

    @IsTest
    static void test_Queueable_County_Updater_Live_Insert_Positive_Fips() {

        Region__c region = new Region__c(Name= 'Region 8',State__c = 'IL');
        insert region;
        County__c county = new County__c(Name = 'DuPage County wrong name',State__c = 'IL', Covaid_Region__c = region.Id, FIPS__c = 17043);
        insert county;

        Municipality__c municipality = [SELECT Id FROM Municipality__c LIMIT 1][0];
        Account newAccount = TestUtils.buildAccount('Test New Account', municipality.Id,'Accel Account');
        newAccount.ShippingStreet = '4619 Main';
        newAccount.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
        newAccount.ShippingPostalCode = '60532';
        newAccount.ShippingCountry = 'US';
        insert newAccount;

        String censusResponse = QueueableCountyUpdaterLive.TEST_JSON_RESPONSE;
        String ep = QueueableCountyUpdaterLive.BASE_EP+newAccount.ShippingLatitude+'&longitude=' + newAccount.ShippingLongitude + '&format=json';


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', censusResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            //simulate data.com but avoid the triggers since we can't chain queueables in unit test code.
            QueueableMuniUpdater.doChainJob = false;
            newAccount.ShippingLatitude = 42.795778000000000;
            newAccount.ShippingLongitude = -87.075013000000000;
            update newAccount;

            QueueableCountyUpdaterLive q = new QueueableCountyUpdaterLive(new Set<Id>{newAccount.Id},false);
            System.enqueueJob(q);

            Test.stopTest();

            newAccount = [SELECT Id, County_LU__c, Covid_Region_LU__c,County_LU_Auto_Update__c FROM Account WHERE Id = :newAccount.Id];
            System.assertEquals(county.Id, newAccount.County_LU__c);
            System.assertEquals(region.Id, newAccount.Covid_Region_LU__c);
        }
    }
    @IsTest
    static void test_Queueable_County_Updater_Live_Insert_NoGeoInfo() {

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
      //  newAccount.County__c = null;
        newAccount.Covid_Region_LU__c = null;
        insert newAccount;


        System.runAs(uAdmin) {

            Test.startTest();

            QueueableCountyUpdaterLive q = new QueueableCountyUpdaterLive(new Set<Id>{newAccount.Id},false);
            System.enqueueJob(q);

            Test.stopTest();

            newAccount = [SELECT Id, County_LU__c, Covid_Region_LU__c,County_LU_Auto_Update__c FROM Account WHERE Id = :newAccount.Id];
            System.assertEquals(newAccount.County_LU__c, null);
            System.assertEquals(newAccount.Covid_Region_LU__c, null);
        }
    }
}