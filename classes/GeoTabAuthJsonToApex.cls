public class GeoTabAuthJsonToApex {

    public GeoTabAuthResult result;
    public String jsonrpc;
    public Exception ex;
    public GeoTabError error;

    public static GeoTabAuthJsonToApex parse(String json){
        return (GeoTabAuthJsonToApex) System.JSON.deserialize(json, GeoTabAuthJsonToApex.class);
    }
}