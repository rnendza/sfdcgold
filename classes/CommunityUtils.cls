/**
 * Community Utils provides for common utility operations originally developed to support the Accel Community;
 */
public class CommunityUtils {

    public static final String  DATE_FORMAT_FULLMONTH_NAME      = 'MMMM';
   /**
    * @param dt     The Date to analyze.
    * @return       The Full monthName.
    * @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
    * @see TEST_CommunityUtils Not really sure if this is right but one who knows
    * could probably look at the test class.
    */
    public static String retrieveFullMonthNameDisplay( Date dt ) {
        String fullMonthName = '';
        if(dt != null) {
            fullMonthName = ((Datetime)dt).format(DATE_FORMAT_FULLMONTH_NAME);
        }
        return fullMonthName;
    }
    /**
     * Internal method to see if the current time is in a time where hpd data is not available.
     *
     * @param timeNow   The current Time. Generally included as parm as opposed to internal to assist with testing.
     * @param timeMin   The min time in the range.. ie Midnight or whatever is passed.
     * @param timeMax   The max time in the range.. ie 9am  or whatever is passed.
     * @return          True if we are in the Hpd Data Dark Zone, otherwise False.
     * @see             https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
     * @todo            deprecate when validated there ar no client references to this.
     * @deprecated
     */
    private static  Boolean isHpdDataDarkZone(Time timeNow, Time timeMin, Time timeMax) {
        Boolean isDark = false;
        if(timeNow != null && timeMin != null && timeMax != null) {
            Boolean isWithin       = ( timeMin <= timeNow && timeNow < timeMax );
            isDark = isWithin;
        } else {
            System.debug(LoggingLevel.ERROR,'pass the right values you dope!');
        }
        return isDark;
    }

    /**
     * Determines if HPD is available for the current day or not.
     *
     * @param timeNow   The current SFDC Time instance. (passed as opposed to internal for better testing )
     * @return          True if we are in the Hpd Data Dark Zone, otherwise False.
     * @see             https://accel-entertainment.monday.com/boards/286658657/pulses/293969060
     * @todo            remove when validated there are no client references to this.
     * @deprecated
     */
    public static Boolean isHpdDarkZone(Time timeNow) {
        Time    timeMin        = Time.newInstance(24,0,0,0);// @TODO pull from custom meta.
      //  Time    timeMax        = Time.newInstance(09,0,0,0);// @TODO pull from custom meta.
        Time    timeMax        = Time.newInstance(09,15,0,0);// @TODO pull from custom meta.
        return isHpdDataDarkZone(timeNow,timeMin,timeMax);
    }
    /**
     * This date is decided by the batch job that updates Hold_Per_Day__c records of record type 'Daily_Aggregate'
     * which runs around 9am everyday. if enough were created, yesterdays date will be returned, otherwise the date
     * that was previously stored in there will be returned.
     *
     * @return the latest hpd date field.
     * @see AggregateMachineHpd
     * @see Batch_Settings__c
     */
    public static Date getMostRecentHpdDate() {
        Batch_Settings__c settings = Batch_Settings__c.getOrgDefaults();
        Date hpdDate = settings.Most_Recent_Hpd_Date__c != null ? settings.Most_Recent_Hpd_Date__c : null;
        return hpdDate;
    }
    /**
     * A simple convienence wrapper to support legacy code.
     * @return true if the most recent hpd date is more then 1 day prior.
     */
    public static Boolean getHpdDark() {
        return getMostRecentHpdDate() < Date.today().addDays(-1);
    }
}