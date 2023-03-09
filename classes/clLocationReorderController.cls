public class clLocationReorderController {

    public final static String MAP_KEY_LOCATIONS = 'MAP_KEY_LOCATIONS';

    /**
     * @param sObjectApiName  The parent sObjectApi Name to query. [Route__c or Route_Schedule__c].
     * @param parentRecordId  The parent Id to query for children.
     *
     * @return                A list of clLocationObjects in the response map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveLocations(String sObjectApiName, Id parentRecordId) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += '---> parentRecId='+parentRecordId+'.. sObj='+sObjectApiName;

        List<clLocation> clLocations = new List<clLocation>();
        switch on sObjectApiName {
            when 'Route__c' {
                clLocations = retrieveRouteAccounts(parentRecordId);
            }
            when 'Route_Schedule__c' {
                clLocations = retrieveRouteScheduleAccounts(parentRecordId);
            }
        }
        dto.isSuccess = !clLocations.isEmpty();
        dto.values.put(MAP_KEY_LOCATIONS,clLocations);
        return dto;
    }

    /**
     * @param allRecords All sObjects to update.
     * @return Response dto containing opp info
     */
    @AuraEnabled
    public static ResponseDto doUpdateStopNumbers(List<SObject> allRecords) {
        ResponseDto dto = new ResponseDto();
        Long mStart = SYSTEM.now().millisecond();
        update allRecords;
        Long mEnd = System.now().millisecond();
        dto.technicalMsg += '--> updated '+allRecords.size() + ' records for stop number. total upd time='+ (mEnd - mStart);
        dto.isSuccess = true;
        return dto;
    }

    /**
     * @param parentRecordId  The parent Record Id
     * @return                A list of clLocation which wraps Route_Account__c.
     */
    public static List<clLocation> retrieveRouteAccounts(Id parentRecordId) {
        List<clLocation> clLocations = new List<clLocation>();

        List<Route_Account__c> routeAccounts = [
                SELECT  Id,Route__c,Stop_Number__c,Route__r.Name,
                        Account__r.Access_Time__c,Collection_Type__c,Replenishment_Type__c,
                        Account__c,Account__r.Name,Account__r.ShippingCity,Account__r.ShippingState,Account__r.ShippingStreet,
                        Account__r.ShippingCountry,Account__r.ShippingPostalCode
                FROM    Route_Account__c
                WHERE   Route__c = :parentRecordId
                ORDER BY Stop_Number__c ASC NULLS LAST,
                         Account__r.Name
        ];

        for(Route_Account__c ra : routeAccounts) {
            clLocation clLoc = new clLocation();
            clLoc.recordId = ra.Id;
            clLoc.locName = ra.Account__r.Name;
            clLoc.locId = ra.Account__c;
            clLoc.locAccessTime = ra.Account__r.Access_Time__c;
            clLoc.stopNumber = ra.Stop_Number__c != null ? Integer.valueOf(ra.Stop_Number__c) : 0;
            clLoc.formattedAddress = formatAddress(new clAddy(ra));
            clLoc.formattedLocName = getFormattedLocName(clLoc.locName,clLoc.stopNumber);
            clLoc.parentName = ra.Route__r.Name;
            clLoc.collectionType = ra.Collection_Type__c;
            clLoc.replenishmentType = ra.Replenishment_Type__c;
            clLocations.add(clLoc);
        }
        return clLocations;
    }

    /**
     * @param parentRecordId  The parent Record Id
     * @return                A list of clLocation which wraps Route_Schedule_Account__c.
     */
    public static List<clLocation> retrieveRouteScheduleAccounts(Id parentRecordId) {
        List<clLocation> clLocations = new List<clLocation>();

        List<Route_Schedule_Account__c> routeScheduleAccounts = [
                SELECT  Id,Route_Schedule__c,Stop_Number__c,Route_Schedule__r.Name,
                        Account__r.Access_Time__c,Collection_Type__c,Replenishment_Type__c,
                        Account__c,Account__r.Name,Account__r.ShippingCity,Account__r.ShippingState,Account__r.ShippingStreet,
                        Account__r.ShippingCountry,Account__r.ShippingPostalCode
                FROM    Route_Schedule_Account__c
                WHERE   Route_Schedule__c = :parentRecordId
                ORDER BY Stop_Number__c ASC NULLS LAST,
                        Account__r.Name
        ];
        for(Route_Schedule_Account__c rsa : routeScheduleAccounts) {
            clLocation clLoc = new clLocation();
            clLoc.recordId = rsa.Id;
            clLoc.locName = rsa.Account__r.Name;
            clLoc.locId = rsa.Account__c;
            clLoc.locAccessTime = rsa.Account__r.Access_Time__c;
            clLoc.stopNumber = rsa.Stop_Number__c != null ? Integer.valueOf(rsa.Stop_Number__c) : 0;
            clLoc.formattedAddress = formatAddress(new clAddy(rsa));
            clLoc.formattedLocName = getFormattedLocName(clLoc.locName,clLoc.stopNumber);
            clLoc.parentName = rsa.Route_Schedule__r.Name;
            clLoc.collectionType = rsa.Collection_Type__c;
            clLoc.replenishmentType = rsa.Replenishment_Type__c;
            clLocations.add(clLoc);
        }
        return clLocations;
    }

    /**
     * @param clAddy a clAddy object.
     * @return formatted address string.
     */
    @TestVisible
    private Static String formatAddress(clAddy clAddy) {
        String addy = '';
        if (clAddy != null) {
            addy += clAddy.street;
            addy += ' - ' + clAddy.city;
            addy += ' ' + clAddy.state;
        }
        return addy;
    }

    /**
     * @param locName     The location name (account name).
     * @param stopNumber  The location stop number.
     *
     * @return            A string including the stop name next to the location name.
     */
    @TestVisible
    private static String getFormattedLocName(String locName, Integer stopNumber) {
        String stopText = '';
        if(stopNumber == null) {
            stopNumber = 0;
        }
        stopText = stopNumber != null ? '(' + stopNumber + ') ' : '';
        return stopText + locName;
    }
    /**
     * Wraps either a Route_Account__c or Route_Schedule_Account__c.
     */
    public class clLocation {
        @AuraEnabled public String parentName;
        @AuraEnabled public String locName;
        @AuraEnabled public String locAccessTime;
        @AuraEnabled public String formattedLocName;
        @AuraEnabled public Id locId;
        @AuraEnabled public Id recordId;
        @AuraEnabled public Integer stopNumber;
        @AuraEnabled public String formattedAddress;
        @AuraEnabled public String collectionType;
        @AuraEnabled public String replenishmentType;
    }

    public class clAddy {
        @AuraEnabled public String street;
        @AuraEnabled public String city;
        @AuraEnabled public String state;
        @AuraEnabled public String postalCode;
        @AuraEnabled public String country;

        public clAddy( Route_Account__c ra) {
            this.street = ra.Account__r.ShippingStreet;
            this.city = ra.Account__r.ShippingCity;
            this.state = ra.Account__r.ShippingState;
        }

        public clAddy( Route_Schedule_Account__c rsa) {
            this.street = rsa.Account__r.ShippingStreet;
            this.city = rsa.Account__r.ShippingCity;
            this.state = rsa.Account__r.ShippingState;
        }
    }
}