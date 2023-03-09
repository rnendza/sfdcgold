@IsTest
private class TEST_BatchCountyRegion_Lu_Patch {

    public static String ADMINUNAME = 'acceltestadmin@accel.com';
    public static User uAdmin = TestUtils.getUserForTest(ADMINUNAME);

    @testSetup
    static void setup() {

        System.runAs(uAdmin) {
            Test.startTest();

            List<Municipality__c> munis = TestUtils.createMunicipalities('muni name', 1);

            Municipality__c muni = [SELECT Id, State__c FROM Municipality__c];
            muni.State__c = 'GA';
            update muni;

            Account account = TestUtils.buildAccount('account name', muni.Id);
            account.ShippingStreet = '4916 Main Street Unit 2';
            account.ShippingCity = 'Lisle';
            account.ShippingState = 'GA';  //  Be careful of we implement state / country picklists!
            account.ShippingPostalCode = '60532';
            account.ShippingCountry = 'US';
         //   account.County__c = 'Dupage';
            account.ShippingLatitude = 41.795778000000000;
            account.ShippingLongitude = -88.075013000000000;
            insert account;

            Region__c region = new Region__c(Name = 'Region 1', State__c = 'IL');
            insert region;

            Region__c region2 = new Region__c(Name = 'GA Region 1', State__c = 'GA');
            insert region2;

            County__c county = new County__c(Name = 'DuPage', State__c = 'IL', Covaid_Region__c = region.Id);
            insert county;

            County__c county2 = new County__c(Name = 'DuPage', State__c = 'GA', Covaid_Region__c = region2.Id);
            insert county2;

            Test.stopTest();
        }
    }

    @IsTest
    static void test_Batch_County_Lookup_Updater_Insert_Positive() {

        County__c county = [SELECT Id, Name FROM County__c WHERE Name = 'DuPage' AND State__c = 'IL'];
        Account account = [
                SELECT Id,  County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude
                     //   SELECT Id, County__c, County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude

                FROM Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
     //   account.County__c = county.Name;
        update account;
        // DEFEAT Trigger setting this.
        account.County_LU_Auto_Update__c = false;
        account.Covid_Region_LU__c = null;
        account.County_LU__c = county.Id;
        update account;


        System.runAs(uAdmin) {

            Test.startTest();
            BatchCountyAndRegionLu_Non_IL_Patch b = new BatchCountyAndRegionLu_Non_IL_Patch();
            Database.executeBatch(b, 1);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_Batch_County_Lookup_Updater_Insert_RollItBack() {

        County__c county = [SELECT Id, Name FROM County__c WHERE Name = 'DuPage' AND State__c = 'IL'];
        Account account = [
                SELECT Id, County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude
                      //  SELECT Id, County__c, County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude

                FROM Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
      //  account.County__c = county.Name;
        update account;
        // DEFEAT Trigger setting this.
        account.County_LU_Auto_Update__c = false;
        account.Covid_Region_LU__c = null;
        account.County_LU__c = county.Id;
        update account;

        System.runAs(uAdmin) {

            Test.startTest();
            BatchCountyAndRegionLu_Non_IL_Patch b = new BatchCountyAndRegionLu_Non_IL_Patch(true);
            Database.executeBatch(b, 1);
            Test.stopTest();
        }
    }


    @IsTest
    static void test_Batch_County_Lookup_Updater_Insert_Log_Existing() {
        County__c county = [SELECT Id, Name FROM County__c WHERE Name = 'DuPage' AND State__c = 'IL'];
        Account account = [
                SELECT Id, County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude
                     //   SELECT Id, County__c, County_Auto_Updated__c,County_LU_Auto_Update__c,ShippingLatitude,ShippingLongitude

                FROM Account
                WHERE ShippingStreet = '4916 Main Street Unit 2'
        ];
       // account.County__c = county.Name;
        update account;
        // DEFEAT Trigger setting this.
        account.County_LU_Auto_Update__c = false;
        account.Covid_Region_LU__c = null;
        account.County_LU__c = county.Id;
        update account;


        System.runAs(uAdmin) {

            Test.startTest();

            String jobName = 'BatchCountyAndRegionLu_Non_IL_Patch';
            String rtDevName ='Salesforce_Jobs';
            Id rtId =  SObjectType.Accel_Application_Error__c.getRecordTypeInfosByDeveloperName().get(rtDevName).getRecordTypeId();
            Accel_Application_Error__c log = new Accel_Application_Error__c(RecordTypeId = rtId, Job_Name__c = jobName);
            insert log;
            BatchCountyAndRegionLu_Non_IL_Patch b = new BatchCountyAndRegionLu_Non_IL_Patch();
            Database.executeBatch(b,1);
            Test.stopTest();

        }
    }
}