@IsTest
private class GeoTabServiceResourceControllerTest {

    @TestSetup
    static void setup() {

        Test.startTest();

        List<ServiceResource> srs = new List<ServiceResource>();
        String testDeviceId = GeoTabUtils.TEST_DEVICE_IDS[0];
        srs.add(AccelTestHarness.buildSingleServiceResource(UserInfo.getName(),UserInfo.getUserId(),testDeviceId));
        insert srs;

        List<ServiceResourceHistory> serviceResourceHistories = new List<ServiceResourceHistory>();
        for(ServiceResource sr : srs) {
            ServiceResourceHistory hist = new ServiceResourceHistory(
                ServiceResourceId = sr.Id,
                Field = GeoTabServiceResourceController.DEFAULT_HIST_FIELD_API_NAME
            );
            serviceResourceHistories.add(hist);
        }
        insert  serviceResourceHistories;

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

        ResponseDto dto = GeoTabServiceResourceController.retrieveGpsServiceResourceUsers();
        List<GeoTabServiceResourceController.ServiceResourceUserWrapper> userWrappers =
                (List<GeoTabServiceResourceController.ServiceResourceUserWrapper>)
                        dto.values.get(GeoTabServiceResourceController.MAP_KEY_SERVICE_RESOURCE_USERS);

        for(GeoTabServiceResourceController.ServiceResourceUserWrapper wrap : userWrappers) {
            System.assert(srNames.contains(wrap.srName));
        }
        Test.stopTest();
    }

    @IsTest
    static void testRetrieveServiceResourceHistories() {

        Map<Id,ServiceResource> mSrs = new Map<Id,ServiceResource>([SELECT Id,Name FROM ServiceResource]);

        Test.startTest();

        ResponseDto dto = GeoTabServiceResourceController.retrieveServiceResourceHistories(mSrs.values()[0].Id,
                        new List<String>{GeoTabServiceResourceController.DEFAULT_HIST_FIELD_API_NAME},200);

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveServiceResourceHistories_LastKnownLocation() {

        Map<Id,ServiceResource> mSrs = new Map<Id,ServiceResource>([SELECT Id,Name FROM ServiceResource]);

        Test.startTest();

        ResponseDto dto = GeoTabServiceResourceController.retrieveServiceResourceHistories(mSrs.values()[0].Id,
                new List<String>{'LastKnownLocation'},200);

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveAllTrackedFields() {


        Test.startTest();

        ResponseDto dto = GeoTabServiceResourceController.retrieveAllTrackedFields('ServiceResource');

        Test.stopTest();
    }
}