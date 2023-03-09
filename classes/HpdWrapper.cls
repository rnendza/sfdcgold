public with sharing class HpdWrapper {
    @AuraEnabled public Id          accountId           { get;set; }
    @AuraEnabled public String      accountName         { get;set; }
    @AuraEnabled public String      accountNickname     { get;set;}
    @AuraEnabled public String      accountPhysicalStreet { get;set; }
    @AuraEnabled public String      accountPhysicalCity { get;set; }
    @AuraEnabled public String      accountZip { get;set; }
    @AuraEnabled public Double      accountLat { get;set; }
    @AuraEnabled public Double      accountLong { get;set; }
    @AuraEnabled public Date        accountAccelVgtLiveDate  {get;set;}   //  RJN 8-12-2019 SFCOMM-291515455
    @AuraEnabled public String      hpdId               { get;set; }
    @AuraEnabled public String      hpdName             { get;set; }
    @AuraEnabled public String      assetId             { get;set; }
    @AuraEnabled public Decimal     sasPosition         { get;set; }
    @AuraEnabled public String      assetModel          { get;set; }
    @AuraEnabled public Date        hpdDate             { get;set; }
    @AuraEnabled public Integer     hpdYear             { get;set; }
    @AuraEnabled public Integer     hpdMonth            { get;set; }
    @AuraEnabled public String      vgtUid              { get;set; }
    @AuraEnabled public Decimal     hpd           { get;set; }
    @AuraEnabled public Decimal     amtPlayed           { get;set; }
    @AuraEnabled public Decimal     amtWon              { get;set; }
    @AuraEnabled public Decimal     netRevenue          { get;set; }
    @AuraEnabled public Decimal     fundsIn             { get;set; }
    @AuraEnabled public Decimal     fundsOut            { get;set; }
    @AuraEnabled public Decimal     netFunds            { get;set; }
    @AuraEnabled public Decimal     taxRate             { get;set; }
    @AuraEnabled public Decimal     stateShare          { get;set; }
    @AuraEnabled public Decimal     locShare            { get;set; }
    @AuraEnabled public Decimal     adminFeeRate        { get;set; }
    @AuraEnabled public Decimal     adminShare          { get;set; }
    @AuraEnabled public Decimal     totalBill           { get;set; }
    @AuraEnabled public Integer     distinctDateCount   { get;set; }
    @AuraEnabled public Integer     distinctAccountCount   { get;set; }
    @AuraEnabled public String      weekday             { get;set; }
    @AuraEnabled public String      dateValue             { get;set; }


    public HpdWrapper() {}
}