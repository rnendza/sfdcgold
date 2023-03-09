public class GeoTabParams {

    public String id;
    public String method;
    public Params params;

    /**
     * @param credentials   A GeoTabAuthCredentials instance. i.e. username,pw,database
     * @param typeName      The typeName i.e. Entity [LogRecord,Device..etc].
     * @param id            An ID is used to uniquely reference entities in the API (client generated).
     * @param method        The Method Name i.e. [Get,GetFeed,Authenticate..etc].
     */
    public GeoTabParams(GeoTabAuthCredentials credentials,String typeName,String id,String method) {
        this.params = new Params(credentials,typeName);
        this.id = id;
        this.method = method;
    }

    /**
     * @param credentials   A GeoTabAuthCredentials instance. i.e. username,pw,database
     * @param typeName      The typeName i.e. Entity [LogRecord,Device..etc].
     * @param id            An ID is used to uniquely reference entities in the API (client generated).
     * @param method        The Method Name i.e. [Get,GetFeed,Authenticate..etc].
     * @param resultsLimit  xx
     */
    public GeoTabParams(GeoTabAuthCredentials credentials,String typeName,String id,String method,Integer resultsLimit) {
        this.params = new Params(credentials,typeName,resultsLimit);
        this.id = id;
        this.method = method;
    }

    /**
     *  Nested wrapper for params{}
     */
    public class Params {

        public String typeName;                     //  The typeName i.e. Entity [LogRecord,Device..etc].
        public GeoTabAuthCredentials credentials;   //  A GeoTabAuthCredentials instance. i.e. username,pw,database
        public GeoTabSearchParams search;           //  type name specific
        public Integer resultsLimit;

        public Params(GeoTabAuthCredentials credentials,String typeName) {
            this.credentials = credentials;
            this.typeName = typeName;
        }

        public Params(GeoTabAuthCredentials credentials,String typeName,Integer resultsLimit) {
            this.credentials = credentials;
            this.typeName = typeName;
            this.resultsLimit = resultsLimit;
        }
    }
}