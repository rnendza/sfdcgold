public with sharing class clAutomationSvc {

    public final static String RPS_TRIGGER_PREVENT_DELETE       = 'clRPSTriggerHandler_prevent_delete';
    public final static STring MR_TRIGGER_PREVENT_DELETE        = 'MR_TriggerHandler_Prevent_Delete';
    public final static String ACCOUNT_TRIGGER_PREVENT_DELETE   = 'AccountTriggerHandler_cl_prevent_delete';

    public static Boolean preventRecordDelete(String devName) {
        Cash_Logistics_Automation_Setting__mdt mdt = retrieveAutomationSetting(devName);
        return mdt.Active__c && mdt.Prevent_Record_Delete__c;
    }

    public static Cash_Logistics_Automation_Setting__mdt retrieveAutomationSetting(String devName) {
        Cash_Logistics_Automation_Setting__mdt mdt = CustomMetadataSvc.retrieveAutomationMetadata(devName);
        return mdt;
    }

    /**
     * @param accountIds  XX
     * @return XX
     */
    public static Map<Id,List<Route_Processing_Sheet__c>> mapRpsToAccount(Set<Id> accountIds) {
        Map<Id,List<Route_Processing_Sheet__c>> mAccount_Rpss = new Map<Id,List<Route_Processing_Sheet__c>>();

        Map<Id,Route_Processing_Sheet__c> routeProcessingSheets = new Map<Id,Route_Processing_Sheet__c>([
                SELECT Id, Account__c
                FROM   Route_Processing_Sheet__c
                WHERE  Account__c IN :accountIds
        ]);
        if(!routeProcessingSheets.isEmpty()) {
            for(Route_Processing_Sheet__c rps : routeProcessingSheets.values()) {
                if(!mAccount_Rpss.containsKey(rps.Account__c)) {
                    mAccount_Rpss.put(rps.Account__c, new List<Route_Processing_Sheet__c>{rps});
                } else {
                    List<Route_Processing_Sheet__c> rpss = mAccount_Rpss.get(rps.Account__c);
                    rpss.add(rps);
                }
            }
        }
        return mAccount_Rpss;
    }

    public static List<Cash_Logistics_Schedule_Setting__mdt> retrieveScheduleMetadatas(Boolean activeRegion) {

        List<Cash_Logistics_Schedule_Setting__mdt> mdts = new List<Cash_Logistics_Schedule_Setting__mdt>();

        try {
            DescribeSObjectResult describeResult = Cash_Logistics_Schedule_Setting__mdt.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());

            String q =  ' SELECT ' + String.join(fieldNames, ',')
                    + '   FROM  ' + describeResult.getName() +
                    '     WHERE Active_Region__c = :activeRegion ';
            mdts = Database.query(q);
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        return mdts;
    }
}