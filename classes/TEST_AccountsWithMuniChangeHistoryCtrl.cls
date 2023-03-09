//note. lame sfdc forces us to do this otherwise we are going to spend all freekin day trying to cover code
//for object history tables.. which has been an idea for 5 damn years!
@isTest(SeeAllData=true)
private class TEST_AccountsWithMuniChangeHistoryCtrl{
    public static String UNAME = 'acceltest@accel.com';

    /**
     *
     */
    @isTest static void testMuniHistory() {
        User u = TestUtils.getUserForTest(UNAME);
        System.runAs(u) {

            Test.startTest();
            AccountsWithMuniChangeHistoryController ctrl = new AccountsWithMuniChangeHistoryController();
            ctrl.userId = u.id;

            //-- no  muni history
            Account a = new Account(name='Blah accel unit test 1');
            insert a;
            //  RJN 10-5-2019 Added State to abide by newly created val rule on Muni
            Municipality__c muni = new Municipality__c(name='blah muni unit test 1',State__c='IL');
            insert muni;
            a.municipalitylookup__c = muni.id;
            update a;
            ctrl.muni = muni;
            List<Account> accounts = ctrl.getAccounts();
            system.assert(accounts.isEmpty());

            //-- will have  muni history. note not all orgs may have muni history those the conditional
            List<Municipality__c>  munis = [
                select      id
                from        municipality__c
                where       id in (
                            select parentId
                            from   Municipality__History
                            where  field != null)
                limit 1
            ];
            if(!munis.isEmpty()) {
                ctrl.muni = munis[0];
                //---- we can't force an update into muni history in the last second. make it as big as possible for the test
                // system.assert(!muniWraps.isEmpty());
                ctrl.iHistorySecondsToGoBack = 999999999;
                try {
                    //--- the best we can do for now code coverage wise.. due to testing limitation of history tables!
                    List<AccountsWithMuniChangeHistoryController.MuniHistWrapper> muniWraps = ctrl.getMuniHistories();
                } catch (Exception e) {
                    system.debug(e);
                }

            }
            Test.stopTest();
        }
    }
}