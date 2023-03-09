({
    /**
     * On init of component. init objects.. datatables and selection dates.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    doInit: function(cmp,evt,helper) {
        helper.csvExporter = cmp.find('csvExporter');
        helper.formatUtils = cmp.find('formatUtils');
        helper.chartMachineTotalsDisplay = cmp.find('chartMachineTotalsDisplay');
        helper.chartDailyLocShareDisplay = cmp.find('chartDailyLocShareDisplay');
        helper.defaultSelectionDates(cmp);
        helper.initGridMachineColumns(cmp);

        //--- add a window resize listener.. needed for charts size we are customizing the shit out of this.
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
    },
    /**
     * Export to CSV button above treegrid.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleDatatableToolbarButtonClick: function (cmp, event, helper) {
        if (event) {
            const btnId = event.getSource().getLocalId();
            switch (btnId) {
                case 'btnCsvDownload' :
                    helper.prepCsvExport(cmp);
                    break;
            }
        }
    },
    /**
     * Show a spinner for 500 ms.
     *
     * Note this a hack to account for the fact that lightning:treegrid is internally slow
     * when expanding child rows when there are a large number of parent rows. This is somewhat
     * useless as we don't get to this function it seems until after the internal sfdc code has processed.
     *
     * let's hope lightning TreeGrid gets optimized by SFDC or maybe we just load child rows async. but that's
     * alot of code to change.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleGridToggle: function (cmp, event, helper) {
        let TIMEOUT_MILLISECONDS = 500;
        let params = event.getParams();
        let isExpanded = params.isExpanded;
        if(isExpanded) {
            cmp.set('v.showGridSpinner', true);
            window.setTimeout($A.getCallback(function() {cmp.set('v.showGridSpinner',false)}), TIMEOUT_MILLISECONDS);
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
        var selectedPlVal = event.getParam('value');
        cmp.set('v.selectedAccountId',selectedPlVal);
        helper.log(cmp,'do search selected Account Id ='+selectedPlVal);

        if(selectedPlVal) {
            cmp.set('v.showSpinner', true);
            helper.retrieveHoldPerDayByAccount(cmp);
            var accounts = cmp.get('v.userAccounts');
            cmp.set('v.selectedAccount',helper.getAccountById(accounts,selectedPlVal));
        }
    },
    /**
     * User changed start / end date.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    onDateUpdated: function (cmp, event, helper) {
        var target = event.getSource();
        if(target) {
            cmp.set('v.showSpinner', true);
            helper.retrieveHoldPerDayByAccount(cmp);
        }
    },
    /**
     * Scripts were loaded successfully. if this is not called SFDC is pissed about the scripts your trying to use and
     * not allowing them. ( CSP violation or not found most likely )
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    scriptsLoaded: function(cmp,evt,helper) {
        if (typeof (echarts) == 'undefined') {
            alert(cmp, 'echarts not loaded!', 'error');
        } else {
            helper.log(cmp, 'echarts lib successfully loaded ', 'info');
            helper.retrieveUserAccountsAndHpds(cmp);
            cmp.set('v.scriptsWereLoaded', true);
        }
    },
})