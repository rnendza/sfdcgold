/**
 * UI Backing controller for the clLinkedRps lwc component.
 * Retrieves all / filtered (searchparams) linked RPS records and total counts of records for display on the client.
 */
public class clLinkedRpsController {

    @TestVisible
    private static final Integer    DEFAULT_ROWS_LIMIT      = 200;
    public static final String      MAP_KEY_RPS_WRAPPERS    = 'RPS_WRAPPERS';
    public static final String      MAP_KEY_RPS_TOTAL_CNT   = 'RPS_TOTAL_CNT';
    public static final String      MAP_KEY_PARENT_ACCT_ID  = 'PARENT_ACCT_ID';

    /**
     * Retrieve all RPS records for the parent account other then the current RPS being viewed.
     *
     * @param currentRpsId  The Route_Processing_Sheet__c.Id.
     * @param searchParams  The search param object (filters).
     *
     * @return              A ResponseDto containing a List of RpsWrapper objects.
     * @see RpsSearchParams
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveLinkedRps(Id currentRpsId,RpsSearchParams searchParams) {
        ResponseDto dto = new ResponseDto();

        Route_Processing_Sheet__c currentRps = retrieveRps(currentRpsId);
        Id parentAccountId = currentRps.Account__c;

        List<Route_Processing_Sheet__c> rpss = retrieveRpss(parentAccountId,currentRpsId,searchParams);
        dto.isSuccess = !rpss.isEmpty();
        dto.values.put(MAP_KEY_RPS_WRAPPERS,buildRpsWrappers(rpss));
        dto.values.put(MAP_KEY_PARENT_ACCT_ID,parentAccountId);
        return dto;
    }

    /**
     * Retrieve the count of all RPS records for the parent account other then the current RPS being viewed.
     *
     * @param currentRpsId  The Route_Processing_Sheet__c.Id.
     * @param searchParams  The search param object (filters).
     *
     * @return              A ResponseDto containing an Integer value of the count.
     * @see RpsSearchParams
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveLinkedRpsTotalRecords(Id currentRpsId,RpsSearchParams searchParams) {
        ResponseDto dto = new ResponseDto();
        Integer iTotal = 0;

        Route_Processing_Sheet__c currentRps = retrieveRps(currentRpsId);
        Id parentAccountId = currentRps.Account__c;

        iTotal = retrieveRpssTotalRecords(parentAccountId,currentRpsId,searchParams);
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_RPS_TOTAL_CNT,iTotal);
        return dto;
    }

    /**
     * Wrap the Route_Processing_Sheet__c up in a wrapper class.
     *
     * @param rpss  A List of Route_Processing_Sheet__c sObjects.
     * @return      A List of RpsWrapper objects.
     */
    public static List<RpsWrapper> buildRpsWrappers(List<Route_Processing_Sheet__c> rpss) {
        List<RpsWrapper> rpsWrappers = new List<RpsWrapper>();

        for(Route_Processing_Sheet__c rps : rpss) {
            rpsWrappers.add( new RpsWrapper(rps) );
        }
        return rpsWrappers;
    }

    /**
     * Calls the svc to retrieve the List of Route_Processing_Sheet__c sObjects.
     *
     * @param parentAccountId   The Route_Processing_Sheet.Account__c value.
     * @param currentRpsId      The Route_Processing_Sheet__c.Id value being viewed.
     * @param searchParams      The RpsSearchParams (query filters).
     *
     * @return                  A List of Route_Processing_Sheet__c sObjects.
     */
    public static List<Route_Processing_Sheet__c> retrieveRpss(Id parentAccountId, Id currentRpsId,RpsSearchParams searchParams) {

        clLinkedRpsSvc.DEBUG_QUERY = false;

        List<Route_Processing_Sheet__c> rpss = clLinkedRpsSvc.retrieveRpsAdvancedSearch(
                searchParams.iLimit,
                currentRpsId,
                parentAccountId,
                searchParams.hasVgtVariance,
                searchParams.hasRtVariance,
                searchParams.daysBackCollectionDate
        );
        return rpss;
    }

    /**
     * Calls the svc to retrieve the Count List of Route_Processing_Sheet__c sObjects for the parent account (minus 1).
     *
     * @param parentAccountId   The Route_Processing_Sheet.Account__c value.
     * @param currentRpsId      The Route_Processing_Sheet__c.Id value being viewed.
     * @param searchParams      The RpsSearchParams (query filters).
     *
     * @return                  A integer that sums the count of all rps for the account besides the current one being viewed.
     */
    public static Integer retrieveRpssTotalRecords(Id parentAccountId, Id currentRpsId,RpsSearchParams searchParams) {

        clLinkedRpsSvc.DEBUG_QUERY = false;

        Integer iTotal = clLinkedRpsSvc.retrieveRpsAdvancedSearchTotalRecords(  currentRpsId, parentAccountId,
                                                                                searchParams.hasVgtVariance,
                                                                                searchParams.hasRtVariance,
                                                                                searchParams.daysBackCollectionDate);
        return iTotal;
    }

    /**
     * Retrieves minimal fields for a single Route_Processing_Sheet__c.
     *
     * @param rpsId     The Route_Processing_Sheet__c.Id.
     * @return          The Route_Processing_Sheet__c sObject with minimal fields.
     */
    public static Route_Processing_Sheet__c retrieveRps(Id rpsId) {

        Route_Processing_Sheet__c rps =  [
                SELECT Id,Account__c
                FROM   Route_Processing_Sheet__c
                WHERE  Id = :rpsId
        ];
        return rps;
    }

    /**
     * A wrapper on Route_Processing_Sheet__c for future flexibility.
     */
    public class RpsWrapper {

        @AuraEnabled public Id rpsId;
        @AuraEnabled public String rpsName;
        @AuraEnabled public Date rpsCollectionDate;
        @AuraEnabled public String rpsCollectionType;
        @AuraEnabled public Double rpsVgtVariance;
        @AuraEnabled public Double rpsRtVariance;

        @AuraEnabled public Boolean hasVgtVariance {
            get {
                return rpsVgtVariance != null && rpsVgtVariance != 0;
            }
        }
        @AuraEnabled public Boolean hasRtVariance {
            get {
                return rpsRtVariance != null && rpsRtVariance != 0;
            }
        }

        public RpsWrapper(Route_Processing_Sheet__c rps) {
            this.rpsId = rps.Id;
            this.rpsName = rps.Name;
            this.rpsCollectionType = rps.Collection_Type__c;
            this.rpsCollectionDate = rps.Collection_Date__c;
            this.rpsVgtVariance = rps.Variance__c;
            this.rpsRtVariance = rps.RT_Variance__c;
        }
    }

    /**
     * Search filters for the query.
     */
    public class RpsSearchParams {
        @AuraEnabled public Boolean hasRtVariance  {get;set;}           //  Has a RPS.Variance__c value != 0
        @AuraEnabled public Boolean hasVgtVariance {get;set;}           //  Has a RPS.RT_Variance__c value != 0
        @AuraEnabled public Integer daysBackCollectionDate {get;set;}
        @AuraEnabled public Integer iLimit {get;set;}                   //  The limit of number of SOQL rows to return.

        public RpsSearchParams() {
            this.iLimit = DEFAULT_ROWS_LIMIT;
        }
    }
}