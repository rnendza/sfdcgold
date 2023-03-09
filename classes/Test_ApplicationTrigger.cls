/**
 * Created by CedricN on 4/12/2021.
 */
@isTest
private  class Test_ApplicationTrigger {


    @testSetup

   static void testSetup(){
       // List<LicenseApplication__c> Applications = new List<LicenseApplication__c>();



                Account acct = new Account(name =' Test Account', Total_Applications__c = 0);

                insert acct;



    }

    @isTest
    static void insertApplicationCount(){

        Account act = [Select Id, Name, Total_Applications__c from Account where Name='Test Account'];

        LicenseApplication__c app = new LicenseApplication__c();

        app.type__c = 'IGB Video Gaming';
        app.Location_DBA__c = act.Id;

        if(act.Total_Applications__c >= 2 ){
            act.addError('ERROR MESSAGE');
        }

        try{
            insert app;
          //  System.debug(accUpdateList);
        }Catch(Exception e){
            System.debug('Exception :'+e.getMessage());
        }




    }



    @isTest
    static void twoApplicationCount(){

        Account act = [Select Id, Name, Total_Applications__c from Account where Name='Test Account'];

        LicenseApplication__c app = new LicenseApplication__c();

        app.type__c = 'IGB Video Gaming';
        app.Location_DBA__c = act.Id;

        LicenseApplication__c app3 = new LicenseApplication__c();

        app3.type__c = 'IGB Video Gaming';
        app3.Location_DBA__c = act.Id;

        if(act.Total_Applications__c >= 2 ){
            act.addError('ERROR MESSAGE');
        }

        try{
            insert app;

            insert app3;
            //  System.debug(accUpdateList);
        }Catch(Exception e){
            Boolean expectedExceptionThrown =  e.getMessage().contains('ERROR MESSAGE') ? true : false;
    //        System.assertEquals(expectedExceptionThrown, true);
            System.debug('Exception :'+e.getMessage());
        }




    }

    @isTest
    static void deleteApplicationCount(){

        Account ac2 = [Select Id, Name, Total_Applications__c from Account where Name='Test Account'];


        if(ac2.Total_Applications__c >= 2 ){
            ac2.addError('ERROR MESSAGE');
        }
        LicenseApplication__c app1 = new LicenseApplication__c();

        app1.type__c = 'IGB Video Gaming';
        app1.Location_DBA__c = ac2.Id;
        try{
            insert app1;
            //  System.debug(accUpdateList);
            delete app1;
        }Catch(Exception e){
            System.debug('Exception :'+e.getMessage());
        }



    }



}