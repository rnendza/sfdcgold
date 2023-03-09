@isTest
private class TEST_LocationAssessmentTrigger {

//    public static String UNAME = 'acceltest@accel.com';
//    /**
//     * Setup test data.
//     */
//    @testSetup static void setup() {
//        User u = TestUtils.getUserForTest(UNAME);
//        System.runAs(u) {
//            List<Municipality__c> municipalities = TestUtils.createMunicipalities('testaccellmuni', 1);
//            List<Account> accounts = new List<Account>();
//            Integer numAccounts = 2;
//            Id locRtId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
//            for (Municipality__c municipality : municipalities) {
//                for (Integer i = 0; i < numAccounts; i++) {
//                    Account accelAccount = TestUtils.buildAccount('accel test acct:' + i + 'a', municipality.id, 'Accel Account');
//                    accelAccount.recordtypeId = locRtId;
//                    accelAccount.Accel_VGT_Live_DAte__c = null;
//                    accounts.add(accelAccount);
//                }
//            }
//            insert accounts;
//            accounts = [SELECT Id,Name from Account];
//            System.assert(accounts.size() == numAccounts);
//
//        }
//    }
//    @isTest static void testLocAssSavedAfterValidated() {
//        User u = TestUtils.getUserForTest(UNAME);
//        Id locRtId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
//        System.runAs(u) {
//            //first make sure loc asses are created.
//            List<Account>  accounts = [SELECT Id, Name, REcordType.Name, Accel_VGT_Live_Date__c, Type From Account where  recordTypeId = :locRtId];
//            system.assert(!accounts.isEmpty());
//            Set<Id> accountIds = new Set<Id>();
//            for(Account account : accounts) {
//                account.Type = 'Accel Account';
//                account.Accel_VGT_Live_Date__C = Date.today();
//                accountIds.add(account.id);
//            }
//            update accounts;
//
//            List<Vetting_Questionnaire__c> vqs = [SELECT Id  from Vetting_Questionnaire__c where account__C in :accountIds];
//            system.assert(!vqs.isEmpty());
//
//
//            Test.startTest();
//
//            for(Vetting_Questionnaire__c vq : vqs) {
//                vq.Are_the_VGT_fans_clean__c = 'Yes';
//            }
//            update vqs; //assume page layout req fields entered.
//            vqs.clear();
//            vqs = [SELECT Id,Assessment_Status__c  from Vetting_Questionnaire__c where account__C in :accountIds];
//            for(Vetting_Questionnaire__c vq : vqs) {
//                system.assert(vq.Assessment_Status__c == 'Partially Complete');
//            }
//
//            Test.stopTest();
//        }
//    }
//
//    @isTest static void testLocAssMarkedCompleted() {
//        User u = TestUtils.getUserForTest(UNAME);
//        Id locRtId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
//        System.runAs(u) {
//            //first make sure loc asses are created.
//            List<Account>  accounts = [SELECT Id, Name, REcordType.Name, Accel_VGT_Live_Date__c, Type From Account where  recordTypeId = :locRtId];
//            system.assert(!accounts.isEmpty());
//            Set<Id> accountIds = new Set<Id>();
//            for(Account account : accounts) {
//                account.Type = 'Accel Account';
//                account.Accel_VGT_Live_Date__C = Date.today();
//                accountIds.add(account.id);
//            }
//            update accounts;
//
//            List<Vetting_Questionnaire__c> vqs = [SELECT Id  from Vetting_Questionnaire__c where account__C in :accountIds];
//            system.assert(!vqs.isEmpty());
//
//
//            Test.startTest();
//
//            for(Vetting_Questionnaire__c vq : vqs) {
//                vq.Marked_Complete__c = true;
//            }
//            update vqs; //assume page layout req fields entered.
//            vqs.clear();
//            vqs = [SELECT Id,Assessment_Status__c  from Vetting_Questionnaire__c where account__C in :accountIds];
//            for(Vetting_Questionnaire__c vq : vqs) {
//                system.assert(vq.Assessment_Status__c == 'Completed');
//            }
//            //uncheck it.
//            vqs.clear();
//            vqs = [SELECT Id,Marked_Complete__c  from Vetting_Questionnaire__c where account__C in :accountIds];
//            for(Vetting_Questionnaire__c vq : vqs) {
//                vq.Marked_Complete__c = false;
//            }
//            update vqs;
//            vqs.clear();
//            vqs = [SELECT Id,Assessment_Status__c  from Vetting_Questionnaire__c where account__C in :accountIds];
//            for(Vetting_Questionnaire__c vq : vqs) {
//                system.assert(vq.Assessment_Status__c == 'Partially Complete');
//            }
//
//            Test.stopTest();
//        }
//    }
//
//    @isTest static void testLocStatusChanged() {
//        User u = TestUtils.getUserForTest(UNAME);
//        Id locRtId = Schema.getGlobalDescribe().get('Account').getDescribe().getRecordTypeInfosByDeveloperName().get('Location').getRecordTypeId();
//        System.runAs(u) {
//            //first make sure loc asses are created.
//            List<Account>  accounts = [SELECT Id, Name, REcordType.Name, Accel_VGT_Live_Date__c, Type From Account where  recordTypeId = :locRtId];
//            system.assert(!accounts.isEmpty());
//            Set<Id> accountIds = new Set<Id>();
//            for(Account account : accounts) {
//                account.Type = 'Accel Account';
//                account.Accel_VGT_Live_Date__C = Date.today();
//                accountIds.add(account.id);
//            }
//            update accounts;
//
//            List<Vetting_Questionnaire__c> vqs = [SELECT Id  from Vetting_Questionnaire__c where account__C in :accountIds];
//            system.assert(!vqs.isEmpty());
//
//
//            Test.startTest();
//
//            for(Vetting_Questionnaire__c vq : vqs) {
//                vq.Assessment_Status__c = 'Completed';
//            }
//            update vqs; //assume page layout req fields entered.
//            vqs.clear();
//            vqs = [SELECT Id,Assessment_Status__c  from Vetting_Questionnaire__c where account__C in :accountIds];
//            for(Vetting_Questionnaire__c vq : vqs) {
//                system.assert(vq.Assessment_Status__c == 'Completed');
//            }
//
//            Test.stopTest();
//        }
//    }
}