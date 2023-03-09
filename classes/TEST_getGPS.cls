@isTest
private class TEST_getGPS {

    @isTest
    static void testAuthCallout(){
        Test.setMock(HttpCalloutMock.class, new GPSAuthMockHttpResponseGenerator()); 
        GetGPS g = new GetGPS();
        String token = g.GetAuthToken();
        System.assertEquals(token, '12345');
    }
    
    @isTest (SeeAllData=true) 
    static void testGetGPSLocationsCallout(){
        Test.setMock(HttpCalloutMock.class, new GPSLocationMockHttpResponseGenerator());
        GetGPS g = new GetGPS();
          g.getGPSLocations();
    }
}