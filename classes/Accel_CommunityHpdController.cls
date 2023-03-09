public with sharing class Accel_CommunityHpdController {

    public static final String MAP_KEY_HPD_LIST         = 'HPD_LIST';
    public static final String MAP_KEY_ACCOUNT_LIST     = 'ACCOUNT_LIST';

    @AuraEnabled
    public static ResponseDto retrieveAccounts() {
        ResponseDto dto = new ResponseDto();
        HPD_Total_Setting__mdt hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ACCT_AGGREGATION_DEVNAME);
        List<String> accountTypes = hpdTotalSetting.HPD_Account_Types__c.split(',');
        List<Account> accounts =  [select   id,Name,ShippingCity
                                    from    account
                                    where  type in :accountTypes
                                    order  by name ASC
                                    limit 500];
        dto.isSuccess = true;
        dto.values.put(MAP_KEY_ACCOUNT_LIST,accounts);
        return dto;
    }

    /**
     *
     *
     * @param accountIds
     *
     * @return DTO  with the HPD List.
     */
    @AuraEnabled
    public static ResponseDto retrieveAccountHpds(Id accountId) {
        Integer iLimitRows = 2000;
        List<Hold_Per_Day__c> hpds = new List<Hold_Per_Day__c>();
        ResponseDto dto = new ResponseDto();
        try {
            hpds = [SELECT  id, account__c,Position__c,
                            Date__c,NTI__c,Funds_In__c,Location_Share__c
                    FROM    Hold_Per_Day__c
                    WHERE   account__c = :accountId
                    and     RecordType.Name = 'Daily HPD'
                    ORDER BY Date__c DESC
                    LIMIT   :iLimitRows ];
            dto.isSuccess = true;
        } catch (Exception e) {
            dto.severity = 'error';
            dto.message = e.getMessage();
            dto.technicalMsg = e.getStackTraceString();
        }
        dto.values.put(MAP_KEY_HPD_LIST, hpds);
        return dto;
    }
}