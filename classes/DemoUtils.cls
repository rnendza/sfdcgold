public with sharing class DemoUtils {

    /**
     *
     * @return a Map of Real Account DBA Name ==> Demo Account DBA Name
     */
    public static Map<String,String> getAccountNameMap() {
        Map<String, String> mRealName_DemoName = new Map<String, String>();
        mRealName_DemoName.put('SLOTS OF FUN','Gold Star');
        mRealName_DemoName.put('LATHAM TAP','Fox Bar');
        mRealName_DemoName.put('BIG FOOT BAR & GRILL','Richard\'s Bar');
        mRealName_DemoName.put('GOLDEN GIRLS','Jack\'s Ale House');
        mRealName_DemoName.put('DELIA ITALIA & STUDIO 5','Joe\'s Tavern');
        return mRealName_DemoName;
    }
    /**
     *
     *
     * @param mRealAccount_DemoAccount
     *
     * @return a Map of Real Account Id ==> Demo Account Id
     */
    public static Map<Id,Id> getAccountIdMap(Map<String,String> mRealAccount_DemoAccount) {
        Map<Id,Id> m = new Map<Id,Id>();
        Map<Id,Account> mAccountsByIds = new Map<Id,Account>([  SELECT  Id, Name, Legal_Name__c
                                                                FROM    Account
                                                                WHERE  ( Name in :mRealAccount_DemoAccount.keySet()
                                                                OR      Name in :mRealAccount_DemoAccount.values() )
                                                                AND     Type != 'Prospect Account']);
        if(!mAccountsByIds.isEmpty()) {
            Map<String,Account> mDemo = new Map<String, Account>();
            Map<String,Account> mReal = new Map<String, Account>();
            for (Account account : mAccountsByIds.values()) {
                if (account.Legal_Name__c == 'Portal Dummy Account') {
                    mDemo.put(account.Name, account);
                } else {
                    mReal.put(account.Name, account);
                }
            }
            for(String realName : mReal.keySet()) {
                Account realAccount = mReal.get(realName);
                if(!m.containsKey(realAccount.id)) {
                    for(String demoName : mDemo.keySet()) {
                        for(String realAccountName : mRealAccount_DemoAccount.keySet()) {
                            if(realAccountName == realName) {
                                Account demoAccount  = mDemo.get(mRealAccount_DemoAccount.get(realAccountName));
                                m.put(realAccount.id, demoAccount.id);
                            }
                        }
                    }
                }
            }
        }
        return m;
    }
}