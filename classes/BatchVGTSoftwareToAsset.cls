global class BatchVGTSoftwareToAsset implements Database.Batchable <SObject>,
                                                Database.Stateful {

//    global Boolean commitTrans = false;
//    private List<String> recipientEmailAddys = new List<String>();
//    global String formattedLocalStartTimeString;
//    global String formattedLocalEndTimeString;
//
    global final static String  VGT_RT_DEV_NAME     = 'VGT';
//    global final static String  SOFTWARE_DEV_NAME   = 'Software';
//    global final static Id      SW_RT_ID            = Schema.SObjectType.Asset.getRecordTypeInfosByName()
//                                                        .get(SOFTWARE_DEV_NAME).getRecordTypeId();
//
//    global Integer totalSwAssetsCreated = 0;
//    private List<Exception>  exceptions = new List<Exception>();
//    private Integer batchSize;
//    private Integer totalBatchesRun = 0;
//    private List<Asset> first200AssetsCreated = new List<Asset>();


    global BatchVGTSoftwareToAsset( List<String> recipientEmailAddys, Boolean commitTrans) {
//        this.commitTrans = commitTrans;
//        if(recipientEmailAddys != null) {
//            this.recipientEmailAddys = recipientEmailAddys;
//        }
    }

    global database.QueryLocator start(Database.BatchableContext bc) {


//        formattedLocalStartTimeString= Datetime.now().format();
        return Database.getQueryLocator([
                SELECT  Id, Name, ParentId, AccountId, RecordTypeId,Software__c,Software_Upgraded_Date__c,Status
                FROM    Asset
                WHERE   RecordType.DeveloperName = :VGT_RT_DEV_NAME
        ]);
    }

    global void execute(Database.BatchableContext bc, List<Asset> scope) {

//        totalBatchesRun ++;
//        List<Asset> swAssetsToCreate = new List<Asset>();
//        if (batchSize == null || scope.size() > batchSize) batchSize = scope.size();
//
//        for(Asset asset : scope) {
//            Asset swAsset = new Asset(RecordTypeId = SW_RT_ID);
//            swAsset.Name = asset.Software__c;
//            swAsset.ParentId = asset.Id;
//            swAsset.AccountId = asset.AccountId;
//            swAsset.Created_by_VGT_Software_Transfer__c = true;
//            swAsset.Status = 'Allocated';
//            swAsset.Software_Upgraded_Date__c = asset.Software_Upgraded_Date__c;
//            swAssetsToCreate.add(swAsset);
//        }
//        try {
//            Savepoint sp = Database.setSavepoint();
//            insert swAssetsToCreate;
//            totalSwAssetsCreated += swAssetsToCreate.size();
//            List<Asset> assetsCreated = [
//                    SELECT Id, Name, AccountId, Account.Name, ParentId, Parent.Name, SerialNumber,CreatedDate,
//                            CreatedBy.Username, RecordType.DeveloperName, Created_by_VGT_Software_Transfer__c,
//                            RecordType.Name,Software_Upgraded_Date__c,Status
//                    FROM   Asset
//                    WHERE  Id IN :swAssetsToCreate
//                    ORDER  BY CreatedDate ASC
//            ];
//            Integer iNumAssetsStored = first200AssetsCreated.size();
//            if(iNumAssetsStored < 201) {
//                first200AssetsCreated.addAll(assetsCreated);
//            }
//            if(!commitTrans) {
//                Database.rollback(sp);
//            }
//        } catch (Exception e) {
//            System.debug(LoggingLevel.ERROR, e);
//            exceptions.add(e); //  @todo log to Accel_error_Log__c
//        }
    }

    global void finish(Database.BatchableContext bc) {
//        formattedLocalEndTimeString= Datetime.now().format();
//        String owaEmailAddy = 'crm@accelentertainment.com';
//        if(recipientEmailAddys == null || recipientEmailAddys.isEmpty()) {
//            recipientEmailAddys = new List<String> {'rick@chicagosalesforceconsulting.com'};
//        }
//        String subject = 'Accel SFDC Batch Asset - VGT Software to new VGT Asset Automation process complete! ';
//        String body = buildEmailContent();
//        EmailSvc.sendEmail(recipientEmailAddys,null,subject,body,null,owaEmailAddy);
    }

//    @TestVisible
//    private String buildEmailContent() {
//        String msg = '';
//        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
//        msg += '<br/>If you are receiving this email, it is because your email address was added to view the results of this batch job<br/><br/>';
//        if(commitTrans) {
//            msg += '<span style="color:green"><b> ** Transaction was committed! ** </b></span><br/>';
//        } else  {
//            msg += '<span style="color:red"><b>NOTE!  Transaction was intentionally rolled back due to a user supplied parameter.</b>&nbsp;&nbsp;</span><br/>';
//            msg += '<span>The results would have been the following if the transaction was committed:</span>';
//        }
//        msg += '<br/><br/><b>Overall Stats:</b><br/>';
//        msg += '<br/><b>Total # of New Assets Created: ' +totalSwAssetsCreated + '</b>';
//        msg += '<br/>Batch Apex Class: <b>BatchVGTSoftwareToAsset</b>';
//        msg += '<br/>Batch Size: <b>' +batchSize + '</b>';
//        msg += '<br/>Number of Batches Executed  <b>' +totalBatchesRun + '</b>';
//        msg += '<br>Recipient Email Addresses: <b>'+recipientEmailAddys+'</b>';
//        msg += '<br>Commit: <b>'+commitTrans+'</b>';
//        msg += '<br/>Org Base URL: <b>' +baseUrl + '</b>';
//        msg += '<br/>Start Time: <b> ' + formattedLocalStartTimeString + '</b>';
//        msg += '<br/>End Time: <b> ' + formattedLocalEndTimeString + '</b>';
//        msg += '<br/><hr>';
//
//        msg += '<br/><br/><b>Pseudo:</b><br/>';
//        msg += '<ul>';
//        msg += '<li>Mod automation on Asset (Asset Trigger / BEFORE Insert) to auto gen serial numbers for all software assets (not only those linked to an Inventory Request.</li>';
//        msg += '<li>Created Asset.Created_by_VGT_Software_Transfer__c. Visible only to SA. Specifically to track the success of this process.</li>';
//        msg += '<li>In the Start method of the Batch. SELECT All VGT Assets with Software__c populated.</li>';
//        msg += '<li>In the Execute method of the Batch create new Software Assets with their Asset.ParentId = #3.</li>';
//        msg += '<li>In the Finish method send out an email with results.</li>';
//        msg += '<li>Use a toggle of commitTrans so we dont polute Asset with bad data on potentially failed tests</li>';
//        msg += '</ul>';
////
//        //---- just build an adhoc html table. messy style wise but gets the job done.
//        String nbrDataColStyle = 'border:1px solid silver;text-align: right;';
//        String textDataColStyle = 'border:1px solid silver;text-align: left;';
//        String hdrStyle='padding:2';
//
//        if(!commitTrans) {
//            msg += '<br/><br/>';
//            msg +=' <span style="color:red"> ** Note **  the below data does not exist in the target org as it was rolled back. HERE is example of what would exist on a commit!!!</span>';
//        }
//
//        msg += '<br/><br/><b> == Newly Created Assets (only a sample of the first 200) == </b><br/><br/>';
//        msg += '<table style="border 1px solid black" padding="1">';
//        msg += '<tr style="background-color:silver">';
//        msg +='<th style="'+hdrStyle+'">Asset Name</th>';
//        msg += '<th style="'+hdrStyle+'">Parent Asset Name</th>';
//        msg += '<th style="'+hdrStyle+'">Account Name</th>';
//        msg += ' <th style="'+hdrStyle+'">Serial #</th>';
//        msg += ' <th style="'+hdrStyle+'">RecordType</th>';
//        msg += ' <th style="'+hdrStyle+'">Status</th>';
//        msg += ' <th style="'+hdrStyle+'">Software Updated Date</th>';
//        msg += ' <th style="'+hdrStyle+'">Created_by_VGT_Software_Transfer__c</th>';
//        msg += ' <th style="'+hdrStyle+'">CreatedBy</th>';
//        msg += ' <th style="'+hdrStyle+'">CreatedDate</th>';
//        msg += '</tr>';
//        for(Asset  a: first200AssetsCreated) {
//            msg+='<tr>';
//            msg+='<td style="'+textDataColStyle + '"> <a href="'+baseUrl+'/'+a.Id+'">' + a.Name+'</a> </td>';
//            msg+='<td style="'+textDataColStyle + '">  <a href="'+baseUrl+'/'+a.ParentId+'">' + a.Parent.Name+'</a> </td>';
//            msg+='<td style="'+textDataColStyle + '">  <a href="'+baseUrl+'/'+a.AccountId+'">' + a.Account.Name+'</a> </td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.SerialNumber+'</td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.RecordType.Name+'</td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.Status+'</td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.Software_Upgraded_Date__c+'</td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.Created_by_VGT_Software_Transfer__c+'</td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.Createdby.username+'</td>';
//            msg+='<td style="'+textDataColStyle + '">'+a.CreatedDate+'</td>';
//            msg+='</tr>';
//        }
//        msg +='</table>';
//        msg +=  '<br/><br/><br/>To run this job again simply execute the following anon apex script.<br/><br/>BatchVGTSoftwareToAsset b = new BatchVGTSoftwareToAsset(new List<String> {\'youremailaddy\'});Database.executeBatch(b,200)</br><br>';
//
//        return msg;
//    }
}