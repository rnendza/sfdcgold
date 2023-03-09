@isTest

private class TEST_AccountFields {
        @testSetup static void setup() {
     
            //Test.startTest();  //merely to reset gov limits to get around cpu time

            TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
            //----- RJN Override base params to basically not test in a bulk safe fashion and only create one of each
            //----- do processes don't blow chunks.
//            params.iNumMunis = 1;
//            params.iNumAccountsPerMuni=1;
//            params.iNumWorkOrdersPerCase=1;
//            params.iNumAssetsPerAccount=1;
//            params.iNumServiceTerritoriesPerOppHours=1;
//            params.iNumOppHours=1;
            //----------------------------------------

            TestUtils.createAllDataToServiceAppointments( params );
               List <Account> Testlist = [Select ID, Name, VGT_1__r.SAS__c From Account];
          // Testlist[0].VGT_1__r.SAS__c = '1';
        ID AccountId = Testlist[0].Id;
                Asset TestAsset = TestUtils.buildAsset('TestAsset', AccountId, 'Redemption');
            insert TestAsset;

         Municipality__c testMuni =   TestUtils.createMunicipalities('Test Uni', 1)[0];
           Account testaccount =  TestUtils.buildAccount('Fox Bar', testMuni.Id);

            OperatingHours oppHours = testUtils.buildOppHours('test', 'America/Los_Angeles', 1)[0];

            insert oppHours;

            ServiceTerritory testTerr = testUtils.buildServiceTerritories('test',oppHours.Id,1)[0];

            insert testTerr;




           User testCed = testUtils.createUserForTest('PatZ@accelentertainment.com');

            User ced = [select name from User where name = 'Cedric Ngwa'];

            //insert ced;
          //  insert testCed;

            ServiceResource testServ = testUtils.buildServiceResource('Cedric Ngwa',UserInfo.getUserId())[0];
          //  UserINfo.get
            Id userId = UserInfo.getUserId();
            testServ.Accel_User__r = ced;

            insert testServ;


            ServiceTerritoryMember testMem = testUtils.buildServiceTerritoryMember(testServ.Id, testTerr.Id, oppHours.Id, 'P', DateTime.newInstance(2018, 1, 31, 7, 8, 16) , DateTime.newInstance(2019, 1, 31, 7, 8, 16));
            testMem.ServiceTerritory = testTerr;
            testMem.ServiceTerritoryId = testTerr.Id;
            testMem.ServiceResource = testServ;
            testMem.ServiceResourceId = testServ.Id;
            testMem.ServiceResource.Accel_User__r= ced;
            insert testMem;

            Service_Territory_Resources__c getServ = new Service_Territory_Resources__c();

            getServ.Service_Territory__c = testTerr.Id;

            getServ.Service_Resource__c = testServ.Id;

            insert getServ;

            testaccount.Assigned_PM_Tech__c = 'Cedric Ngwa';

            testaccount.Service_Territory__c= testTerr.Id;
            insert testaccount;
            Asset Asset1 = TestUtils.buildAsset('Test1', AccountId, 'Redemption');
            Asset Asset2 = TestUtils.buildAsset('Test2', AccountId, 'Redemption');
            Asset Asset3 = TestUtils.buildAsset('Test3', AccountId, 'Redemption');
            Asset Asset4 = TestUtils.buildAsset('Test4', AccountId, 'Redemption');
            Asset Asset5 = TestUtils.buildAsset('Test5', AccountId, 'Redemption');
            Asset1.SAS__c = '1';
            Asset2.SAS__c = '2';
            Asset3.SAS__c = '3';
            Asset4.SAS__c = '4';
            Asset5.SAS__c = '5';
            
            insert Asset1;
            insert Asset2;
            insert Asset3;
            insert Asset4;
            insert Asset5;
            
          
            
            /*List<account> accounts = [Select ID, Name, Assigned_PM_Tech__c From Account];
            
            For(account acc : accounts){
                acc.Assigned_PM_Tech__c = Userinfo.getName();
                acc.VGT_1__r = Asset1;
            }
            
            update accounts; */
            
            List<account> get = [Select ID, Name, VGT_1__r.SAS__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c From Account];
            For(account g : get){
                g.VGT_1__c = Asset1.Id;
                g.VGT_2__c = Asset2.Id;
                 g.VGT_3__c = Asset3.Id;
                 g.VGT_4__c = Asset4.Id;
                 g.VGT_5__c = Asset5.Id;
                
                
            }
            update get; 

//            List<Account> accounts = [
//                    SELECT  Id, Name, Assigned_PM_Tech__c
//                    FROM    Account
//            ];
//            for(Account account : accounts) {
//                account.Assigned_PM_Tech__c = UserInfo.getName();
//                account.Name = 'Acc ' + account.Name;
//                System.debug('Cedric debug account='+account);
//            }
//            update accounts;


           
         /*   String sQuery =  'select id, Name, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,IGB_License__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_6__c, VGT_7__c, VGT_8__c, VGT_9__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, Redemption__c, Redemption__r.Model__c from Account order by createdDate DESC limit 5';
        List < sObject > lstOfRecords = Database.query(sQuery);
          List < sObject > returnList1 = new List < sObject > ();
        for (sObject obj: lstOfRecords) {
            returnList1.add(obj);
                }
            insert returnList1; */
            
      //    List<Municipality__c> Testt = TestUtils.createMunicipalities('TestM12', 1);
      //    insert Testt;
            
     //      Account Account12 = TestUtils.buildAccount('Account1', Testt[0].Id, 'Accel Account');
          
        // insert Account12;
         //   User Me = new User();
            //insert Me;
           /* TestUtils.createSvcWatchdogUtilityBarSettings(uCallCenter);
            List<Account> accounts = [SELECT Id, ShippingStreet, ShippingCity, ShippingState FROM Account ];
            Integer i = 0;
            for(Account account :accounts) {
                account.ShippingStreet = '123 xyz - '+i;
                account.ShippingCity   = 'Chicago - '+i;
                account.ShippingState  = 'IL';            //  Be careful of we implement state / country picklists!
            }
            update accounts;
           // Test.stopTest(); */
        }
    
    
    @isTest static void testgetAccount(){
        
        List <Account> Testlist = [Select ID From Account];
        
        ID AccountId = Testlist[0].Id;
        
        
        Account  testAccount = AccountFields.getAccount(AccountId);   //'0011I00000uPuwMQAS'
        System.assertEquals(AccountId,testAccount.Id);
        
    }
    
        @isTest static void testgetAsset(){
        
        List <Account> Testlist = [Select ID From Account];
        
        ID AccountId = Testlist[0].Id;
        
        
    List<Asset> TestAsset =      AccountFields.getAsset(AccountId); //'0011I00000uPuwMQAS'
        //System.assertEquals(AccountId,testAccount.Id);
           
        
    }
    
    
    
       @isTest static void testgetPosition1(){
        
        List <Account> Testlist = [Select ID, VGT_1__c  From Account ];
           //Where (VGT_1__r.SAS__c ='1' OR VGT_2__r.SAS__c ='1' OR VGT_3__r.SAS__c ='1' OR VGT_4__r.SAS__c ='1' OR VGT_5__r.SAS__c ='1')
           
        
        ID AccountId = Testlist[0].Id;
        
        
 Asset TestAsset =      AccountFields.getPosition1(AccountId); //'0011I00000uPuwMQAS'
        //System.assertEquals(AccountId,testAccount.Id);
           
        
    }
    
           @isTest static void testgetPosition2(){
        
        List <Account> Testlist = [Select ID, VGT_2__c From Account];
        
        ID AccountId = Testlist[0].Id;
        
        
 Asset TestAsset = AccountFields.getPosition2(AccountId); //'0011I00000uPuwMQAS'
        //System.assertEquals(AccountId,testAccount.Id);
           
        
    }
    
           @isTest static void testgetPosition3(){
        
        List <Account> Testlist = [Select ID From Account];
        
        ID AccountId = Testlist[0].Id;
        
        
 Asset TestAsset =      AccountFields.getPosition3(AccountId); //'0011I00000uPuwMQAS'
        //System.assertEquals(AccountId,testAccount.Id);
           
        
    }
    
           @isTest static void testgetPosition4(){
        
        List <Account> Testlist = [Select ID From Account];
        
        ID AccountId = Testlist[0].Id;
        
        
 Asset TestAsset =      AccountFields.getPosition4(AccountId); //'0011I00000uPuwMQAS'
        //System.assertEquals(AccountId,testAccount.Id);
           
        
    }
    
           @isTest static void testgetPosition5(){
        
        List <Account> Testlist = [Select ID From Account];
        
        ID AccountId = Testlist[0].Id;
        
        
 Asset TestAsset =      AccountFields.getPosition5(AccountId); //'0011I00000uPuwMQAS'
        //System.assertEquals(AccountId,testAccount.Id);
               }
    
    
   //System.runAs(adminUser) {
       @isTest static void testfetchUserInfo(){
       // List<User> Name = [Select Name From User where Id = UserInfo.getId() ];

       // String TestUser = AccountFields.getUserName();

       AccountFields.fetchUser();

       //System.assertEquals(Name[0].Name, TestUser);
   //}
}

    @isTest static void testgetuserName(){
        AccountFields.getUserName();
    }
    
    
    
    @isTest static void testgetAssets(){
        
        
        
        
        List<Asset> getAsset = AccountFields.getAssets('Test1');
        
        
        
        
        
    }
    
    
    @isTest static void testfetchLookupValues(){
        
        
       List< Account> Name1 = [Select Name from Account];
        
        List<Account> Thing = [Select Name From Account];


        Account Acc = new Account(name = 'Acc');

        insert Acc;

        Account Fox = new Account(name='Fox Bar');
        insert Fox;

        String CheckParam;

        List<sObject> Returnagain;

       // Switch on CheckParam{

        //    when 'Yes'{

                List<sObject> returnList = AccountFields.fetchLookUpValues('Fox Bar', 'Account', 'Yes');

            /*    For (Sobject obj : returnList){

                    returnList.add(obj);
                } */


			  List<sObject> returnList2 = AccountFields.fetchLookUpValues('Fox Bar', 'Account', 'Other');


         //   }

           // when 'No'{

                List<sObject> returnList1 = AccountFields.fetchLookUpValues('Fox Bar', 'Account', 'No');


            //}


        }
        



        

    
    
    
    @isTest static void testgetValues(){
      //  List<String> Values = ['Incomplete', 'Not Complete', Co]
      //  
      List<String> getList = AccountFields.getValues();
        
        
    }
    
    
    
    
   /*  @auraEnabled public static List<Asset> getAssets(String keyword){
        String keyword1 = keyword + '%';
        List<Asset> returnList = new List<Asset>();
        List<Asset> searching = [Select id, Name from Asset Where Name Like: keyword1];
        
        for (Asset sr: searching) {
            returnList.add(sr);
        }
        return returnList;*/
	    

}