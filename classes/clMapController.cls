/**
 * Created by rnend on 6/25/2021.
 */

public with sharing class clMapController {

    @TestVisible

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveReverseGeoAddy(GeoCoordinates geoCoordinates) {
        ResponseDto dto = new ResponseDto();

        GoogleGeoCodeJsonToApex oJson = GoogleSvc.quickReverseGeo(geoCoordinates.longitude,geoCoordinates.latitude);
        String formattedAddy = getFormattedAddy(oJson);
        dto.isSuccess = formattedAddy != null;
        dto.values.put('FORMATTED_ADDRESS',formattedAddy);
        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveCurrentRecord(Id recordId, String sObjectApiName) {

        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += ' recordId='+recordId + '.. sObjectApiName='+sObjectApiName;

        switch on sObjectApiName {
            when 'Route_Schedule__c' {
                Route_Schedule__c routeSchedule = clRouteScheduleSvc.retrieveRouteSchedule(recordId);
                if(routeSchedule != null) {
                    dto.values.put('SOBJECT',routeSchedule);
                    dto.isSuccess = true;
                }
            }
        }
        return dto;
    }

    public static String getFormattedAddy(GoogleGeoCodeJsonToApex oGoogleJson) {
        String addy = '';
        if (oGoogleJson != null) {
            addy = oGoogleJson.results[0].formatted_address;
        }
        return addy;
    }
}