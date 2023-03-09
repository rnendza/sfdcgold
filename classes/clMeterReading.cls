public class clMeterReading {

    Id meterId;
    String name;

    public clMeterReading(Meter_Reading__c meter) {
        this.meterId = meter.Id;
        this.name = meter.Name;
    }
}