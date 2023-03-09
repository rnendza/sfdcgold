public class GeoTabDeviceStatusInfo {

    @AuraEnabled public Integer bearing;
    @AuraEnabled public String currentStateDuration;
    @AuraEnabled public String dateTime_x;
    @AuraEnabled public GeoTabDevice device;
    //driver
    //exceptionEvents[]
    //groups[]
    @AuraEnabled public Boolean isDeviceCommunicating;
    @AuraEnabled public Boolean isDriving;
    @AuraEnabled public Double latitude;
    @AuraEnabled public Double longitude;
    @AuraEnabled public Double speed;
    @AuraEnabled public String version;
    @AuraEnabled public String id;
}