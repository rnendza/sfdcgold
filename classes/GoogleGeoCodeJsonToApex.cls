public class GoogleGeoCodeJsonToApex {

    public class Address_components {
        public String long_name;
        public String short_name;
        public List<String> types;
    }

    public class Geometry {
        public Location location;
        public String location_type;
        public Viewport viewport;
    }

    public class Plus_code {
        public String compound_code;
        public String global_code;
    }

    public class Geometry_Z {
        public Viewport bounds;
        public Location location;
        public String location_type;
        public Viewport viewport;
    }

    public class Results {
        public List<Address_components> address_components;
        public String formatted_address;
        public Geometry geometry;
        public String place_id;
        public Plus_code plus_code;
        public List<String> types;
        public List<String> postcode_localities;
    }

    public class Viewport {
        public Location northeast;
        public Location southwest;
    }

    public class Location {
        public Double lat;
        public Double lng;
    }

    public Plus_code plus_code;
    public List<Results> results;
    public String status;


    public static GoogleGeoCodeJsonToApex parse(String json) {
        return (GoogleGeoCodeJsonToApex) System.JSON.deserialize(json, GoogleGeoCodeJsonToApex.class);
    }
}