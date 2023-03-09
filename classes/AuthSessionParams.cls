public class AuthSessionParams {

    @TestVisible
    private static Integer DEFAULT_LIMIT = 50000;

    //  The Limit ion the Query
    @AuraEnabled public Integer iLimit  {get;set;}

    //  A List of User.Id to compare against Users.Id
    @AuraEnabled public List<Id> userIds {get;set;}

    //  A List of Session Types to compare against SessionType
    @AuraEnabled public List<String> sessionTypes {get;set;}

    //  A List of Login Types to compare against LoginType
    @AuraEnabled public List<String> loginTypes {get;set;}

    public AuthSessionParams() {
        this.iLimit = DEFAULT_LIMIT;
        this.userIds = new List<Id>();
        this.sessionTypes = new List<String>();
        this.loginTypes = new List<String>();
    }
}