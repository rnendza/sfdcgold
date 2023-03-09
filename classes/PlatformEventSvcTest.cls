@IsTest
private class PlatformEventSvcTest {

    @IsTest
    static void test_publishPlatformEvents_success() {

        List<SObject> sObjects = new List<SObject>();
        Record_Updated_Event__e recordUpdatedEvent = new Record_Updated_Event__e();
        recordUpdatedEvent.Record_Ids__c = 'blahid';
        recordUpdatedEvent.SObject_API_Name__c = 'Account';
        sObjects.add(recordUpdatedEvent);

        Test.startTest();
        PlatformEventSvc.publishPlatformEvents(sObjects);
        Test.stopTest();
    }

    @IsTest
    static void test_publishPlatformEvents_error() {

        List<SObject> sObjects = new List<SObject>();
        sObjects.add(new Account());

        Test.startTest();
        PlatformEventSvc.publishPlatformEvents(sObjects);
        Test.stopTest();
    }
}