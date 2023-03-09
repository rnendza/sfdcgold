/**
 *
 */
public with sharing class AcPostLoginProcessingController {

    public final static String  MAP_KEY_LICENSE_WARNINGS    = 'LICENSE_WARNINGS';
    public final static String  MAP_KEY_LICENSE_SUMMARY     = 'LICENSE_SUMMARY';
    public final static Integer DAYS_TILL_EXPIRATION        = 30; //@TODO CUSTOM META DATA
    public final static Integer MAX_ACCOUNTS                = 300;

    /**
     * Retrieves accounts visible to the running user that have existing licenses.
     *
     * @return a Response Dto with a List of Accounts with Expiring Licenses (if any)
     */
    @AuraEnabled  (Cacheable = true)
    public static ResponseDto retrieveExpiredLicenseInfo() {
        ResponseDto dto = new ResponseDto();
        List<Account> visibleAccounts               =   AccountSvc.retrieveAccounts(MAX_ACCOUNTS);
        List<License__c> expiredOrExpiringLicenses  =   LicenseSvc.retrieveAccountsExpiringOrExpiredLicenses(visibleAccounts,
                                                                                                             DAYS_TILL_EXPIRATION);
        if(!expiredOrExpiringLicenses.isEmpty()) {
            AccountLicenseSummary licenseSummary = new AccountLicenseSummary();
            for(License__c license : expiredOrExpiringLicenses) {
                if(LicenseSvc.isLicenseExpired(license.Expiration_Date__c)) {
                    licenseSummary.iNumExpiredLicenses++;
                } else if (LicenseSvc.isLicenseExpiring(license.Expiration_Date__c,DAYS_TILL_EXPIRATION)) {
                    licenseSummary.iNumExpiringLicenses++;
                }
            }
            licenseSummary.anyExpiredOrExpiring = licenseSummary.iNumExpiringLicenses >0 || licenseSummary.iNumExpiredLicenses > 0;
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_LICENSE_WARNINGS,expiredOrExpiringLicenses);
            dto.values.put(MAP_KEY_LICENSE_SUMMARY,licenseSummary);
        } else {
            dto.technicalMsg = 'No expiring licenses found.';
        }
        return dto;
    }
}