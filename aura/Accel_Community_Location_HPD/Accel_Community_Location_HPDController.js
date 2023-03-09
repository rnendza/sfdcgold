({
    /**
     * Fire it up!
     */
    doInit: function (cmp, event, helper) {
        try {
            console.log('do init');
            helper.initHpdDatatableColumns(cmp);
            helper.retrieveUserAccounts(cmp);
        } catch (e) {
            helper.log(cmp, 'error while initializing component', 'error', e);
            helper.displayUiMsg(cmp,'error',e.message);
        }
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
        if(selectedAccountId && selectedAccountId != '') {
            cmp.set('v.showSpinner', true);
            cmp.set('v.searchExecuted', true);
            console.log('@TODO in DEV DEBUG selected account id=' + selectedAccountId);
            helper.retrieveAccountsHpds(cmp);
        } else {
            cmp.set('v.searchExecuted', false);
        }
    }
})