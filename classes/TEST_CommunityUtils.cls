@IsTest
private class TEST_CommunityUtils {

    public static Time time_1100                = Time.newInstance(11,0,0,0);
    public static Time time_0500                = Time.newInstance(05,0,0,0);

    public static String UNAME = 'acceltest@accel.com';

    @TestSetup
    static void setup() {
        User u = TestUtils.getUserForTest(new TestUtils.SecSettings('', UNAME, '', '', ''), Datetime.now());


        List<SObject> sObjs = new List<SObject>();
        String settingName = 'Batch_Settings__c ' + UserInfo.getOrganizationId();
        sObjs.add(new Batch_Settings__c(Name = settingName, SetupOwnerId = UserInfo.getOrganizationId(),
                Most_Recent_Hpd_Date__c  = Date.today().addDays(-1)));

        insert sObjs;
    }

    /**
     * Tests getting the month name for the 1st of the month, last of the month, 2nd of the month,
     * and the current test run date
     */
    @IsTest
    static void test_RetrieveFullMonthNameDisplay_Positive() {

        Test.startTest();
        // -- Test the first of month..
        Date dFirstOfMonth = Date.newInstance(2019, 08, 01);
        String displayMonth = CommunityUtils.retrieveFullMonthNameDisplay(dFirstOfMonth);
        System.assertEquals(displayMonth, 'July');

        // --Test the last of month
        Date dLastOfMonth = Date.newInstance(2019, 07, 31);
        displayMonth = CommunityUtils.retrieveFullMonthNameDisplay(dLastOfMonth);
        System.assertEquals(displayMonth, 'July');

        // --Test the Second of the month.
        Date dSecondOfMonth = Date.newInstance(2019,08 , 01).addDays(1);
        displayMonth = CommunityUtils.retrieveFullMonthNameDisplay(dSecondOfMonth);
        System.assertEquals(displayMonth, 'August');

        // --Test the current day (hopefully nightly regression tests will fail on a particular day if there is a bug
        Date yesterdayDay = Date.today().addDays(-1);
        displayMonth = CommunityUtils.retrieveFullMonthNameDisplay(yesterdayDay);
        System.assertEquals(displayMonth, (((Datetime) yesterdayDay).format(CommunityUtils.DATE_FORMAT_FULLMONTH_NAME)));

        Test.stopTest();

    }
    @IsTest
    static void test_IsHpdDarkZone_Legacy_Positive() {
        Test.startTest();

        System.assertEquals(CommunityUtils.isHpdDarkZone(time_0500),true);
        System.assertEquals(CommunityUtils.isHpdDarkZone(time_1100),false);

        Test.stopTest();
    }

    /**
    * Simply test sending a null date.
    */
    @IsTest
    static void test_RetrieveFullMonthNameDisplay_Negative() {
        Test.startTest();
        String displayMonth = CommunityUtils.retrieveFullMonthNameDisplay(null);
        System.assertEquals(displayMonth, '');
        Test.stopTest();
    }
    @IsTest
    static void test_getMostRecentHpd_Positive() {
        Test.startTest();
        System.assertEquals(CommunityUtils.getMostRecentHpdDate(),Date.today().addDays(-1));
        Test.stopTest();
    }
    @IsTest
    static void test_getHpdDarkPositive() {
        Test.startTest();
        System.assertEquals(CommunityUtils.getHpdDark(),false);
        Test.stopTest();
    }
}