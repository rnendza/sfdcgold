public class ApiSvc {

    public static API_Setting__mdt retrieveApiSetting(String mdtDevName) {
        API_Setting__mdt mdt;
        SObject oSetting = CustomMetadataSvc.retrieveCustomMetadata(API_Setting__mdt.getSObjectType(),mdtDevName);
        if(oSetting != null) {
            mdt = (Api_Setting__mdt)oSetting;
        }
        return mdt;
    }
}