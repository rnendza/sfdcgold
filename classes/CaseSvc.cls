public with sharing class CaseSvc {

    /**
     * Returns a list of cases where the asset name or the account name is like the searchTerm.
     *
     * @param searchTerm
     * @return a list of Cases
     */
    public static List<Case> retrieveCaseHistoryCases( String searchTerm, Integer iRowLimit ) {
        List<Case> cases = new List<Case>();
        searchTerm = searchTerm +'%';
        cases = [
                SELECT  Id,CaseNumber, Show_Record__c,Status,CreatedDate, G2S_Updated__c,Solution__c,Tech_Notes__c,
                        Account.Name, AccountId, Asset.Name, AssetId, Work_Type__c,Work_Type__r.Name, Assigned_Resource__r.Name,
                        Asset.Show_Record__c,Asset.SAS__c, Asset.GP_Manufacturer__c
                FROM    Case
                WHERE   ( Asset.Name LIKE :searchTerm or Account.Name LIKE :searchTerm)
                LIMIT   :iRowLimit
        ];
        return cases;
    }
}