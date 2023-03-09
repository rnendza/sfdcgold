/**
 * Business Logic intended to back the FSL ServiceResource Object.
 */
public class ServiceResourceTriggerHandler {

    /**
     * Rolls through the updated ServiceResource records and determines if the ServiceResource.Technician_Type__c
     * was modified.  if So build a map of the modified sObjects, parse the ServiceResource.Name field and append
     * the technician type if necessary.
     *
     * @param oldSrMap   Trigger.Old  for a ServiceResource .
     * @param newSrMap   Trigger.New  for a ServiceResource.
     *
     * @return a List of Updated ServicesResource sObjects if any.
     */
    public static List<ServiceResource> updateName(Map<Id, ServiceResource> oldSrMap, Map<Id, ServiceResource> newSrMap) {

        List<ServiceResource>       updatedServiceResources = new List<ServiceResource>();
        Map<Id, ServiceResource>    mServiceResourcesByIds  = new Map<Id, ServiceResource>();

        if (oldSrMap != null && !oldSrMap.isEmpty()) {
            for (ServiceResource newServiceResource : newSrMap.values()) {
                ServiceResource oldServiceResource =  oldSrMap.get(newServiceResource.id);
                if (newServiceResource.Technician_Type__c != oldServiceResource.Technician_Type__c) {
                    mServiceResourcesByIds.put(newServiceResource.id, newServiceResource);
                }
            }
            if (!mServiceResourcesByIds.isEmpty()) {
                updatedServiceResources = parseAndAppendName( mServiceResourcesByIds.values() );
            }
        }
        return updatedServiceResources;
    }
    /**
     * Currently meant for a before insert.
     *
     * @param newServiceResources  A List of new ServiceResource sObjects (no id on these obviously
     * @return a List of Updated ServicesResource sObjects if any (prior to insert)
     */
    public static List<ServiceResource> updateName( List<ServiceResource> newServiceResources ) {
        return parseAndAppendName(newServiceResources);
    }
    /**
     * Rolls through the newly Inserted / Updated ServiceResource sObjects.
     *
     * 1. Ensures name is not null (really has to be as ui enforces this but just in case.
     * 2. if There is a value in ServiceResource.Technician_Type__c.
     *    a. If there was already a technician type appended to the Name field (ie ' - VGT'
     *       1. remove everything every the - and append new tech type.
     *    b. If no tech type previously was appended.
     *       1. add a dash ' - ' and append the tech type.
     * 3. set the ServiceResoure.Name to this new value. (let the implicit update / insert do it's thing)
     * 4. return a list of what was modified.. if anything.
     *
     * @param  serviceResources  a List of ServiceResource records to be potentially modified.
     * @return A List of Updated ServicesResource sObjects if any
     */
    @TestVisible
    private static List<ServiceResource> parseAndAppendName( List<ServiceResource> serviceResources ) {
        List<ServiceResource> updatedServiceResources = new List<ServiceResource>();

        for (ServiceResource newSr : serviceResources ) {
            String srName = newSr.name;
            if(srName != null) {
                if(newSr.Technician_Type__c != null) {
                    if (srName.contains(' - ')) {
                        Integer idxDash = srName.indexOf(' - ');
                        srName = srName.substring(0, idxDash);
                        srName += ' - ' + newSr.Technician_Type__c;
                    } else {
                        srName += ' - ' + newSr.Technician_Type__c;
                    }
                } else {
                    Integer idxDash = srName.indexOf('-');
                    if(idxDash > 0) {
                        srName = srName.substring(0, idxDash - 1);
                    }
                }
                newSr.name = srName;
                updatedServiceResources.add(newSr);
            }
        }
        return updatedServiceResources;
    }
}