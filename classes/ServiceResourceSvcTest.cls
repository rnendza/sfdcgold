@IsTest
private class ServiceResourceSvcTest {


    @TestSetup
    static void setup() {
        Test.startTest();

        List<ServiceResource> srs = new List<ServiceResource>();
        String testDeviceId = GeoTabUtils.TEST_DEVICE_IDS[0];
        srs.add(AccelTestHarness.buildSingleServiceResource(UserInfo.getName(), UserInfo.getUserId(), testDeviceId));
        insert srs;

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveGpsServiceResources() {

        Map<Id,ServiceResource> testSrvs = new Map<Id,ServiceResource>([SELECT Id FROM ServiceResource]);

        Test.startTest();
        List<ServiceResource> serviceResources = ServiceResourceSvc.retrieveGpsServiceResources();
        for(ServiceResource sr : serviceResources) {
            System.assert(testSrvs.keySet().contains(sr.Id));
        }
        Test.stopTest();
    }

    @IsTest
    static void testRetrieveGpsServiceResourceNames() {

        List<ServiceResource> testSrs = [SELECT Id,Name FROM ServiceResource];
        Set<String> srNames = new Set<String>();
        for(ServiceResource testSr : testSrs) {
            srNames.add(testSr.Name);
        }

        Test.startTest();
        List<ServiceResource> serviceResources = ServiceResourceSvc.retrieveGpsServiceResourceNames();
        for(ServiceResource sr : serviceResources) {
            System.assert(srNames.contains(sr.Name));
        }
        Test.stopTest();
    }

    @IsTest
    static void testRetrieveServiceResourceHistories() {

        Map<Id,ServiceResource> testSrvs = new Map<Id,ServiceResource>([SELECT Id FROM ServiceResource]);
        Set<String> fieldNames = new Set<String>{ServiceResource.LastKnownLocationDate.getDescribe().getName()};

        Test.startTest();

        List<ServiceResourceHistory> serviceResourceHistories =
                ServiceResourceSvc.retrieveServiceResourceHistories(testSrvs.keySet(),fieldNames,10);

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveTrackedFields() {

        Test.startTest();

        List<FieldDefinition> fieldDefinitions = ServiceResourceSvc.retrieveTrackedFields('Account');

        Test.stopTest();
    }
}