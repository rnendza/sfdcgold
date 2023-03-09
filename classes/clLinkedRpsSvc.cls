public with sharing class clLinkedRpsSvc {

    public static Boolean DEBUG_QUERY = true;

    /**
     * @param iLimit                    The query limit (number of rows) - required.
     * @param currentRpsId `            The Route_Processing_Sheet__c.Id to ignore - required.
     * @param parentAccountId           The Route_Processing_Sheet__c.Account__c - required.
     * @param hasVgtVariance            Filter for Variance__c = boolean.
     * @param hasRtVariance             Filter for RT_Variance__c = boolean.
     * @param daysBackCollectionDate    The Collection_Date__c = LAST_N_DAYS:[param].
     *
     * @return                  A list of Route_Processing_Sheet__c sObjects.
     */
    public static List<Route_Processing_Sheet__c> retrieveRpsAdvancedSearch(    Integer iLimit,
                                                                                Id currentRpsId,
                                                                                Id parentAccountId,
                                                                                Boolean hasVgtVariance,
                                                                                Boolean hasRtVariance,
                                                                                Integer daysBackCollectionDate) {
        String q = '';
        String filters = '';

        if(hasVgtVariance != null) {
            if( hasVgtVariance ) {
                filters += ' AND Variance__c != 0 ';
            } else {
                filters += ' AND Variance__c = 0 ';
            }
        }
        if(hasRtVariance != null) {
            if( hasRtVariance ) {
                filters += ' AND RT_Variance__c != 0 ';
            } else {
                filters += ' AND RT_Variance__c = 0 ';
            }
        }

        if(daysBackCollectionDate != null) {
            filters += ' AND Collection_Date__c = LAST_N_DAYS:'+daysBackCollectionDate + ' ';
        }

        q+= ' SELECT Id,Name,Collection_Date__c,Collection_Type__c,RT_Variance__c,Variance__c ';
        q+= ' FROM   Route_Processing_Sheet__c ';
        q+= ' WHERE  Id         != :currentRpsId';
        q+= ' AND    Account__c  = :parentAccountId ';
        if(filters != '') {
            q+= filters;
        }
        q+= ' ORDER  By CreatedDate DESC ';
        q+= ' LIMIT  :iLimit ';

        if(DEBUG_QUERY) {
            System.debug('---> query: ' + q);
        }
        List<Route_Processing_Sheet__c> rpss = Database.query(q);
        return rpss;
    }

    /**
     * Sum the count of RPS sObjects.
     *
     * @param currentRpsId `            The Route_Processing_Sheet__c.Id to ignore - required. `
     * @param parentAccountId           The Route_Processing_Sheet__c.Account__c - required.
     * @param hasVgtVariance            Filter for Variance__c = boolean..
     * @param hasRtVariance             Filter for RT_Variance__c = boolean.
     * @param daysBackCollectionDate    The Collection_Date__c = LAST_N_DAYS:[param].
     *
     * @return                  A Count of RPS sObjects.
     */
    public static Integer retrieveRpsAdvancedSearchTotalRecords(    Id currentRpsId, Id parentAccountId,
                                                                    Boolean hasVgtVariance, Boolean hasRtVariance,
                                                                    Integer daysBackCollectionDate ) {
        String q = '';
        String filters = '';

        if(hasVgtVariance != null) {
            if( hasVgtVariance ) {
                filters += ' AND Variance__c != 0 ';
            } else {
                filters += ' AND Variance__c = 0 ';
            }
        }
        if(hasRtVariance != null) {
            if( hasRtVariance ) {
                filters += ' AND RT_Variance__c != 0 ';
            } else {
                filters += ' AND RT_Variance__c = 0 ';
            }
        }

        if(daysBackCollectionDate != null) {
            filters += ' AND Collection_Date__c = LAST_N_DAYS:'+daysBackCollectionDate + ' ';
        }

        q+= ' SELECT Count() ';
        q+= ' FROM   Route_Processing_Sheet__c ';
        q+= ' WHERE  Id         != :currentRpsId';
        q+= ' AND    Account__c  = :parentAccountId ';
        if(filters != '') {
            q+= filters;
        }

        if(DEBUG_QUERY) {
            System.debug('---> query: ' + q);
        }
        Integer iCount = Database.countQuery(q);
        return iCount;
    }
}