public without sharing class GoogleSvc {

    private static final Integer DEFAULT_TIMEOUT = 10000;
    public static final Integer HTTP_OK = 200;
    @TestVisible private final static String LATLNG_PARAM = '&latlng=';


    /**
     * @param googleTransaction an enum containing the api call desired.
     * @return
     *
     * @see GoogleTransaction
     */
    public static HttpRequest initHttpRequest(GoogleTransaction googleTransaction) {
        HttpRequest httpRequest;

        switch on googleTransaction {
            when GEOCODING {
                httpRequest = buildGeocodingHttpRequest();
            } when DISTANCEMATRIX { 
                httpRequest = buildDistanceMatrixHttpRequest();
            }
            when else {
                System.debug(LoggingLevel.ERROR,'---> Invalid google trans requested:'+googleTransaction.name());
            }
        }
        return httpRequest;
    }

    /**
     * @return A valid HttpRequest object if we can build it, otherwise null.
     */
    @TestVisible
    private static HttpRequest buildGeocodingHttpRequest() {
        HttpRequest httpRequest = new HttpRequest();

        Google_Setting__mdt mdt = queryForMetadata(GoogleTransaction.GEOCODING.name());

        httpRequest.setEndpoint(mdt.Endpoint__c + mdt.Api_Key__c);
        httpRequest.setTimeout(mdt.Timeout__c != null ? Integer.valueOf(mdt.Timeout__c) : DEFAULT_TIMEOUT);
        httpRequest.setMethod(mdt.Http_Method__c);


        return httpRequest;
    }

   /**
    * @return A valid HttpRequest object if we can build it, otherwise null.
    */
    @TestVisible
    private static HttpRequest buildDistanceMatrixHttpRequest() {
        HttpRequest httpRequest = new HttpRequest();

        Google_Setting__mdt mdt = queryForMetadata(GoogleTransaction.DISTANCEMATRIX.name());

        httpRequest.setEndpoint(mdt.Endpoint__c + mdt.Api_Key__c);
        httpRequest.setTimeout(mdt.Timeout__c != null ? Integer.valueOf(mdt.Timeout__c) : DEFAULT_TIMEOUT);
        httpRequest.setMethod(mdt.Http_Method__c);


        return httpRequest;
    }

    /**
     * @param developerName The developername of the custom metadata record.
     * @return              An instance of Google_Setting__mdt if found, otherwise null.
     */
    public static Google_Setting__mdt queryForMetadata(String developerName) {
        Google_Setting__mdt mdt;

        SObject sObj = CustomMetadataSvc.retrieveCustomMetadata(Google_Setting__mdt.getSobjectType(), developerName);
        if(sObj != null) {
            mdt = (Google_Setting__mdt)sObj;
        }
        return mdt;
    }

    public static GoogleGeoCodeJsonToApex quickReverseGeo(Double lng,Double lat) {

        Http http = new Http();
        HttpRequest httpRequest = GoogleSvc.initHttpRequest(GoogleTransaction.GEOCODING);
        String baseEp = httpRequest.getEndpoint();


        String epSuffix = LATLNG_PARAM + lat + ',' + lng;
        httpRequest.setEndpoint(baseEp + epSuffix);

        HttpResponse res;

        if(!Test.isRunningTest()) {
            res = http.send(httpRequest);
        } else {
            res = new HttpResponse();
            res.setStatusCode(GoogleSvc.HTTP_OK);
            res.setBody(testJsonValidMuni);
        }

        String jsonResponse = '';
        GoogleGeoCodeJsonToApex jsonObj;

        if (res.getStatusCode() == GoogleSvc.HTTP_OK) {
            jsonResponse = res.getBody();
            jsonObj = GoogleGeoCodeJsonToApex.parse(jsonResponse);
            System.debug('---> jsonObj=' + jsonObj);
        }
        return jsonObj;
    }

    public static String testJsonValidMuni ='{'+
            '   \"plus_code\" : {'+
            '      \"compound_code\" : \"WR5W+32 Carol Stream, IL, USA\",'+
            '      \"global_code\" : \"86HHWR5W+32\"'+
            '   },'+
            '   \"results\" : ['+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"27W371\",'+
            '               \"short_name\" : \"27W371\",'+
            '               \"types\" : [ \"street_number\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"North Avenue\",'+
            '               \"short_name\" : \"N Ave\",'+
            '               \"types\" : [ \"route\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Carol Stream\",'+
            '               \"short_name\" : \"Carol Stream\",'+
            '               \"types\" : [ \"locality\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Wayne Township\",'+
            '               \"short_name\" : \"Wayne Township\",'+
            '               \"types\" : [ \"administrative_area_level_3\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"60188\",'+
            '               \"short_name\" : \"60188\",'+
            '               \"types\" : [ \"postal_code\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"27W371 N Ave, Carol Stream, IL 60188, USA\",'+
            '         \"geometry\" : {'+
            '            \"location\" : {'+
            '               \"lat\" : 41.9076835,'+
            '               \"lng\" : -88.1549825'+
            '            },'+
            '            \"location_type\" : \"ROOFTOP\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.90903248029149,'+
            '                  \"lng\" : -88.15363351970851'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.90633451970849,'+
            '                  \"lng\" : -88.15633148029151'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJlbrZo7OqD4gRlmxHM5AbeYE\",'+
            '         \"plus_code\" : {'+
            '            \"compound_code\" : \"WR5W+32 Carol Stream, IL, USA\",'+
            '            \"global_code\" : \"86HHWR5W+32\"'+
            '         },'+
            '         \"types\" : [ \"street_address\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"27W371\",'+
            '               \"short_name\" : \"27W371\",'+
            '               \"types\" : [ \"street_number\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"North Avenue\",'+
            '               \"short_name\" : \"N Ave\",'+
            '               \"types\" : [ \"route\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"West Chicago\",'+
            '               \"short_name\" : \"West Chicago\",'+
            '               \"types\" : [ \"locality\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Wayne Township\",'+
            '               \"short_name\" : \"Wayne Township\",'+
            '               \"types\" : [ \"administrative_area_level_3\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"60185\",'+
            '               \"short_name\" : \"60185\",'+
            '               \"types\" : [ \"postal_code\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"1533\",'+
            '               \"short_name\" : \"1533\",'+
            '               \"types\" : [ \"postal_code_suffix\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"27W371 N Ave, West Chicago, IL 60185, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9079076,'+
            '                  \"lng\" : -88.1549483'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.90762429999999,'+
            '                  \"lng\" : -88.15524839999999'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 41.9077481,'+
            '               \"lng\" : -88.1551358'+
            '            },'+
            '            \"location_type\" : \"ROOFTOP\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.90911493029149,'+
            '                  \"lng\" : -88.15374936970849'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.9064169697085,'+
            '                  \"lng\" : -88.1564473302915'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJO-RqpLOqD4gRZTrmTNIXnPI\",'+
            '         \"types\" : [ \"premise\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"27\",'+
            '               \"short_name\" : \"27\",'+
            '               \"types\" : [ \"street_number\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois 64\",'+
            '               \"short_name\" : \"IL-64\",'+
            '               \"types\" : [ \"route\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"West Chicago\",'+
            '               \"short_name\" : \"West Chicago\",'+
            '               \"types\" : [ \"locality\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Wayne Township\",'+
            '               \"short_name\" : \"Wayne Township\",'+
            '               \"types\" : [ \"administrative_area_level_3\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"60185\",'+
            '               \"short_name\" : \"60185\",'+
            '               \"types\" : [ \"postal_code\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"27 IL-64, West Chicago, IL 60185, USA\",'+
            '         \"geometry\" : {'+
            '            \"location\" : {'+
            '               \"lat\" : 41.90816239999999,'+
            '               \"lng\" : -88.1548811'+
            '            },'+
            '            \"location_type\" : \"RANGE_INTERPOLATED\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9095113802915,'+
            '                  \"lng\" : -88.15353211970849'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.9068134197085,'+
            '                  \"lng\" : -88.15623008029151'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"EiUyNyBJTC02NCwgV2VzdCBDaGljYWdvLCBJTCA2MDE4NSwgVVNBIhoSGAoUChIJUQkMj7OqD4gRLwT35tJTDHUQGw\",'+
            '         \"types\" : [ \"street_address\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"Morton Road\",'+
            '               \"short_name\" : \"Morton Rd\",'+
            '               \"types\" : [ \"route\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"West Chicago\",'+
            '               \"short_name\" : \"West Chicago\",'+
            '               \"types\" : [ \"locality\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Wayne Township\",'+
            '               \"short_name\" : \"Wayne Township\",'+
            '               \"types\" : [ \"administrative_area_level_3\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"60185\",'+
            '               \"short_name\" : \"60185\",'+
            '               \"types\" : [ \"postal_code\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"Morton Rd, West Chicago, IL 60185, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9080027,'+
            '                  \"lng\" : -88.15544510000001'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.9074171,'+
            '                  \"lng\" : -88.1554546'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 41.9077099,'+
            '               \"lng\" : -88.1554481'+
            '            },'+
            '            \"location_type\" : \"GEOMETRIC_CENTER\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9090588802915,'+
            '                  \"lng\" : -88.15410086970851'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.9063609197085,'+
            '                  \"lng\" : -88.15679883029152'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJe0YKr7OqD4gROPW20wYMlAc\",'+
            '         \"types\" : [ \"route\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"60185\",'+
            '               \"short_name\" : \"60185\",'+
            '               \"types\" : [ \"postal_code\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Northwoods\",'+
            '               \"short_name\" : \"Northwoods\",'+
            '               \"types\" : [ \"neighborhood\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"Northwoods, IL 60185, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9501239,'+
            '                  \"lng\" : -88.13185989999999'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.8347019,'+
            '                  \"lng\" : -88.279146'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 41.8959291,'+
            '               \"lng\" : -88.21690269999999'+
            '            },'+
            '            \"location_type\" : \"APPROXIMATE\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9501239,'+
            '                  \"lng\" : -88.13185989999999'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.8347019,'+
            '                  \"lng\" : -88.279146'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJ_9LtAC_-DogRSoqgr86gvL4\",'+
            '         \"postcode_localities\" : [ \"Northwoods\", \"West Chicago\" ],'+
            '         \"types\" : [ \"postal_code\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"Wayne Township\",'+
            '               \"short_name\" : \"Wayne Township\",'+
            '               \"types\" : [ \"administrative_area_level_3\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"Wayne Township, IL, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9882439,'+
            '                  \"lng\" : -88.144747'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.89923590000001,'+
            '                  \"lng\" : -88.26317809999999'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 41.9154215,'+
            '               \"lng\" : -88.2087628'+
            '            },'+
            '            \"location_type\" : \"APPROXIMATE\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9882439,'+
            '                  \"lng\" : -88.144747'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.89923590000001,'+
            '                  \"lng\" : -88.26317809999999'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJb5GxCKsBD4gR0yAGUWxUr6o\",'+
            '         \"types\" : [ \"administrative_area_level_3\", \"political\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"Dupage County, IL, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.994029,'+
            '                  \"lng\" : -87.91425690000001'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.68533,'+
            '                  \"lng\" : -88.26317809999999'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 41.8243831,'+
            '               \"lng\" : -88.0900762'+
            '            },'+
            '            \"location_type\" : \"APPROXIMATE\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.994029,'+
            '                  \"lng\" : -87.91425690000001'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.68533,'+
            '                  \"lng\" : -88.26317809999999'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJa_8YHt6oD4gRaux4XvaID0k\",'+
            '         \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"Illinois, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 42.5083379,'+
            '                  \"lng\" : -87.01993499999999'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 36.970298,'+
            '                  \"lng\" : -91.5130789'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 40.6331249,'+
            '               \"lng\" : -89.3985283'+
            '            },'+
            '            \"location_type\" : \"APPROXIMATE\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 42.5083379,'+
            '                  \"lng\" : -87.01993499999999'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 36.970298,'+
            '                  \"lng\" : -91.5130789'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJGSZubzgtC4gRVlkRZFCCFX8\",'+
            '         \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"United States\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 71.5388001,'+
            '                  \"lng\" : -66.885417'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 18.7763,'+
            '                  \"lng\" : 170.5957'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 37.09024,'+
            '               \"lng\" : -95.712891'+
            '            },'+
            '            \"location_type\" : \"APPROXIMATE\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 71.5388001,'+
            '                  \"lng\" : -66.885417'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 18.7763,'+
            '                  \"lng\" : 170.5957'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"ChIJCzYy5IS16lQRQrfeQ5K5Oxw\",'+
            '         \"types\" : [ \"country\", \"political\" ]'+
            '      },'+
            '      {'+
            '         \"address_components\" : ['+
            '            {'+
            '               \"long_name\" : \"WR5W+32\",'+
            '               \"short_name\" : \"WR5W+32\",'+
            '               \"types\" : [ \"plus_code\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Carol Stream\",'+
            '               \"short_name\" : \"Carol Stream\",'+
            '               \"types\" : [ \"locality\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"DuPage County\",'+
            '               \"short_name\" : \"Dupage County\",'+
            '               \"types\" : [ \"administrative_area_level_2\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"Illinois\",'+
            '               \"short_name\" : \"IL\",'+
            '               \"types\" : [ \"administrative_area_level_1\", \"political\" ]'+
            '            },'+
            '            {'+
            '               \"long_name\" : \"United States\",'+
            '               \"short_name\" : \"US\",'+
            '               \"types\" : [ \"country\", \"political\" ]'+
            '            }'+
            '         ],'+
            '         \"formatted_address\" : \"WR5W+32 Carol Stream, IL, USA\",'+
            '         \"geometry\" : {'+
            '            \"bounds\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.90775000000001,'+
            '                  \"lng\" : -88.15487499999999'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.907625,'+
            '                  \"lng\" : -88.155'+
            '               }'+
            '            },'+
            '            \"location\" : {'+
            '               \"lat\" : 41.90764799999999,'+
            '               \"lng\" : -88.154962'+
            '            },'+
            '            \"location_type\" : \"ROOFTOP\",'+
            '            \"viewport\" : {'+
            '               \"northeast\" : {'+
            '                  \"lat\" : 41.9090364802915,'+
            '                  \"lng\" : -88.15358851970849'+
            '               },'+
            '               \"southwest\" : {'+
            '                  \"lat\" : 41.90633851970851,'+
            '                  \"lng\" : -88.1562864802915'+
            '               }'+
            '            }'+
            '         },'+
            '         \"place_id\" : \"GhIJ0CNGzy30REAR24e85eoJVsA\",'+
            '         \"plus_code\" : {'+
            '            \"compound_code\" : \"WR5W+32 Carol Stream, IL, USA\",'+
            '            \"global_code\" : \"86HHWR5W+32\"'+
            '         },'+
            '         \"types\" : [ \"plus_code\" ]'+
            '      }'+
            '   ],'+
            '   \"status\" : \"OK\"'+
            '}';
}