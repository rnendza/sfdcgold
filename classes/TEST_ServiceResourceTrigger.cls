@IsTest
private class TEST_ServiceResourceTrigger {

    public static String UNAME = 'acceltest@accel.com';

    //--- @TODO Make this dynamic.
    public static final String VGT_PL_VALUE         = 'Vgt';
    public static final String AMUSEMENT_PL_VALUE   = 'Amusement';
    /**
     * Setup test data. Just build a couple of different users and a couple of different ServiceResource Recs for now.
     */
    @TestSetup
    static void setup() {
        User u1 = TestUtils.getUserForTest(UNAME);
        User u2 = TestUtils.getUserForTest(UNAME+'2');
        List<ServiceResource> srs = new List<ServiceResource>();
        srs.add(TestUtils.buildSingleServiceResource(u1.LastName, u1.id));
        srs.add(TestUtils.buildSingleServiceResource(u2.LastName, u2.id));
        insert srs;
    }
    /**
     * Test the update of Service Resource in the context of territory type and the appending of it on the sr name.
     * The following is tested:
     *
     * (1)-- Test update of SR that had no technician type appended.
     * (2)-- Test update of SR that DID have a technician type appended.
     * (3)-- Test NULL technician type.
     */
    @IsTest 
    static void test_ServiceResource_Update_Positive() {

        User u1 = TestUtils.getUserForTest(UNAME);
        System.runAs(u1) {
            List<ServiceResource> srs = [SELECT Id, Name, Technician_Type__c FROM ServiceResource ];
            Test.startTest();
            //--(1)-- Test update of SR that had no technician type appended.
            for(ServiceResource sr : srs) {
                sr.Technician_Type__c = VGT_PL_VALUE;
            }
            update srs;
            srs = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource ];
            for(ServiceResource sr : srs) {
                system.assert(sr.name.contains( ' - ' + sr.Technician_Type__c));
            }

            //--(2)-- Test update of SR that DID have a technician type appended.
            srs = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource ];
            for(ServiceResource sr : srs) {
                sr.Technician_Type__c = AMUSEMENT_PL_VALUE;
            }
            update srs;
            srs = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource ];
            for(ServiceResource sr : srs) {
                system.assert(sr.name.contains( ' - ' + sr.Technician_Type__c));
            }

            //--(3)-- Test NULL technician type.
            srs = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource ];
            for(ServiceResource sr : srs) {
                sr.Technician_Type__c = null;
            }
            update srs;
            srs = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource ];
            for(ServiceResource sr : srs) {
                system.assert(sr.name == u1.LastName);
            }
            Test.stopTest();
        }
    }

   /**
    * Test the insert of Service Resource in the context of territory type and the appending of it on the sr name.
    * The following is tested:
    *
    * (1)-- Test insert of an sr with no tech type.
    * (2)-- Test insert of an sr with VGT Type
    * (3)-- Test bulk insert of sr (just to be safe) with VGT Type.
    */
    @IsTest
    static void test_ServiceResource_Insert_Positive() {

        User u1 = TestUtils.getUserForTest(UNAME + 'srtestpos1');
        User u2 = TestUtils.getUserForTest(UNAME + 'srtestpos2');

        List<User> bulkUsers = new List<User>();

        for(Integer i=0; i<5;i++) {
            TestUtils.secSettings settings =
                    new TestUtils.SecSettings('','testuser'+i+'@blah.com','','','');
            bulkUsers.add( TestUtils.getUserForTest( settings,System.now(),true,false ) );
        }
        insert bulkUsers;

        System.runAs(u1) {
            ServiceResource sr = TestUtils.buildSingleServiceResource(u1.lastname,u1.id);
            Test.startTest();

            //--(1)-- Test insert of an sr with no tech type.
            insert sr;
            sr = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource where Accel_User__c = :u1.id];
            system.assert(sr.name == u1.lastname && sr.Technician_Type__c == null );

            //--(2)-- Test insert of an sr with VGT Type
            ServiceResource sr2 =  TestUtils.buildSingleServiceResource(u2.lastname,u2.id);
            sr2.Technician_Type__c = VGT_PL_VALUE;
            insert sr2;
            sr = [SELECT Id,  Name, Technician_Type__c FROM ServiceResource where Accel_User__c = :u2.id];
            system.assert(sr.name == u2.lastname + ' - '+VGT_PL_VALUE  && sr.Technician_Type__c == VGT_PL_VALUE );

            //--(3)-- Test bulk insert of sr (just to be safe) with VGT Type
            List<ServiceResource> bulkServiceResources = new List<ServiceResource>();
            for(Integer i=0;i<5;i++) {
                User u = TestUtils.getUserForTest('tst_'+i +'@bogus.com');
                ServiceResource srBulk = TestUtils.buildSingleServiceResource(u.lastname,u.id);
                srBulk.Technician_Type__c = VGT_PL_VALUE;
                bulkServiceResources.add(srBulk);
            }
            insert bulkServiceResources;
            bulkServiceResources.clear();
            bulkServiceResources = [SELECT Id,Name, Technician_Type__c FROM ServiceResource where Accel_User__c in :bulkUsers];
            for(ServiceResource srBulk : bulkServiceResources) {
               system.assert(srBulk.name.contains(' - '+VGT_PL_VALUE ));
            }
            Test.stopTest();
        }
    }
}