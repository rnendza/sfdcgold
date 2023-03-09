global class AggregateMachineHpd implements Queueable{

    public final static Integer NMB_OF_INSERTS_FOR_SUCCESS = 2200;

    global void execute(QueueableContext ctx){
        //call this class's other functions to get gps updates
        insertNewHpd();
    }
    /*
    public void deleteNewHpd(){
        List<Hold_Per_Day__c> del = new List<Hold_Per_Day__c>();
        del = [select id from Hold_Per_Day__c where recordtypeid = '0121k0000004PfvAAE'];
        try{
            delete del;
        }catch(DMLException e){}
    }
    */
    public void insertNewHpd() {
        Integer totalAggregatesCreated = 0;

        List<AggregateResult> todayMachineRecords;
        List<Hold_Per_Day__c> newAggregates = new List<Hold_Per_Day__c>();



        todayMachineRecords = [
                SELECT
                        Account__c accId,
                        COUNT_DISTINCT(Asset__c) assetCount,
                        SUM(NTI__c) revenueSum,
                        SUM(Funds_In__c) fundsInSum,
                        SUM(Funds_Out__c) fundsOutSum,
                        SUM(Amount_Played__c) amtPlayedSum,
                        SUM(Amount_Won__c) amtWonSum,
                        MAX(Date__c) hpdDate
                FROM Hold_Per_Day__c
                WHERE RecordType.Name = 'Daily HPD'
                and createddate = TODAY
                group by Account__c
        ];

        for (AggregateResult ar : todayMachineRecords) {
            Hold_Per_Day__c newRecord = new Hold_Per_Day__c();
            newRecord.account__c = (Id) ar.get('accId');
            newRecord.vgt_count__c = (Integer) ar.get('assetCount');
            newRecord.NTI__c = (Decimal) ar.get('revenueSum');
            newRecord.Funds_In__c = (Decimal) ar.get('fundsInSum');
            newRecord.Funds_Out__c = (Decimal) ar.get('fundsOutSum');
            newRecord.Amount_Played__c = (Decimal) ar.get('amtPlayedSum');
            newRecord.Amount_Won__c = (Decimal) ar.get('amtWonSum');
            newRecord.Date__c = (Date) ar.get('hpdDate');
            //newRecord.RecordTypeId = '0121k0000004PfvAAE'; //change this when sandbox refreshed to prod value
            newRecord.RecordTypeId = '0121I0000007HPZQA2'; //prod value
            newAggregates.add(newRecord);
        }

        if(newAggregates.size()>0) {
            try {
                insert newAggregates;
                totalAggregatesCreated = newAggregates.size();
            } catch (DMLException e) {
                List<String> emailAddys = new List<String>();
                emailAddys.add('zacharym@accelentertainment.com');
                String emsg = e.getNumDml() + 'x ' + e.getDmlMessage(0) + ' errors.\n' + 'Fields: ' + e.getDmlFieldNames(0);
                EmailSvc.sendEmail(emailAddys, null, 'Daily HPD Aggregates DML Errors', emsg);
                for (integer i = 0; i < e.getNumDML(); i++) {
                    system.debug('***** The error message ' + e.getDMLMessage(i));
                }
            } finally {
                /*
                 * Update the Batch_Settings__c custom setting with the most recent hpd date
                 * and log a msg to the sfdc log object with the result.
                 */
                String className = AggregateMachineHpd.class.getName();
                String logMsg = '';

                try {
                    Date mostRecentHpdDate = updateMostRecentHpdDate(totalAggregatesCreated);
                    logMsg = '~~~SUCCESS~~~ in '+className+' while updating most recent Hpd Date to ' + mostRecentHpdDate;
                    logMsg += '-- number of inserts for success: '+NMB_OF_INSERTS_FOR_SUCCESS;
                    logMsg += '--- total Aggregates created: '+totalAggregatesCreated;
                } catch (Exception ex) {
                    System.debug(LoggingLevel.DEBUG, ex);
                    logMsg = '<<< ERROR >>> in '+className+' upon UPD of Custom Setting holding Most Recent Hpd Date';
                }
                ResponseDto dto = Accel_LoggingUtilsController.logErrorMessage(logMsg, null);
                if(!dto.isSuccess) {
                    System.debug(LoggingLevel.ERROR,dto.technicalMsg);
                }
            }
        }
    }
    /**
     * If we created more then x amount of daily hold per day records. set the date yesterday, otherwise
     * keep it the same. This date is stored in a custom setting and can be retrieved by community
     * queries to decide which HPD Data to pull.
     *
     * @param totalAggregatesCreated  The total daily aggregate hold per days created.
     */
    public Date updateMostRecentHpdDate(Integer totalAggregatesCreated ) {

        Batch_Settings__c batchSettings = Batch_Settings__c.getOrgDefaults();
        Date dYesterday = Date.today().addDays(-1);
        Date mostRecentHpdDate;
        System.debug('>>> batchSettings: '+batchSettings);
        if(batchSettings != null) {
            if ( totalAggregatesCreated > NMB_OF_INSERTS_FOR_SUCCESS ) {
                // note be careful on UT as we won't be inserting this many.. act on UT accordingly.
                mostRecentHpdDate = dYesterday;
                batchSettings.Most_Recent_Hpd_Date__c = mostRecentHpdDate;
                upsert batchSettings;
            } else {
                mostRecentHpdDate = batchSettings.Most_Recent_Hpd_Date__c;
            }
        }
        return mostRecentHpdDate;
    }

    public void insertNewSpecificHpd(String specificDate) {

        Date d = Date.parse(specificDate);

        List<AggregateResult> todayMachineRecords;
        List<Hold_Per_Day__c> newAggregates = new List<Hold_Per_Day__c>();

        todayMachineRecords = [
                SELECT
                        Account__c accId,
                        COUNT_DISTINCT(Asset__c) assetCount,
                        SUM(NTI__c) revenueSum,
                        SUM(Funds_In__c) fundsInSum,
                        SUM(Funds_Out__c) fundsOutSum,
                        SUM(Amount_Played__c) amtPlayedSum,
                        SUM(Amount_Won__c) amtWonSum,
                        MAX(Date__c) hpdDate
                FROM Hold_Per_Day__c
                WHERE RecordType.Name = 'Daily HPD'
                and Date__c = :d
                group by Account__c
        ];

        for (AggregateResult ar : todayMachineRecords) {
            Hold_Per_Day__c newRecord = new Hold_Per_Day__c();
            newRecord.account__c = (Id) ar.get('accId');
            newRecord.vgt_count__c = (Integer) ar.get('assetCount');
            newRecord.NTI__c = (Decimal) ar.get('revenueSum');
            newRecord.Funds_In__c = (Decimal) ar.get('fundsInSum');
            newRecord.Funds_Out__c = (Decimal) ar.get('fundsOutSum');
            newRecord.Amount_Played__c = (Decimal) ar.get('amtPlayedSum');
            newRecord.Amount_Won__c = (Decimal) ar.get('amtWonSum');
            newRecord.Date__c = (Date) ar.get('hpdDate');
            //newRecord.RecordTypeId = '0121k0000004PfvAAE'; //change this when sandbox refreshed to prod value
            newRecord.RecordTypeId = '0121I0000007HPZQA2'; //prod value
            newAggregates.add(newRecord);
        }

        if(newAggregates.size()>0) {
            try {
                insert newAggregates;
            } catch (DMLException e) {
                List<String> emailAddys = new List<String>();
                emailAddys.add('zacharym@accelentertainment.com');
                String emsg = e.getNumDml() + 'x ' + e.getDmlMessage(0) + ' errors.\n' + 'Fields: ' + e.getDmlFieldNames(0);
                EmailSvc.sendEmail(emailAddys, null, 'Daily HPD Aggregates DML Errors', emsg);
                for (integer i = 0; i < e.getNumDML(); i++) {
                    system.debug('***** The error message ' + e.getDMLMessage(i));
                }
            }
        }
    }
}