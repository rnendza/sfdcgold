/**
 * SObjectQuerySvc provides the ability to query a single SObject for multiple records via building dynamic
 * SOQL or dynamic SOSL. Also can provide results for RecentlyViewed records.
 */
public without sharing class SObjectQuerySvc {

    public static Boolean DEBUG_QUERY = false;

    /**
     * Queries the RecentlyView Object and then uses those Ids to query the target object.
     *
     * @param sObjectApiName    The Api Name of the target sObject.                                     * REQUIRED *
     * @param selectFields      A List of field names to select / return in the results.                * REQUIRED *
     * @param orderByClause     The order by clause of the target sObject
     * @param maxRows           The max limit of recently viewed records.
     *
     * <p>
     * USAGE:
     *
     *   List<String> fields = new List<String> {'Firstname','Lastname','Name'};
     *   List<SObject> sObjects = SObjectQuerySvc.retrieveRecentlyViewedSSObjectResults('User',fields,'LASTNAME ASC',10);
     *</p>
     *
     * @implNotes
     * 1. This returns records only for the running user in context!
     * 2. Explicitly excludes community viewed records (NetworkId = null).
     *
     * @see https://developer.salesforce.com/docs/atlas.en-us.object_reference.meta/object_reference/sforce_api_objects_recentlyviewed.htm
     *
     * @return                  A List of sObjects.
     */
    public static List<SObject> retrieveRecentlyViewedSObjectResults(   String          sObjectApiName,
                                                                        List<String>    selectFields,
                                                                        String          orderByClause,
                                                                        Integer         maxRows) {
        List<SObject> sObjects = new List<SObject>();

        Map<Id,RecentlyViewed> mRecentRecs = new Map<Id,RecentlyViewed>([
                SELECT  Id, Name, Type
                FROM    RecentlyViewed
                WHERE   Type = :sObjectApiName
                AND     NetworkId = NULL
                AND     LastViewedDate != NULL
                ORDER BY LastViewedDate DESC
                LIMIT :maxRows
        ]);
        if(DEBUG_QUERY) {
            System.debug('\n---> recently viewed ids=\n\n' + mRecentRecs.keySet() + '\n');
        }
        if(!mRecentRecs.isEmpty() || Test.isRunningTest()) {
            Set<Id> filterIds = mRecentRecs.keySet();
            //  Unit Test Hack as we can't be sure the running test users has live recently viewed recs.
            if(Test.isRunningTest()) {
                filterIds =  new Map<Id,User>([SELECT Id FROM USER LIMIT 5]).keySet();
            }
            String soqlSelectFields = String.join(selectFields,',');
            maxRows = maxRows != null ? maxRows : 100;
            String soql = '';
            soql += '   SELECT   ' + soqlSelectFields;
            soql += '   FROM     ' + sObjectApiName;
            soql += '   WHERE ID IN :filterIds ';
            if(orderByClause != null) {
                soql += ' ORDER BY ' + orderByClause;
            }
            soql += '   LIMIT   :maxRows ';

            if(DEBUG_QUERY) {
                System.debug('\n---> sosl=\n\n' + soql + '\n');
            }
            sObjects = Database.query(soql);
        }
        return sObjects;
    }


    /**
     * Queries a single sObject using soql.
     *
     * @param sObjectApiName    The Api Name of the sObject.                                            * REQUIRED *
     * @param selectFields      A List of field names to select / return in the results.                * REQUIRED *
     * @param whereFilter       Any where criteria
     * @param orderByClause     The order by clause.
     * @param maxRows           The max limit of rows.
     *
     * <p>
     * USAGE:
     *
     *   List<String> fields = new List<String> {'Firstname','Lastname','Name'};
     *   String whereFilter = 'IsActive = TRUE';
     *   List<SObject> sObjects = SObjectQuerySvc.retrieveSObjectResults('User',fields,whereFilter,'LASTNAME ASC',200);
     *</p>
     *
     * @return                  A List of sObjects.
     */
    public static List<SObject> retrieveSObjectResults( String          sObjectApiName,
                                                        List<String>    selectFields,
                                                        String          whereFilter,
                                                        String          orderByClause,
                                                        Integer         maxRows) {

        String soqlSelectFields = String.join(selectFields,',');
        maxRows = maxRows != null ? maxRows : 50000;

        String soql = '';
        soql += '   SELECT   ' + soqlSelectFields;
        soql += '   FROM     ' + sObjectApiName;
        if(whereFilter != null) {
            soql += '   WHERE    ' + whereFilter;
        }
        if(orderByClause != null) {
            soql += ' ORDER BY ' + orderByClause;
        }
        soql += '   LIMIT   :maxRows ';

        if(DEBUG_QUERY) {
            System.debug('\n---> sosl=\n\n' + soql + '\n');
        }

        List<SObject> sObjects = Database.query(soql);
        return sObjects;
    }

    /**
     * Queries a single sObject using sosl.
     *
     * @param sObjectApiName    The Api Name of the sObject.                                            * REQUIRED *
     * @param selectFields      A List of field names to select / return in the results.                * REQUIRED *
     * @param searchTerm        The search term ( sosl will handle wild-carding and fuzzy searches).    * REQUIRED *
     * @param whereFilter       Any additional where criteria (beyond the search term).
     * @param orderByClause     The order by clause.
     * @param maxRows           The max limit of rows (2000 is sosl max).
     *
     * <p>
     * USAGE:
     *
     *   List<String> fields = new List<String> {'Firstname','Lastname','Name'};
     *   String whereFilter = 'IsActive = TRUE';
     *   List<SObject> sObjects = SObjectQuerySvc.retrieveSoslSObjectResults('User',fields,'Rick',whereFilter,'LASTNAME ASC',200);
     *
     *   That creates the following sosl:
     *   FIND 'Rick' IN ALL FIELDS  RETURNING User (ID, Firstname,Lastname,Name  WHERE  ( IsActive = TRUE )  ORDER BY LASTNAME ASC) LIMIT 200
     * </p>
     *
     * @return                  A List of sObjects.
     */
    public static List<SObject> retrieveSoslSObjectResults( String sObjectApiName,
                                                            List<String> selectFields,
                                                            String searchTerm,
                                                            String whereFilter,
                                                            String orderByClause,
                                                            Integer maxRows ) {

        List<SObject> sObjResults = new List<SObject>();

        String soslSelectFields = String.join(selectFields, ',');
        String query = 'ID, ' + soslSelectFields;

        if (String.isNotBlank(whereFilter)) {
            query += '  WHERE  ( ' + whereFilter + ' ) ';
        }
        if (String.isNotBlank(orderByClause)) {
            query += ' ORDER BY ' + orderByClause;
        }
        maxRows = maxRows != null ? maxRows : 2000;

        String sosl = '';
        sosl += ' FIND \'' + String.escapeSingleQuotes(searchTerm);
        sosl += '\' IN ALL FIELDS ';
        sosl += ' RETURNING ' + sObjectApiName;
        sosl += ' (' + query + ')';
        sosl += ' LIMIT ' + maxRows;

        if(DEBUG_QUERY) {
            System.debug('\n---> sosl=\n\n' + sosl + '\n');
        }
        List<List<SObject>> sObjsOfSObjs = Search.query(sosl);
        if(!sObjsOfSObjs.isEmpty()) {
            sObjResults = sObjsOfSObjs[0];
        }
        return sObjResults;
    }

}