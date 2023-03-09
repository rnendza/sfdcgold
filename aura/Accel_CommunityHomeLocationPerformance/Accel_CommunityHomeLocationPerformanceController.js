({
    /**
     * Called upon init of component. Inits datatables and general utils and registers a windowResizing event for use
     * with resizing charts
     *
     * Retrieves general table data that is not dependent on the chart libs (ie. lice exp and loc share..
     *
     * @param cmp
     * @param evt
     * @param helper
     * @note server data retrieval is called after scripts are loaded.
     */
    doInit: function (cmp, evt, helper) {
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.initLocationDatatableColumns(cmp);
        helper.retrieveTableData(cmp);
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
        helper.formatUtils = cmp.find('formatUtils');
    },
    /**
     * Scripts were loaded successfully. if this is not called SFDC is pissed about the scripts your trying to use and
     * not allowing them. ( CSP violation or not found most likely ).
     *
     * Call helper method to initially retrieve data that is needed for charts.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    scriptsLoaded: function (cmp, evt, helper) {
        if (typeof (echarts) == 'undefined') {
            alert(cmp, 'echarts not loaded!', 'error');
        } else {
            helper.log(cmp, 'echarts lib successfully loaded ', 'info');
            //helper.retrieveAllData(cmp);
            helper.retrieveChartData(cmp);
            cmp.set('v.scriptsWereLoaded', true);
        }
    },
    //================================================ UI EVENTS ============================================
    /**
     *  Monthly picklist by the pie chart..
     *
     * @param cmp
     * @param event
     * @param helper
     *
     */
    onChangeMonthSelect: function (cmp, event, helper) {
        const selectedDate = cmp.get('v.selectedDate');
        if (!selectedDate || selectedDate === 'null') {
            helper.retrieveMonthlyPieData(cmp, 'All');
            cmp.set('v.pieChartSubTitle','All locations (lifetime)');
            helper.processAreaChartButtonClick(cmp,null,helper,'ALL');
            return;
        }
        if (selectedDate === '1YR') {
            helper.retrieveMonthlyPieData(cmp, '1YR');
            cmp.set('v.pieChartSubTitle','All locations (over the past year)');
            helper.processAreaChartButtonClick(cmp,null,helper,'1YR');
            return;
        }

        const accountIds = cmp.get('v.visibleAccountIds');
        if (selectedDate && accountIds && accountIds.length > 0) {
            $A.util.addClass(cmp.find("apexcharts-location-area"), "slds-hide");
            $A.util.removeClass(cmp.find("apexcharts-location-area-by-month"), "slds-hide");
            const evt = $A.get("e.c:Accel_ChartLocShareTotalMonthSelected");
            //@see Accel_CommunityAccountMonthTotals as one of the components handing this event.
            evt.setParams({
                "dateSelected": selectedDate,
                "accountIds": cmp.get('v.visibleAccountIds')
            });
            helper.log(cmp, 'firing locShareDateSelectedEvent with param dateSelected=' + selectedDate + '..accoundIds (obj)=' + cmp.get('v.visibleAccountIds'), 'info');
            evt.fire();
        } else {
            helper.log(cmp, 'not firing locShareDateSelectedEvent','info');
        }
    },
    /**
     * for future use.. for a watcher of a variable
     * @param cmp
     * @param event
     * @param helper
     */
    handleLocDataTabChange: function (cmp, event, helper) {
        const bVal = event.getParam("value");
        if (bVal) {
            //cmp.set('v.showSpinner',false);
        }
    },
    /**
     * for future use...
     * @param cmp
     * @param event
     */
    handleOnSelectPrimaryTabs: function (cmp, event) {
        const tabId = event.getParam('id');
        switch (tabId) {
            case 'locShareTab' :
                break;
            case 'locDetailTab' :
                //  cmp.set('v.showSpinner',true);
                break;
        }
    },
    /**
     * call upon refreshing of datatable next to charts...
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleLocShareMthChartDataRefreshed: function (cmp, event, helper) {
        const arr = event.getParam("locShareSingleMonthData");
        helper.log(cmp, '----------- handleLocShareMthChartDataRefreshed.... Recieved new hpd data in array', 'info', arr);
        cmp.set('v.locShareSingleMonthData', arr);
        let dateSelected;
        if (arr.length > 0) {
            dateSelected = arr[0].hpdDate;
        }
        helper.log(cmp, 'hpd date selected=', 'info', dateSelected);
        if (dateSelected) {
            try {
                dateSelected = new Date(dateSelected);
                dateSelected.setDate(dateSelected.getDate()+1);
                window.setTimeout($A.getCallback( function() {
                    //cmp.set('v.selectedDate','1YR');
                    cmp.find("monthSelect").set("v.value",dateSelected);
                }));
            } catch (e) {
                alert(e);
            }
            //@TODO do we need this?
            helper.resetPieChartSeriesMonthly(cmp, dateSelected, arr);
        }
    },
    /**
     * Chart frequency button click.. ( 1 year / all / Yoy)
     * @param cmp
     * @param event
     * @param helper
     */
    handleAreaChartToolbarButtonClick: function (cmp, event, helper) {
        const target = event.getSource();
        if (event) {
            helper.processAreaChartButtonClick(cmp, event, helper);
        }
    },
    //========================================= DATATABLE PAGINATION / SORT =====================================
    onFirst: function (cmp, event, helper) {
        cmp.set("v.currentPageNumber", 1);
        helper.buildData(cmp, 'v.rawAccountData', 'v.accountData');
    },
    onLast: function (cmp, event, helper) {
        cmp.set("v.currentPageNumber", cmp.get("v.totalPages"));
        helper.buildData(cmp, 'v.rawAccountData', 'v.accountData');
    },
    onNext: function (cmp, event, helper) {
        const pageNumber = cmp.get("v.currentPageNumber");
        cmp.set("v.currentPageNumber", pageNumber + 1);
        helper.buildData(cmp, 'v.rawAccountData', 'v.accountData');
    },
    onPrev: function (cmp, event, helper) {
        const pageNumber = cmp.get("v.currentPageNumber");
        cmp.set("v.currentPageNumber", pageNumber - 1);
        helper.buildData(cmp, 'v.rawAccountData', 'v.accountData');
    },
    /**
     * Datatable sort...........
     *
     * @param cmp
     * @param event
     * @param helper
     * @TODO appears to be bugs in certain circumstances.
     */
    updateLocationDataColumnSorting: function (cmp, event, helper) {
        const fieldName = event.getParam('fieldName');
        const sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        const data = cmp.get('v.locationRawData');
        helper.log(cmp, 'calling sortData with fieldName=' + fieldName + '.. direction=' + sortDirection);
        helper.sortData(cmp, data, fieldName, sortDirection);
    },
});