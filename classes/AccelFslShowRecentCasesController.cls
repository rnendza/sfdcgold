public with sharing class AccelFslShowRecentCasesController {

    public static final String          MAP_KEY_CASE_WRAPPERS           = 'CASE_WRAPPERS';
    public static final String          CASE_CLOSED_STATUS              = 'Closed';
    public static final Integer         DEFAULT_ROW_LIMIT               = 200;
    public static final List<String>    DEFAULT_EXCLUDES_STATUSES       = new List<String>{CASE_CLOSED_STATUS};
    public static final String          DEFAULT_INC_CREATED_DT_LITERAL  = '= LAST_N_DAYS:7';
    public static final String          SEVERITY_ERROR                  = 'error';

    /**
     * Retrieve the recent cases based on user criteria.
     *
     * @param caseParams    A CaseParams object (uses defaults for all by service appointment id).
     * @return              A ResponseDto object containing a list of CaseWrappers in the values map.
     *
     * @see CaseParams
     */
    @AuraEnabled
    public static ResponseDto retrieveRecentCases(CaseParams caseParams) {
        ResponseDto dto = new ResponseDto();
        List<CaseWrapper> caseWrappers;
        dto.technicalMsg +=' caseParams: '+caseParams;

        if(validateCaseParams(caseParams)) {
            List<Case> cases;
            try {
                cases = retrieveCases(caseParams);
                caseWrappers = buildCaseWrappers(cases);
                dto.isSuccess = !caseWrappers.isEmpty();
            } catch(QueryException qex) {
                dto.severity = SEVERITY_ERROR;
                dto.technicalMsg = qex.getStackTraceString();
                dto.message = qex.getMessage();
            }
        } else {
            dto.severity = SEVERITY_ERROR;
            dto.message = 'Invalid case parameters for query: '+caseParams;
        }
        dto.values.put(MAP_KEY_CASE_WRAPPERS,caseWrappers);
        return dto;
    }

    /**
     * @param cases A list of Case sObjects.
     * @return      A list of CaseWrapper objects.
     */
    public static List<CaseWrapper> buildCaseWrappers(List<Case> cases) {
        List<CaseWrapper> caseWrappers = new List<CaseWrapper>();
        if(cases != null && !cases.isEmpty()) {
            for(Case cse : cases) {
                caseWrappers.add(new CaseWrapper(cse));
            }
        }
        return caseWrappers;
    }

    /**
     * Find all cases linked to the service appointment account id which do not have a Case.Status passed as a param
     * and have a creationdate per the case dataliteral passed as a param.
     *
     * @param caseParams    A CaseParam Object.
     * @return              A list of Case sObjects.
     */
    public static List<Case> retrieveCases(CaseParams caseParams) {
        List<Case> recentCases = new List<Case>();
        List<ServiceAppointment> sas = [
                SELECT Id,AccountId
                FROM   ServiceAppointment
                WHERE  Id = :caseParams.svcAppointmentId
        ];

        if(!sas.isEmpty()) {
            Id saAccountId = sas[0].AccountId;
            List<String> excludedCaseStatuses = caseParams.excludedStatuses;
            Integer iLimit = caseParams.iLimitRows;

            String soql = '';
            soql +=' SELECT     Id,CaseNumber,Status,Assigned_Resource__c,Assigned_Resource__r.Name,Service_Category__c, ';
            soql +='            CreatedDate ';
            soql +=' FROM       Case ';
            soql +=' WHERE      AccountId = :saAccountId ';
            soql +=' AND        Status NOT IN  :excludedCaseStatuses ';
            soql +=' AND        CreatedDate ' + caseParams.includedCreatedDateLiteral + ' ';
            soql +=' ORDER BY CreatedDate DESC ';
            soql +=' LIMIT :iLimit ';

            recentCases = Database.query(soql);
        }
        return recentCases;
    }
    /**
     * @param caseParams A CaseParam object.
     * @return           True if not blank on all params, otherwise false.
     */
    private static Boolean validateCaseParams(CaseParams caseParams) {
        return String.isNotBlank(caseParams.includedCreatedDateLiteral) &&
                caseParams.excludedStatuses != null &&
                !caseParams.excludedStatuses.isEmpty();
    }

    /**
     * Wraps a Case sObject.
     */
    public class CaseWrapper {
        @AuraEnabled public Id caseId;
        @AuraEnabled public String caseNumber;
        @AuraEnabled public String caseLink;
        @AuraEnabled public String status;
        @AuraEnabled public String assignedResourceId;
        @AuraEnabled public String assignedResourceName;
        @AuraEnabled public String assignedResourceLink;
        @AuraEnabled public String serviceCategory;
        @AuraEnabled public Datetime createdDate;

        public CaseWrapper(Case cse) {
            this.caseId = cse.Id;
            this.caseNumber = cse.CaseNumber;
            this.caseLink = this.caseId != null ? '/'+this.caseId : null;
            this.status = cse.Status;
            this.assignedResourceId = cse.Assigned_Resource__c;
            this.assignedResourceName = cse?.Assigned_Resource__r?.Name;
            this.assignedResourceLink = this.assignedResourceId != null ? '/' + this.assignedResourceId : null;
            this.serviceCategory = cse.Service_Category__c;
            this.createdDate = cse.CreatedDate;
        }
    }

    /**
     * Main parameter object passed from the client.
     */
    public class CaseParams {
        @AuraEnabled public Id svcAppointmentId {get;set;}
        @AuraEnabled public Integer iLimitRows {get;set;}
        @AuraEnabled public List<String> excludedStatuses {get;set;}
        @AuraEnabled public String includedCreatedDateLiteral {get;set;}

        public CaseParams() {
            this.iLimitRows = DEFAULT_ROW_LIMIT;
            this.excludedStatuses = DEFAULT_EXCLUDES_STATUSES;
            this.includedCreatedDateLiteral = DEFAULT_INC_CREATED_DT_LITERAL;
        }
    }
}