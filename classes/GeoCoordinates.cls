public class  GeoCoordinates {
    
    @AuraEnabled public Double latitude  {get;set;}
    @AuraEnabled public Double longitude {get;set;}
    @AuraEnabled public String accountId {get;set;}
    @AuraEnabled public String accountName {get;set;}
    @AuraEnabled public String accountAddress {get;set;}
    @AuraEnabled public Address address {get;set;}

    public GeoCoordinates() {
        this.address =  new Address();
    }

    public GeoCoordinates(Double lat,Double lng) {
        this.latitude = lat;
        this.longitude = lng;
        this.address =  new Address();
    }

    public GeoCoordinates(System.Location location) {
        this.latitude = location.latitude;
        this.longitude = location.longitude;
    }

    public class Address {
        @AuraEnabled public String street {get;set;}
        @AuraEnabled public String city {get;set;}
    }
}