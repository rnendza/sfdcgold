/**
 * AsyncSvc provides for all operations around Async_Job__c basically this is
 * an object that can be used to keep real time status of Batch, Queuable etc
 * jobs fired and queried via a component.
 */
public class AsyncSvc {

    /**
     * Inserts a record into Async_Job__c
     *
     * @param parentJobId       the SFDC Batch Job Id.
     * @param recordName        the name field in Async_Apex__c
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param className         the apex class name that fired this job.
     * @param parentJobStatus   the status of this particular job.
     * @param overallJobDetails the over all job details (only stored in initiator and stored in json)
     * @param batchGroupStatus  the overall status of the batch group.
     * @param isInitiator       indicates if this is the initiator of a chain of jobs.
     *
     * @return                  An Async_Job__c sObject
     */
    public static Async_Job__c insertAsyncJob(String parentJobId, String recordName, String overallJobStatus,
            String className, String parentJobStatus, String overallJobDetails,
            String batchGroupStatus, Boolean isInitiator) {

        Async_Job__c job = new Async_Job__c(
                Name = recordName,
                Parent_Job_Id__c = parentJobId,
                Apex_Class_Name__c = className,
                Overall_Job_Status__c = overallJobStatus,
                Overall_Job_Details__c = overallJobDetails,
                Parent_Job_Status__c = parentJobStatus,
                Batch_Group_Status__c = batchGroupStatus,
                Is_Initiator__c = isInitiator
        );
        try {
            if (isInitiator) {
                OverallJobDetails ojd = new OverallJobDetails(className + ' - ' + parentJobStatus, overallJobStatus);
                List<OverallJobDetails> ojds = new List<OverallJobDetails>{ ojd};
                String sJSON = JSON.serialize(ojds);
                job.Overall_Job_Details__c = sJSON;
            }
            insert job;
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, e);
            //  @todo log to SFDC object
        }
        return job;
    }
    /**
     * Inserts a record into Async_Job__c
     *
     * @param parentJobId       the SFDC Batch Job Id.
     * @param recordName        the name field in Async_Apex__c
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     *
     * @return                  An Async_Job__c sObject
     */
    public static Async_Job__c insertAsyncJob( String parentJobId, String recordName, String overallJobStatus) {
        return insertAsyncJob(parentJobId, recordName, overallJobStatus,null);
    }

    /**
     * Inserts a record into Async_Job__c
     *
     * @param parentJobId       the SFDC Batch Job Id.
     * @param recordName        the name field in Async_Apex__c
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param className         the apex class name that fired this job.
     *
     * @return                  An Async_Job__c sObject
     */
    public static Async_Job__c insertAsyncJob( String parentJobId, String recordName, String overallJobStatus, String className) {
        return insertAsyncJob(parentJobId, recordName, overallJobStatus, className,null,null);
    }

    /**
     * Inserts a record into Async_Job__c
     *
     * @param parentJobId       the SFDC Batch Job Id.
     * @param recordName        the name field in Async_Apex__c
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param className         the apex class name that fired this job.
     * @param parentJobStatus   the status of this particular job.
     *
     * @return                  An Async_Job__c sObject
     */
    public static Async_Job__c insertAsyncJob(  String parentJobId, String recordName, String overallJobStatus,
                                                String className, String parentJobStatus) {
        return insertAsyncJob(parentJobId, recordName, className, overallJobStatus,parentJobStatus,null);
    }

    /**
     * Inserts a record into Async_Job__c
     *
     * @param parentJobId       the SFDC Batch Job Id.
     * @param recordName        the name field in Async_Apex__c
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param className         the apex class name that fired this job.
     * @param parentJobStatus   the status of this particular job.
     * @param overallJobDetails the over all job details (only stored in initiator and stored in json)
     *
     * @return                  An Async_Job__c sObject
     */
    public static Async_Job__c insertAsyncJob(  String parentJobId, String recordName, String overallJobStatus,
            String className, String parentJobStatus,String overallJobDetails) {
        return insertAsyncJob(parentJobId, recordName, overallJobStatus,className,parentJobStatus, overallJobDetails,null);
    }

    /**
     * Inserts a record into Async_Job__c
     *
     * @param parentJobId       the SFDC Batch Job Id.
     * @param recordName        the name field in Async_Apex__c
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param className         the apex class name that fired this job.
     * @param parentJobStatus   the status of this particular job.
     * @param overallJobDetails the over all job details (only stored in initiator and stored in json)
     * @param batchGroupStatus  the overall status of the batch group.
     *
     * @return                  An Async_Job__c sObject
     */
    public static Async_Job__c insertAsyncJob(  String parentJobId, String recordName, String overallJobStatus,
            String className, String parentJobStatus,String overallJobDetails, String batchGroupStatus) {
        return insertAsyncJob(parentJobId, recordName, overallJobStatus, className, parentJobStatus, overallJobDetails, batchGroupStatus, false);
    }

    /**
     * Retrieves a List of Async_Job__c sObjects
     *
     * @param   asyncJobNames   A Set of the Name values of Async_Job__c.
     * @return                  An List of Async_Job__c sObjects.
     */
    public static List<Async_Job__c> retrieveAsyncJobs( Set<String> asyncJobNames) {
        return  [
                SELECT  Id, Overall_Job_Status__c,Parent_Job_Status__c, Parent_Job_Id__c, Overall_Job_Details__c,
                        Batch_Group_Status__c, Is_Initiator__c
                FROM    Async_Job__c
                WHERE   Name  IN :asyncJobNames
        ];
    }

    /**
     * Retrieves an Async_Job__c sObject.
     *
     * @param   asyncJobName    The Name values of Async_Job__c.
     * @return                  An Async_Job_c sObject.
     */
    public static Async_Job__c retrieveInitiatingAsyncJob( String asyncJobName ) {
        List<Async_Job__c> jobs = [
                SELECT  Id, Overall_Job_Status__c,Parent_Job_Status__c, Parent_Job_Id__c, Overall_Job_Details__c,
                        Batch_Group_Status__c,Is_Initiator__c
                FROM    Async_Job__c
                WHERE   Name  = :asyncJobName
                AND     Is_Initiator__c = TRUE
        ];
        return !jobs.isEmpty() ? jobs[0] : null;
    }
    /**
     * Retrieves an Async_Job__c sObject
     *
     * @param   jobName    The Name values of Async_Job__c.
     * @return                  A
     */
    public static Async_Job__c retrieveAsyncJob( String jobName ) {
        List<Async_Job__c> jobs = retrieveAsyncJobs( new Set<String>{ jobName } );
        return !jobs.isEmpty() ? jobs[0] : null;
    }

    /**
     * Updates an Async Job sObject. Returns the updated sObject.
     *
     * @param jobName           Updates an Async_Job__c sObject.
     * @param parentJobStatus   the status of this particular job.
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param overallJobDetails A list of the over all job details (only stored in initiator and stored in json)
     * @param batchGroupStatus  the overall status of the batch group.
     *
     * @return                  The updated Async_Job__c sObject.
     */
    public static Async_Job__c updateJobStatus( String jobName, String parentJobStatus, String overallJobStatus,
            List<OverallJobDetails> overallJobDetails, String batchGroupStatus) {
        Async_Job__c job = retrieveAsyncJob(jobName);
        if(job!= null) {
            job.Parent_Job_Status__c = parentJobStatus;
            job.Overall_Job_Status__c = overallJobStatus;
            if (overallJobDetails != null && !overallJobDetails.isEmpty()) {
                Async_Job__c initiatingJob = retrieveInitiatingAsyncJob(jobName);
                if (initiatingJob != null && initiatingJob.Overall_Job_Details__c != null) {
                    List<OverallJobDetails> tmpOverallJobDetails =
                            (List<OverallJobDetails>) JSON.deserialize(initiatingJob.Overall_Job_Details__c, List<OverallJobDetails>.class);
                    tmpOverallJobDetails.addAll(overallJobDetails);
                    String newJSON = JSON.serialize(tmpOverallJobDetails);
                    job.Overall_Job_Details__c = newJSON;
                }
            }
            job.Batch_Group_Status__c = batchGroupStatus;
            try {
                update job;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR,e);
                job = null;
                //@todo write to sfdc obj maybe this should throw an exception?
            }
            if(batchGroupStatus == 'Completed') {
                List<Async_Job__c> jobs = retrieveAsyncJobs(new Set<String> {jobName} );
                for(Async_Job__c ajob : jobs) {
                    ajob.Batch_Group_Status__c = 'Completed';
                }
                update jobs;
            }
        }
        return job;
    }
    /**
     * Updates an Async Job sObject. Returns the updated sObject.
     *
     * @param jobName           Updates an Async_Job__c sObject.
     * @param parentJobStatus   the status of this particular job.
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     * @param overallJobDetails A list of the over all job details (only stored in initiator and stored in json)
     *
     * @return                  The updated Async_Job__c sObject.
     */
    public static Async_Job__c updateJobStatus(String jobName, String parentJobStatus, String overallJobStatus,
                                                List<AsyncSvc.OverallJobDetails> overallJobDetails) {
        return updateJobStatus(jobName,parentJobStatus,overallJobStatus, overallJobDetails,null);
    }

    /**
     * Updates an Async Job sObject. Returns the updated sObject.
     *
     * @param jobName           Updates an Async_Job__c sObject.
     * @param parentJobStatus   the status of this particular job.
     * @param overallJobStatus  the overall status of the entire job (chained included) text not pl
     *
     * @return                  The updated Async_Job__c sObject.
     */
    public static Async_Job__c updateJobStatus(String jobName, String parentJobStatus, String overallJobStatus) {
        return updateJobStatus(jobName,parentJobStatus,overallJobStatus,null);
    }

    /**
     * Updates an Async Job sObject. Returns the updated sObject.
     *
     * @param jobName           Updates an Async_Job__c sObject.
     * @param parentJobStatus   the status of this particular job.
     *
     * @return                  The updated Async_Job__c sObject.
     */
    public static Async_Job__c updateJobStatus(String jobName, String parentJobStatus) {
        return updateJobStatus(jobName,parentJobStatus,null);
    }

    /**
     *  An internal class to keep track of job details.
     */
    public class OverallJobDetails {
        public String event {get;set;}
        public String eventDesc {get;set;}

        public OverallJobDetails(String event, String eventDesc) {
            this.event = event;
            this.eventDesc = eventDesc;
        }
    }
}