/**
 * Summarizes all wrappers from an expiration standpoint for ease of use by the client.
 */
public class AccountLicenseSummary {
    @AuraEnabled public Integer     iNumExpiredLicenses             {get;set;}
    @AuraEnabled public Integer     iNumExpiringLicenses            {get;set;}
    @AuraEnabled public Boolean     anyExpiredOrExpiring            {get;set;}

    public AccountLicenseSummary() {
        this.iNumExpiredLicenses    =   0;
        this.iNumExpiringLicenses   =   0;
        this.anyExpiredOrExpiring   =   false;
    }
}