global class PortalAdvisory_Sch_Import implements Schedulable {

    global void execute(SchedulableContext ctx) {
        Id jobId = System.enqueueJob( new PortalAdvisoryQueueableImport() );
        System.debug('---> firing queueable jobId='+jobId);
    }
}