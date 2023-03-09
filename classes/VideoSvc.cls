public class VideoSvc {
    /**
     * @param settingsRecord  The Custom Metadata settings record (ie. Community)
     * @return a SObject containing Video_Setting__mdt otherwise will probably throw an exception.
     */
    public static SObject retrieveVideoCustomSettings( String settingsRecord) {
        return CustomMetadataSvc.retrieveCustomSearchMeta(Video_Setting__mdt.getSObjectType(), settingsRecord);
    }
}