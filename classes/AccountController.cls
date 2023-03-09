/**
 *
 */
public class AccountController {

    public static final String MAP_KEY_HPD_LIST = 'LOCATION_HPDS';
    public static final String MAP_KEY_HPD_ACCOUNT_SETTINGS = 'MAP_KEY_HPD_ACCOUNT_SETTINGS';

    @AuraEnabled
    public static ResponseDto retrieveHpdAccountSettings() {
        ResponseDto dto = new ResponseDto();
        dto.values.put(MAP_KEY_HPD_ACCOUNT_SETTINGS, CustomMetadataSvc.retrieveCustomSearchMeta(HPD_Total_Setting__mdt.getSObjectType(), 'HPD_Account_Display'));
        dto.isSuccess = true;
        return dto;
    }
    /**
     *
     * @param accountId
     * @return Dto with list of Hold Per Days and Single sObject of Hold Per Day Total
     */
    @AuraEnabled
    public static ResponseDto retrieveHpds(Id accountId) {
        ResponseDto dto = new ResponseDto();
        List<Hold_Per_Day__c> hpds = AccountSvc.retrieveAccountHpd(accountId);
        Hold_Per_Day_Total__c holdPerDayTotal = AccountSvc.retrieveAccountHpdTotal(accountId);
        if (!hpds.isEmpty()) {
            dto.isSuccess = true;
            dto.values.put(MAP_KEY_HPD_LIST, hpds);
        } else {
            dto.isSuccess = false;
            dto.severity = 'warning';
            dto.message = 'no hpds found';
        }
        dto.sObj = holdPerDayTotal; //fail silently.

        return dto;
    }
}