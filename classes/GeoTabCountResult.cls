public class GeoTabCountResult {
    public Integer result;
    public String  jsonRpc;
    public String  id;
    public GeoTabError error;

    public static GeoTabCountResult parse(String json){
        return (GeoTabCountResult) System.JSON.deserialize(json, GeoTabCountResult.class);
    }
}