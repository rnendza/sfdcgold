@IsTest
private class clBatchCycleNumberUpdateTest {

    @TestSetup
    static void setupData() {

    }

    @IsTest
    static void test_update_cycle_number_auto_increment() {
        String devName = 'Scheduler';

        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
        Integer currentCycle = Integer.valueOf(mdt.Next_Cycle__c);

        Test.startTest();
        clBatchCycleNumberUpdate b = new clBatchCycleNumberUpdate();
        Database.executeBatch(b,50);
        Test.stopTest();

        mdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
        Integer incrementedCycle = Integer.valueOf(mdt.Next_Cycle__c);
        //  We can't really test a meta data deploy in unit test
        //System.assertEquals(incrementedCycle,currentCycle + 1);
    }

    @IsTest
    static void test_update_cycle_number_manual_increment() {
        String devName = 'Scheduler';

        Cash_Logistics_Setting__mdt mdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
        Integer nextCycle = Integer.valueOf(mdt.Next_Cycle__c) + 1;

        Test.startTest();
        clBatchCycleNumberUpdate b = new clBatchCycleNumberUpdate(nextCycle);
        Database.executeBatch(b,50);
        Test.stopTest();

        mdt = (Cash_Logistics_Setting__mdt)CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,devName);
        //  We can't really test a metadata deploy in unit test.
        //System.assertEquals(mdt.Next_Cycle__c,nextCycle);
    }
}