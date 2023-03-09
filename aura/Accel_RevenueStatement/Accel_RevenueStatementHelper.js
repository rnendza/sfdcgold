({
    /**
     * Call Server to get accounts visible to the user.
     * @param cmp
     */
    retrieveUserAccounts: function(cmp) {
        var self = this;
        var action = cmp.get('c.retrieveAccounts');
        var collectionUtils = cmp.find('collectionUtils');
        cmp.set("v.showSpinner", true);

        action.setCallback(this, $A.getCallback(function (response) {
            var self = this;
            var state = response.getState();
            var accounts = [];
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
                cmp.set('v.userAccounts',accounts);
                cmp.set("v.showSpinner", false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(JSON.stringify(errors));
                self.displayUiMsg(cmp, 'error', errors);
                cmp.set("v.showSpinner", false);
            }
        }));
        self.log(cmp, 'Enqueuing call to retrieve accounts', 'info');
        $A.enqueueAction(action);
    },
    /**
     * Call Server to get aggregated hpd daily records for machines within a date range.
     * @param cmp
     */
    retrieveHoldPerDayByAccount: function(cmp) {
        var self = this;
        //retrieveHoldPerDayByAccount( Id accountId, Date startDate, Date endDate ) {
        var action = cmp.get( 'c.retrieveHoldPerDayByAccount' );
        var collectionUtils = cmp.find('collectionUtils');
        cmp.set("v.showSpinner", true);
        var accountId = cmp.get("v.selectedAccountId");
      //  var dStart = new Date(2018,12,9);
      //  var dEnd = new Date( 2018,12,15);
        var sStartDate = JSON.stringify( '2018-12-09');
        var sEndDate = JSON.stringify( '2018-12-15' );

        self.log(cmp,'--- params= accountId='+accountId + '..startDate='+sStartDate,'info');
        action.setParams({"accountId": accountId, "startDate" : sStartDate, "endDate" :sEndDate});

        action.setCallback(this, $A.getCallback(function (response) {
            var self = this;
            var state = response.getState();
            var hpdWraps = [];
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                collectionUtils.getMapValue('HPD_WRAPPER_LIST', dto.values, function (value) {hpdWraps = value;});
                //cmp.set('v.holdPerDayWrappers',hpdWraps);
                console.log(hpdWraps);
                cmp.set('v.hpdDebug',JSON.stringify(hpdWraps));
                var totals = self.buildTotals(cmp,hpdWraps);
                console.log(totals);
                cmp.set('v.hpdTotals',totals);
                cmp.set('v.hpdTotalsDebug',JSON.stringify(totals));
                self.buildFakeFooter(cmp,hpdWraps,totals);
                cmp.set("v.showSpinner", false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(JSON.stringify(errors));
                self.displayUiMsg(cmp, 'error', errors);
                cmp.set("v.showSpinner", false);
            }
        }));
        self.log(cmp, 'Enqueuing call to retrieve hold per day aggregates','info');
        $A.enqueueAction(action);
    },
    buildFakeFooter: function (cmp,hpdWraps,hpdTotals) {
        var self = this;
        //var hpdWraps = cmp.get("v.holdPerDayWrappers");
        //alert(JSON.stringify(hpdWraps));
        var hpdWrap = {
            vgtUid         : "Totals:",
            amtPlayed      : hpdTotals.totalAmtPlayed,
            amtWon         : hpdTotals.totalAmtWon,
            netRevenue     : hpdTotals.totalNetRevenue,
            fundsIn        : hpdTotals.totalFundsIn,
            fundsOut     : hpdTotals.totalFundsOut,
            netFunds      : hpdTotals.totalNetFunds,
            adminFeeRate  : null,
            adminShare  : 9999,
            totalBill   : hpdTotals.totalBill
        };
        hpdWraps.push(hpdWrap);
       // alert('pushing:'+JSON.stringify(hpdWrap));

           cmp.set("v.holdPerDayWrappers",hpdWraps);
    },
    buildTotals: function (cmp,hpdWraps) {
        var self = this;
        //var hpdWraps = cmp.get('v.holdPerDayWrappers');
        var totals = {
            totalAmtPlayed      : 0,
            totalAmtWon         : 0,
            totalNetRevenue     : 0,
            totalFundsIn        : 0,
            totalFundsOut       : 0,
            totalNetFunds       : 0,
            totalBill           : 0
        };
        for(var i=0; i<hpdWraps.length; i++) {
            var hpdWrap = hpdWraps[i];
            totals.totalNetRevenue      += hpdWrap.netRevenue;
            totals.totalAmtPlayed       += hpdWrap.amtPlayed;
            totals.totalAmtWon          += hpdWrap.amtWon;
            totals.totalFundsIn         += hpdWrap.fundsIn;
            totals.totalFundsOut        += hpdWrap.fundsOut;
            totals.totalBill            += hpdWrap.totalBill;
            totals.totalNetFunds         += hpdWrap.netFunds;
        }
        return totals;
    },
    initRevenueDatatableColumns: function (cmp) {
        cmp.set('v.revenueStatementColumns', [
            {label: 'VGT UID', fieldName: 'vgtUid', type: 'String', sortable: true},
            {label: 'Amt Played', fieldName: 'amtPlayed', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Amt Won', fieldName: 'amtWon', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Net Revenue', fieldName: 'netRevenue', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Funds In', fieldName: 'fundsIn', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Funds Out', fieldName: 'fundsOut', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Net Funds', fieldName: 'netFunds', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Admin Fee', fieldName: 'adminFeeRate', type: 'number',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Admin Share', fieldName: 'adminShare', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Tax Rate', fieldName: 'taxRate', type: 'number',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'State Share', fieldName: 'stateShare', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }},
            {label: 'Total Bill', fieldName: 'totalBill', type: 'currency',sortable: true,cellAttributes: { alignment: 'left' }}

        ]);
    },
    /**
     * Simply a wrapper around The Utils Component / log method.
     *
     * @param cmp
     * @param msg - the message to log...
     * @param level [debug,info,warn,error]
     * @param jsonObj  optional a JSON OBJECT and not a string!
     */
    log: function (cmp, msg, level, jsonObj) {
        try {
            if (cmp.get("v.debugConsole") || level === 'error') {
                var cmpName = '--- Accel_Community_Location_HPD ';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, level, msg, jsonObj);
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    },
    /**
     * Uses force:showToast to display a Toast msg in the UI.
     *
     * @param cmp
     * @param type - the type of message (error,warning,success,info)
     * @param msg  - the message to display.
     * @see https://developer.salesforce.com/docs/component-library/bundle/force:showToast/specification
     */
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    }
})