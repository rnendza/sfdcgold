public class GeocodeSearchController {

    public static final String MAP_KEY_GEO_JSON_RESULTS             =   'MAP_KEY_GEO_JSON_RESULTS';
    public static final String MAP_KEY_REVERSE_GEOCODE_ADDRESS      =   'MAP_KEY_REVERSE_GEOCODE_ADDRESS';

    /**
     * Since LocationIq has already come back with valid JSON, no need to parse it. in fact we can't otherwise we
     * will not get array but rather one value. The Platform Serializes Objects on the way down to the client
     * automatically.
     *
     * @param term  The term to search
     * @return      A Response dto containing the JSON in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveGeocodeAutocompleteAddresses ( String term) {
        ResponseDto dto = new ResponseDto();
        String jsonResult = YelpSearchSvc.autocompleteLocationIq(term);
        if(jsonResult!=null ) {
            dto.isSuccess = true;
            dto.message = 'success';
            if(jsonResult != '') {
                Object obj = JSON.deserializeUntyped(jsonResult);
                dto.values.put( MAP_KEY_GEO_JSON_RESULTS, obj );
            }
        } else {
            dto.technicalMsg = 'invalid search.. term used ='+term;
            dto.message = 'No Results Found';
        }
        return dto;
    }
    /**
     *
     *
     * @param term
     *
     * @return
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveReverseGeocodeAddress ( Decimal latitude, Decimal longitude) {
        ResponseDto dto = new ResponseDto();
        String jsonResult = YelpSearchSvc.reverseGeocode(latitude, longitude);
        if(jsonResult!=null ) {
            dto.isSuccess = true;
            dto.message = 'success';
            if(jsonResult != '') {
                Object obj = JSON.deserializeUntyped(jsonResult);
                dto.values.put( MAP_KEY_REVERSE_GEOCODE_ADDRESS, obj );
            }
        } else {
            dto.technicalMsg = 'UNABLE TO REVERSE GEO WITH PROVIDED LAT / LON';
            dto.message = 'No Results Found';
        }
        return dto;
    }
}