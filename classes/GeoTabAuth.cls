public class GeoTabAuth {

    public String method;
    public GeoTabAuthParams params;
    public static String DEFAULT_METHOD = 'Authenticate';

    public GeoTabAuth(String method) {
        this.method = method;
        this.params =new GeoTabAuthParams();
    }

    public GeoTabAuth(String db,String uName, String pw) {
        this.method = DEFAULT_METHOD;
        this.params =new GeoTabAuthParams(db,uName,pw);
    }

    public GeoTabAuth() {
        this.method = DEFAULT_METHOD;
        this.params =new GeoTabAuthParams();
    }
}