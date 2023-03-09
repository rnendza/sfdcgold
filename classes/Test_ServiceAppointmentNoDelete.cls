@isTest

private class Test_ServiceAppointmentNoDelete {
    
    @isTest static void TestNoDeleteServiceAppointment(){
        
        Account testaccount = New Account(Name='Test Account v1');
        
        insert testaccount;
        
        ServiceAppointment Serv = new ServiceAppointment(ParentRecordId	= testaccount.id, Status='None', DueDate = datetime.now(), EarliestStartTime= datetime.now());
        
        
        insert Serv;



        User testservuser = new User(FirstName='Test Service User', LastName='Test User', Email='TestUser@testuser.com', ProfileId = '00e1I000000Zxfl', UserName='TestUser@testuser.com.fulldev', Alias='TestU', TimeZoneSidKey='America/Chicago', LocaleSidKey='en_US', EmailEncodingKey=' ISO-8859-1', LanguageLocaleKey='en_US');
        
        insert testservuser;
        
        List<ServiceAppointment> servs = new List<ServiceAppointment>();
        
        servs.add(Serv);
        //Test.startTest();
        
     //   insert servs;
        
                  //   Database.DeleteResult result = Database.delete(Serv, false);
                  Test.startTest();
        System.runas(testservuser){
            try {
                              CannotDeleteServiceAppointment.NoDeleteServiceAppointment(servs);    

                delete [Select Id from ServiceAppointment where ParentRecordId =:testaccount.id];
            }
            
            catch(Exception e) {
                
                e.getMessage();
                
                
            }
        }

        Test.stopTest();


        
    }

}