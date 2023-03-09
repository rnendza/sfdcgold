public with sharing class CaseController {
    public static final String MAP_KEY_CASE_LIST = 'CASE_LIST';
    public static final String MAP_KEY_RSM_SEARCH_SETTINGS  = 'MAP_KEY_SEARCH_SETTINGS';

    @AuraEnabled
    public static ResponseDto retrieveSearchSettings() {
        ResponseDto dto = new ResponseDto();
        dto.values.put(MAP_KEY_RSM_SEARCH_SETTINGS, CustomMetadataSvc.retrieveCustomSearchMeta(Custom_Search__mdt.getSObjectType(), 'RSM_Case_History_Lookup'));
        dto.isSuccess = true;
        return dto;
    }

    @AuraEnabled
    public static ResponseDto searchCases(String searchTerm) {
        Custom_Search__mdt searchMdt = (Custom_Search__mdt)CustomMetadataSvc.retrieveCustomSearchMeta(Custom_Search__mdt.getSObjectType(), 'RSM_Case_History_Lookup');

        Integer iRowLimit = Integer.valueOf(searchMdt.Number_of_Max_Search_Results__c);
        ResponseDto dto = new ResponseDto();
        List<Case> cases = CaseSvc.retrieveCaseHistoryCases(searchTerm,iRowLimit);
        dto.isSuccess = true;
        if(cases != null && cases.size() == iRowLimit) {
            dto.severity = 'warning';
            dto.message = 'Your search was limited to '+iRowLimit +' results. Please refine your search or locate your results below.'; //@TODO Label
        }
        dto.values.put(MAP_KEY_CASE_LIST, cases);
        return  dto;
    }
}