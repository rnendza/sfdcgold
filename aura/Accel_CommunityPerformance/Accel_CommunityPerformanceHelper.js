({
    locationDailyLocShareChart: null, machineDailyLocShareChart: null,
    chartMachineTotalsDisplay: null, chartDailyLocShareDisplay: null,
    csvExporter: null, formatUtils: null,
    MACHINE_NAME_TRUNCATE_LEN : 15,

    /**
     * Retrieve user accounts and then hold per day daily records from the server.
     * Process the records , build chart data, and render chart data.
     *
     * @param cmp
     */
    retrieveUserAccountsAndHpds: function(cmp) {
            cmp.set("v.showSpinner", true);
            cmp.lax.enqueue('c.retrieveAccounts') //populate area chart....
                .then(response => {
                    this.processUserAccounts(cmp,response);
                    cmp.set("v.showSpinner", false);
                    const options = {};
                    let accountId = cmp.get("v.selectedAccountId");
                    let sStartDate = JSON.stringify(cmp.get("v.startDate")),sEndDate = JSON.stringify(cmp.get("v.endDate"));
                    const params = {accountId: accountId, startDate: sStartDate, endDate: sEndDate};
                    cmp.set("v.showSpinner", true);
                    return cmp.lax.enqueue('c.retrieveHoldPerDayByAccount',params,options);
                })
                .then(response => {
                     this.processHpdsByAccount(cmp,response);
                 })
                .catch(errors => {
                    cmp.set("v.showSpinner", false);
                    this.handleErrors(cmp,errors);
                });
    },
    /**
     * Retrieve hold per day daily records by single account id and start and end date.
     *
     * @param cmp
     * @returns {*|LaxPromise}
     */
    retrieveHoldPerDayByAccount: function(cmp) {
        let accountId = cmp.get("v.selectedAccountId");
        let sStartDate = JSON.stringify(cmp.get("v.startDate")),sEndDate = JSON.stringify(cmp.get("v.endDate"));
        const params = {accountId: accountId, startDate: sStartDate, endDate: sEndDate};
        cmp.set("v.showSpinner", true);
        return cmp.lax.enqueue('c.retrieveHoldPerDayByAccount',params)
            .then(response => {
                this.processHpdsByAccount(cmp,response);
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleErrors(cmp,errors);
            });
    },
    /**
     * Take the server data from selecting user accounts (and custom meta data of export field names)
     * and populate picklist as well as field names to export.
     *
     * @param cmp
     * @param response
     */
    processUserAccounts: function (cmp, response) {
        let dto = response;
        let accounts = [];
        let collectionUtils = cmp.find('collectionUtils');
        collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
        cmp.set('v.userAccounts', accounts);
        this.setUserAccountOptions(cmp); //---- translate user account array to options array for combo box (location filter)

        let accountId = this.getUrlParam('accountId');
        if (accountId && accountId !== '') {
            cmp.set('v.selectedAccountId', accountId);
        } else {
            accountId = accounts[0].Id;
            cmp.set('v.selectedAccountId', accounts[0].Id);
        }
        //alert('process user accounts.. selected account id='+cmp.get('v.selectedAccountId'));
        cmp.set('v.selectedAccount', this.getAccountById(accounts, accountId));
        //alert('process user accounts.. selected account o after calling getAccountById'+JSON.stringify(cmp.get('v.selectedAccount')));
        let machineDataExportFieldNames = [];
        collectionUtils.getMapValue('MACHINE_EXPORT_FIELD_NAME_LIST', dto.values, function (value) {machineDataExportFieldNames = value;});
        cmp.set('v.machineDataExportFieldNames',machineDataExportFieldNames);
        // window.setTimeout($A.getCallback(function () {
        //     cmp.find("accountSelect").set("v.value", accountId);
        //     alert('in settimeout callback accountSelected='+cmp.find('accountSelect').get('v.value'));
        // }));
    },
    /**
     *
     * @param cmp
     * @param response
     */
    processHpdsByAccount: function (cmp, response) {
        cmp.set("v.showSpinner", false);
        let dto = response;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        collectionUtils.getMapValue('HPD_WRAPPER_LIST', dto.values, function (value) {hpdWraps = value;});
        if (hpdWraps && hpdWraps.length > 0) {
            this.concatAccountName(cmp,hpdWraps);
            cmp.set('v.holdPerDayWrappers', hpdWraps);

            let mHpdDate_LocShareTotal;
            collectionUtils.getMapValue('MAP_HPDDATE_LOCSHARETOTAL', dto.values, function (value) {mHpdDate_LocShareTotal = value;});
            cmp.set('v.hpdDateLocShareMap', mHpdDate_LocShareTotal);

            let oHpdDate_HpdChildren;
            collectionUtils.getMapValue('MAP_HPDDATE_HPDCHILDREN', dto.values, function (value) {oHpdDate_HpdChildren = value;});

            let finalHpdWraps = [];
            if (oHpdDate_HpdChildren) {
                finalHpdWraps = this.shapeTreeGridParentAndChildern(cmp,oHpdDate_HpdChildren);
            }
            cmp.set('v.gridMachineData', finalHpdWraps);
            this.renderEChartBarChart(cmp);
            this.renderMachineDailyLocShare(cmp);
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for your criteria. Please modify your search criteria.');
        }
        this.log(cmp, 'hdpwrappers...', 'info', hpdWraps);
    },
    /**
     *
     * @param cmp
     * @param dDate
     * @returns {{dDateSelected: *, echartData: Array, sStartDate: string, negativeDailys: Array, aggregatedDailys: Array,
     *          legendData: Array, locShareTotalFormatted: (*|number), totalLocShare: number, sEndDate: string}}
     */
    buildDailyEchartPieData: function (cmp, dDate) {
        var self = this;
        var hpdWraps = cmp.get('v.holdPerDayWrappers');
        var m = this.groupDataByKey(hpdWraps, 'vgtUid');
        var aggregatedDatas = [];

        Object.keys(m).map(function (key, index) {
            var machineValues = m[key];
            let aggregatedData = {'machineName': key, 'assetId': '', 'locShareTotal': 0};
            let assetId = '',locShare = 0;
            var bMatchFound = false;

            for (let i = 0; i < machineValues.length; i++) {
                let dailyValue = machineValues[i];
                if(dDate) {
                    var realDate =new Date(dailyValue.hpdDate);
                    realDate.setDate(realDate.getDate() + 1);
                    if(dDate.getTime() === realDate.getTime()) {
                        locShare += dailyValue.locShare;
                        assetId = dailyValue.assetId;
                        bMatchFound = true;
                    } else {
                        continue;
                    }
                }
                if(!dDate) {
                    locShare += dailyValue.locShare;
                    assetId = dailyValue.assetId;
                }
            }
            //@TODO defect?
            if(dDate && bMatchFound) {
                aggregatedData.assetId = assetId;
                aggregatedData.locShareTotal = locShare;
                aggregatedDatas.push(aggregatedData);
            } else {
                aggregatedData.assetId = assetId;
                aggregatedData.locShareTotal = locShare;
                aggregatedDatas.push(aggregatedData);
            }
        });
        //----- seperate positive and negative values.
        var positiveDailys = [];
        var negativeDailys = [];
        for(var i = 0; i<aggregatedDatas.length; i++) {
            var ad = aggregatedDatas[i];
            if(ad.locShareTotal > 0) {
                positiveDailys.push(ad);
            } else {
                if(ad.locShareTotal !== 0) {
                    negativeDailys.push(ad);
                }
            }
        }

        var aggregatedDailys = positiveDailys;
        var echartData = [];
        var legendData = [];
        var dStartDate = cmp.get("v.startDate");
        if(dDate) {dStartDate = dDate;}

        var sStartDate = $A.localizationService.formatDate(dStartDate,'MM-dd-YYYY');
        var dEndDate = cmp.get('v.endDate');
        var sEndDate = $A.localizationService.formatDate(dEndDate,'MM-dd-YYYY');
        var totalLocShare = 0;
        aggregatedDailys.sort(function (a, b) {return b.locShareTotal - a.locShareTotal});
        for (var i = 0; i < aggregatedDailys.length; i++) {
            var dailyAggregate = aggregatedDailys[i];
            var data = {
                'id' : dailyAggregate.assetId,'value': dailyAggregate.locShareTotal,
                'name': truncate(dailyAggregate.machineName,this.MACHINE_NAME_TRUNCATE_LEN)
            };
            totalLocShare += dailyAggregate.locShareTotal;
            var machineName = truncate(dailyAggregate.machineName,this.MACHINE_NAME_TRUNCATE_LEN);
            legendData.push(machineName);
            echartData.push(data);
        }
        //--- subtract negative values from total
        for(var i = 0; i < negativeDailys.length; i++) {
            var negDaily = negativeDailys[i];
            totalLocShare += negDaily.locShareTotal;
        }
        let locShareTotalFormatted = 0;
        locShareTotalFormatted =  self.formatNumericValue('$',totalLocShare,0);

        let chartData = {
            legendData  : legendData,
            echartData  : echartData,
            negativeDailys : negativeDailys,
            aggregatedDailys : aggregatedDailys,
            locShareTotalFormatted : locShareTotalFormatted,
            dDateSelected : dDate,
            sStartDate : sStartDate,
            sEndDate : sEndDate,
            totalLocShare : totalLocShare
        };

        /**
         *
         * @param str
         * @param len
         * @returns {*|string}
         */
        function truncate(str,len) {
            var ret = '';
            if (str.length > len) {
                ret = str.substring(0, len) + '...';
            }else{
                ret = str;
            }
            return ret;
        }
        return chartData;
    },
    /**
     *
     * @param cmp
     * @param hpdWraps
     */
    concatAccountName: function(cmp, hpdWraps) {
        for (let i = 0; i < hpdWraps.length; i++) {
            let hpdWrap = hpdWraps[i];
            if (hpdWrap.accountName && hpdWrap.accountPhysicalStreet) {
                hpdWrap.accountNameConcat = hpdWrap.accountName + ' - ' + hpdWrap.accountPhysicalStreet
            }
        }
    },
    /**
     * Set default form dates either from the url param [month] or just make the start date
     * 2 weeks back from today.
     *
     * @param cmp
     */
    defaultSelectionDates: function (cmp) {
        let sMonthSelected = this.getUrlParam('month');
        let sDaySelected = this.getUrlParam('yesterday');
        if(sDaySelected ==='true'){
            let startDate = new Date();
            startDate.setDate(startDate.getDate() - 1);
            let yesterday = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
            cmp.set('v.endDate', yesterday);
            cmp.set('v.startDate', yesterday);
        }else if (!sMonthSelected) {
            let endDate = new Date();
            let sEndDate = $A.localizationService.formatDate(endDate, 'YYYY-MM-dd');
            cmp.set('v.endDate', sEndDate);
            let startDate = new Date(endDate.valueOf());
            startDate.setDate(startDate.getDate() - 14);
            let sStartDate = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
            cmp.set('v.startDate', sStartDate);
        } else {
            let startDate = new Date();
            startDate.setTime(sMonthSelected);
            let lastDayOfMonth = getLastDayofMonth(startDate.getFullYear(), startDate.getMonth());
            let endDate = new Date(startDate).setDate(lastDayOfMonth);
            let sEndDate = $A.localizationService.formatDate(endDate, 'YYYY-MM-dd');
            cmp.set('v.endDate', sEndDate);
            let sStartDate = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
            cmp.set('v.startDate', sStartDate);
        }
        function getLastDayofMonth(y, m) {
            return new Date(y, m + 1, 0).getDate();
        }
    },
    /**
     *
     * @param cmp
     */
    prepCsvExport: function(cmp) {
        if(cmp.get('v.holdPerDayWrappers')) {
            let arr = cmp.get('v.holdPerDayWrappers');
            let fields = cmp.get('v.machineDataExportFieldNames');
            let fileName  = 'MachinePerformance_'+cmp.get('v.startDate')+'_to_'+cmp.get('v.endDate') +'.csv';
            let dto;
            this.csvExporter.doExport(arr,fields,fileName, function(value) {dto = value;});
            this.displayUiMsg(cmp,dto.severity,dto.message);
        }
    },
    /**
     *
     * @param cmp
     */
    initGridMachineColumns: function (cmp) {
        cmp.set('v.gridMachineColumns', [
            {label: 'Date', fieldName: 'hpdDate', type: 'date', sortable: false},
            {label: 'Machine', fieldName: 'vgtUid', type: 'String', sortable: false},
            {label: 'Funds In', fieldName: 'fundsIn', type: 'currency', sortable: false, cellAttributes: {alignment: 'left'}},
            {label: 'Funds Out', fieldName: 'fundsOut', type: 'currency', sortable: false, cellAttributes: {alignment: 'left'}},
            {label: 'Location Share', fieldName: 'locShare', type: 'currency', sortable: false, cellAttributes: {alignment: 'left', class: 'loc-share-value'}}
        ]);
    },
    /**
     *
     * @param cmp
     * @returns {{dataAxis: Array, data: Array}}
     */
    buildTimeSeriesDailyData: function (cmp) {
        var self = this;
        var data = [];
        var dataSeries = [];
        var dataAxis = [];
        var dateLocShareMap = cmp.get('v.hpdDateLocShareMap');
        if (dateLocShareMap) {
            Object.keys(dateLocShareMap).forEach(function (key) {
                var dDate = new Date(key);
                var locShare = dateLocShareMap[key];
                var val = [dDate, locShare];
                dataAxis.push(dDate);
                data.push(locShare);
                dataSeries.push(val);
            });
            var mDates = dataSeries.map(function (x) {
                return new Date(x[0]);
            });
            var latestDate = new Date(Math.max.apply(null, mDates));
            var earliestDate = new Date(Math.min.apply(null, mDates));
            if (latestDate) {
                cmp.set('v.locationLatestDate', latestDate);
            }
            if (earliestDate) {
                cmp.set('v.locationEarliestDate', earliestDate);
            }
        }
        //----- earliest to latest date sort
        data.reverse();
        dataAxis.sort(function (a, b) {return a.getTime() - b.getTime()});

        var dStartDate = cmp.get("v.startDate"),dEndDate = cmp.get('v.endDate');
        var sStartDate = $A.localizationService.formatDate(dStartDate,'MM-dd-YYYY');
        var sEndDate = $A.localizationService.formatDate(dEndDate,'MM-dd-YYYY');

        var subText = '';
        var account = cmp.get('v.selectedAccount');
        if(account) {
            subText = account.ShippingStreet + ' - ' + account.ShippingCity;
        }
        var bShowBarValues = true;
        if(data.length > 15) {
            bShowBarValues = false;
        }
        let chartData = {
            data  : data,
            dataAxis  : dataAxis,
            sStartDate : sStartDate,
            sEndDate : sEndDate,
            subText : subText,
            bShowBarValues : bShowBarValues
        };
        return chartData;
    },
    /**
     * The OOTB treegrid requires a unique structure with a property named _children.
     * shape the data accordingly here.
     *
     * @param cmp
     * @param oHpdDate_HpdChildren
     * @returns {Array}
     */
    shapeTreeGridParentAndChildern: function(cmp,oHpdDate_HpdChildren) {
        var finalHpdWraps = [];
        Object.keys(oHpdDate_HpdChildren).forEach(function (key) {
            var finalHpdWrap = {};
            var hpdWraps = oHpdDate_HpdChildren[key];
            var totalLocShare = 0;
            var totalFundsIn = 0;
            var totalFundsOut = 0;
            var totalNetRevenue = 0;
            hpdWraps.forEach(function (v) {
                v.hpdDate = null;
                totalLocShare += v.locShare;
                totalFundsIn += v.fundsIn;
                totalFundsOut += v.fundsOut;
                totalNetRevenue += v.netRevenue;
            });
            finalHpdWrap.hpdDate = new Date(key);
            if (finalHpdWrap.hpdDate) {
                finalHpdWrap.hpdDate.setDate(finalHpdWrap.hpdDate.getDate() + 1);
            }
            finalHpdWrap.vgtUid = 'All Machines';
            finalHpdWrap.fundsIn = totalFundsIn;
            finalHpdWrap.fundsOut = totalFundsOut;
            finalHpdWrap.locShare = totalLocShare;
            finalHpdWrap.netRevenue = totalNetRevenue;
            finalHpdWrap._children = hpdWraps;
            finalHpdWraps.push(finalHpdWrap);
        });
        return finalHpdWraps;
    },
    /**
     * Transform userAccount array to array suitable for lightning comobox.
     * @param cmp
     */
    setUserAccountOptions: function (cmp) {
        let accounts = cmp.get('v.userAccounts');
        let accountOptions = [];
        if(accounts) {
            for(let i=0; i<accounts.length; i++) {
                let account = accounts[i];
                let concatName = account.Name + ' - ' + account.ShippingStreet + ' - ' + account.ShippingCity ;
                let accountOption = {'label': concatName, 'value': account.Id};
                accountOptions.push(accountOption);
            }
        }
        cmp.set('v.userAccountOptions',accountOptions);
    },
    /**
     *
     * @param data
     * @param key
     * @returns {*}
     */
    groupDataByKey: function (data, key) {
        // `data` is an array of objects, `key` is the key (or property accessor) to group by
        // reduce runs this anonymous function on each element of `data` (the `item` parameter,
        // returning the `storage` parameter at the end
        return data.reduce(function (storage, item) {
            // get the first instance of the key by which we're grouping
            var group = item[key];
            // alert(JSON.stringify(group));
            // set `storage` for this instance of group to the outer scope (if not empty) or initialize it
            storage[group] = storage[group] || [];
            // add this item to its group within `storage`
            storage[group].push(item);
            // return the updated storage to the reduce function, which will then loop through the next
            return storage;
        }, {}); // {} is the initial value of the storage
    },
    /**
     * filter existing chart
     * @param cmp
     * @param dDateSelected
     * @TODO move to option builder??
     */
    filterMachineDailyLocShareByClickedDate: function (cmp, dDateSelected) {
        var self = this;
        if(this.machineDailyLocShareChart) {

            try {
                var chartData = this.buildDailyEchartPieData(cmp,dDateSelected);
                var aggregatedDailys = chartData.aggregatedDailys;
                var negativeDailys = chartData.negativeDailys;
                var echartData = [];
                var legendData = [];
                var totalLocShare = 0;
                var locShareTotalFormatted = 0;
                for (var i = 0; i < aggregatedDailys.length; i++) {
                    var dailyAggregate = aggregatedDailys[i];
                    var data = {'value': dailyAggregate.locShareTotal, 'name': dailyAggregate.machineName};
                    totalLocShare += dailyAggregate.locShareTotal;
                    var machineName = dailyAggregate.machineName;
                    legendData.push(machineName);
                    echartData.push(data);
                }
                //--- subtract negative values from total
                for(var i = 0; i < negativeDailys.length; i++) {
                    var negDaily = negativeDailys[i];
                    totalLocShare += negDaily.locShareTotal;
                }

                locShareTotalFormatted =  self.formatNumericValue('$',totalLocShare,1);
                var sDate = $A.localizationService.formatDate(dDateSelected, 'MM-dd-YYYY');

                var titles = [];
                var title = {
                    text: 'Machine Totals on ' + sDate,
                    subtext: 'Location Share: '+ locShareTotalFormatted,
                    x: 'left',
                    textStyle: {
                        fontSize: 15
                    },
                    subtextStyle: {
                        color: 'black'
                    },
                    top: 10
                };
                var titlePieMiddle = {
                    top:'53%',
                    right: '44%',
                    textStyle : {
                        fontSize: 22
                    },
                    subtextStyle : {
                        color: 'black'
                    },
                    text: locShareTotalFormatted
                };
                titles.push(title);
                titles.push(titlePieMiddle);

                var graphics =  [];
                if(negativeDailys.length > 0) {
                    let responseDto;
                    let chartData = {negativeDailys : negativeDailys};
                    this.chartMachineTotalsDisplay.generateNegativeLocShareGraphic(chartData, function (value) {
                        responseDto = value;
                    });
                    if(responseDto && responseDto.graphic) {
                        graphics.push(responseDto.graphic);
                    }
                }
                var option = {
                    title: titles,
                    graphic: graphics,
                    series : [
                        {
                            data: echartData,
                        }
                    ]
                };
                this.machineDailyLocShareChart.setOption(option,false);
                this.machineDailyLocShareChart.off('click');
            } catch (e) {
                alert(e);
            }
        }
    },
    /**
     * Machine daily loc share ie. pie chart.
     *
     * @param cmp
     * @param dDateSelected
     */
    renderMachineDailyLocShare: function (cmp,dDateSelected) {
        let self = this;
        let eleDiv = cmp.find("echartsmachinedailylocshare").getElement();
        let chartData = this.buildDailyEchartPieData(cmp,dDateSelected);
        let responseDto;

        //@see Accel_ChartMachineTotalsDisplay.cmp
        this.chartMachineTotalsDisplay.buildMachineTotalsPieOptions(chartData, function (value) {responseDto = value;});
        this.machineDailyLocShareChart = echarts.init(eleDiv,'light');
        try {
            this.machineDailyLocShareChart.setOption(responseDto.option);
            //---- set the onclick to fire an event containing data about the clicked part of the pie.....
            this.machineDailyLocShareChart.on('click', function (params) {
                try {
                    let machineClicked = {
                        assetId : params.data.id,
                        machineName : params.data.name,
                        accountId : cmp.get('v.selectedAccountId')
                    };
                    let evt = $A.get("e.c:Accel_Evt_MachineClicked");
                    evt.setParams({"machineClicked": machineClicked});
                    self.log(cmp, 'firing evt with selectedMachine', 'info', machineClicked);
                    evt.fire();
                } catch (e) {
                    alert(e);
                    self.log(cmp,'unable to fire evt..','error',e);
                }
            });
        } catch (e) {
            this.handleSetOptionErrors(cmp,e,responseDto);
        }
    },
    /**
     *
     * @param cmp
     * @param error
     * @TODO move to above.. / establish higher level error handling!
     */
    handleSetOptionErrors: function(cmp, error,responseDto) {
        this.log(cmp, 'errors in calling setOption on chart instance. check your option builder config', 'error', error);
        this.log(cmp, '--- response dto from option builder =','info',responseDto);
    },
    /**
     *
     * @param cmp
     */
    renderEChartBarChart: function(cmp) {
        let self = this;
        let eleDiv = cmp.find("echartsbarchart").getElement();
        let chartData = self.buildTimeSeriesDailyData(cmp);
        let responseDto;

        //@see Accel_ChartDailyLocShareDisplay.cmp
        this.chartDailyLocShareDisplay.buildDailyLocShareBarOptions(chartData, function(value) {responseDto = value;});
        this.locationDailyLocShareChart = echarts.init(eleDiv, 'light');
        try {
            this.locationDailyLocShareChart.setOption(responseDto.option);
            this.locationDailyLocShareChart.on('click', function (params) {
                self.log(cmp, 'click of bar chart..', 'info', params);
                let dateSelected;
                if (params.name) {
                    dateSelected = new Date(params.name);
                    dateSelected.setDate(dateSelected.getDate() + 1);
                }
                if (dateSelected) {
                    self.renderMachineDailyLocShare(cmp, dateSelected);
                }
            });
        } catch (e) {
            this.handleSetOptionErrors(cmp, e, responseDto);
        }
    },
    /**
     * Wrapper to generic format val util...
     *
     * @param prefix
     * @param value
     * @param fixed
     */
    formatNumericValue: function (prefix, value, fixed) {
        let formatResponse;
        let formattedValue;
        try {
            let infoToFormat = {prefix: '$', value: value, fixed: fixed};
            this.formatUtils.formatNumericValue(infoToFormat, function (value) {
                formatResponse = value;
            });
            if (formatResponse.value) {
                formattedValue = formatResponse.value;
            }
        } catch (e) {
            this.log(cmp,'error formatting value','error',e);
        }
        return formattedValue;
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
        let lvl;
        if (arguments.length === 0) {
            console.error('you must minimally pass the cmp ref and message to the log function');
            return;
        } else if (arguments.length === 1) {
            console.error('could not find message to log');
            return;
        } else if (arguments.length === 2) {
            lvl = 'debug';
        } else  {
            lvl = level;
        }
        try {
            if (cmp.get("v.debugConsole") || lvl === 'error') {
                var cmpName = '--- Accel_CommunityPerformance --- ';
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
    getAccountById: function (arr, value) {
        for (let i = 0, iLen = arr.length; i < iLen; i++) {
            if (arr[i].Id === value) return arr[i];
        }
    },
    /**
     * OK this seems to be redic that you need to do this but no other way in communities seems clean.
     * @param paramName
     * @returns {*}
     * note: ripped off from Avijit Chakraborty.. wtf?
     * https://salesforce.stackexchange.com/questions/219823/best-way-to-pass-url-parameters-to-a-salesforce-community-lightning-component
     */
    getUrlParam: function (paramName) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');

            if (sParameterName[0] === paramName) {
                return sParameterName[1] === undefined ? true : sParameterName[1];
            }
        }
    },
    /**
     * A generic catch 'all' method. Originally meant for catching SS errors but here for future
     * refinement.
     *
     * @param cmp
     * @param errors
     */
    handleErrors : function(cmp,error) {
        this.log(cmp, 'errors in init server side retrieval calls', 'error', error);
        console.log(error);
        try {
            var name = error.name;
            switch (name) {
                case 'ApexActionError':
                    //do nothing wtf are we going to do with this anyway!
                    break;
            }
        } catch (e) {
            this.log(cmp, 'error handling errors lol','error',e);
        }
    },
    /**
     *
     * @param cmp
     * @param type
     * @param msg
     */
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    windowResizing: function (cmp, evt, helper) {
        if(this.locationDailyLocShareChart) {
            // noinspection JSValidateTypes
            this.locationDailyLocShareChart.resize();
        }
        if(this.machineDailyLocShareChart) {
            this.machineDailyLocShareChart.resize();
        }
    }
});