({
    responseDto: {option: null, message: '', isSuccess: false},
    callback: null,
    chartData: null,
    formatUtils: null,
    /**
     * Not really validating anything yet but placed where for future purposes.
     *
     * @param cmp
     * @param evt
     * @returns {{isSuccess: boolean}}
     */
    validateParams: function (cmp, evt) {
        let params = evt.getParam('arguments');
        this.callback = params.callback;
        this.chartData = params.chartData;
        return {isSuccess: true};
    },
    /**
     * Builds the main chart options and returns them in a dto for instantiation by the client.
     *
     * @param cmp
     * @param evt
     * @returns {responseDto|{message, option, isSuccess}}
     */
    buildChartOptions: function () {
        let allSeriesData = [];

        let retMachineAvgData = this.buildMachineAvgSeriesData(this.chartData);
        let retMachineData = this.buildMachineSeriesData(this.chartData);

        let machineAvgSeriesData = retMachineAvgData.machineAvgSeriesData;
        let machineSeriesData = retMachineData.machineSeriesData;
        let machineAvgLegendData = retMachineAvgData.machineAvgLegendData;

        let titles = this.buildChartTitles(this.chartData);
        let legends = this.buildChartLegends(machineAvgLegendData);

        for (let i = 0; i < machineAvgSeriesData.length; i++) {allSeriesData.push(machineAvgSeriesData[i]);}
        for (let i = 0; i < machineSeriesData.length; i++) {allSeriesData.push(machineSeriesData[i]);}
        let sTop = '25%';
        if(window.matchMedia("(max-width: 896px)").matches){
            sTop = '35%';
        }

        let option = {
            // Global palette:
           // color:  ['#37A2DA', '#32C5E9', '#67E0E3', '#9FE6B8', '#FFDB5C','#ff9f7f', '#fb7293', '#E062AE', '#E690D1', '#e7bcf3', '#9d96f5', '#8378EA', '#96BFFF'],
            grid: {
                show: false,
                top: sTop,
                containLabel: true,
                left: '5%',
                right: '2%'
            },
            title: titles,
            toolbox: {
                show: true,
                feature: {
                    mark: {show: true},
                    dataView: {show: false, readOnly: false},
                    restore: {show: true},
                    saveAsImage: {show: false}
                },
                showTitle: false,
                right: '2%'
            },
            tooltip: {
                trigger: 'axis',
                axisPointer: {
                    type: 'shadow',
                    label: {
                        show: true,
                        backgroundColor: '#333'
                    }
                },
                formatter: function (params) {
                    let ret = '';
                    try {
                        let oMachine = params[1];
                        if(oMachine) {
                            let oAvg = params[0];
                            let date = new Date(oMachine.name);
                            let localizedDate = $A.localizationService.formatDate(date, "MMM dd yyyy");
                            ret = localizedDate + ' - ' + oMachine.seriesName + '<br/>';
                            ret += 'Location Share: $' + oMachine.value;
                            ret += '<br/>';
                            ret += 'Statewide Average:  $' + oAvg.value;
                        }
                    } catch (e) {
                        console.error(e);
                    }
                    return ret;
                }
            },
            legend: legends,
            xAxis: {
                id: 'monthDataXaxisCategory',
                name: 'Previous 30 Days',
                nameLocation: 'middle',
                nameGap: 45,
                data: this.chartData.category,
                axisLine: {
                    lineStyle: {
                        color: 'black'
                    }
                },
                axisLabel: {
                    color: 'black',
                    margin: 14,
                    formatter: function (value, index) {
                        let sDate = value;
                        let dDate = new Date(sDate);
                        let val = $A.localizationService.formatDate(dDate, "MMM DD");
                        return val;
                    }
                },
                axisTick: {
                    show: true,
                    length: 6,
                    lineStyle: {
                        color: '#A9A9A9',
                        type: 'solid'
                    }
                },
            },
            yAxis: {
                name: 'Location Share',
                nameLocation: 'middle',
                nameGap: 60,
                axisLine: {
                    lineStyle: {
                        color: 'black'
                    },
                    onZero : false
                },
                axisLabel: {
                    color: 'black',
                    margin: 12,
                    formatter: function (value, index) {
                        let val = '$' + value;
                        return val;
                    }
                },
                axisTick: {
                    show: true,
                    length: 6,
                    lineStyle: {
                        color: '#A9A9A9',
                        type: 'solid'
                    }
                },
                splitLine: {
                    show:true,
                    lineStyle: {
                        /*color: ['red']*/
                        type: 'dashed'
                    }

                },
                min: 'dataMin',
                max: 'dataMax'
            },
            series: allSeriesData
        };
        //--- @TODO error checking.
        this.responseDto.option = option;
        this.responseDto.isSuccess = true;
        return this.responseDto;
    },
    /**
     * Builds the chart title. (returns an array in case we want multiple)
     *
     * @param chartData
     * @returns {Array}
     */
    buildChartTitles: function (chartData) {
        let titles = [];
        let sTitle = 'Machine Performance - 30 Day';
        let subtext = 'Location Share vs Statewide Avg';
        if(chartData.selectedAccount) {
            subtext +='\n\n' + chartData.selectedAccount.ShippingStreet + ' - '+chartData.selectedAccount.ShippingCity;
        }
        let title = {
            text: sTitle,
            x: 'left',
            textStyle: {fontSize: 16, color: 'black'},
            subtext: subtext,
            subtextStyle: {color: 'black',fontSize: 10},
            top: 10
        };
        titles.push(title);
        return titles;
    },
    /**
     *
     * @param chartData
     * @returns {{machineSeriesData: Array}}
     */
    buildMachineSeriesData: function (chartData) {
        let self = this;
        let oHpdsByMachine = chartData.oHpdsByMachine;
        let machineSeriesData = [];

        Object.keys(oHpdsByMachine).map(function (key, index) {
            let machineName = key;
            let machineSeries = {
                name: machineName,
                /*smooth: true,*/
                symbol: 'circle',
                showAllSymbol:'auto',
                showSymbol: true,
                symbolSize:10,
                type: 'line',
                stack: machineName,
                data: [],
                connectNulls: true,
                lineStyle: {width: 4},
                label: {
                    normal: {
                        show: true,
                        color: 'black',
                        itemStyle: {
                            color: 'black'
                        },
                        formatter: function(params) {
                            //console.log(params.data);
                            let shortVal = self.formatValue('',params.data,0);
                            return  shortVal;
                        },
                        fontSize: 11
                    }
                },
            };
            let oMachineData = oHpdsByMachine[key];
            let listMachineData = Array.from(oMachineData);
            for (let i = 0; i < listMachineData.length; i++) {
                let machine = listMachineData[i];
                machineSeries.data.push(machine.Location_Share__c);
            }
            machineSeriesData.push(machineSeries);
        });
        return {
            machineSeriesData: machineSeriesData
        }
    },
    /**
     * Build the machine avg (30 day statewide avg) series data.
     * @param chartData
     * @returns {{machineAvgSeriesData: Array, machineAvgLegendData: Array}}
     */
    buildMachineAvgSeriesData: function (chartData) {
        //====
        let setMachineNames = chartData.setMachineNames;
        let machineAvgData = chartData.machineAvgData;
        let category = chartData.category;
        let machineAvgSeriesData = [];
        let machineAvgLegendData = [];
        let listMachineNames = Array.from(setMachineNames);

        for (let i = 0; i < listMachineNames.length; i++) {
            let machineName = listMachineNames[i];
            let bShowLabel = false;
            let machineAvgSeries = {
                name: machineName,
                symbol: 'none',
                type: 'line',
                stack: machineName,
                data: [],
                connectNulls: true,
                lineStyle: {
                    width: 3,
                    type: 'dotted',
                    shadowColor: 'rgba(0, 0, 0, 0.5)',
                    shadowBlur: 10
                },
                label: {
                    show:bShowLabel
                },
            };
            let legendData = {name: machineName};
            let machineAvg = machineAvgData.find(obj => obj.Asset_Model_Name__c === machineName);
            for (let i = 0; i < category.length; i++) {
               if(i === 0) {
                   legendData.singleLocShareAvgValue = machineAvg.Thirty_Day_Location_Share_Avg__c;
               }
               machineAvgSeries.data.push(machineAvg.Thirty_Day_Location_Share_Avg__c);
            }
            machineAvgLegendData.push(legendData);
            machineAvgSeriesData.push(machineAvgSeries);
        }
        machineAvgLegendData.sort(function(a, b) {return b.singleLocShareAvgValue - a.singleLocShareAvgValue;}); //quick sort date asc
        return {
            machineAvgSeriesData: machineAvgSeriesData,
            machineAvgLegendData: machineAvgLegendData
        }
    },
    /**
     * Builds multiple chart legends.
     *
     * @param machineAvgLegendData
     * @returns {Array}
     */
    buildChartLegends: function (machineAvgLegendData) {
        let legends = [];
        let sTop = '13%';
        if(window.matchMedia("(max-width: 896px)").matches){
            sTop = '80';
        }


        let legendMachineAverages = {
            type: 'scroll',
            data: machineAvgLegendData,
            top: sTop,
            selectedMode: 'single',
            itemHeight: 14,
            itemWidth: 24,
            padding: [
                3,  // up
                5, // right
                3,  // down
                5, // left
            ],
            textStyle: {
                fontSize: 12
            }
        };
        legends.push(legendMachineAverages);
        return legends;
    },
    /**
     * Wrapper to generic format val util...
     *
     * @param prefix
     * @param value
     * @param fixed
     */
    formatValue: function (prefix, value, fixed) {
        let formatResponse;
        let formattedValue;
        try {
            let infoToFormat = {prefix: '', value: value, fixed: fixed};
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
});