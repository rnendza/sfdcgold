/**
 * PlatformEventSvc is a general class to wrap operations pertains to SFDC Platform Events.
 * @see EventBus
 */
public class PlatformEventSvc {

    public static final String DML_ACTION_INSERT = 'INSERT';
    public static final String DML_ACTION_UPDATE = 'UPDATE';
    public static final String DML_ACTION_DELETE = 'DELETE';
    public static final String MDT_ACTION_UPDATE = 'MDT_UPDATE';

    /**
     * Publish a list of events!
     * @param platformEvents
     */
    public static void publishPlatformEvents( List<SObject> platformEvents ) {

        List<Database.SaveResult> pubResults = EventBus.publish( platformEvents );
        for ( Database.SaveResult sr : pubResults ) {
            if ( sr.isSuccess() ) {
                    System.debug(LoggingLevel.INFO, 'pub successful:'+sr.getId());
            } else {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR,'Error returned: ' + err.getStatusCode() + ' - ' + err.getMessage());
                    System.debug(LoggingLevel.ERROR,'Error returned fields: ' + err.getFields());
                }
            }
        }
    }
}