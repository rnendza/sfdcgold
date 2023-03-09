public class GeoTabUserResult {
    @AuraEnabled public GeoTabUser[] result;
    public String jsonrpc;
    @AuraEnabled public String id;
    @AuraEnabled public GeoTabError error;

    public static GeoTabUserResult parse(String json){
        return (GeoTabUserResult) System.JSON.deserialize(json, GeoTabUserResult.class);
    }
}