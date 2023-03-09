public without sharing class clRelatedFiles {

    public static final String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
    public static final String downloadPath = 'sfc/servlet.shepherd/document/download/';
    public static final String previewPath = 'sfc/servlet.shepherd/version/renditionDownload?rendition=THUMB720BY480&versionId=';

    //      url: '/sfc/servlet.shepherd/document/download/0692w000000MmSyAAK?operationContext=S1
    public static final String MAP_KEY_RELATED_FILES = 'RELATED_FILES';
    public static final String MAP_KEY_ROUTE_IMPORT = 'ROUTE_IMPORT';
    public static final String MAP_KEY_SUCCESS_FILEWRAP = 'SUCCESS_FILEWRAP';
    public static final String MAP_KEY_CSVDATA_FILEWRAP = 'CSVDATA_FILEWRAP';
    public static final String MAP_KEY_PL_OPTIONS_FILE_CREATED_BY = 'PL_OPTIONS_FILE_CREATED_BY';
    public static final String MAP_KEY_PL_OPTIONS_UPLOAD_STATUS = 'PL_OPTIONS_UPLOAD_STATUS';
    public static final String MAP_KEY_DELETE_FILE = 'DELETE_FILE';
    public static final String MAP_KEY_PERMISSIONS = 'PERMISSIONS';

    @TestVisible private static final String PUB_PROCESS_MODIFY_ROUTES = 'modifyRoutes';
    @TestVisible private static final String PUB_STATUS_PROCESSING = 'processing';
    @TestVisible private static final String PUB_STATUS_COMPLETE = 'complete';
    @TestVisible private static Id pRouteImportId;
    @TestVisible private static Id pContentDocumentId;
    @TestVisible private static Boolean FORCE_ENABLE_CUSTOM_PERM = false;
    @TestVisible private static final String IMPORT_FAILED_MSG = 'Route import Failed! All changes are rolled back!';
    @TestVisible private static final String IMPORT_SUCCESS_MSG = 'Route import Successful!';

    // =====  Logging
    @TestVisible private static Accel_Application_Error__c log;
    @TestVisible private static String jobName = 'clRelatedFiles_import';
    //  Various internal stateful counters
    private static Integer iTotalRecordsFailed = 0, iTotalRecordsSelected = 0, iTotalRecordsUpdated = 0;
    private static Integer iTotalRecordsProcessed = 0, iNumExeCalls = 0;
    public static Boolean logFailedRecordIds = true;
    private static Map<Id, String> mFailedUpdates = new Map<Id, String>();


    /**
     * The method will blah blah blah...
     *
     * @param routeImportRows   The route import data from the csv that was parsed on the client.
     * @param contentDocumentId The content document id.
     * @param routeImportId     The Route_Import__c.Id.
     * @return                  A dto containing messaging / results? etc.
     *
     * @implnote
     *     Pseudo:
     *     (1) Get all the unique Route Names in the CSV
     *     (2) Get all Route_Account__c records for the processing location.
     *     (3) Create a map of Route Name => Route__c.Id for later tagging.
     *     (4) Create new Route__Account sObjects based on spreadsheet data.
     *     (5) Delete all existing Route_Account__c data associated with the processing location.
     *     (6) Insert new Route_Account__c data based on the spreadsheet.
     *     (7) Create a _success_csv and create a separate content version.
     *
     * @todo this method is too long and needs to be modularized and cleaned up for prod!
     */
    @AuraEnabled
    public static ResponseDto doModifyRoutes(List<RouteImportData> routeImportRows, Id contentDocumentId, Id routeImportId) {

        initLog();
        Boolean rollItBack = false; //@todo pass in param!
        ResponseDto dto = new ResponseDto();
        String msg = ' * doModifyRoutes - Processing ' + routeImportRows.size() + ' csv rows. for docId = ' + contentDocumentId + ' and routeImport Id = ' + routeImportId;
        log.Execution_Details__c += '\n' + msg + '\n' ;
        iTotalRecordsSelected = routeImportRows.size();
        log.Total_Records_Selected__c = iTotalRecordsSelected;
        publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);

        pContentDocumentId = contentDocumentId;
        pRouteImportId = routeImportId;

        dto.technicalMsg += '.. processing ' + routeImportRows.size() + ' rows ..docId=' + contentDocumentId + '..importId=' + routeImportId;
        dto.values.put('incomingparams', routeImportRows);

        List<Route_Import__c> routeImports = [SELECT Id, Name,Region__c FROM Route_Import__c WHERE Id = :routeImportId];

        Boolean routeRegionMismatch = false;

        if (!routeImports.isEmpty()) {
            String processingLoc = routeImports[0].Name;
            log.Execution_Details__c += '\n * Route Import Name: ' + routeImports[0].Name + '\n';

            Set<String> routeNames = new Set<String>();
            List<Route_Account__c> newRouteAccounts = new List<Route_Account__c>();

            //  (1) Get all the unique Route Names in the CSV
            for (RouteImportData rid : routeImportRows) {
                routeNames.add(rid.routeName);
            }

            /*
             * (1a) worst case server side check - mismatched route - region check
             *
             * 2/11/2020  REMOVED CHECK Since the user is only providing route names (as opposed to route ids and route names
             *            are the same across multiple regions (sigh) we can't really do a direct check
             *            to make sure they aren't uploading the wrong spreadsheet for the wrong region.
             */

            dto.technicalMsg += ' route names:' + routeNames;
            log.Execution_Details__c += '\n * Route Names Found: ' + routeNames + '\n';

            //  (2) Get all Route_Account__c records for the processing location.
            Map<Id, Route_Account__c> mRouteAccounts = new Map<Id, Route_Account__c> ([
                    SELECT Id,Name,Route__r.Name,Route__c,Stop_Number__c
                    FROM Route_Account__c
                    WHERE Route__r.Processing_Location__c = :processingLoc
            ]);
            dto.technicalMsg += ' # route accounts to del found:' + mRouteAccounts.size();
            log.Execution_Details__c += '\n * ' + dto.technicalMsg + '\n';

            //  (3) Create a map of Route Name => Route__c.Id for later tagging. (might have routes with no accounts )
            //  2/11/2022 added processing location filter.
            Map<Id, Route__c> mRoutes = new Map<Id, Route__c>([
                    SELECT Id,Name
                    FROM Route__c
                    WHERE Name IN :routeNames
                    AND   Processing_Location__c = :processingLoc
            ]);
            Map<String, Id> mRouteName_RouteId = new Map<String, Id>();
            for (Route__c route : mRoutes.values()) {
                mRouteName_RouteId.put(route.Name, route.Id);
            }
            dto.technicalMsg += 'map size:' + mRouteName_RouteId.size();

            //  (3) Create new Route__Account sObjects based on spreadsheet data.
            Integer iNumFullAuditReplenishmentType = 0, iNumCashFillReplenishmentType = 0;
            for (RouteImportData rid : routeImportRows) {
                Route_Account__c newRouteAccount = new Route_Account__c();
                newRouteAccount.Route__c = mRouteName_RouteId.get(rid.routeName);
                newRouteAccount.Account__c = rid.accountId;
                newRouteAccount.Stop_Number__c = rid.stopNumber;
                newRouteAccount.Collection_Type__c = rid.collectionType;
                newRouteAccount.X1_Fill_Level__c = rid.x1FillLevel;
                newRouteAccount.X5_Fill_Level__c = rid.x5FillLevel;
                newRouteAccount.X20_Fill_Level__c = rid.x20FillLevel;
                newRouteAccount.X50_Fill_Level__c = rid.x50FillLevel;
                newRouteAccount.X100_Fill_Level__c = rid.x100FillLevel;
                newRouteAccount.Replenishment_Type__c = rid.replenishmentType;
                if(rid.replenishmentType == 'Full Audit') {
                    iNumFullAuditReplenishmentType ++;
                } else if (rid.replenishmentType == 'Cash Fill') {
                    iNumCashFillReplenishmentType ++;
                }
                newRouteAccounts.add(newRouteAccount);
            }
            Savepoint sp = Database.setSavepoint();

            //  (4) Delete all existing Route_Account__c data associated with the processing location.
            try {
                msg = 'Deleting ' + mRouteAccounts.size() + ' Route Account records.';
                log.Execution_Details__c += '\n * ' + msg + '\n';

                publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);
                delete mRouteAccounts.values();
                dto.technicalMsg += '..... Deleted ' + mRouteAccounts.size() + ' route account records.';
                //     (4a) THERE SHOULD BE NO Route_Account__c records left of all the route names in the csv for the processing loc.
                //     The below will intentionally force a hard error if not true.
                System.assertEquals(0, [
                        SELECT Id
                        FROM   Route_Account__c
                        WHERE Route__r.Name IN :routeNames
                        AND Route__r.Processing_Location__c = :processingLoc
                ].size());

                //  (5) Insert new Route_Account__c data based on the spreadsheet.
                msg = 'Creating ' + newRouteAccounts.size() + ' new Route Account records.';
                log.Execution_Details__c += '\n * ' + msg + '\n';
                publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);


                msg = 'Total Number of Cash Fill replenishmentType values: '+ iNumCashFillReplenishmentType;
                log.Execution_Details__c += '\n * ' + msg + '\n';
                publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);

                msg = 'Total Number of Full Audit replenishmentType values: '+ iNumFullAuditReplenishmentType;
                log.Execution_Details__c += '\n * ' + msg + '\n';
                publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);

                iTotalRecordsProcessed = newRouteAccounts.size();
                insert newRouteAccounts;
                iTotalRecordsUpdated = newRouteAccounts.size();

                List<Route_Account__c> routeAccounts = [
                        SELECT Id,Name,Route__c,X1_Fill_Level__c,X50_Fill_Level__c,X20_Fill_Level__c,X100_Fill_Level__c,
                                X5_Fill_Level__c,Route__r.Name,CreatedDate,CreatedById,CreatedBy.Username,
                                Account__r.NAme,Collection_Type__c,Replenishment_Type__c,Stop_Number__c
                        FROM Route_Account__c
                        WHERE Id IN :newRouteAccounts
                ];
                dto.technicalMsg += '...... Inserted ' + newRouteAccounts.size() + ' new route account records.';


                if (rollItBack) Database.rollback(sp);

                ContentVersion cv = [SELECT Id, CL_Upload_Status__c FROM ContentVersion WHERE ContentDocumentId = :contentDocumentId];
                cv.CL_Upload_Status__c = 'Published';
                update cv;
                FileWrapper fw = buildRouteAccountSuccessCsv(contentDocumentId, routeImportId, routeAccounts);
                dto.values.put(MAP_KEY_SUCCESS_FILEWRAP, fw);

                if (rollItBack) msg = 'Rolling back all changes';
                publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);
                if (rollItBack) dto.technicalMsg += '......... XXXX Rolled back delete and create for testing purposes! ';
                dto.message = IMPORT_SUCCESS_MSG;
                dto.isSuccess = true;
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_SUCCESS;
            } catch (Exception e) {
                Database.rollback(sp);
                dto.isSuccess = false;
                dto.message = IMPORT_FAILED_MSG;
                dto.message += e.getMessage();
                log.Execution_Details__c += '\n * ERROR! ' + e.getMessage() + '\n';
                log.Stack_Trace__c = '';
                log.Stack_Trace__c += '\n Exception: ' + e.getMessage() + '- ' + e.getLineNumber() + ' - '
                        + e.getCause() + ' - ' + e.getStackTraceString();
                log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_FAILED;
                log.Total_Updates_Failed__c = newRouteAccounts.size();
            }

        } else {
            dto.message = IMPORT_FAILED_MSG;
            dto.isSuccess = false;
            dto.technicalMsg += 'No route import record found for passed routeImportId=' + routeImportId;
            dto.severity = 'error';
            log.Execution_Details__c += '\n* ROUTE IMPORT FAILED SEE STACK TRACE' + '\n';
            log.Stack_Trace__c += '\n* ' + dto.technicalMsg;
            log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_FAILED;
        }
        writeFinalLog();
        return dto;
    }


    private static void publishPlatformEvent(String uiMsg, String status, String pubProcess) {

        Route_Import_PE__e event = new Route_Import_PE__e();

        event.Route_Import_Id__c = pRouteImportId;
        event.Content_Document_Id__c = pContentDocumentId;
        event.Status__c = status;
        event.Publishing_Process_Name__c = pubProcess;
        event.Ui_Message__c = uiMsg;

        if (log != null) {
            log.Execution_Details__c += '\n * Firing Platform Event: ' + event + '\n';
        }

        PlatformEventSvc.publishPlatformEvents(new List<Route_Import_PE__e>{
                event
        });
    }

    @AuraEnabled
    public static ResponseDto deleteRelatedFile(Id contentDocumentId) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'doc id passed=' + contentDocumentId;
        ContentDocument deletedDoc = ContentManagerSvc.deleteDocument(contentDocumentId);
        dto.values.put(MAP_KEY_DELETE_FILE, deletedDoc);
        dto.isSuccess = deletedDoc != null;
        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveContentVersion(Id contentDocumentId) {
        ResponseDto dto = new ResponseDto();
        ContentVersion cv = ContentManagerSvc.retrieveContentVersion(contentDocumentId);

        FileWrapper fw;
        if (cv != null) {
            fw = new FileWrapper(cv);
            fw.csvData = cv.VersionData.toString();
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_CSVDATA_FILEWRAP, fw);
        return dto;
    }

    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveImporterHelpContentVersion(String title) {
        ResponseDto dto = new ResponseDto();
        FileWrapper fw;
        ContentVersion cv;
        Map<Id, ContentVersion> mCvs = ContentManagerSvc.retrieveContentVersionsByTitle(title);
        if (!mCvs.values().isEmpty()) {
            cv = mCvs.values()[0];
            if (cv != null) {
                dto.isSuccess = true;
                fw = new FileWrapper(cv);
            }
        }
        dto.values.put('importerhelpcsv', fw);
        return dto;
    }
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveRouteImport(Id routeImportId) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'incoming route import id:' + routeImportId;

        List<Route_Import__c> routeImports = [SELECT Id, Name FROM Route_Import__c WHERE Id = :routeImportId];
        if (!routeImports.isEmpty()) {
            Route_Import__c ri = routeImports[0];
            dto.values.put(MAP_KEY_ROUTE_IMPORT, ri);
            dto.isSuccess = true;
        } else {
            dto.message = 'Could not find Route Import Record!';
        }
        return dto;
    }

    /**
     * @param recordId  xx
     * @return          xx
     */
    @AuraEnabled public static ResponseDto retrieveRelatedFiles(Id recordId, String uploadType) {

        ResponseDto dto = new ResponseDto();
        String entityName = recordId.getSobjectType().getDescribe().name;
        dto.technicalMsg += ' recordId param: ' + recordId + '..uploadType=' + uploadType;

        List<FileWrapper> fileWrappers = new List<FileWrapper>();
        Set<PlOption> fileCreatedByPlOptions = new Set<PlOption>();
        Set<PlOption> fileUploadStatusPlOptions = new Set<PlOption>();

        //Map<Id, ContentVersion> mCvs = ContentManagerSvc.retrieveContentVersions(new Set<Id>{recordId}, entityName);
        Map<Id, ContentVersion> mCvs = ContentManagerSvc.retrieveContentVersionsNoVersionData(new Set<Id>{recordId}, entityName);
        // filter further
        List<ContentVersion> cvs = new List<ContentVersion>();
        for (ContentVersion cv : mCvs.values()) {
            if (cv.Cash_Logistics_Upload_Type_fileupload__c == uploadType) {
                cvs.add(cv);
            }
        }

        if (!cvs.isEmpty()) {
            fileWrappers = buildFileResultsResponse(cvs);
            fileWrappers.sort();
            fileCreatedByPlOptions = buildCreatedByPlOptions(fileWrappers);
            fileUploadStatusPlOptions = buildStatusPlOptions(fileWrappers);

        } else {
            dto.message += 'No files associated with this record.';
            dto.technicalMsg += '... no content version found.';
        }
        dto.isSuccess = fileWrappers != null && !fileWrappers.isEmpty();
        dto.values.put(MAP_KEY_RELATED_FILES, fileWrappers);
        dto.values.put(MAP_KEY_PL_OPTIONS_FILE_CREATED_BY, fileCreatedByPlOptions);
        dto.values.put(MAP_KEY_PL_OPTIONS_UPLOAD_STATUS, fileUploadStatusPlOptions);

        return dto;
    }

    @TestVisible
    private static List<FileWrapper> buildFileResultsResponse(List<ContentVersion> cvs) {
        List<FileWrapper> fileWraps = new List<FileWrapper>();
        for (ContentVersion cv : cvs) {
            FileWrapper fw = new FileWrapper(cv);
            fileWraps.add(fw);
        }
        return fileWraps;
    }

    @TestVisible
    private static Set<PlOption> buildCreatedByPlOptions(List<FileWrapper> fileWrappers) {
        Set<PlOption> options = new Set<PlOption>();
        options.add(new PlOption('-1', 'Any User', true));

        for (FileWrapper fw : fileWrappers) {
            options.add(new PlOption(fw.fileCreatedById, fw.fileCreatedByName, false));
        }
        return options;
    }

    @TestVisible
    private static Set<PlOption> buildStatusPlOptions(List<FileWrapper> fileWrappers) {
        Set<PlOption> options = new Set<PlOption>();
        options.add(new PlOption('-1', 'Any Status', true));

        for (FileWrapper fw : fileWrappers) {
            options.add(new PlOption(fw.fileUploadStatus, fw.fileUploadStatus, false));
        }
        return options;
    }

    @TestVisible
    private static FileWrapper buildRouteAccountSuccessCsv(Id contentDocumentId, Id routeImportId, List<Route_Account__c> routeAccounts) {
        ContentVersion cv = ContentManagerSvc.retrieveContentVersion(contentDocumentId);
        String csvName = cv.Title + '_publish_successes' + '_' + System.now() + '.csv';
        String msg = 'Creating results file ' + csvName;
        publishPlatformEvent(msg, PUB_STATUS_PROCESSING, PUB_PROCESS_MODIFY_ROUTES);

        clRouteAccountCsv csvBuilder = new clRouteAccountCsv();
        String csvData = csvBuilder.generateRouteAccountCsv(routeAccounts);
        FileWrapper fw = new FileWrapper(saveFile(routeImportId, csvName, csvData));
        return fw;
    }

    public class FileWrapper implements Comparable {

        @AuraEnabled public Id contentVersionId;
        @AuraEnabled public Id contentDocumentId;
        @AuraEnabled public String fileTitle;
        @AuraEnabled public String fileSize;
        @AuraEnabled public String fileType;
        @AuraEnabled public String fileDownloadUrl;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public PlOption fileCreatedByPlOption;
        //  Below is lame but lwc datatables need flattended data.
        @AuraEnabled public String fileCreatedByName;
        @AuraEnabled public Datetime fileCreatedByDate;
        @AuraEnabled public Id fileCreatedById;
        @AuraEnabled public String fileClUploadType;
        @AuraEnabled public Blob fileVersionData;
        @AuraEnabled public String csvData;
        @AuraEnabled public String fileUploadStatus;

        public FileWrapper() {

        }
        public FileWrapper(ContentVersion cv) {
            this.lastModifiedDate = cv.LastModifiedDate;
            this.contentDocumentId = cv.ContentDocumentId;
            this.contentVersionId = cv.Id;
            this.fileTitle = cv.Title;
            this.fileSize = ContentManagerSvc.formatBytes(cv?.ContentDocument?.ContentSize, 1);
            this.fileType = cv?.ContentDocument?.FileType?.toLowerCase();
            this.fileDownloadUrl = constructDownloadUrl(this.contentDocumentId);
            this.fileCreatedByName = cv?.CreatedBy.Name;
            this.fileCreatedByDate = cv?.CreatedDate;
            this.fileCreatedById = cv?.CreatedById;
            this.fileCreatedByPlOption = new PlOption(fileCreatedById, fileCreatedByName, false);
            this.fileClUploadType = cv?.Cash_Logistics_Upload_Type_fileupload__c;
            this.fileUploadStatus = cv?.CL_Upload_Status__c;

        }

        public Integer compareTo(Object objToCompare) {
            FileWrapper compareToWrap = (FileWrapper) objToCompare;
            if (lastModifiedDate == compareToWrap.lastModifiedDate) return 0;
            if (lastModifiedDate < compareToWrap.lastModifiedDate) return 1;
            return -1;
        }

        @TestVisible
        private String constructDownloadUrl(Id contentDocumentId) {
            //return baseUrl + '/' + downloadPath + contentDocumentId;
            return '/' + downloadPath + contentDocumentId;
        }
    }

    @AuraEnabled
    public static ResponseDto retrievePermissions(List<Permission> permissions) {

        ResponseDto dto = new ResponseDto();

        List<Permission> customPerms = new List<Permission>();

        if (permissions != null && !permissions.isEmpty()) {
            dto.isSuccess = true;
            for (Permission perm : permissions) {
                Permission customPerm = new Permission(perm);
                if (perm.name != null) {
                    customPerm.enabled = UserSvc.doesUserHavePermission(perm.name);
                }
                customPerms.add(customPerm);
            }
        }
        dto.values.put(MAP_KEY_PERMISSIONS, customPerms);
        return dto;
    }

    @AuraEnabled
    public static ContentVersion saveFile(Id recordId, String fileName, String csvData) {

        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.VersionData = Blob.valueOf(csvData);
        contentVersion.PathOnClient = '/' + fileName ;
        contentVersion.IsMajorVersion = false;
        contentVersion.CL_Upload_Status__c = 'Uploaded';
        contentVersion.Cash_Logistics_Upload_Type_fileupload__c = 'Route Import Success Log';

        //contentVersion.FileExtension
        insert contentVersion;


        contentVersion = [
                select id, ContentDocumentId,Title,ContentUrl
                from ContentVersion
                WHERE Id = :contentVersion.Id
        ];
        contentVersion = ContentManagerSvc.retrieveContentVersion(contentVersion.contentDocumentId);

        ContentDocumentLink cl = new ContentDocumentLink();
        cl.ContentDocumentId = contentVersion.ContentDocumentId;
        cl.LinkedEntityId = recordId;
        cl.ShareType = 'V';
        cl.Visibility = 'AllUsers';
        insert cl;

        return contentVersion;
    }

    public class PlOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean selected;

        public PlOption(String val, String lbl, Boolean selected) {
            this.value = val;
            this.label = lbl;
            this.selected = selected;
        }
        public Boolean equals(Object obj) {
            if (obj instanceOf PlOption) {
                return this.value == ((PlOption) obj).value;
            }
            return false;
        }
        public Integer hashCode() {
            Integer[] chars = value.getChars();
            Integer returnValueInt = 0;
            for (integer i = 0; i < chars.size(); i++) {
                returnValueInt = returnValueInt + chars[i];
            }
            return (300 * returnValueInt);
        }
    }
    /**
     * Wrapper containing exact column headers of csv import for routes.
     */
    public class RouteImportData {

        @AuraEnabled public String accountId { get; set; }
        @AuraEnabled public String routeName { get; set; }
        @AuraEnabled public String collectionType { get; set; }
        @AuraEnabled public Boolean valid { get; set; }
        @AuraEnabled public String validCssClass { get; set; }
        @AuraEnabled public Integer stopNumber { get; set; }
        @AuraEnabled public Integer rowNumber { get; set; }
        @AuraEnabled public Integer x1FillLevel { get; set; }
        @AuraEnabled public Integer x5FillLevel { get; set; }
        @AuraEnabled public Integer x20FillLevel { get; set; }
        @AuraEnabled public Integer x50FillLevel { get; set; }
        @AuraEnabled public Integer x100FillLevel { get; set; }
        @AuraEnabled public String  replenishmentType {get;set;}
    }

    public class Permission {
        @AuraEnabled public String action { get; set; }
        @AuraEnabled public String name { get; set; }
        @AuraEnabled public Boolean enabled { get; set; }

        public Permission() {
        }
        public Permission(Permission perm) {
            this.action = perm.action;
            this.name = perm.name;
        }
    }

    /**
     * Inserts a new log to be used in this job.
     */
    private static void initLog() {
        log = BatchjobSvc.buildLog(jobName);
        log.Overall_Job_Status__c = AppLogSvc.JOB_STATUS_PROCESSING;
        log.Total_Records_Updated__c = 0;
        log.Total_Records_Processed__c = 0;
        log.Total_Records_Selected__c = 0;
        log.Stack_Trace__c = ' ';
        log.Execution_Details__c = ' ';
        log.JobType__c = 'ApexToken';
    }

    /**
     * Writes job level totals.
     * @param log The current Accel_Application_error__c log in ctx.
     */
    private static void writeFinalLog() {

        if (log != null) {

            log.Execution_Details__c += '\n\n==========   OVERALL Job Totals   =============== \n';
            log.Process_End_Date__c = System.now();
            log.Total_Records_Selected__c = iTotalRecordsSelected;
            log.Total_Records_Processed__c = iTotalRecordsProcessed;
            log.Total_Records_Updated__c = iTotalRecordsUpdated;
            log.Total_Updates_Failed__c = iTotalRecordsFailed;
            log.Execution_Details__c += '* Total Records Selected = ' + iTotalRecordsSelected + '\n';
            log.Execution_Details__c += '* Total Records Attempted to Update = ' + log.Total_Records_Processed__c + '\n';
            log.Execution_Details__c += '* Total Records Updated = ' + log.Total_Records_Updated__c + '\n';
            log.Execution_Details__c += '* Total Updates Failed = ' + mFailedUpdates.size() + '\n';
            //log.Overall_Job_Status__c = 'Success';

            insert log;
        }
    }
}