public class HoldsPerDayStatsHelper {

    public static HPD_Total_Setting__mdt hpdTotalMunicipalitySetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(BatchHpdMunicipalityTotals.MUNICIPALITY_AGGREGATION_DEVNAME);
    public static HPD_Total_Setting__mdt hpdTotalAccountSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(BatchHpdAccountTotals.ACCT_AGGREGATION_DEVNAME);



//------------------  DEPRICATED IN FAVOR OR HPDSVC. ----------------------------------------------------------------------------------
//    public static List<Hold_Per_Day_Total__c> buildAccountHoldPerDayTotals(Map<Id, HpdStats> mHpdStatsByAccountIds) {
//        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
//
//        Map<Id, Hold_Per_Day_Total__c> mholdPerDayTotalsByIds = new Map<Id, Hold_Per_Day_Total__c>([
//                SELECT  id, recordtypeid, account__c, HPD_TTM_Revenue_Total__c,HPD_TTM_Daily_Total__c,frequency__c,
//                        HPD_TTM_Funds_Out_Total__c,
//                        municipality__c,hpd_total_vgt_count__c,HPD_Funds_In_Total_12_weeks__c,HPD_Revenue_Total_12_Weeks__c,
//                        HPD_Funds_In_Total_8_weeks__c,HPD_Revenue_Total_8_Weeks__c,
//                        HPD_Funds_In_Total_4_weeks__c,HPD_Revenue_Total_4_Weeks__c,
//                        HPD_Municipality_Accel_Revenue_Total_12__c,location_type__c,
//                        HPD_Funds_Out_Total_4_Weeks__c,HPD_Funds_Out_Total_8_Weeks__c,HPD_Funds_Out_Total_12_Weeks__c
//                FROM    Hold_Per_Day_Total__c
//                WHERE   account__c in :mHpdStatsByAccountIds.keySet()
//                FOR UPDATE
//        ]);
//        Map<Id, Hold_Per_Day_Total__c> mholdPerDayTotalsByAccountIds = new Map<Id, Hold_Per_Day_Total__c>();
//        for (Hold_Per_Day_Total__c holdPerDayTotal : mholdPerDayTotalsByIds.values()) {
//            mholdPerDayTotalsByAccountIds.put(holdPerDayTotal.account__c, holdPerDayTotal);
//        }
//
//        if (!mholdPerDayTotalsByIds.isEmpty()) {
//            //RecordType rt = [select id from recordtype where developername = 'Location' and sobjectType = 'Hold_Per_Day_Total__c'];
//            Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
//            for (Id acctId : mHpdStatsByAccountIds.keySet()) {
//                HpdStats hpdStats = (HpdStats) mHpdStatsByAccountIds.get(acctId);
//                Hold_Per_Day_Total__c holdPerDayTotal = mholdPerDayTotalsByAccountIds.get(acctId);
//                if (holdPerDayTotal != null) {
//                    holdPerDayTotal.HPD_TTM_Revenue_Total__c = hpdStats.ttm_totalNetFunds;
//                    holdPerDayTotal.HPD_TTM_Daily_Total__c = hpdStats.ttm_totalHpd;
//                    holdPerDayTotal.HPD_TTM_Funds_in_Total__c = hpdStats.ttm_totalFundsIn;
//                    holdPerDayTotal.HPD_TTM_Funds_Out_Total__c = hpdStats.ttm_totalFundsOut;
//                    holdPerDayTotal.HPD_Funds_In_Total_12_weeks__c = hpdStats.totalFundsIn12Weeks;
//                    holdPerDayTotal.HPD_Funds_In_Total_4_weeks__c = hpdStats.totalFundsIn4Weeks;
//                    holdPerDayTotal.HPD_Funds_In_Total_8_weeks__c = hpdStats.totalFundsIn8Weeks;
//
//                    holdPerDayTotal.HPD_Funds_Out_Total_4_Weeks__c = hpdStats.totalFundsOut4Weeks;
//                    holdPerDayTotal.HPD_Funds_Out_Total_8_Weeks__c = hpdStats.totalFundsOut8Weeks;
//                    holdPerDayTotal.HPD_Funds_Out_Total_12_Weeks__c = hpdStats.totalFundsOut12Weeks;
//
//                    holdPerDayTotal.HPD_Total_Vgt_Count__C = hpdStats.ttm_accountVgts;
//                    holdPerDayTotal.Municipality__c = hpdStats.muniId;
//                    holdPerDayTotal.HPD_Revenue_Total_12_Weeks__c = hpdStats.totalNetFunds12Weeks;
//                    holdPerDayTotal.HPD_Revenue_Total_8_Weeks__c = hpdStats.totalNetFunds8Weeks;
//                    holdPerDayTotal.HPD_Revenue_Total_4_Weeks__c = hpdStats.totalNetFunds4Weeks;
//                    holdPerDayTotal.recordtypeid = rtId;
//                    holdPerDayTotal.frequency__c = 'Monthly';
//                    holdPerDayTotals.add(holdPerDayTotal);
//                }
//            }
//        } else {
//            system.debug(logginglevel.warn, 'build account hold per day totals. no hpd records for provided account ids of. '+mHpdStatsByAccountIds.keySet());
//        }
//        return holdPerDayTotals;
//    }
//    public static List<Hold_Per_Day_Total__c> buildMunicipalityHoldPerDayTotals(Map<Id, HpdStats> mHpdStatsByMuniIds) {
//        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
//        Map<Id, Hold_Per_Day_Total__c> mholdPerDayTotalsByIds = new Map<Id, Hold_Per_Day_Total__c>([
//                SELECT id, recordtypeid, account__c, HPD_TTM_Revenue_Total__c,HPD_TTM_Daily_Total__c,frequency__c,municipality__c,hpd_total_vgt_count__c,
//                        HPD_Revenue_Total_12_Weeks__c,HPD_Municipality_Accel_Revenue_Total_12__c,HPD_Municipality_Accel_Total_VGT_Count__c,
//                        HPD_Revenue_Total_4_Weeks__c,HPD_Revenue_Total_8_Weeks__c,HPD_Funds_In_Total_4_Weeks__c,HPD_Funds_In_Total_8_Weeks__c,
//                        HPD_Municipality_Funds_Out_Total_4_Weeks__c,HPD_Municipality_Funds_Out_Total_8_Weeks__c, HPD_Municipality_Funds_Out_Total_12weeks__c
//                FROM Hold_Per_Day_Total__c
//                WHERE municipality__c in :mHpdStatsByMuniIds.keySet()
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
//                    holdPerDayTotal.frequency__c = 'Monthly';
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
//
//    public static map<Id, HpdStats> aggregateHpdStats(Set<Id>accountIds) {
//        Map<Id, HpdStats> mHpdStatsByAccountIds = new Map<Id, HpdStats>();
//        String rtName = 'Monthly HPD';
//        List<String> accountTypes = hpdTotalAccountSetting.HPD_Account_Types__c.split(',');
//        //---12 month
//        for (AggregateResult ar : [
//                SELECT Account__c,
//                        MAX(Account__r.MunicipalityLookup__c) muniId,
//                        SUM(Net_Funds__c) netFundsTotal,
//                        SUM(Net_Funds__c) netAccelRevTotal,
//                        SUM(Funds_In__c) fundsInTotal,
//                        SUM(Funds_Out__c) fundsOutTotal,
//                        AVG(VGT_Count__c) vgtTotal,
//                        SUM(HPD__c) hpdTotal
//                FROM Hold_Per_Day__c
//                WHERE Account__c in :accountIds
//                AND RecordType.Name = :rtName
//                and Date__c = LAST_N_MONTHS:13
//                and Account__r.type in :accountTypes
//                GROUP BY Account__c
//        ]) {
//            HpdStats hpdStats = new HpdStats();
//            if (ar.get('netFundsTotal') != null) {
//                hpdStats.ttm_totalNetFunds = (Decimal) ar.get('netFundsTotal');
//                hpdStats.ttm_totalHpd = (Decimal) ar.get('hpdTotal');
//                hpdStats.ttm_totalFundsIn = (Decimal) ar.get('fundsInTotal');
//                hpdStats.ttm_totalFundsOut = (Decimal) ar.get('fundsOutTotal');
//                hpdStats.ttm_accountVgts = Integer.valueOf((Decimal) ar.get('vgtTotal'));
//                hpdStats.muniId = (Id) ar.get('muniId');
//
//            }
//            mHpdStatsByAccountIds.put((Id) ar.get('Account__c'), hpdStats);
//        }
//        //---------------
//        //---1 month ie 4 weeks
//        for (AggregateResult ar : [
//                SELECT Account__c,
//                        MAX(Account__r.MunicipalityLookup__c) muniId,
//                        SUM(Net_Funds__c) netFundsTotal,
//                        SUM(Funds_In__c) fundsInTotal,
//                        SUM(Funds_Out__c) fundsOutTotal
//                FROM Hold_Per_Day__c
//                WHERE Account__c in :mHpdStatsByAccountIds.keySet()
//                AND RecordType.Name = :rtName
//                and Date__c = LAST_N_MONTHS:2
//                and Account__r.type in :accountTypes
//                GROUP BY Account__c
//        ]) {
//            Id acctId = (Id) ar.get('Account__c');
//            HpdStats hpdStats = mHpdStatsByAccountIds.get(acctId);
//            if (ar.get('netFundsTotal') != null) {
//                hpdStats.totalNetFunds4Weeks = (Decimal) ar.get('netFundsTotal');
//                hpdStats.totalFundsIn4Weeks = (Decimal) ar.get('fundsInTotal');
//                hpdStats.totalFundsOut4Weeks  = (Decimal) ar.get('fundsOutTotal');
//                mHpdStatsByAccountIds.put((Id) ar.get('Account__c'), hpdStats);
//            }
//        }
//        //---2 months ie 8 weeks
//        for (AggregateResult ar : [
//                SELECT Account__c,
//                        MAX(Account__r.MunicipalityLookup__c) muniId,
//                        SUM(Net_Funds__c) netFundsTotal,
//                        SUM(Funds_In__c) fundsInTotal,
//                        SUM(Funds_Out__c) fundsOutTotal
//                FROM Hold_Per_Day__c
//                WHERE Account__c in :mHpdStatsByAccountIds.keySet()
//                AND RecordType.Name = :rtName
//                and Date__c = LAST_N_MONTHS:3
//                and Account__r.type in :accountTypes
//                GROUP BY Account__c
//        ]) {
//            Id acctId = (Id) ar.get('Account__c');
//            HpdStats hpdStats = mHpdStatsByAccountIds.get(acctId);
//            if (ar.get('netFundsTotal') != null) {
//                hpdStats.totalNetFunds8Weeks = (Decimal) ar.get('netFundsTotal');
//                hpdStats.totalFundsIn8Weeks = (Decimal) ar.get('fundsInTotal');
//                hpdStats.totalFundsOut8Weeks  = (Decimal) ar.get('fundsOutTotal');
//                mHpdStatsByAccountIds.put((Id) ar.get('Account__c'), hpdStats);
//            }
//        }
//        //---------------
//        //---3 month
//        for (AggregateResult ar : [
//                SELECT Account__c,
//                        MAX(Account__r.MunicipalityLookup__c) muniId,
//                        SUM(Net_Funds__c) netFundsTotal,
//                        SUM(Funds_In__c) fundsInTotal,
//                        SUM(Funds_Out__c) fundsOutTotal
//                FROM Hold_Per_Day__c
//                WHERE Account__c in :mHpdStatsByAccountIds.keySet()
//                AND RecordType.Name = :rtName
//                and Date__c = LAST_N_MONTHS:4
//                and Account__r.type in :accountTypes
//                GROUP BY Account__c
//        ]) {
//            Id acctId = (Id) ar.get('Account__c');
//            HpdStats hpdStats = mHpdStatsByAccountIds.get(acctId);
//            if (ar.get('netFundsTotal') != null) {
//                hpdStats.totalNetFunds12Weeks = (Decimal) ar.get('netFundsTotal');
//                hpdStats.totalFundsIn12Weeks = (Decimal) ar.get('fundsInTotal');
//                hpdStats.totalFundsOut12Weeks  = (Decimal) ar.get('fundsOutTotal');
//                mHpdStatsByAccountIds.put((Id) ar.get('Account__c'), hpdStats);
//            }
//        }
//        //---------------
//
//
//        return mHpdStatsByAccountIds;
//    }
//
//    public static map<Id, HpdStats> aggregateHpdMunicialityStats(Set<Id>muniIds) {
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
     */
    public static void reInitHpdTotals() {
        HoldsPerDayStatsHelper.initHpdAccountTotalRecs();
        HoldsPerDayStatsHelper.linkAccountWithHdp();
        HoldsPerDayStatsHelper.initHpdMunicipalityTotalRecs();
        HoldsPerDayStatsHelper.linkMunicipalityWithHdp();
    }
    /**
     * Primarily used for Unit Test Code but can be used if we want to clear out hpd totals and start over.
     * @return
     */
    public static List<Hold_Per_Day_Total__c> initHpdAccountTotalRecs() {
        List<Account> accts = [select id, municipalitylookup__c,type from Account
        where (type = 'Accel Account' or type = 'Competitor Account' or type = 'Discontinued Account' or type = 'Other')];

        Set<Id> acctIds = new Set<Id>();
        for (Account a : accts) {
            acctIds.add(a.id);
        }
        List<Hold_Per_Day_Total__c> holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        //RecordType rt = [select id from recordtype where developername = 'Location' and SObjectType = 'Hold_Per_Day_Total__c'];
        Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
        for (Account account : accts) {
            Hold_Per_Day_Total__c hpds = new Hold_Per_Day_Total__c();
            hpds.account__c = account.id;
            hpds.municipality__c = account.MunicipalityLookup__c;
            hpds.recordtypeid = rtId;
            hpds.frequency__c = 'Monthly';
            holdPerDayTotals.add(hpds);
        }
        insert holdPerDayTotals;
        return holdPerDayTotals;
    }
    public static List<Hold_Per_Day_Total__C> initHpdMunicipalityTotalRecs() {
        List<Municipality__c> municipalities = [select id from Municipality__c];

        Set<Id> muniIds = new Set<Id>();
        for (Municipality__c muni : municipalities) {
            muniIds.add(muni.id);
        }
        List<Hold_Per_Day_Total__c>holdPerDayTotals = new List<Hold_Per_Day_Total__c>();
        //RecordType rt = [select id from recordtype where developername = 'Municipality' and SObjectType = 'Hold_Per_Day_Total__c'];
        Id rtId = Schema.getGlobalDescribe().get('Hold_Per_Day_Total__c').getDescribe().getRecordTypeInfosByDeveloperName().get('Municipality').getRecordTypeId();
        for (Municipality__c muni : municipalities) {
            Hold_Per_Day_Total__c hpds = new Hold_Per_Day_Total__c();
            hpds.municipality__c = muni.id;
            hpds.recordtypeid = rtId;
            hpds.frequency__c = 'Monthly';
            holdPerDayTotals.add(hpds);
        }
        insert holdPerDayTotals;
        return holdPerDayTotals;
    }
    public static void linkAccountWithHdp() {
        List<String> accountTypes = hpdTotalMunicipalitySetting.HPD_Account_Types__c.split(',');

        List<Hold_Per_Day_total__c> hpdts = [select id, account__c from hold_per_day_total__c where account__c != null];
        Map<Id, Hold_Per_Day_Total__c> mHoldPerDayTotalsByAccountIds = new Map<Id, Hold_Per_Day_Total__c>();
        for (Hold_Per_Day_Total__c hpdt : hpdts) {
            mHoldPerDayTotalsByAccountIds.put(hpdt.account__c, hpdt);
        }
        List<Account> acctsToUpd = [
                select id, hold_per_day_total__c
                from account
                where hold_per_day_total__c = null
                AND TYPE IN :accountTypes
                limit 2000
        ];
        for (Account a : acctsToUpd) {
            a.hold_per_day_total__c = mHoldPerDayTotalsByAccountIds.get(a.id).id;
        }
        update acctsToUpd;

    }
    public static void linkMunicipalityWithHdp() {
        List<Hold_Per_Day_total__c> hpdts = [select id, municipality__c from hold_per_day_total__c where municipality__c != null and recordtype.name = 'Municipality'];
        Map<Id, Hold_Per_Day_Total__c> mHoldPerDayTotalsByMuniIds = new Map<Id, Hold_Per_Day_Total__c>();
        for (Hold_Per_Day_Total__c hpdt : hpdts) {
            mHoldPerDayTotalsByMuniIds.put(hpdt.municipality__c, hpdt);
        }

        List<Municipality__c> munisToUpd = [select id, hold_per_day_total__c from municipality__c where hold_per_day_total__c = null];
        for (Municipality__c mp : munisToUpd) {
            if (mHoldPerDayTotalsByMuniIds.get(mp.id) != null) {
                mp.hold_per_day_total__c = mHoldPerDayTotalsByMuniIds.get(mp.id).id;
            }
        }
        update munisToUpd;
    }

}