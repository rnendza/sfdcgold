/**
 * Created by CedricN on 2/8/2022.
 */
@isTest
public with sharing class Test_DuplicateContact {

    public static String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';
    public static String USERNAME_PORTAL            = 'accelcustomerportal@portal.com';
    public static Integer NUMBER_OF_ACCOUNTS        = 5;
    public static String HQ_ACCOUNT_NAME            = 'HQ  Portal UT Account';
    public static String PROFILE_NAME_PORTAL        = 'Grouped User Community Standard';
    public static Set<String> ACCOUNT_TYPES         = CustomMetaDataSvc.retrieveCommunityAccountTypes();





    @testSetup
    static void setup(){
    /*UserRole adminRole = new UserRole(DeveloperName = 'TestCustomerPortalRole', Name = 'TestCustomerPortalRole');
    insert adminRole;

    User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);
    adminUser = [ SELECT Id, UserRoleId FROM User WHERE Id = :adminUser.Id ];
    adminUser.UserRoleId = adminRole.Id;
    update adminUser;
    User setupUser = adminUser;*/
        Contact portalContact = new Contact(FirstName='Portal', LastName='User');

        insert portalContact;

        Portal_Contact_Request__c PCR = new Portal_Contact_Request__c(First_Name__c ='Portal', Last_Name__c='User');

        insert PCR;

    }



  @isTest  static void  Test_DuplicateContactMethod(){

      Portal_Contact_Request__c usercontact = [Select Id From Portal_Contact_Request__c Where First_Name__C ='Portal' Limit 1];




        String ContactId = Id.valueOf(usercontact.id);

    List<Contact> contacts = DuplicateContact.DuplicateContactMethod(ContactId);
    }

}