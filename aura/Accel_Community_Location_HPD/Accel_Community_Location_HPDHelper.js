({
    /**
     * Datatable header / column init.
     * @param cmp
     */
    initHpdDatatableColumns: function (cmp) {
        cmp.set('v.holdPerDayColumns', [
            {label: 'Date',     fieldName: 'Date__c',type: 'date-local', sortable: false},
            {label: 'Position',     fieldName: 'Position__c',type: 'Integer', sortable: false },
            {label: 'NTI',      fieldName: 'NTI__c',type: 'currency', sortable: false, cellAttributes: { alignment: 'left' } },
            {label: 'Funds In', fieldName: 'Funds_In__c',type: 'currency', sortable: false,cellAttributes: { alignment: 'left' }},
            {label: 'Location Share', fieldName: 'Location_Share__c',type: 'currency', sortable: false,cellAttributes: { alignment: 'left' }}
            ]);
    },
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
     * Call Server to get hold per day records for selected account.
     * @param cmp
     */
    retrieveAccountsHpds: function (cmp) {
        var self = this;
        var action = cmp.get('c.retrieveAccountHpds');
        var collectionUtils = cmp.find('collectionUtils');
        cmp.set("v.showSpinner", true);
        action.setParams({"accountId": cmp.get('v.selectedAccountId')});

        action.setCallback(this, $A.getCallback(function (response) {
            var self = this;
            var state = response.getState();
            var hpds = [];
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                self.log(cmp,'dto','debug',dto);
                collectionUtils.getMapValue('HPD_LIST', dto.values, function (value) {hpds = value;});
                cmp.set('v.holdPerDayData',hpds);
                cmp.set('v.numberOfHpdRecords',hpds.length);
                cmp.set("v.showSpinner", false);
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(JSON.stringify(errors));
                self.displayUiMsg(cmp, 'error', errors);
                cmp.set("v.showSpinner", false);
            }
        }));
        self.log(cmp, 'Enqueuing call to retrieve hold per days', 'info');
        $A.enqueueAction(action);
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
});