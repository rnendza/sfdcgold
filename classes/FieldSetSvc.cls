/**
 * FieldSetSvc provides for various operations to dynamically determine fieldset information in
 * addition to dynamic sObject Calls.  Generally this is meant to return it's data in the most generic type as possible
 * unless there is a need to abstract clients (controllers) from complex logic. The Clients should mutate this returned
 * data into whatever they need to pass to the UI. There is an exception on lookup fields (which is questionable)
 * in regard to logic branching for those to retrieve the related sObject Name value.
 */
public without sharing class FieldSetSvc {

    public final static String LOOKUP_FIELD_TYPE    = 'REFERENCE';
    public final static String NAME_FIELD_API_NAME  = 'NAME';
    public final static List<String> CUSTOM_OBJECT_HISTORY_FIELDS = new List<String>{
            'Id', 'Field', 'OldValue', 'NewValue','DataType',
            'ParentId', 'Parent.Name', 'CreatedById', 'CreatedBy.Username', 'CreatedDate', 'CreatedBy.Name'
    };
    public final static List<String> STANDARD_OBJECT_HISTORY_FIELDS = new List<String>{
            'Id', 'Field', 'OldValue', 'NewValue','DataType',
            'CreatedById', 'CreatedBy.Username', 'CreatedDate', 'CreatedBy.Name'
    };
    /**
     * Retrieves the Label of given sObject.Field.
     *
     * @param sObjectApiName    The sObject API Name to find ie. Account or Custom_Object__c.
     * @param fieldApiName      The field API Name to find. ie.  Stage or Lead_Source__c
     *
     * @return The field label if found, otherwise blank.
     */
    public static String getFieldLabel(String sObjectApiName, String fieldApiName) {
        String fieldLabel = '';
        Schema.SObjectType sObjType = CustomDescribe.getGlobalDescribe().get(sObjectApiName);
        if(sObjType != null) {
            Schema.SObjectField field = sObjType.getDescribe().fields.getMap().get(fieldApiName);
            if(field != null) {
                fieldLabel = field.getDescribe().label;
            }
        }
        return fieldLabel;
    }


    /**
     * Retrieves all fields on the sObject (and values) for a given rec id and api name.
     * @param recordId        The Id of the record.
     * @param sObjectApiName  The sObject Api Name.
     *
     * @return an sObject with values.
     */
    public static SObject retrieveAllSObjectFieldsAndData(Id recordId, String sObjectApiName) {
        Set<String> fieldApiNames = retrieveAllSObjectFieldApiNames(sObjectApiName);
        return retrieveSObjectDynamic(sObjectApiName,fieldApiNames,recordId);
    }
    /**
     * Finds all the required fields in an SObject and translate them to FieldSetMemberWrappers.
     * @param sObjectApiName  The SObject Api Name.
     * @return  A Map of FieldApiName => FieldSetMemberWrapper.
     *
     * @see FieldSetWrapper
     */
    public static Map<String,FieldSetMemberWrapper> getSObjectRequiredFields(String sObjectApiName) {

        Map<String,FieldSetMemberWrapper> fieldSetMemberWrappersByFieldApiName = new Map<String,FieldSetMemberWrapper>();
        Schema.SObjectType sObjType = CustomDescribe.getGlobalDescribe().get(sObjectApiName);
        Schema.DescribeSObjectResult r = sObjType.getDescribe();
        Map<String,Schema.SObjectField> fields = r.fields.getMap();

        for(String field : fields.keySet()) {
            Schema.DescribeFieldResult describeResult = fields.get(field).getDescribe();
            if (describeResult.isCreateable()  && !describeResult.isNillable() && !describeResult.isDefaultedOnCreate()) {
                fieldSetMemberWrappersByFieldApiName.put(   describeResult.getName(),
                                                            new FieldSetMemberWrapper(fields.get(field),true));
            }
        }
        return fieldSetMemberWrappersByFieldApiName;
    }
    /**
     * Gets Specific FieldSetWrappers for a specific sObject Api Name and Field Set Api Name(s). Use this when
     * we have no record id. ie (new mode)
     *
     * @param fieldSetApiNames The api names of the FieldSet(s) to find.
     * @param sObjectApiName   The sObject Api Name.
     * @return a Map of FieldSetApiName => FieldSetWrapper.
     *
     * @see FieldSetWrapper
     * @see FieldSetMemberWrapper
     */
    public static Map<String,FieldSetWrapper> getSpecificFieldSetWrappersAndFieldSetMembers(Set<String> fieldSetApiNames,
                                                                                            String sObjectApiName) {
        Map<String,FieldSetWrapper> mFieldSetWrappersByApiName = new Map<String,FieldSetWrapper>();
        Map<String,FieldSet> mFieldSetsByApiName = getSpecificFieldSets(fieldSetApiNames,sObjectApiName);
        for(String apiName : mFieldSetsByApiName.keySet()) {
            FieldSetWrapper fsw = new FieldSetWrapper(mFieldSetsByApiName.get(apiName));
            mFieldSetWrappersByApiName.put(apiName,fsw);
        }
        return mFieldSetWrappersByApiName;
    }
    /**
     * Gets all FieldSetWrappers for a specific sObject Api Name. Use this when we have no record id ie (new mode)
     * Note. this is only the Parent Fieldset Wrapper.. not it's members!
     *
     * @param sObjectApiName   The sObject Api Name.
     * @return a Map of FieldSetApiName => FieldSetWrapper.
     *
     * @see FieldSetWrapper
     * @see FieldSetMemberWrapper
     */
    public static Map<String,FieldSetWrapper> getAllFieldSetWrappersAndFieldSetMembers(String sObjectApiName) {

        Map<String,FieldSetWrapper> mFieldSetWrappersByApiName = new Map<String,FieldSetWrapper>();
        Map<String,FieldSet> mFieldSetsByApiName = getAllFieldSets(sObjectApiName);
        for(String apiName : mFieldSetsByApiName.keySet()) {
            FieldSetWrapper fsw = new FieldSetWrapper(mFieldSetsByApiName.get(apiName));
            mFieldSetWrappersByApiName.put(apiName,fsw);
        }
        return mFieldSetWrappersByApiName;
    }
    /**
     * Based on the sObjectApi, and sObject Record Id, This will retrieve ALL FieldSets and
     * their FieldSetMember children. It uses associative wrappers for easy client consumption and serialization.
     *
     * This will match the values (and Referenced field name value (if it's a lookup and has a value) . It will merge this
     * back onto the FieldSetMember Wrapper for easy client consumption.
     *
     * Note. .careful here if there are a lot of field sets on the sObject with alot of files that are lookup fields!
     * Best to use specific fieldsets and key in on theme.
     *
     * @param sObjectApiName  The sObject Api Name
     * @param recordId        The recordId of the sObject to use for 'edit mode'.
     * @return                A Map of Field Set Api Name => FieldSetWrapper.
     *
     * @see FieldSet
     * @see FieldSetWrapper
     * @see FieldSetMember
     * @see FieldSetMemberWrapper
     *
     */
    public static Map<String, FieldSetWrapper> getAllFieldSetWrappersAndFieldSetMembersWithValues(  String sObjectApiName,
                                                                                                    Id recordId) {
        Map<String, FieldSet> mFieldSetsByApiName = getAllFieldSets(sObjectApiName);
        return getSpecificFieldSetWrappersAndFieldSetMembersWithValues(mFieldSetsByApiName.keySet(),sObjectApiName,recordId);
    }
    /**
     * Based on the FieldSets api Name(s), sObjectApi, and sObject Record Id, This will retrieve all specific FieldSets and
     * their FieldSetMember children. It uses associative wrappers for easy client consumption and serialization.
     *
     * This will match the values (and Referenced field name value (if it's a lookup and has a value) . It will merge this
     * back onto the FieldSetMember Wrapper for easy client consumption.
     *
     * @param sObjectApiName  The sObject Api Name
     * @param recordId        The recordId of the sObject to use for 'edit mode'.
     * @return                A Map of Field Set Api Name => FieldSetWrapper.
     *
     * @see FieldSet
     * @see FieldSetWrapper
     * @see FieldSetMember
     * @see FieldSetMemberWrapper
     */
    public static Map<String, FieldSetWrapper> getSpecificFieldSetWrappersAndFieldSetMembersWithValues(Set<String> fieldSetApiNames,
                                                                                                       String sObjectApiName,
                                                                                                       Id recordId) {

        Map<String,FieldSet> mFieldSetsByApiName = getSpecificFieldSets(fieldSetApiNames,sObjectApiName);
        Map<String, FieldSetWrapper> mFieldSetWrappersByApiName = new Map<String, FieldSetWrapper>();
        //  Add the Id since it prob won't be in the fieldset.
        Set<String> fieldApiNames = new Set<String>{'Id'};
        //  Find all the Field api names in the field set so we can use them to query the sObject.
        for (String apiName : mFieldSetsByApiName.keySet()) {
            FieldSetWrapper fsw = new FieldSetWrapper(mFieldSetsByApiName.get(apiName));
            mFieldSetWrappersByApiName.put(apiName, fsw);
            for (FieldSetMemberWrapper fsm : fsw.fieldSetMemberWrappers) {
                fieldApiNames.add(fsm.fieldApiName);
            }
        }
        SObject sObj = retrieveSObjectDynamic(sObjectApiName, fieldApiNames, recordId);
        if(sObj!=null) {
            mFieldSetWrappersByApiName = tagFieldSetMemberWithValue(sObj,mFieldSetWrappersByApiName);
        }
        return mFieldSetWrappersByApiName;
    }
    /**
     * Rolls through the original fieldsetwrap and of course it's child fieldsetmember wraps and finds all members
     * that are lookups with an existing value. It will collection the api names and id values of those members grouped
     * by api name and then fire a soql query to get the name value if possible. after that it was match the name value
     * with the Id and modify the original object in the original map.
     *
     * @param sObj                           The sObject that we are working with.
     * @param mFieldSetWrappersByApiName     A Map of FieldSetApiName => FieldSetWrapper that needs to be modified.
     * @return                               A Map of FieldSetApiName => FieldSetWrapper
     */
    public static Map<String,FieldSetWrapper> tagFieldSetMemberWithValue( SObject sObj,Map<String,FieldSetWrapper> mFieldSetWrappersByApiName) {

        Map<String, Object> mValuesByApiName = sObj.getPopulatedFieldsAsMap();
        //  Tag the value attributes on the fieldset members
        if (!mFieldSetWrappersByApiName.isEmpty()) {
            List<FieldSetMemberWrapper> membersForLookups = new List<FieldSetMemberWrapper>();

            for (FieldSetWrapper fsw : mFieldSetWrappersByApiName.values()) {
                fsw.fieldSetSObjectRecordId = sObj.Id;
                List<FieldSetMemberWrapper> fsms = fsw.fieldSetMemberWrappers;

                for (FieldSetMemberWrapper fsm : fsms) {
                    fsm.fieldSetApiName = fsw.fieldSetApiName;
                    if (mValuesByApiName.containsKey(fsm.fieldApiName)) {
                        //  Set the value regardless of field type (object prop)
                        fsm.fieldValue = mValuesByApiName.get(fsm.fieldApiName);
                        //  we have a lookup field and we have a value lets store it for later use to get the Name field value.
                        if(fsm.fieldType == LOOKUP_FIELD_TYPE && fsm.fieldValue != null) {
                            membersForLookups.add(fsm);
                        }
                    }
                }
            }
            //  Boom ok. we have lookup fields with values.. not lets go see if we can get the name field.
            if(!membersForLookups.isEmpty()) {
                List<FieldSetMemberWrapper> membersModified = new List<FieldSetMemberWrapper>();
                membersModified = handleLookupFieldNameValues(membersForLookups);
                if(!membersModified.isEmpty()) {
                    System.debug(LoggingLevel.INFO,'----- we have modified members!');
                    //  @todo tune the below to only loop through what is needed!
                    //  Loop  through original collection for lookups and modify it if there is a match with the
                    //  child array of members modified on the Id value.
                    for (FieldSetWrapper fsw : mFieldSetWrappersByApiName.values()) {
                        List<FieldSetMemberWrapper> fsms = fsw.fieldSetMemberWrappers;
                        if(fsms != null){
                            for(FieldSetMemberWrapper fsm : fsms) {
                                if(fsm.fieldType == LOOKUP_FIELD_TYPE && fsm.fieldValue != null) {
                                    for(FieldSetMemberWrapper memberModified : membersModified) {
                                        if((Id)memberModified.fieldValue == (Id)fsm.fieldValue) {
                                            System.debug(LoggingLevel.INFO,'----- we found a match!');
                                            fsm.sObjectReferenceToNameFieldValue = memberModified.sObjectReferenceToNameFieldValue;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return mFieldSetWrappersByApiName;
    }
    /**
     * So basically here we work with only Lookup fields. we ned to great a map of sObj Api Name ==> List<Id> values
     * so that we can run only 1 query for each type of sObject referenced.
     *
     * @param membersForLookups  A List for FieldSetMemberWrappers.
     */
    public static List<FieldSetMemberWrapper> handleLookupFieldNameValues(List<FieldSetMemberWrapper> membersForLookups) {
        List<FieldSetMemberWrapper> membersToQuery = new List<FieldSetMemberWrapper>();
        List<FieldSetMemberWrapper> membersModified = new List<FieldSetMemberWrapper>();
        Map<String,List<Id>> mSObjectApiName_IdValues = new Map<String,List<Id>>();

        // Scrub it to be sure the field value is an Id and group Ids by sObject Type.
        for(FieldSetMemberWrapper fsm : membersForLookups) {
            if(fsm.fieldValue != null && fsm.fieldValue instanceof Id) {
                membersToQuery.add(fsm);
                if(!mSObjectApiName_IdValues.containsKey(fsm.sObjectReferenceToApi)) {
                    mSObjectApiName_IdValues.put(fsm.sObjectReferenceToApi, new List<Id>{(Id)fsm.fieldValue});
                } else {
                    List<Id> existingIds = mSObjectApiName_IdValues.get(fsm.sObjectReferenceToApi);
                    existingIds.add((Id)fsm.fieldValue);
                }
            }
        }
        if(!membersToQuery.isEmpty()) {
            membersModified = queryLookupNameFieldValues(membersToQuery,mSObjectApiName_IdValues);
        }
        return membersModified;
    }
    /**
     * So here wwe fire the actual soql queries (if the name field exists) and then we map them by Map Id => Name value.
     * @param mSObjectApiName_IdValues
     * @param mKey_Fsm
     */
    public static List<FieldSetMemberWrapper> queryLookupNameFieldValues(   List<FieldSetMemberWrapper> membersToQuery,
                                                                            Map<String,List<Id>> mSObjectApiName_IdValues) {
        String fieldToFind = NAME_FIELD_API_NAME;
        if(!mSObjectApiName_IdValues.isEmpty()) {
            Map<Id,String> mRecordId_NameValue = new Map<Id,String>();

            for( String sObjectApiName : mSObjectApiName_IdValues.keySet()) {
                if(doesFieldExist(sObjectApiName,fieldToFind)) {
                    List<Id> idValues = mSObjectApiName_IdValues.get(sObjectApiName);

                    String soql = '';
                    soql += ' SELECT Id, '+ fieldToFind;
                    soql += ' FROM     '  + sObjectApiName;
                    soql += ' WHERE Id IN :idValues ';
                    System.debug(LoggingLevel.WARN,'Fire query for lookup name value');
                    Map<Id, SObject> m = new Map<Id, SObject>((List<SObject>) Database.query(soql));
                    if(!m.isEmpty()) {
                        for(SObject sObj : m.values()) {
                            mRecordId_NameValue.put(sObj.Id, (String)sObj.get(fieldToFind)); // @todo dangerous cast?
                        }
                    }
                }
            }
            if(!mRecordId_NameValue.isEmpty()) {
                //  Finally Tag these evil demons with a Name value!
                for(FieldSetMemberWrapper fsm : membersToQuery) {
                    //@TODO dangerous cast??
                    if(mRecordId_NameValue.containsKey( (Id)fsm.fieldValue) ) {
                        fsm.sObjectReferenceToNameFieldValue = mRecordId_NameValue.get((String)fsm.fieldValue);
                    }
                }
            }
        }
        return membersToQuery;
    }
    /**
     * Gets specific FieldSet(s) for a specific sObject.
     *
     * @param fieldSetApiNames  The Api of the field set names desired.
     * @param sObjectApiName    The Sobject Api Name
     * @return A Map of FieldSetApiName => FieldSet
     */
    public static Map<String,FieldSet> getSpecificFieldSets(Set<String> fieldSetApiNames, String sObjectApiName) {
        Map<String,FieldSet> filteredFieldSets = new Map<String,FieldSet>();
        try {
            Map<String,FieldSet> allSObjectFieldSets = getAllFieldSets(sObjectApiName);
            if(!allSObjectFieldSets.isEmpty()) {
                for(String apiName : allSObjectFieldSets.keySet()) {
                    if(fieldSetApiNames.contains(apiName)){
                        filteredFieldSets.put(apiName,allSObjectFieldSets.get(apiName));
                    }
                }
            }
        } catch (Warnings.InvalidSObjectApiNameException invalidEx) {
            System.debug(LoggingLevel.ERROR,invalidEx);
        }
        return filteredFieldSets;
    }
    /**
     * Gets A Map of all FieldSets for a given SObject Api Name.
     *
     * @param sObjectApiName the SObject ApiNAme ie 'Foo_Custom__c'.
     * @return a Map of FieldSetApiName => FieldSet
     * @throws InvalidSObjectApiNameException
     */
    public static Map<String,FieldSet> getAllFieldSets( String sObjectApiName) {
        SObjectType sObjectType = getSObjectType(sObjectApiName);
        Warnings.checkSObjectType(sObjectType,sObjectApiName);
        return getAllFieldSets( getSObjectType(sObjectApiName) );
    }
    /**
     * Gets A Map of all FieldSetWrappers for a given SObject Api Name.
     *
     * @param sObjectApiName the SObject ApiNAme ie 'Foo_Custom__c'.
     * @return a Map of FieldSetApiName => FieldSetWrapper
     * @throws InvalidSObjectApiNameException
     */
    public static Map<String,FieldSetWrapper> getAllFieldSetWrappers( String sObjectApiName ) {
        Map<String,FieldSetWrapper> mFieldSetWrappersByApiName = new Map<String,FieldSetWrapper>();
        SObjectType sObjectType = getSObjectType(sObjectApiName);
        Warnings.checkSObjectType(sObjectType,sObjectApiName);
        Map<String,FieldSet>  mFieldSetsByApiName =  getAllFieldSets( getSObjectType(sObjectApiName) );
        for(String apiName : mFieldSetsByApiName.keySet()) {
            mFieldSetWrappersByApiName.put(apiName, new FieldSetWrapper(mFieldSetsByApiName.get(apiName),false));
        }
        return mFieldSetWrappersByApiName;
    }
    /**
     * Gets A Map of all FieldSets for a given SObjectType.
     *
     * @param sObjectType the SObjectType to get the Map of field sets for.
     * @return a Map of FieldSetApiName => FieldSet
     */
    public static Map<String,FieldSet> getAllFieldSets( SObjectType sObjectType ) {
        return sObjectType.getDescribe().fieldSets.getMap();
    }
    /**
     * Gets a Set of field api names for the passed FieldSets.
     *
     * @param mFieldSets  a map of FieldSetApiName => FieldSet
     * @return a Set<String> of all the fieldApiNames in the past fields sets.
     */
    public static Set<String> getAllFieldSetsFields(Map<String,FieldSet> mFieldSets) {
        Set<String> fields = new Set<String>();
        if(mFieldSets != null) {
            for(String key : mFieldSets.keySet()) {
                FieldSet fs = mFieldSets.get(key);
                for(Schema.FieldSetMember fsm : fs.getFields()){
                    fields.add(fsm.getFieldPath());
                }
            }
        }
        return fields;
    }
   /**
    * Gets an SObjectType for the given sObject API Name.
    *
    * @param sObjectName  The api of the sObject ie. 'Foo_Custom__c'
    * @return  The SObject Type for the passed api name.
    */
    public static SObjectType getSObjectType( String sObjectName)  {

        SObjectType sObjType;
        try {
            sObjType = ((SObject) Type.forName(sObjectName).newInstance()).getSObjectType();
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR,ex);
        }
        return sObjType;
    }
    /**
     * Gets a List of all sObjectTypes in the target org that have field sets.
     * Only returns those with FieldSets that have Members!
     * @return a List<Schema.SObjectType> of SObjects with field sets.
     */
    public static List<Schema.SObjectType> getSObjectTypesWithFieldSets(){
        List<Schema.sObjectType> sObjectTypes = new List<Schema.SObjectType>();
        for(Schema.SObjectType sObj : CustomDescribe.getGlobalDescribe().values()){
            Map<String, Schema.FieldSet> FieldSetMap = sObj.getDescribe().fieldSets.getMap();
            Boolean hasFields = false;
            if(FieldSetMap!=null && FieldSetMap.keySet().size() > 0){
                for(String fieldSetApiName : FieldSetMap.keySet()) {
                    Schema.FieldSet fieldSet = FieldSetMap.get(fieldSetApiName);
                    if(fieldSet.getFields().size() > 0) {
                       hasFields = true;
                    }
                }
            }
            if(hasFields) {
                sObjectTypes.add(sObj);
            }
        }
        return sObjectTypes;
    }
   /**
    * Retrieves a populated sObject for the given sObjectType and recordId.
    *
    * @param sObjectType       The type of sObject.
    * @param selectFields      The additional fields to add to the select besides Id,Name.
    * @param recordId          The SFDC Record Id.
    * @return  A single sObject that was found, otherwise null.
    */
    public static SObject retrieveSObjectDynamic( SObjectType sObjectType, Set<String> selectFields, Id recordId ) {
        String soql = '';
        List<String> lSelectFields = new List<String>();
        lSelectFields.addAll(selectFields);
        String soqlFields = String.join(lSelectFields, ',');
        String sObjectName = sObjectType.getDescribe().getName();

        soql += ' SELECT   '+ soqlFields;
        soql += ' FROM     '+sObjectName;
        soql += ' WHERE     Id =:recordId ';
        soql += ' ORDER BY  CreatedDate DESC ';

        List<SObject> sObjs = Database.query(soql);
        SObject sObj;
        if(!sObjs.isEmpty()) {
            sObj = sObjs[0];
        } else {
            System.debug(LoggingLevel.WARN,'No data found on '+sObjectName + ' for recordId '+ recordId);
        }
        return sObj;
    }
    /**
     * Retrieves a populated sObject for the given sObject Api Name and recordId.
     *
     * @param sObjectType       The type of sObject.
     * @param selectFields      The additional fields to add to the select besides Id,Name.
     * @param recordId          The SFDC Record Id.
     * @return  A single sObject that was found, otherwise null.
     */
    public static SObject retrieveSObjectDynamic( String sObjectApiName, Set<String> selectFields, Id recordId ) {
        return retrieveSObjectDynamic( getSObjectType(sObjectApiName), selectFields, recordId );
    }
    /**
     * Gets a set of all the field api names for an sObject.
     *
     * @param sObjectApiName
     * @return a Set of field api names for the given sObject.
     */
    public static Set<String> retrieveAllSObjectFieldApiNames(String sObjectApiName) {
        Set<String> apiNames = new Set<String>();
        Set<Schema.SObjectField> sObjectFields = retrieveAllSObjectFields(sObjectApiName);
        for(Schema.SObjectField sObjectField : sObjectFields) {
            apiNames.add(sObjectField.getDescribe().name);
        }
        return apiNames;
    }

    public static Map<String,String> retrieveAllSObjects(){
        Map<String,String> mSobjects = new Map<String,String>();

        Pattern regEx = Pattern.compile('^\\w*?__\\B\\w*__'); // get rid of managed package objects.

        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            String name = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();

            Matcher filter = regEx.matcher(objTyp.getDescribe().getLocalName().toLowerCase());

            if(!name.containsignorecase('history') && !name.containsignorecase('tag') &&
                    !name.containsignorecase('share') && !name.containsignorecase('feed') &&
                    !name.containsignorecase('group') && !name.containsignorecase('public') &&
                    !filter.find() &&
                    !objTyp.getDescribe().isCustomSetting() && objTyp.getDescribe().isCreateable() ){
                mSobjects.put(name,label);
            }
        }
        return mSobjects;
    }

    public static Map<String,String> retrieveHistorySObjects(String objectType){
        Map<String,String> mSobjects = new Map<String,String>();

        Pattern regEx = Pattern.compile('^\\w*?__\\B\\w*__'); // get rid of managed package objects.

        for(Schema.SObjectType objTyp : Schema.getGlobalDescribe().Values()){
            String name = objTyp.getDescribe().getName();
            String label = objTyp.getDescribe().getLabel();

            Matcher filter = regEx.matcher(objTyp.getDescribe().getLocalName().toLowerCase());

            if(name.containsignorecase('history') && !name.containsignorecase('tag') &&
                    !name.containsignorecase('share') && !name.containsignorecase('feed') &&
                    !name.containsignorecase('group') && !name.containsignorecase('public') &&
                    !filter.find() &&
                    !objTyp.getDescribe().isCustomSetting() ){
                if(objectType == 'custom' && name.containsIgnoreCase('_')) {
                    mSobjects.put(name,label);
                } else if(objectType == 'standard' && !name.containsIgnoreCase('_')) {
                    mSobjects.put(name,label);
                } else if(objectType == null){
                    mSobjects.put(name,label);
                }
            }
        }
        return mSobjects;
    }

    public static Map<String,String> retrieveHistorySObjects(List<String> historyObjects){
        Map<String,String> mSobjects = new Map<String,String>();

        List<SObjectType> types = new List<SObjectType>();
        for(String historyObject : historyObjects) {
            types.add(getSObjectType(historyObject));
        }
        for(SObjectType objType : types) {
            String name = objType.getDescribe().getName();
            String label = objType.getDescribe().getLabel();
            mSobjects.put(name,label);
        }
        return mSobjects;
    }

    /**
     * Finds all field describe results for passed SObject Api Names.
     *
     * @param sObjectApiNames  Set of SObject Api Name
     * @return A Map of SObjectApiName => Map  FieldNameName => DescribeFieldResult
     */
    public static Map<String,Map<String,DescribeFieldResult>> retrieveFieldDescribeResults (Set<String> sObjectApiNames) {
        Map<String,Map<String,DescribeFieldResult>> m = new Map<String,Map<String,DescribeFieldResult>>();

        for(String apiName : sObjectApiNames) {
            apiName = apiName.toLowerCase();
            Schema.SObjectType sObjectType = ( (SObject)Type.forName(apiName).newInstance() ).getSObjectType();
            Map<String,SObjectField> mFields = sObjectType.getDescribe().fields.getMap();

            for(String sFieldApiName  : mFields.keySet()) {
                if(!m.containsKey(apiName)) {
                    m.put( apiName,new Map< String,DescribeFieldResult > { sFieldApiName => mFields.get(sFieldApiName).getDescribe() } );
                } else {
                    Map<String,DescribeFieldResult> mDfr = m.get(apiName);
                    mDfr.put( sFieldApiName, mFields.get(sFieldApiName).getDescribe() );
                }
            }
        }
        return m;
    }
    public static Map<String,DescribeSObjectResult> retrieveSObjDescribeResults (Set<String> sObjectApiNames) {
        Map<String,DescribeSObjectResult> m = new Map<String,DescribeSObjectResult>();

        for(String apiName : sObjectApiNames) {
            apiName = apiName.toLowerCase();
            Schema.SObjectType sObjectType = ( (SObject)Type.forName(apiName).newInstance() ).getSObjectType();
            DescribeSObjectResult describeSObjectResult = sObjectType.getDescribe();
            m.put(apiName,describeSObjectResult);
        }
        return m;
    }

    public static Map<String,FieldDefinition> retrieveFieldDescriptions(Set<String> sObjectApiNames) {
        Map<String,FieldDefinition> m = new Map<String,FieldDefinition>();
        List<FieldDefinition> fieldDefs = [
                Select Id,Label, QualifiedApiName, Description
                from FieldDefinition
                Where EntityDefinition.QualifiedApiName IN :sObjectApiNames
        ];
        for(FieldDefinition fieldDef : fieldDefs) {
            m.put(fieldDef.QualifiedApiName.toLowerCase(),fieldDef);
        }
        return m;
    }

    /**
     * @param sObjectApiNames xx
     *
     * @return xx
     */
    public static Map<String,Map<String,FieldDefinition>>  retrieveTrackedFieldDefinitions(Set<String> sObjectApiNames ) {

        Map<String,Map<String,FieldDefinition>> mAll = new Map<String,Map<String,FieldDefinition>>();

        List<FieldDefinition> fieldDefs = [
                SELECT  Id,Label, DeveloperName,QualifiedApiName, Description,EntityDefinition.QualifiedApiName
                FROM    FieldDefinition
                WHERE   EntityDefinition.QualifiedApiName IN :sObjectApiNames
                AND     IsFieldHistoryTracked = TRUE
        ];

        for(FieldDefinition fieldDef : fieldDefs) {
            String sObjName = fieldDef.EntityDefinition.QualifiedApiName;
            if(!mAll.containsKey(sObjName)) {
                mAll.put( sObjName,new Map<String,FieldDefinition> {fieldDef.QualifiedApiName => fieldDef});
            } else {
                Map<String,FieldDefinition> mSobj = mAll.get(sObjName);
                mSobj.put(fieldDef.QualifiedApiName,fieldDef);
            }
        }
        return mAll;
    }



    /**
     * Gets a set of all the sObjectFields for an sObject.
     *
     * @param sObjectApiName
     * @return a Set of sObjectFields for the given sObject.
     */
    public static Set<Schema.SObjectField> retrieveAllSObjectFields(String sObjectApiName) {
        SObjectType sObjectType = getSObjectType(sObjectApiName);
        Warnings.checkSObjectType(sObjectType,sObjectApiName);
        Schema.DescribeSObjectResult describeResult = sObjectType.getDescribe();
        Map<String, Schema.SObjectField> fields = describeResult.fields.getMap();
        List<Schema.SObjectField> lSObjectFields = fields.values();
        Set<Schema.SObjectField> sObjectFields = new Set<Schema.SObjectField>(lSObjectFields);
        return sObjectFields;
    }

    public static List<FieldAuditInfo> retrieveFieldHistory(String historyObjectName,Set<String> fieldApiNames) {
        Date startDate = Date.today().addDays(-15);
        Date endDate = Date.today();
        Set<Id> parentIds = null;
        Set<Id> changedByIds = null;

        return retrieveFieldHistory(historyObjectName,fieldApiNames,startDate,endDate,parentIds,changedByIds);
    }

    public static List<FieldAuditInfo> retrieveFieldHistory(String historyObjectName,Set<String> fieldApiNames,DateTime startDate, Datetime endDate) {
        Set<Id> changedByIds = null;
        Set<Id> parentIds = null;

        return retrieveFieldHistory(historyObjectName,fieldApiNames,startDate,endDate,parentIds,changedByIds);
    }

    public static List<FieldAuditInfo> retrieveFieldHistory(String historyObjectName,Set<String> fieldApiNames,Set<Id> parentIds) {
        Date startDate = Date.today().addDays(-90);
        Date endDate = Date.today();
        Set<Id> changedByIds = null;

        return retrieveFieldHistory(historyObjectName,fieldApiNames,startDate,endDate,parentIds,changedByIds);
    }

    public static List<FieldAuditInfo> retrieveFieldHistory( String historyObjectName,Set<String> fieldApiNames,
                                                      Datetime startDate, Datetime endDate, Set<Id> parentIds,
                                                      Set<Id> changedByIds ) {

        List<FieldAuditInfo> fieldAuditInfos = new List<FieldAuditInfo>();

        String soql = '';
        String selectFields;
        String trackedObjApiName;
        Boolean isCustom = historyObjectName.containsIgnoreCase('__History');

        if(isCustom) {
            trackedObjApiName = historyObjectName.replace('__History','');
            selectFields = String.join(CUSTOM_OBJECT_HISTORY_FIELDS,',');
        } else {
            trackedObjApiName = historyObjectName.replace('History','');
            selectFields = String.join(STANDARD_OBJECT_HISTORY_FIELDS,',');
            selectFields += ' ,'+trackedObjApiName+'Id';
            //@tdo make this dynamic some objects have no name field.
            if(trackedObjApiName != 'ServiceAppointment') {
                selectFields += ',' + trackedObjApiName + '.Name';
            } else {
                selectFields += ',' + trackedObjApiName + '.AppointmentNumber';
            }
        }

        soql += ' SELECT  '+selectFields;
        soql += ' FROM ' + historyObjectName;
        soql += ' WHERE    Field IN :fieldApiNames';
        soql += ' AND      CreatedDate  >= :startDate ';
        soql += ' AND      CreatedDate  <= :endDate ';
        if(parentIds != null) {
            if(isCustom) {
                soql += ' AND      ParentId     IN : parentIds ';
            } else {
                soql += ' AND     '+trackedObjApiName+'Id IN : parentIds ';
            }
        }
        if(changedByIds != null) {
            soql += ' AND      CreatedById  IN : changedByIds ';
        }
        if(isCustom) {
            soql += ' ORDER By Parent.Name, Field, CreatedDate DESC ';
        } else {
            soql += ' ORDER By '+trackedObjApiName+'Id, Field, CreatedDate DESC ';
        }
        soql += ' LIMIT    49000 ';

        List<SObject> results = Database.query(soql);
        for(SObject sobj  : results) {
            FieldAuditInfo fai = new FieldAuditInfo();
            fai.fieldId = (Id)sobj.get('Id');
            fai.fieldName = (String)sobj.get('Field');
            if(isCustom) {
                fai.parentId = (Id) sobj.get('ParentId');
                fai.parentName = (String) sobj.getSObject('Parent')?.get('Name');
            } else {
                fai.parentId = (Id) sobj.get( trackedObjApiName+'Id');
                //@tdo make this dynamic some objects have no name field.
                if(trackedObjApiName != 'ServiceAppointment') {
                    fai.parentName = (String) sobj.getSObject(trackedObjApiName)?.get('Name');
                } else {
                    fai.parentName = (String) sobj.getSObject(trackedObjApiName)?.get('AppointmentNumber');
                }
            }
            fai.oldValue = sobj.get('OldValue');
            fai.newValue = sobj.get('NewValue');
            Object oCreatedBy = sobj.getSObject('CreatedBy')?.get('Name');
            if(oCreatedBy != null) {
                fai.createdByName = (String)oCreatedBy;
            }
            fai.createdDate = (Datetime)sobj.get ('CreatedDate');
            fai.createdById = (Id)sobj.get('CreatedById');
            fai.dataType = sobj.get('DataType');
            if(fai.dataType == 'EntityId') {
                fai.isLookup = true;
            }
            fai.parentDisplayLabel = fai.parentName;
            fieldAuditInfos.add(fai);
        }
        return fieldAuditInfos;
    }

    public class FieldAuditInfo {
        @AuraEnabled public Id fieldId;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String fieldLabel;
        @AuraEnabled public Id parentId;
        @AuraEnabled public Object oldValue = '';
        @AuraEnabled public Object newValue = '';
        @AuraEnabled public String createdByName;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Id createdById;
        @AuraEnabled public String parentName;
        @AuraEnabled public String parentDisplayLabel;
        @AuraEnabled public Boolean isLookup = false;
        @AuraEnabled public Object dataType;
    }


   /**
    *
    * @param sObjectApiName
    * @param fieldApiName
    *
    * @return
    */
    public static Boolean doesFieldExist(String sObjectApiName, String fieldApiName) {
        Boolean doesIt = false;
        SObjectType sObjectType = getSObjectType(sObjectApiName);
        if(sObjectType != null) {
            doesIt = sObjectType.getDescribe().fields.getMap().containsKey(fieldApiName);
        }
        return doesIt;
    }
}