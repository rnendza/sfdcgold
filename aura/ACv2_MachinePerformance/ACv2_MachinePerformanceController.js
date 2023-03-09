({

    doInit: function (cmp, evt, helper) {
        //https://accel-entertainment.monday.com/boards/286658657/
        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.formatUtils = cmp.find('formatUtils');
        helper.csvExporter = cmp.find('csvExporter');
        //https://accel-entertainment.monday.com/boards/286658657/
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.retrieveCommunityUserSettings(cmp);

        helper.log(cmp,'doInit','debug');
        //cmp.set('v.dMetric', 'Revenue');
        //cmp.set('v.dFrequency', 'All Days');
        //cmp.set('v.vfhost', encodeURI('https://accelentertainment--uat--c.cs78.visual.force.com/apex/echarttest'));
        helper.log(cmp,'in doInit calling retrieveMonthlydHpdData');
        helper.retrieveMonthlyHpdDates(cmp);
        //helper.initColumns(cmp);
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
    },
    scriptsLoaded: function (cmp, evt, helper) {
        if (typeof (echarts) == 'undefined') {
            alert(cmp, 'echarts not loaded!', 'error');
        } else {
            cmp.set('v.scriptsWereLoaded', true);
        }
    },

    onChangeAccount: function (cmp, event, helper) {
        let selectedVal = event.getParam('value');
        cmp.set('v.selectedAccountId', selectedVal);
        let accounts = cmp.get('v.userAccounts');
        if (selectedVal) {
            helper.retrieveHistoricalData(cmp);
            helper.retrieveAggregateMachineData(cmp);
            helper.retrieveMachineTabData(cmp);
        }
    },

    onChangeMonthSelect: function (cmp, event, helper) {
        const selectedDate = cmp.get('v.selectedDate');
        if (selectedDate === '30' || selectedDate === '90') {
            helper.setYesterday(cmp);
            helper.retrieveAggregateMachineData(cmp);
        } else if (selectedDate === 'Cust') {
            // let start = cmp.get('v.startDate');
            //let end = cmp.get('v.endDate');
            // helper.retrieveCustomPieData(cmp, start, end);

        } else if (selectedDate === 'Yesterday') {
            let start = cmp.get('v.yesterday');
            cmp.set('v.startDate', start);
            cmp.set('v.endDate', start);
            helper.retrieveAggregateMachineData(cmp);

        } else {
            helper.processMonth(cmp, selectedDate);
        }
    },
    onDateUpdated: function (cmp, event, helper) {
        let start = cmp.get('v.startDate');
        let end = cmp.get('v.endDate');
        if(start && end && end >=start ){
            helper.log(cmp,'calling retrieveAggregatedMachineData','debug');
           helper.retrieveAggregateMachineData(cmp);

        }else if(start && end){
            helper.displayUiMsg(cmp,'error','Start Date must equal to or before the End Date');
        }
    },
    onHDateUpdated: function (cmp, event, helper) {
        let start = cmp.get('v.startHDate');
        let end = cmp.get('v.endHDate');
        if(start && end && end >=start ){
            helper.log(cmp,'calling retrieveHistoricalData','debug');
            helper.retrieveHistoricalData(cmp);

        }else if(start && end){
            helper.displayUiMsg(cmp,'error','Start Date must equal to or before the End Date');
        }
    },
    onFrequencyChange: function (cmp, event, helper){
        let freq = cmp.get('v.selectedFrequency');
        if(freq === 'Daily'){
            //changed from monthly, make sure last dates input were valid
            let start = cmp.get('v.startHDate');
            let end = cmp.get('v.endHDate');
            if(start && end && end >=start ){
                helper.log(cmp,'calling retrieveHistoricalData','debug');
                helper.retrieveHistoricalData(cmp);

            }else if(start && end){
                helper.displayUiMsg(cmp,'error','Start Date must equal to or before the End Date');
            }
        }else if (freq === 'Monthly'){
            helper.log(cmp,'calling retrieveHistoricalData','debug');
            helper.retrieveHistoricalData(cmp);
        }
    },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        // assign the latest attribute with the sorted column fieldName and sorted direction
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    changeGraph: function(cmp, evt, helper){
        helper.processBtnClick(cmp, evt, helper);
    },
    downloadData: function(cmp, event, helper){
        helper.prepCsvExport(cmp);
    },
    tabSelected: function(cmp, event, helper){
        let tab = event.getSource();
        switch (tab.get('v.id')){
            case 'perfTab':
                cmp.set('v.mainTabsetSelectedTab', 'perfTab');
                break;
            case 'histTab':
                cmp.set('v.mainTabsetSelectedTab', 'histTab');
        }
    }
})