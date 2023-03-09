public with sharing class  AccountFields {
    @auraEnabled

    public static List<String> getValues() {
        
         List<String> pickListValuesList = new List<String>();
Schema.DescribeFieldResult fieldResult = WorkOrderLineItem.PM_Status__c.getDescribe();
 List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();

for (Schema.PicklistEntry pickListVal : ple) {
    pickListValuesList.add(pickListVal.getLabel());
   // system.debug('---- pl value= ' + pickListVal.getLabel());
     
}
        return pickListValuesList;
 
    }
        
    @auraEnabled public static List<Asset> getAssets(String keyword){
        String keyword1 = keyword + '%';
        List<Asset> returnList = new List<Asset>();
        List<Asset> searching = [Select id, Name from Asset Where Name Like: keyword1];
        
        for (Asset sr: searching) {
            returnList.add(sr);
        }
        return returnList;
    }
    
    @auraEnabled public static List<Asset> getAsset(Id key){
        
         List<Asset> VGT = [Select Id, Model__c, Name From Asset Where Asset.Account.Id = :key And RecordTypeId = '0121I000000W9wyQAC'];
        Return VGT;//
    }
    
    @auraEnabled (cacheable=true)
 public static Account getAccount(Id key){
    Return  [Select id, Name, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity, IGB_License__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__c,VGT_7__c,VGT_8__c,VGT_9__c, VGT_10__c, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name,VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name,VGT_10__r.Name, VGT_10__r.Model__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c,  VGT_10__r.SAS__c, Redemption__c, Redemption__r.Model__c from Account Where Id = :key ];
       //Id Thing = Assets.VGT_1__c;
       // system.debug(Thing);
      // return Thing;
    }
    @AuraEnabled
    public static user fetchUser(){
        User u = [select id, Name, ProfileId from User where Id =: userInfo.getUserId()];
        return u;


    }


    @auraEnabled public static Asset getPosition1(Id key){
        
        
        //Account getAc = new Account();
       // getAc = [Select Id from Account Where Id =:key ];

        //RJN Commented out due to hardcoding  account name
        // Return [Select Id, Name, Model__c, SAS__c, Account.Name From Asset Where SAS__c='1' And Account.Name = 'Gold Star' ];
        List<Asset>  position1Assets =  [
                SELECT Id,Name,Model__c,SAS__c,Account.Name
                FROM   Asset
                WHERE  SAS__c = '1'
                AND    AccountId = :key
        ];
        Asset position1Asset;
        if(!position1Assets.isEmpty()) {
            position1Asset = position1Assets[0];
        }
        return position1Asset;
    }
    
    @auraEnabled public static Asset getPosition2(Id key){
        Return [Select Id, Name, Model__c, SAS__c  From Asset Where SAS__c ='2' And AccountId =:key];
    }
    
    @auraEnabled public static Asset getPosition3(Id key){
        Return [Select Id, Name, Model__c, SAS__c  From Asset Where SAS__c ='3' And AccountId =:key];
    }
    
    @auraEnabled public static Asset getPosition4(Id key){
        Return [Select Id, Name, Model__c, SAS__c  From Asset Where SAS__c ='4' And AccountId =:key];
    }
    
    @auraEnabled public static Asset getPosition5(Id key){
        Return [Select Id, Name, Model__c, SAS__c  From Asset Where SAS__c ='5' And AccountId =:key];
    }
        @AuraEnabled
  public static String getUserName() {
    return UserInfo.getName();
  }
  

    
 @auraEnabled (cacheable=true)
  public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, String CheckParam) {
        system.debug('ObjectName-->' + ObjectName);
        String searchKey = '%' +searchKeyWord + '%';
        //UserInfo.getUserId()
        List < sObject > returnList = new List < sObject > ();
        List < sObject > returnList1 = new List < sObject > ();
      //String Name = UserInfo.getName();
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5

        String parmUName = UserInfo.getName();
      Id key = '00e1I000001NG0z';
      String profile =userinfo.getProfileId(); //00e1I000001NG0z
     /* if(UserInfo.getProfileId()==key){
               String sQuery1 =  'select id, Name, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,IGB_License__c,VGT_10__c, VGT_10__r.Name, VGT_10__r.Model__c, VGT_10__r.SAS__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_6__c, VGT_7__c, VGT_8__c, VGT_9__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, Redemption__c, Redemption__r.Model__c from ' +ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 10';
        List < sObject > lstOfRecords1 = Database.query(sQuery1);
        
        for (sObject obje: lstOfRecords1) {
            returnList1.add(obje);
        }
        return returnList1;
    } */




     String ServiceResources = 'select id, Location_Type__c, Name, County__c,VGT_10__c, VGT_10__r.Name, VGT_10__r.Model__c, VGT_10__r.SAS__c, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,IGB_License__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_6__c, VGT_7__c, VGT_8__c, VGT_9__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, Redemption__c, Redemption__r.Model__c from ' +ObjectName + ' Where Name LIKE: searchKey And Service_Territory__c in (Select Service_Territory__c From Service_Territory_Resources__c Where Service_Resource__r.Accel_User__r.Name =: parmUName) limit 10';

     //Query All Accounts within a specific service Territory
        String ServiceAccounts = 'select id, Location_Type__c, Name, County__c,VGT_10__c, VGT_10__r.Name, VGT_10__r.Model__c, VGT_10__r.SAS__c, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,IGB_License__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_6__c, VGT_7__c, VGT_8__c, VGT_9__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, Redemption__c, Redemption__r.Model__c from ' +ObjectName + ' Where Name LIKE: searchKey And Service_Territory__c in (Select ServiceTerritoryId From ServiceTerritoryMember Where ServiceResource.Accel_User__r.Name =: parmUName) limit 10';

     // Query all accounts that the current running user is assigned too
        String sQuery =  'select id, Location_Type__c, Name, County__c,VGT_10__c, VGT_10__r.Name, VGT_10__r.Model__c, VGT_10__r.SAS__c, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,IGB_License__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_6__c, VGT_7__c, VGT_8__c, VGT_9__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, Redemption__c, Redemption__r.Model__c from ' +ObjectName + ' where Name LIKE: searchKey And Assigned_PM_Tech__c = :parmUName order by createdDate DESC limit 10';

      
       // Query ALL Accounts
        String AllAccounts =  'select id, Location_Type__c, Name, County__c,VGT_10__c, VGT_10__r.Name, VGT_10__r.Model__c, VGT_10__r.SAS__c, BillingStreet,BillingCity,BillingState,BillingPostalCode,ShippingStreet,ShippingCity,IGB_License__c, VGT_6__r.SAS__c, VGT_7__r.SAS__c, VGT_8__r.SAS__c, VGT_9__r.SAS__c, VGT_6__r.Model__c, VGT_7__r.Model__c, VGT_8__r.Model__c, VGT_9__r.Model__c, VGT_6__c, VGT_7__c, VGT_8__c, VGT_9__c, VGT_1__c, VGT_2__c, VGT_3__c, VGT_4__c, VGT_5__c, VGT_6__r.Name, VGT_7__r.Name, VGT_8__r.Name, VGT_9__r.Name, VGT_1__r.Name, VGT_2__r.Name, VGT_3__r.Name, VGT_4__r.Name, VGT_5__r.Name, VGT_5__r.Model__c, VGT_1__r.Model__c, VGT_2__r.Model__c, VGT_3__r.Model__c, VGT_4__r.Model__c,VGT_1__r.SAS__c, VGT_2__r.SAS__c, VGT_3__r.SAS__c, VGT_4__r.SAS__c, VGT_5__r.SAS__c, Redemption__c, Redemption__r.Model__c from ' +ObjectName +' where Name LIKE: searchKey Limit 15';
      
     // Switch on Yes {
        if(CheckParam=='Yes') {
       //     when  'Yes' {

         List < sObject > lstOfRecords = Database.query(sQuery);

         for (sObject obj : lstOfRecords) {
             returnList.add(obj);
         }
         return returnList;


     }
      
     if(CheckParam == 'Other'){
              List < sObject > lstOfRecords = Database.query(AllAccounts);

         for (sObject obj : lstOfRecords) {
             returnList.add(obj);
         }
         return returnList;
      }

    else  {
  // when  'No' {
        List < sObject > lstOfRecords = Database.query(ServiceResources);

        for (sObject obj : lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;

    
	
    /*  else{
          {
  // when  'No' {
        List < sObject > lstOfRecords = Database.query(ServiceResources);

        for (sObject obj : lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;

    }*/
      }
	

       
  }

}