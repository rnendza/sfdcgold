public class AsyncApexJobsSvc {

    /**
     * @param jobStatuses    A List of Job Statuses ie. ['queued'].
     * @param apexClassNames The Name of the Apex scheduled class.
     *
     * @return               A list of AsyncApexJob sObjects.
     */
    public static List<AsyncApexJob> retrieveJobInfo(List<String> jobStatuses, List<String> apexClassNames) {

        List<AsyncApexJob> jobs = [
                SELECT  Id, CronTriggerId, ApexClass.Name, CronTrigger.CronJobDetail.Name, CronTrigger.NextFireTime, Status,
                        CronTrigger.StartTime,CronTrigger.State
                FROM    AsyncApexJob
                WHERE   Status          IN :jobStatuses
                AND     ApexClass.Name  IN :apexClassNames
        ];
        return jobs;
    }
}