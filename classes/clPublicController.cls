public without sharing class clPublicController {

    @TestVisible private final static String MAP_KEY_MDT_RECORD = 'MDT_RECORD';
    @TestVisible private final static String MAP_KEY_USER_RECORD = 'USER_RECORD';

    @AuraEnabled(Cacheable=true)
    public Static String getSessionId() {
        Return UserInfo.getSessionId();
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveMdt(String mdtDevName) {
        ResponseDto dto = new ResponseDto();
        Cash_Logistics_Setting__mdt mdt;

        SObject oMdt = CustomMetadataSvc.retrieveCustomMetadata(Cash_Logistics_Setting__mdt.SObjectType,mdtDevName);
        dto.technicalMsg += 'devname passeted='+mdtDevName;
        if(oMdt != null) {
            mdt = (Cash_Logistics_Setting__mdt)oMdt;
        }
        if(mdt != null) {
            dto.isSuccess = true;
        }
        dto.values.put(MAP_KEY_MDT_RECORD,mdt);
        return dto;
    }
//
//    @AuraEnabled
//    public static ResponseDto updateUser(User user) {
//
//        ResponseDto dto = new ResponseDto();
//        String techMsg = 'calling update user with user='+user;
//        try {
//            update user;
//            techMsg += '.. update complete';
//            dto.technicalMsg = techMsg;
//            dto.isSuccess = true;
//            dto.message = 'Successfully updated user';
//            UserSvc.retrieveUser(user.Id);
//            dto.values.put(MAP_KEY_USER_RECORD,user);
//        } catch (Exception e) {
//            System.debug(LoggingLevel.ERROR,e);
//            dto.message = e.getMessage();
//            dto.technicalMsg = techMsg + 'error on update ' + e.getCause() + ' ' + e.getMessage() + ' ' + e.getStackTraceString();
//        }
//        return dto;
//    }

}