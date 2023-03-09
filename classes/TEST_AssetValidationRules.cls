@IsTest
private class TEST_AssetValidationRules {

    public static String USERNAME = 'acceltest@accel.com';

    @IsTest
    static void test_AssetNameSoftwareNoEdit_Positive() {
        User uAdmin = TestUtils.getUserForTest(USERNAME);
        System.runAs(uAdmin) {

            Id swRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Software').getRecordTypeId();
            Id vgtRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('VGT').getRecordTypeId();
            Asset aSw   = new Asset(Name='asset trigger unit test software',RecordTypeId = swRtId, Description = 'ASSET DESC');
            Asset aVgt  = new Asset(Name='asset trigger unit test VGT',RecordTypeId = vgtRtId, Description = 'ASSET DESC');

            Test.startTest();
            //  (1) Test insert
            insert aSw;
            System.assert(aSw.Id != null);

            //  (2)  Test update of an Asset (but not Name field)
            String newDesc = 'NEW ASSET DESC';
            aSw.Description = newDesc;
            update aSw;
            aSw = [SELECT Id, Description FROM Asset WHERE Id = :aSw.Id];
            System.assertEquals(aSw.Description,newDesc);

            //  (3)  Test a non software asset.
            insert aVgt;
            String newName = 'NEW VGT Asset Name';
            aVgt.Name = newName;
            update aVgt;
            aVgt = [SELECT Id, Name FROM Asset WHERE Id = :aVgt.Id];
            System.assertEquals(aVgt.Name,newName);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_AssetNameSoftwareNoEdit_Negative() {
        User uAdmin = TestUtils.getUserForTest(USERNAME);
        System.runAs(uAdmin) {
            Id swRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Software').getRecordTypeId();
            Asset a = new Asset(Name='asset trigger unit test asset',RecordTypeId = swRtId, Description = 'ASSET DESC');
            insert a;

            Test.startTest();

            //  (1)  Test Update of Name Field
            String newName = 'AssetNewName';
            a.Name = newName;
            try {
                update a;
            } catch (DmlException dmlException) {
                System.assert(dmlException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
                System.assert(dmlException.getDmlFieldNames(0)[0] == 'Name');
            }

            Test.stopTest();
        }
    }
    @IsTest
    static void test_AssetSerialNumberSoftwareNoEdit_Positive() {
        User uAdmin = TestUtils.getUserForTest(USERNAME);
        System.runAs(uAdmin) {

            Id swRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Software').getRecordTypeId();
            Id vgtRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('VGT').getRecordTypeId();
            Asset aSw   = new Asset(Name='asset trigger unit test software',RecordTypeId = swRtId, Description = 'ASSET DESC');
            Asset aVgt  = new Asset(Name='asset trigger unit test VGT',RecordTypeId = vgtRtId, Description = 'ASSET DESC');

            Test.startTest();
            //  (1) Test insert
            insert aSw;
            System.assert(aSw.Id != null);

            //  (2)  Test update of an Asset (but not SerialNumber field)
            String newDesc = 'NEW ASSET DESC';
            aSw.Description = newDesc;
            update aSw;
            aSw = [SELECT Id, Description FROM Asset WHERE Id = :aSw.Id];
            System.assertEquals(aSw.Description,newDesc);

            //  (3)  Test a non software asset.
            insert aVgt;
            String newSerialNumber = 'VGT-Serial 234234';
            aVgt.SerialNumber = newSerialNumber;
            update aVgt;
            aVgt = [SELECT Id, SerialNumber FROM Asset WHERE Id = :aVgt.Id];
            System.assertEquals(aVgt.SerialNumber,newSerialNumber);

            Test.stopTest();
        }
    }
    @IsTest
    static void test_AssetSerialNumberSoftwareNoEdit_Negative() {
        User uAdmin = TestUtils.getUserForTest(USERNAME);
        System.runAs(uAdmin) {
            Id swRtId = Schema.getGlobalDescribe().get('Asset').getDescribe().getRecordTypeInfosByDeveloperName()
                    .get('Software').getRecordTypeId();
            Asset a = new Asset(Name='asset trigger unit test asset',RecordTypeId = swRtId, SerialNumber=' 234532423',Description = 'ASSET DESC');
            insert a;

            Test.startTest();

            //  (1)  Test Update of SerialNumber Field
            String newSerialNumber = 'VGT 324324234423';
            a.SerialNumber = newSerialNumber;
            try {
                update a;
            } catch (DmlException dmlException) {
                System.assert(dmlException.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
                System.assert(dmlException.getDmlFieldNames(0)[0] == 'SerialNumber');
            }

            Test.stopTest();
        }
    }
}