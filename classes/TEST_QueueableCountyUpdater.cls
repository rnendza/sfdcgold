@IsTest
private class TEST_QueueableCountyUpdater {

    public static String ADMINUNAME = 'acceltestadmin@accel.com';
    public static User uAdmin = TestUtils.getUserForTest(ADMINUNAME);

    @testSetup
    static void setup() {

        System.runAs(uAdmin) {
            Test.startTest();

            List<Municipality__c> munis = TestUtils.createMunicipalities('muni name', 1);
            Account account = TestUtils.buildAccount('account name', munis[0].id);
            account.ShippingStreet = '4916 Main Street Unit 2';
            account.ShippingCity = 'Lisle';
            account.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
            account.ShippingPostalCode = '60532';
            account.ShippingCountry = 'US';
            account.ShippingLatitude = 41.795778000000000;
            account.ShippingLongitude = -88.075013000000000;
            insert account;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_Queueable_County_Updater_Insert_Positive() {
        Account account = [SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
        System.debug('--- acount=' + account);
        String ep = QueueableCountyUpdater.BASE_EP + account.ShippingLatitude + '&longitude=' + account.ShippingLongitude + '&format=json';

        String getResponse = '{"Block":{"FIPS":"170438460033003","bbox":[-88.077141,41.793499,-88.074175,41.79639]},"County":{"FIPS":"17043","name":"DuPage"},"State":{"FIPS":"17","code":"IL","name":"Illinois"},"status":"OK","executionTime":"0"}';
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableCountyUpdater q = new QueueableCountyUpdater(1, false);
            System.enqueueJob(q);
            q.performExecute();
            q.writeLog();
            Test.stopTest();

            account = [SELECT Id,  Shipping_Address_Accuracy__c,County_Auto_Updated__c FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
          //  System.assertEquals('DuPage', account.County__c);
            System.debug('acc---->'+account.Shipping_Address_Accuracy__c);

        }
    }

    @IsTest
    static void test_Queueable_County_Updater_Insert_State_Positive() {
        Account account = [SELECT Id, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
        System.debug('--- acount=' + account);
        String ep = QueueableCountyUpdater.BASE_EP + account.ShippingLatitude + '&longitude=' + account.ShippingLongitude + '&format=json';

        String getResponse = '{"Block":{"FIPS":"170438460033003","bbox":[-88.077141,41.793499,-88.074175,41.79639]},"County":{"FIPS":"17043","name":"DuPage"},"State":{"FIPS":"17","code":"IL","name":"Illinois"},"status":"OK","executionTime":"0"}';
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableCountyUpdater q = new QueueableCountyUpdater(1, false,'IL');
            System.enqueueJob(q);
            q.performExecute();
            q.writeLog();
            Test.stopTest();

            account = [SELECT Id, Shipping_Address_Accuracy__c,County_Auto_Updated__c FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
         //  System.assertEquals('DuPage', account.County__c);
            System.debug('acc---->'+account.Shipping_Address_Accuracy__c);

        }
    }

    @IsTest
    static void test_Queueable_County_Updater_Insert_Negative() {
        Account account = [SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
        System.debug('--- acount=' + account);
        String ep = QueueableCountyUpdater.BASE_EP + account.ShippingLatitude + '&longitude=' + account.ShippingLongitude + '&format=json';

        String getResponse = '{"Block":{"FIPS":"170438460033003","bbox":[-88.077141,41.793499,-88.074175,41.79639]},"County":{"FIPS":"17043","name":"DuPage"},"State":{"FIPS":"17","code":"IL","name":"Illinois"},"status":"OK","executionTime":"0"}';
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {
            account.addError('blah');
            Test.startTest();
            QueueableCountyUpdater q = new QueueableCountyUpdater(1, false);
            System.enqueueJob(q);
            q.performExecute();
            q.writeLog();
            Test.stopTest();

            account = [SELECT Id,  County_Auto_Updated__c FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
        //    System.assertEquals('DuPage', account.County__c);

        }
    }


    @IsTest
    static void test_Clear_Auto_Update_Checkbox_Positive() {
        Account account = [SELECT Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude FROM Account WHERE ShippingStreet = '4916 Main Street Unit 2'];
        System.debug('--- acount=' + account);
        String ep = QueueableCountyUpdater.BASE_EP + account.ShippingLatitude + '&longitude=' + account.ShippingLongitude + '&format=json';

        String getResponse = '{"Block":{"FIPS":"170438460033003","bbox":[-88.077141,41.793499,-88.074175,41.79639]},"County":{"FIPS":"17043","name":"DuPage"},"State":{"FIPS":"17","code":"IL","name":"Illinois"},"status":"OK","executionTime":"0"}';
        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse('GET', getResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableCountyUpdater q = new QueueableCountyUpdater(1, false);
            System.enqueueJob(q);
            q.clearAutoUpdateCheckbox();
            Test.stopTest();
        }
    }
}