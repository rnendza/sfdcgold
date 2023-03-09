@IsTest
public class TEST_GoogleGeocodeJsonToApex {


    static testMethod void testParse() {
        GoogleGeoCodeJsonToApex obj = GoogleGeoCodeJsonToApex.parse(testJsonValidMuni);
        System.assert(obj != null);
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

    public static String testJsonInValidMuni ='{'+
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
            '               \"long_name\" : \"Carolxxx Streamxxx\",'+
            '               \"short_name\" : \"Carolxxx Streamxxx\",'+
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
            '               \"long_name\" : \"Carolxxx Streamxxx\",'+
            '               \"short_name\" : \"Carolxxx Streamxxx\",'+
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

            public static String testJsonValidMuniPATownship = '{"status":"OK","results":[{"types":["street_address"],"postcode_localities":null,"plus_code":{"global_code":"87G65WMR+FC","compound_code":"5WMR+FC Warminster, PA, USA"},"place_id":"ChIJO4_xB9WtxokRuP6B-9BDw7g","geometry":{"viewport":{"southwest":{"lng":-75.06023548029151,"lat":40.18237951970851},"northeast":{"lng":-75.05753751970849,"lat":40.18507748029151}},"location_type":"ROOFTOP","location":{"lng":-75.0588865,"lat":40.18372850000001}},"formatted_address":"854 E Street Rd, Warminster, PA 18974, USA","address_components":[{"types":["street_number"],"short_name":"854","long_name":"854"},{"types":["route"],"short_name":"E Street Rd","long_name":"East Street Road"},{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]},{"types":["convenience_store","establishment","food","gas_station","point_of_interest","store"],"postcode_localities":null,"plus_code":{"global_code":"87G65WMR+FC","compound_code":"5WMR+FC Warminster, PA, USA"},"place_id":"ChIJGQdqkn-uxokRV8ocWHvKRXY","geometry":{"viewport":{"southwest":{"lng":-75.0602930802915,"lat":40.1823575197085},"northeast":{"lng":-75.0575951197085,"lat":40.1850554802915}},"location_type":"ROOFTOP","location":{"lng":-75.05894409999999,"lat":40.1837065}},"formatted_address":"890 E Street Rd, Warminster, PA 18974, USA","address_components":[{"types":["street_number"],"short_name":"890","long_name":"890"},{"types":["route"],"short_name":"E Street Rd","long_name":"East Street Road"},{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]},{"types":["street_address"],"postcode_localities":null,"plus_code":null,"place_id":"EiU4OTAgUEEtMTMyLCBXYXJtaW5zdGVyLCBQQSAxODk3NCwgVVNBIhsSGQoUChIJqYD1ptWtxokRJVfBQyK9sAwQ-gY","geometry":{"viewport":{"southwest":{"lng":-75.0604772802915,"lat":40.1821948197085},"northeast":{"lng":-75.05777931970849,"lat":40.1848927802915}},"location_type":"RANGE_INTERPOLATED","location":{"lng":-75.0591283,"lat":40.1835438}},"formatted_address":"890 PA-132, Warminster, PA 18974, USA","address_components":[{"types":["street_number"],"short_name":"890","long_name":"890"},{"types":["route"],"short_name":"PA-132","long_name":"Pennsylvania 132"},{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]},{"types":["route"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJqYD1ptWtxokRJFfBQyK9sAw","geometry":{"viewport":{"southwest":{"lng":-75.0604559302915,"lat":40.1821806697085},"northeast":{"lng":-75.05775796970849,"lat":40.1848786302915}},"location_type":"GEOMETRIC_CENTER","location":{"lng":-75.0591069,"lat":40.1835297}},"formatted_address":"E Street Rd, Warminster, PA 18974, USA","address_components":[{"types":["route"],"short_name":"PA-132","long_name":"East Street Road"},{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]},{"types":["locality","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJn9qVo-6uxokRjZ6iLcwxNAI","geometry":{"viewport":{"southwest":{"lng":-75.1377819,"lat":40.171033},"northeast":{"lng":-75.0438021,"lat":40.2378098}},"location_type":"APPROXIMATE","location":{"lng":-75.099807,"lat":40.2067884}},"formatted_address":"Warminster, PA 18974, USA","address_components":[{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]},{"types":["administrative_area_level_3","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJn9qVo-6uxokRNT1AKUsv8RA","geometry":{"viewport":{"southwest":{"lng":-75.1377819,"lat":40.171033},"northeast":{"lng":-75.0438021,"lat":40.2378098}},"location_type":"APPROXIMATE","location":{"lng":-75.0903154,"lat":40.2053679}},"formatted_address":"Warminster Township, PA 18974, USA","address_components":[{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]},{"types":["postal_code"],"postcode_localities":["Hartsville","Ivyland","Warminster","Warwick"],"plus_code":null,"place_id":"ChIJwWJ5KaWuxokRYhb5KXkU2XA","geometry":{"viewport":{"southwest":{"lng":-75.1377819,"lat":40.1706329},"northeast":{"lng":-75.0085649,"lat":40.255783}},"location_type":"APPROXIMATE","location":{"lng":-75.07279559999999,"lat":40.2180742}},"formatted_address":"Ivyland, PA 18974, USA","address_components":[{"types":["postal_code"],"short_name":"18974","long_name":"18974"},{"types":["locality","political"],"short_name":"Ivyland","long_name":"Ivyland"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_2","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJHw5nt85GxIkRE6dc-_7kG54","geometry":{"viewport":{"southwest":{"lng":-75.48405679999999,"lat":40.048595},"northeast":{"lng":-74.721519,"lat":40.6085799}},"location_type":"APPROXIMATE","location":{"lng":-75.2479061,"lat":40.4107964}},"formatted_address":"Bucks County, PA, USA","address_components":[{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_1","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJieUyHiaALYgRPbQiUEchRsI","geometry":{"viewport":{"southwest":{"lng":-80.51989499999999,"lat":39.7197989},"northeast":{"lng":-74.6895018,"lat":42.5141658}},"location_type":"APPROXIMATE","location":{"lng":-77.1945247,"lat":41.2033216}},"formatted_address":"Pennsylvania, USA","address_components":[{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["country","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJCzYy5IS16lQRQrfeQ5K5Oxw","geometry":{"viewport":{"southwest":{"lng":170.5957,"lat":18.7763},"northeast":{"lng":-66.885417,"lat":71.5388001}},"location_type":"APPROXIMATE","location":{"lng":-95.712891,"lat":37.09024}},"formatted_address":"United States","address_components":[{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["plus_code"],"postcode_localities":null,"plus_code":{"global_code":"87G65WMR+GF","compound_code":"5WMR+GF Warminster, PA, USA"},"place_id":"GhIJ36P-eoUXREAR0QSKWMTDUsA","geometry":{"viewport":{"southwest":{"lng":-75.06016148029151,"lat":40.18246351970849},"northeast":{"lng":-75.0574635197085,"lat":40.18516148029149}},"location_type":"ROOFTOP","location":{"lng":-75.058859,"lat":40.183761}},"formatted_address":"5WMR+GF Warminster, PA, USA","address_components":[{"types":["plus_code"],"short_name":"5WMR+GF","long_name":"5WMR+GF"},{"types":["locality","political"],"short_name":"Warminster","long_name":"Warminster"},{"types":["administrative_area_level_3","political"],"short_name":"Warminster Township","long_name":"Warminster Township"},{"types":["administrative_area_level_2","political"],"short_name":"Bucks County","long_name":"Bucks County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18974","long_name":"18974"}]}],"plus_code":{"global_code":"87G65WMR+GF","compound_code":"5WMR+GF Warminster, PA, USA"}}';
            public static String testJsonValidMuniPABorough = '{"status":"OK","results":[{"types":["accounting","establishment","finance","point_of_interest"],"postcode_localities":null,"plus_code":{"global_code":"87H25WF2+23","compound_code":"5WF2+23 Brookville, PA, USA"},"place_id":"ChIJAQ6QU2_BzIkRJkzFUI0iP2k","geometry":{"viewport":{"southwest":{"lng":-79.1012185802915,"lat":41.1712284197085},"northeast":{"lng":-79.0985206197085,"lat":41.1739263802915}},"location_type":"ROOFTOP","location":{"lng":-79.09986959999999,"lat":41.1725774}},"formatted_address":"245 Allegheny Blvd, Brookville, PA 15825, USA","address_components":[{"types":["street_number"],"short_name":"245","long_name":"245"},{"types":["route"],"short_name":"Allegheny Blvd","long_name":"Allegheny Boulevard"},{"types":["locality","political"],"short_name":"Brookville","long_name":"Brookville"},{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"15825","long_name":"15825"},{"types":["postal_code_suffix"],"short_name":"1535","long_name":"1535"}]},{"types":["street_address"],"postcode_localities":null,"plus_code":null,"place_id":"Ei0yMTUgQWxsZWdoZW55IEJsdmQsIEJyb29rdmlsbGUsIFBBIDE1ODI1LCBVU0EiGxIZChQKEgl_HzJK5cPMiRF0iPe2XBKerxDXAQ","geometry":{"viewport":{"southwest":{"lng":-79.09950928029149,"lat":41.1708421197085},"northeast":{"lng":-79.09681131970848,"lat":41.1735400802915}},"location_type":"RANGE_INTERPOLATED","location":{"lng":-79.09816029999999,"lat":41.1721911}},"formatted_address":"215 Allegheny Blvd, Brookville, PA 15825, USA","address_components":[{"types":["street_number"],"short_name":"215","long_name":"215"},{"types":["route"],"short_name":"Allegheny Blvd","long_name":"Allegheny Boulevard"},{"types":["locality","political"],"short_name":"Brookville","long_name":"Brookville"},{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"15825","long_name":"15825"},{"types":["postal_code_suffix"],"short_name":"2551","long_name":"2551"}]},{"types":["route"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJ3d2aSfrDzIkRCMowpUWoRsg","geometry":{"viewport":{"southwest":{"lng":-79.1040046802915,"lat":41.1701947197085},"northeast":{"lng":-79.10130671970849,"lat":41.1728926802915}},"location_type":"GEOMETRIC_CENTER","location":{"lng":-79.1026607,"lat":41.1715294}},"formatted_address":"Z. H. Confair Memorial Hwy, Brookville, PA 15825, USA","address_components":[{"types":["route"],"short_name":"Interstate 80","long_name":"Z. H. Confair Memorial Highway"},{"types":["locality","political"],"short_name":"Brookville","long_name":"Brookville"},{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"15825","long_name":"15825"}]},{"types":["locality","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJAxAbaDzCzIkR3lxgxF4Yuss","geometry":{"viewport":{"southwest":{"lng":-79.10478189999999,"lat":41.1426389},"northeast":{"lng":-79.0634098,"lat":41.177765}},"location_type":"APPROXIMATE","location":{"lng":-79.0830924,"lat":41.1611746}},"formatted_address":"Brookville, PA 15825, USA","address_components":[{"types":["locality","political"],"short_name":"Brookville","long_name":"Brookville"},{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"15825","long_name":"15825"}]},{"types":["postal_code"],"postcode_localities":["Brookville","Hazen"],"plus_code":null,"place_id":"ChIJ7wOt8BXCzIkR2vc6lA6o7nE","geometry":{"viewport":{"southwest":{"lng":-79.198691,"lat":41.02841},"northeast":{"lng":-78.92565599999999,"lat":41.325821}},"location_type":"APPROXIMATE","location":{"lng":-79.0419053,"lat":41.1778033}},"formatted_address":"Hazen, PA 15825, USA","address_components":[{"types":["postal_code"],"short_name":"15825","long_name":"15825"},{"types":["locality","political"],"short_name":"Hazen","long_name":"Hazen"},{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_2","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJG0U4It3pzIkRm_wUxTgIM5g","geometry":{"viewport":{"southwest":{"lng":-79.21570609999999,"lat":40.9059709},"northeast":{"lng":-78.7100591,"lat":41.376565}},"location_type":"APPROXIMATE","location":{"lng":-78.9288242,"lat":41.147013}},"formatted_address":"Jefferson County, PA, USA","address_components":[{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_1","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJieUyHiaALYgRPbQiUEchRsI","geometry":{"viewport":{"southwest":{"lng":-80.51989499999999,"lat":39.7197989},"northeast":{"lng":-74.6895018,"lat":42.5141658}},"location_type":"APPROXIMATE","location":{"lng":-77.1945247,"lat":41.2033216}},"formatted_address":"Pennsylvania, USA","address_components":[{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["country","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJCzYy5IS16lQRQrfeQ5K5Oxw","geometry":{"viewport":{"southwest":{"lng":170.5957,"lat":18.7763},"northeast":{"lng":-66.885417,"lat":71.5388001}},"location_type":"APPROXIMATE","location":{"lng":-95.712891,"lat":37.09024}},"formatted_address":"United States","address_components":[{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["plus_code"],"postcode_localities":null,"plus_code":{"global_code":"87H25VFX+3Q","compound_code":"5VFX+3Q Brookville, PA, USA"},"place_id":"GhIJh22LMhuWREAR3htDAHDGU8A","geometry":{"viewport":{"southwest":{"lng":-79.10191148029149,"lat":41.1713385197085},"northeast":{"lng":-79.09921351970848,"lat":41.1740364802915}},"location_type":"ROOFTOP","location":{"lng":-79.10058599999999,"lat":41.172705}},"formatted_address":"5VFX+3Q Brookville, PA, USA","address_components":[{"types":["plus_code"],"short_name":"5VFX+3Q","long_name":"5VFX+3Q"},{"types":["locality","political"],"short_name":"Brookville","long_name":"Brookville"},{"types":["administrative_area_level_2","political"],"short_name":"Jefferson County","long_name":"Jefferson County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"15825","long_name":"15825"}]}],"plus_code":{"global_code":"87H25VFX+3Q","compound_code":"5VFX+3Q Brookville, PA, USA"}}';
            public static String testJsonValidMuniStreetNumber = '{"status":"OK","results":[{"types":["premise"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJteiq48Yn24kRB3ol7S6U6Fg","geometry":{"viewport":{"southwest":{"lng":-75.68416513029152,"lat":41.8234650697085},"northeast":{"lng":-75.68146716970851,"lat":41.8261630302915}},"location_type":"ROOFTOP","location":{"lng":-75.6828306,"lat":41.8248027}},"formatted_address":"1623 Oliver Rd, New Milford, PA 18834, USA","address_components":[{"types":["street_number"],"short_name":"1623","long_name":"1623"},{"types":["route"],"short_name":"Oliver Rd","long_name":"Oliver Road"},{"types":["locality","political"],"short_name":"New Milford","long_name":"New Milford"},{"types":["administrative_area_level_3","political"],"short_name":"New Milford Township","long_name":"New Milford Township"},{"types":["administrative_area_level_2","political"],"short_name":"Susquehanna County","long_name":"Susquehanna County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18834","long_name":"18834"}]},{"types":["route"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJNWjaB8cn24kRHtJQdziLk98","geometry":{"viewport":{"southwest":{"lng":-75.68337643029149,"lat":41.8241092197085},"northeast":{"lng":-75.68067846970848,"lat":41.8268071802915}},"location_type":"GEOMETRIC_CENTER","location":{"lng":-75.6820281,"lat":41.8254578}},"formatted_address":"PA-848, New Milford, PA 18834, USA","address_components":[{"types":["route"],"short_name":"PA-848","long_name":"Harford Road"},{"types":["locality","political"],"short_name":"New Milford","long_name":"New Milford"},{"types":["administrative_area_level_3","political"],"short_name":"New Milford Township","long_name":"New Milford Township"},{"types":["administrative_area_level_2","political"],"short_name":"Susquehanna County","long_name":"Susquehanna County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18834","long_name":"18834"}]},{"types":["administrative_area_level_3","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJ2QTOEJ3Y2okRhW_J-M3Arf0","geometry":{"viewport":{"southwest":{"lng":-75.79230609999999,"lat":41.8130459},"northeast":{"lng":-75.6409159,"lat":41.9102429}},"location_type":"APPROXIMATE","location":{"lng":-75.6906241,"lat":41.8673559}},"formatted_address":"New Milford Township, PA, USA","address_components":[{"types":["administrative_area_level_3","political"],"short_name":"New Milford Township","long_name":"New Milford Township"},{"types":["administrative_area_level_2","political"],"short_name":"Susquehanna County","long_name":"Susquehanna County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["postal_code"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJnRUyxnjY2okR-79PqyWERco","geometry":{"viewport":{"southwest":{"lng":-75.84827,"lat":41.7277699},"northeast":{"lng":-75.6410339,"lat":41.94344900000001}},"location_type":"APPROXIMATE","location":{"lng":-75.737149,"lat":41.8342853}},"formatted_address":"New Milford, PA 18834, USA","address_components":[{"types":["postal_code"],"short_name":"18834","long_name":"18834"},{"types":["locality","political"],"short_name":"New Milford","long_name":"New Milford"},{"types":["administrative_area_level_2","political"],"short_name":"Susquehanna County","long_name":"Susquehanna County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_2","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJYwlwWhzV2okRAiKwREhhcHc","geometry":{"viewport":{"southwest":{"lng":-76.1468491,"lat":41.641411},"northeast":{"lng":-75.462411,"lat":41.9992829}},"location_type":"APPROXIMATE","location":{"lng":-75.8069082,"lat":41.745553}},"formatted_address":"Susquehanna County, PA, USA","address_components":[{"types":["administrative_area_level_2","political"],"short_name":"Susquehanna County","long_name":"Susquehanna County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_1","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJieUyHiaALYgRPbQiUEchRsI","geometry":{"viewport":{"southwest":{"lng":-80.51989499999999,"lat":39.7197989},"northeast":{"lng":-74.6895018,"lat":42.5141658}},"location_type":"APPROXIMATE","location":{"lng":-77.1945247,"lat":41.2033216}},"formatted_address":"Pennsylvania, USA","address_components":[{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["country","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJCzYy5IS16lQRQrfeQ5K5Oxw","geometry":{"viewport":{"southwest":{"lng":170.5957,"lat":18.7763},"northeast":{"lng":-66.885417,"lat":71.5388001}},"location_type":"APPROXIMATE","location":{"lng":-95.712891,"lat":37.09024}},"formatted_address":"United States","address_components":[{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["plus_code"],"postcode_localities":null,"plus_code":{"global_code":"87H6R8F8+XR","compound_code":"R8F8+XR Gibson, PA, USA"},"place_id":"GhIJYAMixJXpREARVkj5SbXrUsA","geometry":{"viewport":{"southwest":{"lng":-75.6842864802915,"lat":41.8235885197085},"northeast":{"lng":-75.6815885197085,"lat":41.8262864802915}},"location_type":"ROOFTOP","location":{"lng":-75.68294,"lat":41.824883}},"formatted_address":"R8F8+XR Gibson, PA, USA","address_components":[{"types":["plus_code"],"short_name":"R8F8+XR","long_name":"R8F8+XR"},{"types":["locality","political"],"short_name":"Gibson","long_name":"Gibson"},{"types":["administrative_area_level_3","political"],"short_name":"Gibson Township","long_name":"Gibson Township"},{"types":["administrative_area_level_2","political"],"short_name":"Susquehanna County","long_name":"Susquehanna County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18847","long_name":"18847"}]}],"plus_code":{"global_code":"87H6R8F8+XR","compound_code":"R8F8+XR Gibson, PA, USA"}}';
            public static String testJsonValidMuniPremise = '{"status":"OK","results":[{"types":["premise"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJFcODpgAbxYkRhHz73GAddyM","geometry":{"viewport":{"southwest":{"lng":-75.84984458029152,"lat":41.2392133197085},"northeast":{"lng":-75.8471466197085,"lat":41.2419112802915}},"location_type":"ROOFTOP","location":{"lng":-75.8484932,"lat":41.2403841}},"formatted_address":"255 Highland Park Blvd, Wilkes-Barre Township, PA 18702, USA","address_components":[{"types":["street_number"],"short_name":"255","long_name":"255"},{"types":["route"],"short_name":"Highland Park Blvd","long_name":"Highland Park Boulevard"},{"types":["locality","political"],"short_name":"Wilkes-Barre Township","long_name":"Wilkes-Barre Township"},{"types":["administrative_area_level_2","political"],"short_name":"Luzerne County","long_name":"Luzerne County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18702","long_name":"18702"},{"types":["postal_code_suffix"],"short_name":"6769","long_name":"6769"}]},{"types":["establishment","point_of_interest"],"postcode_localities":null,"plus_code":{"global_code":"87H665R2+6H","compound_code":"65R2+6H Wilkes-Barre Township, PA, USA"},"place_id":"ChIJV1eG2AEbxYkRQCruAXC5ndY","geometry":{"viewport":{"southwest":{"lng":-75.8498999802915,"lat":41.2391870197085},"northeast":{"lng":-75.84720201970849,"lat":41.2418849802915}},"location_type":"ROOFTOP","location":{"lng":-75.848551,"lat":41.240536}},"formatted_address":"255 Highland Park Blvd, Wilkes-Barre Township, PA 18702, USA","address_components":[{"types":["street_number"],"short_name":"255","long_name":"255"},{"types":["route"],"short_name":"Highland Park Blvd","long_name":"Highland Park Boulevard"},{"types":["locality","political"],"short_name":"Wilkes-Barre Township","long_name":"Wilkes-Barre Township"},{"types":["administrative_area_level_2","political"],"short_name":"Luzerne County","long_name":"Luzerne County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18702","long_name":"18702"}]},{"types":["route"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJZYApD6obxYkR5IaqFTCnqzI","geometry":{"viewport":{"southwest":{"lng":-75.8497154302915,"lat":41.2398345197085},"northeast":{"lng":-75.84701746970849,"lat":41.2425324802915}},"location_type":"GEOMETRIC_CENTER","location":{"lng":-75.8483352,"lat":41.2412044}},"formatted_address":"Unnamed Road, Wilkes-Barre Township, PA 18702, USA","address_components":[{"types":["route"],"short_name":"Unnamed Road","long_name":"Unnamed Road"},{"types":["locality","political"],"short_name":"Wilkes-Barre Township","long_name":"Wilkes-Barre Township"},{"types":["administrative_area_level_2","political"],"short_name":"Luzerne County","long_name":"Luzerne County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"},{"types":["postal_code"],"short_name":"18702","long_name":"18702"}]},{"types":["locality","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJA0BPqoMDxYkRMXMSfuqMvYY","geometry":{"viewport":{"southwest":{"lng":-75.8938409,"lat":41.215281},"northeast":{"lng":-75.82613909999999,"lat":41.2520809}},"location_type":"APPROXIMATE","location":{"lng":-75.86967539999999,"lat":41.2285305}},"formatted_address":"Wilkes-Barre Township, PA, USA","address_components":[{"types":["locality","political"],"short_name":"Wilkes-Barre Township","long_name":"Wilkes-Barre Township"},{"types":["administrative_area_level_2","political"],"short_name":"Luzerne County","long_name":"Luzerne County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["postal_code"],"postcode_localities":["Bear Creek Village","Hilldale","Hudson","Korn Krest","Plains","Wilkes-Barre","Wilkes-Barre Township"],"plus_code":null,"place_id":"ChIJA0BPqoMDxYkRdncweq6IHI8","geometry":{"viewport":{"southwest":{"lng":-75.9564098,"lat":41.1253509},"northeast":{"lng":-75.6210909,"lat":41.3047981}},"location_type":"APPROXIMATE","location":{"lng":-75.87835679999999,"lat":41.24262}},"formatted_address":"Wilkes-Barre Township, PA 18702, USA","address_components":[{"types":["postal_code"],"short_name":"18702","long_name":"18702"},{"types":["locality","political"],"short_name":"Wilkes-Barre Township","long_name":"Wilkes-Barre Township"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_2","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJT8UL4YF0xYkRY-bZsVwaZh4","geometry":{"viewport":{"southwest":{"lng":-76.31973599999999,"lat":40.901986},"northeast":{"lng":-75.6005771,"lat":41.4272459}},"location_type":"APPROXIMATE","location":{"lng":-75.9927652,"lat":41.1404353}},"formatted_address":"Luzerne County, PA, USA","address_components":[{"types":["administrative_area_level_2","political"],"short_name":"Luzerne County","long_name":"Luzerne County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["administrative_area_level_1","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJieUyHiaALYgRPbQiUEchRsI","geometry":{"viewport":{"southwest":{"lng":-80.51989499999999,"lat":39.7197989},"northeast":{"lng":-74.6895018,"lat":42.5141658}},"location_type":"APPROXIMATE","location":{"lng":-77.1945247,"lat":41.2033216}},"formatted_address":"Pennsylvania, USA","address_components":[{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["country","political"],"postcode_localities":null,"plus_code":null,"place_id":"ChIJCzYy5IS16lQRQrfeQ5K5Oxw","geometry":{"viewport":{"southwest":{"lng":170.5957,"lat":18.7763},"northeast":{"lng":-66.885417,"lat":71.5388001}},"location_type":"APPROXIMATE","location":{"lng":-95.712891,"lat":37.09024}},"formatted_address":"United States","address_components":[{"types":["country","political"],"short_name":"US","long_name":"United States"}]},{"types":["plus_code"],"postcode_localities":null,"plus_code":{"global_code":"87H665R2+9R","compound_code":"65R2+9R Wilkes-Barre Township, PA, USA"},"place_id":"GhIJAiuHFtmeREAR0ZFc_kP2UsA","geometry":{"viewport":{"southwest":{"lng":-75.84928648029152,"lat":41.2395885197085},"northeast":{"lng":-75.8465885197085,"lat":41.2422864802915}},"location_type":"ROOFTOP","location":{"lng":-75.8479,"lat":41.241}},"formatted_address":"65R2+9R Wilkes-Barre Township, PA, USA","address_components":[{"types":["plus_code"],"short_name":"65R2+9R","long_name":"65R2+9R"},{"types":["locality","political"],"short_name":"Wilkes-Barre Township","long_name":"Wilkes-Barre Township"},{"types":["administrative_area_level_2","political"],"short_name":"Luzerne County","long_name":"Luzerne County"},{"types":["administrative_area_level_1","political"],"short_name":"PA","long_name":"Pennsylvania"},{"types":["country","political"],"short_name":"US","long_name":"United States"}]}],"plus_code":{"global_code":"87H665R2+9R","compound_code":"65R2+9R Wilkes-Barre Township, PA, USA"}}';
}