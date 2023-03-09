/**
 *
 */
public with sharing class AccountsWithMuniChangeHistoryController {
    public Municipality__c  muni                        {get;set;}
    public Id               userId                      {get;set;}
    public Integer          iHistorySecondsToGoBack     {get;set;}
    public Boolean          bNonTrackableFieldExists    {get;set;}

    public AccountsWithMuniChangeHistoryController() {
        this.bNonTrackableFieldExists = false;
        if(iHistorySecondsToGoBack == null) {
            iHistorySecondsToGoBack = -1;
        }
    }
    public List<Account> getAccounts() {
        List<Account> accounts = new List<Account>();
        if(userId != null) {
            accounts = AccountSvc.retrieveAccounts(userId, muni.id);
        }
        return accounts;
    }
    /**
     *
     *
     * @return
     * @todo move to svc / user generic describe calls.
     */
    public List<MuniHistWrapper> getMuniHistories() {
        List<Municipality__History> histories = new List<Municipality__History>();
        List<MuniHistWrapper> muniHistWrappers = new List<MuniHistWrapper>();
        if(iHistorySecondsToGoBack > 0) {
            iHistorySecondsToGoBack = iHistorySecondsToGoBack * -1;
        }
        Datetime dt = System.now().addSeconds(iHistorySecondsToGoBack);
        histories = [
                Select  Id, field,OldValue, NewValue, CreatedDate, createdby.name
                From    Municipality__History
                WHERE   ParentId = :muni.id
                and     CreatedDate >= :dt];
        if(!histories.isEmpty()) {
            for(Municipality__History mh : histories) {
                muniHistWrappers.add(new MuniHistWrapper(mh));
            }
           // doNonTrackableFieldExist(muniHistWrappers);
        }
        return muniHistWrappers;
    }
    /**
     * Wraps Municipality__c so we further manip results if desired.
     * @TODO use dynamic type.
     */
    public class MuniHistWrapper {
        public Municipality__History muniHist {get;set;}
        public String fieldLabel {get;set;}
        public MuniHistWrapper(Municipality__History mh) {
            this.muniHist = mh;
            this.fieldLabel = AccountsWithMuniChangeHistoryController.getFieldLabel('Municipality__c',muniHist.field);
        }
    }
    //-- @TODO too many describe calls. combine the below 3. for future!
//    static Boolean doNonTrackableFieldExist(List<MuniHistWrapper> mhHistories) {
//        Map<String, Schema.SobjectField> fieldMap = getSObjectFieldMap('Municipality__c');
//        if(mhHistories != null) {
//            for(MuniHistWrapper mhWrap: mhHistories) {
//                Schema.SObjectField field = fieldMap.get(mhWrap.muniHist.field);
//                Schema.DisplayType fldType = field.getDescribe().getType();
//                system.debug(fldType);
//            }
//        }
//        return false;
//    }

    //-- @TODO move the below to gen util method
    static String getFieldLabel(String objApiName, String fieldApiName) {
        String label = '';
        Map<String, Schema.SobjectField> fieldMap = getSObjectFieldMap(objApiName);
        label = fieldMap.get(fieldApiName).getDescribe().getLabel();
        return label;
    }
    static Map<String, Schema.SObjectField> getSObjectFieldMap(String sObjectApiName) {
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Schema.SObjectType schema = schemaMap.get(sObjectApiName);
        return  schema.getDescribe().fields.getMap();
    }
}