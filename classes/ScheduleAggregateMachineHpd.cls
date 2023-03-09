public class ScheduleAggregateMachineHpd implements Schedulable {

    public void execute(SchedulableContext ctx){
        System.enqueueJob(new AggregateMachineHpd());
    }
}