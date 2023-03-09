public class AuditTrailParams {

    @TestVisible
    private static Integer DEFAULT_LIMIT = 50000;

    //  The Limit ion the Query
    @AuraEnabled public Integer iLimit  {get;set;}

    //  A List of User.Id to compare against CreatedById
    @AuraEnabled public List<Id> userIds {get;set;}

    //  A List of Profile.Id to compare against CreatedBy.Profile.Id
    @AuraEnabled public List<Id> profileIds {get;set;}

    //  A List of Actions to Exclude to compare against Action
    @AuraEnabled public List<String> excludeActions {get;set;}

    //  A List of Actions to Include to compare against Action
    @AuraEnabled public List<String> includeActions {get;set;}

    // The startDateTime to compare against CreatedDate
    @AuraEnabled public Datetime startDate {get;set;}

    // The endDateTime to compare against CreatedDate
    @AuraEnabled public Datetime endDate {get;set;}

    @AuraEnabled public List<String> userTypes {get;set;}

    /*
     * Exclude things such as login / logout actions
     * @see AuditTrailParams.EXCLUDE_ACTIONS
     */
    @AuraEnabled public Boolean devOnlyActions {get;set;}

    public AuditTrailParams() {
        this.iLimit = DEFAULT_LIMIT;
        this.userIds = new List<Id>();
        this.profileIds = new List<Id>();
        this.excludeActions = new List<String>();
        this.includeActions = new List<String>();
        this.userTypes = new List<String>();
        this.devOnlyActions = false;
    }
}