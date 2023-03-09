/**
 * Created by rnend on 8/12/2021.
 */

@IsTest
private class clBatchMeterReadingsCreationTest {
    /**
     * NOTE start / stop test merely there to reset gov limits as creating non cl data takes forever given
     * all the processors / flows and eventually will bust cpu time outs on it's own.
     */
    @TestSetup
    static void setupData() {

        Test.startTest();
        Map<String,Object> mBaseData = clTESTUTILS.createAllNonClData();
        Test.stopTest();

        Map<String,Object> mClData =  clTESTUTILS.createEnd2EndRouteData(mBaseData);
    }


    @IsTest
    static void test_exeBatch() {

        Map<Id,Route_Processing_Sheet__c> m = new Map<Id,Route_Processing_Sheet__c>([SELECT Id FROM Route_Processing_Sheet__c LIMIT 2]);
        Test.startTest();

        clBatchMeterReadingsCreation b = new clBatchMeterReadingsCreation(m.keySet());
        Database.executeBatch(b,2);

        Test.stopTest();


        Map<Id,Meter_Reading__c> mMeters = clMeterSvc.retrieveRpsMeterReadings(m.values()[0].Id);
        for(Meter_Reading__c mr : mMeters.values()) {
            System.assertEquals(mr.BV_Type__c,clTESTUTILS.ASSET_BV_TYPE_JCM);
        }
    }

    @IsTest
    static void test_exeBatch_no_assets() {

        Map<Id,Route_Processing_Sheet__c> m = new Map<Id,Route_Processing_Sheet__c>(
            [SELECT Id,Account__c FROM Route_Processing_Sheet__c LIMIT 2]
        );

        Set<Id> accountIds = new Set<Id>();
        for(Route_Processing_Sheet__c rps : m.values()) {
            accountIds.add(rps.Account__c);
        }
        List<Meter_Reading__c> mrs = [SELECT Id FROM Meter_Reading__c];
        Boolean deleteFailed = false;
        try {
            delete mrs; //  DELETE Any existing test meter readings created in the setup method.
        } catch (Exception e) {
            deleteFailed = true;
            System.debug(LoggingLevel.INFO,e);  // @todo org prevented deletes will make this crash!
        }
        List<Asset> assets = [SELECT Id FROM Asset WHERE AccountId IN :accountIds];
        delete assets; // DELETE Test Assets for locations for rps sheets in test ctx.

        Test.startTest();

        clBatchMeterReadingsCreation b = new clBatchMeterReadingsCreation(m.keySet());
        Database.executeBatch(b,2);

        Test.stopTest();


        Map<Id,Meter_Reading__c> mMeters = clMeterSvc.retrieveRpsMeterReadings(m.values()[0].Id);
        System.debug('---> meters='+mMeters);
        if(!deleteFailed) {
            System.assert(mMeters.isEmpty());
        }
    }

    @IsTest
    static void test_exeBatch_logging() {

        Map<Id,Route_Processing_Sheet__c> m = new Map<Id,Route_Processing_Sheet__c>([SELECT Id FROM Route_Processing_Sheet__c LIMIT 2]);
        Test.startTest();

        clBatchMeterReadingsCreation b = new clBatchMeterReadingsCreation(m.keySet());
        Database.executeBatch(b,2);

        Test.stopTest();

        Accel_Application_Error__c log = [
                SELECT Id,Job_Name__c,Execution_Details__c
                FROM   Accel_Application_Error__c
                WHERE  Job_Name__c = 'clBatchMetersCreation'
                AND    CreatedDate = TODAY
        ];
        System.debug('---> exelog='+log.Execution_Details__c);
        System.assert(log.Execution_Details__c.contains('RPSMeterIds'));
    }
}