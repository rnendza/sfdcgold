global class ScheduledServiceReports implements Schedulable {
       
    //cron var for 1:05 am each day
    public static String CRON_EXP = '0 5 1 * * ?';
    
    //cron var for testing every minute
    public static String CRON_TEST = '0 1 * * * ?';
    
    global void execute(SchedulableContext ctx) {
        SendServiceEmails.sendServiceEmails();
    }
}