({
    /**
     * Calls the server to retrieve License Exp and HPD Total data.
     * @param cmp
     */
    retrieveAllAccountMonthlyTotals: function (cmp) {
        cmp.set("v.showSpinner", true);
        let monthDate = cmp.get("v.dateSelected");
        let dMonthDate = new Date(monthDate);
        let action = 'c.retrieveHoldPerDayByAccountsSingleMonth';
        let accountIds = cmp.get('v.accountIds');
        let params = {
            "accountIds": accountIds,
            "monthDate": dMonthDate
        }
        cmp.lax.enqueue(action,params) //pop area chart....
            .then(response => {
                this.processAllAccountMonthlyTotals(cmp, response);
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleInitErrors(cmp,errors);
            });
    },
    processAllAccountMonthlyTotals: function(cmp, response) {
        let dto = response;
        cmp.set('v.showSpinner',false);
        let hpdWraps = [];
        let collectionUtils =  cmp.find('collectionUtils');
        collectionUtils.getMapValue('HPD_ACCOUNTS_SINGLE_MONTH_WRAPPER_LIST', dto.values, function (value) {hpdWraps = value;});
        this.log(cmp, 'retrieveAllAccountMonthlyTotals.... HPD_ACCOINTS_SINGLE_MONTH_WRAPPER_LIST', 'info' + hpdWraps);
        if (hpdWraps) {
            for (var i = 0; i < hpdWraps.length; i++) {
                var hpdWrap = hpdWraps[i];
                if (hpdWrap.accountName && hpdWrap.accountPhysicalStreet) {
                    hpdWrap.accountNameConcat = hpdWrap.accountPhysicalStreet + ' - ' + hpdWrap.accountPhysicalCity;
                }
            }
        }
        hpdWraps.sort(function (a, b) {return b.locShare - a.locShare;});
        cmp.set('v.locationMonthlyData', hpdWraps);
        cmp.set('v.locationMonthlyRawData', hpdWraps);

        this.buildData(cmp, 'v.locationMonthlyRawData', 'v.locationMonthlyData');
        let arr = cmp.get('v.locationMonthlyData');
        cmp.set("v.totalPages", Math.ceil(arr.length / cmp.get("v.pageSize")));
        let evt = $A.get("e.c:Accel_ChartLocShareMthDataRefreshed");
        evt.setParams({
            "locShareSingleMonthData": hpdWraps
        });
        this.log(cmp, 'firing evt with hpdWraps', 'info', hpdWraps);
        evt.fire();
    },
    /**
     *
     * @param cmp
     * @param errors
     */
    handleInitErrors : function(cmp,errors) {
        this.log(cmp, 'errors in init server side retrieval calls', 'error', errors);
        console.log(errors);
    },
    initLocationDatatableColumns: function (cmp) {
        cmp.set('v.locationColumns', [
            {label: 'Month', fieldName: 'hpdDate', type: 'date-local', sortable: true},
            {
                label: 'Location Share',
                fieldName: 'locShare',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Funds Out',
                fieldName: 'fundsOut',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Revenue',
                fieldName: 'netRevenue',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            }

        ]);
    },
    initLocationMonthDatatableColumns: function (cmp) {
        cmp.set('v.locationMonthlyColumns', [
            {label: 'Location', fieldName: 'accountNameConcat', type: 'String', sortable: true},
            {
                label: 'Location Share',
                fieldName: 'locShare',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Revenue',
                fieldName: 'netRevenue',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            }
        ]);
    },
    /**
     *  Builds displayed table data based on current page selection.
     * @param cmp
     * @param rawAttributeName  ie v.rawAccountData
     * @param dataAttributeName ie v.accountData
     */
    buildData: function (cmp, rawAttributeName, dataAttributeName) {
        var self = this;
        var data = [];
        var pageNumber = cmp.get("v.currentPageNumber");
        var pageSize = cmp.get("v.pageSize");
        var rawData = cmp.get(rawAttributeName);

        var x = (pageNumber - 1) * pageSize;
        //creating data-table data
        for (; x <= (pageNumber) * pageSize; x++) {
            if (rawData[x]) {
                data.push(rawData[x]);
            }
        }
        cmp.set(dataAttributeName, data);
        self.generatePageList(cmp, pageNumber);
    },
    generatePageList: function (cmp, pageNumber) {
        pageNumber = parseInt(pageNumber);
        var pageList = [];
        var totalPage = cmp.get("v.totalPages");
        if (pageNumber < 5 && pageNumber < totalPage) {
            pageList.push(2, 3, 4, 5);
        } else if (pageNumber > (totalPage - 5)) {
            pageList.push(totalPage - 5, totalPage - 4, totalPage - 3, totalPage - 2, totalPage - 1);
        } else {
            pageList.push(pageNumber - 2, pageNumber - 1, pageNumber, pageNumber + 1, pageNumber + 2);
        }
        cmp.set("v.pageList", pageList);
        cmp.set("v.showSpinner", false);
    },
    sortData: function (cmp, data, fieldName, sortDirection, attributeName,rawAttributeName) {
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        this.log(cmp, 'in helper sort data after sort width data length =' + data.length + '..attribute name=' + attributeName,'info',data);
        cmp.set(attributeName, data);
        this.buildData(cmp, rawAttributeName, attributeName);

    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function (x) {
                return primer(x[field])
            } :
            function (x) {
                return x[field]
            };
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    //=============================================== GENERAL HELPER UTILS =============================================
    /**
     * Simply a wrapper around The Utils Component / log method.
     *
     * @param cmp
     * @param msg - the message to logn...
     * @param level [debug,info,warn,error]
     * @param jsonObj  optional a JSON OBJECT and not a string!
     */
    log: function (cmp, msg, level, jsonObj) {
        var lvl;
        if (arguments.length === 0) {
            console.error('you must minimally pass the cmp ref and message to the log function');
            return;
        } else if (arguments.length === 1) {
            console.error('could not find message to log');
            return;
        } else if (arguments.length === 2) {
            lvl = 'debug';
        } else {
            lvl = level;
        }
        try {
            if (cmp.get("v.debugConsole") || lvl === 'error') {
                var cmpName = '--- Accel_CommunityAccountMonthTotals CMP --- ';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, lvl, msg, jsonObj);
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    },
    sortHpdDateDesc: function (cmp, arr) {
        arr.sort(function (a, b) {
            var aDate = new Date(a.hpdDate);
            var bDate = new Date(b.hpdDate);
            return bDate.getTime() - aDate.getTime();
        });
    },
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
})