/**
 * Created by Zach on 3/21/2019.
 */

public without sharing class AdminSvc {

    //trick here is to use "without sharing" in order to bypass user security for data calculation purposes

    public static List<Account> getClosestAccounts(Id id, String accType) {
        List<Account> accList = new List<Account>();
        List<Account> accAddr = new List<Account>();
        Double lat;
        Double llong;
        accAddr=[select ShippingLatitude, ShippingLongitude from Account where id = :id limit 1];
        lat=accAddr[0].ShippingLatitude;
        llong=accAddr[0].ShippingLongitude;
        Set<String> accountTypes = CustomMetaDataSvc.retrieveCommunityAccountTypes();

        accList = [ select  id, name, Location_Type__c, DISTANCE(ShippingAddress, GEOLOCATION(:lat, :llong), 'mi') dist
                    from    Account
                    where   ShippingLatitude != null
                    and     Type  in :accountTypes
                    and     Accel_VGT_Live_Date__c != null
                    and     id != :id
                    and     Location_Type__c = :accType
                    order by DISTANCE(ShippingAddress, GEOLOCATION(:lat, :llong), 'mi') ASC limit 10];

        return accList;
    }
}