@IsTest
private class TEST_SObjectErrorCsv {

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
    static void test_SObjectErrorCsv_Positive() {
        List<Account> accounts = [
                SELECT  Id,Branding__c, ShippingState, RecordType.DeveloperName,LastModifiedDate,CreatedBy.Username,
                        Type
                FROM    Account
        ];
        Map<Id,String> mErrorsByIds = new Map<Id,String>();
        for(Account account : accounts) {
            mErrorsByIds.put(account.Id,'blah error');
        }
        Test.startTest();

        SObjectErrorCsv csvBuilder = new SObjectErrorCsv();
        String csv = csvBuilder.generateCsv(mErrorsByIds);
        System.debug(csv);

        //test misc formatters
        Datetime lastModifiedDate = accounts[0].LastModifiedDate;
        Time myTime = Time.newInstance(lastModifiedDate.hour(),lastModifiedDate.minute(),lastModifiedDate.second(),lastModifiedDate.millisecond());
        csvBuilder.format(myTime);
        csvBuilder.formatTime(myTime);
        csvBuilder.formatTime(null);

        Test.stopTest();
    }
}