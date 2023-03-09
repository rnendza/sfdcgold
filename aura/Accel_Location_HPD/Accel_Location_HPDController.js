({
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    init: function (cmp, event, helper) {
        try {
            cmp.set("v.showSpinner", true);
            helper.setHpdSummaryHelpHeaderText(cmp);
            helper.retrieveHpdAccountSettings(cmp,helper);
            helper.initDatatableColumns(cmp);
            helper.retrieveHpds(cmp);
        } catch (e) {
            alert(e);
            console.log(e);
        }
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    }
})