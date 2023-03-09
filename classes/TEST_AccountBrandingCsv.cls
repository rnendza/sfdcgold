@IsTest
private class TEST_AccountBrandingCsv {

    static Integer NUMBER_OF_ACCOUNTS        = 5;

    @TestSetup
    static void setup() {

        List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni', 1);

        Test.startTest();

        List<Account> accounts = new List<Account>();
        for (Municipality__c municipality : municipalities) {
            for (Integer i = 0; i < NUMBER_OF_ACCOUNTS; i++) {
                Account acct = TestUtils.buildAccount('accel test acct:' + i + 'a', municipality.id,
                        'Accel Account');
                accounts.add(acct);
                i++;
            }
        }
        insert accounts;

        Test.stopTest();
    }

    @IsTest
    static void test_AccountBrandingCsv_Positive() {
        List<Account> accounts = [
                SELECT  Id,Branding__c, ShippingState, RecordType.DeveloperName,CreatedDate,CreatedBy.Username,
                        Type
                FROM    Account
        ];

        Test.startTest();

        AccountBrandingCsv csvBuilder = new AccountBrandingCsv();
        String csv = csvBuilder.generateCsv(accounts);
        System.debug(csv);

        //test misc formatters
        Datetime createdDate = accounts[0].CreatedDate;
        Time myTime = Time.newInstance(createdDate.hour(),createdDate.minute(),createdDate.second(),createdDate.millisecond());
        csvBuilder.format(myTime);
        csvBuilder.formatTime(myTime);
        csvBuilder.formatTime(null);

        Test.stopTest();
    }
}