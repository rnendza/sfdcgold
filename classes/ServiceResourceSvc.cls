public with sharing class ServiceResourceSvc {

    /**
     * Retrieve all Active Service Resources that have a GeoTab GPS Device Id. or TrackerId (All Fields)
     * @return A List of ServiceResource sObjects.
     */
    public static List<ServiceResource> retrieveGpsServiceResources() {

        List<ServiceResource> resources;
        String q = '';
        q += ' SELECT {0} ';
        q += ' FROM    ServiceResource ';
        q += ' WHERE  ( GeotabId__c != NULL OR trackerid__c != NULL ) ';
        q += ' AND     IsActive = TRUE ';

        String formattedQuery = String.format(q,getAllFields(ServiceResource.SObjectType));
        resources = Database.query(formattedQuery);
        return resources;
    }

    /**
     * Retrieve all Active Service Resources that have a GeoTab GPS Device Id or TrackerId (Id, Name Fields only)
     * @return A List of ServiceResource sObjects.
     */
    public static List<ServiceResource> retrieveGpsServiceResourceNames() {
        List<ServiceResource> resources = [
                SELECT Id,Name,Accel_User__r.Email,Technician_Type__c,ResourceType,trackerid__c,GeotabId__c
                FROM   ServiceResource
                WHERE  (GeotabId__c != NULL OR trackerid__c != NULL)
                AND    IsActive = TRUE
        ];
        return resources;
    }
    /**
     * @param srIds             A Set of ServiceResource.Id values.
     * @param fieldApiNames     A Set of ServiceResource field api names for fields that changed.
     * @param iLimit            The limit of number of records returned.
     *
     * @return A List of ServiceResourceHistory sObjects.
     */
    public static List<ServiceResourceHistory> retrieveServiceResourceHistories(Set<Id> srIds,Set<String> fieldApiNames,
                                                                                Integer iLimit) {
        List<ServiceResourceHistory> srs = [
                SELECT  Id,Field,OldValue,NewValue,CreatedDate,CreatedBy.Name,CreatedById,ServiceResource.trackerid__c,
                        ServiceResource.GeotabId__c,ServiceResourceId,ServiceResource.Name
                FROM    ServiceResourceHistory
                WHERE   Field IN :fieldApiNames
                AND     ServiceResourceId IN :srIds
                ORDER BY CreatedBy.Name ASC, CreatedDate DESC
                LIMIT :iLimit
        ];
        return srs;
    }

    /**
     * @TODO MOVE TO SOME GENERIC UTILS!
     *
     * @param sObjType The type of SObject.
     *
     * @return xxx
     */
    public static List<String>  getAllFields(SObjectType sObjType) {
        Map<String, Schema.SObjectField> fieldsMap = sObjType.getDescribe().fields.getMap();
        String sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        List<String> fields = new List<String>{sfields};
        return fields;
    }


    /**
     * @param sObjectApiName  The Api name of the sObject with tracked fields.
     * @return A List of FieldDefinition sObjects
     * @TODO MOVE TO SOME GENERIC UTILS!
     */
    public static List<FieldDefinition> retrieveTrackedFields(String sObjectApiName) {
        List<FieldDefinition> fieldDefinitions = [
                SELECT QualifiedApiName,Label,DeveloperName
                FROM   FieldDefinition
                WHERE  EntityDefinition.QualifiedApiName = :sObjectApiName
                AND    IsFieldHistoryTracked = TRUE
                ORDER By Label ASC
        ];
        return fieldDefinitions;
    }
}