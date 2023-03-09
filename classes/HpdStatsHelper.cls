public class HpdStatsHelper {

    public static HPD_Total_Setting__mdt hpdTotalMunicipalitySetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.MUNICIPALITY_AGGREGATION_DEVNAME);
    public static HPD_Total_Setting__mdt hpdTotalAccountSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME);

//    /**
//     *
//     * @param mHpdStatsByMuniIds - a map of Municipality Ids => HpdStats objects.
//     * @return a list of Hold Per Day Totals.
//     */
//    public static List<Hold_Per_Day_Total__c> buildMuniHoldPerDayTotals(Map<Id, HpdStats> mHpdStatsByMuniIds, String frequency) {
//        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
//        Map<Id, Hold_Per_Day_Total__c> mholdPerDayTotalsByIds = new Map<Id, Hold_Per_Day_Total__c>([
//                SELECT id, recordtypeid, account__c, HPD_TTM_Revenue_Total__c,HPD_TTM_Daily_Total__c,frequency__c,municipality__c,hpd_total_vgt_count__c,
//                        HPD_Revenue_Total_12_Weeks__c,HPD_Municipality_Accel_Revenue_Total_12__c,HPD_Municipality_Accel_Total_VGT_Count__c,
//                        HPD_Revenue_Total_4_Weeks__c,HPD_Revenue_Total_8_Weeks__c,HPD_Funds_In_Total_4_Weeks__c,HPD_Funds_In_Total_8_Weeks__c,
//                        HPD_Municipality_Funds_Out_Total_4_Weeks__c,HPD_Municipality_Funds_Out_Total_8_Weeks__c, HPD_Municipality_Funds_Out_Total_12weeks__c
//                FROM Hold_Per_Day_Total__c
//                WHERE municipality__c in :mHpdStatsByMuniIds.keySet()
//                and  recordtype.name = 'Municipality'
//                and  Frequency__c = :frequency
//                FOR UPDATE
//        ]);
//        Map<Id, Hold_Per_Day_Total__c> mholdPerDayTotalsByMuniIds = new Map<Id, Hold_Per_Day_Total__c>();
//        for (Hold_Per_Day_Total__c holdPerDayTotal : mholdPerDayTotalsByIds.values()) {
//            mholdPerDayTotalsByMuniIds.put(holdPerDayTotal.municipality__c, holdPerDayTotal);
//        }
//
//        if (!mholdPerDayTotalsByMuniIds.isEmpty()) {
//            //RecordType rt = [select id from recordtype where developername = 'Municipality' and sobjectType = 'Hold_Per_Day_Total__c'];
//            Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Municipality').getRecordTypeId();
//            for (Id muniId : mHpdStatsByMuniIds.keySet()) {
//                HpdStats hpdStats = (HpdStats) mHpdStatsByMuniIds.get(muniId);
//                Hold_Per_Day_Total__c holdPerDayTotal = mholdPerDayTotalsByMuniIds.get(muniId);
//                if (holdPerDayTotal != null) {
//                    holdPerDayTotal.account__c = null;
//                    holdPerDayTotal.HPD_TTM_Revenue_Total__c = hpdStats.ttm_totalNetFunds;
//                    holdPerDayTotal.HPD_Total_Vgt_Count__C = hpdStats.ttm_totalVgts;
//
//                    holdPerDayTotal.HPD_Revenue_Total_12_Weeks__c = hpdStats.totalNetFunds12Weeks;
//                    holdPerDayTotal.HPD_Municipality_Funds_In_Total__c = hpdStats.totalFundsIn12Weeks;
//                    holdPerDayTotal.HPD_Municipality_Accel_Revenue_Total_12__c = hpdStats.totalAccelRev12Weeks;
//
//                    holdPerDayTotal.HPD_Municipality_Revenue_Total_4_Weeks__c = hpdStats.totalAccelRev12Weeks;
//                    holdPerDayTotal.HPD_Municipality_Revenue_Total_8_Weeks__c = hpdStats.totalAccelRev8Weeks;
//
//                    holdPerDayTotal.HPD_Municipality_Funds_In_Total_8_Weeks__c = hpdStats.totalFundsIn8Weeks;
//                    holdPerDayTotal.HPD_Municipality_Funds_In_Total_4_Weeks__c  = hpdStats.totalFundsIn4weeks;
//
//                    holdPerDayTotal.HPD_Municipality_Funds_Out_Total_4_Weeks__c = hpdStats.totalFundsOut4Weeks;
//                    holdPerDayTotal.HPD_Municipality_Funds_Out_Total_8_Weeks__c = hpdStats.totalFundsOut8Weeks;
//                    holdPerDayTotal.HPD_Municipality_Funds_Out_Total_12Weeks__c = hpdStats.totalFundsOut12Weeks;
//                    // holdPerDayT
//                    //holdPerDayTotal.HPD`
//
//                    holdPerDayTotal.Municipality__c = hpdStats.muniId;
//                    holdPerDayTotal.recordtypeid = rtId;
//                    holdPerDayTotal.frequency__c = frequency;
//
//                    holdPerDayTotal.HPD_Municipality_Accel_Total_VGT_Count__c = hpdStats.totalAccelVgtCount;
//                    holdPerDayTotals.add(holdPerDayTotal);
//                }
//            }
//        } else {
//            system.debug(logginglevel.warn, 'build muni hold per day totals. no hpd records for provided account ids of. '+mHpdStatsByMuniIds.keySet());
//        }
//        return holdPerDayTotals;
//    }
//    public static map<Id, HpdStats> aggregateHpdStats(Set<Id>accountIds,String rtName) {
//        return null;
//    }


    /**
     * Aggregate Hold per total total (accounts) up to the municipality level
     *
     * @param muniIds
     * @return a map of muni id = > HpdStats
     */
//    public static map<Id, HpdStats> aggregateHpdMuniStats(Set<Id>muniIds, String frequency) {
//        Map<Id, HpdStats> mHpdStatsByMuniIds = new Map<Id, HpdStats>();
//        String rtDevNameToAggregate = hpdTotalMunicipalitySetting.Record_Type_Dev_Name_To_Process__c;
//        for (AggregateResult ar : [
//                SELECT Municipality__c,
//                        SUM(HPD_TTM_Funds_In_Total__c) netFundsTotal,
//                        SUM(hpd_total_vgt_count__c) vgtTotal,
//                        SUM(HPD_Funds_In_Total_12_weeks__c) fundsInTotal,
//                        SUM(HPD_Funds_In_Total_8_Weeks__c) fundsInTotal8Weeks,
//                        SUM(HPD_Funds_In_Total_4_Weeks__c) fundsInTotal4Weeks,
//                        SUM(HPD_Funds_Out_Total_4_weeks__c) fundsOutTotal4Weeks,
//                        SUM(HPD_Funds_Out_Total_8_Weeks__c) fundsOutTotal8Weeks,
//                        SUM(HPD_Funds_Out_Total_12_Weeks__c) fundsOutTotal12Weeks,
//                        SUM(HPD_Accel_Revenue_Total_12_Weeks__C) accelRevenueTotal,
//                        SUM(HPD_Accel_Total_VGT_Count__c) accelVgtTotal,
//                        SUM(HPD_Revenue_Total_12_Weeks__c) revenueTotal,
//                        SUM(HPD_Revenue_Total_8_Weeks__c) revTotal8Weeks,
//                        SUM(HPD_Revenue_Total_4_Weeks__c) revTotal4Weeks
//                FROM Hold_Per_Day_Total__c
//                WHERE Municipality__c in :muniIds
//                AND RecordType.DeveloperName = :rtDevNameToAggregate
//                AND Frequency__c = :frequency
//                GROUP BY Municipality__c
//        ]) {
//            HpdStats hpdStats = new HpdStats();
//            if (ar.get('netFundsTotal') != null) {
//                hpdStats.ttm_totalNetFunds = (Decimal) ar.get('netFundsTotal');
//                hpdStats.muniId = (Id) ar.get('Municipality__c');
//                hpdStats.ttm_totalVgts = Integer.valueOf((Decimal) ar.get('vgtTotal'));
//                hpdStats.totalNetFunds12Weeks = (Decimal) ar.get('revenueTotal');
//                hpdStats.totalFundsIn12Weeks = (Decimal) ar.get('fundsInTotal');
//                hpdStats.totalAccelRev12Weeks = (Decimal) ar.geT('accelRevenueTotal');
//                hpdStats.totalAccelVgtCount = Integer.valueOf((Decimal) ar.get('accelVgtTotal'));
//                hpdStats.totalAccelRev8Weeks = (Decimal) ar.get('revTotal8Weeks');
//                hpdStats.totalAccelRev4Weeks = (Decimal) ar.get('revTotal4Weeks');
//                hpdStats.totalFundsIn8Weeks = (Decimal) ar.get('fundsInTotal8Weeks');
//                hpdStats.totalFundsIn4Weeks = (Decimal) ar.get('fundsInTotal4Weeks');
//
//                hpdStats.totalFundsOut12Weeks = (Decimal) ar.get('fundsOutTotal12Weeks');
//                hpdStats.totalFundsOut8Weeks = (Decimal) ar.get('fundsOutTotal8Weeks');
//                hpdStats.totalFundsOut4Weeks = (Decimal) ar.get('fundsOutTotal4Weeks');
//            }
//            mHpdStatsByMuniIds.put((Id) ar.get('Municipality__c'), hpdStats);
//        }
//        //---------------
//        return mHpdStatsByMuniIds;
//    }

    /**
     * Primarily used for Unit Test Code but can be used if we want to clear out hpd totals and start over.
     * Note one should delete all rows in existing hpd totals table first before using this!
     * for live data this may need to be run twice in order to skip around gov limits as it does check flags on the
     * records.
     */
    public static void reInitHpdTotals() {
        Map<String,Object> mKeyObject = HpdStatsHelper.initHpdAccountTotalRecs(null);
        List<Account> accounts = (List<Account>)mKeyObject.get('ACCOUNTS');
        system.assert(!accounts.isEmpty());
        List<Hold_Per_Day_Total__c> hpds = (List<Hold_Per_Day_Total__c>)mKeyObject.get('HPD_TOTALS');
        system.debug('--- # of hpd totals inserted for accounts:'+hpds.size());
        List<Account> monthlyAccountsUpdated = HpdStatsHelper.linkAccountsWithHdp(accounts,'Monthly');
        system.assert(!monthlyAccountsUpdated.isEmpty());
        system.debug('--- # of accounts linked for monthly:'+monthlyAccountsUpdated.size());
        //List<Account> dailyAccountsUpdated = HpdStatsHelper.linkAccountsWithHdp(accounts,'Daily');
        //system.debug('--- # of accounts linked for daily:'+monthlyAccountsUpdated.size());
        //system.assert(!dailyAccountsUpdated.isEmpty());

        mKeyObject = HpdStatsHelper.initHpdAssetTotalRecs(null);
        List<Asset> assets = (List<Asset>)mKeyObject.get('ASSETS');
        //system.assert(!assets.isEmpty());
        hpds = (List<Hold_Per_Day_Total__c>)mKeyObject.get('HPD_TOTALS');
        system.debug('--- # of hpd totals inserted for assets:'+hpds.size());
        List<Asset> assetsUpdated = HpdStatsHelper.linkAssetsWithHdp(assets);
        //system.assert(!assetsUpdated.isEmpty());
        system.debug('--- # of assets linked:'+assetsUpdated.size());

        mKeyObject = HpdStatsHelper.initHpdMunicipalityTotalRecs(null);
        List<Municipality__c> munis  = (List<Municipality__c>)mKeyObject.get('MUNIS');
        system.assert(!munis.isEmpty());
        hpds = (List<Hold_Per_Day_Total__c>)mKeyObject.get('HPD_TOTALS');
        system.debug('--- # of hpd totals inserted for munis:'+hpds.size());
        List<Municipality__c> monthlyMunisUpdated = HpdStatsHelper.linkMunicipalityWithHpd(munis,'Monthly');
        system.assert(!monthlyMunisUpdated.isEmpty());
        system.debug('--- # of munis linked for monthly:'+monthlyMunisUpdated.size());
       // List<Municipality__c> dailyMunisUpdated = HpdStatsHelper.linkMunicipalityWithHpd(munis,'Daily');
       // system.assert(!dailyMunisUpdated.isEmpty());
        //system.debug('--- # of munis linked for daily:'+dailyMunisUpdated.size());
    }
    /**
     *
     * Inits Daily and Monthly hpd total locations (account recs)
     * @return
     * @see BatchHpdInitAccountRecs
     */
    public static Map<String,Object> initHpdAccountTotalRecs(List<Account> accounts) {
        Integer iNumHpdtsDailyInserted = 0;
        Integer iNumHpdtsMonthlyInserted = 0;
        if(accounts == null) {
            //coming from Unit test code or some non batch code.
            accounts = [
                    select id, municipalitylookup__c,type,Most_Recent_Hold_Per_Day__c
                    from Account
                    where (type = 'Accel Account' or type = 'Competitor Account' or type = 'Discontinued Account' or type = 'Other')
                    limit 200
            ];
        }
        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
        for (Account account : accounts) {
            Hold_Per_Day_Total__c hpds = new Hold_Per_Day_Total__c();
            hpds.account__c = account.id;
            hpds.municipality__c = account.MunicipalityLookup__c;
            hpds.recordtypeid = rtId;
            hpds.frequency__c = 'Monthly';
            hpds.Most_Recent_HPD__c = account.Most_Recent_Hold_Per_Day__c;
            iNumHpdtsMonthlyInserted ++;

//            Hold_Per_Day_Total__c hpdsDaily = new Hold_Per_Day_Total__c();
//            hpdsDaily.account__c = account.id;
//            hpdsDaily.municipality__c = account.MunicipalityLookup__c;
//            hpdsDaily.recordtypeid = rtId;
//            hpdsDaily.frequency__c = 'Daily';
//            hpdsDaily.Most_Recent_HPD__c = account.Most_Recent_Hold_Per_Day__c;
//            iNumHpdtsDailyInserted ++;

            holdPerDayTotals.add(hpds);
        //    holdPerDayTotals.add(hpdsDaily);
        }
        insert holdPerDayTotals;
        system.debug('------ inserted ' +holdPerDayTotals.size() + ' hpd total records');

        Map<String,Object> m  = new Map<String,Object>();
        m.put('HPD_TOTALS',holdPerDayTotals);
        m.put('ACCOUNTS',accounts);
        m.put('NUM_MONTHLY_INSERTED',iNumHpdtsMonthlyInserted);
        //m.put('NUM_DAILY_INSERTED',iNumHpdtsDailyInserted);
        return m;
    }
    /**
 *
 * Inits Daily and Monthly hpd total locations (account recs)
 * @return
 * @see BatchHpdInitAccountRecs
 */
    public static Map<String,Object> initHpdAssetTotalRecs(List<Asset> assets) {
        Integer iNumHpdtsDailyInserted = 0;
//        Set<String> excludedAcctTypes = new Set<String>{
//                'Discontinued Account'
//        };
        if(assets == null) {
            //coming from Unit test code or some non batch code.
            assets = [
                    SELECT Id, accountId, account.most_recent_hold_per_day__c
                    FROM Asset
                    WHERE recordtype.name = 'VGT'
                //    and Account.Type NOT IN :excludedAcctTypes
                    LIMIT 200
            ];
        }
        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Machine').getRecordTypeId();
        for (Asset ass : assets) {
            Hold_Per_Day_Total__c hpds = new Hold_Per_Day_Total__c();
            hpds.account__c = ass.accountId;
            hpds.asset__c = ass.Id;
            hpds.recordtypeid = rtId;
            hpds.frequency__c = 'Daily';
            hpds.Most_Recent_HPD__c = ass.account.most_recent_hold_per_day__c;
            holdPerDayTotals.add(hpds);
        }
        insert holdPerDayTotals;
        iNumHpdtsDailyInserted += holdPerDayTotals.size();

        Map<String,Object> m  = new Map<String,Object>();
        m.put('HPD_TOTALS',holdPerDayTotals);
        m.put('ASSETS',assets);
        m.put('NUM_DAILY_INSERTED',iNumHpdtsDailyInserted);
        return m;
    }
    /**
     * currently only inits monthly
     *
     * @return
     */
    public static Map<String,Object> initHpdMunicipalityTotalRecs(List<Municipality__c> munis) {
        Integer iNumHpdtsDailyInserted = 0;
        Integer iNumHpdtsMonthlyInserted = 0;

        if(munis == null) {
            munis = [select id,hold_per_day_total__c,hold_per_day_total_daily__c from Municipality__c limit 200];
        }

        Set<Id> muniIds = new Set<Id>();
        for (Municipality__c muni : munis) {
            muniIds.add(muni.id);
        }
        List<Hold_Per_Day_Total__c>holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Municipality').getRecordTypeId();
        for (Municipality__c muni : munis) {
            Hold_Per_Day_Total__c hpds = new Hold_Per_Day_Total__c();
            hpds.municipality__c = muni.id;
            hpds.recordtypeid = rtId;
            hpds.frequency__c = 'Monthly';
            holdPerDayTotals.add(hpds);
            iNumHpdtsMonthlyInserted ++;

//            Hold_Per_Day_Total__c hpdsDaily = new Hold_Per_Day_Total__c();
//            hpdsDaily.municipality__c = muni.id;
//            hpdsDaily.recordtypeid = rtId;
//            hpdsDaily.frequency__c = 'Daily';
//            holdPerDayTotals.add(hpdsDaily);
//            iNumHpdtsDailyInserted++;
        }
        insert holdPerDayTotals;
        Map<String,Object> m  = new Map<String,Object>();
        m.put('HPD_TOTALS',holdPerDayTotals);
        m.put('MUNIS',munis);
        m.put('NUM_MONTHLY_INSERTED',iNumHpdtsMonthlyInserted);
      //  m.put('NUM_DAILY_INSERTED',iNumHpdtsDailyInserted);
        return m;
    }
    /**
     *
     */
    public static List<Account> linkAccountsWithHdp(List<Account> accounts , String type) {
        Map<Id,Account> mAccountsByIds = new Map<Id,Account>();
        for(Account account : accounts) {
            mAccountsByIds.put(account.id,account);
        }
        List<Hold_Per_Day_Total__c> holdPerDayTotals = [select id, account__c
        from hold_per_day_total__c where frequency__c = :type and account__c in :mAccountsByIds.keyset()
        and recordtype.name = 'Location'];
        Map<Id, Hold_Per_Day_Total__c> mHoldPerDayTotalsByAccountIds = new Map<Id, Hold_Per_Day_Total__c>();
        for (Hold_Per_Day_Total__c hpdt : holdPerDayTotals) {
            mHoldPerDayTotalsByAccountIds.put(hpdt.account__c, hpdt);
        }
        for (Account a : accounts) {
            if(type == 'Monthly') {
                a.hold_per_day_total__c = mHoldPerDayTotalsByAccountIds.get(a.id).id;
            } else if (type == 'Daily') {
                a.hold_per_day_total_daily__c = mHoldPerDayTotalsByAccountIds.get(a.id).id;
            }
        }
        update accounts;
        return accounts;
    }
    /**
     *
     *
     * @param munis
     * @param freq
     *
     * @return
     */
    public static List<Municipality__c> linkMunicipalityWithHpd(List<Municipality__c> munis, String freq) {
        Map<Id,Municipality__c> municipalitiesByIds = new Map<Id,Municipality__c>();
        for(Municipality__c muni : munis) {
            municipalitiesByIds.put(muni.id,muni);
        }
        List<Hold_Per_Day_total__c> hpdts = [
                    select  id, municipality__c
                    from    hold_per_day_total__c
                    where   municipality__c in :municipalitiesByIds.keyset()
                                                and recordtype.name = 'Municipality'
                                                and frequency__c = :freq];
        Map<Id, Hold_Per_Day_Total__c> mHoldPerDayTotalsByMuniIds = new Map<Id, Hold_Per_Day_Total__c>();
        for (Hold_Per_Day_Total__c hpdt : hpdts) {
            mHoldPerDayTotalsByMuniIds.put(hpdt.municipality__c, hpdt);
        }
        for (Municipality__c muni : munis) {
            if(freq == 'Monthly') {
                muni.hold_per_day_total__c = mHoldPerDayTotalsByMuniIds.get(muni.id).id;
            } else if (freq == 'Daily') {
               // muni.hold_per_day_total_daily__c = mHoldPerDayTotalsByMuniIds.get(muni.id).id;
            }
        }
        update munis;
        return munis;
    }

    /**
     *
     *
     * @param assets
     *
     * @return
     */
    public static List<Asset> linkAssetsWithHdp(List<ASset> assets) {
        Map<Id,Asset> mAssetsByIds = new Map<Id,Asset>();
        for(Asset ass : assets) {
            mAssetsByIds.put(ass.id,ass);
        }
        List<Hold_Per_Day_Total__c> holdPerDayTotals = [
                        select id, asset__c
                        from hold_per_day_total__c
                        where recordtype.name = 'Machine'
                        and asset__c in :mAssetsByIds.keyset()];
        Map<Id, Hold_Per_Day_Total__c> mHoldPerDayTotalsByAssetIds = new Map<Id, Hold_Per_Day_Total__c>();
        for (Hold_Per_Day_Total__c hpdt : holdPerDayTotals) {
            mHoldPerDayTotalsByAssetIds.put(hpdt.asset__c, hpdt);
        }
        for (Asset ass : assets) {
            ass.hold_per_day_total__c = mHoldPerDayTotalsByAssetIds.get(ass.id).id;
        }
        update assets;
        return assets;
    }

}