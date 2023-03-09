/**
 * Created by CedricN on 8/13/2020.
 */

@IsTest
private class Test_FieldAssessmentCount {
   /* public static final String USERNAME_ADMIN             = 'acceltestadmin@accelentertainment.com';
    public static final String ACCOUNT_NAME               = 'Blah Random UT Account';
    public static final string count;
    public static final String KNOWN_SOBJECT_API_NAME     = 'Account';
    public static final String KNOWN_FIELDSET_API_NAME    = 'test_lookup';
    public static final String KNOWN_FIELDSET_FIELD_NAME  = 'Type';*/

    @testSetup static void setup(){
     /*  Profile pr = new Profile(name ='Regional Manager');
     User test = TestUtils.getUserForTest('TestUser@accelentertainment.com');
        test.ProfileId=pr.Id;
        test.Email = 'acceltestadmin@accelentertainment.com';

        User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

        User user = new User();
        // populate the record
        user.emailencodingkey='UTF-8';
        user.languagelocalekey='en_US';
        user.localesidkey='en_US';
        user.timezonesidkey='America/Chicago';

        user.Alias = 'test1';
        user.email = 'test1@accelentertainment.com';
        user.lastname = 'theRegion';
        user.username = 'test1@accelentertainment.com';
        user.ProfileId = pr.Id;

        insert user;*/

      /* Account Account1 = new Account();
        List<Municipality__c> muni = TestUtils.createMunicipalities('Test Muni', 2);
        For(Municipality__c m : muni){
            Account1 = TestUtils.buildAccount('TestAccount', m.id);
        }
        insert Account1;
        Project__c Proj1 = new Project__c(Name = 'Project 1', Account__r=Account1, Count_of_Field_Assessements__c=0, Project_Status__c='Pre-Initiation');
      //  count=Proj1.Count_of_Field_Assessements__c;
        insert Proj1;

        Field_Assessment__c Field1 = new Field_Assessment__c( Project__c=Proj1.ID);
        insert Field1;*/


    }
    @IsTest
    static void testBehavior() {
      // User adminUser = TestUtils.getUserForTest(USERNAME_ADMIN);

     //   System.runAs( adminUser){

            FieldAssessmentCount f1 = new FieldAssessmentCount();
        Test.startTest();
        Database.executeBatch(f1);

    Test.stopTest();

         //   system.assert(false, [Select Id, Name From Field_Assessment__c Where Count_of_Field_Assessements__c!=0] = Null);

          // system.assertEquals(1, f1.Account)

        }



    }