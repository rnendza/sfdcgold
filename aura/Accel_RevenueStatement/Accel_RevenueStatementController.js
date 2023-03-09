({
    doInit: function(cmp, event, helper) {
        helper.retrieveUserAccounts(cmp);
        helper.initRevenueDatatableColumns(cmp);
    },
    /**
     *  Account PL Change.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    onChangeAccount: function (cmp, event, helper) {
        var selectedAccountId = cmp.get('v.selectedAccountId');
        if(selectedAccountId && selectedAccountId !== '') {
            cmp.set('v.showSpinner', false);
          //  cmp.set('v.searchExecuted', true);
            helper.retrieveHoldPerDayByAccount(cmp);
        } else {
            cmp.set('v.searchExecuted', false);
        }
    }
})