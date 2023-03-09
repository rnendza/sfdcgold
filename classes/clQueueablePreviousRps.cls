/**
 * Queueable class to set Route_processing_Sheet__c.Previous_RT_Collection__c and
 * Route_Processing_Sheet__c.Previous_VGT_Collection__c fields for the RPS records passed.
 */
public class clQueueablePreviousRps implements Queueable{

    public final static  Set<String> COLLECTION_TYPES_VGT =
            new Set<String>{
                    'Regular - RT & VGT',
                    'Additional Fill – VGT Only',
                    'Additional Fill – RT & VGT',
                    'Regular - VGT Only' // 9/22/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
            };

    public static Set<String> COLLECTION_TYPES_RT =
            new Set<String>{
                    'Regular - RT & VGT',
                    'Additional Fill – RT Only',
                    'Additional Fill – RT & VGT',
                    'Regular - RT Only (Go Lives/RT swaps)' // 9/22/2022 https://accel-entertainment.monday.com/boards/1300348967/pulses/3181062708
            };


    //  The rps records in context.
    Map<Id,Route_Processing_Sheet__c> mRps;

    /**
     * FOR FUTURE USE..
     * @param newRps a single new Route_Processing_Sheet__c sObject (Id Required)
     */
    public clQueueablePreviousRps( Route_Processing_Sheet__c newRps) {
        this.mRps = new Map<Id,Route_Processing_Sheet__c>{ newRps.Id => newRps };
        System.debug(LoggingLevel.info,'--> prevrps single rps const: rps recs: '+this.mRps);
    }

    /**
     * @param mNewRps a map for Route_Processing_Sheet__c.Id => Route_Processing_Sheet__c
     */
    public clQueueablePreviousRps(Map<Id,Route_Processing_Sheet__c> mNewRps) {
        this.mRps = mNewRps;
        System.debug(LoggingLevel.info,'--> prevrps const: rps recs: '+this.mRps);
    }

    /**
     * Delegate the call to performExecute for more testing options.
     * @param ctx  The QueueableContext
     */
    public void execute(QueueableContext ctx) {
        this.performExecute();
        System.debug(LoggingLevel.info,'--> prevrps execute');
    }

    /**
     * Custom inner class to seperate out collection type ids.
     */
    public class PreviousCollectionType {
        public Id prevRtId;
        public Id prevVgtId;

        public PreviousCollectionType(Route_Processing_Sheet__c rps) {

            if(COLLECTION_TYPES_VGT.contains(rps.Collection_Type__c)) {
                this.prevVgtId = rps.Id;
            }
            If(COLLECTION_TYPES_RT.contains(rps.Collection_Type__c)) {
                this.prevRtId = rps.Id;
            }
            System.debug(LoggingLevel.info,'--> prevrps inner PreviousCollectionType constr: '+this);
        }
    }

    /**
     *  Find all route processing sheets associated with all unique account ids in context.
     *  Take the most recent one (excluding the one in ctx) and use that to update prev fields.
     */
    public void performExecute() {

        Map<Id,Id> mNewAccountId_RpsId = new Map<Id,Id>();
        Map<Id,PreviousCollectionType> mUpdateRpsId_prevRps = new Map<Id,PreviousCollectionType>();

        //  Get all new Account Ids are that fired from the Trigger
        for(Route_Processing_Sheet__c rpsNew : mRps.values()) {
            mNewAccountId_RpsId.put(rpsNew.Account__c,rpsNew.Id);
        }
        System.debug('---> prevrps cl macctid_rpsid='+mNewAccountId_RpsId);

        //  Find all the rps records for the account ids in context
        Map<Id,List<Route_Processing_Sheet__c>> mAllAccountRpss = findAllRps(mNewAccountId_RpsId.keySet());
        System.debug(LoggingLevel.info,'--> allAccountRps: '+mAllAccountRpss);

        if(!mAllAccountRpss.isEmpty()) {

            //  Roll through the full superset of rps records for each account.
            for (Id acctId : mAllAccountRpss.keySet()) {

                //  Grabs only the rps records for the current account.
                List<Route_Processing_Sheet__c> acctRpss = mAllAccountRpss.get(acctId);
                Integer i = 0;
                Integer totalAcctRps = acctRpss.size();

                //  If there are 2 rps records for the account use the next one in the list (order by in soql )
                if(acctId == '0011I00000Ux7K7QAJ') {
                    System.debug('using oswego');
                    System.debug('total acct rps:'+totalAcctRps);
                }

                for(Route_Processing_Sheet__c newestRps : acctRpss) {
                    if(i < totalAcctRps - 1) {
                        Route_Processing_Sheet__c prevRps = acctRpss[i+1];
                        if(acctId == '0011I00000Ux7K7QAJ') {
                            System.debug('Oswego prev account rps used:'+prevRps);
                        }
                        PreviousCollectionType pct = new PreviousCollectionType(prevRps);
                        if(acctId == '0011I00000Ux7K7QAJ') {
                            System.debug('Oswego put newest rps id key='+newestRps.Id + ' pct=' + pct + ' in map');
                        }
                        mUpdateRpsId_prevRps.put(newestRps.Id, pct);
                    }
                    i++;
                }
            }
            System.debug(LoggingLevel.info,'--> prevrps mUpdateRpsId_prevRps: '+mUpdateRpsId_prevRps);
            //  We are not sure the caller will provide us with the fields that need updating so
            //  requery the rps recs in ctx.
            List<Route_Processing_Sheet__c> routeProcessingSheets = [
                    SELECT Id,Previous_RT_Collection__c,Previous_VGT_Collection__c
                    FROM Route_Processing_Sheet__c
                    WHERE Id IN :mRps.keySet()
            ];
            System.debug(LoggingLevel.info,'--> prevrps routeProcessingSheets: '+routeProcessingSheets);

            List<Route_Processing_Sheet__c> rpssToUpd = new List<Route_Processing_Sheet__c>();
            //  Roll through and update the rps 'prev' fields that are in context.
            for (Route_Processing_Sheet__c rpsUpd : routeProcessingSheets) {
                if (mUpdateRpsId_prevRps.containsKey(rpsUpd.Id)) {
                    PreviousCollectionType pct = mUpdateRpsId_prevRps.get(rpsUpd.Id);
                    if (pct != null) {
                        rpsUpd.Previous_VGT_Collection__c = mUpdateRpsId_prevRps.get(rpsUpd.Id).prevVgtId;
                        rpsUpd.Previous_RT_Collection__c = mUpdateRpsId_prevRps.get(rpsUpd.Id).prevRtId;
                        rpssToUpd.add(rpsUpd);
                    }
                } else {
                    System.debug(LoggingLevel.info,'--> rolling through update and prev rps  no key found: ');
                }
            }
            //  Fire the update.
            System.debug(LoggingLevel.info,'--> prevrps rpssToUpd: '+rpssToUpd);
            if (!rpssToUpd.isEmpty()) {
                update rpssToUpd;
                System.debug(rpssToUpd);
                System.debug('---> ' + rpssToUpd.size() + ' route processing sheets updated.');
            }
        }
    }

    /**
     * Query all rpss (for the account ids in context). sort by Account id , Collection date desc.
     * Appears to be working functionally as of 12/28/2021 but have gov limit concerns.
     *
     * @param accountIds All the accountIds of the newly inserted RPS Records.
     *
     * @return A List of Route Processing Sheets which includes those newly inserted, sorted like the following:
     *         AccountId, CollectionDate   (DESC) ie.
     *
     * @description  Basically the client will need to skip the current row and use i+1 to find it's most recent.
     *
     * @todo         This is problematic if done in bulk outside of a usually daily process as
     *               we need to go back on every rps and every account id
     *               ie. we are going to hit 50K limits at some point on the 100 account ids coming in alone
     *               as  we establish more history but I don't know how to avoid this as this
     *               is awkward to figure out. maybe skip out to SFDC functions? Idk.
     *               maybe add Collection Date within last month?
     */
    @TestVisible
    private Map<Id,List<Route_Processing_Sheet__c>> findAllRps(Set<Id> accountIds) {
        System.debug(LoggingLevel.info,'--> prevrps findPreviousRps: accountIds: '+accountIds);
        Map<Id,List<Route_Processing_Sheet__c>> mAcct_Rps = new Map<Id,List<Route_Processing_Sheet__c>>();

        List<Route_Processing_Sheet__c> prevRps = [
                SELECT      Id,Account__c,CreatedDate,Previous_VGT_Collection__c,Previous_RT_Collection__c,Collection_Type__c
                FROM        Route_Processing_Sheet__c
                WHERE       Account__c  IN :accountIds
                ORDER BY    Account__c, Collection_Date__c DESC, Id DESC
        ];
        System.debug(LoggingLevel.info,'--> prevrps findPreviousRps: query results: '+prevRps);
        for(Route_Processing_Sheet__c rps : prevRps) {
            if(!mAcct_Rps.containsKey(rps.Account__c)) {
                mAcct_Rps.put(rps.Account__c, new List<Route_Processing_Sheet__c> {rps});
            } else {
                List<Route_Processing_Sheet__c> acctRps = mAcct_Rps.get(rps.Account__c);
                acctRps.add(rps);
            }
        }

        return mAcct_Rps;
    }
}