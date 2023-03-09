/**
 * ContactSvc provides for all operations around a Contact sObject.
 */
public without sharing class ContactSvc {

    /**
     * Queries the AccountContactRelation sObject.
     * 
     * @param contactId             The Id for the Contact sObject.
     * @param explodeHqAccounts     @deprecated
     *
     * @return                      A List of ContactAccount objects.
     */
    public static List<ContactAccount> retrieveContactAccounts(Id contactId,Boolean explodeHqAccounts) {

        List<ContactAccount> contactAccounts = new List<ContactAccount>();

        List<AccountContactRelation> accountContactRelations = [
                SELECT  Id, AccountId, ContactId, IsDirect, StartDate, EndDate, IsActive,
                        Account.Name, Account.ShippingAddress,Account.ParentId,Account.HQ_Account__c,
                        Contact.Name, Account.IGB_License__c,
                        Account.Relationship_Manager__c,Account.Relationship_Manager__r.Name
                FROM    AccountContactRelation
                WHERE   ContactId = :contactId
                ORDER BY Account.HQ_Account__c DESC, IsDirect DESC, Account.Name
        ];

        Set<Id> hqIds = new Set<Id>();
        for(AccountContactRelation acr : accountContactRelations) {
            ContactAccount contactAccount = new ContactAccount(acr);
            contactAccounts.add(contactAccount);
            if (explodeHqAccounts) {
                if (acr.Account.HQ_Account__c) {
                    hqIds.add(acr.AccountId);
                }
            }
        }
        return contactAccounts;
    }

    /**
     * Queries the provided hq ids and fields all of their children.
     *
     * @param hqIds     A Set of Headquarter Ids. (bumped up against Account.ParentId)
     * @return          A List of Account sObjects.
     */
    public static List<Account> findHqChildren(Set<Id> hqIds) {
        List<Account> hqChildren = [
                SELECT Id,Name
                FROM   Account
                WHERE  ParentId IN :hqIds
                AND    Type = 'Accel Account'
                AND    RecordType.DeveloperName = 'Location'
        ];
        return hqChildren;
    }
    /**
     * An abstraction of AccountContactRelation.
     */
    public class ContactAccount {
        @AuraEnabled Id         acrId                   {get;set;}
        @AuraEnabled Id         accountId               {get;set;}
        @AuraEnabled Id         accountParentId         {get;set;}
        @AuraEnabled Id         contactId               {get;set;}
        @AuraEnabled Boolean    isDirect                {get;set;}
        @AuraEnabled Boolean    isActive                {get;set;}
        @AuraEnabled Boolean    isHqAccount             {get;set;}
        @AuraEnabled String     accountName             {get;set;}
        @AuraEnabled String     accountIgbNumber        {get;set;}
        @AuraEnabled Address    accountShippingAddress  {get;set;}
        @AuraEnabled Id         rmId                    {get;set;}
        @AuraEnabled String     rmName                  {get;set;}


        ContactAccount(AccountContactRelation acr) {
            this.acrId = acr.Id;
            this.accountId = acr.AccountId;
            this.accountParentId = acr.Account.ParentId;
            this.contactId = acr.ContactId;
            this.isDirect = acr.IsDirect;
            this.isActive = acr.IsActive;
            this.isHqAccount = acr.Account.HQ_Account__c;
            this.accountName = acr.Account.Name;
            this.accountIgbNumber = acr.Account.IGB_License__c;
            this.accountShippingAddress = acr.Account.ShippingAddress;
            this.rmId =  acr.Account.Relationship_Manager__c;
            this.rmName = acr.Account.Relationship_Manager__r.Name;
        }
    }
    /**
     * Builds a portal user sObject.
     *
     * @param accountId     The Id of the account.
     * @param firstName     The firstname of the user.
     * @param lastName      The lastname of the user.
     * @param email         The email of the user.
     * @param userName      The username of the user.
     *
     * @return              A non inserted User sObject.
     */
    public static User buildPortalUser( Id accountId, String firstName, String lastName,
                                        String email, String userName) {

        Profile profile1 = [Select Id from Profile where name = 'Individual User Community Standard'];

        String alias;
        if(lastName.length() > 8) {
            alias = lastName.substring(0,7);
        } else {
            alias = lastName;
        }
        if(userName == null) {
            userName = email;
        }
        User portalUser = new User(
                ProfileId = profile1.Id,
                Username = userName ,
                Alias = alias,
                Email= email,
                EmailEncodingKey='UTF-8',
                Firstname=firstName,
                Lastname=lastName,
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US',
                TimeZoneSidKey='America/Chicago'
        );
        return portalUser;
    }
    /**
     * @param accountId     The account id of th contact.
     * @param portalUser    The User sObj the contact should relate to.
     *
     * @return              A non-inserted Contact sObj.
     */
    public static Contact buildPortalContact( Id accountId, User portalUser) {
       Contact contact = new Contact(
               AccountId = accountId,
               LastName = portalUser.lastName,
               FirstName = portalUser.FirstName,
               Email = portalUser.Email,
               Community_Contact__c = true
       );
        return contact;
    }
    /**
     * Find monthly HPD records for the past set of account ids.
     *
     * @param accountIds    A set of Account Ids to search for.
     * @return              A List of Hold_Per_Day__c sObjects
     */
    public static List<Hold_Per_Day__c> retrieveAllMonthliesForAccounts(Set<Id> accountIds) {

        List<Hold_Per_Day__c> hpds = [
                SELECT Id, Account__c,Date__c,Account__r.Name, Account__r.Nickname__c, Account__r.ShippingAddress,
                        Net_Revenue__c,Location_Share__c,Funds_In__c,Funds_Out__c,VGT_Count__c
                FROM   Hold_Per_Day__c
                WHERE  RecordType.DeveloperName = 'Monthly_HPD'
                AND   Account__c IN :accountIds
                ORDER BY Date__c DESC, Account__r.Name ASC
        ];
        return hpds;
    }

//    DEPRECATED!! @see CommunityUserSettingsSvc
//    /**
//     * Retrieves community Profile Settings for the passed contactId.
//     * @param contactId     The SFDC Id of the contact.
//     * @return              A Contact sObject containing community specific fields. ie. AC_xxxx
//     */
    public static Contact retrieveContactCommunityProfileSettings( Id contactId ) {
        Contact contactProfileSettings;
//
//        List<Contact> contacts = [
//                SELECT  Id, Name, AC_Home_Location_Address_Display__c
//                FROM    Contact
//                WHERE   Id          =   :contactId
//        ];
//        if(!contacts.isEmpty()) {
//            contactProfileSettings = contacts[0];
//        } else {
//            System.debug(LoggingLevel.ERROR, 'Contact not found for passed Id='+contactId);
//        }
        return contactProfileSettings;
    }
}