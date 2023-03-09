/**
 * Created by CedricN on 2/26/2020.
 */

@IsTest
private class TEST_GenDataTables {
    public static String UNAMEADMIN     = 'acceltestadmin@accelentertainment.com';
    public static final Integer NUMBER_OF_PRODUCTS = 2;
    public static final Integer NUMBER_OF_IR_LINES = 5;
    public static final Integer NUMBER_OF_MUNIS = 2;
    public static final Integer NUMBER_OF_ACCTS_PER_MUNI = 2;

//    @IsTest
//    static void setup(){
//       // asset = TestUtils.createAsset('test asset');
//
//        User adminUser = TestUtils.getUserForTest(UNAMEADMIN);
//
//   //    insert adminUser;
//
//
//        WorkType Work = new WorkType(Name='Test', DurationType='Hours', EstimatedDuration=1);
//
//        insert Work;
//
//        List<Municipality__c> munis = TestUtils.createMunicipalities('UT MUNI', NUMBER_OF_MUNIS);
////        insert munis;
//        List<Account> accounts = new List<Account>();
//        List<Asset> assets = new List<Asset>();
//        asset Asset = new Asset(Name='Test Asset', GP_Manufacturer__c='Test Manufactor');
//       insert Asset;
//        Integer z = 0;
//        for (Municipality__c municipality : munis) {
//            for (Integer i = 0; i < NUMBER_OF_ACCTS_PER_MUNI; i++) {
//                Account account = TestUtils.buildAccount('accel test acct:' + z + 'a', municipality.id,
//                        'Accel Account');
//                account.ShippingState = 'IL';
//                account.Service_Region__c='Watseka 1';
//
//                accounts.add(account);
//                z++;
//            }
//        }
//       insert accounts;
//
//        Account newAccount = new Account(name='Test Acoount', Service_Region__c='Watseka 1' );
//        insert newAccount;
//   //     insert newAccount;
//        Case createCase = TestUtils.createCase('test case subject',asset.id);
//        createCase.Assigned_Resource__c=adminUser.Id;
//        createCase.Status = 'In Progress';
//        createCase.AssetId=asset.Id;
//        createCase.Work_Type__r = Work;
//        createCase.Description='Test Description';
//
//      //  createCase.CreatedDate = (Datetime.now().addDays(-1));
//
//      //  insert createCase;
//
//
//        Test.setCreatedDate(createCase.Id, Datetime.now().addDays(-1) );
//
//      //  insert createCase;
//        Case newCase = new Case( Assigned_Resource__c=adminUser.Id, Status='Pending', AssetId=asset.Id, Work_Type__r= Work, Description='Test Description');
//
//        insert newCase;
//        Test.setCreatedDate(newCase.Id, Datetime.now().addDays(-1) );
//
//    }
    @IsTest
    static void testBehavior() {
        Asset asset = new Asset(name='test asset');

        User    adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Test.startTest();
        TestUtils.createCase('test case subject1',asset.id);


        new GenDataTables();
        List<Case> pendingLogList =  new GenDataTables().pendingLogAgg;

        List<Case> dailyloglist = new GenDataTables().dailyLogAgg;

        List<AggregateResult> regionBreakDownList = new GenDataTables().regionBreakDownListAgg;

        for(AggregateResult ar: regionBreakDownList){
            System.assert(ar.get('Service_Region__c')!=null);
            System.assertequals(ar.get('CreatedDate'),Datetime.now().addDays(-1));
        }
        List<AggregateResult> techBdListAgg = new GenDataTables().technicianBreakDownListAgg;

        List<AggregateResult> manufacturerBreakDownList = new GenDataTables().manufacturerBreakDownListAgg;

        for(AggregateResult ar: manufacturerBreakDownList){
            System.assert(ar.get('Service_Region__c')!=null);
            System.assert(ar.get('Assigned_Resource__c')!=null);
            System.assertequals(ar.get('CreatedDate'),Datetime.now().addDays(-1));
        }

        Test.stopTest();

    }
    @IsTest
    static void testBehavior2() {
        Asset asset = new Asset(name='test asset');

        User    adminUser = TestUtils.getUserForTest(UNAMEADMIN);
        Test.startTest();
        TestUtils.createCase('test case subject1',asset.id);

        new GenDataTables();
        List<Case> pendingLogList =  new GenDataTables().pendingLogAgg;

        List<Case> dailyloglist = new GenDataTables().dailyLogAgg;


        List<AggregateResult> callcenterBreakDownList = new GenDataTables().callCenterBreakDownListAgg;
        for(AggregateResult ar: callcenterBreakDownList){
            System.assert(ar.get('Service_Region__c')!=null);
            System.assert(ar.get('GP_Manufacturer__c')!=null);
            System.assertequals(ar.get('CreatedDate'),Datetime.now().addDays(-1));
        }

        String getReportDate = new GenDataTables().getReportDate();

        Integer getTotalCalls = new GenDataTables().getTotalCalls();

        Integer getTechComplete = new GenDataTables().getTechComplete();

        Integer getCallCenterComplete = new GenDataTables().getCallCenterComplete();

        Integer getIncompleteCalls = new GenDataTables().getIncompleteCalls();


        Integer getInprogressCalls = new GenDataTables().getInProgressCalls();

        Integer getUnresolvedCalls = new GenDataTables().getUnresolvedCalls();







        /*  system.assert(!pendingLogList.isEmpty());
           system.assert(!dailyloglist.isEmpty());
           system.assert(!regionBreakDownList.isEmpty());
           system.assert(!manufacturerBreakDownList.isEmpty());
           system.assert(!technicianBreakDownList.isEmpty());
           system.assert(!callcenterBreakDownList.isEmpty());*/
        system.assert(getReportDate!=null);
        system.assert(getTotalCalls!=null);
        system.assert(getTechComplete!=null);
        system.assert(getCallCenterComplete!=null);
        system.assert(getIncompleteCalls!=null);
        system.assert(getInprogressCalls!=null);
        system.assert(getUnresolvedCalls!=null);
        Test.stopTest();

    }
}