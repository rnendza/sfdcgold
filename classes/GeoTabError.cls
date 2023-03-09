public class GeoTabError {

    @AuraEnabled public Error error;
    public String jsonrpc;	        //  2.0
    public String id;	            //  97de831fedf115a0f0547c70537ecd40
    public Integer requestIndex;	//  0

    public class Error {
        @AuraEnabled public String message;	//  The method 'GetCountOf' could not be found....
        @AuraEnabled public Integer code;	//  -32601
        @AuraEnabled public Data data;
        @AuraEnabled public String name;	    //  JSONRPCError
        @AuraEnabled public Errors[] errors;
    }

    public class Errors {
        @AuraEnabled public String message;	//  The method 'GetCountOf' could not be found....
        @AuraEnabled public String name;	    //  MissingMethodException
    }

    public class Data {
        @AuraEnabled public String id;	//  46a0bd9e-91ce-4fc0-9419-ab4397f3dded
        @AuraEnabled public String type;	//  MissingMethodException
        @AuraEnabled public Integer requestIndex;	//  0
    }

    public static GeoTabError parse(String json){
        return (GeoTabError) System.JSON.deserialize(json, GeoTabError.class);
    }

}