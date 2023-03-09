public with sharing class Accel_CommunityPerformanceController {
    public static final String MAP_KEY_ACCOUNT_LIST             = 'ACCOUNT_LIST';
    public static final String MAP_KEY_HPD_LIST                 = 'HPD_WRAPPER_LIST';
    public static final String MACHINE_EXPORT_FIELD_NAMES       = 'MACHINE_EXPORT_FIELD_NAME_LIST';
    public static final String MAP_KEY_HPDDATE_LOCSHARETOTAL    = 'MAP_HPDDATE_LOCSHARETOTAL';
    public static final String MAP_KEY_HPDDATE_HPDCHILDREN      = 'MAP_HPDDATE_HPDCHILDREN';

    /**
     *
     *
     * @return a dto containing a list of strings of the field names to export.
     */
    @AuraEnabled
    public static ResponseDto retrieveMachineDataExportSettings() {
        ResponseDto dto = new ResponseDto();
        String settingName = 'MachineExport', fieldName='Export_Field_Names__c';
        Object o = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName,fieldName);
        if(o!=null) {
            String exportFieldNames = (String)o;
            dto.isSuccess = true;
            List<String> fieldNames = exportFieldNames.split('~');
            dto.values.put(MACHINE_EXPORT_FIELD_NAMES,fieldNames);
        }
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();

        //@TODO Merge the below into 1 call!
        Integer iLimit = 30;
        String settingName = 'Application_Search_Limits';
        String fieldName = 'Max_Account_Results__c';
        Object oMaxAccounts = CustomMetadataSvc.retrieveCommunityMetaFieldValue(settingName, fieldName);
        if (oMaxAccounts != null) {
            iLimit = ((Decimal) oMaxAccounts).intValue();
        }
        ResponseDto dtoExportFields = retrieveMachineDataExportSettings();
        if (dtoExportFields.isSuccess) {
            List<string> exportFields = new List<String>();
            try {
                exportFields = (List<String>) dtoExportFields.values.get(MACHINE_EXPORT_FIELD_NAMES);
                dto.values.put(MACHINE_EXPORT_FIELD_NAMES, exportFields);
            } catch (Exception e) {
                system.debug(logginglevel.error, e);
            }
        }
        Map<Id, Account> mAccountsByIds = AccountSvc.retrieveAccounts(accountTypes, iLimit);
        //if no igb license number remove from the list! ie corp HQ
        List<Account> filteredAccounts = new List<Account>();
        for (Account account : mAccountsByIds.values()) {
            if (account.IGB_License__c != null) {
                filteredAccounts.add(account);
            }
        }
        dto.values.put(MAP_KEY_ACCOUNT_LIST, filteredAccounts);
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
    @AuraEnabled (cacheable=true)
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

        ResponseDto dto     = new ResponseDto();

        Set<Id> assetIds    = AccountSvc.retrieveAccountAssets( accountId, assetRtName ).keySet();
        hpdWrappers         = HpdSvc.retrieveHpdAssetDailyResults( accountId,assetIds,hpdRtName,dStartDate,dEndDate,defaultTaxRate,defaultAdminRate );
        //------------ @TODO do this client side!!!! this is the chart data.
        Map<Date,Decimal> mHpdDate_LocshareTotal = new Map<Date,Decimal>();
        if (hpdWrappers != null && !hpdWrappers.isEmpty()) {
            for (HpdWrapper hpdWrap : hpdWrappers) {
                Date    dDate   = hpdWrap.hpdDate;
                Decimal dTotal  = hpdWrap.locShare;
                if (dDate != null) {
                    if (!mHpdDate_LocshareTotal.containsKey(dDate)) {
                        mHpdDate_LocshareTotal.put(dDate,dTotal);
                    } else {
                        Decimal currentTotal = (Decimal)mHpdDate_LocshareTotal.get(dDate);
                        currentTotal += dTotal;
                        mHpdDate_LocshareTotal.put(dDate,currentTotal);
                    }
                }
            }
            dto.isSuccess       = true;
        } else {
            dto.technicalMsg += '--no hpdwrappers found for HpdSvc.retrieveHpdAssetDailyResults ';
        }
        //-====== @TODO do this client side.. this is the treegrid data.
        Map<Date,List<HpdWrapper>> mHpdDate_HpdChildren = new Map<Date,List<HpdWrapper>>();
        if (hpdWrappers != null && !hpdWrappers.isEmpty()) {
            for (HpdWrapper hpdWrap : hpdWrappers) {
                Date    dDate   = hpdWrap.hpdDate;
                if (dDate != null) {
                    if (!mHpdDate_HpdChildren.containsKey(dDate)) {
                        mHpdDate_HpdChildren.put(dDate,new List<HpdWrapper> { hpdWrap} );
                    } else {
                        List<HpdWrapper> hpdWraps = (List<HpdWrapper>)mHpdDate_HpdChildren.get(dDate);
                        hpdWraps.add(hpdWrap);
                    }
                }
            }
        }
        dto.values.put('HPD_WRAPPER_LIST',hpdWrappers);
        dto.values.put(MAP_KEY_HPDDATE_LOCSHARETOTAL,mHpdDate_LocshareTotal);
        dto.values.put(MAP_KEY_HPDDATE_HPDCHILDREN,mHpdDate_HpdChildren);
        return dto;
    }
    @AuraEnabled (cacheable=true)
    public static ResponseDto retrieveHoldPerDayByAccountsMonthlyAggregates( List<Id>  accountIds, String  startDate, String endDate ) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();


        //--- SFDC Hack the framework sucks at passing dates server side.
        Date dStartDate = (Date) JSON.deserialize(startDate,Date.class);
        Date dEndDate = (Date) JSON.deserialize(endDate,Date.class);
        //--- SFDC hack since the framework can't pass sets
        Set<Id> accountIdsSet = new Set<Id>();
        accountIdsSet.addAll(accountIds);
        //@TODO Custom meta / pass as param?
        String hpdRtName    = 'Daily HPD';
        String assetRtName  = 'VGT';
        Decimal defaultTaxRate = 30.0000;
        Decimal defaultAdminRate = 0.8513;

        Set<Id> assetIds    = AccountSvc.retrieveAccountAssets( accountIdsSet, assetRtName ).keySet();
        hpdWrappers         = HpdSvc.retrieveHpdAssetMonthlyResults( accountIdsSet,assetIds,hpdRtName,dStartDate,dEndDate,defaultTaxRate,defaultAdminRate );
        ResponseDto dto     = new ResponseDto();
        dto.isSuccess       = true;
        dto.values.put('HPD_WRAPPER_LIST',hpdWrappers);
        return dto;
    }
}