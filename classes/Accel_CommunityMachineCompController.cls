/**
 * Controller backing Accel_CommunityMachineComparisonMethod.
 */
public with sharing class Accel_CommunityMachineCompController {

    public static final String MAP_KEY_HPD_RECS = 'HPD_RECS';
    public static final String MAP_KEY_MACHINE_AVERAGES = 'PRODUCT_MACHINE_AVERAGES';
    public static final String DAILY_RECORDTYPE_NAME = 'Daily HPD';
    public static final String NO_RECORDS_FOUND_MSG = 'No records found'; //@TODO custom label
    public static final Integer DAYS_TO_GO_BACK = 30;

    /**
     * A simple sample query of HPD data.. kinda useless but just to provide an example.
     *
     * @param accountId - String account Id.
     *
     * @return a instance of responseDto containing the retrieved hpd list or error info
     * @see ResponseDto
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveHoldPerDayByAccountLast30(String accountId) {
        //@TODO a good boy would validate incoming params including the dates.
        ResponseDto dto = new ResponseDto();
        List<Hold_Per_Day__c> holdPerDays = new List<Hold_Per_Day__c>();
        Date dStartDate = System.today() - DAYS_TO_GO_BACK;
        Date dEndDate = System.today();
        //--------- note generally I would call a service ie HpdSvc and leave business log out of the controller tied to the uti.
        //--------- this is just a simple example that is part of end to end data retrieval; examples.
        holdPerDays = [
                SELECT  id,date__c,asset__c,location_share__c, net_revenue__c,asset__r.model__c
                FROM    Hold_Per_Day__c
                WHERE   account__c = :accountId
                and     date__c >= :dStartDate
                and     date__c <= :dEndDate
                and     RecordType.Name = :DAILY_RECORDTYPE_NAME
                LIMIT   50000
        ];
        if (!holdPerDays.isEmpty()) {
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_HPD_RECS, holdPerDays);
            dto.technicalMsg = 'param accountId=' + accountId;
        } else {
            dto.message = NO_RECORDS_FOUND_MSG;
            dto.isSuccess = false;
        }
        return dto;
    }
    /**
     *  Queries for machine averages over 30 days. Data on product is populuated nightly via batch jobs.
     *  All machines returned here (about 20)
     *
     * @return a instance of responseDto containing the retrieved product list or error info
     * @see ResponseDto
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveMachineAverages() {
        ResponseDto dto = new ResponseDto();
        List<Product2> products = ProductSvc.retrieveAllMachineAverages();

        if (!products.isEmpty()) {
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_MACHINE_AVERAGES, products);
        } else {
            dto.message = NO_RECORDS_FOUND_MSG;
            dto.isSuccess = false;
        }
        return dto;
    }
}