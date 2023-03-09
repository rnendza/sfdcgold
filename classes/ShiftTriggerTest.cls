@isTest
private class ShiftTriggerTest{
    @TestSetup
    static void makeData(){
        Profile p = [select id from profile limit 1];
        
        User u = [select id from user limit 1];
        
        ServiceResource sr = new ServiceResource(Name='test', IsActive=true, RelatedRecordId=u.Id, Accel_User__c=u.Id, ResourceType = 'T');
        insert sr;
        
        Shift s = new Shift(ServiceResource=sr,Status='Tentative', StartTime=Datetime.newInstance(2022,1,1,9,0,0), EndTime=Datetime.newInstance(2022,1,1,10,0,0), TimeSlotType='Normal', Secondary_Service_Territory__c='Rockford');
        insert s;
    }
    
    
    @isTest
    static void testDupe(){
        Test.startTest();
        try{
            ServiceResource sr = [select id from ServiceResource limit 1];
        	Shift s = new Shift(ServiceResource=sr,Status='Tentative', StartTime=Datetime.newInstance(2022,1,1,9,0,0), EndTime=Datetime.newInstance(2022,1,1,10,0,0), TimeSlotType='Normal', Secondary_Service_Territory__c='Rockford');
        	insert s;
        }catch(Exception e){
            System.assertNotEquals(null, e.getMessage());
        }
		Test.stopTest();
       	List<Shift> shifts = [select id from Shift];
        System.assertEquals(1, shifts.size());
    }
    
    @isTest
    static void testSuccess(){
        Test.startTest();
        ServiceResource sr = [select id from ServiceResource limit 1];
        Shift s = new Shift(ServiceResource=sr,Status='Tentative', StartTime=Datetime.newInstance(2022,1,2,9,0,0), EndTime=Datetime.newInstance(2022,1,2,10,0,0), TimeSlotType='Normal', Secondary_Service_Territory__c='Rockford');
        insert s;
		Test.stopTest();
       	List<Shift> shifts = [select id from Shift];
        System.assertEquals(2, shifts.size());
    }
}