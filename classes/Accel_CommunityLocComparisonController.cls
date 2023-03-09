/**
 * Created by rnend on 1/31/2019.
 */

public with sharing class Accel_CommunityLocComparisonController {
    @AuraEnabled
    public static ResponseDto retrieveHoldPerDayByAccountsAllMonths( List<Id>  accountIds) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();

        //--- SFDC Hack hack make this real per locations!
        //Date dStartDate = Date.valueOf(sStartDate);
        //Date dEndDate = Date.valueOf(sEndDate);
        Date dStartDate = System.today().addMonths(-48);
        Date dEndDate = System.today();
        //--- SFDC hack since the framework can't pass sets
        Set<Id> accountIdsSet = new Set<Id>();
        accountIdsSet.addAll(accountIds);
        //@TODO Custom meta / pass as param?
        String hpdRtName    = 'Monthly HPD';

        hpdWrappers         =  HpdSvc.retrieveHpdAllAccountsByAllMonthResults(accountIdsSet,  hpdRtName, dStartDate, dEndDate);
        Map<Id,List<HpdWrapper>>  m = new Map<Id,List<HpdWrapper>>();
        //-====== @TODO do this client side.. this is the treegrid data.

        if (hpdWrappers != null && !hpdWrappers.isEmpty()) {
            for (HpdWrapper hpdWrap : hpdWrappers) {
                Id accountId = hpdWrap.accountId;
                if (accountId != null) {
                    if (!m.containsKey(accountId)) {
                        m.put(accountId,new List<HpdWrapper> { hpdWrap} );
                    } else {
                        List<HpdWrapper> hpdWraps = (List<HpdWrapper>)m.get(accountId);
                        hpdWraps.adD(hpdWrap);
                    }
                }
            }
        }


        ResponseDto dto     = new ResponseDto();
        dto.isSuccess       = true;
        dto.values.put('HPD_ACCOUNTS_ALL_MONTH_WRAPPER_MAP',m);
        return dto;
    }
}