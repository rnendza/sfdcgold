public with sharing class RecordAutocompleteController {

    public static final String  MAP_KEY_SOBJECT_RESULTS   = 'MAP_KEY_SOBJECT_RESULTS';
    public static final String  MAP_KEY_SELECTED_SOBJECT_RESULT   = 'MAP_KEY_SELECTED_SOBJECT_RESULT';
    public static Boolean USE_SOSL = FALSE;

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveSelectedSObjectResult(String sObjectApiName, String primaryDisplayField,
            String secondaryDisplayField,
            String defaultRecordSelectedId) {

        SObject sObj;
        ResponseDto dto = new ResponseDto();
        if(defaultRecordSelectedId != null) {
            List<String> selectFields = buildSelectFields(primaryDisplayField, secondaryDisplayField, null);
            String whereCriteria = '  Id = \'' + defaultRecordSelectedId + '\' ';
            List<SObject> sObjects = SObjectQuerySvc.retrieveSObjectResults(sObjectApiName, selectFields, whereCriteria, null, 1);
            if (sObjects != null && !sObjects.isEmpty()) {
                sObj = sObjects[0];
                dto.isSuccess = true;
            }
            dto.technicalMsg = 'SelectFields='+selectFields + '...WhereCriteria='+whereCriteria;
        } else {
            dto.technicalMsg = 'Default selected record id is null. .skipping query.';
        }
        dto.values.put(MAP_KEY_SELECTED_SOBJECT_RESULT,sObj);
        return dto;
    }

    /**
     *
     *
     * @param sObjectApiName
     * @param primaryDisplayField
     * @param secondaryDisplayField
     * @param searchTerm
     * @param primaryFilterField
     * @param secondaryFilterField
     * @param iMinCharacters
     * @param additionalWhereCriteria
     * @param preloadResults
     * @param iMaxRows
     *
     * @return
     * @todo replace this mess with an options like object.
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveSObjectResults(String sObjectApiName, String primaryDisplayField,
                                                     String secondaryDisplayField,
                                                     String searchTerm, String primaryFilterField,
                                                     String secondaryFilterField,
                                                     Integer iMinCharacters,
                                                     String additionalWhereCriteria,
                                                     String orderByClause,
                                                     String defaultRecordSelectedId,
                                                     Boolean preloadResults,
                                                     Integer iMaxRows) {
        ResponseDto dto = new ResponseDto();
        List<SObject> sObjects;
        if(( preloadResults != null && !preloadResults )|| ( searchTerm != null && searchTerm !='null')) {
            if (iMinCharacters != null) {
                if (searchTerm == null || searchTerm == '' || searchTerm.length() < iMinCharacters) {
                    dto.isSuccess = false;
                    dto.technicalMsg = 'not enough characters provided. preloadresults='+preloadResults + '...searchTerm = '+searchTerm;
                    return dto;
                }
            }
        }
        List<String> selectFields = buildSelectFields(  primaryDisplayField,secondaryDisplayField,
                                                        primaryFilterField);
        String whereCriteria = null;
        if(!USE_SOSL) {
            if ((preloadResults != null && !preloadResults) || searchTerm != null) {
                whereCriteria = buildWhereCriteria(searchTerm, primaryFilterField, secondaryFilterField);
                if (additionalWhereCriteria != null) {
                    whereCriteria += ' AND ' + additionalWhereCriteria;
                }
            } else {
                if (additionalWhereCriteria != null) {
                    whereCriteria = additionalWhereCriteria;
                }
            }
            //  retrieveSelectedSObjectResult will find the single selected record and push to the results
            //  do not duplicate this here!
            if (defaultRecordSelectedId != null) {
                if (whereCriteria != null) {
                    whereCriteria += ' AND Id != \'' + defaultRecordSelectedId + '\' ';
                } else {
                    whereCriteria = ' Id != \'' + defaultRecordSelectedId + '\' ';
                    // whereCriteria = ' Id != NULL OR  Id = \'' + defaultRecordSelectedId + '\'';
                }
            }
            sObjects = SObjectQuerySvc.retrieveSObjectResults(sObjectApiName, selectFields, whereCriteria, orderByClause, iMaxRows);
        } else {
            sObjects = runSosl(sObjectApiName,selectFields,searchTerm,whereCriteria,orderByClause,iMaxRows);
        }

        dto.isSuccess = !sObjects.isEmpty();
        dto.values.put(MAP_KEY_SOBJECT_RESULTS,sObjects);
        dto.technicalMsg = 'SelectFields='+selectFields + '...WhereCriteria='+whereCriteria;
        return dto;
    }
    @TestVisible
    private static List<SObject> runSosl(String sObjectApiName, List<String> selectFields,String term,String whereCriteria,String orderByClause, Integer iMaxRows) {
        List<SObject> sObjects = SObjectQuerySvc.retrieveSoslSObjectResults(sObjectApiName,selectFields,term,whereCriteria,orderByClause,iMaxRows);
        return sObjects;
    }

    /**
     *
     *
     * @param searchTerm
     * @param primaryFilterField
     * @return
     */
    @TestVisible
    private static String buildWhereCriteria(String searchTerm, String primaryFilterField, String secondaryFilterField) {
        String whereCriteria = '';

        if(secondaryFilterField != null) {
            whereCriteria += '( ' + primaryFilterField + ' LIKE \'%'+searchTerm+'%\'';
            whereCriteria += ' OR ' + secondaryFilterField  + ' LIKE \'%'+searchTerm+'%\')';
        } else {
            whereCriteria = primaryFilterField + ' LIKE \'%'+searchTerm+'%\'';
        }
        return whereCriteria;
    }
    /**
     *
     *
     * @param primaryDisplayField
     * @param secondaryDisplayField
     * @param primaryFilterField
     * @return
     */
    @TestVisible
    private static List<String> buildSelectFields ( String primaryDisplayField, String secondaryDisplayField,
                                                    String primaryFilterField) {
        List<String> selectFields = new List<String>();
        if(!USE_SOSL) {
            selectFields.add('Id');
        }
        selectFields.add(primaryDisplayField);
        selectFields.add(secondaryDisplayField);
        return selectFields;
    }
}