public with sharing class POC_FieldSetController {
       // @auraEnabled public List<String> FieldLabels;
    public static final String  MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS = 'FS_WRAPS_AND_MEMBERS';
    /**
     * Fires a simple update on the sObject. (No Refresh)
     *
     * @param sObj   a Valid SObject which contains an Id.
     * @return      a dto containing success information.
     */
    @AuraEnabled
    public static ResponseDto updateSObject(SObject sObj) {
        return updateSObject(sObj,false);
    }
    /**
     * Fires a simple update on the sObject. will do a refresh of doRefresh = true.
     *
     * @param sObj       A Valid SObject which contains an Id.
     * @param doRefresh  If true, another query is run to refresh after update, otherwise just return after update
     * @return           a dto containing success information. and the sObj property populated if desired.
     */
    @AuraEnabled
    public static ResponseDto updateSObject(SObject sObj, Boolean doRefresh) {
        ResponseDto dto = new ResponseDto();
        try {
            update sObj;
            if(doRefresh) {
                //  @TODO refresh isn't really used let live but it's here for future use.
                sObj = FieldSetSvc.retrieveAllSObjectFieldsAndData(sObj.Id, sObj.getSObjectType().getDescribe().getName());
                dto.sObj = sObj;
            }
            String sObjectLabel = sObj.getSObjectType().getDescribe().getLabel();
            dto.message = 'Update to the '+sObjectLabel + ' was successful!';
            dto.isSuccess = true;
        } catch (DmlException e) {
            dto.technicalMsg = e.getMessage() + e.getCause() + e.getLineNumber() + e.getStackTraceString();
            dto.technicalMsg += 'passed sObject='+sObj;
            dto.technicalMsg += 'doRefresh='+doRefresh;

          //  Account.Name.getDescribe().getLabel();
            List<String>   FieldLabels = e.getDMLFieldNames(0);
            For(integer i=0; i<FieldLabels.size(); i++){
                dto.title = FieldLabels[i];
            }

            For(integer i=0; i< FieldLabels.size();i++) {
                dto.message = 'Update Failed: ' + FieldSetSvc.getFieldLabel('Opportunity', FieldLabels[i]) + '; ' + e.getDmlMessage(0);
            }
            System.debug(LoggingLevel.ERROR,e);
        } catch (Exception e) {
            dto.technicalMsg = e.getMessage() + e.getCause() + e.getLineNumber() + e.getStackTraceString();
            dto.technicalMsg += 'passed sObject='+sObj;
            dto.technicalMsg += 'doRefresh='+doRefresh;
            dto.message = 'Update Failed: '+e.getMessage();
            System.debug(LoggingLevel.ERROR,e);
        }
        return dto;
    }
    /**
     * Retrieves FieldSetWrapper(s) (and their children FieldSetMemberWrapper(s) for the given sObject Api Name
     * And FieldSet Api Name(s).
     *
     * @param sObjectApiName     The sObject Api Name.
     * @PARAM sObjectRecordId    The record id (optional.. if none exists the value property of FieldSetMember will not be populated)
     * @param fieldSetApiNames   The FieldSet Api Name(s).
     *
     * @return a List of FieldSetWrappers in the values map. (hopefully assuming Opportunity.Page_Category__c api name
     * and field set api name play nice).
     */
    @AuraEnabled (Cacheable=true)
    public static ResponseDto retrieveSpecificFieldSetWrappersAndFieldSetMembers(   String sObjectApiName,
                                                                                    String sObjectRecordId,
                                                                                    List<String> fieldSetApiNames) {
        ResponseDto dto = new ResponseDto();
        Set<String> fsApiNames = new Set<String>(fieldSetApiNames);

        Map<String,FieldSetWrapper> mFieldSetWrappersByApiName =
                FieldSetSvc.getSpecificFieldSetWrappersAndFieldSetMembersWithValues(    fsApiNames,
                                                                                        sObjectApiName,
                                                                                        sObjectRecordId);
        dto.isSuccess = !mFieldSetWrappersByApiName.isEmpty();
        if(!dto.isSuccess) {
            dto.technicalMsg += 'Could not find field set wraps for sObjectApiName='+sObjectApiName+
                    '....fieldSetApiNames='+fieldSetApiNames +'.....sObjectRecordId='+sObjectRecordId;
            dto.message = 'We could not find the fieldset for fieldset api name = '+fieldSetApiNames+' Please contact an administrator';
        }
        dto.values.put(MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS,mFieldSetWrappersByApiName.values());
        return dto;
    }


    @AuraEnabled (Cacheable=true)
    public static string serverecho(Id Lookupvalue){
        
        	String sObjName = Lookupvalue.getSObjectType().getDescribe().getName();

        return sObjName;
    }
    
    @AuraEnabled
    public static sObject GetRecord(string recId, String RecName){
        
       // List < sObject > returnList = new List < sObject > ();
      //  tring qr = 'select id, CaseNumber from '+match+' where id='+'\'' + BrowserURLId + '\'
        
        String sQuery = 'select Name, Id from '+RecName+' where Id='+'\'' + recId + '\'';
        List < sObject > returnList = Database.query(sQuery);
        
       /* for( sObject obj: lstofRecords){
            returnList.add(obj);
        }*/
       return returnList[0];
        
       // sObject sObj = Schema.getGlobalDescribe().get(ObjectName).newSObject() ;
    }
    
   /* @AuraEnabled
public static SObject getObject(String objId, String objectType, String fields){
    if (String.isBlank(objId) || !(objId instanceOf Id)){
        throw new AuraHandledException('no id');
    }
    String query = 'SELECT ';
    query += fields;
    query += ' FROM ' + objectType;
    query += ' WHERE Id = :objId ';
    try{
        List<SObject> objects = Database.query(query);
        if (objects != null && objects.size() > 0){
            return objects[0];
        }
        else{
            throw new AuraHandledException('No record retrieved');
        }
    }
    catch(Exception e){
        throw new AuraHandledException(e.getMessage());
    }
}*/
}