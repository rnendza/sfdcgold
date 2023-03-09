public with sharing class Accel_RevenueStatementController {

    public static final String MAP_KEY_HPD_LIST         = 'HPD_LIST';
    public static final String MAP_KEY_ACCOUNT_LIST     = 'ACCOUNT_LIST';

    @AuraEnabled
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes    = CustomMetaDataSvc.retrieveCommunityAccountTypes();
        Integer iLimit              = 500; //@TODO Custom setting?
        dto.values.put(MAP_KEY_ACCOUNT_LIST,AccountSvc.retrieveAccounts( accountTypes,iLimit ).values() );
        dto.isSuccess = true;
        return dto;
    }

    /**
     *
     *
     * @param accountId
     * @param startDate the earliest hpd date.
     * @param endDate the latest hpd date.
     *
     * @return
     * @see HpdSvc
     * @see HpdWrapper
     */
    @AuraEnabled
    public static ResponseDto retrieveHoldPerDayByAccount( String accountId, String  startDate, String endDate ) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        //--- SFDC Hack the framework sucks at passing dates server side.
        Date dStartDate = (Date) JSON.deserialize(startDate,Date.class);
        Date dEndDate = (Date) JSON.deserialize(endDate,Date.class);

        //@TODO Custom meta / pass as param?
        String hpdRtName    = 'Daily HPD';
        String assetRtName  = 'VGT';
        Decimal defaultTaxRate = 30.0000;
        Decimal defaultAdminRate = 0.8513;

        Set<Id> assetIds    = AccountSvc.retrieveAccountAssets( accountId, assetRtName ).keySet();
      //  system.debug('assetIds for accountId='+accountId + '.. assetRtName='+assetRtName + '.. assetIds='+assetIds);

        hpdWrappers         = HpdSvc.retrieveHpdAssetRevenueResults( accountId ,assetIds,hpdRtName,dStartDate,dEndDate,defaultTaxRate,defaultAdminRate );
        ResponseDto dto     = new ResponseDto();
        dto.isSuccess       = true;
        dto.values.put('HPD_WRAPPER_LIST',hpdWrappers);
        return dto;
    }
}