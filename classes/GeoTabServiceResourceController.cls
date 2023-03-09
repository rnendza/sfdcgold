/**
 * User Interface facing class for GeoTab (BlueArrow) GPS and SFDC Service Resources.
 * Currently will assist in building a picklist / search box for all service resource with geoTabIds.
 * Will also return ServiceResourceHistory wrappers for selected Service Resources.
 *
 * @see ServiceResourceSvc
 * @see GeoTabServiceResourceControllerTest
 */
public class GeoTabServiceResourceController {

    public static String                MAP_KEY_SERVICE_RESOURCE_USERS  = 'SERVICE_RESOURCE_USER_WRAPS';
    public static String                MAP_KEY_SERVICE_RESOURCE_HIST   = 'SERVICE_RESOURCE_HISTORY_WRAPS';
    public static String                MAP_KEY_TRACKED_FIELD_WRAPS     = 'SERVICE_RESOURCE_TRACKED_FIELD_WRAPS';
    public static Integer               DEFAULT_HIST_ROW_LIMIT          = 200;
    public static String                DEFAULT_HIST_FIELD_API_NAME     = 'LastKnownLocationDate';

    /**
     * Retrieves a list of all service resource records that have a geotab device id or tracker id and are active
     * (Id,Name only) suitable for search / picklists.
     *
     * @return A ResponseDto object with a List of ServiceResourceUserWrapper objects in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveGpsServiceResourceUsers() {
        ResponseDto dto = new ResponseDto();
        List<ServiceResource> serviceResourceUsers = ServiceResourceSvc.retrieveGpsServiceResourceNames();
        List<ServiceResourceUserWrapper> serviceResourceUserWrappers = buildServiceResourceUserWrappers(serviceResourceUsers);
        dto.isSuccess = !serviceResourceUserWrappers.isEmpty();
        dto.values.put(MAP_KEY_SERVICE_RESOURCE_USERS,serviceResourceUserWrappers);
        return dto;
    }

    /**
     *
     * Retrieves a list of all history records on change of LastKnownLocationDate for the passed Service Resource Id.
     *
     * @param serviceResourceId     The ServiceResource.Id value to search for.
     * @param fieldApiName          The tracked field api name.`
     * @param iLimit                The limit on the History sObject query.
     *
     * @return A ResponseDto object with a List of HistoryWrapper objects in the values map.
     */
    @AuraEnabled
    public static ResponseDto retrieveServiceResourceHistories(Id serviceResourceId,List<String> fieldApiNames,Integer iLimit) {
        Set<String> sFieldApiNames = new Set<String>();
        sFieldApiNames.addAll(fieldApiNames);
        return retrieveServiceResourceHistories(serviceResourceId,sFieldApiNames,iLimit);
    }

    /**
     *
     * Retrieves a list of all history records on change of fields in fieldApis passed for the passed
     * Service Resource Ids.
     *
     * @param serviceResourceId     The ServiceResource.Id value to search for.
     * @param fieldApiNames         A Set of ServiceResource fieldApiNames to look for history for.
     * @param iLimit                The limit on the History sObject query.
     *
     * @return A ResponseDto object with a List of HistoryWrapper objects in the values map.
     */
    public static ResponseDto retrieveServiceResourceHistories(Id serviceResourceId,Set<String> fieldApiNames,Integer iLimit) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'srId = '+serviceResourceId + '... fieldApiNames='+fieldApiNames + '.iLimit='+iLimit;
        Set<Id> srIds = new Set<Id>{serviceResourceId};
        iLimit = iLimit == null ? DEFAULT_HIST_ROW_LIMIT : iLimit;
        if(fieldApiNames.contains('LastKnownLocation')) {
            fieldApiNames.remove('LastKnownLocation');
            fieldApiNames.add('LastKnownLongitude');
            fieldApiNames.add('LastKnownLatitude');
        }
        List<ServiceResourceHistory> serviceResourceHistories =
                ServiceResourceSvc.retrieveServiceResourceHistories(srIds,fieldApiNames,iLimit);

        List<HistoryWrapper> historyWrappers = buildHistoryWrappers(serviceResourceHistories);
        dto.isSuccess = !historyWrappers.isEmpty();
        dto.values.put(MAP_KEY_SERVICE_RESOURCE_HIST,historyWrappers);
        return dto;
    }

    /**
     * Retrieves a list of all tracked fields for the supplied sObjectApiName.
     *
     * @param sObjectApiName  The Api name of the sObject with tracked fields.
     * @return A ResponseDto object with a List of HistoryFieldWrapper objects in the values map.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveAllTrackedFields(String sObjectApiName) {
        ResponseDto dto = new ResponseDto();

        List<FieldDefinition> fieldDefs = ServiceResourceSvc.retrieveTrackedFields(sObjectApiName);
        List<HistoryFieldWrapper> wraps = buildFieldHistoryFieldWrappers(fieldDefs);
        dto.isSuccess = !wraps.isEmpty();
        dto.values.put(MAP_KEY_TRACKED_FIELD_WRAPS,wraps);
        return dto;
    }

    /**
     * Builds Wrappers for ServiceResourceHistory for easier client usage.
     *
     * @param srHistories   A List of ServiceResourceHistory sObjects.
     * @return              A List of HistoryWrapper objects.
     */
    public static List<HistoryWrapper> buildHistoryWrappers(List<ServiceResourceHistory> srHistories) {
        List<HistoryWrapper> wraps = new List<HistoryWrapper>();
        for(ServiceResourceHistory srh : srHistories) {
            wraps.add(new HistoryWrapper(srh));
        }
        return wraps;
    }

    /**
     * Builds Wrappers for ServiceResource for easier client usage.
     *
     * @param srs   A List of ServiceResourcesObjects.
     * @return      A List of ServiceResourceUserWrapper objects.
     */
    public static List<ServiceResourceUserWrapper> buildServiceResourceUserWrappers(List<ServiceResource> srs) {
        List<ServiceResourceUserWrapper> wraps = new List<ServiceResourceUserWrapper>();
        for(ServiceResource sr : srs) {
            wraps.add(new ServiceResourceUserWrapper(sr));
        }
        return wraps;
    }

    /**
     * Builds Wrappers for FieldDefinition for easier client usage (xxxHistory object wrapper)
     *
     * @param fieldDefinitions  A List of FieldDefinition sObjects.
     * @return      A List of HistoryFieldWrapper objects.
     */
    public static List<HistoryFieldWrapper> buildFieldHistoryFieldWrappers(List<FieldDefinition> fieldDefinitions) {
        List<HistoryFieldWrapper> wraps = new List<HistoryFieldWrapper>();
        for(FieldDefinition fd : fieldDefinitions) {
            wraps.add(new HistoryFieldWrapper(fd));
        }
        return wraps;
    }

    /**
     * Wraps a ServiceResource object
     */
    public class ServiceResourceUserWrapper {
        @AuraEnabled public Id srId;
        @AuraEnabled public String srName;
        @AuraEnabled public String srUserEmail;
        @AuraEnabled public String srTechType;
        @AuraEnabled public String srResourceType;
        @AuraEnabled public String srTrackerId;
        @AuraEnabled public String srGeoTabId;
        @AuraEnabled public String srGpsType;


        public ServiceResourceUserWrapper(ServiceResource sr) {
            this.srId = sr.Id;
            this.srName = sr.Name;
            this.srUserEmail = sr.Accel_User__r.Email;
            this.srTechType = sr.Technician_Type__c;
            this.srResourceType = sr.ResourceType;
            this.srGeoTabId = sr.GeotabId__c;
            this.srTrackerId = sr.trackerid__c;
            this.srGpsType = this.srGeoTabId != null ? 'Geotab' : 'Donlen';
        }
    }

    /**
     * Wraps a ServiceResourceHistory sObject.
     */
    public class HistoryWrapper {
        @AuraEnabled public String historyId;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String createdByName;
        @AuraEnabled public Id createdById;
        @AuraEnabled public Object oldValue;
        @AuraEnabled public Object newValue;
        @AuraEnabled public Datetime oldLastKnownLocationDate;
        @AuraEnabled public Datetime newLastKnownLocationDate;
        @AuraEnabled public String gpsType;

        public HistoryWrapper(ServiceResourceHistory srh) {
            this.historyId = srh.Id;
            this.oldValue = srh.OldValue;
            this.newValue = srh.NewValue;
            this.fieldApiName = srh.Field;
            this.createdDate = srh.CreatedDate;
            this.createdById = srh.CreatedById;
            this.createdByName = srh.CreatedBy.Name;
            this.gpsType = srh.ServiceResource.GeotabId__c != null ? 'Geotab' : 'Donlen';

            if(this.fieldApiName == DEFAULT_HIST_FIELD_API_NAME) {
                //  A hack since oldvalue / newvalue are not creatable in unit tests and will be null.
                if(Test.isRunningTest()) {
                    this.oldValue = Datetime.now().addMinutes(-1);
                    this.newValue = Datetime.now();
                }
                if(this.oldValue instanceof  Datetime) {
                    this.oldLastKnownLocationDate = (Datetime)this.oldValue;
                }
                if(this.newValue instanceof  Datetime) {
                    this.newLastKnownLocationDate = (Datetime)this.newValue;
                }
            }
        }
    }

    /**
     * Wraps a FieldDefinition sObject with field specific information.
     */
    public class HistoryFieldWrapper {
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldLabel;

        public HistoryFieldWrapper(FieldDefinition fd) {
            this.fieldApiName = fd.DeveloperName;
            this.fieldLabel = fd.Label;
        }
    }
}