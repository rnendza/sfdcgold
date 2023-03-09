({
    //====================================     Global / static variables      ==========================================
    //--- chartMachineComparisonDisplay hold reference to component that builds chart options.
    //--- machineComparisonChart will hold a reference to chart after it is initialized.
    //--- collection utils.. other util components called via aura:method.
    //--- HPD_LIST is a mock const used as the map key that is returned in the map returned from the apex call.
    chartMachineComparisonDisplay: null,
    machineComparisonChart: null,
    collectionUtils: null, loggingUtils : null,
    HPD_LIST: 'HPD_RECS',PRODUCT_MACHINE_AVERAGES: 'PRODUCT_MACHINE_AVERAGES',
    //==================================================================================================================
    /**
     * Retrieval of server side hpd data and machine averages.
     * @param cmp
     * @todo check other data on responseDto.
     */
    retrieveHpdDataAndMachineAverages: function (cmp)   {
        cmp.set("v.showComparisonSpinner", true);
        let accountId = cmp.get("v.selectedAccount").Id;
        const params = {accountId: accountId};
        //--- promises abstraction. https://github.com/ruslan-kurchenko/sfdc-lax
        //--- enqueue server side call and then process results when returned.
        cmp.lax.enqueue('c.retrieveMachineAverages')
            .then(response => {
                this.processMachineAverageData(cmp,response);
                cmp.set("v.showComparisonSpinner", false);
                return cmp.lax.enqueue('c.retrieveHoldPerDayByAccountLast30',params);
            })
            .then(response => {
                this.processHpdServerData(cmp,response);
            })
            .catch(errors => {
                cmp.set("v.showComparisonSpinner", false);
                this.handleErrors(cmp, errors); //@TODO handle errors should be beefed up.
            });
    },
    /**
     * Pull hpd data out of map returned from server. ie return from server is Map String => Object.
     * In this case object is an array of HPD Data. Set local attribute with server hpd data.
     * Call the render of the chart.
     *
     * @param cmp
     * @param response  - response retrieved from the server.
     *
     * @see ResponseDto Apex Class.
     * @todo check other data on responseDto / more robust error handling.
     */
    processHpdServerData:function (cmp,response) {
        let dto = response;
        if(dto.isSuccess) {
            let hpds = [];
            //------ the 'platform' return true maps from the server. we need to help it out
            this.collectionUtils.getMapValue(this.HPD_LIST, dto.values, function (value) {hpds = value;});
            cmp.set('v.hpdData',hpds);
            if(!this.machineComparisonChart) {
                //chart was never created or properly initialized with options. create a new one.
                this.renderComparisonChart(cmp);
            } else { //already set all the options and shit just update the series data.
                //----------------------------this.updateChartSeriesData(cmp); @TODO
                this.renderComparisonChart(cmp);
            }
        } else {
            //-- soft error handling.. probably toast a ui message.
            this.log(cmp,dto.technicalMsg,dto.severity,dto);
        }
    },
    /**
     * Consume the data from the server side call to get machine data.
     *
     * @param cmp
     * @param response  The response (containing the dto) from the apex controller SS call to get machine data.
     */
    processMachineAverageData:function (cmp,response) {
        let dto = response;
        if(dto.isSuccess) {
            let products = [];
            this.collectionUtils.getMapValue(this.PRODUCT_MACHINE_AVERAGES, dto.values, function (value) {products = value;});
            cmp.set('v.machineAverages',products);
        } else {
            this.log(cmp,dto.technicalMsg,dto.severity,dto);
        }
    },
    /**
     * Simply refresh the data options in the series as the chart was already built!.
     * Refresh anything else needed here. titles. etc. ie setOption will override the particular value in the
     * existing option  object on the existing instance of machineComparison chart. all other options are the same
     * as when it was created.
     *
     * @param cmp
     */
    updateChartSeriesData: function(cmp) {
        if(this.machineComparisonChart) {
            this.log(cmp,'updating existing chart data from parent data change','info');
            // let chartData = this.buildRealChartHpdDataFromParent(cmp);
            // let option = {
            //     xAxis: {id: 'monthDataXaxisCategory', data: chartData.category},
            //     series: [
            //         {id: 'netRevenueSeriesLine',    data: chartData.lineData},
            //         {id: 'locShareSeriesBar',       data: chartData.barData},
            //         {id: 'netRevenueSeriesBar',     data: chartData.lineData},
            //         {id: 'dotted',                  data: chartData.lineData}
            //     ]
            // };
            // try {
            //     this.machineComparisonChart.setOption(option);
            // } catch (e) {
            //     this.handleErrors(cmp,e);
            // }
        }
    },
    /**
     * Builds the data in a format suitable for the chart. Uses external component to build the chart options with this data.
     * Inits an instance of the chart and sets the options on the chart. Also registers a mouse click handler.
     *
     * @param cmp
     *
     * @see Accel_ChartMachineComparisonDisplay
     * @see https://ecomfe.github.io/echarts-doc/public/en/api.html#events
     */
    renderComparisonChart: function (cmp) {
        var self = this; //needed for logging in click handler callback
        let responseDto, chartData;
        chartData = this.buildComparisonChartData(cmp); //uses data from apex server side call.
        //@see Accel_ChartMachineComparisonDisplay.cmp
        this.chartMachineComparisonDisplay.buildChartOptions(chartData, function (value) {responseDto = value;});
        this.machineComparisonChart = echarts.init(cmp.find("echartsMachineComparison").getElement(),'light');
        this.machineComparisonChart.setOption(responseDto.option);
        this.setSpecialGradientOptions(cmp);

        this.machineComparisonChart.on('click', function (params) {
            //@see https://ecomfe.github.io/echarts-doc/public/en/api.html#events
            self.log(cmp,'chart was clicked somewhere.. name param in clicked event..','info',params.name);
        });
    },
    /**
     * Builds data based off the server query using accountId.
     *
     * @param cmp
     * @returns {{setMachineNames: Set<any>, oHpdsByMachine: *, category: Array, machineAvgData: Array}}
     */
    buildComparisonChartData: function(cmp) {
        let category = [], machineAvgData = [];
        let setMachineNames = new Set();
        let hpds = cmp.get('v.hpdData');
        machineAvgData = cmp.get('v.machineAverages');
        //--- Dynamically create prop hpd.machineName to make grouping easier.
        //--- crunch all machine names down to unique set for legend building.
        for(let i = 0; i<hpds.length;i++) {
            let hpd = hpds[i];
            hpd.machineName = hpd.Asset__r.Model__c;
            setMachineNames.add(hpd.Asset__r.Model__c);
        }
        let oHpdsByMachine = this.groupDataByKey(hpds,'machineName');
        let oHpdsByDate = this.groupDataByKey(hpds,'Date__c');
        // quick and dirty sort keys by date asc
        oHpdsByDate = Object.keys(oHpdsByDate).sort().reduce((r, k) => (r[k] = oHpdsByDate[k], r), {});
        //--- x axis values..
        Object.keys(oHpdsByDate).map(function (key, index) {
            let dHpdDate = new Date(key);
            category.push([ dHpdDate.getFullYear(),  dHpdDate.getMonth()+1, dHpdDate.getDate()+1,].join('-'));
        });
        return {
            category: category,
            setMachineNames : setMachineNames,
            machineAvgData: machineAvgData,
            oHpdsByMachine: oHpdsByMachine,
            selectedAccount: cmp.get('v.selectedAccount')
        }
    },
    /**
     * Set special options that require the echarts lib here (ie graphic) so we do not have to pass this large
     * object to the component.
     *
     * Note. setOptions will merge by default.
     * Note. echarts.graphic doesn't appear to work the same way it does in the examples. it works a bit but not the same.
     *
     * @TODO figure this damn echarts.graphic object out. locker service? version of the lib itself?
     */
    setSpecialGradientOptions: function (cmp) {
        var self = this;
        //{"x":0,"y":0,"x2":1,"y2":0,"type":"linear","global":false,"colorStops":[]}
        //note nothing truly freekin works here! regardless of the number of derivatives. Locker service thing??????
        //this does add some color but not the right ones.. ! just grey.. and yes echarts.graphic.LinearGradient (
        //without parens around echarts was attempted as well as not using the LinearGradient object at all..
        //there seems to be a versioning issue / issue with their doc here. or possibly locker service .. that
        //nasty ahole is screwing us over.
        var linearGradient1 =  new (echarts).graphic.LinearGradient(
                0, 0, 1, 0,
                [
                    {offset: 0, color: 'rgba(250,10,10,1)'},
                    {offset: 0.8, color: 'rgba(250,250,0, 0.2)'}
                ]
        );
        var linearGradient2 = new (echarts).graphic.LinearGradient(
            0, 0, 1, 0,
              [
                    {offset: 0, color: 'rgba(20,200,212,0.5)'},
                    {offset: 0.2, color: 'rgba(20,200,212,0.2)'},
                    {offset: 1, color: 'rgba(20,200,212,0)'}
                ]
        );
        if (this.machineComparisonChart) {
            let option = {
                series: [{
                    id: 'locShareSeriesBar',
                    itemStyle: {
                        normal: {
                            barBorderRadius: 5,
                            color: linearGradient1
                        }
                    }
                },
                    {
                        id: 'netRevenueSeriesBar',
                        itemStyle: {
                            normal: {
                                color: linearGradient2
                            }
                        },
                    }
                ]
            };
            //------------ probably need a type above self.machineComparisonChart.setOption(option);
        }
    },
    //=============================================== GENERAL HELPER UTILS =============================================

    /**
     * Groups an object by keys.
     *
     * @param data  - the array to group
     * @param key   - the key of the array to group
     * @returns {*} - object grouping
     *
     * @TODO move to collectionUtils
     */
    groupDataByKey: function (data, key) {
        // `data` is an array of objects, `key` is the key (or property accessor) to group by
        // reduce runs this anonymous function on each element of `data` (the `item` parameter,
        // returning the `storage` parameter at the end
        return data.reduce(function (storage, item) {
            // get the first instance of the key by which we're grouping
            var group = item[key];
            // set `storage` for this instance of group to the outer scope (if not empty) or initialize it
            storage[group] = storage[group] || [];
            // add this item to its group within `storage`
            storage[group].push(item);
            // return the updated storage to the reduce function, which will then loop through the next
            return storage;
        }, {}); // {} is the initial value of the storage
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
        console.error(error); //in case the logging util missis it!
        try {
            var name = error.name;
            switch (name) {
                case 'ApexActionError':
                    //do nothing wtf are we going to do with this anyway!
                    break;
            }
            //@TODO pop ui msg on other stuff.
        } catch (e) {
            this.log(cmp, 'error handling errors lol','error',e);
        }
    },
    /**
     * When the user resizes the window we must call resize on the charts (width 100%) so that the canvas recalculates
     * the size of it's container.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    windowResizing: function (cmp, evt, helper) {
        if(this.machineComparisonChart) {
            this.machineComparisonChart.resize();
        }
    },
    /**
     * Simple debug method to avoid code smell.
     * @param cmp
     */
    debugInboundParams: function(cmp) {
        this.log(cmp,'inbound account', 'info', cmp.get('v.selectedAccount'));
    },
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
        var self = this;
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
                var cmpName = '--- '+cmp.getName() + ' CMP --- ';
                var cLogger = self.loggingUtils;
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
});