({
    /**
     * Retrieve all account from picklist.
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function (cmp, event, helper) {
        helper.initUtils(cmp);
        if(cmp.get('v.focusFirstFormField')) {
            helper.focusFirstFlowFormField(cmp);
        }
        helper.retrieveAccountsForIrSelection(cmp);
    },
    /**
     * Merely for logging purposes.
     * @param cmp
     * @param event
     * @param helper
     */
    handleOnChange: function(cmp,event,helper) {
        const selectedValue = cmp.get('v.selectedValue');
        helper.log(cmp, 'account id selected', 'debug', selectedValue);
    }
});