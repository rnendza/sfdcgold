@isTest
public class test_sendServiceEmails{

public static String CRON_EXP = '0 0 0 15 3 ? 2022';

   @isTest static void test_sendSEmails(){

        Test.StartTest();
        String jobId = System.schedule('ScheduledServiceReportsTest',  CRON_EXP,  new ScheduledServiceReports());
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,   NextFireTime FROM CronTrigger WHERE id = :jobId];
        System.assertEquals(CRON_EXP,  ct.CronExpression);
        Test.stopTest();
    }
}