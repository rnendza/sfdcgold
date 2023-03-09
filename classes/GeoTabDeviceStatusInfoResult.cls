public class GeoTabDeviceStatusInfoResult {

    @AuraEnabled public GeoTabDeviceStatusInfo[] result;
    public String jsonrpc;	//2.0
    public String id;	//268ea12eac2a2cc9f6f6581156006e4a
    @AuraEnabled public GeoTabError error;
    public GeoTabSearchParams searchParams;
    @AuraEnabled public Integer httpStatusCode;

    public static GeoTabDeviceStatusInfoResult parse(String json){
        json = json.replace('dateTime','dateTime_x');
        return (GeoTabDeviceStatusInfoResult) System.JSON.deserialize(json, GeoTabDeviceStatusInfoResult.class);
    }
}