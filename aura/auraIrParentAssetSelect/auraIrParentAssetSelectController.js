({
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function (cmp, event, helper) {
        helper.initUtils(cmp);
        helper.retrieveParentAssetsForIrSelection(cmp);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleOnChange: function(cmp,event,helper) {
        const selectedValue = cmp.get('v.selectedValue');
        helper.log(cmp, 'asset id selected', 'debug', selectedValue);
    }
});