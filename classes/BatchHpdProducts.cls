global class BatchHpdProducts implements Database.Batchable<Sobject>, Database.Stateful {

    Map<String,Product2> mModelName_Product = new Map<String,Product2>();
    Map<String,Set<Id>> mModelName_SetLocId = new Map<String,Set<Id>>();

    global String formattedLocalStartTimeString;
    global String formattedLocalEndTimeString;
    global Integer numHpdsProcessed = 0;
    global Integer numDifferentLocations = 0;

    global Integer numDaysToProcess = 30;
    global Date    hpdStartDate;
    global Date    hpdEndDate;

    public final static String HPD_PRODUCT_AGGREGATION_DEVNAME                 = 'HPD_Product_Aggregation';

    /**
     * Get the subset of products we want to work with (ie. asset_model_name__c != null)
     * Zero out any existing values  (since we are running this every day) and throw this in a map of Asset Model Name ==> Product2
     */
    global BatchHpdProducts(Integer iNumDaysToProcess) {
        if(iNumDaysToProcess != 0 && iNumDaysToProcess != null) {
            numDaysToProcess = iNumDaysToProcess;
        }
        List<Product2> products = [
                SELECT  ID, asset_model_name__c,name,
                        Thirty_Day_Location_Share_Total__c,Thirty_Day_Location_Share_Avg__c,
                        Thirty_Day_Revenue_Total__c,Thirty_Day_Revenue_Avg__c
                FROM    Product2
                WHERE   asset_model_name__c != null
        ];
        for(Product2 product : products) {
            product.Thirty_Day_Location_Share_total__c  = 0;
            product.Thirty_Day_Location_Share_Avg__c = 0;
            product.Thirty_Day_Revenue_total__c  = 0;
            product.Thirty_Day_Revenue_Avg__c = 0;
            mModelName_Product.put(product.asset_model_name__c, product);
            mModelName_SetLocId.put(product.asset_model_name__c,new Set<Id>());
        }
    }

    /**
     *
     * Run main HPD Daily Query with start date being today - numDayToProcess.
     *
     * @param bc
     * @return query locator.
     */
    global database.querylocator start(Database.BatchableContext bc) {
        formattedLocalStartTimeString = DateTime.now().format();
        hpdEndDate = System.today();
        hpdStartDate = System.today().addDays(- numDaysToProcess);

        return Database.getQueryLocator([
                SELECT  Id, Location_Share__c,Net_Revenue__c,
                        asset__r.model__c, account__c
                FROM    Hold_Per_Day__c
                WHERE   RecordType.Name = 'Daily HPD'
                and     Date__c <= :hpdEndDate
                and     Date__c >= :hpdStartDate
        ]);
    }
    /**
     * Take results of the start method and roll through them / aggregating them.
     *
     * @param bc
     * @param scope
     */
    global void execute(Database.BatchableContext bc, List<Hold_Per_Day__c> scope) {
        if (!scope.isEmpty()) {
            for (Hold_Per_Day__c hpd : scope) {
                //if no asset for whatever reason.. (bad data?) skip it.
                if(hpd.asset__c == null) {
                    continue;
                }
                String modelName = hpd.asset__r.model__c;
                //--- if the asset associated with the hpd has a model name = product2.asset_model_name..
                if (modelName != null && hpd.Location_Share__c != null) {
                    if(mModelName_Product.containsKey(modelName)) {
                        Product2 p = mModelName_Product.get(modelName);
                        if(p!= null) {
                            numHpdsProcessed ++;
                            p.Thirty_Day_Location_Share_Total__c += hpd.location_share__c;
                            p.Thirty_Day_Revenue_Total__c += hpd.net_revenue__c;
                        }
                        //--- build a map of model name to all the associated locations (set is unique by def)
                        if(!mModelName_SetLocId.containsKey(modelName)) {
                            mModelName_SetLocId.put(modelName, new Set<Id>{hpd.account__c});
                        } else {
                            Set<Id> locIds = mModelName_SetLocId.get(modelName);
                            locIds.add(hpd.account__c);
                        }
                    }
                }
            }
        }
    }
    /**
     * I
     *
     * @param bc
     */
    global void finish(Database.BatchableContext bc) {
        List<Product2> productsToUpdate = new List<Product2>();
        Set<Id> allLocIds = new Set<Id>();
        for(String modelName : mModelName_Product.keySet()) {
            Product2 p2 = (Product2)mModelName_Product.get(modelName);
            Set<Id> locIds = (Set<Id>)mModelName_SetLocId.get(modelName);
            allLocIds.addAll(locIds);
            Integer iNumLocations = locIds.size();
            if( iNumLocations != null && iNumLocations != 0 ) {
                Decimal locShareAvg = (p2.Thirty_Day_Location_Share_Total__c / iNumLocations) / numDaysToProcess;
                if(locShareAvg != null) {
                    locShareAvg = locShareAvg.setScale(2,RoundingMode.HALF_UP);
                }
                Decimal revAvg = (p2.Thirty_Day_Revenue_Total__c / iNumLocations) / numDaysToProcess;
                if(revAvg != null) {
                    revAvg = revAvg.setScale(2,RoundingMode.HALF_UP);
                }
                p2.Thirty_Day_Location_Share_Avg__c = locShareAvg;
                p2.Thirty_Day_Revenue_Avg__c = revAvg;
                productsToUpdate.add(p2);
            }
        }
        numDifferentLocations = allLocIds.size();
        update productsToUpdate;
        List<String> emailAddys = EmailSvc.getHpdEmailNotificationAddys(HPD_PRODUCT_AGGREGATION_DEVNAME);
        String subject = 'Accel SFDC Batch Product HPD Aggregation Automation process complete! ';
        String body = buildEmailContent(productsToUpdate);
        EmailSvc.sendEmail(emailAddys,subject,body);
    }
    /**
     * Just build a simple adhoc email to send the results to admins.
     *
     * @param productsUpdated  the products that were updated in this batch job.
     * @return the body content of the email (html content).
     */
    @testvisible
    private String buildEmailContent(List<Product2> productsUpdated) {
        String msg = '';
        formattedLocalEndTimeString = DateTime.now().format();
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        HPD_Total_Setting__mdt hpdTotalSetting = CustomMetadataSvc.retrieveHpdTotalSettingsMeta(HPD_PRODUCT_AGGREGATION_DEVNAME);
        String metaDataTypeUrl = baseUrl + '/lightning/setup/CustomMetadata/page?address=%2F'+hpdTotalSetting.Id;
        msg += '<br/>If you are receiving this email,it is because your email address was added to the Custom Metadata type: ';
        msg +=  '<a href="'+metaDataTypeUrl+'">HPD_Product_Aggregation</a> as a valid address to receive debug emails for this job. You may remove your email from this list via clicking the previous link.';
        msg +=  '<br/><br/>To run this job again simply execute the following anon apex script. BatchHpdProducts b = new BatchHpdProducts(30);Database.executeBatch(b,2000)</br>';
        msg +=  '<br/>Or modify the scheduled Job (ScheduleBatchHpdProducts)<br/>';
        msg += '<br/>Batch Apex Class: <b>BatchHpdProducts</b>';
        msg += '<br/>Org Base URL:<b>' +baseUrl + '</b><br/>';
        msg += '<br/>Start Time:<b> ' + formattedLocalStartTimeString + '</b>';
        msg += '<br/>End Time:<b> ' + formattedLocalEndTimeString + '</b>';
        msg += '<br/></br><b>Pseudo:</b><br/>';
        msg += '<ul>';
        msg += '<li>SELECT the location_share__c and net_revenue__c for  last 30 days (from today) of daily hpd records</li>';
        msg += '<li>SUM both values up on the product2 object</li>';
        msg += '<li>After aggregation is complete... take (P2.thiry_day_location_share_total / Total Num Diff Locations) / Day Processed. [ie 30] to get the avg. </li>';
        msg += '<li>Send this debug email to addresses listed in the customer meta data setting above.</li>';
        msg += '</ul>';
        msg += '<br/>Num Days Processed:<b>'+numDaysToProcess+'</b>';
        msg += '<br/>HPD Start Date:<b>'+hpdStartDate+'</b>';
        msg += '<br/>HPD End Date:<b>'+hpdEndDate+'</b>';
        msg += '</br><br/># of HPD Daily Recs Processed:<b> ' + numHpdsProcessed + '</b>';
        msg += '</br><br/># of different locations:<b> ' + numDifferentLocations + '</b>';
        msg += '<br/># of Products updated:<b> ' + productsUpdated.size() + '</b>';

        //---- just build an adhoc html table. messy style wise but gets the job done.
        String nbrDataColStyle = 'border:1px solid silver;text-align: right;';
        String hdrStyle='padding:2';

        msg += '<br/><br/><b> == Updated Product Values == </b><br/><br/>';
        msg += '<table style="border 1px solid black" padding="1">';
        msg += '<tr style="background-color:silver">';
        msg +='<th style="'+hdrStyle+'">Asset Model Name</th><th style="'+hdrStyle+'">'+numDaysToProcess+' Day Loc Share Total</th><th style="'+hdrStyle+'">'+numDaysToProcess+' Day Loc Share Avg</th>';
        msg +='<th style="'+hdrStyle+'">'+numDaysToProcess+' Day Rev Total</th><th style="'+hdrStyle+'">'+numDaysToProcess+' Day Rev Avg</th><th>Product</th>';
        msg += '</tr>';
        for(Product2 p2 :  productsUpdated) {
            msg+='<tr>';
            msg+='<td style="border:1px solid silver">'+p2.Asset_Model_Name__c+'</td>';
            msg+='<td style="'+nbrDataColStyle+'">'+'$'+String.valueOf(p2.Thirty_Day_Location_Share_Total__c.format())+'</td>';
            msg+='<td style="'+nbrDataColStyle+'">'+'$'+String.valueOf(p2.Thirty_Day_Location_Share_Avg__c.format())+'</td>';
            msg+='<td style="'+nbrDataColStyle+'">'+'$'+String.valueOf(p2.Thirty_Day_Revenue_Total__c.format())+'</td>';
            msg+='<td style="'+nbrDataColStyle+'">'+'$'+String.valueOf(p2.Thirty_Day_Revenue_Avg__c.format())+'</td>';
            msg+='<td style="border:1px solid silver"><a href="'+baseUrl+'/'+p2.Id+'">'+p2.Name+'</a></td>';
            msg+='</tr>';
        }
        msg +='</table>';
        return msg;
    }
}