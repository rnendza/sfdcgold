/**
 * HpdSvc is a class containing static methods to query hold per day and hold per day total objects.
 * @TODO seperate out for account / asset / muni ?
 */
public with sharing class HpdSvc {

    public final static String ACCT_AGGREGATION_DEVNAME                 = 'HPD_Account_Aggregation';
    public final static String ASSET_AGGREGATION_DEVNAME                = 'HPD_Account_Aggregation'; //@TODO Modify
    public final static String MUNICIPALITY_AGGREGATION_DEVNAME         = 'HPD_Municipality_Aggregation';

    public static HPD_Total_Setting__mdt hpdTotalMunicipalitySetting    = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(MUNICIPALITY_AGGREGATION_DEVNAME);
    public static HPD_Total_Setting__mdt hpdTotalAccountSetting         = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(ACCT_AGGREGATION_DEVNAME);
    public static HPD_Total_Setting__mdt hpdTotalAssetSetting           = CustomMetadataSvc.retrieveHpdTotalSettingsMeta('HPD_Asset_Aggregation');

    /**
     * @param hpdIds  - hold per day ids.
     * @return a list of hold per day sObjects with every field.
     * @note - be very careful with this as it does a select * and will not be well performing / not kind to heap size.
     */
    public static List<Hold_Per_Day__c> retrieveFullHpds(Set<Id> hpdIds) {
        List<Hold_Per_Day__c> hpds;
        DescribeSObjectResult describeResult = Hold_Per_Day__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String q = 'SELECT '+String.join(fieldNames,',')+' FROM  '+describeResult.getName() +' WHERE id in :hpdIds';
        hpds = DataBase.query(q);
        return hpds;
    }

    /**
     *
     * @param iNumMonths
     * @param iNumHpdRecs
     *
     * @return true if there is enough data to display aggregate totals, otherwise false.
     */
    public static Boolean hasEnoughHpdData(Integer iNumMonths, Decimal dNumHpdRecs) {
        Boolean hasEnough = false;
        if(iNumMonths != null && dNumHpdRecs != null) {
            iNumMonths = iNumMonths * -1;
            Integer iNumHpdRecs = dNumHpdRecs.intValue();
            hasEnough = iNumHpdRecs >= iNumMonths;
        }
        return hasEnough;
    }

    /**
     * Retrieves all columns on the Hold_Per_Day_Total__c object filtered by record type (ie. Asset / Machine etc)
     * and frequency (if applicable) ie. Daily / Monthly. Uses the number of months passed to figure out which
     * fields to write to.
     *
     * @param iMonths         - Number of months back to search for from most recent HPD Date attached to the account.
     * @param mHpdStatsByIds  - Aggregated HPD stats.
     * @param qType           - Query Type.. ie Account or Asset
     *
     * @return  a List of Hold_Per_Day_Total__c records to be updated.
     */
    public static List<Hold_Per_Day_Total__c> retrieveFullHpdTotals(Integer iMonths,Map<String,HpdStats> mHpdStatsByIds, String qType, String frequency,String locType) {
        String q = '';
        String filterCol = '';
        String hpdTotalRtName = '';
        String primaryFilterSoql = '';

        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();

        Set<String> filterIds = new Set<String>();
        Set<String> assetIds = new Set<String>();
        Set<String> accountIds = new Set<String>();
        if(qType == 'Asset') {
            hpdTotalRtName = 'Machine';
            for(String sAsset_Account : mHpdStatsByIds.keySet() ) {
               assetIds.add(sAsset_Account.left(18));
               accountIds.add(sAsset_Account.right(18));
            }
            system.debug('asset ids='+assetIds);
            //system.debug('accopunt ids='+accountIds``);
            primaryFilterSoql += ' Asset__c in :assetIds and Account__c in :accountIds ';
            //primaryFilterSoql += ' Asset__c in :assetIds  ';
        } else if ( qType == 'Account') {
            filterCol = 'Account__c';
            hpdTotalRtName = 'Location';
            filterIds = mHpdStatsByIds.keySet();
            primaryFilterSoql += ' Account__c in :filterIds ';
        } else if ( qType == 'Municipality') {
            filterCol = 'Municipality__c';
            hpdTotalRtName = 'Municipality';
            filterIds = mHpdStatsByIds.keySet();
            primaryFilterSoql += ' Municipality__c in :filterIds ';
        }
        DescribeSObjectResult describeResult = Hold_Per_Day_Total__c.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());

        String soqlFilterFreq = '';
        if((qType == 'Account' || qType == 'Municipality') && frequency != null) {
            soqlFilterFreq = ' and Frequency__c = :frequency ';
        }

        q += ' SELECT ' + String.join(fieldNames,',');
        q += ' FROM   ' + describeResult.getName();
        q += ' WHERE '  + primaryFilterSoql;
        q += ' and      RecordType.Name = :hpdTotalRtName ';
        q +=   soqlFilterFreq;
        q += ' FOR UPDATE ';
        system.debug(q);
        holdPerDayTotals = Database.query(q);
        Map <Id, Hold_Per_Day_Total__c > mHoldPerDayTotalsByIds = new Map<Id, Hold_Per_Day_Total__c> (holdPerDayTotals);
        Map< String, Hold_Per_Day_Total__c> mHoldPerDayTotalsByEntityIds =  new Map<String, Hold_Per_Day_Total__c>();
        //-- use either either account / asset / or muni id  for map key.
        for(Hold_Per_Day_Total__c holdPerDayTotal : holdPerDayTotals) {
            if(qType != null) {
                if(qType == 'Account') {
                    mHoldPerDayTotalsByEntityIds.put((String)holdPerDayTotal.get('Account__c'),holdPerDayTotal);
                } else if (qType == 'Asset') {
                    String key = (String)holdPerDayTotal.asset__c + (String)holdPerDayTotal.account__c;
                    mHoldPerDayTotalsByEntityIds.put(key,holdPerDayTotal);
                } else if (qType == 'Municipality') {
                    mHoldPerDayTotalsByEntityIds.put((String)holdPerDayTotal.get('Municipality__c'),holdPerDayTotal);
                }
            }
        }
        List<Hold_Per_Day_Total__c> holdPerDayTotalsToUpd = new List<Hold_Per_Day_Total__c>();
        //@TODO rework not placing data in seperate hpd stats fields?
        if (!mHoldPerDayTotalsByIds.isEmpty()) {
            for (String  keyId : mHpdStatsByIds.keySet()) {
                HpdStats hpdStats = (HpdStats) mHpdStatsByIds.get(keyId);
                Hold_Per_Day_Total__c holdPerDayTotal = mHoldPerDayTotalsByEntityIds.get(keyId);
                if (holdPerDayTotal != null && hpdStats != null) {
                    system.debug('evaluating holdPerDayTotal2='+holdPerDayTotal);
                    system.debug('hpdStats ='+hpdStats);
                    if (iMonths != null) {
                        if (qType == 'Asset') {
                            holdPerDayTotal.HPD_Total_Vgt_Count__C = 1;
                        }
                        switch on iMonths {
                            when -12 { // --- TRAILING 12 MONTHS.
                                holdPerDayTotal.Most_Recent_Hpd__c = hpdStats.ttm_maxHpdId;
                                holdPerDayTotal.Municipality__c = hpdStats.muniId;
                                holdPerDayTotal.Position__c = hpdStats.machinePosition;
                                holdPerDayTotal.Total_Nbr_of_HPD_Records__c = hpdStats.ttm_recordCount;
                                system.debug('fubar ttm number:'+holdPerDayTotal.HPD_TTM_Nbr_of_Records_Found__c);
                                system.debug('---- fubar iMonths='+iMonths + ' .. total number of hpd recors number='+holdPerDayTotal.Total_Nbr_of_HPD_Records__c);
                                if(hasEnoughHpdData(iMonths,holdPerDayTotal.Total_Nbr_of_HPD_Records__c)) {
                                    holdPerDayTotal.HPD_TTM_Revenue_Total__c = hpdStats.ttm_totalNetFunds;
                                    holdPerDayTotal.HPD_TTM_Daily_Total__c = hpdStats.ttm_totalHpd;
                                    holdPerDayTotal.HPD_TTM_Funds_In_Total__c = hpdStats.ttm_totalFundsIn;
                                    holdPerDayTotal.HPD_TTM_Funds_Out_Total__c = hpdStats.ttm_totalFundsOut;
                                    holdPerDayTotal.HPD_TTM_Nbr_of_Records_Found__c = hpdStats.ttm_recordCount;
                                    holdPerDayTotal.HPD_TTM_NTI__c = hpdStats.ttm_nti;
                                    holdPerDayTotal.HPD_TTM_Amount_Played__c = hpdStats.ttm_totalAmountPlayed;
                                    holdPerDayTotal.HPD_TTM_Amount_Won__c = hpdStats.ttm_totalAmountWon;
                                    holdPerDayTotal.TTM_Avg__c = hpdStats.ttm_avgHpd;
                                } else {
                                    holdPerDayTotal.HPD_TTM_Revenue_Total__c = 0;
                                    holdPerDayTotal.HPD_TTM_Daily_Total__c = 0;
                                    holdPerDayTotal.HPD_TTM_Funds_In_Total__c = 0;
                                    holdPerDayTotal.HPD_TTM_Funds_Out_Total__c = 0;
                                    holdPerDayTotal.HPD_TTM_Nbr_of_Records_Found__c = 0;
                                    holdPerDayTotal.HPD_TTM_NTI__c = 0;
                                    holdPerDayTotal.HPD_TTM_Amount_Played__c = 0;
                                    holdPerDayTotal.HPD_TTM_Amount_Won__c = 0;
                                    holdPerDayTotal.TTM_Avg__c = 0;
                                }
                                holdPerDayTotal.TTM_Total_Nbr_of_Days_in_Months__c = hpdStats.ttm_sumDaysInMonths;
                                if (qType == 'Account') {
                                    holdPerDayTotal.HPD_Total_VGT_Count__c = hpdStats.ttm_accountVgts;
                                }
                            }
                            when -6 { // --- TRAILING 6 MONTHS.
                                holdPerDayTotal.Most_Recent_Hpd__c = hpdStats.tsm_maxHpdId;
                                holdPerDayTotal.Municipality__c = hpdStats.muniId;
                                holdPerDayTotal.Position__c = hpdStats.machinePosition;
                                holdPerDayTotal.HPD_TSM_Nbr_of_Records_Found__c = hpdStats.tsm_recordCount;
                                if(hasEnoughHpdData(iMonths,holdPerDayTotal.HPD_TSM_Nbr_of_Records_Found__c)) {
                                    holdPerDayTotal.HPD_TSM_Revenue_Total__c = hpdStats.tsm_totalNetFunds;
                                    holdPerDayTotal.HPD_TSM_Daily_Total__c = hpdStats.tsm_totalHpd;
                                    holdPerDayTotal.HPD_TSM_Funds_In_Total__c = hpdStats.tsm_totalFundsIn;
                                    holdPerDayTotal.HPD_TSM_Funds_Out_Total__c = hpdStats.tsm_totalFundsOut;
                                    holdPerDayTotal.HPD_TSM_NTI__c = hpdStats.tsm_nti;
                                    holdPerDayTotal.HPD_TSM_Amount_Played__c = hpdStats.tsm_totalAmountPlayed;
                                    holdPerDayTotal.HPD_TSM_Amount_Won__c = hpdStats.tsm_totalAmountWon;
                                    holdPerDayTotal.TSM_Avg__c = hpdStats.tsm_avgHpd;
                                } else {
                                    holdPerDayTotal.HPD_TSM_Revenue_Total__c = 0;
                                    holdPerDayTotal.HPD_TSM_Daily_Total__c = 0;
                                    holdPerDayTotal.HPD_TSM_Funds_In_Total__c = 0;
                                    holdPerDayTotal.HPD_TSM_Funds_Out_Total__c = 0;
                                    holdPerDayTotal.HPD_TSM_NTI__c = 0;
                                    holdPerDayTotal.HPD_TSM_Amount_Played__c = 0;
                                    holdPerDayTotal.HPD_TSM_Amount_Won__c = 0;
                                    holdPerDayTotal.TSM_Avg__c = 0;
                                }
                                holdPerDayTotal.TSM_Total_Nbr_of_Days_in_Months__c = hpdStats.tsm_sumDaysInMonths;
                                if (qType == 'Account') {
                                    holdPerDayTotal.HPD_Total_VGT_Count__c = hpdStats.tsm_accountVgts;
                                }
                            }
                            when -3 { // 12 weeks
                                holdPerDayTotal.Municipality__c = hpdStats.muniId;
                                holdPerDayTotal.Position__c = hpdStats.machinePosition;
                                holdPerDayTotal.HPD_Nbr_of_Records_12_Weeks__c = hpdStats.totalRecsFound12Weeks;
                                if(hasEnoughHpdData(iMonths,holdPerDayTotal.HPD_Nbr_of_Records_12_Weeks__c )) {
                                    holdPerDayTotal.HPD_Funds_In_Total_12_weeks__c = hpdStats.totalFundsIn12Weeks;
                                                    holdPerDayTotal.HPD_Funds_Out_Total_12_Weeks__c = hpdStats.totalFundsOut12Weeks;
                                    holdPerDayTotal.HPD_Revenue_Total_12_Weeks__c = hpdStats.totalNetFunds12Weeks;
                                    holdPerDayTotal.HPD_Amount_Played_12_Weeks__c = hpdStats.totalAmountPlayed12Weeks;
                                    holdPerDayTotal.HPD_Amount_Won_12_Weeks__c = hpdStats.totalAmountWon12Weeks;
                                    holdPerDayTotal.HPD_NTI_12_Weeks__c = hpdStats.totalNti12Weeks;
                                    holdPerDayTotal.Twelve_Week_HPD_Avg__c = hpdStats.avgHpd12Weeks;
                                } else {
                                    holdPerDayTotal.HPD_Funds_In_Total_12_weeks__c = 0;
                                    holdPerDayTotal.HPD_Funds_Out_Total_12_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Revenue_Total_12_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Amount_Played_12_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Amount_Won_12_Weeks__c = 0;
                                    holdPerDayTotal.HPD_NTI_12_Weeks__c = 0;
                                    holdPerDayTotal.Twelve_Week_HPD_Avg__c = 0;
                                }
                                holdPerDayTotal.Total_Nbr_of_Days_in_Months_12_Weeks__c = hpdStats.totalDaysInMonths12Weeks;
                                if (qType == 'Account') {
                                    holdPerDayTotal.HPD_Total_VGT_Count__c = hpdStats.totalAccelVgtCount;
                                }
                            } when -2 { // 8 weeks
                                holdPerDayTotal.Municipality__c = hpdStats.muniId;
                                holdPerDayTotal.Position__c = hpdStats.machinePosition;
                                holdPerDayTotal.HPD_Nbr_of_Records_8_Weeks__c = hpdStats.totalRecsFound8Weeks;
                                if(hasEnoughHpdData(iMonths,holdPerDayTotal.HPD_Nbr_of_Records_8_Weeks__c )) {
                                    holdPerDayTotal.HPD_Funds_In_Total_8_Weeks__c = hpdStats.totalFundsIn8Weeks;
                                    holdPerDayTotal.HPD_Funds_Out_Total_8_Weeks__c = hpdStats.totalFundsOut8Weeks;
                                    holdPerDayTotal.HPD_Revenue_Total_8_Weeks__c = hpdStats.totalNetFunds8Weeks;
                                    holdPerDayTotal.HPD_Amount_Played_8_Weeks__c = hpdStats.totalAmountPlayed8Weeks;
                                    holdPerDayTotal.HPD_Amount_Won_8_Weeks__c = hpdStats.totalAmountWon8Weeks;
                                    holdPerDayTotal.HPD_NTI_8_Weeks__c = hpdStats.totalNti8Weeks;
                                    holdPerDayTotal.Eight_Week_HPD_Avg__c = hpdStats.avgHpd8Weeks;
                                } else {
                                    holdPerDayTotal.HPD_Funds_In_Total_8_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Funds_Out_Total_8_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Revenue_Total_8_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Amount_Played_8_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Amount_Won_8_Weeks__c = 0;
                                    holdPerDayTotal.HPD_NTI_8_Weeks__c = 0;
                                    holdPerDayTotal.Eight_Week_HPD_Avg__c = hpdStats.avgHpd8Weeks;
                                }
                                holdPerDayTotal.Total_Nbr_of_Days_in_Months_8_Weeks__c = hpdStats.totalDaysInMonths8Weeks;
                                if (qType == 'Account') {
                                    holdPerDayTotal.HPD_Total_VGT_Count__c = hpdStats.totalAccelVgtCount;
                                }
                            } when -1 { // 4 weeks
                                holdPerDayTotal.Municipality__c = hpdStats.muniId;
                                holdPerDayTotal.position__c = hpdStats.machinePosition;
                                holdPerDayTotal.HPD_Nbr_of_Records_4_Weeks__c = hpdStats.totalRecsFound4Weeks;
                                if(hasEnoughHpdData(iMonths,holdPerDayTotal.HPD_Nbr_of_Records_4_Weeks__c )) {
                                    holdPerDayTotal.HPD_Funds_In_Total_4_weeks__c = hpdStats.totalFundsIn4Weeks;
                                    holdPerDayTotal.HPD_Funds_Out_Total_4_Weeks__c = hpdStats.totalFundsOut4Weeks;
                                    holdPerDayTotal.HPD_Revenue_Total_4_Weeks__c = hpdStats.totalNetFunds4Weeks;
                                    holdPerDayTotal.HPD_Amount_Played_4_Weeks__c = hpdStats.totalAmountPlayed4Weeks;
                                    holdPerDayTotal.HPD_Amount_Won_4_Weeks__c = hpdStats.totalAmountWon4Weeks;
                                    holdPerDayTotal.HPD_NTI_4_Weeks__c = hpdStats.totalNti4Weeks;
                                    holdPerDayTotal.Four_Week_HPD_Avg__c = hpdStats.avgHpd4Weeks;
                                    holdPerDayTotal.Total_Nbr_of_Days_in_Months_4_Weeks__c = hpdStats.totalDaysInMonths4Weeks;
                                } else {
                                    holdPerDayTotal.HPD_Funds_In_Total_4_weeks__c = 0;
                                    holdPerDayTotal.HPD_Funds_Out_Total_4_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Revenue_Total_4_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Amount_Played_4_Weeks__c = 0;
                                    holdPerDayTotal.HPD_Amount_Won_4_Weeks__c = 0;
                                    holdPerDayTotal.HPD_NTI_4_Weeks__c = 0;
                                    holdPerDayTotal.Four_Week_HPD_Avg__c = 0;
                                    holdPerDayTotal.Total_Nbr_of_Days_in_Months_4_Weeks__c = 0;
                                }
                                if (qType == 'Account' ) {

                                    holdPerDayTotal.HPD_Total_VGT_Count__c = hpdStats.totalAccelVgtCount;

                                    //holdPerDayTotal.Total_of_Days_in_Monthly_Time_Period__c = hpdStats.sumDaysInMonths;
                                }
                            }
                        }
                    } else {
                        // muni aggregation
                        //@TODO not every field here yet.
                        if(locType == null) {
                            holdPerDayTotal.HPD_Municipality_VGT_Total__c = hpdStats.totalVgtCount;

                            holdPerDayTotal.HPD_Municipality_TTM_Amount_Played__c = hpdStats.ttm_totalAmountPlayed;
                            holdPerDayTotal.HPD_Municipality_TTM_Amount_Won__c = hpdStats.ttm_totalAmountWon;
                            holdPerDayTotal.HPD_Municipality_TTM_NTI__c = hpdStats.ttm_nti;
                            holdPerDayTotal.HPD_Municipality_TTM_Funds_In_Total__c = hpdStats.ttm_totalFundsIn;
                            holdPerDayTotal.HPD_Municipality_TTM_Funds_Out_Total__c = hpdStats.ttm_totalFundsOut;

                            holdPerDayTotal.HPD_Municipality_Funds_Out_Total_12weeks__c = hpdStats.totalFundsOut12Weeks;
                            holdPerDayTotal.HPD_Municipality_Funds_Out_Total_8_Weeks__c = hpdStats.totalFundsOut8Weeks;
                            holdPerDayTotal.HPD_Municipality_Funds_Out_Total_4_Weeks__c = hpdStats.totalFundsOut4Weeks;

                            holdPerDayTotal.HPD_Municipality_Funds_In_Total_12_Weeks__c = hpdStats.totalFundsIn12Weeks;
                            holdPerDayTotal.HPD_Municipality_Funds_In_Total_8_Weeks__c = hpdStats.totalFundsIn8Weeks;
                            holdPerDayTotal.HPD_Municipality_Funds_In_Total_4_Weeks__c = hpdStats.totalFundsIn4Weeks;

                            holdPerDayTotal.HPD_Municipality_NTI_Total_12_Weeks__c = hpdStats.totalNti12Weeks;
                            holdPerDayTotal.HPD_Municipality_NTI_Total_8_Weeks__c = hpdStats.totalNti8Weeks;
                            holdPerDayTotal.HPD_Municipality_NTI_Total_4_Weeks__c = hpdStats.totalNti4Weeks;

                            holdPerDayTotal.HPD_Municipality_Revenue_Total_12_Weeks__c = hpdStats.totalAccelRev12Weeks;
                            holdPerDayTotal.HPD_Municipality_Revenue_Total_8_Weeks__c = hpdStats.totalAccelRev8Weeks;
                            holdPerDayTotal.HPD_Municipality_Revenue_Total_4_Weeks__c = hpdStats.totalAccelRev4Weeks;

                            holdPerDayTotal.HPD_Municipality_Amount_Won_12_Weeks__c = hpdStats.totalAmountWon12Weeks;
                            holdPerDayTotal.HPD_Municipality_Amount_Won_8_Weeks__c = hpdStats.totalAmountWon8Weeks;
                            holdPerDayTotal.HPD_Municipality_Amount_Won_4_Weeks__c = hpdStats.totalAmountWon4Weeks;

                            holdPerDayTotal.HPD_Municipality_Amount_Played_12_Weeks__c = hpdStats.totalAmountPlayed12Weeks;
                            holdPerDayTotal.HPD_Municipality_Amount_Played_8_Weeks__c = hpdStats.totalAmountPlayed8Weeks;
                            holdPerDayTotal.HPD_Municipality_Amount_Played_4_Weeks__c = hpdStats.totalAmountPlayed4Weeks;
                        } else {
                            //HPD_Muni_Accel_Revenue_Total_12_Weeks new field
                            //hpdStats.totalVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                            //hpdStats.totalAccelRev12Weeks = (Decimal) ar.get('revTotal12Weeks');

                            holdPerDayTotal.HPD_Municipality_Accel_Total_VGT_Count__c = hpdStats.totalVgtCount;
                            holdPerDayTotal.HPD_Municipality_Accel_Revenue_Total_12__c = hpdStats.totalAccelRev12Weeks;
                        }

                    }
                    holdPerDayTotalsToUpd.add(holdPerDayTotal);
                }
            }
        } else {
            system.debug(logginglevel.warn, 'build asset hold per day totals. no hpd records for provided  ids of. '+mHpdStatsByIds.keySet());
        }
        return holdPerDayTotalsToUpd;
    }

    /**
     *
     *
     * @param iMonths
     * @param qType
     * @param results
     * @param mHpdStatsByIds
     *
     * @return
     */
    public static Map<String,HpdStats> buildHpdResultsMap( Integer iMonths, String qType,
                                                            List<AggregateResult> results,Map<String,HpdStats> mHpdStatsByIds) {
        String keyField = '';
        if(mHpdStatsByIds == null) {
            mHpdStatsByIds = new Map<String,HpdStats>();
        }
        if(qType == 'Asset') {
           keyField =  'Asset__c';  //MAP Key...
        } else if (qType =='Account') {
            keyField = 'Account__c';
        }
        switch  on iMonths {
            when -12 { // --- TRAILING 12 MONTHS.
                for(AggregateResult ar : results ) {
                    HpdStats hpdStats = new HpdStats();
                    hpdStats.ttm_maxHpdId = (Id) ar.get('maxHpdId');
                    hpdStats.machinePosition = (Decimal) ar.get('position');
                    hpdStats.ttm_totalNetFunds = (Decimal) ar.get('netFundsTotal');
                    hpdStats.ttm_totalHpd = (Decimal) ar.get('hpdTotal');
                    hpdStats.ttm_totalFundsIn = (Decimal) ar.get('fundsInTotal');
                    hpdStats.ttm_totalFundsOut = (Decimal) ar.get('fundsOutTotal');
                    hpdStats.ttm_recordCount = Integer.valueOf((Decimal) ar.get('recordCount'));
                    hpdStats.ttm_totalAmountWon = (Decimal) ar.get('amountWonTotal');
                    hpdStats.ttm_totalAmountPlayed = (Decimal) ar.get('amountPlayedTotal');
                    hpdStats.ttm_nti = (Decimal) ar.get('nti');
                    hpdStats.muniId = (Id) ar.get('muniId');
                    hpdStats.ttm_avgHpd = (Decimal) ar.get('avgHpd');
                    hpdStats.ttm_sumDaysInMonths = Integer.valueOf((Decimal) ar.get('daysInMonthTotal'));
                    hpdStats.accountId = (Id) ar.get('Account__c');
                    if(qType == 'Account') {
                        hpdStats.totalAccelVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                    }
                    if(qType == 'Asset') {
                        hpdStats.assetId =  (Id) ar.get('Asset__c');
                    }
                    String mapKey = '';
                    if(qType == 'Account') {
                        mapKey = (String) ar.get('Account__c');
                    } else if (qType == 'Asset') {
                        mapKey = (String) ar.get('Asset__c')+(String)ar.get('Account__c');
                        system.debug('mapKey='+mapKey);
                    }
                    mHpdStatsByIds.put(mapKey, hpdStats);
                }
            }
            when -6 { // --- TRAILING 6 MONTHS.
                for(AggregateResult ar : results ) {
                    HpdStats hpdStats = new HpdStats();
                    hpdStats.tsm_maxHpdId = (Id) ar.get('maxHpdId');
                    hpdStats.machinePosition = (Decimal) ar.get('position');
                    hpdStats.tsm_totalNetFunds = (Decimal) ar.get('netFundsTotal');
                    hpdStats.tsm_totalHpd = (Decimal) ar.get('hpdTotal');
                    hpdStats.tsm_totalFundsIn = (Decimal) ar.get('fundsInTotal');
                    hpdStats.tsm_totalFundsOut = (Decimal) ar.get('fundsOutTotal');
                    hpdStats.tsm_recordCount = Integer.valueOf((Decimal) ar.get('recordCount'));
                    hpdStats.tsm_totalAmountWon = (Decimal) ar.get('amountWonTotal');
                    hpdStats.tsm_totalAmountPlayed = (Decimal) ar.get('amountPlayedTotal');
                    hpdStats.tsm_nti = (Decimal) ar.get('nti');
                    hpdStats.muniId = (Id) ar.get('muniId');
                    hpdStats.tsm_avgHpd = (Decimal) ar.get('avgHpd');
                    hpdStats.tsm_sumDaysInMonths = Integer.valueOf((Decimal) ar.get('daysInMonthTotal'));
                    hpdStats.accountId = (Id) ar.get('Account__c');
                    if(qType == 'Account') {
                        hpdStats.totalAccelVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                    }
                    if(qType == 'Asset') {
                        hpdStats.assetId =  (Id) ar.get('Asset__c');
                    }
                    String mapKey = '';
                    if(qType == 'Account') {
                        mapKey = (String) ar.get('Account__c');
                    } else if (qType == 'Asset') {
                        mapKey = (String) ar.get('Asset__c')+(String)ar.get('Account__c');
                        system.debug('mapKey='+mapKey);
                    }
                    mHpdStatsByIds.put(mapKey, hpdStats);
                }
            }
            when -3 { // ---- LAST 12 WEEKS
                for(AggregateResult ar :results) {
                    HpdStats hpdStats = new HpdStats();
                    hpdStats.machinePosition = (Decimal) ar.get('position');
                    hpdStats.totalNetFunds12Weeks = (Decimal) ar.get('netFundsTotal');
                    hpdStats.totalFundsIn12Weeks = (Decimal) ar.get('fundsInTotal');
                    hpdStats.totalFundsOut12Weeks  = (Decimal) ar.get('fundsOutTotal');
                    hpdStats.totalAmountWon12Weeks = (Decimal) ar.get('amountWonTotal');
                    hpdStats.totalAmountPlayed12Weeks = (Decimal) ar.get('amountPlayedTotal');
                    hpdStats.totalNti12Weeks =  (Decimal) ar.get('nti');
                    hpdStats.muniId = (Id) ar.get('muniId');
                    hpdStats.totalRecsFound12Weeks = Integer.valueOf((Decimal) ar.get('recordCount'));
                    hpdStats.avgHpd12Weeks = (Decimal)ar.get('avgHpd');
                    hpdStats.totalDaysInMonths12Weeks = Integer.valueOf((Decimal) ar.get('daysInMonthTotal'));
                    hpdStats.accountId = (Id) ar.get('Account__c');
                    if(qType == 'Account') {
                        hpdStats.totalAccelVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                    }
                    if(qType == 'Asset') {
                        hpdStats.assetId =  (Id) ar.get('Asset__c');
                    }
                    String mapKey = '';
                    if(qType == 'Account') {
                        mapKey = (String) ar.get('Account__c');
                    } else if (qType == 'Asset') {
                        mapKey = (String) ar.get('Asset__c')+(String)ar.get('Account__c');
                    }
                    mHpdStatsByIds.put(mapKey, hpdStats);
                }
            }
            when -2 { // ---- LAST 8 WEEKS
                for(AggregateResult ar :results) {
                    HpdStats hpdStats = new HpdStats();
                    hpdStats.machinePosition = (Decimal) ar.get('position');
                    hpdStats.totalNetFunds8Weeks = (Decimal) ar.get('netFundsTotal');
                    hpdStats.totalFundsIn8Weeks = (Decimal) ar.get('fundsInTotal');
                    hpdStats.totalFundsOut8Weeks  = (Decimal) ar.get('fundsOutTotal');
                    hpdStats.totalAmountWon8Weeks = (Decimal) ar.get('amountWonTotal');
                    hpdStats.totalAmountPlayed8Weeks = (Decimal) ar.get('amountPlayedTotal');
                    hpdStats.totalNti8Weeks =  (Decimal) ar.get('nti');
                    hpdStats.muniId = (Id) ar.get('muniId');
                    hpdStats.totalRecsFound8Weeks = Integer.valueOf((Decimal) ar.get('recordCount'));
                    hpdStats.avgHpd8Weeks = (Decimal)ar.get('avgHpd');
                    hpdStats.totalDaysInMonths8Weeks = Integer.valueOf((Decimal) ar.get('daysInMonthTotal'));
                    hpdStats.accountId = (Id) ar.get('Account__c');
                    if(qType == 'Account') {
                        hpdStats.totalAccelVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                    }
                    if(qType == 'Asset') {
                        hpdStats.assetId =  (Id) ar.get('Asset__c');
                    }
                    String mapKey = '';
                    if(qType == 'Account') {
                        mapKey = (String) ar.get('Account__c');
                    } else if (qType == 'Asset') {
                        mapKey = (String) ar.get('Asset__c')+(String)ar.get('Account__c');
                    }
                    mHpdStatsByIds.put(mapKey, hpdStats);
                }
            }
            when -1 { // --- LAST 4 WEEKS
                for(AggregateResult ar :results) {
                    HpdStats hpdStats = new HpdStats();
                    hpdStats.machinePosition = (Decimal) ar.get('position');
                    hpdStats.totalNetFunds4Weeks = (Decimal) ar.get('netFundsTotal');
                    hpdStats.totalFundsIn4Weeks = (Decimal) ar.get('fundsInTotal');
                    hpdStats.totalFundsOut4Weeks  = (Decimal) ar.get('fundsOutTotal');
                    hpdStats.totalAmountWon4Weeks = (Decimal) ar.get('amountWonTotal');
                    hpdStats.totalAmountPlayed4Weeks = (Decimal) ar.get('amountPlayedTotal');
                    hpdStats.totalNti4Weeks =  (Decimal) ar.get('nti');
                    hpdStats.muniId = (Id) ar.get('muniId');
                    hpdStats.totalRecsFound4Weeks = Integer.valueOf((Decimal) ar.get('recordCount'));
                    hpdStats.avgHpd4Weeks = (Decimal)ar.get('avgHpd');
                    hpdStats.totalDaysInMonths4Weeks  = Integer.valueOf((Decimal) ar.get('daysInMonthTotal'));
                    hpdStats.accountId = (Id) ar.get('Account__c');
                    if(qType == 'Account') {
                        hpdStats.totalAccelVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                    }
                    if(qType == 'Asset') {
                        hpdStats.assetId =  (Id) ar.get('Asset__c');
                    }
                    String mapKey = '';
                    if(qType == 'Account') {
                        mapKey = (String) ar.get('Account__c');
                    } else if (qType == 'Asset') {
                        mapKey = (String) ar.get('Asset__c')+(String)ar.get('Account__c');
                    }
                    mHpdStatsByIds.put(mapKey, hpdStats);
                }
            }
        }
        return mHpdStatsByIds;
    }
   /**
    *
    *
    * @param iMonths
    * @param qType
    * @param results
    * @param mHpdStatsByIds
    *
    * @return
    */
    public static Map<String,HpdStats> buildHpdTotalResultsMap( String qType,
            List<AggregateResult> results,Map<String,HpdStats> mHpdStatsByIds, String locType) {
        String keyField = '';
        if(mHpdStatsByIds == null) {
            mHpdStatsByIds = new Map<String,HpdStats>();
        }
        if(qType == 'Municipality') {
            keyField =  'Municipality__c';  //MAP Key...
        }
        for(AggregateResult ar : results) {
            HpdStats hpdStats = new HpdStats();

            //hpdStats.ttm_totalNetFunds = (Decimal) ar.get('netFundsTotal');
            hpdStats.muniId = (Id) ar.get('Municipality__c');
            if(locType == null) {

                hpdStats.totalNti8Weeks = (Decimal) ar.get('nti8Weeks');
                hpdStats.totalNti4Weeks = (Decimal) ar.get('nti4Weeks');

                hpdStats.totalAmountPlayed12Weeks = (Decimal) ar.get('amountPlayed12Weeks');
                hpdStats.totalAmountPlayed8Weeks = (Decimal) ar.get('amountPlayed8Weeks');
                hpdStats.totalAmountPlayed4Weeks = (Decimal) ar.get('amountPlayed4Weeks');
                hpdStats.totalVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                hpdStats.ttm_totalVgts = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                hpdStats.ttm_totalAmountPlayed = (Decimal) ar.get('ttmAmountPlayed');
                hpdStats.ttm_totalAmountWon = (Decimal) ar.get('ttmAmountWon');
                hpdStats.ttm_nti = (Decimal) ar.get('ttmNTI');
                hpdStats.ttm_recordCount = Integer.valueOf((Decimal) ar.get('recordCount'));
                hpdStats.ttm_totalNetFunds = (Decimal) ar.get('netFundsTotal');
                hpdStats.ttm_totalFundsIn = (Decimal) ar.get('ttmFundsInTotal');
                hpdStats.ttm_totalFundsOut = (Decimal) ar.get('ttmFundsOutTotal');

                hpdStats.totalAccelRev12Weeks = (Decimal) ar.get('revTotal12Weeks');
                hpdStats.totalAccelRev8Weeks = (Decimal) ar.get('revTotal8Weeks');
                hpdStats.totalAccelRev4Weeks = (Decimal) ar.get('revTotal4Weeks');


                hpdStats.totalFundsOut12Weeks = (Decimal) ar.get('fundsOutTotal12Weeks');
                hpdStats.totalFundsOut8Weeks = (Decimal) ar.get('fundsOutTotal8Weeks');
                hpdStats.totalFundsOut4Weeks = (Decimal) ar.get('fundsOutTotal4Weeks');

                hpdStats.totalFundsIn12Weeks = (Decimal) ar.get('fundsInTotal12Weeks');
                hpdStats.totalFundsIn8Weeks = (Decimal) ar.get('fundsInTotal8Weeks');
                hpdStats.totalFundsIn4Weeks = (Decimal) ar.get('fundsInTotal4Weeks');

                hpdStats.totalNti12Weeks = (Decimal) ar.get('nti12Weeks');
                hpdStats.totalAmountWon12Weeks = (Decimal) ar.get('amountWon12Weeks');
                hpdStats.totalAmountWon8Weeks = (Decimal) ar.get('amountWon8Weeks');
                hpdStats.totalAmountWon4Weeks = (Decimal) ar.get('amountWon4Weeks');

                hpdStats.totalAmountPlayed12Weeks = (Decimal) ar.get('amountPlayed12Weeks');
                hpdStats.totalAmountPlayed8Weeks = (Decimal) ar.get('amountPlayed8Weeks');
                hpdStats.totalAmountPlayed4Weeks = (Decimal) ar.get('amountPlayed4Weeks');

                system.debug('------------ hpdStats after write=' + hpdStats);
            } else { //Accel Account currently only supported
                //HPD_Muni_Accel_Revenue_Total_12_Weeks new field
                hpdStats.totalVgtCount = Integer.valueOf((Decimal) ar.get('vgtTotal'));
                hpdStats.totalAccelRev12Weeks = (Decimal) ar.get('revTotal12Weeks');
            }
            mHpdStatsByIds.put((Id) ar.get(keyField), hpdStats);
        }
        return mHpdStatsByIds;
    }

    /**
     *
     * @param iMonths   - The nbr of months we are looking to aggregate the query by (negative value) -12, -6, -3, -2, or -1
     * @param qType     - The type of  query.. ie Account or Asset or Municipality.
     * @param lookupIds - The accountIds or AssetIds or Muni Itds.
     * @param rtName    - The Hpd record Type ie.  Daily HPD or Monthly HPD
     * @return          - A list of Hold_per_day_total__c records for update.
     */
    public static List<Hold_Per_Day_Total__c> updateHpdTotals(  Integer iMonths,String qType, Set<Id> lookupIds,
            String rtName, String frequency, String locType) {

        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        List<AggregateResult> ars = new List<AggregateResult>();
        Map<String,HpdStats> mHpdStatsByIds = new Map<String,HpdStats>();
        if(qType == 'Account' || qType == 'Asset') {
            ars = retrieveHpdAggregateResults(iMonths, qType, lookupIds, rtName);
            for(AggregateResult ar : ars) {
                system.debug('--ar = '+ar);
            }
            buildHpdResultsMap(iMonths, qType, ars, mHpdStatsByIds);
            for(HpdStats hStat : mHpdStatsByIds.values()) {
                system.debug('---hStat='+hStat);
            }
           holdPerDayTotals = retrieveFullHpdTotals(iMonths, mHpdStatsByIds, qType, frequency,locType);
            for(Hold_Per_Day_Total__c holdPerDayTotal : holdPerDayTotals) {
                system.debug('--- hpd total='+holdPerDayTotal);
            }
        } else if (qType == 'Municipality') {
            ars = retrieveHpdTotalMuniAggregateResults('Location',lookupIds,frequency,locType);
            for(AggregateResult ar : ars) {
                system.debug('--ar = '+ar);
            }
            buildHpdTotalResultsMap(qType,ars,mHpdStatsByIds,locType);
            for(HpdStats hStat : mHpdStatsByIds.values()) {
                system.debug('---hStatxxxxxx='+hStat);
            }
            holdPerDayTotals = retrieveFullHpdTotals(null,mHpdStatsByIds,qType,frequency,locType);
            for(Hold_Per_Day_Total__c holdPerDayTotal : holdPerDayTotals) {
                system.debug('--- hpd total='+holdPerDayTotal);
            }
        }
        return  holdPerDayTotals;
    }

    /**
     * A generic query to aggregate either Asset or Account based data (either monthly or daily) for n number of months.
     *
     * @param iMonths   - The nbr of months we are looking to aggregate the query by (negative value) -12,-6,-3,-2.-1.
     * @param qType     - The type of  query.. ie Account or Asset
     * @param lookupIds - The accountIds or AssetIds.
     * @param rtName    - The Hpd record Type ie Daily HPD or Monthly HPD
     *
     * @return           - a list of aggregate results to  process.
     */
    public static List<AggregateResult> retrieveHpdAggregateResults(Integer iMonths, String qType, Set<Id> lookupIds,
                                                                    String rtName) {
        system.debug('fubar .. iMonths='+imonths);
        system.debug('fubar .. qType='+qType);
        system.debug('fubar lookupIds...' + lookupIds);
        system.debug('fubar rtName='+rtName);
        List<AggregateResult> results = new List<AggregateResult>();
        String query = '';
        String primarySelectCol         = getPrimarySelectColumn(qType);
        String secondarySelectSql       = getSecondarySelectSql(qType);
        String primaryWhereFilterCol    = getPrimaryWhereFilter(qType);
        String endDateSoql              = getEndDateSoql(iMonths);
        //Date lastDailyUploadDate =    hpdTotalAssetSetting.Last_Daily_HPD_Upload_Date__c; //manually updated for now.
        //--- since this was changed to automated assume it was yesterday.
        Date lastDailyUploadDate = System.today().addDays(-1);
        //Set<String> excludedAcctTypes   = new Set<String>{'Discontinued Account'};
        Set<String> excludedAcctTypes   = new Set<String>();

        query += 'SELECT ' + primarySelectCol                                       +','    ;
        query +=             secondarySelectSql                                             ;
        query += '          MAX(Id)                                 maxHpdId, '             ;
        query += '          MAX(Account__r.MunicipalityLookup__c)   muniId, '               ;
        query += '          MAX(Account__r.Most_Recent_Hold_Per_Day__r.Date__c) mostRecentHpd, ' ;
        query += '          SUM(Net_Funds__c)                       netFundsTotal, '        ;
        query += '          SUM(Net_Funds__c)                       netAccelRevTotal, '     ;
        query += '          SUM(Funds_In__c)                        fundsInTotal, '         ;
        query += '          SUM(Funds_Out__c)                       fundsOutTotal, '        ;
        query += '          SUM(Amount_Played__c)                   amountPlayedTotal, '    ;
        query += '          SUM(Amount_Won__c)                      amountWonTotal, '       ;
        query += '          AVG(HPD__c)                             avgHpd, '               ;
        query += '          SUM(Nti__c)                             nti, '                  ;
        query += '          AVG(VGT_Count__c)                       vgtTotal, '             ;
        query += '          MAX(Position__c)                        position, '             ;
        query += '          SUM(HPD__c)                             hpdTotal, '             ;
        query += '          COUNT(Id)                               recordCount, '          ;
        query += '          SUM(Days_In_Month__c)                   daysInMonthTotal '      ;
        query += 'FROM      Hold_Per_Day__c '                                               ;
        query += 'WHERE ' + primaryWhereFilterCol + '               in  :lookupIds '        ;
        query += 'and       RecordType.Name                         =   :rtName '           ;
        query += 'and       Account__r.Type                         NOT IN :excludedAcctTypes ';
        if(qType != 'Asset') {
            query += 'and       Date_LTE_Acct_Most_Recent_HPD__c        =   true '          ;
        }
        query +=            endDateSoql                                                     ;
        query += 'GROUP BY '+primarySelectCol                                               ;
        if(qType == 'Asset') {
            query += ' ,Account__c ';
        }
        system.debug('assetIds='+lookupIds);
        system.debug('rtName='+rtName);
        system.debug(query);
        results = Database.query(query);

        //@TODO try / catch
        return results;
    }
    /**
     * Returns SOQL so that we can use a formula field to simulate Field A vs Field B comparison
     * So that we can get accurate 12 month , 12 week etc timelines as opposed to real clock time.
     * The formula field looks at either account. most recent hold per day (for monthlies) or.. as a hack currently......
     * The custom metadata type for HPD Asset aggregation for daily. ie. Last_Daily_HPD_Upload_Date__c
     *
     * @param iMonths - The nbr of months we are looking to aggregate the query by (negative value)
     * @return a string containing additional where criteria when querying hold per day.
     */
    @testvisible
    private static String getEndDateSoql(Integer iMonths) {
        String q = '';
        switch on iMonths {
            when -12 {
                q = ' and Date_Bt_Most_Recent_HPD_and_12_Mths__c = true ';
            }
            when -6 {
                q = ' and Date_Bt_Most_Recent_HPD_and_6_Mths__c = true ';
            }
            when -3 {
                q = ' and Date_Bt_Most_Recent_HPD_and_3_Mths__c = true ';
            }
            when -2 {
                q = ' and Date_Bt_Most_Recent_HPD_and_2_Mths__c = true ';
            }
            when -1 {
                q = ' and Date_Bt_Most_Recent_HPD_and_1_Mth__c = true ';
            }
        }
        return q;
    }
    /**
     *
     *
     * @param qType
     *
     * @return
     */
    @testvisible
    private static String getSecondarySelectSql(String qType) {
        String colName = '';
        if(qType == 'Account') {
            colName = '';
        } else if (qType == 'Asset') {
            colName = ' Account__c, ';
        }
        return colName;
    }
    /**
     *
     *
     * @param qType
     *
     * @return
     */
    @testvisible
    private static String getPrimarySelectColumn(String qType) {
        String colName = '';
        if(qType == 'Account') {
            colName = ' Account__c  ';
        } else if (qType == 'Asset') {
            colName = ' Asset__c ';
        }
        return colName;
    }
    /**
     *
     *
     * @param qType
     *
     * @return
     */
    @testvisible
    private static String getPrimaryWhereFilter(String qType) {
        return getPrimarySelectColumn(qType);
    }

    public static List<AggregateResult> retrieveHpdTotalMuniAggregateResults(String rtName, Set<Id> muniIds, String frequency, String locType) {
        List<AggregateResult> results = new List<AggregateResult>();
        String query = '';

        query += 'SELECT    Municipality__c ' + ',' ;
        query += '          SUM(HPD_TTM_Funds_In_Total__c)          netFundsTotal, '            ;
        query += '          SUM(HPD_TTM_Funds_In_Total__c)          ttmFundsInTotal, '       ;
        query += '          SUM(HPD_TTM_Funds_Out_Total__c)         ttmFundsOutTotal, '       ;
        query += '          SUM(hpd_total_vgt_count__c)             vgtTotal, '              ;
        query += '          SUM(HPD_TTM_Amount_Played__c)           ttmAmountPlayed, '         ;
        query += '          SUM(HPD_TTM_Amount_Won__c)              ttmAmountWon, '            ;
        query += '          SUM(HPD_TTM_NTI__c)                     ttmNTI, '                 ;
        query += '          SUM(HPD_NTI_12_Weeks__c)                nti12Weeks, '                 ;
        query += '          SUM(HPD_NTI_8_Weeks__c)                 nti8Weeks, '                 ;
        query += '          SUM(HPD_NTI_4_Weeks__c)                 nti4Weeks, '                 ;
        query += '          SUM(HPD_Funds_In_Total_12_weeks__c)     fundsInTotal12Weeks, '      ;
        query += '          SUM(HPD_Funds_In_Total_8_weeks__c)      fundsInTotal8Weeks, '       ;
        query += '          SUM(HPD_Funds_In_Total_4_weeks__c)      fundsInTotal4Weeks, '       ;
        query += '          SUM(HPD_Funds_Out_Total_12_weeks__c)    fundsOutTotal12Weeks, '    ;
        query += '          SUM(HPD_Funds_Out_Total_8_weeks__c)     fundsOutTotal8Weeks, '     ;
        query += '          SUM(HPD_Funds_Out_Total_4_weeks__c)     fundsOutTotal4Weeks, '     ;
        query += '          SUM(HPD_Revenue_Total_12_weeks__c)      revTotal12Weeks, '         ;
        query += '          SUM(HPD_Revenue_Total_8_weeks__c)       revTotal8Weeks, '          ;
        query += '          SUM(HPD_Revenue_Total_4_weeks__c)       revTotal4Weeks, '          ;
        query += '          SUM(HPD_Amount_Played_12_weeks__c)      amountPlayed12Weeks, '     ;
        query += '          SUM(HPD_Amount_Played_8_weeks__c)       amountPlayed8Weeks, '     ;
        query += '          SUM(HPD_Amount_Played_4_weeks__c)       amountPlayed4Weeks, '     ;
        query += '          SUM(HPD_Amount_Won_12_weeks__c)         amountWon12Weeks, '     ;
        query += '          SUM(HPD_Amount_Won_8_weeks__c)          amountWon8Weeks, '     ;
        query += '          SUM(HPD_Amount_Won_4_weeks__c)          amountWon4Weeks, '     ;
        query += '          COUNT(Id)                               recordCount ' ;
        query += 'FROM      Hold_Per_Day_Total__c ' ;
        query += 'WHERE     Municipality__c                         in  :muniIds ' ;
        query += 'and       RecordType.Name                         =   :rtName ' ;
        query += 'and       Frequency__c                            =   :frequency ' ;
        if(locType == 'Accel Account') {
            query += ' and  Location_Type__c = :locType';
        }
        query += ' GROUP BY  Municipality__c ' ;
        system.debug(query);
        results = Database.query(query);

        //@TODO try / catch
        return results;
    }
    //===================================== @TODO refactor the below (community stuff for now) =========================================
    //--------------- THIS WAS DONE IN A VERY VERY RUSHED FASHION FOR DEMO PURPOSES AND SHOULD BE REDONE!
    /**
     *
     *
     * @param accountId
     * @param assetIds
     * @param rtName
     * @param startDate
     * @param endDate
     *
     * @return
     */
   public static List<HpdWrapper> retrieveHpdAssetRevenueResults(Id accountId, Set<Id> assetIds, String rtName,
            Date startDate, Date endDate, Decimal defaultTaxRate, Decimal defaultAdminFeeRate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<AggregateResult> ars = retrieveHpdAssetAggregateResults(new Set<Id>{accountId},assetIds,rtName,startDate,endDate);
        if(!ars.isEmpty()) {
            system.debug('running hpd build wrappers for asset rev results of size.. '+ars.size());
            hpdWrappers = buildHpdWrappers(ars,defaultTaxRate,defaultAdminFeeRate);
            system.debug('hpdWrappers='+hpdWrappers);
        }
        return hpdWrappers;
    }
    public static List<HpdWrapper> retrieveHpdAssetDailyResults(Id accountId, Set<Id> assetIds, String rtName,
            Date startDate, Date endDate, Decimal defaultTaxRate, Decimal defaultAdminFeeRate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<Hold_Per_Day__c> holdPerDays = retrieveHpdAssetResults(accountId,assetIds,rtName,startDate,endDate);
        if(!holdPerDays.isEmpty()) {
            hpdWrappers = buildHpdDailyWrappers(holdPerDays,defaultTaxRate,defaultAdminFeeRate);
        }
        return hpdWrappers;
    }
    public static List<HpdWrapper> retrieveHpdAssetMonthlyResults(Set<Id> accountIds, Set<Id> assetIds, String rtName,
            Date startDate, Date endDate, Decimal defaultTaxRate, Decimal defaultAdminFeeRate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<AggregateResult> ars = retrieveHpdAssetAggregateByMonthlyResults(accountIds,assetIds,rtName,startDate,endDate);
        if(!ars.isEmpty()) {
            hpdWrappers = buildHpdWrappers(ars,defaultTaxRate,defaultAdminFeeRate);
        }
        return hpdWrappers;
    }
    public static List<HpdWrapper> retrieveHpdAccountLifetimeResults(Set<Id> accountIds,  String rtName,
            Date startDate, Date endDate, Decimal defaultTaxRate, Decimal defaultAdminFeeRate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<AggregateResult> ars = retrieveHpdAccountAggregateByLifeTimeResults(accountIds,rtName,startDate,endDate);
        if(!ars.isEmpty()) {
            hpdWrappers = buildMonthlyWrappers(ars);
        }
        return hpdWrappers;
    }
    public static List<HpdWrapper> retrieveHpdAllAccountsBySingleMonthlyResults(Set<Id> accountIds,  String rtName, Date monthDate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<AggregateResult> ars =  retrieveHpdAllAccountAggregateBySingleMonthResults(accountIds,rtName,monthDate);
        if(!ars.isEmpty()) {
            hpdWrappers = buildAccountMonthlyHpdWrappers(ars);
        }
        return hpdWrappers;
    }
    public static List<HpdWrapper> retrieveHpdAllAccountsByAllMonthResults(Set<Id> accountIds,  String rtName, Date startDate, Date endDate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<AggregateResult> ars =  retrieveHpdAllAccountAggregateByAllMonthResults(accountIds,rtName,startDate,endDate);
        if(!ars.isEmpty()) {
            hpdWrappers = buildAccountMonthlyHpdWrappers(ars);
        }
        return hpdWrappers;
    }
    public static List<HpdWrapper> retrieveHpdAllAccountsMonthlyResults(Set<Id> accountIds,  String rtName,
            Date startDate, Date endDate) {

        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        List<AggregateResult> ars =  retrieveHpdAllLocationsAggregateByMonthlyResults(accountIds,rtName,startDate,endDate);
        if(!ars.isEmpty()) {
            hpdWrappers = buildMonthlyWrappers(ars);
        }
        return hpdWrappers;
    }
    /**
   *
   *
   *
   * @param accountId
   * @param assetIds
   * @param rtName
   * @param startDate
   * @param endDate
   *
   * @return
   */
    public static List<Hold_Per_Day__c> retrieveHpdAssetResults(Id accountId, Set<Id> assetIds, String rtName,
            Date startDate, Date endDate) {

        List<Hold_Per_Day__c> holdPerDays = [
                SELECT  asset__c,
                        id,
                        name,
                        account__r.name,
                        account__r.shippingCity,
                        account__r.shippingStreet,
                        account__r.igb_license__C,
                        asset__r.name,
                        asset__r.model__c,
                        asset__r.SAS__c,
                        account__c,
                        Position__c,
                        Date__c,
                        Amount_Played__c,
                        Amount_Won__c,
                        Net_Revenue__c,
                        Funds_In__c,
                        Funds_Out__c,
                        Net_Funds__c,
                        NTI_Tax_Rate_30__c,
                        Location_Share__c,
                        State_Share__c
                FROM    Hold_Per_Day__c
                Where   asset__c        in :assetIds
                and     account__c      =   :accountId
                and     Date__c         >=  :startDate
                and     Date__c         <=  :endDate
                and     RecordType.Name =   :rtName
                ORDER BY Date__c DESC
        ];
        return holdPerDays;
    }
    /**
    *
    *
    *
    * @param accountId
    * @param assetIds
    * @param rtName
    * @param startDate
    * @param endDate
    *
    * @return
    */
    public static List<AggregateResult> retrieveHpdAssetAggregateResults(Set<Id> accountIds, Set<Id> assetIds, String rtName,
            Date startDate, Date endDate) {

        List<AggregateResult> ars = [
                SELECT  asset__c,
                        MAX( id )                       hpdId,
                        MAX( date__c)                   hpdDate,
                        MAX( name )                     hpdName,
                        MAX( account__r.name)           accountName,
                        MAX( account__r.igb_license__C) license,
                        MAX( asset__r.name )            assetName,
                        MAX( asset__r.SAS__c )          assetPosition,
                        MAX( account__r.shippingstreet) accountPhysicalStreet,
                        MAX( account__r.shippingcity)   accountPhysicalCity,
                        MAX( asset__r.model__c )        model,
                        MAX( Position__c )              position,
                        SUM( Amount_Played__c )         amtPlayed,
                        SUM( Amount_Won__c )            amtWon,
                        SUM( Net_Revenue__c )           netRevenue,
                        SUM( Funds_In__c )              fundsIn,
                        SUM( Funds_Out__c )             fundsOut,
                        SUM( Net_Funds__c )             netFunds,
                        MAX( NTI_Tax_Rate_30__c )       taxRate,
                        SUM( State_Share__c )           stateShare,
                        COUNT( Id )                     recordCount
                FROM    Hold_Per_Day__c
                Where   asset__c        in  :assetIds
                and     account__c      in  :accountIds
                and     Date__c         >=  :startDate
                and     Date__c         <=  :endDate
                and     RecordType.Name =   :rtName
                GROUP BY asset__c
        ];
        return ars;
    }
    /**
    *
    *
    *
    * @param accountId
    * @param assetIds
    * @param rtName
    * @param startDate
    * @param endDate
    *
    * @return
    */
    public static List<AggregateResult> retrieveHpdAssetAggregateByMonthlyResults(Set<Id> accountIds, Set<Id> assetIds, String rtName,
            Date startDate, Date endDate) {
        List<AggregateResult> ars = [
                SELECT  asset__c,
                        MAX( date__c )                  hpdDate,
                        CALENDAR_YEAR(date__c)          hpdYear,
                        CALENDAR_MONTH(date__c)         hpdMonth,
                        MAX( id )                       hpdId,
                        MAX( name )                     hpdName,
                        MAX( account__c)                accountId,
                        MAX( account__r.name)           accountName,
                        MAX( account__r.shippingstreet) accountPhysicalStreet,
                        MAX( account__r.shippingcity)   accountPhysicalCity,
                        MAX( account__r.igb_license__C) license,
                        MAX( asset__r.name )            assetName,
                        MAX( asset__r.model__c )        model,
                        MAX( asset__r.SAS__c )          assetPosition,
                        MAX( Position__c )              position,
                        SUM( Amount_Played__c )         amtPlayed,
                        SUM( Amount_Won__c )            amtWon,
                        SUM( Net_Revenue__c )           netRevenue,
                        SUM( Funds_In__c )              fundsIn,
                        SUM( Funds_Out__c )             fundsOut,
                        SUM( Net_Funds__c )             netFunds,
                        MAX( NTI_Tax_Rate_30__c )       taxRate,
                        SUM( State_Share__c )           stateShare,
                        COUNT( Id )                     recordCount
                FROM    Hold_Per_Day__c
                Where   asset__c        in :assetIds
                and     account__c      in  :accountIds
                and     Date__c         >=  :startDate
                and     Date__c         <=  :endDate
                and     RecordType.Name =   :rtName
                GROUP BY asset__c,CALENDAR_YEAR(date__c), CALENDAR_MONTH(date__c)
                ORDER BY asset__c,CALENDAR_YEAR(date__c) DESC, CALENDAR_MONTH(date__c) DESC
        ];
        return ars;
    }
    public static List<AggregateResult> retrieveHpdAllAccountAggregateBySingleMonthResults(Set<Id> accountIds, String rtName, Date monthDate) {
        Integer iCalMonth = monthDate.month();
        Integer iCalYear  = monthDate.year();
        List<AggregateResult> ars = [
                SELECT  account__c,
                        MAX( date__c )                  hpdDate,
                        MAX( id )                       hpdId,
                        MAX( name )                     hpdName,
                        MAX( account__r.igb_license__C) license,
                        MAX( account__r.name)           accountName,
                        MAX( account__r.shippingstreet) accountPhysicalStreet,
                        MAX( account__r.shippingcity)   accountPhysicalCity,
                        MAX( asset__r.name )            assetName,
                        MAX( asset__r.model__c )        model,
                        MAX( asset__r.SAS__c )          assetPosition,
                        MAX( Position__c )              position,
                        SUM( Amount_Played__c )         amtPlayed,
                        SUM( Amount_Won__c )            amtWon,
                        SUM( Net_Revenue__c )           netRevenue,
                        SUM( Funds_In__c )              fundsIn,
                        SUM( Funds_Out__c )             fundsOut,
                        SUM( Net_Funds__c )             netFunds,
                        MAX( NTI_Tax_Rate_30__c )       taxRate,
                        SUM( State_Share__c )           stateShare,
                        SUM( Location_Share__c)         locShare,
                        COUNT( Id )                     recordCount
                FROM    Hold_Per_Day__c
                Where   account__c      in  :accountIds
                and     CALENDAR_MONTH(Date__c)  =  :iCalMonth
                and     CALENDAR_YEAR(Date__c)  =  :iCalYear
                and     RecordType.Name =   :rtName
                GROUP BY account__c
                ORDER BY account__c ASC
        ];
        return ars;
    }

    public static List<AggregateResult> retrieveHpdAllAccountAggregateByAllMonthResults(Set<Id> accountIds, String rtName, Date startDate, Date endDate) {
       // Integer iCalMonth = monthDate.month();
       // Integer iCalYear  = monthDate.year();
        List<AggregateResult> ars = [
                SELECT  account__c,
                        MAX( date__c )                  hpdDate,
                        MAX( id )                       hpdId,
                        MAX( name )                     hpdName,
                        MAX( account__r.igb_license__C) license,
                        MAX( account__r.name)           accountName,
                        MAX( account__r.shippingstreet) accountPhysicalStreet,
                        MAX( account__r.shippingcity)   accountPhysicalCity,
                        MAX( asset__r.name )            assetName,
                        MAX( asset__r.model__c )        model,
                        MAX( asset__r.SAS__c )          assetPosition,
                        MAX( Position__c )              position,
                        SUM( Amount_Played__c )         amtPlayed,
                        SUM( Amount_Won__c )            amtWon,
                        SUM( Net_Revenue__c )           netRevenue,
                        SUM( Funds_In__c )              fundsIn,
                        SUM( Funds_Out__c )             fundsOut,
                        SUM( Net_Funds__c )             netFunds,
                        MAX( NTI_Tax_Rate_30__c )       taxRate,
                        SUM( State_Share__c )           stateShare,
                        SUM( Location_Share__c)         locShare,
                        COUNT( Id )                     recordCount
                FROM    Hold_Per_Day__c
                Where   account__c      in  :accountIds
                and     RecordType.Name =   :rtName
                GROUP BY account__c, CALENDAR_YEAR(date__c), CALENDAR_MONTH(date__c)
                ORDER BY account__c, CALENDAR_YEAR(date__c) DESC, CALENDAR_MONTH(date__c) DESC
        ];
        return ars;
    }
    public static List<AggregateResult> retrieveHpdAccountAggregateByLifeTimeResults(Set<Id> accountIds, String rtName,
            Date startDate, Date endDate) {

        List<AggregateResult> ars = [
                SELECT  account__c,
                        MAX( account__r.name)           accountName,
                        MAX( account__r.shippingstreet) accountPhysicalStreet,
                        MAX( account__r.shippingcity)   accountPhysicalCity,
                        MAX( date__c )                  hpdDate,
                        MAX( id )                       hpdId,
                        MAX( name )                     hpdName,
                        MAX( account__r.igb_license__C) license,
                        SUM( Amount_Played__c )         amtPlayed,
                        SUM( Amount_Won__c )            amtWon,
                        SUM( Net_Revenue__c )           netRevenue,
                        SUM( Funds_In__c )              fundsIn,
                        SUM( Funds_Out__c )             fundsOut,
                        SUM( Net_Funds__c )             netFunds,
                        MAX( NTI_Tax_Rate_30__c )       taxRate,
                        SUM( State_Share__c )           stateShare,
                        SUM( Location_Share__c)         locShare,
                        COUNT( Id )                     recordCount
                FROM    Hold_Per_Day__c
                Where   account__c      in  :accountIds
                and     Date__c         >=  :startDate
                and     Date__c         <=  :endDate
                and     RecordType.Name =   :rtName
                GROUP BY account__c
                ORDER BY account__c DESC

        ];
        return ars;
    }

    public static List<AggregateResult> retrieveHpdAllLocationsAggregateByMonthlyResults(Set<Id> accountIds, String rtName,
                    Date startDate, Date endDate) {

        List<AggregateResult> ars = [
                SELECT  MAX(date__c)                    hpdDate,
                        CALENDAR_YEAR(date__c)          hpdYear,
                        CALENDAR_MONTH(date__c)         hpdMonth,
                        SUM( Location_Share__c )        locShare,
                        SUM( Amount_Played__c )         amtPlayed,
                        SUM( Amount_Won__c )            amtWon,
                        SUM( Net_Revenue__c )           netRevenue,
                        SUM( Funds_In__c )              fundsIn,
                        SUM( Funds_Out__c )             fundsOut,
                        SUM( Net_Funds__c )             netFunds,
                        MAX( NTI_Tax_Rate_30__c )       taxRate,
                        SUM( State_Share__c )           stateShare,
                        COUNT( Id )                     recordCount
                FROM    Hold_Per_Day__c
                Where   account__c      in  :accountIds
                and     Date__c         >=  :startDate
                and     Date__c         <=  :endDate
                and     RecordType.Name =   :rtName
                GROUP BY CALENDAR_YEAR(date__c), CALENDAR_MONTH(date__c)
                ORDER BY CALENDAR_YEAR(date__c) DESC, CALENDAR_MONTH(date__c) DESC
        ];
        return ars;
    }
    @testvisible
    private Static List<HpdWrapper> buildHpdWrappers(List<AggregateResult> ars, Decimal defaultTaxRate, Decimal defaultAdminFeeRate) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();


        for(AggregateResult ar : ars) {

                HpdWrapper hpdWrapper = new HpdWrapper();
                hpdWrapper.hpdId = (Id) ar.get('hpdId');
                hpdWrapper.hpdName = (String) ar.get('hpdName');
            try { //@TODO Cleanup
                hpdWrapper.assetId = (Id) ar.get('asset__c');
            } catch (SObjectException ex) {
                system.debug(ex);
            }
            hpdWrapper.sasPosition = (Decimal) ar.get('position');
            try {
                hpdWrapper.hpdYear = (Integer) ar.get('hpdYear');
                hpdWrapper.hpdMonth = (Integer) ar.get('hpdMonth');
            } catch (SObjectException ex) {
                system.debug(ex);
            }
            if(hpdWrapper.sasPosition == null || hpdWrapper.sasPosition == 0) {
                String sSas = (String) ar.get('assetPosition');
                if(sSas != null && sSas != '') {
                    hpdWrapper.sasPosition = Decimal.valueOf(sSas);
                }
            }
            hpdWrapper.vgtUid = (String) ar.get('model');
            hpdWrapper.amtPlayed = (Decimal) ar.get('amtPlayed');
            hpdWrapper.amtWon = (Decimal) ar.get('amtWon');
            hpdWrapper.netRevenue = (Decimal) ar.get('netRevenue');
            hpdWrapper.fundsIn = (Decimal) ar.get('fundsIn');
            hpdWrapper.fundsOut = (Decimal) ar.get('fundsOut');
            hpdWrapper.netFunds = (Decimal) ar.get('netFunds');
            hpdWrapper.taxRate = (Decimal) ar.get('taxRate');
            hpdWrapper.hpdDate = (Date) ar.get('hpdDate');
            hpdWrapper.accountName = (String) ar.get('accountName');
            hpdWrapper.accountPhysicalStreet = (String) ar.get('accountPhysicalStreet');
            hpdWrapper.accountPhysicalCity = (String) ar.get('accountPhysicalCity');
            try { //@TODO Cleanup
                hpdWrapper.accountId =  (Id) ar.get('account__c');

                if (ar.get('hpdYear') != null) {
                    hpdWrapper.hpdYear = (Integer) ar.get('hpdYear');
                }
                if (ar.get('hpdMonth') != null) {
                    hpdWrapper.hpdMonth = (Integer) ar.get('hpdMonth');
                }
            } catch (SObjectException ex) {
                system.debug(ex);
            }

            if(hpdWrapper.taxRate == null)   {hpdWrapper.taxRate = defaultTaxRate;}
            hpdWrapper.stateShare = (Decimal) ar.get('stateShare');
            if(hpdWrapper.stateShare == null)   {
                hpdWrapper.stateShare = hpdWrapper.netFunds * (hpdWrapper.taxRate / 100 );
                hpdWrapper.stateShare = hpdWrapper.stateShare.setScale(2, RoundingMode.UP);
            }
            hpdWrapper.adminFeeRate = defaultAdminFeeRate;
            hpdWrapper.adminShare = hpdWrapper.netFunds * ( hpdWrapper.adminFeeRate / 100 );
            hpdWrapper.adminShare = hpdWrapper.adminShare.setScale(2, RoundingMode.UP);
            hpdWrapper.totalBill = hpdWrapper.stateShare + hpdWrapper.adminShare;

            hpdWrappers.add(hpdWrapper);
        }
        return hpdWrappers;
    }
    @testvisible
    private Static List<HpdWrapper> buildHpdDailyWrappers(List<Hold_Per_Day__c> holdPerDays, Decimal defaultTaxRate, Decimal defaultAdminFeeRate) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();
        for(Hold_Per_Day__c hpd : holdPerDays) {

            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.hpdId = hpd.id;
            hpdWrapper.hpdDate = hpd.date__c;
            hpdWrapper.hpdName = hpd.name;
            hpdWrapper.assetId = hpd.asset__c;
            hpdWrapper.sasPosition = hpd.Position__c;
            if(hpdWrapper.sasPosition == null) {
                String sSas = hpd.asset__r.SAS__C;
                if(sSas != null && sSas != '') {
                    hpdWrapper.sasPosition = Decimal.valueOf(sSas);
                }
            }
            hpdWrapper.accountName = hpd.account__r.name;
            hpdWrapper.accountPhysicalStreet = hpd.account__r.shippingstreet;
            hpdWrapper.hpdDate = hpd.date__c;
            hpdWrapper.vgtUid = hpd.asset__r.model__c;
            hpdWrapper.amtPlayed = hpd.Amount_Played__c;
            hpdWrapper.amtWon = hpd.Amount_Won__c;
            hpdWrapper.netRevenue = hpd.Net_Revenue__c;
            hpdWrapper.fundsIn = hpd.Funds_In__c;
            hpdWrapper.fundsOut = hpd.Funds_Out__c;
            hpdWrapper.netFunds = hpd.Net_Funds__c;
            hpdWrapper.taxRate = hpd.NTI_Tax_Rate_30__c;
            if(hpdWrapper.taxRate == null)   {hpdWrapper.taxRate = defaultTaxRate;}
            hpdWrapper.stateShare = hpd.State_Share__c;
            if(hpdWrapper.stateShare == null)   {
                hpdWrapper.stateShare = hpdWrapper.netFunds * (hpdWrapper.taxRate / 100 );
                hpdWrapper.stateShare = hpdWrapper.stateShare.setScale(2, RoundingMode.UP);
            }
            hpdWrapper.adminFeeRate = defaultAdminFeeRate;
            hpdWrapper.adminShare = hpdWrapper.netFunds * ( hpdWrapper.adminFeeRate / 100 );
            hpdWrapper.adminShare = hpdWrapper.adminShare.setScale(2, RoundingMode.UP);
            hpdWrapper.totalBill = hpdWrapper.stateShare + hpdWrapper.adminShare;
            try { //@TODO Cleanup
                hpdWrapper.locShare =  hpd.Location_Share__c;
            } catch (SObjectException ex) {
                system.debug(ex);
            }

            hpdWrappers.add(hpdWrapper);
        }
        return hpdWrappers;
    }

    @testvisible
    private Static List<HpdWrapper> buildMonthlyWrappers(List<AggregateResult> ars) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();

        for(AggregateResult ar : ars) {

            HpdWrapper hpdWrapper = new HpdWrapper();

            hpdWrapper.hpdDate = (Date) ar.get('hpdDate');
            try { //@TODO Cleanup
                hpdWrapper.hpdYear = (Integer) ar.get('hpdYear');
                hpdWrapper.hpdMonth = (Integer) ar.get('hpdMonth');
            } catch (SObjectException ex) {
                system.debug(ex);
            }
            try { //@TODO Cleanup
                hpdWrapper.accountId = (Id) ar.get('accountId');
            } catch (SObjectException ex) {
                system.debug(ex);
            }
            try { //@TODO Cleanup
                hpdWrapper.accountId = (Id) ar.get('account__c');
                hpdWrapper.accountName = (String) ar.get('accountName');
                hpdWrapper.accountPhysicalStreet = (String) ar.get('accountPhysicalStreet');
            } catch (SObjectException ex) {
                system.debug(ex);
            }
            hpdWrapper.amtPlayed = (Decimal) ar.get('amtPlayed');
            hpdWrapper.amtWon = (Decimal) ar.get('amtWon');
            hpdWrapper.netRevenue = (Decimal) ar.get('netRevenue');
            hpdWrapper.fundsIn = (Decimal) ar.get('fundsIn');
            hpdWrapper.fundsOut = (Decimal) ar.get('fundsOut');
            hpdWrapper.netFunds = (Decimal) ar.get('netFunds');
            hpdWrapper.locShare = (Decimal) ar.get('locShare');





            hpdWrappers.add(hpdWrapper);
        }
        return hpdWrappers;
    }

    @testvisible
    private Static List<HpdWrapper> buildAccountMonthlyHpdWrappers(List<AggregateResult> ars) {
        List<HpdWrapper> hpdWrappers = new List<HpdWrapper>();

        for(AggregateResult ar : ars) {

            HpdWrapper hpdWrapper = new HpdWrapper();
            hpdWrapper.accountId = (Id) ar.get('account__c');
            hpdWrapper.accountPhysicalStreet = (String) ar.get('accountPhysicalStreet');
            hpdWrapper.accountPhysicalCity = (String) ar.get('accountPhysicalCity');
            hpdWrapper.accountName = (String) ar.get('accountName');
            hpdWrapper.hpdDate = (Date) ar.get('hpdDate');
            hpdWrapper.amtPlayed = (Decimal) ar.get('amtPlayed');
            hpdWrapper.amtWon = (Decimal) ar.get('amtWon');
            hpdWrapper.netRevenue = (Decimal) ar.get('netRevenue');
            hpdWrapper.fundsIn = (Decimal) ar.get('fundsIn');
            hpdWrapper.fundsOut = (Decimal) ar.get('fundsOut');
            hpdWrapper.netFunds = (Decimal) ar.get('netFunds');
            hpdWrapper.locShare = (Decimal) ar.get('locShare');
            hpdWrappers.add(hpdWrapper);
        }
        return hpdWrappers;
    }
}