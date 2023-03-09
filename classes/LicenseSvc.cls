/**
 * Provides for operations on License__c.
 * Numerous methods overload for client convenience.
 * This will generally uses static as opposed to Dynamic SOQL for Readability.
 *
 * @see TEST_LicenseSvc
 */
public with sharing class LicenseSvc {

    /**
     * Retrieve a list of expired licenses for the provided account Ids.
     *
     * @param accountIds    A Set of account Ids to retrieve the expired license for.
     * @return              A List of License sObjects that are expired, otherwise empty.
     */
    public static List<License__c> retrieveAccountsExpiredLicenses( Set<Id> accountIds ) {

        List<License__c> expiredLicenses = [
                SELECT  Id,Name,Expiration_Date__c,RecordType.Name,
                        Location__c,Location__r.Name
                FROM    License__c
                WHERE   Location__c         IN :accountIds
                AND     Active_License__c   =   TRUE
                AND     Expiration_Date__c  <   TODAY
        ];
        return expiredLicenses;
    }
    /**
     * Retrieve a list of expiring licenses for the provided account Ids. Meaning licenses that have NOT yet expired
     * but will be expiring with then next :daysToExpiration value.
     *
     * @param daysTillExpiration    An Integer value denoting the number of days till expiration be considered expiring.
     * @param accountIds            A Set of account Ids to retrieve the expired license for.
     * @return                      A List of License sObjects that are expired, otherwise empty.
     */
    public static List<License__c> retrieveAccountsExpiringLicenses( Set<Id> accountIds, Integer daysTillExpiration ) {

        Date nextNdays = Date.today().addDays(daysTillExpiration);

        List<License__c> expiringLicenses = [
                SELECT  Id,Name,Expiration_Date__c,RecordType.Name,
                        Location__c,Location__r.Name
                FROM    License__c
                WHERE   Location__c         IN   :accountIds
                AND     Active_License__c   =   TRUE
                AND     Expiration_Date__c  >=  TODAY
                AND     Expiration_Date__c  <=  :nextNdays
        ];
        return expiringLicenses;
    }

    /**
     * Retrieve a list of expiring or expired licenses for the provided account Ids.
     * Meaning licenses that have expired or will be expiring with then next :daysToExpiration value.
     *
     * @param daysTillExpiration    An Integer value denoting the number of days till expiration be considered expiring.
     * @param accountIds            A Set of account Ids to retrieve the expired license for.
     * @return                      A List of License sObjects that are expired, otherwise empty.
     */
    public static List<License__c> retrieveAccountsExpiringOrExpiredLicenses( Set<Id> accountIds, Integer daysTillExpiration ) {

        Date nextNdays = Date.today().addDays(daysTillExpiration);

        List<License__c> licenses = [
                SELECT  Id,Name,Expiration_Date__c,RecordType.Name,
                        Location__c,Location__r.Name
                FROM    License__c
                WHERE   Location__c             IN   :accountIds
                AND     Active_License__c       =   TRUE
                AND (       ( Expiration_Date__c  >=  TODAY AND Expiration_Date__c  <=  :nextNdays)
                            OR (Expiration_Date__c < TODAY)
                    )
        ];
        return licenses;
    }

    /**
     * If Null or the license expiration date is > then todays date it is not expired, otherwise it is.
     * @param expirationDate    The Expiration Date of the license.
     * @return                  True if expired, otherwise false.
     */
    public static Boolean isLicenseExpired(Date expirationDate) {
        return (expirationDate != null && Date.today() > expirationDate);
    }

    /**
     * @param expirationDate        The expiration date of the license.
     * @param daysTillExpiration    The # of days until license expiration used to warn this user of an expiring license.
     *
     * @return  True if the expiration date is not null and not expired and is within the amount of days till daysTillExpiration.
     */
    public static Boolean isLicenseExpiring(Date expirationDate, Integer daysTillExpiration) {
        return (expirationDate != null &&  expirationDate > Date.today() && expirationDate < Date.today().addDays(daysTillExpiration));
    }
    //============================================= VARIOUS OVERLOADS ==================================================

    /**
     * @param lAccountIds   A List of accountIds.
     * @return              A  List of License__c sObjects.
     */
    public static List<License__c> retrieveAccountsExpiredLicenses( List<Id> lAccountIds ) {
        Set<Id> accountIds =  new Set<Id>();
        accountIds.addAll(lAccountIds);
        return retrieveAccountsExpiredLicenses(accountIds);
    }

    /**
     * @param accounts  A List of accounts.
     * @return          A List of License sObjects.
     */
    public static List<License__c> retrieveAccountsExpiredLicenses( List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
        }
        return retrieveAccountsExpiredLicenses(accountIds);
    }

    /**
     * @param accountId An accountId.
     * @return          A List of License__c sObjects
     */
    public static List<License__c> retrieveAccountExpiredLicenses( Id accountId ) {
        return retrieveAccountsExpiredLicenses(new Set<Id> {accountId});
    }

    /**
     * @param lAccountIds           A List of account ids.
     * @param daysTillExpiration    The amount of days till the license expires.
     *
     * @return                      A List of licenses expiring at daysTillExpiration.
     */
    public static List<License__c> retrieveAccountsExpiringLicenses( List<Id> lAccountIds,Integer daysTillExpiration ) {
        Set<Id> accountIds =  new Set<Id>();
        accountIds.addAll(lAccountIds);
        return retrieveAccountsExpiringLicenses(accountIds, daysTillExpiration);
    }

    /**
     * @param accounts              A List of accounts.
     * @param daysTillExpiration    The amount of days till the license expires.
     *
     * @return                      A List of licenses expiring at daysTillExpiration.
     */
    public static List<License__c> retrieveAccountsExpiringLicenses( List<Account> accounts, Integer daysTillExpiration) {
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
        }
        return retrieveAccountsExpiringLicenses(accountIds,daysTillExpiration);
    }

    /**
     *
     * @param accountId             An Account Id.
     * @param daysTillExpiration    The amount of days till the license expires.
     *
     * @return                      A List of licenses expiring at daysTillExpiration.
     */
    public static List<License__c> retrieveAccountExpiringLicenses( Id accountId, Integer daysTillExpiration) {
        return retrieveAccountsExpiringLicenses(new Set<Id> {accountId},daysTillExpiration);
    }

    /**
     *
     * @param accounts              A List of Account sObjects.
     * @param daysTillExpiration    The amount of days till the license expires.
     *
     * @return                      A List of licenses expiring at daysTillExpiration.
     */
    public static List<License__c> retrieveAccountsExpiringOrExpiredLicenses(   List<Account> accounts,
                                                                                Integer iNumDaysTillExpiration) {
        Set<Id> accountIds = new Set<Id>();
        for(Account account : accounts) {
            accountIds.add(account.Id);
        }
        return retrieveAccountsExpiringOrExpiredLicenses(accountIds,iNumDaysTillExpiration);
    }
//---------------- deprecate

    /**
     * 3/25/2021 uncommented license active check in
     *
     *    public static List<License__c> retrieveAccountsExpiringOrExpiredLicenses( Set<Id> accountIds, Integer daysTillExpiration ) {
 * Note: normally i would keep the active filter in there.. but there seems to be some automation or process broke
 * s I would assume an Active_License__c lookup on the Account would be in sync with the Associated License.Active_License__c
 * but this was the lesser evil below to try to deal with bad data.
 *
 *
 *
 */
}