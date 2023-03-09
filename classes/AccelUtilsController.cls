/**
 * Backs accelUtilsSvc lwc component.
 */
public with sharing class AccelUtilsController {
    /**
     * Retrieves high level / overall community settings (ie. Debug_Console)
     * @return  An instance of Community_Setting__mdt  for 'System_Settings'
     */
    @AuraEnabled ( Cacheable = true)
    public static Community_Setting__mdt retrieveCommunitySystemSettings() {
        Community_Setting__mdt systemSettings = retrieveCommunityMeta('System_Settings');
        return systemSettings;
    }
    /**
    *
    *
    * @param sObjectType
    * @param devName
    *
    * @return
    * @TODO move to custommetadatasvc when jobs are unscheduled.
    */
    public static Community_Setting__mdt retrieveCommunityMeta( String settingName ) {
        Community_Setting__mdt  communitySettingMdt;

        DescribeSObjectResult   describeResult          = Community_Setting__mdt.getSObjectType().getDescribe();
        List<String>            fieldNames              = new List<String>(describeResult.fields.getMap().keySet());

        String q = '    SELECT ' + String.join(fieldNames, ',') +
                '   FROM    Community_Setting__mdt ' +
                '   WHERE   developername = :settingName ';

        communitySettingMdt = Database.query(q);
        return communitySettingMdt;
    }
}