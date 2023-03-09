public class GeoTabDeviceResult {
    @AuraEnabled public GeoTabDevice[] result;
    public String jsonrpc;
    public String id;
    @AuraEnabled public GeoTabError error;

    public static GeoTabDeviceResult parse(String json){
        return (GeoTabDeviceResult) System.JSON.deserialize(json, GeoTabDeviceResult.class);
    }
}