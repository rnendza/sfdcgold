global class AggregateMachineModelMetrics implements Queueable {
    @TestVisible static Time    UNIT_TEST_CURRENT_TIME_OVERRIDE     = System.now().time().addHours(2);

    global void execute(QueueableContext ctx){
        updateModelMetricHpd('Statewide90DAverage');
        updateModelMetricHpd('Statewide90DAveragePrevYear');
    }

    public void updateModelMetricHpd(String type){

        List<Hold_Per_Day__c> newAggregates = new List<Hold_Per_Day__c>();
        List<Hold_Per_Day__c> updateAggregates = new List<Hold_Per_Day__c>();

        List<String> models = new List<String>();
        List<String> locationTypes = new List<String>();
//        Boolean isHpdDarkZone = isHpdDarkZone();

        //values from formula field
        locationTypes.add('Other');
        locationTypes.add('Fraternal/VFW');
        locationTypes.add('Bar');
        locationTypes.add('C-Store');
        locationTypes.add('Gaming parlor');
        locationTypes.add('Restaurant');
        locationTypes.add('Truck Stop');
        locationTypes.add('Grocery Store');

        Date startD ;
        Date endD;

        Date mostRecentHpdDate = CommunityUtils.getMostRecentHpdDate();
        endD = (type == 'Statewide90DAverage') ? mostRecentHpdDate : Date.today().addDays(-366); //  @todo ??
        startD = (type == 'Statewide90DAverage') ? mostRecentHpdDate.addDays(-91) : Date.today().addDays(-456);//  @todo ??

/*       @todo not 100% sure what the logic is meant to do in the below.. interpreting it as.... (minus dark zone stuff):
            (a) end date:  if type = StateWide90DAverage use most recent hpd date otherwise use a date 366 days ago
            (b) start date: if type = StateWide90DAverage use most recent hpd date - 91 days..  otherwise use a date 456 days ago.*/

//        if(isHpdDarkZone){
//            endD = (type == 'Statewide90DAverage' ? Date.today().addDays(-2) : Date.today().addDays(-367));
//            startD = (type == 'Statewide90DAverage' ? Date.today().addDays(-92) : Date.today().addDays(-457));
//        }else{
//            endD = (type == 'Statewide90DAverage' ? Date.today().addDays(-1) : Date.today().addDays(-366));
//            startD = (type == 'Statewide90DAverage' ? Date.today().addDays(-91) : Date.today().addDays(-456));
//        }

        //get models from live locations
        for(AggregateResult machine : [select model__c m from asset where recordtype.name ='VGT' and account.accel_vgt_live_date__c != null and model__c != null and account.type = 'Accel Account' group by model__c]){
            models.add((String)machine.get('m'));
        }
        //get the current hpd model metric dataset
        updateAggregates = [select id, funds_in__c, machine_model__c, machine_location_type__c  from hold_per_day__c where recordtype.name = 'Model Metric' and metric_type__c = :type];

//loop through each location type
        for(String s : locationTypes){
            //for each location type loop through each model and do calcs

            for(AggregateResult ar : [select avg(funds_In__c) fundsIn, asset__r.model__c assetModel from hold_per_day__c where account__r.accel_vgt_live_date__c != null and asset__r.model__c in :models and account__r.Filtered_Location_Type__c = :s  and account__r.type = 'Accel Account' and date__c >= :startD and date__c <= :endD group by asset__r.model__c]){
                //find corresponding hpd record and either update it or send it to be created
                Integer found = 0;
                for(hold_per_day__c h : updateAggregates){
                    if(h.machine_model__c == (String)ar.get('assetModel') && h.machine_location_type__c == s){
                        //found, set int flag to true
                        found = 1;
                        //modify the hpd record average funds in
                        h.funds_in__c = (Decimal)ar.get('fundsIn');
                    }
                }
                if(found == 0){
                    //new hpd record needs to be created for that model at that location type
                    Hold_Per_Day__c newHpd = new Hold_Per_Day__c();
                    newHpd.funds_in__c = (Decimal)ar.get('fundsIn');
                    newHpd.machine_model__c = (String)ar.get('assetModel');
                    newHpd.recordtypeid = SObjectType.Hold_Per_Day__c.getRecordTypeInfosByDeveloperName().get('Model_Metric').getRecordTypeId();
                    newHpd.metric_type__c = type;
                    newHpd.machine_location_type__c = s;
                    newAggregates.add(newHpd);
                }
            }
        }
        if(newAggregates.size()>0){
            try{
                insert newAggregates;
            }catch(DmlException e){
                //hello?
            }
        }
        try{
            update updateAggregates;
        }catch(DmlException e){
            //hello?
        }
    }
//    @TestVisible
//    private static Boolean isHpdDarkZone() {
//        Boolean isHpdDarkZone;
//        if(!Test.isRunningTest()) {
//            isHpdDarkZone = CommunityUtils.isHpdDarkZone(System.now().time());
//        } else {
//            System.debug('==== unit test time='+UNIT_TEST_CURRENT_TIME_OVERRIDE);
//            isHpdDarkZone = CommunityUtils.isHpdDarkZone(UNIT_TEST_CURRENT_TIME_OVERRIDE);
//        }
//        return isHpdDarkZone;
//    }

}