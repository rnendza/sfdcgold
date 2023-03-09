public without sharing class FieldSetController {

    public static final String  MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS = 'FS_WRAPS_AND_MEMBERS';
    /**
     * Retrieves FieldSetWrapper(s) (and their children FieldSetMemberWrapper(s) for the given sObject Api Name
     * And FieldSet Api Name(s).
     *
     * @param sObjectApiName     The sObject Api Name.
     * @param fieldSetApiNames   The FieldSet Api Name(s).
     *
     * @return a List of FieldSetWrappers in the values map. (hopefully assuming Opportunity.Page_Category__c api name
     * and field set api name play nice).
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveSpecificFieldSetWrappersAndFieldSetMembers(String sObjectApiName, List<String> fieldSetApiNames) {
        ResponseDto dto = new ResponseDto();
        Set<String> fsApiNames = new Set<String>(fieldSetApiNames);
        Map<String,FieldSetWrapper> mFieldSetWrappersByApiName =
                FieldSetSvc.getSpecificFieldSetWrappersAndFieldSetMembers(fsApiNames,sObjectApiName);
        dto.isSuccess = !mFieldSetWrappersByApiName.isEmpty();
        if(!dto.isSuccess) {
            dto.technicalMsg += 'Could not find field set wraps for sObjectApiName='+sObjectApiName+
                    '....fieldSetApiNames='+fieldSetApiNames;
            dto.message = 'We could not find the fieldset for fieldset api name = '+fieldSetApiNames+' Please contact an administrator';
        }
        dto.values.put(MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS,mFieldSetWrappersByApiName.values());
        return dto;
    }
}