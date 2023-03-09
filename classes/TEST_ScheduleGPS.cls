@isTest
public class TEST_ScheduleGPS {

public static String CRON_EXP = '0 0 0 15 3 ? 2022';

    @isTest static void test_scheduleGPS(){
            Test.setMock(HttpCalloutMock.class, new GPSLocationMockHttpResponseGenerator());
            Test.StartTest();
            String jobId = System.schedule('testGPS',  CRON_EXP,  new ScheduleGPS());
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,   NextFireTime FROM CronTrigger WHERE id = :jobId];
            System.assertEquals(CRON_EXP,  ct.CronExpression);
            Test.stopTest();
        }
    
 }