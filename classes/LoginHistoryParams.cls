public class LoginHistoryParams {

    @TestVisible
    private static Integer DEFAULT_LIMIT = 50000;

    //  The Limit ion the Query
    @AuraEnabled public Integer iLimit  {get;set;}

    //  A List of User.Id to compare against UserId
    @AuraEnabled public List<Id> userIds {get;set;}

    //  A List of Profile.Id to compare against User.Profile.Id
    @AuraEnabled public List<Id> profileIds {get;set;}

    @AuraEnabled public List<String> statuses {get;set;}

    // The startDateTime to compare against CreatedDate
    @AuraEnabled public Datetime startDate {get;set;}

    // The endDateTime to compare against CreatedDate
    @AuraEnabled public Datetime endDate {get;set;}


    public LoginHistoryParams() {
        this.iLimit = DEFAULT_LIMIT;
        this.userIds = new List<Id>();
        this.profileIds = new List<Id>();
        this.statuses = new List<String>();
    }
}