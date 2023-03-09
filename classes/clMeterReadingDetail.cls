global  class clMeterReadingDetail {
    public id meterId;
    public String meterName;
    public Double currentLtCashInAmt = 0;

    public clMeterReadingDetail(Meter_Reading__c mr) {
        this.meterId = mr.Id;
        this.meterName = mr.Name;
        this.currentLtCashInAmt = mr.Current_Lifetime_Cash_In__c;
    }
}