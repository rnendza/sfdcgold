public class ScheduleGPS implements Schedulable {

    public void execute(SchedulableContext ctx){
        System.enqueueJob(new GetGPS());
    }
}