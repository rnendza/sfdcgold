@IsTest
private class PaAdvisoryGallerySvcTest {
    @TestSetup
    static void setupData() {
        Test.startTest();
        Map<String, Object> mPortalAdminData = PortalAdminTestUtils.createAllPaData();
        Test.stopTest();

        PA_Advisory__c paAdvisory = PortalAdminTestUtils.buildPaAdvisoryData(1)[0];
        paAdvisory.Advisory_Number__c = 'VGT-000864'; //  this is in the mock xml
        insert paAdvisory;
    }


    @IsTest
    static void testRetrievePaAdvisories_success() {

        List<PA_Advisory__c> allRecords =  [SELECT Id FROM PA_Advisory__c];

        Test.startTest();
        Date advisoryStartDate = null;
        Date advisoryEndDate = null;
        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisories(50000,advisoryStartDate,advisoryEndDate);
        System.assertEquals(allRecords.size(),advisories.size());

        advisoryStartDate = Date.today().addDays(-7);
        advisoryEndDate = date.today().addDays(1);
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisories(50000,advisoryStartDate,advisoryEndDate);

        Test.stopTest();
    }


    @IsTest
    static void testRetrievePaAdvisoriesAdvancedSearch_success() {

        List<PA_Advisory__c> yesterdayRecs = PortalAdminTestUtils.buildPaAdvisoryData(2);
        for(PA_Advisory__c rec : yesterdayRecs) {
            rec.Advisory_Date__c = Date.today().addDays(-1);
        }
        insert yesterdayRecs;

        List<PA_Advisory__c> allRecords = [SELECT Id,Advisory_Date__c,Visible__c,Full_Name__c FROM PA_Advisory__c];

        Integer iNumYesterdayRecs = yesterdayRecs.size();
        Integer iNumTodaysRecs = allRecords.size() - iNumYesterdayRecs;
        Integer iNumAllRecs = allRecords.size();
        System.debug('---> all recs size: '+iNumAllRecs);
        Integer iOffset = 0;
        Integer iLimit = allRecords.size();
        Date advisoryStartDate = null;
        Date advisoryEndDate = null;
        Boolean isVisible = null;
        String fullName = null;
        String city = null;

        Test.startTest();

        //  (1) Give me everything.
        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(allRecords.size(),advisories.size());

        //  (2) With offset.
        iLimit = 4;
        iOffset = 2;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iLimit,advisories.size());

        //  (3) With advisoryStartDate
        advisoryStartDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iNumTodaysRecs,advisories.size());

        //  (4) With advisoryEndDate
        advisoryEndDate = Date.today().addDays(-1);
        advisoryStartDate = null;
        iLimit = 50000;
        iOffset = 0;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iNumYesterdayRecs,advisories.size());

        //  (5) With advisoryStartDate and endDate
        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iNumAllRecs,advisories.size());

        //  (6) With visible filter
        //@todo need Visible__c business logic communicated and finalized.
        //PA_Advisory__c advisory = [SELECT Id,Visible__c FROM PA_Advisory__c LIMIT  1];
        //advisory.Visible__c = false;
        //update advisory;

        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        isVisible = true;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (6) With full name filter
        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = 'First'+iNumAllRecs;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (7) With full name only
        advisoryStartDate = null;
        advisoryEndDate = null;
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = 'First'+iNumAllRecs;
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (8) With full name and city filter
        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = 'First'+iNumAllRecs;
        city = 'Chicago';
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (9) With city only filter
        advisoryStartDate = null;
        advisoryEndDate = null;
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = null;
        city = 'Chicago';
        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearch(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisoriesAdvancedSearchTotalRecords_success() {

        List<PA_Advisory__c> yesterdayRecs = PortalAdminTestUtils.buildPaAdvisoryData(2);
        for(PA_Advisory__c rec : yesterdayRecs) {
            rec.Advisory_Date__c = Date.today().addDays(-1);
            rec.City__c = 'Chicago';
        }
        insert yesterdayRecs;

        List<PA_Advisory__c> allRecords = [SELECT Id,Advisory_Date__c,Visible__c,Full_Name__c FROM PA_Advisory__c];

        Integer iNumYesterdayRecs = yesterdayRecs.size();
        Integer iNumTodaysRecs = allRecords.size() - iNumYesterdayRecs;
        Integer iNumAllRecs = allRecords.size();
        System.debug('---> all recs size: '+iNumAllRecs);
        Integer iOffset = 0;
        Integer iLimit = allRecords.size();
        Date advisoryStartDate = null;
        Date advisoryEndDate = null;
        Boolean isVisible = null;
        String fullName = null;
        String city = null;

        Test.startTest();

        //  (1) Give me everything.
        Integer iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(allRecords.size(),iTotal);

        //  (2) With offset.
        iLimit = 4;
        iOffset = 2;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iLimit,iTotal);

        //  (3) With advisoryStartDate
        advisoryStartDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iNumTodaysRecs,iTotal);

        //  (4) With advisoryEndDate
        advisoryEndDate = Date.today().addDays(-1);
        advisoryStartDate = null;
        iLimit = 50000;
        iOffset = 0;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iNumYesterdayRecs,iTotal);

        //  (5) With advisoryStartDate and endDate
        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        System.assertEquals(iNumAllRecs,iTotal);

        //  (6) With visible filter
        //@todo need Visible__c business logic communicated and finalized.
        //PA_Advisory__c advisory = [SELECT Id,Visible__c FROM PA_Advisory__c LIMIT  1];
        //advisory.Visible__c = false;
        //update advisory;

        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        isVisible = true;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (6) With full name filter
        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = 'First'+iNumAllRecs;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (6) With city filter
        advisoryStartDate = Date.today().addDays(-1);
        advisoryEndDate = Date.today();
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = null;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (8) With full name only
        advisoryStartDate = null;
        advisoryEndDate = null;
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = 'First'+iNumAllRecs;
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (9) With full name and city
        advisoryStartDate = null;
        advisoryEndDate = null;
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = 'First'+iNumAllRecs;
        city = 'Chicago';
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );

        //  (10) With city only
        advisoryStartDate = null;
        advisoryEndDate = null;
        iLimit = 50000;
        iOffset = 0;
        isVisible = null;
        fullName = null;
        city = 'Chicago';
        iTotal = PaAdvisoryGallerySvc.retrievePaAdvisoriesAdvancedSearchTotalRecords(
                iOffset, iLimit, advisoryStartDate, advisoryEndDate, isVisible, fullName,city
        );
        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisory_success() {

        PA_Advisory__c testAdvisory =  [SELECT Id FROM PA_Advisory__c LIMIT  1];

        Test.startTest();

        PA_Advisory__c advisory = PaAdvisoryGallerySvc.retrievePaAdvisory(testAdvisory.Id);
        System.assertEquals(testAdvisory.Id,advisory.Id);

        Test.stopTest();
    }

    @IsTest
    static void testRetrieveAdvisoryExportData_success() {

        List<PA_Advisory__c> visibleAdvisories = [
                SELECT Id FROM PA_Advisory__c WHERE Visible__c = TRUE
        ];
        List<PA_Advisory__c> allAdvisories = [
                SELECT Id FROM PA_Advisory__c
        ];

        Test.startTest();

        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesExportData(true);
        System.assertEquals(visibleAdvisories.size(),advisories.size());

        advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesExportData(null);
        System.assertEquals(allAdvisories.size(),advisories.size());

        Test.stopTest();
    }

    @IsTest
    static void testRetrievePaAdvisoriesForPdfExport_success() {

        Map<Id,PA_Advisory__c> mPas = new Map<Id,PA_Advisory__c>([SELECT Id FROM PA_Advisory__c WHERE Visible__c = TRUE]);

        Test.startTest();

        List<PA_Advisory__c> advisories = PaAdvisoryGallerySvc.retrievePaAdvisoriesForPdfExport(mPas.keySet());

        System.assertEquals(mPas.size(), advisories.size());

        Test.stopTest();
    }
}