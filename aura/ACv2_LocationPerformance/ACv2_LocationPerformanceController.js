({
    /**
     *
     *   https://accel-entertainment.monday.com/boards/286658657/pulses/293968845
     *   https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     */
    doInit: function (cmp, evt, helper) {
        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.disabledRadarChartTitle =  $A.get("$Label.c.Community_Disabled_Radar_Chart_Title");
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.formatUtils = cmp.find('formatUtils');
        helper.csvExporter = cmp.find('csvExporter');
        helper.retrieveCommunityUserSettings(cmp);
        //--- all the below moved to callaback of retrieveCommunitySettings for timing reasons.
        // helper.processUrlParams(cmp);
        // helper.initColumns(cmp);
        // helper.setYesterday(cmp);
        // helper.retrieveMonthlyHpdDates(cmp);
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293968275
     *
     * Pass the accountId and the selected date when the user has a month selected in the top left drop down
     * and then selects a slice of the pie chart and then display the machine performance link.. to the machine performance
     * page. User must pic month then choose slice. The opposite is not supported, there would have been too much
     * rework for that!
     */
    doViewMachinePerformance: function(cmp, evt, helper) {

        let locationIdSelected  = cmp.get('v.locationIdSelected');
        let selectedDate        = cmp.get('v.selectedDate');

        let msg = 'doViewMachinePerformance..locationIdSelected='+locationIdSelected+'...selectedDate='+selectedDate;
        helper.log(cmp,msg,'debug');

        if(locationIdSelected && selectedDate) {
            try {
                let urlEvent = $A.get("e.force:navigateToURL");
                let date = new Date(selectedDate);
                date.setDate(date.getDate() + 1);
                let fDate = $A.localizationService.formatDate(date, 'YYYY-MM-dd');
                let dayParam = '&day=' + fDate;
                urlEvent.setParams({"url": '/machine-performance?accountId=' + locationIdSelected + dayParam});
                urlEvent.fire();
            } catch (e) {
                helper.log(cmp,'generic','error');
            }
        }
    },
    scriptsLoaded: function (cmp, evt, helper) {
        if (typeof (echarts) == 'undefined') {
            alert(cmp, 'echarts not loaded!', 'error');
        } else {
            //helper.retrieveAggregateLifetimeHpdData(cmp); moved to init / retrieveCommunityUserSettings for timing reasons.
            helper.log(cmp, 'echarts lib successfully loaded ', 'info');
            cmp.set('v.scriptsWereLoaded', true);
        }
    },
    onDateUpdated: function (cmp, event, helper) {
        let start = cmp.get('v.startDate');
        let end = cmp.get('v.endDate');
        helper.log(cmp,'onDateUpdated start='+start+'... end='+end,'debug');
        if(start && end && end >=start ){
            //fire
            helper.log(cmp,'calling retrieveCustomPieData','debug');
            helper.retrieveCustomPieData(cmp, start, end);
            cmp.set('v.locationSelected', 'All Locations');
            cmp.set('v.pieType', 'Custom');

        }else if(start && end){
            helper.displayUiMsg(cmp,'error','Start Date must equal to or before the End Date');
        }
    },
    /**
     *  https://accel-entertainment.monday.com/boards/286658657/pulses/293968275
     *  https://accel-entertainment.monday.com/boards/286658657/pulses/293968845
     */
    onChangeMonthSelect: function (cmp, event, helper) {
        const selectedDate = cmp.get('v.selectedDate');
        helper.log(cmp,'onChangeMonthSelect selectedDate=','debug',selectedDate);
        if (selectedDate === 'Lifetime') {
            cmp.set('v.displayMachinePerformanceLink',false);
            //===============================
           helper.refreshPieLifetime(cmp);
           cmp.set('v.locationSelected', 'All Locations');
           cmp.set('v.pieType', 'All');
           helper.refreshAggregateMonthlyAverages(cmp);
        }else if (selectedDate === 'Cust') {
            cmp.set('v.displayMachinePerformanceLink',false);
           // let start = cmp.get('v.startDate');
            //let end = cmp.get('v.endDate');
            // helper.retrieveCustomPieData(cmp, start, end);
            //helper.disableRadar(cmp);
            cmp.set('v.locationIdSelected',null);
        }else {
            cmp.set('v.displayMachinePerformanceLink',false);
            cmp.set('v.locationSelected', 'All Locations');
            cmp.set('v.locationIdSelected',null);
            cmp.set('v.pieType', 'Monthly');
            helper.retrieveMonthlyPieData(cmp, selectedDate);
        }
    },
    // Client-side controller called by the onsort event handler
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    downloadData: function(cmp, event, helper){
        helper.prepCsvExport(cmp);
    },
})