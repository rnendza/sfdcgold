/**
 * Sample Schedule Script
 * ============================
 *
 *  // run every day at 5pm
 *  Sch_BatchSweepstakesLocUpdate schJob = new Sch_BatchSweepstakesLocUpdate();
 *  String cron = '0 0 17 * * ?';
 *  system.schedule('BatchsweepstakesLocUpdate', cron, schJob);
 *
 * Schedule doc.
 *
 * second minute hour day_of_month month day_of_week optional_year
 *
 * second:        0 (this doesn't actually do anything)
 * minute:        0–59
 * hour:          0-23
 * day_of_month:  1-31 - * ? / L W
 * month:         1-12 JAN-DEC , - * /
 * day_of_week:   1-7 SUN-SAT , - * ? / L #
 * optional_year: null or 1970–2099 , - * /
 *
 * Character   Description
 * ,           Delimits values. Example: JAN, MAR, APR
 * -           Specifies a range. Example: JAN-MAR
 * *           Specifies all values
 * ?           Specifies no specific value
 * /           Specifies increments. Example: Day_of_month = 1/5, the will run every fifth day of the month, starting on the first of the month.
 * L           Specifies the end of a range (last). See docs for more details
 * W           Specifies the nearest weekday of the given day. Example: 20W. If 20th is a Saturday, the class runs on the 19th
 * #           Specifies the nth day of the month, in the format weekday#day_of_month. Example: 2#2 means the class runs on the second Monday of every month.
 * ============================
 */
public class cl_Sch_BatchRouteScheduleCreation  implements Schedulable {

    public static Integer DEFAULT_BATCH_SIZE = 50;
    public static String  SCHEDULER_MDT_DEV_NAME = 'Scheduler';

    public String region;

    public cl_Sch_BatchRouteScheduleCreation () {}

    public cl_Sch_BatchRouteScheduleCreation(String pRegion) {
        this.region = pRegion;
        System.debug('---> rs sch region passed:'+this.region);
    }

    /**
     * @param ctx  The context of the scheduled job.
     */
    public void execute(SchedulableContext ctx) {

        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,SCHEDULER_MDT_DEV_NAME);
        Integer iNextCycle = Integer.valueOf(mdt.Next_Cycle__c);

        clBatchRouteScheduleCreation b;
        System.debug('---> rs sch exe region used to pass to batch constr:'+this.region);
        if(this.region != null) {

            b = new clBatchRouteScheduleCreation(iNextCycle,region);
        } else {
            b = new clBatchRouteScheduleCreation(iNextCycle);
        }
        Id jobId = Database.executeBatch(b,DEFAULT_BATCH_SIZE);
        System.debug(LoggingLevel.INFO,'Executing batch job cl_Sch_BatchRouteScheduleCreation Id='+jobId+' with a batch size of '+DEFAULT_BATCH_SIZE);
    }
}