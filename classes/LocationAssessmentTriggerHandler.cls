/**
 * Business Logic intended to back Vetting_Questionnaire__c (Location Assessment)
 */
public with sharing class LocationAssessmentTriggerHandler {
//    /**
//     * Meant to be called in a before update trigger.
//     *
//     * Performs the following.
//     * 1a. If Marked complete hit by the user.. if it was not previously checked changed status to partially complete.
//     * 1b. If it was unchecked. change the status by to Partially complete.
//     * 2. If not 1.. if the assessment status was changed (automation of via admin) record who changed it and when.
//     * 3. If not 1 or 2, ie user hit save and passed validation on new assessment. change it to partially completed.
//     *
//     * @param oldLocAssMap
//     * @param newLocAssMap
//     */
//    public static void updateLocAssessmentStatus(   Map<Id, Vetting_Questionnaire__c> oldLocAssMap,
//                                                    Map<Id, Vetting_Questionnaire__c> newLocAssMap) {
//
//        if (oldLocAssMap != null && !oldLocAssMap.isEmpty()) {
//
//            for (Vetting_Questionnaire__c newLocAss : newLocAssMap.values()) {
//                Vetting_Questionnaire__c oldLocAss = oldLocAssMap.get(newLocAss.id);
//
//                if (newLocAss.Marked_Complete__c != oldLocAss.Marked_Complete__c) {
//                    if (newLocAss.Marked_Complete__c) {
//                        newLocAss.Assessment_Status__c = 'Completed';
//                    } else {
//                        newLocAss.Assessment_Status__c = 'Partially Complete';
//                    }
//                    newLocAss.User_That_Changed_Status__c = UserInfo.getUserId();
//                    newLocAss.Last_Status_Change_Date_Time__c = System.now();
//                } else if (newLocAss.Assessment_Status__c != oldLocAss.Assessment_Status__c) {
//                    newLocAss.User_That_Changed_Status__c = UserInfo.getUserId();
//                    newLocAss.Last_Status_Change_Date_Time__c = System.now();
//                } else {
//                    //-- if this is saved at all and none of the above occured.
//                    //-- this means they filled all page layout lvel required fields.. mark it partially complete.
//                    //-- @TODO Metadata api to pull pl req fields and check them all!
//                    if(newLocAss.Assessment_Status__c != 'Completed') {
//                        newLocAss.Assessment_Status__c = 'Partially Complete';
//                        newLocAss.User_That_Changed_Status__c = UserInfo.getUserId();
//                        newLocAss.Last_Status_Change_Date_Time__c = System.now();
//                    }
//                }
//            }
//        }
//    }
}