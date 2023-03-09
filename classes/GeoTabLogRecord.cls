public class GeoTabLogRecord {

    public Double longitude;	//  -87.9113998
    public Double latitude;
    public Double speedMph;
    public String dateTime_x;	//  2022-08-24T14:19:03.000Z
    public Device device;
    public String id;	        //  b2506A

    public Double speed {
        get {return speed;}
        set { speed = value;speedMph = this.calcSpeedMph(value);}
    }

    @TestVisible
    private Double calcSpeedMph(Double val) {
        Double mph;
        if (val != null) {
            if (val != 0) {
                mph = (val * .621371).setScale(1);
            } else {
                mph = 0;
            }
        }
        return mph;
    }

    public class Device {
        public String id;
    }
}