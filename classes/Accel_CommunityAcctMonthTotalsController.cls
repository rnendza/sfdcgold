public with sharing class Accel_CommunityAcctMonthTotalsController {

    @AuraEnabled
    public static ResponseDto retrieveHoldPerDayByAccountsSingleMonth( List<Id>  accountIds, String monthDate ) {
        // retrieveHpdAllAccountsBySingleMonthlyResults(Set<Id> accountIds,  String rtName, Date monthDate) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();

        //--- SFDC Hack the framework sucks at passing dates server side.
        Date dMonthDate = Date.valueOf(monthDate);
        //--- SFDC hack since the framework can't pass sets
        Set<Id> accountIdsSet = new Set<Id>();
        accountIdsSet.addAll(accountIds);
        //@TODO Custom meta / pass as param?
        String hpdRtName    = 'Monthly HPD';

        hpdWrappers         = HpdSvc.retrieveHpdAllAccountsBySingleMonthlyResults( accountIdsSet,hpdRtName,dMonthDate );
        ResponseDto dto     = new ResponseDto();
        dto.isSuccess       = true;
        dto.values.put('HPD_ACCOUNTS_SINGLE_MONTH_WRAPPER_LIST',hpdWrappers);
        return dto;
    }

}