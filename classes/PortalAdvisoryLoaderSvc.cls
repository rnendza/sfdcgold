/**
 * General operations for PA_Advisory__c. Also contains operations to parse PA XML returned in the response
 * from RESTful calls. Finally contains operations to update custom metadata (ie start / end date) for the
 * scheduled calls ie. Metadata.Operations.enqueueDeployment
 *
 * @see PortalAdvisoryLoaderSvcTest
 */
public class PortalAdvisoryLoaderSvc {

    public static String DEFAULT_IMG_TYPE = 'jpeg'; // used to append to the base64 string in the RTE.

   /**
    * Retrieves ALL Fields except Base 64 String data  for supplied PA_Advisory__c Ids.
    *
    * @param paAdvisoryIds The Pa_Advisory__c sObject SFDC Ids.
    * @return A List of PA_Advisory__c sObjects.
    */
    public static List<PA_Advisory__c> retrievePaAdvisories(Set<Id> paAdvisoryIds) {
        List<PA_Advisory__c> paAdvisories = new List<PA_Advisory__c>();

        Set<String> excludeFields = new Set<String> {'Image_Base_64_String__c'};

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Pa_Advisory__c ';
        q += 'WHERE  Id IN :paAdvisoryIds ';
        q += 'ORDER BY Name ASC';

        String formattedQuery = String.format(q,getAllPaAdvisoryFields(excludeFields));
        paAdvisories = Database.query(formattedQuery);
        return paAdvisories;
    }

    /**
     * Retrieves ALL Fields for supplied PA_Advisory__c Ids.
     *
     * @param paAdvisoryIds The Pa_Advisory__c sObject SFDC Ids.
     * @param excludeFields The fields to exclude from SELECT *. (null or empty if you want them all)
     * @return A List of PA_Advisory__c sObjects.
     */
    public static List<PA_Advisory__c> retrievePaAdvisories(Set<Id> paAdvisoryIds,Set<String> excludeFields) {
        List<PA_Advisory__c> paAdvisories = new List<PA_Advisory__c>();

        String q = '';
        q += 'SELECT {0} ';
        q += 'FROM   Pa_Advisory__c ';
        q += 'WHERE  Id IN :paAdvisoryIds ';
        q += 'ORDER BY Name ASC';

        String formattedQuery = String.format(q,getAllPaAdvisoryFields(excludeFields));
        paAdvisories = Database.query(formattedQuery);
        return paAdvisories;
    }

    /**
     * @param userRecords The UserRecord retrieved from the RESTful Service
     * @return A List of Upserted PA_Advisory__c sObjects.
     */
    public static List<PA_Advisory__c> upsertPaRecords(List<UserRecord> userRecords) {
        List<PA_Advisory__c> paAdvisories = new List<PA_Advisory__c>();

        for(PortalAdvisoryLoaderSvc.UserRecord ur : userRecords) {
            PA_Advisory__c advisory = new PA_Advisory__c();

            advisory.GUID__c = ur.guid;
            advisory.Comments__c = ur.comments;
            advisory.Violations__c = ur.violations;
            advisory.Advisory_Number__c = ur.advisoryNumber;
            advisory.Advisory_Date__c = ur.dAdvisoryDate;
            advisory.Advisory_Number_And_Type__c =  ur.advisoryNumberAndType;
            advisory.Advisory_Type__c = ur.advisoryType;
            advisory.Request_Date__c = ur.dRequestDate;
            advisory.Docket_Number__c = ur.docketNumber;
            advisory.Exclusion_Period__c = ur.sExclusionPeriod;
            advisory.SSN__c = ur.ssn != null ? Integer.valueOf(ur.ssn) : null;
            advisory.First_Name__c = ur.firstName;
            advisory.Last_Name__c = ur.lastName;
            advisory.Birth_Date__c = ur.dBirthDate;
            advisory.Cell_Phone__c = ur.cellPhoneNumber;
            advisory.Phone__c = ur.telephoneNumber;
            advisory.Image_Base_64_String__c = ur.imageBase64String;
            advisory.Intake_Removal_Code__c = ur.intakeRemovalCode;
            advisory.Exclusion_Type__c = ur.exclusionType;
            advisory.Intake_Or_Removal__c = ur.intakeOrRemoval;

            if(String.isNotBlank(advisory.Image_Base_64_String__c)) {
                advisory.Has_Image__c = true;
                advisory.Photo__c = '<img src="data:image/'+DEFAULT_IMG_TYPE+';base64,'+advisory.Image_Base_64_String__c+'" />';  // RTE Field
            }

            writeAddress(ur,advisory);
            writePhysicalDesc(ur,advisory);

            paAdvisories.add(advisory);
        }

        upsert paAdvisories PA_Advisory__c.Fields.Advisory_Number_And_Type__c;  // UPSERT USING CONCAT KEY
        return paAdvisories;
    }

    /**
     * @param userRecord    The UserRecord from the deserialized xml.
     * @param paAdvisory    The PA_Advisory_Record__c to write to.
     */
    @TestVisible
    private static void writeAddress(PortalAdvisoryLoaderSvc.UserRecord userRecord, PA_Advisory__c paAdvisory) {
        if(userRecord.userAddress != null) {
            paAdvisory.Address_1__c = userRecord.userAddress.address1;
            paAdvisory.Address_2__c = userRecord.userAddress.address2;
            paAdvisory.Address_3__c = userRecord.userAddress.address3;
            paAdvisory.City__c = userRecord.userAddress.city;
            paAdvisory.State_Code__c = userRecord.userAddress.stateCode;
            paAdvisory.Postal_Code__c = userRecord.userAddress.postalCode;
        }
    }

   /**
    * @param userRecord    The UserRecord from the deserialized xml.
    * @param paAdvisory    The PA_Advisory_Record__c to write to.
    */
    @TestVisible
    private static void writePhysicalDesc(PortalAdvisoryLoaderSvc.UserRecord userRecord, PA_Advisory__c paAdvisory) {
        if(userRecord.userPhysicalDesc != null) {
            paAdvisory.Eye_Color__c = userRecord.userPhysicalDesc.eyeColor;
            paAdvisory.Hair_Color__c = userRecord.userPhysicalDesc.hairColor;
            paAdvisory.Gender__c = userRecord.userPhysicalDesc.gender;
            try {
                paAdvisory.Height_Ft__c = userRecord.userPhysicalDesc.heightFt != null ? String.valueOf(userRecord.userPhysicalDesc.heightFt) : null;
                paAdvisory.Height_In__c = userRecord.userPhysicalDesc.heightIn != null ? String.valueOf(userRecord.userPhysicalDesc.heightIn) : null;
                paAdvisory.Weight__c = userRecord.userPhysicalDesc.weight;
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR,e);
            }

        }
    }

   /**
    * Parse Provider Xml into Apex consumable classes.
    *
    * @param xmlBody xxx
    * @param debugUserRecords   Spit out parsed user records (truncates photo data)
    * @param debugLimits        SFDC Gov Limits
    * @param pullImageData      If false, truncates the base64 Image data.
    *
    * @return  a List of UserRecords;
    *
    *
    * @see  XmlTransformer https://github.com/zabroseric/sfdc-xml-parser
    * @see  Provider doc on xml?
    */
    public static List<UserRecord> parsePaXmlRecords(String xmlBody, Boolean debugUserRecords, Boolean debugLimits, Boolean pullImageData) {
        List<UserRecord> userRecords = new List<UserRecord>();

        XmlTransformer.RESERVED_WORDS = new List<String>{'true'}; //  Must be limited otherwise the regex will hit too complex gov limit.
        if (debugLimits) {
            System.debug('--> before xml deserialize: heapSize: '+Limits.getHeapSize());
        }
        Map<String, Object> objectMap = (Map<String, Object>) XmlTransformer.deserialize(xmlBody).toObject();
        if (debugLimits) {
            System.debug('--> after xml deserialize: heapSize: '+Limits.getHeapSize());
        }

        Integer iNumLoops = 0;
        for (String rootKey : objectMap.keySet()) { iNumLoops++;

            Map<String, Object> mXmlMap = (Map<String, Object>) objectMap.get(rootKey);

            for (String resultsKey : mXmlMap.keySet()) { iNumLoops++;

                Map<String, Object> mAdvisory = (Map<String, Object>) mXmlMap.get(resultsKey);

                if (mAdvisory != null) {
                    for (String advisoryKey : mAdvisory.keySet()) { iNumLoops++;

                        //  If only one record we must be careful here.
                        List<Object> allAdvisoryObjects;
                        Boolean isList = mAdvisory.get(advisoryKey) instanceof List<Object>;
                        if(isList) {
                            allAdvisoryObjects = (List<Object>) mAdvisory.get(advisoryKey);
                        } else {
                            Object singleAdvisoryObject = mAdvisory.get(advisoryKey);
                            allAdvisoryObjects = new List<Object>();
                            allAdvisoryObjects.add(singleAdvisoryObject);
                        }
                        //-------

                        for (Object advisoryObject : allAdvisoryObjects) { iNumLoops++;
                            UserRecord user = new UserRecord();

                            Map<String, Object> mSingleAdvisory = (Map<String, Object>) advisoryObject;

                            if(mSingleAdvisory.containsKey('attributes')) {
                                //  <Advisory ExclusionType="VGTs" IntakeOrRemoval="I" AdvisoryType="VGT">
                                Map<string,Object> mAttributes = (Map<String,Object>)mSingleAdvisory.get('attributes');
                                user.exclusionType = (String)mAttributes.get('ExclusionType');
                                user.intakeOrRemoval = (String)mAttributes.get('IntakeOrRemoval');
                                user.advisoryType = (String)mAttributes.get('AdvisoryType');
                            }

                            user.ssn = (String) mSingleAdvisory.get('SSN');
                            user.guid = (String) mSingleAdvisory.get('APIUserGuid');
                            user.advisoryNumber = (String) mSingleAdvisory.get('AdvisoryNumber');
                            user.firstName = (String) mSingleAdvisory.get('FirstName');
                            user.lastName = (String) mSingleAdvisory.get('LastName');
                            user.dAdvisoryDate = convertToDate(mSingleAdvisory.get('AdvisoryDate'));
                            user.dRequestDate = convertToDate(mSingleAdvisory.get('RequestDate'));
                            user.dBirthDate = convertToDate(mSingleAdvisory.get('BirthDate'));
                            user.advisoryNumberAndType = user.advisoryNumber+user.advisoryType;
                            user.sExclusionPeriod = (String) mSingleAdvisory.get('ExclusionPeriod');
                            user.docketNumber = (String) mSingleAdvisory.get('DocketNumber');
                            user.cellPhoneNumber = (String) mSingleAdvisory.get('CellphoneNumber');
                            user.telephoneNumber = (String)mSingleAdvisory.get('TelephoneNumber');
                            if(pullImageData) {
                                user.imageBase64String = (String) mSingleAdvisory.get('Photo');
                                user.hasImage = user.imageBase64String != null && user.imageBase64String != '';
                            }
                            user.imageSize = user.imageBase64String?.length();
                            user.intakeRemovalCode = (String) mSingleAdvisory.get('IntakeRemovalCode');
                            user.comments = (String) mSingleAdvisory.get('Comments');
                            if(user.comments == null || user.comments == '') {
                                user.comments = 'None Provided';
                            }
                            user.violations = (String) mSingleAdvisory.get('Violations');
                            if(user.violations == null || user.violations == '') {
                                user.violations = 'None Provided';
                            }

                            Map<String,Object> mAddress = (Map<String,Object>) mSingleAdvisory.get('Address');
                            parseAddress(mAddress,user);

                            Map<String,Object> mPhysicalDesc = (Map<String,Object>) mSingleAdvisory.get('PhysicalDesc');
                            parsePhysicalDesc(mPhysicalDesc,user);

                            userRecords.add(user);
                        }
                    }
                } else {
                    System.debug(LoggingLevel.WARN,'No User Data in XML!');
                }
            }
        }

        if (debugUserRecords) {
            String msg = '\n\n === PARSED USER STUFF ('+userRecords.size() +' user records found) ====\n';
            msg +='(Note base64 data truncated when debugging for clarity)\n';
            for (UserRecord ur : userRecords) {
                msg += '\n---> ' + ur + '\n';
            }
            System.debug(msg + '\n\n');
        }
        if(debugLimits) {
            System.debug('---> # of times in for loop: ' + iNumLoops);
        }
        return userRecords;
    }

   /**
    * Enqueue job to use the Metadata.Deploy container to update the custom metadata record.
    * (A fancy version of a DML Update)  This will call back when done to handleResult.
    *
    * @param metdataName            The api Custom mdt name ie. (Cash_Logistics_Setting__mdt)
    * @param recordDevName          The record dev name ie. (Scheduler)
    * @param label                  The record label ie. (Scheduler)
    * @param metadataFieldValueMap  A map of Field_Api_Name => new field value ie. (Next_Cycle__c => 5)
    * @return                       The Job Id fired.
    *
    */
    public static Id updateCustomMetadata(  String metdataName, String recordDevName, String label,
                                            Map<String, Object> metadataFieldValueMap) {

        Metadata.CustomMetadata cMetadata = new Metadata.CustomMetadata();
        cMetadata.fullName = metdataName + '.' + recordDevName;
        cMetadata.label = label;

        for(String key : metadataFieldValueMap.keySet()){
            Metadata.CustomMetadataValue cMetadataValue = new Metadata.CustomMetadataValue();
            cMetadataValue.Field = key;
            cMetadataValue.Value = metadataFieldValueMap.get(key);
            cMetadata.values.add(cMetadataValue);
        }
        Metadata.DeployContainer mdContainer = new Metadata.DeployContainer();
        mdContainer.addMetadata(cMetadata);
        CustomMetadataCallBack callback = new CustomMetadataCallBack();
        Id jobId;

        if(!Test.isRunningTest()) {
            jobId = Metadata.Operations.enqueueDeployment(mdContainer, callback);
        }

        System.debug('---> fire job:'+jobId);
        return jobId;
    }

    /**
     * @param xmlBody the xml body
     * @return  A List<String> of error messages.
     */
    public static List<String> findProviderErrors(String xmlBody) {
        List<String> errors = new List<String>();

        XmlTransformer.RESERVED_WORDS = new List<String>{'true'}; //  Must be limited otherwise the regex will hit too complex gov limit.
        Map<String, Object> objectMap = (Map<String, Object>) XmlTransformer.deserialize(xmlBody).toObject();

        for (String rootKey : objectMap.keySet()) {
            Map<String, Object> mXmlMap = (Map<String, Object>) objectMap.get(rootKey);

            for (String errorsKey : mXmlMap.keySet()) {
                Map<String, Object> mErrors = (Map<String, Object>) mXmlMap.get(errorsKey);
                if (mErrors != null && !mErrors.isEmpty()) {
                    for (String errorKey : mErrors.keySet()) {
                        Object oError = mErrors.get(errorKey);
                        if (oError != null) {
                            errors.add((String) oError);
                        }
                    }
                }
            }
        }
        return errors;
    }

    /**
     * @return Number of PA_Advisory__c records
     */
    public static Integer retrieveNumAdvisoryRecords() {
        return [ SELECT Count() FROM PA_Advisory__c ];
    }

    /**
     * @return Max Advisory_Date__c from PA_Advisory__c.
     */
    public static Date retrieveMaxAdvisoryDate() {
        Date maxDate;
        List<AggregateResult> ars = [SELECT Max(Advisory_Date__c) MaxDate FROM PA_Advisory__c ];
        if(!ars.isEmpty()) {
            maxDate = (Date) (ars[0].get('MaxDate'));
        }
        return maxDate;
    }

   /**
    * @return Min Advisory_Date__c from PA_Advisory__c.
    */
    public static Date retrieveMinAdvisoryDate() {
        Date minDate;
        List<AggregateResult> ars = [SELECT Min(Advisory_Date__c) MinDate FROM PA_Advisory__c ];
        if(!ars.isEmpty()) {
            minDate = (Date) (ars[0].get('MinDate'));
        }
        return minDate;
    }

    /**
     * @param mAddress  The map containing the Address object in the xml.
     * @param user      The UserRecord to write to.
     */
    @TestVisible
    private static void parseAddress(Map<String,Object> mAddress, UserRecord user) {
        user.userAddress.address1 = (String)mAddress.get('Address1');
        user.userAddress.address2 = (String)mAddress.get('Address2');
        user.userAddress.address3 = (String)mAddress.get('Address3');
        user.userAddress.city = (String)mAddress.get('City');
        user.userAddress.stateCode = (String)mAddress.get('StateCode');
        user.userAddress.postalCode = (String)mAddress.get('PostalCode');
    }

   /**
    * @param mPhysicalDesc  The map containing the Physical Desc in the xml.
    * @param user           The UserRecord to write to.
    */
    @TestVisible
    private static void parsePhysicalDesc(Map<String,Object> mPhysicalDesc, UserRecord user) {
        user.userPhysicalDesc.hairColor = (String)mPhysicalDesc.get('HairColor');
        user.userPhysicalDesc.eyeColor = (String)mPhysicalDesc.get('EyeColor');
        user.userPhysicalDesc.gender = (String)mPhysicalDesc.get('Gender');
        user.userPhysicalDesc.heightFt = convertToInt(mPhysicalDesc.get('HeightFt'));
        user.userPhysicalDesc.heightIn = convertToInt(mPhysicalDesc.get('HeightIn'));
        user.userPhysicalDesc.weight = convertToInt(mPhysicalDesc.get('Weight'));
        if(user.userPhysicalDesc.heightFt != null && user.userPhysicalDesc.heightIn != null) {
            user.userPhysicalDesc.heightDisplay = user.userPhysicalDesc.heightFt+'-'+user.userPhysicalDesc.heightIn;
        }
        user.userPhysicalDesc.distinguishingMarks = (String)mPhysicalDesc.get('DistinguishingMarks');
    }

   /**
    * Wrap each person up and use however you want.
    * @see UserAddress
    * @see UserPhysicalDesc
    */
    public class UserRecord {

        @AuraEnabled public String ssn;
        @AuraEnabled public String guid;
        @AuraEnabled public Date dBirthDate;
        @AuraEnabled public Date dAdvisoryDate;
        @AuraEnabled public Date dRequestDate;
        @AuraEnabled public String advisoryType;
        @AuraEnabled public String advisoryNumber;
        @AuraEnabled public String advisoryNumberAndType;
        @AuraEnabled public String sExclusionPeriod; // 1 year, 5 years, Lifetime and X Year(s)
        @AuraEnabled public String exclusionType; // Casino, Casino Exclusion Fantasy Contest, Fantasy Exclusion, iGaming, iGaming Exclusion, VGT and VGT Exclusion
        @AuraEnabled public String lastName;
        @AuraEnabled public String firstName;
        @AuraEnabled public String imageBase64String;
        @AuraEnabled public Integer imageSize;
        @AuraEnabled public String cellPhoneNumber;
        @AuraEnabled public String telephoneNumber;
        @AuraEnabled public Boolean hasImage;
        @AuraEnabled public String intakeOrRemoval;
        @AuraEnabled public String intakeRemovalCode;
        @AuraEnabled public String docketNumber;
        @AuraEnabled public String comments;
        @AuraEnabled public String violations;

        @AuraEnabled public UserAddress userAddress;
        @AuraEnabled public UserPhysicalDesc userPhysicalDesc;

        @AuraEnabled public PA_Advisory__c paAdvisory;  //  Matched SFDC Record.

        public UserRecord() {
            this.userAddress = new UserAddress();
            this.userPhysicalDesc = new UserPhysicalDesc();
        }
    }

    public class UserAddress {
        @AuraEnabled public String address1;
        @AuraEnabled public String address2;
        @AuraEnabled public String address3;
        @AuraEnabled public String city;
        @AuraEnabled public String stateCode;
        @AuraEnabled public String postalCode;
    }

    public class UserPhysicalDesc {
        @AuraEnabled public String hairColor;
        @AuraEnabled public String eyeColor;
        @AuraEnabled public String gender;
        @AuraEnabled public Integer heightFt;
        @AuraEnabled public Integer heightIn;
        @AuraEnabled public String  heightDisplay;
        @AuraEnabled public Integer weight;
        @AuraEnabled public String  distinguishingMarks;
    }

    /**
     * Handle callback from a metadata deploy (update mdt)
     */
    public class CustomMetadataCallBack implements Metadata.DeployCallback {

        public void handleResult(Metadata.DeployResult result, Metadata.DeployCallbackContext context) {
            System.debug('---> result='+result);
            System.debug('----> context = '+context);
        }
    }

    public static Date convertToDate(Object o) {
        Date dt;
        if (o != null && o instanceof String) {
            dt = Date.parse((String)o);
        }
        return dt;
    }

    @TestVisible
    private static Integer convertToInt(Object o) {
        Integer i;
        if (o != null && o instanceof String) {
            i = Integer.valueOf(o);
        }
        return i;
    }
    /**
     * @param excludeFields  Any fields to be excludes (null or empty if you want them all)
     * @return                List of fields suitable for substitution in a SELECT.
     */
    public static List<String>  getAllPaAdvisoryFields(Set<String> excludeFields) {
        Map<String, Schema.SObjectField> fieldsMap = PA_Advisory__c.sObjectType.getDescribe().fields.getMap();
        String sFields;
        List<String> filteredFields = new List<String>();

        if( excludeFields != null && !excludeFields.isEmpty()) {
            for (String fieldName : fieldsMap.keySet()) {
                if(!excludeFields.contains(fieldName)) {
                    filteredFields.add(fieldName);
                }
            }
            sFields = String.join(filteredFields,',');
        } else {
            sFields = String.join(new List<String>(fieldsMap.keySet()), ',');
        }
        List<String> fields = new List<String>{sfields};
        return fields;
    }

    //  ======  SAMPLE VALID XML RECORD'S FOR TESTING PURPOSES
    @TestVisible
    private static String retrieveMockXml() {
        String mockXml = '<SelfExclusionAPIQuery><Results><Advisory ExclusionType="VGTs" IntakeOrRemoval="I" AdvisoryType="VGT"><BirthDate>06/14/1973</BirthDate><SSN>7464</SSN><AdvisoryNumber>VGT-000864</AdvisoryNumber><AdvisoryDate>07/06/2022</AdvisoryDate><RequestDate>6/30/2022</RequestDate><ExclusionPeriod>Five Years</ExclusionPeriod><IntakeRemovalCode>I</IntakeRemovalCode><DocketNumber>22-00864-SE</DocketNumber><LastName>Peltier</LastName><FirstName>Mark</FirstName><AliasName></AliasName><CellphoneNumber></CellphoneNumber><TelephoneNumber>4124195730</TelephoneNumber><Violations></Violations><Comments></Comments><Photo>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</Photo><APIUserGuid>e34c30b5-efe1-42e8-9153-0a9c8a79d662</APIUserGuid><EnrollmentAdvisoryNumber></EnrollmentAdvisoryNumber><Address><Address1>909 WOODLAND AVE</Address1><Address2></Address2><Address3></Address3><City>MCKEESPORT</City><StateCode>PA</StateCode><PostalCode>15133</PostalCode></Address><PhysicalDesc><DistinguishingMarks/><HairColor>Bald</HairColor><EyeColor>Brown</EyeColor><Gender>M</Gender><HeightFt>5</HeightFt><HeightIn>5</HeightIn><Weight/></PhysicalDesc></Advisory><Advisory ExclusionType="VGTs" IntakeOrRemoval="I" AdvisoryType="VGT"><BirthDate>12/01/1993</BirthDate><SSN>9599</SSN><AdvisoryNumber>VGT-000865</AdvisoryNumber><AdvisoryDate>07/06/2022</AdvisoryDate><RequestDate>6/30/2022</RequestDate><ExclusionPeriod>One Year</ExclusionPeriod><IntakeRemovalCode>I</IntakeRemovalCode><DocketNumber>22-00865-SE</DocketNumber><LastName>Berzinsky</LastName><FirstName>Alec</FirstName><AliasName></AliasName><CellphoneNumber>4848948416</CellphoneNumber><TelephoneNumber/><Violations></Violations><Comments></Comments><Photo>R0lGODlheAB4APcAAAAAAAAAMwAAZgAAmQAAzAAA/wArAAArMwArZgArmQArzAAr/wBVAABVMwBVZgBVmQBVzABV/wCAAACAMwCAZgCAmQCAzACA/wCqAACqMwCqZgCqmQCqzACq/wDVAADVMwDVZgDVmQDVzADV/wD/AAD/MwD/ZgD/mQD/zAD//zMAADMAMzMAZjMAmTMAzDMA/zMrADMrMzMrZjMrmTMrzDMr/zNVADNVMzNVZjNVmTNVzDNV/zOAADOAMzOAZjOAmTOAzDOA/zOqADOqMzOqZjOqmTOqzDOq/zPVADPVMzPVZjPVmTPVzDPV/zP/ADP/MzP/ZjP/mTP/zDP//2YAAGYAM2YAZmYAmWYAzGYA/2YrAGYrM2YrZmYrmWYrzGYr/2ZVAGZVM2ZVZmZVmWZVzGZV/2aAAGaAM2aAZmaAmWaAzGaA/2aqAGaqM2aqZmaqmWaqzGaq/2bVAGbVM2bVZmbVmWbVzGbV/2b/AGb/M2b/Zmb/mWb/zGb//5kAAJkAM5kAZpkAmZkAzJkA/5krAJkrM5krZpkrmZkrzJkr/5lVAJlVM5lVZplVmZlVzJlV/5mAAJmAM5mAZpmAmZmAzJmA/5mqAJmqM5mqZpmqmZmqzJmq/5nVAJnVM5nVZpnVmZnVzJnV/5n/AJn/M5n/Zpn/mZn/zJn//8wAAMwAM8wAZswAmcwAzMwA/8wrAMwrM8wrZswrmcwrzMwr/8xVAMxVM8xVZsxVmcxVzMxV/8yAAMyAM8yAZsyAmcyAzMyA/8yqAMyqM8yqZsyqmcyqzMyq/8zVAMzVM8zVZszVmczVzMzV/8z/AMz/M8z/Zsz/mcz/zMz///8AAP8AM/8AZv8Amf8AzP8A//8rAP8rM/8rZv8rmf8rzP8r//9VAP9VM/9VZv9Vmf9VzP9V//+AAP+AM/+AZv+Amf+AzP+A//+qAP+qM/+qZv+qmf+qzP+q///VAP/VM//VZv/Vmf/VzP/V////AP//M///Zv//mf//zP///wAAAAAAAAAAAAAAACH5BAEAAPwALAAAAAB4AHgAAAj/AMOIESMQh0CCOAgOVLjw4MKHECNKnEiRIpqHFwdmvMjooiQxaBil6Tjm48iQaT5OQqkSTSM0kx4eNLgwYUGGFitWzAhSo8+PHtGwdCmpZFFJk5CKSfpyZJpJKaMihSnpKdWUUJFihTmJ5g0xNBEKDGOzppivZMOgoTmWYVsxZwYKRONQZ0SePnsuBAqyo18xIhkNjCnmY8uXRws7leTw4NeyNhOi1YsXIs/KEecuzNjR58Uxgj327Xsx48ilYtKgTsPyZEyrL1fGdgkTZsKzYmLIRegWYsGDDm/vHt5bb3GIgnt2HgOyEUjQtEOTLlx4TEg0JZcOjVm1I/eSbwV+/yXumPfDhHQZjveNWS7ejdQrZy8NGD72ji9flszuurqk6ClpV9WAA+GwhWQD6eYVWBgpFBdOxl1kkIS7XVSXbxJdZ1x9PRXlF320AcWdagPSBpVI3TnFyCSTCcQFWRAqBNxtwjU03IU6qZWhRJ2ZBFhqPql4UmqB9ReTbP/JVltSAYIF43gzHnTReo2tddNEbZWlY10OfbRXT+1RV19y12XHHUhHlbQYakrmB5NAB4rlpEw1ypSZXLfhiONdDT4knWGUgRlfZzFhl2KSig3I3UpMIgVjWlyElZaNbX2V0Vs86XjbehheamOfeKnGEUcDvSSGfkWhcZiq+6VY5ICxof/26JyRftqnebZ+Chyedlr2pZ+k5gWimEAFRhtiaqJY26tYqUaTDOW9BSVuOM01k0KcnkeprVLy6RkjzH0EXXKiWmdqoUoSeKR2jZY0SXnVMphrrmX5JmmMET3o660R9mSdYIDSBhN+MLF7lST5DZhSpGMhCKOMBe7GZYw41ihpvXfm9ZCXnRHrk7koFcmSmWwuSdS7YHFBccTF+eCecOJ5CjGE2e7alkAA/yUomRo5ByiJF6Wr5lRMojhbV9juNi2m88ZII53cmvdVDFRT3eVHMXyVXF6Egfkvq0eZeKzYjQzo7q65NWQxvm/NCXHDNo53w8NhUL2CASoEoILdMGz/EcZYjDASQxiMSCIJL5ls7eWZr3V01GKMDiwVoysl6Dbabd9gIcvH3RlcGFzc8CLVBgCQN94HqAAADFSvvsUNjGAikOGSFJ5UdRp+jSLI3R2raHcrOUrceJv2utmuPC1I7aavHwj6DTGsAID0eAcAg/UrpL76CqzX7TfVWxSGFGPhD2TY10YttpWSkU/SSJOR2VxTY8QxiPZwaB24RQwGVq136ga4mwADiDfUmS4GewvD3lSwhZAwQhhlKwzASPOSVy2lSN6B1VSE55DQyWsyEimLvoxHEBlUDXpUUwEAVcjC1KUuBqvTm/VM98KqhcFwY5JEJobBw158hCQtaU2S/6pyJCJyJSk0mtTMHqI5gqTHXuIpEFliAAPurQCB1LOiC1UQwOt50XoHMB0AYFhFGFRRIFWjYgy2MAkeDiMpxTrJ0XY3PiS1Lzxu0xJF7menFMaAgAAAQABhmDovUs2LY0zk3vwYwyoGUgWqYx0jEvfGYRDjjbh73IrYpTCtICwpk0BaGKCFsWs9EW000SNZ9pfIGcIQgXhDZOvuRkVXko6WLCTj6vCGQDX+rXCG60UmYuKdRBUMSSNp35suV6+2KQRmn0JQCqUnxgMCwIU05OLqFFk11rFOjWo0QPSqSEYE7s1vgrkhHN+IsGP+7im/C2Uo3dLMGnVrIPqSH0GiV/+6AlpvhjAQY0BhyD1XbpOgBCxoGffGS1/u83XAXBEPb7cSY8VGUS5JScEMwpbLyas4T7sJGmGoOmoiMgCBDCNJUac6GNJwm1zknhq/Cb6aUnF/rNtfGHqRjIlSZWiMWkpRGiXPXTVzWxHTp0Kg9ce7BZKAqttmQCMJgBlysaWPhCkv63bIwXk1DH075A325zcx9MKSw6idRpMC1KuAsmD6lNt5LuQQKuWGe1kNpF5Vp7fSmXR6gAxkQAEr03N6DwaQpOIVzbjGvo01DFuAASMwuS5GtZOoS+qa6D5K1568BWPj+WMMWfrSApqudNe7aumues2rBtSbVkvjN3MK2y3/0I4RAknrkh6nsBWlpBGgpF/bhrsQlwl3INCLalT1utrWBlCqhD3o9q53SJn2zXtjjYEWIEs1LawRKbygXRja6J/alC2ZB8MKR68UGbNgaDg2mSUg9RbI/yEWlqxjYSxT28UuwjancGKsd28aPsiOpW6FW5G6hLo+yhHRTsTN0sTc1jq9PhK11kujhmHb1VjOtKaQndvfxOC3v/ntdbBdJOGEMT53mXe3LgZl0lhWl83JrDhh2OZpAym9b77ub0A2cZDB+U0hBzkMixBDkk1MkL+poIzd/S4oDRcdy76vjqDs2tuK9946gaVqFtbrQNc4N+RITEYnNjKalYyGJC+i/3Bvxu3+vBvZwRHOcJhcK1Gw0j6sRBFXdQFhQ+jClhssV5D0DYBXSbybSFAnEoa5MyPO0JE3Gy6ijGFMpWl3W+7+bY2LyAQv3szONBFtt6FESkzghUf2VISkYaZpWxKMQ05zGhOX5nR4bQ3nXC/CcOGtm4F/mdbJHulgZTvSibLCohstxK5qgeaupkbIalpNIR/yi611GN5J7Jp24cVEeL+d60wzYtySWARZCVK7pPDwPwRjFFaIpmrkisGD1FqZtmTi0qdmWDcHMYzh4JiUXni7F5jwYXiFwYthhLcX4U0rL3C9bUZA+nA+XIT3JFi7iWbltwdzF7NxbCMcPNE9Tv+EGPTqG1WqYTskAwfvJISB8JpLIq1pFSYvZs5tSYhbEhD/OS/GPe5esBi3gyscQVZU0WOztY5UCeVvqOVMlGPoNhUO6Atnfemk7Pzm3hb1G2l+c0kwXNSi3jkvbA70w9284W58t5xhcEPxge3FTLIss7lsHj2+91MvJanouiQ+8Lbd4ZkwujAVn3hheNvxLB630MHd8HZYfhgQd3IMMh0TN5331MkWubTOLC/jUuvkX1Zh4MsKGHgjxYeTQPjOay7qhL/97aI+HMHB7e21D0MYPGzHu7m7hcLZNhMblNxlMYpEsuCbeK3eENVXere9TcYvcDT8+ETt7djbHvO29yH/uCVhi9qZ/3C+F3475tGLJHv3DL3A2X/c5HRkF0zl9h6IDzorkZVvEXxyYRi0NnDjVnDh13ZqN3nZR36Hc240NwzsMAztQA/0UGx1swjDoHT90VtPp3dpgSDxIi8jdDMDwV+0ZGc4QzgcNwm0VnCqhjiwV3YGNz7ld36F83BwNwzukAwU+EaL8F1ppVYjMxVzpF7Pc2+P8WfOFBfo8WyJ9GFy8ReRgGnjM3vcl3MyiIC65nZE93u9EIET2IO9IGdhUGoCUhL2xygiET5yhS8ktCutU0sqxhBJpm2850MO10bdl4c+RHsQp3DBdDiY94DBpwz0IHy88DcYyEMAYja8//V5orQg64Ub17IZZmFoumQ1bbEIMEc73bd2hOhwlaRzwxB+EYeAisdDQ+dwwkeB9KAMwndn7eBDIPEdYaNMsfE3OPAiu6hPJqcQ6SE/MIBNPiYj2lY4fWh0eoh5g5iKsddwiZdzNGd7BUiIrUgP+qAMGThZPIQavKUqKiI2SOM8uPEYc7InEQE9eIVAZcZ1wYQ4DQd0ogiNPSSKNNd4g4hza5dwNhd3rrgP9MALD+RGfREgpjYUFTQJ5KgbVNd3DTMX07JPCZU14eM3MBd2bXdWOaiR+ciMbmR0o4h4ythtbleI2JiBcGc482Fq2uEmA/IVaGEg9tYinENCrTNQBP9RPsBUcKJYjyAZdx4JlM3oeHmIQxonGIXDQ+6gD/uQgcBHGEEjII14TEsBLVb5G9ByifinI/ZWNwSkUxBTOJlAlNEYd2dVj0IplDy3T2MFPUB2bjykDAApj08XH6iiURUkFVEkOmXmJB31UUzEb1c1OKHzY+PhOPKYlnEHfIspe7SzT7X1S8EkgfSwD/rgbRnYE+sCKJUVMqoxENDClx5UYA5DiWGxGwaROor2aWsEYmPhEXh2lkB5VqmIeZeGW790Z+d3c4xJDNioDLcjGkGRLEHhkplTjucoRRjyMAkSUCM1YGCQNXvjTWT1N8D2ez0JfCNJcVS4bb4ngTzkijj/1Bm0gYZoiCqqklFJZBMvcpUJUS+TmCfYkjdjoVO/FFFN9mlb4DftRnPa6YU0R27blm5KlpTCNwzz4Jv0MD4DMSSJgS64gxhywhsxyYZTd1wclRtjdGBjQTuYMAniFoS89nP2OIg8FzhTiGRDNmI3B57qJ5e0OB2FIhLlVUG0ATXxwpfPhJwetQV4I0GAQx24CTgh4WhTaDj+eZbwWDuQhlsfcQMrkFyDU6A5mKA9mDheAiYSCm8k0h/2gpxlAZM4sR6PEYeEExL5OTizxTo3QHetl260U5vBZn43pEORxVWbh3Oi6A7DQIH6kIcaYSzPkSqOYx1HwZV8xCu18iR4/zJte/OmH1E3rCMGmVA3B8BVYYB8Z5pkuudw4pdkTXpnZ+FNN1A7vdCD4dmn9EAMWboR4FIs5WkSHSN9k0KTk6JEU1NC3cNphGNg1NFVs/NrtaObykhzuMWpFHdpCmFpw5AMfJqgVvqn0vEh1PEapGFResFHwZFvaTOJ5Rilxxip2Bap8odnmWadrweSoIqMyIeHugaUwjcPlUkPiaMx2FEaH/I1gkIf9RMeGfo8HoQWmghM5odbVJhWaJdWElQYtqB4LVqwtJNW3Td+q0gMVmqIFZilzSGknzkk4Tirw8KcnPVsJTRKZ+FyE8RrwEY7RLmbwooUNNcOfAqnnIaw6P+WYMFnse5QmX/qJcMCJh0Dq/vKNmfWXl3ZP2t0Q90JbmXJcyoLdH84DPowD8IHbOs0PitbeRaroPpQDzxUF6GBlBlRFM1xr9kGIjrCr+TBEJGhAiNmOwMHcSY6cTU3c97miQ+3pxWIeZIHiHmodmc5DzvIs8ogkMLyMa46tvGhHPCxL3Pynm9RNW96bn34fWd5VmQHiOYnt2clr1V7cxBntw+ne3DXDsQQhpXZjTiiuBFiqAVTO/SRpXGxOfFSVwORQDCndgcXlCApm473bX1YefQwDw53ip6akUD3nTpoiPpQgeF1uIEiHfExItFhIRoCvfJymm2adLazc0TZcLT/WUkAKn7AFLy9YLpVm6SQF7prB7rg6YqoGiNbY4liAhhBBW+qMh0dgxeodBDTMxeM0IcH10bhy7tkV7A4KIGIOHPM2At4qHYe2Q6wqKAVGKMX0rgNUhspUjlAKxqC8nfQM6k7CYOiiLnn66JyR2sGB4o6aH5u9IB/GKBnhb7DS4GF+7xNozEaYTjJRhUEkRS1ESgY0Vm9RKyHd7ludKApTDgrAsMz7HCBE3dwt3be+8TugLEHiluppBOZ4hOKcxLFhL8fjBleZD4u6MDMKHznEHw6WGyZBrU8FLMyC6AeicbJK5sVaMNu5CWYoxNkxVjW2SgnkRjUobFbglyroxvI/wi6MIzC4Olw7cbCbQx8OlvBH+mF83jCE7jJ4KnFuLHFnXMWdZMbT7YCS0c0hRE08MEXeZFCc1NHaPzEbWy64Bl7LFZzOavA7ZAMwveAcKeRBtebEryzcccIMjlXNdlBozxSBwQ74rMmgCLEctFLrfeJHsmnB6rEive7OcjGqiiIU9yYTyzBnLxzD3maD2k/Z7E/UyoeqtNSDNZJqRy2gjJGa1QYO4eWuazEkCx+iBPHX+hwcQbB4Qu+P9nGe+tGgqEb5JihV3fKgiGltXRf6qRWxUQiOlxOhGPN4MmnjzyLNJdxNzh0IPm8wjp0Zte7zTjDvKzAoohbSRgp5SOmSf8YgEnxN6FDZq80qcw3z6IiHWGAQlOacDskmxJosWZ5dCy6spd2n4EIvowpTDmLvntszKGjMjB51bzBqBJlsEnxPSlkOuqkdyGyuBYiU+EzPrJ5ukIZXkhpYAS7a4ygcfdJa+H8gOrnyCS2IHHyge2ZNoDheLh10yvyaaqpG6rWSdYxo2IySDZgWy2axihMvkCmELfldrfJGEimZHGqz9ncQ5F6lTJQQnvd12cROuO1uRFXr5BVSDEQdSxoWSyhF+B0mJHNQz01nt4jEOMWoLXjeyVNO5wYODB70B9tgaddoeu1XqP9FcNaGG/kQ0qnG6+0N5MwTEvCLrVIHZjYNxb/iRTePAxpWqcfCcwNxwvnANXip2vdjMLCB3GSYCAG4Z7hAy1X/RVxclaTBWzAJN5k9k0qMEmJLWMEwhe9VDXFd9ssWGIR20MQxwu2gN5DF+ERvopSHIi+nMRxvGqiPUoeLt/6M991yoJwKWoJ9k3WRanXrWpXgSJp4ByC1VVfAb7DB91mCeEUbgs6juPkFziB4722poo71JOKpxCDE5oeRN24oeSiA98+V81nhQatGVArkFtIMUzDlGp59wZQUU4AVhiMuWsJJ3FzPddvZgtvluaMUAhlnuYn/XMsVrzgDKijxJcxcN94rhuieQNJIVEzqGBckDViMEYwIAaVNExQ/7cS2ZEamSAG2gNO6iSi+zjXBWoLjKDjl67jlq7pOg5xyPi7QGe3bYe8jOFyWVOYBsKXziMDr3PVONSWEPEUXR5IGlY1BzCM03MDN4BSVQU92MNLWlN2eNZwgbPpDdvpfxjht0DS5UfFaFen5urCCmvnOo0DRz5W1p4be54QMmBCKPXtBhAANzAGmaAJgx5m6B4AaaAJmpAJaMDrupRLN4R8uMVDYieQm752EHcOvcDvVFzhDgx8E6fZTJzaN5iBOVblCwE+1n4gOq3t1P0UT6EJcDAJXJ4G1k7r1z0G/WZhKCUDmVDu7J4JaeBSBiRYIwZkYieKbqfpvLDsFe7y2/+Mcz40bGqhdGX4EcWXCb6pDJc0CVQDPQ6fG0qeNVUVAAcQAzKQEGOQBuUOFlW17pkwBu/JHGlw9WOw6ypwA04f8iXvVNukNwguBnT7vQ9+OGhu6T9utesLfIYj6FaDThK0Q8rAp10T8o0APTKQXf3T8Alx9VCRCZTAGtGDA5OgCSyS9GPA5ZpACW8w+APB63olBpoACsqgCWlwA1W1Y7GkFsGUcMCHCRKXa4rIhSEq+grLVTr1Y0A2CT0oCR0fA43A84Kj9HWz93cOPZpADOze+5OgBpkfSDiw7jFh7TKQ9MevaJJvYXze7pqAA9r0SGDktmgCj/lIcxcH7W2tqXX/s/XCtnFjtfB6pRuW5PPKoAz7RJFZ43Jp0PRikPUo9RXmPv7r3vu+X/J69e2bX19UND0AAUDFAQAwAACIcQAGjDBiJE3CNEziMGGZJC2SxEhSL2EUJfLKxEuSmBgwYsQQc+Pkyi1iwhwEEKDhMGL0lBGruY/YSRkxbvQkGQPm0IMBxLxJIyYATBxi0jx9ioMo0aVEDQg9OFDFwZVhNIqcKFKjJLK9PlrUiCbMypMmTYZRcYPmsEwSayobJmnljUz1MrVke1LMVKI4JmnKNOZG1alLA6gwcNBAVcoACAo0sCJyZKwlY4RBM5bXJEmYxubNSzbMjTBrPZtka3LFjUnKWJTZvDlMBswAK2JMqjcpzSTiQbEShnlAzJhMmjQNT9N0N8zIVbcCiBxTYPKCAgMYLHmga8OHGcmSHesyTEuVQn1uubEFtkmEKlsGzRqD5s1MyiahFEOMSQL/FMqxmCYjTLmnnFNjEhwYg1A7AFbgjiAVHiMIhgCyWwEGlW5wST00SAswRPhWcsmzlQ5Q4SSYMiFmQIW++44LGHG7DRpiMhEupRiqyg45qsQ7qarjsJOMOu2uM8Cg7ba7iq3WUtoiDLLUY20l2FT0rEWsCBJjGNtw2nEuYoYh7jBi6lmGmJuUcS6TomDaqjohh2LMzgnnfOwgghyLATLNsNsQsvA++wwNlxjJkq3vYrgKIbeyzMrPMG27bRnbMikQJjGUweGkpgQc6s85T20sO8euG8rJyYIETyWDNKMQuwthi8+lLLd4bSEWxQPvM0bgIuiyomJoKo1MeCwwM4JW/1BWjJ56enAyVpWs87HKnnTyQG8N9A7BmFpbrSRbgWzRw8BucGvDDhXSysphVTpIQ3uRc9faAwJASRNi2lxmGapgqjVPJTekLEjekAT3wBa9WkStGyArCEMYOky3O0gDhZRWA7YIbZHWtoiMQjuFuvBCbWPSkEUMZ3MqwIWrU1jPg2pFtSoKGTPZMp+zEuMMr66ET4Vu/YQhM6XfNegtKy9Sa7Va/3RyQ8sgy3cpzRCerLJC6TxwKVaX4hBJVhGM7EIE++zzMpQkiWQs9BoKw60Vbi1oIJOqFGMRh8zzai2uBKI6pmz9VFtbDVcQI5PhJllYwoGzcixIsvvk08+ixP91m6y4IyELE2EwMU+9taYcmiyRzotEjNYnZrherV81sqiBENIugDQ0KUZgJc1OEknh51SVO4a3sprCy5ZiKHRJRBrtPGHIsug8sqZf/TyMIhacbJ8v9+52lq/OV6gVmpJKfJwjzHzQCyu10ECE37/M5Kr+fl7154WZRJheMIHe84YBktVlLyNokA92KEQhe2krMvVbW2bc9bPI3WlP2VmeZBijHQMgT3PaMZWf3sY/TPzPhCEJCUT+R5rnAdB6oFPL+6wWQoJk5mbV0cpSXOYyA9nJh6eyluF+N7PN4Q5ct0MiAEBkven1TxKoeWJeRMK/0WBvblhJ2/IQ9D7lXTD/bAdSnvieRJhr/YxGe8Jd5ihjEJcV0Tpvewj/5OjE1Azjfy0kS14YkaI57etqz0JboeZHoxwiKIMZ7KAONZewyXmrVnqqSrEkJC6ZOIQ0qBkgCsGykYeIRS0uQtx3vvgtD3oPfFRbGcFQZTvhyTA7NrOaAyVkIZb1UDIAOg9E0ERCFpLuSq05jigRtqc2dpFFCqyl2ijULLEBiTp9QtDOFHaz5HiwfogDYTUX9qjPBMg86DEPI4ZVrkqpyobD9NkWh3nG731PQx+MH5402EfJiUty24rl7SJZKe3EwDc+CZF6fNKe66xTKJdxmdIcmM85FUifA1FkpdB1OfohE0oQT9qM/ToYT3OS73sKS9l3VvArFazvSQ/s5xcjiqGw4TCaaCuYuGRaMMotkk6xzOb7JOSYdz4SbDOMHRAdhqAfTUihRnwn7kxVTO1srZaWCQgAOw==</Photo><APIUserGuid>73c468f2-0745-47bb-aee5-cd2880751506</APIUserGuid><EnrollmentAdvisoryNumber></EnrollmentAdvisoryNumber><Address><Address1>2110 PENNSYLVANIA AVE</Address1><Address2>APT K6</Address2><Address3></Address3><City>BETHLEHEM</City><StateCode>PA</StateCode><PostalCode>18018</PostalCode></Address><PhysicalDesc><DistinguishingMarks/><HairColor>Brown</HairColor><EyeColor>Hazel</EyeColor><Gender>M</Gender><HeightFt>5</HeightFt><HeightIn>8</HeightIn><Weight/></PhysicalDesc></Advisory><Advisory ExclusionType="VGTs" IntakeOrRemoval="I" AdvisoryType="VGT"><BirthDate>08/28/1990</BirthDate><SSN>2530</SSN><AdvisoryNumber>VGT-000866</AdvisoryNumber><AdvisoryDate>07/06/2022</AdvisoryDate><RequestDate>7/1/2022</RequestDate><ExclusionPeriod>Five Years</ExclusionPeriod><IntakeRemovalCode>I</IntakeRemovalCode><DocketNumber>22-00866-SE</DocketNumber><LastName>Cameron</LastName><FirstName>Brian</FirstName><AliasName></AliasName><CellphoneNumber></CellphoneNumber><TelephoneNumber>2676643595</TelephoneNumber><Violations></Violations><Comments></Comments><Photo>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</Photo><APIUserGuid>ddf2a712-fddd-4777-b461-46bc08942750</APIUserGuid><EnrollmentAdvisoryNumber></EnrollmentAdvisoryNumber><Address><Address1>639 MORRIS ST</Address1><Address2></Address2><Address3></Address3><City>PHILADELPHIA</City><StateCode>PA</StateCode><PostalCode>19148</PostalCode></Address><PhysicalDesc><DistinguishingMarks/><HairColor>Brown</HairColor><EyeColor>Hazel</EyeColor><Gender>M</Gender><HeightFt>6</HeightFt><HeightIn>2</HeightIn><Weight/></PhysicalDesc></Advisory></Results></SelfExclusionAPIQuery>';
        return mockXml;
    }

    //  ======  SAMPLE VALID XML RECORDS FOR TESTING PURPOSES
    @TestVisible
    private static String retrieveMockXml_1record() {
        String mockXml = '<SelfExclusionAPIQuery><Results><Advisory ExclusionType="VGTs" IntakeOrRemoval="I" AdvisoryType="VGT"><BirthDate>06/14/1973</BirthDate><SSN>7464</SSN><AdvisoryNumber>VGT-000864</AdvisoryNumber><AdvisoryDate>07/06/2022</AdvisoryDate><RequestDate>6/30/2022</RequestDate><ExclusionPeriod>Five Years</ExclusionPeriod><IntakeRemovalCode>I</IntakeRemovalCode><DocketNumber>22-00864-SE</DocketNumber><LastName>Peltier</LastName><FirstName>Mark</FirstName><AliasName></AliasName><CellphoneNumber></CellphoneNumber><TelephoneNumber>4124195730</TelephoneNumber><Violations></Violations><Comments></Comments><Photo>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</Photo><APIUserGuid>e34c30b5-efe1-42e8-9153-0a9c8a79d662</APIUserGuid><EnrollmentAdvisoryNumber></EnrollmentAdvisoryNumber><Address><Address1>909 WOODLAND AVE</Address1><Address2></Address2><Address3></Address3><City>MCKEESPORT</City><StateCode>PA</StateCode><PostalCode>15133</PostalCode></Address><PhysicalDesc><DistinguishingMarks/><HairColor>Bald</HairColor><EyeColor>Brown</EyeColor><Gender>M</Gender><HeightFt>5</HeightFt><HeightIn>5</HeightIn><Weight/></PhysicalDesc></Advisory></Results></SelfExclusionAPIQuery>';        return mockXml;
    }

    //  ======  SAMPLE VALID XML INDICATING A PROVIDER ERROR
    @TestVisible
    private static String retrieveMockErrorXml() {
        String mockXml ='<PGCBSEInquiry><Errors><Error>{Error Code} – {Error Description}</Error></Errors></PGCBSEInquiry>';
        return mockXml;
    }

    //  ======  SAMPLE NO RESULTS FOUND AT PROVIDER
    @TestVisible
    private static String retrieveMockNoResultsXml() {
        String mockXml = '<SelfExclusionAPIQuery><Results></Results></SelfExclusionAPIQuery>';
        return mockXml;
    }
}