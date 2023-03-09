trigger Accel_ApplicationCount on LicenseApplication__c ( after insert, after delete, after undelete, after update) {

        List<Account> accUpdateList = new List<Account>();
    LicenseApplication__c app = new LicenseApplication__c();
    List<id> accIdList = new List<id>();
    if(Trigger.isInsert || Trigger.isUndelete || Trigger.isUpdate){
        For( LicenseApplication__c con1 : Trigger.new){
            
            if(con1.Total_Applications__c >= 2 ){
                con1.addError('ERROR : ONLY 1 ACTIVE APPLICATION PER ACCOUNT ALLOWED');
            }
            
           accIdList.add(con1.Location_DBA__c);
            
            //}
      /* List<Account> acc = [SELECT Id,  Total_Applications__c,(SELECT id FROM  License_Applications__r) FROM Account WHERE id =: con1.Location_DBA__r.Id ];
            
           // for(Account a: acc){
            for(integer i=0;i< acc.size();i++){
        acc[i].Total_Applications__c = acc[i].License_Applications__r.size();
        accUpdateList.add(acc[i]);*/
              
            }
          
    }     
         
        
    
    if(Trigger.isDelete){
        For( LicenseApplication__c con1 : Trigger.old){
            accIdList.add(con1.Location_DBA__c);
        }
    }
    
       if(Trigger.isUpdate){
        For( LicenseApplication__c con1 : Trigger.old){
            accIdList.add(con1.Location_DBA__c);
        }
    }
    
    For(Account acc : [SELECT Total_Applications__c,(SELECT id FROM  License_Applications__r Where Application_Status__c != 'Closed') FROM Account WHERE id =: accIdList]){
        acc.Total_Applications__c = acc.License_Applications__r.size();
        
       // if(acc.License_Applications__r.size() > 0){
            //acc.Total_Applications__c = null;
          //  acc.License_Applications__r.addError('ERROR TEST');
            
      //  }
        
       // else{
        
        accUpdateList.add(acc);
       // }
    }
    try{
        update accUpdateList;
        System.debug(accUpdateList);
    }Catch(Exception e){
        System.debug('Exception :'+e.getMessage());
    }

}