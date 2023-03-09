public class UserParams {
    @TestVisible
    private static Integer DEFAULT_LIMIT = 50000;

    //  The Limit ion the Query
    @AuraEnabled public Integer iLimit  {get;set;}

    //  A List of User.Id to compare against UserId
    @AuraEnabled public List<Id> userIds {get;set;}

    @AuraEnabled public List<String> userTypes {get;set;}

    //  A List of Strings ie. ['active','inactive'] used to determine User.IsActive filter.
    @AuraEnabled public List<String> activeInactives {get;set;}

    public UserParams() {
        this.iLimit = DEFAULT_LIMIT;
        this.userIds = new List<Id>();
        this.userTypes = new List<String>();
        this.activeInactives = new List<String>();
    }
}