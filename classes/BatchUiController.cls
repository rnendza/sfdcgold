public with sharing class BatchUiController {

    /**
     * Retrieves Async Apex jobs from the Standard SFDC AsyncApexJob sObject using Job Ids stored in custom
     * Async_Job__c.  This is done due to the inability to track groups of chained jobs.
     *
     * @param apexClassNames       @todo deprecate
     * @param jobId                The ApexAsyncJob. Id
     * @param bChain               @todo deprecate.
     * @param asyncJobName         The Async_Job__c.Name value used to pull all the job ids.
     *
     * @return                     A responseDto containing a List of AsyncApexJob sObjects and a single Async_Job__c sObject.
     */
    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrieveAsyncApexJobs(List<String> apexClassNames, String jobId,
                                                    Boolean bChain, String asyncJobName) {
        ResponseDto dto = new ResponseDto();

        List<Async_Job__c> asyncJobs =  [
                SELECT Id, Parent_Job_Id__c, Apex_Class_Name__c,Overall_Job_Status__c,
                        Parent_Job_Status__c,Overall_Job_Details__c,Batch_Group_Status__c
                FROM   Async_Job__c
                WHERE  Name = :asyncJobName
        ];
        if(!asyncJobs.isEmpty()) {
            Async_Job__c job = asyncJobs[0];

            List<String> jobIds = new List<String>{jobId};
            Set<Id> allJobIds = new Set<Id>();
            for(Async_Job__c asyncJob : asyncJobs) {
                allJobIds.add(asyncJob.Parent_Job_Id__c);
            }
            String soql = '';
            soql += ' SELECT Id,JobType,JobItemsProcessed,TotalJobItems,Status, ';
            soql += '        ApexClassId,MethodName,NumberOfErrors, ApexClass.Name, CreatedDate, ';
            soql += '        CompletedDate, CreatedBy.Username ';
            soql += ' FROM   AsyncApexJob ';
            soql += ' WHERE   Id IN :allJobIds ';
            soql += ' ORDER BY CreatedDate ASC ';
            soql += ' LIMIT 5';

            List<AsyncApexJob> jobs = Database.query(soql);
            dto.technicalMsg = 'returning '+ jobs.size() + ' job records';
            dto.values.put('jobs',jobs);
            dto.values.put('async_job_record',job);
            dto.isSuccess = true;
        } else {
            dto.isSuccess = false;
            dto.technicalMsg = 'No async found found yet for jobId: '+jobId;
        }
        return dto;
    }
    @AuraEnabled(Cacheable=false)
    public static ResponseDto retrieveAllAsyncApexJobsToday(Id userId) {
        ResponseDto dto = new ResponseDto();

        List<AsyncApexJob> apexJobs =  [
                SELECT Id, JobType,JobItemsProcessed,TotalJobItems,Status,ApexClassId,MethodName,NumberOfErrors,
                        ApexClass.Name,CreatedDate,CompletedDate,CreatedBy.Username
                FROM   AsyncApexJob
                WHERE  CreatedById = :userId
                AND    CreatedDate = TODAY
                AND    JobType = 'BatchApex'
                ORDER BY CreatedDate DESC
        ];
        if(!apexJobs.isEmpty()) {
            dto.values.put('jobs',apexJobs);
            dto.isSuccess = true;
        } else {
            dto.isSuccess = false;
            dto.technicalMsg = 'No apex jobs initialed by '+userId + ' today';
        }
        return dto;
    }
    /**
     *
     *
     * @param name
     * @return
     */
    @AuraEnabled(Cacheable=false)
    public static List<Async_Job__c> retrieveAsyncJobs(String name) {
         return  [
          SELECT Id, Name,Parent_Job_Id__c,Apex_Class_Name__c,Overall_Job_Status__c,Overall_Job_Details__c,Batch_Group_Status__c
          FROM   Async_Job__c
          WHERE  Name = :name
        ];
    }
    /**
     *
     * @param batchSize
     * @param sourceAcctId
     * @param targetAcctId
     * @param commitTrans
     * @param chainJobs
     *
     * @return
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto fireBatchTransferHpdMonthlies(Integer batchSize, Id sourceAcctId, Id targetAcctId,
                                                            Id recipientEmailUserId,
                                                            Boolean commitTrans, Boolean chainJobs ) {
        ResponseDto dto = new ResponseDto();
        dto.isSuccess = true;
        Map<Id,Id> mSourceAcctId_TargetAcctId = new Map<Id,Id> {sourceAcctId => targetAcctId};
        String recipientUserEmail = null;
        if(recipientEmailUserId != null) {
            User u = retrieveUserDetails(recipientEmailUserId);
            if(u != null) {
                recipientUserEmail = u.email;
            }
        }

        BatchTransferHpdMonthlies b = new BatchTransferHpdMonthlies(mSourceAcctId_TargetAcctId,recipientEmailUserId,
                                                                    commitTrans,chainJobs);
       String async_job_name = b.asyncJobName;

        Id batchId = Database.executeBatch(b,batchSize);
        dto.values.put('batchId',batchId);
        dto.values.put('async_job_name',async_job_name);
        return dto;
    }
    /**
     *
     * @param userId
     * @return
     */
    @AuraEnabled(Cacheable=true)
    public static User retrieveUserDetails(Id userId) {
        User user = UserSvc.retrieveUserDetails(userId);
        return user;
    }

    @AuraEnabled(Cacheable=true)
    public static CompletedAccountResult retrieveCompletedAccountData(Id accountId) {

        CompletedAccountResult car;
        Account account;
        if(accountId != null) {
            account = [
                    SELECT  Id, Name, Type, Most_Recent_Hold_Per_Day__c, Most_Recent_Hold_Per_Day__r.Name,
                            Most_Recent_Hold_Per_Day__r.Date__c,
                            Hold_Per_Day_Total__r.Name,Hold_Per_Day_Total__c
                    FROM    Account
                    WHERE   Id = :accountId
            ];
            car = new CompletedAccountResult(account);
            List<AggregateResult> ars = [
                    SELECT COUNT(Id) totalHpds
                    FROM   Hold_Per_Day__c
                    WHERE  RecordType.DeveloperName = 'Monthly_Hpd'
                    AND    Account__c = :accountId
            ];
            if(!ars.isEmpty()) {
                Integer iTotal = (Integer)ars[0].get('totalHpds');
                car.totalHpds = iTotal;
            }
        }
        return car;
    }
    public class CompletedAccountResult{

        @AuraEnabled public Id accountId {get;set;}
        @AuraEnabled public String accountName {get;set;}
        @AuraEnabled public String accountType {get;set;}
        @AuraEnabled public Id mostRecentHpdId {get;set;}
        @AuraEnabled public String mostRecentHpdName {get;set;}
        @AuraEnabled public Date mostRecentHpdDate {get;set;}
        @AuraEnabled public Id hpdTotalId {get;set;}
        @AuraEnabled public String hpdTotalName {get;set;}
        @AuraEnabled public Integer totalHpds {get;set;}

        CompletedAccountResult(Account account) {
            this.accountId = account.Id;
            this.accountName = account.Name;
            this.accountType = account.Type;
            this.mostRecentHpdId = account.Most_Recent_Hold_Per_Day__c;
            this.mostRecentHpdName = account.Most_Recent_Hold_Per_Day__r.Name;
            this.mostRecentHpdDate = account.Most_Recent_Hold_Per_Day__r.Date__c;
            this.hpdTotalId = account.Hold_Per_Day_Total__c;
            this.hpdTotalName = account.Hold_Per_Day_Total__r.Name;
            this.totalHpds = 0;
        }
    }
}