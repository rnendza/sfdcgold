public class CommunityAsyncSettings {

    public static final String HPD_PURGE_MDT_TYPE_DEV_NAME = 'Hpd_Purge';

    public static Community_Async_Job_Setting__mdt retrieveCommunityAsyncMdt(String devName) {
        Community_Async_Job_Setting__mdt setting;

        DescribeSObjectResult describeResult = Community_Async_Job_Setting__mdt.getSObjectType().getDescribe();
        List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
        String q = 'SELECT ' + String.join(fieldNames, ',') + ' FROM  ' + describeResult.getName() + ' WHERE developername = :devName';

        setting = DataBase.query(q);
        return setting;
    }

}