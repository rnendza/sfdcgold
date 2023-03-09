@IsTest
private class TEST_QueueableMuniSample {

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
    static void test_Queueable_County_Updater_Insert_Positive() {
        Account account = [SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];

       // Account account = [SELECT Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];

        System.debug('--- acount=' + account);


        String getResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);

        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableMuniSample q = new QueueableMuniSample();
            q.performExecute();
            Test.stopTest();
        }
    }

    @IsTest
    static void test_Queueable_Muni_Gmuni_Not_Found() {
        Account account = [SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];

       // Account account = [SELECT Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];

        System.debug('--- acount=' + account);


        String getResponse = TEST_GoogleGeocodeJsonToApex.testJsonInValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);

        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableMuniSample q = new QueueableMuniSample();
            q.performExecute();
            Test.stopTest();
        }
    }
}