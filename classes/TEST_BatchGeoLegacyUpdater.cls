@isTest
private class TEST_BatchGeoLegacyUpdater{

    public static String UNAME = 'acceltest@accel.com';

    @testSetup static void setup() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni',1);
            List<Account> accounts = new List<Account>();
            Integer i = 0;
            for(Municipality__c municipality : municipalities) {
                accounts.add(TestUtils.buildAccount('accel test acct:'+i + 'a', municipality.id,'Accel Account'));
                accounts.add(TestUtils.buildAccount('accel test acct:'+i + 'b', municipality.id,'Competitor Account'));
                i++;
            }
            insert accounts;
            accounts = [ select id, shipping_address_accuracy__c from account where Id in :accounts];
            for(Account account : accounts) {
                account.Shipping_Address_Accuracy__c = null;
            }
            update accounts;
        }
    }

    @isTest static void test_Batch_Update_Accuracy_Value_Positive() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {
            Test.startTest();
            BatchGeoAccuracyLegacyUpdater b = new BatchGeoAccuracyLegacyUpdater();
            Id batchId = Database.ExecuteBatch(b,2);
            Account account = [SELECT Id, Type FROM Account limit 1];
            account.type = 'Bad value';

            Map<Id,Account> mAccountsByIds = new Map<Id,Account>{account.Id => account};

            List<Database.SaveResult> results = Database.update(mAccountsByIds.values(), false);
            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results.get(i);
                if (sr.isSuccess()) {
                    //
                } else {
                    Id accountId = mAccountsByIds.values().get(i).Id;
                    b.handleErrors(accountId, results.get(i).getErrors());
                }
            }
            Test.stopTest();
            //@todo assert
        }
    }

}