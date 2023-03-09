public with sharing class VideoController {

    public static String MAP_KEY_VIDEO_METADATA = 'VIDEO_METADATA';

    /**
     * Retrieves custom Video Metadata.
     * @param settingsRecord  ie. Community
     * @return a ResponseDto Object with a Map of Key => SObject in it's values map
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveVideoMetadata(String settingsRecord) {
        ResponseDto dto = new ResponseDto();
        SObject sObj;
        try {
            sObj = VideoSvc.retrieveVideoCustomSettings(settingsRecord);
        } catch (Exception e) {
            dto.technicalMsg = 'SettingsRecord='+settingsRecord + '...'+e.getMessage();
            dto.message = 'Could not locate metadata for '+settingsRecord;
            dto.severity = 'error';
        }
        if(sObj != null) {
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_VIDEO_METADATA,sObj);
        }
        return dto;
    }
}