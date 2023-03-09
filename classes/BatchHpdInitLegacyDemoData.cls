/**

*/
global class BatchHpdInitLegacyDemoData implements Database.Batchable<Sobject>, Database.Stateful {

    global HPD_Total_Setting__mdt hpdTotalSetting;
    global Integer iNumHpdsInserted = 0;
    global Integer iNumHpdsProcessed = 0;
    global Integer iNumHpdsCloned = 0;
    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    Map<Id,Id> mRealAccountId_DemoAccountId;
    Map<String,String> mRealAccountName_DemoAccountName;
    Boolean rollItBack = false;
    Boolean incremental = false;
    List<String> dbErrors = new List<String>();
    List<String> exMessages = new List<String>();


    global BatchHpdInitLegacyDemoData(Boolean bRollItBack,Boolean bIncremental) {
        this.rollItBack = bRollItBack;
        formattedLocalStartTimeString = DateTime.now().format();
        mRealAccountName_DemoAccountName = DemoUtils.getAccountNameMap();
        mRealAccountId_DemoAccountId = DemoUtils.getAccountIdMap(mRealAccountName_DemoAccountName);
        this.incremental = bIncremental;
    }
    /**
     *
     *
     * @param bc
     *
     * @return
     */
    global database.querylocator start(Database.BatchableContext bc) {
        hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HpdSvc.ASSET_AGGREGATION_DEVNAME);
        if(incremental) {
            return Database.getQueryLocator([
                    SELECT  Account__c,Amount_Played__c,Amount_Won__c,Asset__c,Current_Credits__c,Date__c,
                            Day_of_Week__c,Funds_In__c,Funds_Out__c,HPD__c,
                            Municipality_Share__c,Net_Wager__c,
                            NTI_Tax_Rate_30__c,NTI__c,Portal_Dummy_Account__c,Position__c,
                            RecordTypeId,State_Share__c,VGT_Count__c
                    FROM    Hold_Per_Day__c
                    WHERE   Account__c in :mRealAccountId_DemoAccountId.keySet()
                    AND      ( CreatedDate = TODAY
                    // https://accel-entertainment.monday.com/boards/286658657/pulses/311204127
                    OR       ( CreatedDate = YESTERDAY AND RecordType.DeveloperName = 'Monthly_HPD' ))
            ]);
        } else {
            return Database.getQueryLocator([
                    SELECT Account__c,Amount_Played__c,Amount_Won__c,Asset__c,Current_Credits__c,Date__c,
                            Day_of_Week__c,Funds_In__c,Funds_Out__c,HPD__c,
                            Municipality_Share__c,Net_Wager__c,
                            NTI_Tax_Rate_30__c,NTI__c,Portal_Dummy_Account__c,Position__c,
                            RecordTypeId,State_Share__c,VGT_Count__c
                    FROM Hold_Per_Day__c
                    WHERE Account__c in :mRealAccountId_DemoAccountId.keySet()
            ]);
        }
    }

    global void execute(Database.BatchableContext bc, List<Hold_Per_Day__c> hpds) {

        List<Hold_Per_Day__c> holdPerDaysToIns = new List<Hold_Per_Day__c>();
        iNumHpdsProcessed = iNumHpdsProcessed += hpds.size();
        if(!hpds.isEmpty()) {
            try {
                for (Hold_Per_Day__c hpd : hpds) {
                    Hold_Per_Day__c hpdToIns = hpd.clone(false);
                    hpdToIns.Account__c = mRealAccountId_DemoAccountId.get(hpdToIns.Account__c);
                    hpdToIns.Portal_Dummy_Account__c = true;
                    hpdToIns.Amount_Played__c += 1;
                    hpdToIns.Amount_Won__c += 1;
                    hpdToIns.Funds_In__c += 1;
                    hpdToIns.Funds_Out__c += 1;
                    if(hpdToIns.Current_Credits__c != null) {
                        hpdToIns.Current_Credits__c += 1;
                    }
                    if(hpdToIns.Municipality_Share__c != null) {
                        hpdToIns.Municipality_Share__c += 1;
                    }
                    if(hpdToIns.Net_Wager__c != null) {
                        hpdToIns.Net_Wager__c += 1;
                    }
                    if(hpdToIns.NTI__c != null) {
                        hpdToIns.NTI__c += 1;
                    }
                    if(hpdToIns.State_Share__c != null) {
                        hpdToIns.State_Share__c += 1;
                    }
                    iNumHpdsCloned++;
                    holdPerDaysToIns.add(hpdToIns);
                }
            } catch (Exception e) {
                exMessages.add(e.getMessage() + '..'+ e.getCause() + '..'+e.getLineNumber());
            }
            Savepoint sp = Database.setSavepoint();
            Database.SaveResult[] srList = Database.insert(holdPerDaysToIns, true);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    iNumHpdsInserted++;
                } else {
                    for (Database.Error err : sr.getErrors()) {
                        dbErrors.add(err.message);
                        System.debug('The following error has occurred.');
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('HPD fields that affected this error: ' + err.getFields());
                    }
                }
            }
            if(rollItBack) {
                Database.rollback(sp);
            }
        }
    }

    global void finish(Database.BatchableContext bc) {
        formattedLocalEndTimeString = DateTime.now().format();
        String name = '';

        if(!incremental) {
            name = 'Accel SFDC Batch HPD Demo Legacy Data Init Automation process complete! ';
        } else {
            name = 'Accel Incrmental HPD Demo Data Refreshed Automation process complete! ';
        }
        String subject = name;
        String msg = '<br/>If you are receiving this email,it is because your email address was added to the HPD_Total_Setting__mdt as a valid address to receive debug emails for this job.<br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b><br/>';
        msg += '</br><br/>rollitBack set to :<b> ' + rollItBack + '</b>';
        if(!incremental) {
            msg += '</br><br/><b>NOTE: </b> Set batch size to 12 otherwise the lame process builders will blow up!';
        }
        msg += '</br><br/><b>NOTE: </b> New Hold_Per_Day__c records created flagged as Hold_Per_Day__c.Portal_Demo_Account__c = true';
        msg += '</br><br/><b>NOTE: </b> +1 added to all non null dollar amts';
        msg += '</br><br/># of Real HPD Records Processed:<b> ' + iNumHpdsProcessed + '</b>';
        msg += '</br><br/># of Real HPD Records Cloned:<b> ' + iNumHpdsCloned + '</b>';
        msg += '<br/># of Demo HPD Records Created:<b> ' + iNumHpdsInserted + '</b></br>';
        if(!dbErrors.isEmpty()) {
            msg += '<br/># DATABASE ERRORS OCCURRED:</br>';
            for(String dbError : dbErrors) {
                msg += '<br/>DbErrors = '+dbError;
            }
        }
        if(!exMessages.isEmpty()) {
            msg += '<br/># EXCEPTIONS OCCURRED:</br>';
            for(String exMsg : exMessages) {
                msg += '<br/>ex msg = '+exMsg;
            }
        }
        msg += '<br/><br/><b>Mapping of Accounts:</b><br/>';
        for(String realName : mRealAccountName_DemoAccountName.keySet()) {
            String demoName = mRealAccountName_DemoAccountName.get(realName);
            msg+= 'Real Account DBA Name: '+realName + '.......... Demo Account Dba Name: ' + demoName + '<br/>';
        }
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HpdSvc.ASSET_AGGREGATION_DEVNAME);
        //List<String> emailAddys = new List<String>{'rick@chicagosalesforceconsulting.com'};
        String body = msg;
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
}