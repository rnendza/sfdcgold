public with sharing class clUserController {
    
    @AuraEnabled(Cacheable=true)
    public static User retrieveUserDetails(Id userId) {
        User user = UserSvc.retrieveUserDetails(userId);
        return user;
    }

}