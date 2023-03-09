@IsTest
private class AccelFslShowRecentCasesControllerTest {

    private static final String CALLCENTERUNAME             = 'callcenterdude@dude.com';
    private static final User uCallCenter                   = TestUtils.getUserForTest( CALLCENTERUNAME );

    @TestSetup
    static void setupData() {
        Test.startTest();
        TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
        TestUtils.createAllDataToServiceAppointments( params );
        Test.stopTest();
    }

    @IsTest
    static void test_retrieveRecentCases_success() {

        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;

        System.runAs(uCallCenter) {
            ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
            AccelFslShowRecentCasesController.CaseParams caseParams = new AccelFslShowRecentCasesController.CaseParams();
            caseParams.svcAppointmentId = sa.Id;

            Test.startTest();

            ResponseDto dto = AccelFslShowRecentCasesController.retrieveRecentCases(caseParams);
            System.debug('dto-->'+dto);
            //  @todo asserts!
            Test.stopTest();
        }
    }


    @IsTest
    static void test_retrieveRecentCases_nullSaId() {

        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;

        System.runAs(uCallCenter) {
            AccelFslShowRecentCasesController.CaseParams caseParams = new AccelFslShowRecentCasesController.CaseParams();

            Test.startTest();

            ResponseDto dto = AccelFslShowRecentCasesController.retrieveRecentCases(caseParams);
            System.assert(!dto.isSuccess);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveRecentCases_invalidParams() {

        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;

        System.runAs(uCallCenter) {
            ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
            AccelFslShowRecentCasesController.CaseParams caseParams = new AccelFslShowRecentCasesController.CaseParams();
            caseParams.svcAppointmentId = sa.Id;
            caseParams.excludedStatuses = null;

            Test.startTest();

            ResponseDto dto = AccelFslShowRecentCasesController.retrieveRecentCases(caseParams);
            System.assert(!dto.isSuccess);
            System.assertEquals(AccelFslShowRecentCasesController.SEVERITY_ERROR,dto.severity);
            Test.stopTest();
        }
    }

    @IsTest
    static void test_retrieveRecentCases_invalidDateLiteral() {

        uCallCenter.profileId = [SELECT Id from Profile where Name = 'Accel Call Center']?.Id;
        update uCallCenter;

        System.runAs(uCallCenter) {
            ServiceAppointment sa = [SELECT Id FROM ServiceAppointment LIMIT 1];
            AccelFslShowRecentCasesController.CaseParams caseParams = new AccelFslShowRecentCasesController.CaseParams();
            caseParams.svcAppointmentId = sa.Id;
            caseParams.includedCreatedDateLiteral = ' BAD DATE LITERAL ';

            Test.startTest();

            ResponseDto dto = AccelFslShowRecentCasesController.retrieveRecentCases(caseParams);
            System.assert(!dto.isSuccess);
            System.assertEquals(AccelFslShowRecentCasesController.SEVERITY_ERROR,dto.severity);
            Test.stopTest();
        }
    }

}