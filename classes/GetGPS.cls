global class GetGPS implements Queueable, Database.AllowsCallouts {

    //method that gets executed each time the scheduled job runs
    global void execute(QueueableContext ctx){
        //call this class's other functions to get gps updates
        getGPSLocations();
     }
    
    //define method to get authentication token from DriverPoint
    //private so apex code outside of this class cannot access the authentication token to maliciously delete fleet data on DriverPoint
   @TestVisible public String getAuthToken() {
    
        //declare local string var to hold the token
        String token;
        
        //create Httpd request using Accel's DriverPoint Account Credentials
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        Http http = new Http();
        //set httpd request parameters according to the Donlen API specifications  
        req.setEndpoint('https://webservice.donlen.com/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        
        //donlen credentials for API access
        String username = System.label.GPSusername;
        String pass = System.label.GPSlabel;
        
        //format a http request string in XML format according to the Donlen API specifications 
        String xmlRequestString = '<?xml version="1.0"?> <WebServiceRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="D:\\development\\primary\\src\\xsd\\WebServiceRequestMetaData.xsd"> <RequestAuthorization Token="" Version="1"/> <Request RequestName="GET_AUTHENTICATION_TOKEN"> <RequestParameters> <RequestParameter ParameterId="ID" ParameterValue="'+username+'"/> <RequestParameter ParameterId="PASSWORD" ParameterValue="'+pass+'"/> </RequestParameters> </Request> </WebServiceRequest> ';
        //encode it according to the Donlen API specifications
        req.setBody('xmls=' + EncodingUtil.urlEncode(xmlRequestString, 'UTF-8'));
        
        //send the http request and store the resulting reponse in an httpresponse object
        resp = http.send(req);
        
        //for testing purposes
        //System.debug(resp.getBody());
        //System.debug(EncodingUtil.urlDecode(resp.getBody(), 'UTF-8'));
       
        //parse the response to be able to extract the authentication token by loading the response as XML nodes in a Dom Document
        Dom.Document doc = new Dom.Document();
        doc.load(resp.getBody());
        //hard coded the element order of the response string according to the Donlen API specifications for easy token extraction
        Dom.XMLNode webserviceresponse = doc.getRootElement();
        Dom.XMLNode response = webserviceresponse.getChildElement('response', null);
        Dom.XMLNode responseList = response.getChildElement('responseList', null);
        Dom.XMLNode responseItem = responseList.getChildElement('responseItem', null);
        token = responseItem.getAttributeValue('value', null);
        
        //return the authentication token
        return token;
    }
    
    public void getGPSLocations() {
    
        //declare local string var to hold the authentication token
        String token;
        if(Test.isRunningTest()){
            token='12345';
        }else{
            token = getAuthToken();    
            }   
        
        List<ServiceResource> techs = [select id, trackerid__c, lastknownlatitude, lastknownlongitude, activitystatus__c from ServiceResource where trackerid__c != null];
        List<CollectionVehicle__c> vehicles = [select id, DVN__c, Location__Latitude__s, Location__Longitude__s, activitystatus__c from CollectionVehicle__c];
        List<ServiceTerritoryMember> members = [select id, ServiceResourceId, Latitude, Longitude from ServiceTerritoryMember];
        List<GPStracking__c> newtrackingrecords = new List<GPSTracking__c>();
        
        //create Httpd request
        HttpRequest req = new HttpRequest();
        HttpResponse resp = new HttpResponse();
        Http http = new Http();
        
        req.setEndpoint('https://webservice.donlen.com/');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/x-www-form-urlencoded');
 
        //format a http request string in XML format according to the Donlen API specifications
        String xmlRequestString = '<?xml version="1.0"?> <WebServiceRequest xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="D:\\development\\primary\\src\\xsd\\WebServiceRequestMetaData.xsd"> <RequestAuthorization Token="'+token+'" Version="1"/> <Request RequestName="GET_COMPANY_LAST_LOCATION"> </Request> </WebServiceRequest> ';
        //encode it according to the Donlen API specifications
        req.setBody('xmls=' + EncodingUtil.urlEncode(xmlRequestString, 'UTF-8'));  
        //send the http request and store the resulting reponse in an httpresponse object
        resp = http.send(req);
        //for testing purposes only
        //System.debug(resp.getBody());
        
        //load the response into a Document object to iterate through and pull the data from
        Dom.Document doc = new Dom.Document();
        doc.load(resp.getBody());
        Dom.XMLNode webserviceresponse = doc.getRootElement();
        Dom.XMLNode response = webserviceresponse.getChildElement('response', null);
        //loop through the xml response and set GPS data to the technicians list
        for(Dom.XMLNode responseListChild : response.getChildElements()){
            //first responseItem will be DVN, check ID
            Dom.XMLNode firstResponseItem = responseListChild.getChildElement('responseItem', null);
            String dvnId = firstResponseItem.getAttributeValue('value', null);
            //find the tech with that dvn if exists
            for(integer i=0; i<techs.size(); i++){
            if(dvnId != null){
                if(dvnId.equals(techs[i].trackerid__c)){
                    //System.debug('Found Match at'+techs[i].id);
                    for(Dom.XMLNode dvnResponseItems : responseListChild.getChildElements()){
                        String dvnAttr = dvnResponseItems.getAttributeValue('id', null);
                        if(dvnAttr.contains('LastLatitude')){
                            //System.Debug('Lat: '+dvnResponseItems.getAttributeValue('value', null));
                            techs[i].lastknownlatitude = Double.valueOf(dvnResponseItems.getAttributeValue('value', null));
                        }else if(dvnAttr.contains('LastLongitude')){
                            //System.Debug('Long: '+dvnResponseItems.getAttributeValue('value', null));
                            techs[i].lastknownlongitude = Double.valueOf(dvnResponseItems.getAttributeValue('value', null));
                        }else if(dvnAttr.contains('ActivityType')){
                            //System.Debug('ActivityType: '+dvnResponseItems.getAttributeValue('value', null));
                            techs[i].activitystatus__c = dvnResponseItems.getAttributeValue('value', null);
                        }
                    }
                }
               }
            }
        }
        
        //loop through the xml response and set GPS data for collectionvehicles
        for(Dom.XMLNode responseListChild : response.getChildElements()){
            //first responseItem will be DVN, check ID
            Dom.XMLNode firstResponseItem = responseListChild.getChildElement('responseItem', null);
            String dvnId = firstResponseItem.getAttributeValue('value', null);
            //find the collection vehicle with that dvn if exists
            for(integer i=0; i<vehicles.size(); i++){
                if(dvnId != null){
                if(dvnId.equals(vehicles[i].DVN__c)){
                    //System.debug('Found Match at '+vehicles[i].id);
                    //store old status before changing values to see if new tracking record is needed
                    String oldstatus = vehicles[i].activitystatus__c;
                    for(Dom.XMLNode dvnResponseItems : responseListChild.getChildElements()){
                        String dvnAttr = dvnResponseItems.getAttributeValue('id', null);
                        if(dvnAttr.contains('LastLatitude')){
                            //System.Debug('Lat: '+dvnResponseItems.getAttributeValue('value', null));
                            vehicles[i].Location__Latitude__s = Double.valueOf(dvnResponseItems.getAttributeValue('value', null));
                        }else if(dvnAttr.contains('LastLongitude')){
                            //System.Debug('Long: '+dvnResponseItems.getAttributeValue('value', null));
                            vehicles[i].Location__Longitude__s = Double.valueOf(dvnResponseItems.getAttributeValue('value', null));
                        }else if(dvnAttr.contains('ActivityType')){
                            //System.Debug('ActivityType: '+dvnResponseItems.getAttributeValue('value', null));
                            vehicles[i].activitystatus__c = dvnResponseItems.getAttributeValue('value', null);
                        }
                    }
                    //check to see if status updated, if so create new tracking record
                    if(vehicles[i].activitystatus__c != oldstatus){
                        GPSTracking__c g = new GPSTracking__C(CollectionVehicle__c = vehicles[i].id, Location__Latitude__s = vehicles[i].Location__Latitude__s, Location__Longitude__s = vehicles[i].Location__Longitude__s, Timestamp__c = Datetime.now(), ActivityStatus__c = vehicles[i].activitystatus__c);
                        newtrackingrecords.add(g);
                    }
                }
            }
            }
        }
        
        //for each tech, find the corresponding service territory member and update that homebase
        for(integer i=0; i<techs.size(); i++){       
            for(integer j=0; j<members.size(); j++){
                if(techs[i].id == members[j].ServiceResourceId){
                    //found the match, update the lat and long fields   
                    members[j].latitude = techs[i].lastknownlatitude;
                    members[j].longitude = techs[i].lastknownlongitude;
                }
            }
        }
        //update techs and territory member records to salesforce
        try {
            update techs;
            //update members; changed 8/27/22 for West Monroe FSL rollout
            //update vehicles; changed 8/27/22 for West Monroe FSL rollout
            //insert newtrackingrecords; changed 8/27/22 for West Monroe FSL rollout
        } catch(DmlException e){
            System.debug('Update failed');
            List<String> emailAddys = new List<String>();
            emailAddys.add('zacharym@accelentertainment.com');
            String emsg = e.getNumDml() + 'x ' + e.getDmlMessage(0) +' errors.\n' + 'Fields: '+e.getDmlFieldNames(0);
            EmailSvc.sendEmail(emailAddys, null, 'GPS DML Errors', emsg);
            for(integer i = 0; i < e.getNumDML(); i++){
              system.debug('***** The error message ' + e.getDMLMessage(i));
             }     
        }
    }
}