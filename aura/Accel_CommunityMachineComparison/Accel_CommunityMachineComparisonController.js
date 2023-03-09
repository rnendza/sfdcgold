({
    /**
     * Action called on the init handler of the component. Set static reference to chart component that will generate
     * options on the chart. Set static reference to utils stuff. Debug some parent cmp params. Add a resize listener.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    doInit: function (cmp,evt,helper) {
        helper.loggingUtils = cmp.find("loggingUtils");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.debugInboundParams(cmp);
        helper.chartMachineComparisonDisplay = cmp.find('chartMachineComparisonDisplay');
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
    },
    /**
     * Ensure chart instance is nullified upon destroy of cmp.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleDestroy: function (cmp,evt,helper) {
        helper.log(cmp,'System is destroying cmp','info');
        if(helper.machineComparisonChart) {
            helper.log(cmp,'nulling out machineComparisonInstance','info');
            helper.machineComparisonChart = null;
        }
    },
    /**
     * Listens for machine clicked on the pie chart.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleMachineClickedEvent: function(cmp,evt,helper) {
        let machineClicked = evt.getParam('machineClicked');
        helper.log(cmp,'Handling machine clicked event:'+JSON.stringify(machineClicked),'info',machineClicked);
        if(helper.machineComparisonChart) {
            helper.machineComparisonChart.dispatchAction( {
                type: 'legendSelect',
                name: machineClicked.machineName
            });
        }
    },
    /**
     * Script libraries are done loading. Ensure a instance of echarts exists.
     * If this is not called it means the chart lib was not found or locker service gave the lib the middle finger.
     * Fire off any server calls / code relative to building the charts.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    scriptsLoaded: function (cmp,evt,helper) {
        if (typeof (echarts) == 'undefined') {
            helper.log(cmp, 'echarts library not loaded!', 'error');
        } else {
            //helper.doEndToEndSampleBuild(cmp);     // will just use sample data built internally.
            helper.retrieveHpdDataAndMachineAverages(cmp);  // hit the server for both hpd machine data and average data.
        }
    },
    /**
     * Detect change of incoming object attribute.
     * ie. User executed different search with different account. start date / end date.
     * Call the server again to get new data.
     *
     * Note. 2 way binding is used so beware of any mods to this object that might be unwanted on parent cmp.
     *
     * @param cmp
     * @param evt
     * @param helper
     *
     * For simple update of option data without entire rebuild of options... see the below
     * @see https://stackoverflow.com/questions/40909841/echarts-refresh-on-data-change
     */
    selectedAccountChange: function(cmp, evt, helper) {
        helper.log(cmp,'selected account had changed.','info');
       // helper.log(cmp,"old value: ",'info',evt.getParam("oldValue"));
       // helper.log(cmp,"new value: ",'info',evt.getParam("value"));
        helper.retrieveHpdDataAndMachineAverages(cmp);  // hit the server for both hpd machine data and average data.
    }
});