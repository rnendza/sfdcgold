/**
 * Created by CedricN on 2/2/2022.
 */

public with sharing class DuplicateContact {

    @AuraEnabled(cacheable=true)



    public static List<Contact> DuplicateContactMethod (String records){

        // List<Portal_Contact_Request__c> PCRequests = [Select ]

        Portal_Contact_Request__c PCRRequest = [Select Id, First_Name__c, Last_Name__c, Email__c From Portal_Contact_Request__c Where Id =:records ];

        Return [Select Id, Name, Email, FirstName, LastName From Contact where ((FirstName Like: '%'+PCRRequest.First_Name__c+'%') AND (LastName like
: '%'+PCRRequest.Last_Name__c+'%')) OR ((LastName Like: '%'+PCRRequest.First_Name__c+'%') And (FirstName like: '%'+PCRrequest.Last_Name__c+'%')) OR (Email Like: '%'+PCRRequest.Email__c) ];



     //   Return [Select Id, Name, Email, FirstName, LastName From Contact where FirstName Like '%John'];




		//Debug Code
		
    }


}