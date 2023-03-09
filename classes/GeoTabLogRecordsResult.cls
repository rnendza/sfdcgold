public with sharing class GeoTabLogRecordsResult {

    public GeoTabLogRecord[] result;
    public String jsonrpc;	//2.0
    public String id;	//268ea12eac2a2cc9f6f6581156006e4a
    public GeoTabError error;
    public GeoTabSearchParams searchParams;

    public static GeoTabLogRecordsResult parse(String json){
        json = json.replace('dateTime','dateTime_x');
        return (GeoTabLogRecordsResult) System.JSON.deserialize(json, GeoTabLogRecordsResult.class);
    }
}