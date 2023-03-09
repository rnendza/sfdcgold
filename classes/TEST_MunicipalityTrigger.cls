@IsTest
private class TEST_MunicipalityTrigger{
    public static String UNAME = 'acceltest@accel.com';
    
    @IsTest
    static void testNewMuniCreation() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();

            List<Municipality__c> munis = TestUtils.createMunicipalities('Test Accel Muni',2);

            List<Hold_Per_Day_Total__c> holdPerDayTotals = [
                    SELECT Id, Account__c
                    FROM   Hold_Per_Day_Total__c
                    WHERE  Municipality__c IN :munis
            ];
            System.assert(holdPerDayTotals.size() == munis.size());

            Test.stopTest();
        }
    }
}