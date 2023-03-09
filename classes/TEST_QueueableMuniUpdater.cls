@IsTest
private class TEST_QueueableMuniUpdater {

    public static String ADMINUNAME = 'acceltestadmin@accel.com';
    public static User uAdmin = TestUtils.getUserForTest(ADMINUNAME);

    @testSetup
    static void setup() {

        System.runAs(uAdmin) {
            Test.startTest();

            List<Municipality__c> munisIL = TestUtils.createMunicipalities('Carol Stream', 1);
            for(Municipality__c muni : munisIL) {
                muni.Name = muni.Name.replace('0','');
            }
            update munisIL;


            List<Municipality__c> munisPA = TestUtils.createMunicipalities(' Warminster Township', 1);
            munisPA.addAll(TestUtils.createMunicipalities('Brookville Borough', 1));
            munisPA.addAll(TestUtils.createMunicipalities('New Milford Township', 1));

            for(Municipality__c muni : munisPA) {
                muni.Name = muni.Name.replace('0','');
                muni.State__c = 'PA';
            }
            update munisPA;


            List<Account> accounts = new List<Account>();

            Account account = TestUtils.buildAccount('account name', munisIL[0].id);
            account.MunicipalityLookup__c = null;
            account.ShippingStreet = '4916 Main Street Unit 2';
            account.ShippingCity = 'Lisle';
            account.ShippingState = 'IL';  //  Be careful of we implement state / country picklists!
            account.ShippingPostalCode = '60532';
            account.ShippingCountry = 'US';
            account.ShippingLatitude = 41.795778000000000;
            account.ShippingLongitude = -88.075013000000000;
            account.County_Auto_Updated__c = true;
            accounts.add(account);

            Account account2 = TestUtils.buildAccount('PA Township account name', munisPA[0].id);
            account2.MunicipalityLookup__c = null;
            account2.ShippingStreet = '890 E Street Rd';
            account2.ShippingCity = 'Warminster';
            account2.ShippingState = 'PA';  //  Be careful of we implement state / country picklists!
            account2.ShippingPostalCode = '18974';
            account2.ShippingCountry = 'US';
            account2.ShippingLatitude = 40.183761000000000;
            account2.ShippingLongitude = -75.058859000000000;
            account2.County_Auto_Updated__c = true;
            accounts.add(account2);


            Account account3 = TestUtils.buildAccount('PA Borough account name', munisPA[1].id);
            account3.MunicipalityLookup__c = null;
            account3.ShippingStreet = '245 Allegheny Blvd Ste A';
            account3.ShippingCity = 'Brookville';
            account3.ShippingState = 'PA';  //  Be careful of we implement state / country picklists!
            account3.ShippingPostalCode = '15825';
            account3.ShippingCountry = 'US';
            account3.ShippingLatitude = 41.172705000000000;
            account3.ShippingLongitude = -79.100586000000000;
            account3.County_Auto_Updated__c = true;
            accounts.add(account3);

            Account account4 = TestUtils.buildAccount('PA Township street num as opposed to addy name', munisPA[2].id);
            account4.MunicipalityLookup__c = null;
            account4.ShippingStreet = '1623 Oliver Rd # Exit219';
            account4.ShippingCity = 'New Milford';
            account4.ShippingState = 'PA';  //  Be careful of we implement state / country picklists!
            account4.ShippingPostalCode = '18834';
            account4.ShippingCountry = 'US';
            account4.ShippingLatitude = 41.8673559;
            account4.ShippingLongitude = -75.6906241;
            account4.County_Auto_Updated__c = true;
            accounts.add(account4);


            insert accounts;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_Queueable_Muni_Updater_Positive() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c
                     //   SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c

                FROM    Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        Set<Id> accountIds = new Set<Id>{account.Id};

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            QueueableMuniUpdater qNoArgs = new QueueableMuniUpdater();
            QueueableMuniUpdater qOneArg = new QueueableMuniUpdater(accountIds);
            QueueableMuniUpdater qPrimary = new QueueableMuniUpdater(accountIds,false);

            qPrimary.performExecute();
            Test.getEventBus().deliver();

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
            System.assert(a.MunicipalityLookup__c != null);
            System.assert(a.Muni_Auto_Updated__c);

            Accel_Application_Error__c log = [
                    SELECT Id, Overall_Job_Status__c,Account__c
                    FROM   Accel_Application_Error__c
                    WHERE  Account__c = :account.Id
                    AND    Job_Name__c = :QueueableMuniUpdater.jobName
            ];
            System.assert(log.Overall_Job_Status__c == 'Success');
            System.assert(qPrimary.platformEventSaveResult.success);

        }
    }

    @IsTest
    static void test_Queueable_Muni_Updater_PA_Township_Positive() {

        Account account = [
                SELECT  Id, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c
                     //   SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c

                FROM    Account
                WHERE ShippingStreet = '890 E Street Rd'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        Set<Id> accountIds = new Set<Id>{account.Id};

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuniPATownship;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            QueueableMuniUpdater qPrimary = new QueueableMuniUpdater(accountIds,false);

            qPrimary.performExecute();
            Test.getEventBus().deliver();

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
            System.assert(a.MunicipalityLookup__c != null);
            System.assert(a.Muni_Auto_Updated__c);

            Accel_Application_Error__c log = [
                    SELECT Id, Overall_Job_Status__c,Account__c
                    FROM   Accel_Application_Error__c
                    WHERE  Account__c = :account.Id
                    AND    Job_Name__c = :QueueableMuniUpdater.jobName
            ];
            System.assert(log.Overall_Job_Status__c == 'Success');
            System.assert(qPrimary.platformEventSaveResult.success);

        }
    }

    @IsTest
    static void test_Queueable_Muni_Updater_PA_Borough_Positive() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c
                       // SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c

                FROM    Account
                WHERE ShippingStreet = '245 Allegheny Blvd Ste A'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        Set<Id> accountIds = new Set<Id>{account.Id};

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuniPABorough;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            QueueableMuniUpdater qPrimary = new QueueableMuniUpdater(accountIds,false);

            qPrimary.performExecute();
            Test.getEventBus().deliver();

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
            System.assert(a.MunicipalityLookup__c != null);
            System.assert(a.Muni_Auto_Updated__c);

            Accel_Application_Error__c log = [
                    SELECT Id, Overall_Job_Status__c,Account__c
                    FROM   Accel_Application_Error__c
                    WHERE  Account__c = :account.Id
                    AND    Job_Name__c = :QueueableMuniUpdater.jobName
            ];
            System.assert(log.Overall_Job_Status__c == 'Success');
            System.assert(qPrimary.platformEventSaveResult.success);

        }
    }
    /**
     * kinda a shitty address on the account. closest we can come is street number as opposed to street address
     * JSOn shape changes.
     */
    @IsTest
    static void test_Queueable_Muni_Updater_PA_Street_Number_Positive() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c
                      //  SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c

                FROM    Account
                WHERE ShippingStreet = '1623 Oliver Rd # Exit219'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        Set<Id> accountIds = new Set<Id>{account.Id};

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuniStreetNumber;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            QueueableMuniUpdater qPrimary = new QueueableMuniUpdater(accountIds,false);

            qPrimary.performExecute();
            Test.getEventBus().deliver();

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
            System.assert(a.MunicipalityLookup__c != null);
            System.assert(a.Muni_Auto_Updated__c);

            Accel_Application_Error__c log = [
                    SELECT Id, Overall_Job_Status__c,Account__c
                    FROM   Accel_Application_Error__c
                    WHERE  Account__c = :account.Id
                    AND    Job_Name__c = :QueueableMuniUpdater.jobName
            ];
            System.assert(log.Overall_Job_Status__c == 'Success');
            System.assert(qPrimary.platformEventSaveResult.success);

        }
    }
    @IsTest
    static void test_Queueable_Muni_Gmuni_Not_Found_In_Accel() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c,
                        Muni_Auto_Updated__c
                               // SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c,
                       // Muni_Auto_Updated__c
                FROM    Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        System.assert(!account.Muni_Auto_Updated__c);
        Set<Id> accountIds = new Set<Id>{account.Id};

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
            QueueableMuniUpdater q = new QueueableMuniUpdater(accountIds,false);
            q.performExecute();
            Test.stopTest();
        }

        Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
        System.assert(a.MunicipalityLookup__c == null);
        System.assert(!a.Muni_Auto_Updated__c);

        Accel_Application_Error__c log = [
                SELECT Id, Overall_Job_Status__c,Account__c
                FROM   Accel_Application_Error__c
                WHERE  Account__c = :account.Id
                AND    Job_Name__c = :QueueableMuniUpdater.jobName
        ];
        System.assert(log.Overall_Job_Status__c == 'Failed');
    }

    /**
     * if the queueable ran with an account without lat / long. make sure there is no callout.l
     */
    @IsTest
    static void test_Queueable_Muni_Bad_Data_No_Callout() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c,
                        Muni_Auto_Updated__c
                               // SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c,
                       // Muni_Auto_Updated__c
                FROM    Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
        account.ShippingLongitude = null;
        account.ShippingLatitude = null;
        update account;

        System.assert(account.MunicipalityLookup__c == null);
        System.assert(!account.Muni_Auto_Updated__c);
        Set<Id> accountIds = new Set<Id>{account.Id};

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableMuniUpdater q = new QueueableMuniUpdater(accountIds,false);
            q.performExecute();
            Test.stopTest();
        }

        Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
        System.assert(a.MunicipalityLookup__c == null);
        System.assert(!a.Muni_Auto_Updated__c);

        Accel_Application_Error__c log = [
                SELECT Id, Overall_Job_Status__c,Account__c
                FROM   Accel_Application_Error__c
                WHERE  Account__c = :account.Id
                AND    Job_Name__c = :QueueableMuniUpdater.jobName
        ];
        System.assert(log.Overall_Job_Status__c == 'Failed');
    }

    @IsTest
    static void test_Queueable_Invalid_Http_ResponseCode() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c,
                        Muni_Auto_Updated__c
                               // SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c,
                       // Muni_Auto_Updated__c
                FROM    Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        System.assert(!account.Muni_Auto_Updated__c);

        Set<Id> accountIds = new Set<Id>{account.Id};

        String getResponse = TEST_GoogleGeocodeJsonToApex.testJsonInValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);

        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, getResponse);
        getResp.statusCode = 500;

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();
            QueueableMuniUpdater q = new QueueableMuniUpdater(accountIds,false);
            q.performExecute();
            Test.stopTest();
        }

        Account a = [SELECT Id, MunicipalityLookup__c,Muni_Auto_Updated__c FROM Account WHERE Id = :account.Id ];
        System.assert(a.MunicipalityLookup__c == null);
        System.assert(!a.Muni_Auto_Updated__c);

        Accel_Application_Error__c log = [
                SELECT Id, Overall_Job_Status__c,Account__c
                FROM   Accel_Application_Error__c
                WHERE  Account__c = :account.Id
                AND    Job_Name__c = :QueueableMuniUpdater.jobName
        ];
        System.assert(log.Overall_Job_Status__c == 'Failed');
    }
    @IsTest
    static void test_Queueable_Muni_Updater_Force_CalloutException() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,
                        MunicipalityLookup__c,Muni_Auto_Updated__c

                              //  SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,
                      //  MunicipalityLookup__c,Muni_Auto_Updated__c

                FROM    Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        System.assert(!account.Muni_Auto_Updated__c);

        Set<Id> accountIds = new Set<Id>{account.Id};

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;


        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        System.runAs(uAdmin) {

            Test.startTest();

            QueueableMuniUpdater qPrimary = new QueueableMuniUpdater(accountIds,false);

            QueueableMuniUpdater.makeCallout = false;
            System.enqueueJob(qPrimary);
            qPrimary.performExecute();

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c FROM Account WHERE Id = :account.Id ];
            System.assert(a.MunicipalityLookup__c == null);

            Accel_Application_Error__c log = [
                    SELECT Id, Overall_Job_Status__c,Account__c
                    FROM   Accel_Application_Error__c
                    WHERE  Account__c = :account.Id
                    AND    Job_Name__c = :QueueableMuniUpdater.jobName
            ];
            System.assert(log.Overall_Job_Status__c == 'Failed');
        }
    }

    @IsTest
    static void test_Queueable_Muni_Updater_Positive_SendEmail() {

        Account account = [
                SELECT  Id,  County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c
                      //  SELECT  Id, County__c, County_Auto_Updated__c,ShippingLatitude,ShippingLongitude,MunicipalityLookup__c

                FROM    Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
        System.assert(account.MunicipalityLookup__c == null);
        Set<Id> accountIds = new Set<Id>{account.Id};

        String googleResponse = TEST_GoogleGeocodeJsonToApex.testJsonValidMuni;
        Google_Setting__mdt mdt = GoogleSvc.queryForMetadata(GoogleTransaction.GEOCODING.name());
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String ep = httpRequest.getEndpoint() + '&latlng='+account.ShippingLatitude + ',' + account.ShippingLongitude;

        MockHttpResponseHandler.SimpleMockResponse getResp =
                new MockHttpResponseHandler.SimpleMockResponse(mdt.Http_Method__c, googleResponse);

        MockHttpResponseHandler mock = new MockHttpResponseHandler();
        System.debug('---> mock ep = ' + ep);
        mock.addResponse(ep, getResp);
        Test.setMock(HttpCalloutMock.class, mock);

        uAdmin = [SELECT Id, Username FROM User WHERE Id = :uAdmin.Id];

        System.runAs(uAdmin) {

            Test.startTest();

            QueueableMuniUpdater.SEND_EMAIL = TRUE;
            QueueableMuniUpdater.TEST_EMAIL_USERNAMES = uAdmin.Username;
            QueueableMuniUpdater qPrimary = new QueueableMuniUpdater(accountIds,false);

            qPrimary.performExecute();
            Test.getEventBus().deliver();

            Test.stopTest();

            Account a = [SELECT Id, MunicipalityLookup__c FROM Account WHERE Id = :account.Id ];
            System.assert(a.MunicipalityLookup__c != null);

            Accel_Application_Error__c log = [
                    SELECT Id, Overall_Job_Status__c,Account__c
                    FROM   Accel_Application_Error__c
                    WHERE  Account__c = :account.Id
                    AND    Job_Name__c = :QueueableMuniUpdater.jobName
            ];
            System.assert(log.Overall_Job_Status__c == 'Success');
            System.assert(qPrimary.platformEventSaveResult.success);
        }
    }
}