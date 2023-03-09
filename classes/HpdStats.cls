/**
 * @TODO this really should be an interface and / or use a base abstract class.
 */
public with sharing class HpdStats {

    public Decimal totalNetFunds12Weeks {get;set;}
    public Decimal totalFundsIn12Weeks  {get;set;}
    public Decimal totalNetFunds4Weeks {get;set;}
    public Decimal totalFundsIn4Weeks  {get;set;}
    public Decimal totalNetFunds8Weeks {get;set;}
    public Decimal totalFundsIn8Weeks  {get;set;}

    public Decimal totalAccelRev12Weeks {get;set;}
    public Decimal totalAccelRev8Weeks {get;set;}
    public Decimal totalAccelRev4Weeks {get;set;}

    public Decimal totalFundsOut4Weeks {get;set;}
    public Decimal totalFundsOut8Weeks {get;set;}
    public Decimal totalFundsOut12Weeks {get;set;}

    public Decimal totalAmountWon4Weeks {get;set;}
    public Decimal totalAmountWon8Weeks {get;set;}
    public Decimal totalAmountWon12Weeks {get;set;}

    public Decimal totalAmountPlayed4Weeks {get;set;}
    public Decimal totalAmountPlayed8Weeks {get;set;}
    public Decimal totalAmountPlayed12Weeks {get;set;}

    public Decimal totalNti12Weeks {get;set;}
    public Decimal totalNti8Weeks {get;set;}
    public Decimal totalNti4Weeks {get;set;}

    public Decimal totalLocShare12Weeks {get;set;}
    public Decimal totalLocShare8Weeks {get;set;}
    public Decimal totalLocShare4Weeks {get;set;}

    public Integer totalVgtCount {get;set;}
    public Integer totalAccelVgtCount {get;set;}
    public Integer totalRecsFound12Weeks {get;set;}
    public Integer totalRecsFound8Weeks {get;set;}
    public Integer totalRecsFound4Weeks {get;set;}

    public Integer totalDaysInMonths12Weeks {get;set;}
    public Integer totalDaysInMonths8Weeks {get;set;}
    public Integer totalDaysInMonths4Weeks {get;set;}

    public Decimal avgHpd12Weeks {get;set;}
    public Decimal avgHpd8Weeks {get;set;}
    public Decimal avgHpd4Weeks {get;set;}

    public Decimal tsm_totalAmountWon {get;set;}
    public Decimal tsm_totalAmountPlayed {get;set;}
    public Decimal tsm_totalNetFunds {get;set;}
    public Decimal tsm_totalFundsIn {get;set;}
    public Decimal tsm_totalFundsOut {get;set;}
    public Decimal tsm_totalHpd {get;set;}
    public Decimal tsm_nti {get;set;}
    public Decimal tsm_totalLocShare {get;set;}
    public Integer tsm_totalVgts {get;set;}
    public Integer tsm_accountVgts {get;set;}

    public Integer tsm_recordCount {get;set;}
    public Integer tsm_sumDaysInMonths {get;set;}
    public Decimal tsm_avgHpd {get;set;}

    public Decimal ttm_totalAmountWon {get;set;}
    public Decimal ttm_totalAmountPlayed {get;set;}
    public Decimal ttm_totalNetFunds {get;set;}
    public Decimal ttm_totalFundsIn {get;set;}
    public Decimal ttm_totalFundsOut {get;set;}
    public Decimal ttm_totalHpd {get;set;}
    public Decimal ttm_nti {get;set;}
    public Decimal ttm_totalLocShare {get;set;}
    public Integer ttm_totalVgts {get;set;}
    public Integer ttm_accountVgts {get;set;}

    public Integer ttm_recordCount {get;set;}
    public Integer ttm_sumDaysInMonths {get;set;}
    public Decimal ttm_avgHpd {get;set;}

    public Id holdPerDayTotalId {get;set;}
    public Id ttm_maxHpdId {get;set;}
    public Id tsm_maxHpdId {get;set;} 
    public Id muniId {get;set;}
    public Id assetId {get;set;}
    public Id accountId {get;set;}
    public Decimal ttm_totalMunicipalityNetFunds {get;set;}
    public Decimal machinePosition {get;set;}





    public HpdStats() {

        this.ttm_avgHpd = 0;
        this.tsm_avgHpd = 0;
        this.avgHpd4Weeks = 0;
        this.avgHpd8Weeks = 0;
        this.avgHpd12Weeks = 0;

        this.totalDaysInMonths12Weeks = 0;
        this.totalDaysInMonths8Weeks = 0;
        this.totalDaysInMonths4Weeks = 0;
        this.totalNetFunds12Weeks  = 0;
        this.totalAccelRev12Weeks = 0;
        this.totalNetFunds8Weeks = 0;
        this.totalFundsIn8Weeks = 0;
        this.totalAccelRev8Weeks = 0;
        this.totalNetFunds4Weeks = 0;
        this.totalAccelRev4Weeks = 0;
        this.totalFundsIn4Weeks =- 0;
        this.totalAccelVgtCount = 0;
        this.totalFundsIn12Weeks = 0;
        this.totalVgtCount = 0;

        this.totalAmountPlayed4Weeks = 0;
        this.totalAmountPlayed8Weeks = 0;
        this.totalAmountPlayed12Weeks = 0;

        this.totalRecsFound12Weeks = 0;
        this.totalRecsFound8Weeks = 0;
        this.totalRecsFound4Weeks = 0;

        this.totalNti12Weeks = 0;
        this.totalNti8Weeks = 0;
        this.totalNti4Weeks = 0;

        this.totalLocShare12Weeks = 0;
        this.totalLocShare8Weeks = 0;
        this.totalLocShare4Weeks = 0;

        this.totalAmountWon4Weeks = 0;
        this.totalAmountWon8Weeks = 0;
        this.totalAmountWon12Weeks = 0;

        this.totalFundsOut4Weeks = 0;
        this.totalFundsOut8Weeks = 0;
        this.totalFundsOut12Weeks = 0;


        this.tsm_totalNetFunds = 0;
        this.tsm_totalFundsIn = 0;
        this.tsm_totalFundsOut = 0;
        this.tsm_totalHpd = 0;
        this.tsm_totalVgts = 0;

        this.tsm_accountVgts = 0;
        this.tsm_recordCount = 0;
        this.tsm_totalAmountWon = 0;
        this.tsm_totalAmountPlayed = 0;
        this.tsm_nti = 0;
        this.tsm_totalLocShare = 0;
        this.tsm_sumDaysInMonths = 0;

        this.ttm_totalNetFunds = 0;
        this.ttm_totalFundsIn = 0;
        this.ttm_totalFundsOut = 0;
        this.ttm_totalHpd = 0;
        this.ttm_totalVgts = 0;

        this.ttm_accountVgts = 0;
        this.ttm_recordCount = 0;
        this.ttm_totalAmountWon = 0;
        this.ttm_totalAmountPlayed = 0;
        this.ttm_nti = 0;
        this.ttm_totalLocShare = 0;
        this.ttm_sumDaysInMonths = 0;


        this.ttm_totalMunicipalityNetFunds = 0;
        this.machinePosition = 0;
    }
}