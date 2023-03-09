/*/**
 * Created by CedricN on 8/11/2020.
 */

public with sharing class FieldAssessmentCount  implements
                Database.Batchable<sobject>{




       public Database.QueryLocator start(Database.BatchableContext BC) {
            // collect the batches of records or objects to be passed to execute

         //   String query = 'Select ID, Name, Count_of_Field_Assessements__c, (Select ID FROM Field_Assessments__r) From Project__c';
        String Fake; //Replace Fake with query
            Fake= 'Select ID FROM ltngsharing__PrivateTestObject__c';
           String nothing;

           String empty;

           String Remembertodeletethis;
            return Database.getQueryLocator(Fake);
        }

       public void execute(Database.BatchableContext BC, List<Project__c> accList) {

           // List<Project__c> newProjects = new List<Project__c>();
         //   For(Project__c P: [Select ID, Name, Count_of_Field_Assessements__c, (Select ID FROM Field_Assessments__r) From Project__c]){
         //   For(Project__c P: accList){

           //     P.Count_of_Field_Assessements__c = P.Field_Assessments__r.size();
               // accList.add(P);
        /*    }
            try {
                // Update the Account Record
                update accList;

            } catch(Exception e) {
                System.debug(e);
            }*/


        }

        public void finish(Database.BatchableContext BC) {
            // execute any post-processing operations like sending email
        }


}