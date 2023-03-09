public class PortalAdvisoryQueueableDateIncrement implements Queueable {

    public static final String  PA_ADVISORY_IMPORT_MDT_TYPE_DEV_NAME     = 'PA_Advisory_Import';
    public static final String  DEFAULT_ENDPOINT_DEV_NAME                = 'PGCBSelfExclusionService_Prod';
    public static final String  COMMUNITY_SETTING_NAME                   = 'Community_Async_Job_Setting__mdt';
    public static Integer       DAYS_TO_ADD                              = 1;

    public static Community_Async_Job_Setting__mdt mdtCommunityAsyncJobSetting =
            CommunityAsyncSettings.retrieveCommunityAsyncMdt(PA_ADVISORY_IMPORT_MDT_TYPE_DEV_NAME);

    public Date startDate,endDate;
    public PortalAdvisoryQueueableDateIncrement() {}

    public void execute(QueueableContext ctx) {
        ResponseDto dto = this.incrementMdtDateValues();
        System.debug(LoggingLevel.DEBUG,'--> increment Mdt Response Dto:'+dto);
    }

    @TestVisible
    private ResponseDto incrementMdtDateValues() {

        ResponseDto dto = new ResponseDto();

        String mdtName          = COMMUNITY_SETTING_NAME;
        String recordDevName    = PA_ADVISORY_IMPORT_MDT_TYPE_DEV_NAME;
        String label            = PA_ADVISORY_IMPORT_MDT_TYPE_DEV_NAME;

        Date newStartDate;
        Date newEndDate;

        if(startDate != null && endDate != null) {
            newStartDate = startDate;
            newEndDate = endDate;
        } else {
            newStartDate = mdtCommunityAsyncJobSetting.Start_Date__c.addDays(DAYS_TO_ADD);
            newEndDate    =newStartDate.addDays(DAYS_TO_ADD);
        }

        Map<String,Object> mFields = new Map<String,Object>();
        mFields.put('Start_Date__c',newStartDate);
        mFields.put('End_Date__c',newEndDate);

        Id jobId = PortalAdvisoryLoaderSvc.updateCustomMetadata(mdtName,recordDevName,label,mFields);
        dto.isSuccess = true;
        dto.message = 'Running job ' + jobId + ' to update custom metadata. You will be notified when complete.';
        dto.severity = 'info';

        return dto;
    }
}