public class GeoTabAuthParams {
    public String database;
    public String userName;
    public String password;

    public GeoTabAuthParams() { }

    public GeoTabAuthParams(String db, String uName, String pw) {
        this.database = db;
        this.userName = uName;
        this.password = pw;
    }
}