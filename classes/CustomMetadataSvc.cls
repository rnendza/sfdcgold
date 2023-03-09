/**
 * CustomMetadataSvc provides for retrieval operations on custom metadata objects.
 */
public class CustomMetadataSvc {

    /**
     * User the passed parameter to search for:
     *
     * 1. Check the Developer name of the custom meta data
     * OR
     * 2. Check the Label of the custom meta data.
     *
     * @param geoAccuracyValue  The value provided in say Account.ShippingGeocodeAccuracy (or any of the accuracy fields)
     * @return A display value of weak / strong according to mapping in the mdt, otherwise an empty string.
     *
     * @implNote
     * This is done as OR statements are not allowed against custom metadata. Also values in the Geo Accuracy fields
     * are not all conducive to developername fields ie 'Zip/Postal Code'
     *
     * @see Geocode_Setting__mdt
     */
    public static String retrieveGeoAccuracyDisplayValue(String geoAccuracyValue) {
        String displayValue = '';

        List<Geocode_Setting__mdt> settings = [
                SELECT Display_Value__c
                FROM   Geocode_Setting__mdt
                WHERE  DeveloperName = :geoAccuracyValue
        ];
        if(!settings.isEmpty()) {
            Geocode_Setting__mdt setting = settings[0];
            displayValue = setting.Display_Value__c;
        } else {
            settings = [ SELECT Display_Value__c FROM   Geocode_Setting__mdt WHERE  Label = :geoAccuracyValue];
            if(!settings.isEmpty()) {
                Geocode_Setting__mdt setting = settings[0];
                displayValue = setting.Display_Value__c;
            }
        }
        return displayValue;
    }

    public static List<Cash_Logistics_Survey_Setting__mdt> retrieveSurveyMetadatas(String customDevName) {

        List<Cash_Logistics_Survey_Setting__mdt> mdts = new List<Cash_Logistics_Survey_Setting__mdt>();

        try {
            DescribeSObjectResult describeResult = Cash_Logistics_Survey_Setting__mdt.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());

            String q =  ' SELECT ' + String.join(fieldNames, ',')
                    + '   FROM  ' + describeResult.getName() +
                        ' WHERE Survey_Dev_Name__c = :customDevName ' +
                        ' AND   Active__c = TRUE ' +
                        ' ORDER By Order__c ASC ';
            mdts = Database.query(q);
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        return mdts;
    }

    public static Cash_Logistics_Automation_Setting__mdt retrieveAutomationMetadata(String devName) {

        Cash_Logistics_Automation_Setting__mdt mdt;

        try {
            DescribeSObjectResult describeResult = Cash_Logistics_Automation_Setting__mdt.getSObjectType().getDescribe();
            List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());

            String q =  ' SELECT ' + String.join(fieldNames, ',')
                    + '   FROM  ' + describeResult.getName() +
                    '     WHERE DeveloperName = :devName ';

            List<Cash_Logistics_Automation_Setting__mdt> mdts = Database.query(q);
            mdt = !mdts.isEmpty() ? mdts[0] : mdt;
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        return mdt;
    }

    /**
     * @param sObjectType   The Type of sObject.
     * @param devName       The Developer name of the custom metadata record.
     *
     * @return              A Raw sObject if found (Client responsibility to cast), otherwise null.
     */
    public static SObject retrieveCustomMetadata(SObjectType sObjectType,String devName) {
        SObject customMdt;

        try {
            DescribeSObjectResult describeResult = sObjectType.getDescribe();
            List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
            String q =  'SELECT ' + String.join(fieldNames, ',') + ' FROM  ' + describeResult.getName() + ' WHERE developername = :devName';
            customMdt = Database.query(q);
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        return customMdt;
    }
    //----------- @TODO merge the below with above
    public static SObject retrieveCustomSearchMeta(SObjectType sObjectType,String devName) {
        SObject sObj;
        DescribeSObjectResult describeResult = sObjectType.getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String q = 'SELECT ' + String.join(fieldNames, ',') + ' FROM  ' + describeResult.getName() + ' WHERE developername = :devName';
        sObj = DataBase.query(q);
        return sObj;
    }

    /**
     * Retrieves a custom meta data type value for the community. (for now single community).
     *
     * @param settingName - the developer name for query. But think of it more as a record type. ie. Application_Search_Limits
     * @param fieldName   - the actual field name of the value you wish to find. ie. Max_Account_Results__c
     *
     * @return and object containing your value. (clients should case to correct type)
     */
    public static Object retrieveCommunityMetaFieldValue( String settingName, String fieldName ) {
        Community_Setting__mdt communityAppLimitsMdt;
        Object oReturn;
        try {
            communityAppLimitsMdt =
                    (Community_Setting__mdt) CustomMetadataSvc.retrieveCustomSearchMeta(Community_Setting__mdt.getSObjectType(), settingName);
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        if (communityAppLimitsMdt != null) {
            oReturn = communityAppLimitsMdt.get(fieldName);
        }
        return oReturn;
    }

    /**
     * Retrieves account types that we want displayed in the external community.
     * If custom meta data not found. defaults to Accel Account.
     *
     * @return a set containing the account types ie {'Accel Account','Other'}
     */
    public static Set<String> retrieveCommunityAccountTypes() {
        Set<String> accountTypes = new Set<String>();
        Community_Setting__mdt communityAppLimitsMdt;
        String settingName = 'Account_Processing';
        String fieldName = 'Account_Types__c';

        try {
            communityAppLimitsMdt =
                    (Community_Setting__mdt) CustomMetadataSvc.retrieveCustomSearchMeta(Community_Setting__mdt.getSObjectType(), settingName);
        } catch (Exception e) {
            system.debug(logginglevel.error, e);
        }
        if (communityAppLimitsMdt != null) {
            Object obj = communityAppLimitsMdt.get(fieldName);
            if(obj!= null) {
                String sAccountTypes = (String)obj;
                if(sAccountTypes!= null) {
                    accountTypes.addAll(sAccountTypes.split(','));
                }
            }
        }
        if(accountTypes.isEmpty()) {
            //default barring we don't have a custom setting.
            accountTypes.add('Accel Account');
        }
        return accountTypes;
    }

    /**
     * @param sObjectType   The Type of sObject.
     * @param devName       The Developer name of the custom metadata record.
     *
     * @return              An instance of Community_Setting__mdt if found, otherwise null
     */
    public static Community_Setting__mdt retrieveCommunityMeta( String settingName ) {
        Community_Setting__mdt  communitySettingMdt;

        DescribeSObjectResult   describeResult          = Community_Setting__mdt.getSObjectType().getDescribe();
        List<String>            fieldNames              = new List<String>(describeResult.fields.getMap().keySet());

        String q = '    SELECT ' + String.join(fieldNames, ',') +
                    '   FROM    Community_Setting__mdt ' +
                    '   WHERE   developername = :settingName ';

        List<Community_Setting__mdt> mdts =  DataBase.query(q);
        if(!mdts.isEmpty()) {
            communitySettingMdt = Database.query(q);
        }
        return communitySettingMdt;
    }

    /**
     * Returns all 'rows' in the HPD_Total_Setting__mdt Custom Metadata type.
     * @return a list of HPD_Total_Setting__mdt Metadata types.
     */
    public static List<HPD_Total_Setting__mdt> retrieveHpdTotalSettingsMetas() {
        return retrieveHpdTotalSettingsMetas(null);
    }

    /**
     * @param devName the developer name of the HPD_Total_Setting__mdt Metadata type.
     * @return a HPD_Total_Setting__mdt.
     */
    public static HPD_Total_Setting__mdt retrieveHpdTotalSettingsMeta(String devName) {
        HPD_Total_Setting__mdt hpdTotalSetting;
        List<HPD_Total_Setting__mdt> hpdTotalSettings = retrieveHpdTotalSettingsMetas(devName);
        if (!hpdTotalSettings.isEmpty()) {
            hpdTotalSetting = hpdTotalSettings[0];
        }
        return hpdTotalSetting;
    }

    /**
     * @param devName - the developer name of the HPD_Total_Setting__mdt Metadata type.
     * @return a list of HPD_Total_Settings__Mdt objects (1 if devname passed, otherwise multiple for each dev name)
     */
    private static List <HPD_Total_Setting__mdt> retrieveHpdTotalSettingsMetas(String devName) {
        List<HPD_Total_Setting__mdt> hpdTotalSettings;
        if (devName != null) {
            hpdTotalSettings = [
                    SELECT Id, developername,MasterLabel, QualifiedApiName,Notification_Email_Addresses__c,
                            Record_type_Dev_Name_To_Process__c,HPD_Account_Types__c,Last_Daily_HPD_Upload_Date__c,
                            Account_Batch_Size__c 
                    FROM HPD_Total_Setting__mdt
                    WHERE DeveloperName = :devName
            ];
        } else {
            hpdTotalSettings = [
                    SELECT Id, developername,MasterLabel, QualifiedApiName,Notification_Email_Addresses__c,
                            Record_type_Dev_Name_To_Process__c,HPD_Account_Types__c,Last_Daily_HPD_Upload_Date__c,
                            Account_Batch_Size__c
                    FROM HPD_Total_Setting__mdt
            ];
        }
        return hpdTotalSettings;
    }
}