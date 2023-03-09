({
    //========================================= Global Shit ===========================================================
    locationMonthlyChart:null,
    locationBreakdownChart:null,
    locationPieChart:null,
    LOC_DETAIL_SVR_DATA: 'MAP_KEY_LOCATION_WRAPPERS',
    LOC_AREA_CHART_SVR_DATA: 'All_LOCATIONS_MONTHLY',
   // LOC_PIE_SVR_DATA: 'LOCATION_LIFETIME_WRAPPER_LIST',
    LOC_PIE_SVR_DATA: 'LOCATION_MONTHLY_HPDS',
    LOC_HPD_LIC_DATA: 'LOCATION_HPD_EXP_WRAPPER_LIST',
    collectionUtils:null,
    loggingUtils:null,
    formatUtils: null,
    //================================================ SERVER Actions ==================================================
    /**
     * Call to retrieve Chart related location data on init.
     *
     *  1. Retrieves lifetime area chart data.
     *      a. renders area chart.
     *      b. fires event to populate data table.
     *  2. Retrieves pie chart data.
     *     a. stores visible account ids (retrieved from 1)
     *     b. stores a Map of accountId => Account for future lookup.
     *
     * @param cmp  - obviously this component instance!
     * @see https://medium.com/@r.kurchenko/lax-the-service-lightning-component-to-write-a-clear-asynchronous-javascript-code-1df5b6b6da40
     */
    retrieveChartData: function (cmp) {
        cmp.set("v.showSpinner", true);
        this.locationMonthlyChart = null;
        cmp.lax.enqueue('c.retrieveLocationAllMonthlyWrappers') //pop area chart....
            .then(response => {
                this.processLifeTimeLineChart(cmp,response);
                cmp.set("v.showSpinner", false);
                const params = {sFreq: '1YR'};
               // const options = {storable:true};
                const options = {};
                return cmp.lax.enqueue('c.retrieveLocationMonthlyHpds',params,options);
            })
            .then(response => {
                this.processMonthlyPieChart(cmp,response);
                //return cmp.lax.enqueue('c.retrieveUserHpdAndExpDate');
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleInitErrors(cmp,errors);
            });
    },
    /**
     * Calls the server to retrieve License Exp and HPD Total data.
     * @param cmp
     */
    retrieveTableData: function (cmp) {

        cmp.lax.enqueue('c.retrieveUserHpdAndExpDate') //pop area chart....
            .then(response => {
                this.processLocDetailData(cmp, response);
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleInitErrors(cmp,errors);
            });
    },
    /**
     * Called on click of area chart button.....  Hits the server to retrieve associated HPD info
     *
     * @param cmp
     * @param freq  - 1YR or ALL
     */
    retrieveMonthlyPieData: function(cmp, freq) {
        if(freq) {
            const options = {};
            let params = {};
            freq = freq.toUpperCase();
            switch (freq) {
                case 'ALL' :
                    params = {sFreq: null};
                    this.log(cmp,'calling server to get pie data.. with params','info',params);
                    cmp.lax.enqueue('c.retrieveLocationMonthlyHpds',params, options )
                        .then(response => {
                            cmp.set("v.showSpinner", false);
                            this.processMonthlyPieChart(cmp,response)
                        })
                        .catch(errors => {
                            cmp.set("v.showSpinner", false);
                            this.handleInitErrors(cmp,errors);
                        });
                    break;
                case '1YR' :
                    params = {sFreq: '1YR'};
                    cmp.lax.enqueue('c.retrieveLocationMonthlyHpds',params,options)
                        .then(response => {
                            cmp.set("v.showSpinner", false);
                            this.processMonthlyPieChart(cmp,response)
                        })
                        .catch(errors => {
                            cmp.set("v.showSpinner", false);
                            this.handleInitErrors(cmp,errors);
                        });
                    break;
            }
        }
    },
    /**
     *@TODO Ui prompt.. / more detailed error processing!
     * @param cmp
     * @param errors
     */
    handleInitErrors : function(cmp,errors) {
        this.log(cmp, 'errors in init server side retrieval calls', 'error', errors);
        console.log(errors);
    },
    /**
     * Consume server qry results and build / render pie chart.
     * @param cmp
     * @param response  - server query results.
     */
    processMonthlyPieChart: function(cmp,response) {
        var dto = response;
        var hpdWrapsByAccount = [];
        this.collectionUtils.getMapValue(this.LOC_PIE_SVR_DATA, dto.values, function (value) {hpdWrapsByAccount = value;});
        var mAccountId_Wraps = new Map();
        if(hpdWrapsByAccount) {
            cmp.set('v.hpdWrapsByAccount',hpdWrapsByAccount);
            cmp.set('v.hpdWrapsByAccountByFreq',hpdWrapsByAccount);
            mAccountId_Wraps = new Map(hpdWrapsByAccount.map(obj => [obj.accountId, obj]));
            cmp.set('v.numAccounts', mAccountId_Wraps.size);
            cmp.set('v.accountIdAccountMap', mAccountId_Wraps);
            this.setLifeTimeLocationShareHpdData(cmp);
            cmp.set('v.visibleAccountIds',Array.from(mAccountId_Wraps.keys()));
            this.log(cmp, 'monthly all location wrappers grouped up to individual account', 'info', cmp.get('v.hpdWrapsByAccount'));
            this.renderEChartPieChart(cmp);
        }
    },
    /**
     * Consume server query results and build / render line / area chart.. also fire. Event to cmp which populates table data.
     * @param cmp
     * @param response
     */
    processLifeTimeLineChart: function(cmp,response) {
         window.setTimeout(function() {
             $A.util.addClass(cmp.find('1YR'), "accel-btn-is-selected");
         }, 0);
        var dto = response;
        var locAllMonthlyWraps = [];
        this.collectionUtils.getMapValue(this.LOC_AREA_CHART_SVR_DATA, dto.values, function (value) {locAllMonthlyWraps = value;});
        if(locAllMonthlyWraps) {
            this.log(cmp, 'monthly all location wrappers (LOCATION SHARE MAIN CHART)', 'info', locAllMonthlyWraps);
            cmp.set('v.locationMonthlyData', locAllMonthlyWraps);
            cmp.set('v.locationMonthlyDataByFreq',this.filterLocDataByCurrentFreq(cmp));
            this.fireTableData(cmp);
            this.renderEChartComplexArea(cmp);
        }
    },
    /**
     *
     * @param cmp
     * @returns {Array}
     */
    filterLocDataByCurrentFreq: function(cmp) {
        var arr = [];
        var currentFreq = cmp.get('v.currentFreq');
        this.log(cmp,'in filterLocDataByCurrentFreq','info',currentFreq);
        if(currentFreq) {
            if(currentFreq === '1YR') {
                cmp.set('v.chartAllLocsSubTitle', 'All locations by month (over the past year)');
                var dDate = new Date();
                dDate.setMonth(dDate.getMonth() - 14);
                var tmpArr = cmp.get('v.locationMonthlyData');
                if(tmpArr) {
                    for(var i=0;i<tmpArr.length;i++) {
                        var hpdWrap = tmpArr[i];
                        var realDate = new Date(hpdWrap.hpdDate);
                        if(realDate >= dDate) {
                            arr.push(hpdWrap);
                        }
                    }
                    this.log(cmp,'1yr filter..','info',arr);
                    cmp.set('v.locationMonthlyDataByFreq',arr);
                    window.setTimeout($A.getCallback( function() {
                        cmp.find("monthSelect").set("v.value",'1YR');
                    }));
                }
                var btnCmp = cmp.find('1YR');
                $A.util.addClass(btnCmp, "accel-btn-is-selected");
                $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            } else if(currentFreq === 'ALL') {
                    cmp.set('v.chartAllLocsSubTitle', 'All locations by month (lifetime)');
                    arr = cmp.get('v.locationMonthlyData');
                    cmp.set('v.locationMonthlyDataByFreq',arr);
                    var btnCmp = cmp.find('ALL');
                    window.setTimeout($A.getCallback( function() {
                        cmp.set('v.selectedDate',null);
                        cmp.find("monthSelect").set("v.value",'null');
                    }));

                    $A.util.addClass(btnCmp, "accel-btn-is-selected");
                    $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            } else {
                arr = cmp.get('v.locationMonthlyData');
            }
        }
        return arr;
    },

    /**
     *
     * @param cmp
     * @param response
     */
    processLocDetailData: function(cmp,response) {
        var dto = response;
        var locHpdExprWraps = [];
        var mAccountId_Wraps = cmp.get('v.accountIdAccountMap');
        this.collectionUtils.getMapValue(this.LOC_HPD_LIC_DATA, dto.values, function (value) {locHpdExprWraps = value;});
        var activeSections = [];
        if (locHpdExprWraps) {
            for (var i = 0; i < locHpdExprWraps.length; i++) {
                var wrap = locHpdExprWraps[i];
                if (i === 0) {
                    activeSections.push(wrap.id);
                }
                if (wrap.hpd4Week.locShare) {
                    wrap.hpdLocShare4Week = wrap.hpd4Week.locShare;
                }
                if (wrap.hpd8Week.locShare) {
                    wrap.hpdLocShare8Week = wrap.hpd8Week.locShare;
                }
                if (wrap.hpd12Week.locShare) {
                    wrap.hpdLocShare12Week = wrap.hpd12Week.locShare;
                }
                if (wrap.hpdTtm.locShare) {
                    wrap.hpdLocShareTtm = wrap.hpdTtm.locShare;
                }
                if(wrap.id) {
                    //dynamically create properly appending data from alternate query.
                    if(mAccountId_Wraps) {
                        //since we changed business reqs on this page.. ie not all area chart loading but rather one year
                        //loading by default. this may not refresh until the all button is clicked.
                        this.setLifeTimeLocationShareHpdData(cmp);
                    } else {
                        //this.log(cmp,'cant find attribute value mAccountId_Wraps.. possible refactoring needed!','info');
                    }
                }
                validateExpDates(wrap);
            }
        }
        this.log(cmp, 'location HPD / License Expiration Wraps', 'debug', locHpdExprWraps);
        cmp.set('v.locHpdExprData', locHpdExprWraps);
        cmp.set('v.activeSections', activeSections);

        function validateExpDates(wrap) {
            var dDate;
            //======================================= @TODO MORE CHECKS.. =================================
            if(wrap.dojLicenseExpDate) {
                dDate = new Date(wrap.dojLicenseExpDate);
                wrap.dojLicenseExp = dDate <= new Date();
            }
            if(wrap.stateLiquorLicenseExpDate) {
                dDate = new Date(wrap.stateLiquorLicenseExpDate);
                wrap.stateLiquorLicenseExp = dDate <= new Date();
            }
            if(wrap.localLiquorLicenseExpDate) {
                dDate = new Date(wrap.localLiquorLicenseExpDate);
                wrap.localLiquorLicenseExp = dDate <= new Date();
            }
            if(wrap.igbGamingLicenseExpDate) {
                dDate = new Date(wrap.igbGamingLicenseExpDate);
                wrap.igbGamingLicenseExp = dDate <= new Date();
            }
        }
    },
    /**
     * We must join 2 seperate datasets for this...
     * @param cmp
     * @TODO since we changed to year onload. we do not have lifetime hpd until the user clicks all.
     */
    setLifeTimeLocationShareHpdData: function(cmp) {
        var locHpdExprWraps = cmp.get('v.locHpdExprData');
        var mAccountId_Wraps = cmp.get('v.accountIdAccountMap');
        if(locHpdExprWraps && mAccountId_Wraps) {
            for (var i = 0; i < locHpdExprWraps.length; i++) {
                var wrap = locHpdExprWraps[i];
                if(wrap.id) {
                    //dynamically create properly appending data from alternate query.
                        var oAccount = mAccountId_Wraps.get(wrap.id);
                        if (oAccount) {
                            wrap.hpdLocShareLifetime = oAccount.locShare;
                        }
                }
            }
            cmp.set('v.locHpdExprData', locHpdExprWraps);
        }
    },
    /**
     *
     * @param cmp
     */
    fireTableData: function(cmp) {
        try {
            var evt = $A.get("e.c:Accel_ChartLocShareTotalsLoaded");
            evt.setParams({
                "locationMonthlyData":  cmp.get('v.locationMonthlyDataByFreq'),
                "locationMonthlyFrequency": cmp.get('v.chartFrequencyActive'),
                "locationMonthlyDataDescription": cmp.get('v.chartAllLocsSubTitle') + ' (lifetime)'
            });
            this.log(cmp, 'firing ChartLocShareTotalsLoadedEvent', 'info');
            evt.fire();
        } catch (e) {
            this.log(cmp,'error firing ChartLocShareTotalsLoaded evet...','error',e);
        }
    },
    /**
     *
     * @param cmp
     * @param dateSelected
     * @param arr
     * @param freq
     * @TODO change to use datasets and encodes for more flexibility and less rebuilding!
     */
    resetAreaChartSeriesMonthly: function(cmp, dateSelected,arr,freq) {
        var self = this;
        if(self.locationMonthlyChart) {
            var data  = self.buildMonthlyChartYoyData(cmp);
            self.log(cmp,'yoy data','info',data);
            var title = 'YoY Location Share';
            var subtext = 'All locations (lifetime)';
            var opt = {
                title : {
                    text: title,
                    subtext: subtext,
                    x:'left',
                    textStyle : {
                        fontSize: 15
                    },
                    subtextStyle : {
                        color: 'black'
                    },
                    top : 8,
                    left: 10
                },
                 tooltip: {
                    trigger: 'axis',
                    /* axisPointer: {
                        type: 'cross',
                        label: {
                            backgroundColor: '#6a7985'
                        }
                    } */
                },
                legend: {
                    data: data.dateSet,
                    top:30
                },
                grid: {
                    left: 20,
                    containLabel: true,
                    show: true,
                    right: 20,
                    bottom: 5,
                    borderColor: 'white',
                    top:60,
                    backgroundColor: 'rgb(255,255,255)'
                },
                toolbox : {
                    show : true,
                    feature : {
                        dataView : {show: false, readOnly: false},
                        restore : {show: true},
                        saveAsImage : {
                            show: false,
                            type: 'png',

                        }
                    },
                    showTitle: false,
                    right: '2%'
                },
                color: ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'],
                xAxis: {
                    type: 'category',
                    boundaryGap: false,
                    data: data.monthsArray,
                    axisLine: {onZero: false},
                    splitLine: {
                        show:true,
                        lineStyle: {
                            color: ['F3F2F2'],
                            type: 'dashed'
                        }
                    },
                },
                yAxis: {
                    type: 'value',
                    min: 'dataMin',
                    max: 'dataMax',
                    axisLine: {onZero: false},
                    splitLine: {
                        show:true,
                        lineStyle: {
                            /*color: ['red']*/
                            type: 'dashed'
                        }
                    },
                    axisLabel: {
                        formatter: function (value, index) {
                            return self.formatYAxisValues('$', value, 0);
                        }
                    }
                },
                series: data.allDataSeries,
                dataZoom: [
                    {
                        type: 'inside'
                    }
                ],

            };
            var mobile_opt = {
                title : {
                    text: title,
                    subtext: subtext,
                    x:'center',
                    itemGap: 5,
                    textStyle : {
                        fontSize: 15
                    },
                    subtextStyle : {
                        color: 'black'
                    },
                    top : 5
                },
                tooltip: {
                    trigger: 'axis',
                    /* axisPointer: {
                        type: 'cross',
                        label: {
                            backgroundColor: '#6a7985'
                        }
                    } */
                },
                legend: {
                    data: data.dateSet,
                    top:45,
                    type: 'scroll',
                    orient: 'horizontal',
                    pageButtonGap: 20
                },
                grid: {
                    left: 5,
                    containLabel: true,
                    show: true,
                    right: 5,
                    bottom: 8,
                    borderColor: 'white',
                    top:72,
                    backgroundColor: 'rgb(255,255,255)'
                },
                toolbox : {
                    show : false,
                    feature : {
                        dataView : {show: false, readOnly: false},
                        restore : {show: true},
                        saveAsImage : {
                            show: false,
                            type: 'png',

                        }
                    },
                    showTitle: false,
                    right: '2%'
                },
                color: ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'],
                xAxis: {
                    type: 'category',
                    boundaryGap: false,
                    data: data.monthsArray,
                    axisLine: {onZero: false},
                    splitLine: {
                        show:true,
                        lineStyle: {
                            color: ['F3F2F2'],
                            type: 'dashed'
                        }
                    },
                },
                yAxis: {
                    type: 'value',
                    min: 'dataMin',
                    max: 'dataMax',
                    axisLine: {onZero: false},
                    splitLine: {
                        show:true,
                        lineStyle: {
                            /*color: ['red']*/
                            type: 'dashed'
                        }
                    },
                    axisLabel: {
                        formatter: function (value, index) {
                            return self.formatYAxisValues('$', value, 0);
                        }
                    }
                },
                series: data.allDataSeries,
                /* dataZoom: [
                    {
                        type: 'inside'
                    }
                ],
                */
            };
            //media query to assign different options for the chart render
            if(window.matchMedia("(max-width: 896px)").matches){
                self.locationMonthlyChart.setOption(mobile_opt,true);
            }else{
                self.locationMonthlyChart.setOption(opt,true);
            }
            //self.locationMonthlyChart.setOption(opt,true);
            self.locationMonthlyChart.off('click');
        }
    },
    /**
     * Just filter through client side data so as
     * @param cmp
     * @param dateSelected
     * @param arr
     * @param freq
     */
    resetPieChartSeriesMonthly: function (cmp, dateSelected, arr, freq) {
        var self = this;
        if (self.locationPieChart) {
            var sTitle, sSubTitle;

            if (!arr) {
                arr = cmp.get('v.hpdWrapsByAccount');
            }
            var data = self.buildMonthlyEchartPieData(cmp, arr);

            var locShareSum = self.formatYAxisValues('$', cmp.get('v.pieChartLocShareTotal'), 0);
            if (dateSelected) {
                sTitle = 'Location Share Breakdown - ' + locShareSum;
                sSubTitle = $A.localizationService.formatDate(dateSelected, "MMM yyyy") + ' by location';
            } else {
                sTitle = 'Location Share Sum - ' + locShareSum;
                switch (freq) {
                    case '6MTH':
                        sSubTitle = 'Last 6 Months by location';
                        break;
                    case '1YR' :
                        sSubTitle = '1 Year prior to today (@TODO)';
                        break;
                    default :
                        sSubTitle = 'Lifetime by location';
                }
            }

            var titles = [];
            var title = {
                text: sTitle,
                subtext: sSubTitle
            };
            var titlePieMiddle = {
                text: locShareSum,
                textStyle: {
                    fontSize: 24
                },
                subtextStyle: {
                    color: 'black'
                }
            };
            titles.push(title);
            titles.push(titlePieMiddle);

            var opt = {
                title: titles,
                series: [
                    {
                        data: data.seriesData,
                        legend: {
                            data: data.legendData,
                            selected: data.selected
                        }
                    }
                ]
            };
            self.log(cmp, 'rebuilding pie chart with monthly data', 'info', dateSelected);
            self.locationPieChart.setOption(opt);
        }
    },
    /**
     *
     * @param cmp
     */
    renderEChartPieChart: function(cmp) {
        var self = this;
        var data = self.buildMonthlyEchartPieData(cmp);
        var eleDiv = cmp.find("echarts-pie-chart-sample").getElement();
        //alert('---- debug pie chart loc share total dev / uat diffs. wtf?----'+cmp.get('v.pieChartLocShareTotal'));
        var locShareSum =  self.formatYAxisValues('$',cmp.get('v.pieChartLocShareTotal'),1);
        var sTitle = 'Location Share Sum - ' +  locShareSum;
        var sSubtext = cmp.get('v.pieChartSubTitle');
        var titles = [];
        var title = {
            text: sTitle,
            subtext: sSubtext,
            x:'left',
            textStyle : {
                fontSize: 15
            },
            subtextStyle : {
                color: 'black'
            },
            top : 10
        };
        var titlePieMiddle = {
            text: locShareSum,
            top:'50%',
            right: '56%',
            textStyle : {
                fontSize: 24
            },
            subtextStyle : {
                color: 'black'
            }
        };
        titles.push(title);
        titles.push(titlePieMiddle);
        var option = {
            title : titles,
            tooltip : {
                trigger: 'item',
                formatter: "{a} <br/>{b} : {c} ({d}%)"
            },
            toolbox : {
                show : true,
                feature : {
                    mark : {show: true},
                    dataView : {show: false, readOnly: false},
                    restore : {show: true},
                    saveAsImage : {show: false}
                },
                showTitle: false,
                right: '2%'
            },
            calculable : false,
            legend: {
                type: 'scroll',
                orient: 'vertical',
                align: 'right',
                /*right: -300,*/
                top: 50,
                bottom: 20,
                right:10,
                data: data.legendData,
                selected: data.selected,
                scrollIndex: 0
            },
            series : [
                {
                    name: 'Location Share',
                    type: 'pie',
                   /* roseType: 'radius',*/
                  /*  radius : '55%',*/
                    radius : ['40%', '65%'],
                    center: ['35%', '55%'],
                 label: {
                      show:true,
                      position: 'inner',
                     formatter: function (oParams) {
                       //  var val =   '{titleStyle|'+self.formatDataLabelValues('', oParams.value, 0) + '}';
                         var val =   self.formatDataLabelValues('', oParams.value, 0);
                       //  var shortPct = self.formatYAxisValues('',oParams.percent,1);
                        // val += '\n';
                        // val += shortPct;
                        // val += '%';
                         return val;
                     },
                     rich: {
                          titleStyle: {
                              fontWeight: 'bold'//@TODO not working!
                          }
                     },
                     fontStyle : 'normal',
                     fontWeight : 600,
                     fontSize: 11,
                     color : 'black'

                    },
                    data: data.seriesData,
                    itemStyle: {
                        emphasis: {
                            shadowBlur: 10,
                            shadowOffsetX: 0,
                            shadowColor: 'rgba(0, 0, 0, 0.5)'
                        }
                    },
                    labelLine: {
                        show: false
                    },
                    animationDelay: function (idx) {
                        return 25;
                    },
                }
            ],

        };
        var mobile_option = {
            title : titles,
            tooltip : {
                trigger: 'item',
                formatter: "{a} <br/>{b} : {c} ({d}%)"
            },
            toolbox : {
                show : false,
                feature : {
                    mark : {show: true},
                    dataView : {show: false, readOnly: false},
                    restore : {show: true},
                    saveAsImage : {show: false}
                },
                showTitle: false,
                right: '2%'
            },
            calculable : false,
            legend: {
                type: 'scroll',
                orient: 'vertical',
                align: 'right',
                /*right: -300,*/
                top: 50,
                bottom: 20,
                right:0,
                //width: 20,
                data: data.legendData,
                selected: data.selected,
                scrollIndex: 0,
                formatter:function(name){
                    if(name.length>16) {
                        return name.substring(0, 13) + "...";
                    }else{
                        return name;
                    }

                },
                textStyle: {
                    fontSize: 10
                }
            },
            series : [
                {
                    name: 'Location Share',
                    type: 'pie',
                    /* roseType: 'radius',*/
                    /*  radius : '55%',*/
                    radius : ['40%', '65%'],
                    center: ['35%', '55%'],
                    label: {
                        show:true,
                        position: 'inner',
                        formatter: function (oParams) {
                            //  var val =   '{titleStyle|'+self.formatDataLabelValues('', oParams.value, 0) + '}';
                            var val =   self.formatDataLabelValues('', oParams.value, 0);
                            //  var shortPct = self.formatYAxisValues('',oParams.percent,1);
                            // val += '\n';
                            // val += shortPct;
                            // val += '%';
                            return val;
                        },
                        rich: {
                            titleStyle: {
                                fontWeight: 'bold'//@TODO not working!
                            }
                        },
                        fontStyle : 'normal',
                        fontWeight : 600,
                        fontSize: 11,
                        color : 'black'

                    },
                    data: data.seriesData,
                    itemStyle: {
                        emphasis: {
                            shadowBlur: 10,
                            shadowOffsetX: 0,
                            shadowColor: 'rgba(0, 0, 0, 0.5)'
                        }
                    },
                    labelLine: {
                        show: false
                    },
                    animationDelay: function (idx) {
                        return 25;
                    },
                }
            ],

        };
        this.locationPieChart = echarts.init(eleDiv,'light');
        if(window.matchMedia("(max-width: 896px)").matches){
            this.locationPieChart.setOption(mobile_option);
        }else{
            this.locationPieChart.setOption(option);
        }
        this.locationPieChart.on('click', function (params) {
            var data = params.data;
            var id = data.id;
            var sSelectedDate = cmp.get('v.selectedDate');
            var sSelectedMonth = '';
            if(sSelectedDate && sSelectedDate !== 'null' && sSelectedDate !== '1YR' ) {
                var dSelectedDate;
                try {
                    dSelectedDate = new Date(sSelectedDate);
                    var time = dSelectedDate.getTime();
                    sSelectedMonth = '&month=' + time;
                } catch (e) {
                    console.error(e);
                }
            }
            var urlEvent = $A.get("e.force:navigateToURL");
            urlEvent.setParams({
                "url": '/performance?accountId=' + id + sSelectedMonth
            });
            urlEvent.fire();
        });
    },
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     * @TODO change to use datasets and encodes for more flexibility and less rebuilding!
     */
    renderEChartComplexArea: function(cmp,evt,helper) {
        var self = this;
        var eleDiv = cmp.find("echarts-location-area").getElement();

        if(self.locationMonthlyChart==null) {
            self.locationMonthlyChart = echarts.init(eleDiv,'light',{renderer: 'svg'});
        }
        var data = self.buildMonthlyEChartData(cmp);
        var categoryData = data.categoryData;
        var valueData = data.valueData;
        var showSeriesDataPointLabel = false;
        if(valueData && valueData.length < 15) {
            showSeriesDataPointLabel = true;
        }
        //var formatTooltipLine = function(color){
        //    return "<span style='display:inline-block;width:10px;height:10px;border-radius:50%;background-color:"+color+";margin-right:5px;'></span><span>line text</span>";
        //};
        var subtext = cmp.get('v.chartAllLocsSubTitle');
        try {
            var option = {
                title: {
                    text: 'Overall Location Share - ' + self.formatYAxisValues('$', cmp.get('v.areaChartLocShareTotal'), 1),
                    subtext: subtext,
                    x: 'left',
                    textStyle: {
                        fontSize: 15
                    },
                    subtextStyle: {
                        color: 'black'
                    },
                    top: 8,
                    left: 10
                },
                toolbox: {
                    show: true,
                    feature: {
                        mark: {show: true},
                        dataView: {show: false, readOnly: false},
                        restore: {show: true},
                        saveAsImage: {
                            show: false,
                            type: 'png',
                        }
                    },
                    showTitle: false,
                    right: '2%'
                },
                tooltip: {
                    trigger: 'axis',
                    formatter: function (oParams) {
                        var param = oParams[0];
                        var date = new Date(param.name);
                        var value = param.value;
                        var localizedDate = $A.localizationService.formatDate(date, "MMM yy");
                        return localizedDate + '\' - ' + value;
                    },
                },
                grid: {
                    left: 20,
                    containLabel: true,
                    show: true,
                    right: 28,
                    bottom: 33,
                    borderColor: 'white',
                    top: 80,
                    backgroundColor: 'rgb(255,255,255)'
                },
                dataZoom: [{
                    type: 'inside',
                    xAxisIndex: [0],
                    start: 0,
                    end: 100,
                }, {
                    type: 'slider',
                    height: 28,
                    show: true,
                    xAxisIndex: [0],
                    start: 0,
                    end: 100,
                    bottom: 0,
                    right: '15%',
                    left: '15%',
                    handleIcon: 'path://M306.1,413c0,2.2-1.8,4-4,4h-59.8c-2.2,0-4-1.8-4-4V200.8c0-2.2,1.8-4,4-4h59.8c2.2,0,4,1.8,4,4V413z',
                    handleSize: '115%',
                    handleStyle: {
                        color: "blue",

                    },
                    textStyle: {
                        color: "black"
                    },
                    borderColor: "#90979c"
                    ,

                    labelFormatter: function (value, valueStr) {
                        var date = new Date(valueStr);
                        var val = $A.localizationService.formatDate(date, "MMM yy");
                        return val+'\'';
                    }
                }
                ],
                xAxis: {
                    data: data.categoryData,
                    type: 'category',
                    axisTick: {
                        show: true
                    },
                    axisLine: {onZero: false},
                    splitLine: {
                        show: false,
                        lineStyle: {
                            /*color: ['red']*/
                            type: 'dashed'
                        }
                    },
                    axisLabel: {
                        formatter: function (value, idx) {
                            var val;
                            val = $A.localizationService.formatDate(value, "MMM yy");
                            if (idx === 0 || idx === data.categoryData.length) {
                                val = $A.localizationService.formatDate(value, "MMM yy");
                            }
                            return val+'\'';
                        }
                    },
                    boundaryGap: false
                },
                yAxis: {
                    type: 'value',
                    axisLabel: {
                        formatter: function (value, index) {
                            return self.formatYAxisValues('$', value, 0);
                        }
                    },
                    splitLine: {
                        show: true,
                        lineStyle: {
                            /*color: ['red']*/
                            type: 'dashed'
                        }
                    },
                    min: 'dataMin',
                    max: 'dataMax'
                },
                series: [{
                    type: 'line',
                    data: data.valueData,
                    symbol: 'circle',
                    symbolSize: 7,
                    symbolKeepAspect: true,
                    showAllSymbol: 'auto',
                    label: {
                        normal: {
                            show: showSeriesDataPointLabel,
                            fontSize: 3.5,
                            fontWeight: 'bold',
                            distance: 1,
                            color: 'black',
                            formatter: function (oParams) {
                                var shortVal = self.formatDataLabelValues('', oParams.value, 0);
                                if (oParams.dataIndex === 0) {
                                    return '';
                                } else {
                                    return shortVal;
                                }
                            }
                        }
                    },
                    areaStyle: {
                         color: {
                             type: 'linear',
                             x: 0,
                             y: 0,
                             x2: 0,
                             y2: 1,
                            colorStops: [{
                                offset: 0,
                                color: 'rgb(255, 158, 68)'
                            }, {
                                offset: 1,
                                color: 'rgb(255, 70, 131)'
                            }],
                            global: false
                        },
                        origin: 'auto'
                       /* normal: {
                            shadowColor: 'rgba(0, 0, 0, 0.1)',
                            shadowBlur: 10
                        } */
                    },
                    itemStyle: {
                        color: 'rgb(255, 70, 131)'
                      /*  normal: {
                            color: 'rgb(0,85,148)',
                            borderColor: 'rgba(0,136,212,0.2)',
                            borderWidth: 8

                        } */
                    },
                }]
            };
        } catch (e) {
            alert(e);
        }
        var mobile_option = {
            title: {
                text: 'Overall Location Share - ' +   self.formatYAxisValues('$',cmp.get('v.areaChartLocShareTotal'),1)  ,
                subtext: subtext,
                x:'center',
                itemGap: 5,
                textStyle : {
                    fontSize: 15
                },
                subtextStyle : {
                    color: 'black'
                },
                top: 5
            },
            toolbox : {
                show : false,
                feature : {
                    mark : {show: true},
                    dataView : {show: false, readOnly: false},
                    restore : {show: true},
                    saveAsImage : {
                        show: false,
                        type: 'png'
                    }
                },
                showTitle: false,
                right: '2%'
            },
            tooltip: {
                trigger: 'axis',
                formatter: function (oParams) {

                    var param = oParams[0];
                    var date = new Date(param.name);
                    var value = param.value;
                    var localizedDate =  $A.localizationService.formatDate(date, "MMM yy");
                    return localizedDate+'\'' + ' - ' + value;
                },
            },
            grid: {
                left: 5,
                containLabel: true,
                show: true,
                right: 5,
                bottom: 8,
                borderColor: 'white',
                top:65,
                backgroundColor: 'rgb(255,255,255)'
            },

            xAxis: {
                data: data.categoryData,
                type : 'category',
                boundaryGap: false,
                axisTick: {
                    show: true
                },
                axisLine: {onZero: false},
                splitLine: {
                    show:true,
                    lineStyle: {
                        /*color: ['red']*/
                        type: 'dashed'
                    }
                },
                axisLabel: {
                    formatter: function (value, idx) {
                        var val;
                        val = $A.localizationService.formatDate(value, "MMM yy");
                        if(idx === 0 || idx === data.categoryData.length) {
                            val =  $A.localizationService.formatDate(value, "MMM yy");
                        }
                        return val+'\'';
                    }
                }
            },
            yAxis: {
                type : 'value',
                axisLabel: {
                    formatter: function (value, index) {
                        return self.formatYAxisValues('$', value, 0);
                    }
                },
                axisLine : {
                    show: false,
                },
                splitLine: {
                    show:true,
                    lineStyle: {
                        /*color: ['red']*/
                        type: 'dashed'
                    }
                },
                axisLine: {onZero: false},

                min: 'dataMin',
                max: 'dataMax'
            },
            series: [{
                type: 'line',
                data: data.valueData,
                // Set `large` for large data amount
                label: {
                    normal: {
                        show: false,
                        position: 'top',
                        color: 'black',
                        fontWeight: 600,
                        formatter: function (oParams) {
                            var shortVal = self.formatDataLabelValues('', oParams.value, 0);
                            if(oParams.dataIndex===0){
                                return '';
                            }else{
                                return shortVal;
                            }
                        }
                    }
                },
                animationDelay: function (idx) {
                    return 25;
                },
                 markPoint : {
                    symbolSize: 5,
                    itemStyle : {
                        color:'rgb(0,0,0)',
                        fontWeight: 600
                    }
                },

                /* symbol: 'none',
                 sampling: 'average',*/
                symbol: 'circle',
                symbolSize: 8,
                showAllSymbol: 'auto',
                areaStyle: {
                    color: {
                        type: 'linear',
                        x: 0,
                        y: 0,
                        x2: 0,
                        y2: 1,
                        colorStops: [{
                            offset: 0,
                            color: 'rgb(255, 158, 68)'
                        },{
                            offset:1,
                            color: 'rgb(255, 70, 131)'
                        }],
                        global: false
                    },
                    origin: 'auto'
                },
                itemStyle: {
                    color: 'rgb(255, 70, 131)'
                }
            }]
        };

        //media query to assign different options for the chart render
        if(window.matchMedia("(max-width: 896px)").matches){
            this.locationMonthlyChart.setOption(mobile_option);
        }else{
            this.locationMonthlyChart.setOption(option);
        }


        this.locationMonthlyChart.on('click', function (params) {
            var dateSelected;
            if(params.name) {
                dateSelected = new Date(params.name);
            }
            if(dateSelected) {
                try {
                    var evt = $A.get("e.c:Accel_ChartLocShareTotalMonthSelected");
                    evt.setParams({
                        "dateSelected": dateSelected,
                        "accountIds": cmp.get('v.visibleAccountIds')
                    });
                    self.log(cmp, 'firing locShareDateSelectedEvent with param dateSelected=' + dateSelected, 'info');
                    evt.fire();
                } catch (e) {
                    self.log(cmp, 'error firing evt', 'error', e);
                }
            }
        });

    },
    /**
     * Build dataset for area chart.
     *
     * @param cmp
     * @returns {{categoryData: Array, valueData: Array}}
     */
    buildMonthlyEChartData: function (cmp) {
        var self = this;
        var totalLocShare = cmp.get('v.areaChartLocShareTotal');
        totalLocShare = 0;
        var categoryData = [];
        var dataSeriesAllLocMonthly = [];
        var selectDateOptions = [];
        var valueData = [];
        //------------------------------------------------------var hpdWraps = cmp.get('v.locationMonthlyData');
        var hpdWraps = cmp.get('v.locationMonthlyDataByFreq');
        self.log(cmp,'building eChart overall loc date with hpdWraps','info',hpdWraps);

            if (hpdWraps) {
                hpdWraps.sort(function (a, b) {
                    var aDate = new Date(a.hpdDate);
                    var bDate = new Date(b.hpdDate);
                    return aDate.getTime() - bDate.getTime();
                });
                for (var i = 0; i < hpdWraps.length; i++) {
                    var hpdWrap = hpdWraps[i];
                    var dDate = new Date(hpdWrap.hpdDate);
                    var valueDate = hpdWrap.hpdDate;
                    totalLocShare += hpdWrap.locShare;
                    dDate.setDate(dDate.getDate() + 1); //@TODO Timezone thing!
                    var val = [dDate, hpdWrap.locShare];

                    categoryData.push(dDate);
                    valueData.push(hpdWrap.locShare);
                    dataSeriesAllLocMonthly.push(val);

                    var selectDateOption = {
                        value: dDate,
                        //  label: $A.localizationService.formatDate(hpdWrap.hpdDate, "yyyy MMM")
                        label: $A.localizationService.formatDate(dDate, "yyyy MMM")
                    };
                    selectDateOptions.push(selectDateOption);
                }
                //--- reverse the sort for the date drilldown pl.. probably not the most performance. @TODO better way.
                selectDateOptions.sort(function (a, b) {
                    return b.value.getTime() - a.value.getTime()
                });
                cmp.set('v.dateSelectOptions', selectDateOptions);
                cmp.set('v.areaChartLocShareTotal', totalLocShare);
                var mDates = dataSeriesAllLocMonthly.map(function (x) {
                    return new Date(x[0]);
                });
                var latestDate = new Date(Math.max.apply(null, mDates));
                //--- add 1 month on both sides for visual purposes.. (not the same as tooltip bug)
                latestDate.setDate(latestDate.getDate() + 31);
                var earliestDate = new Date(Math.min.apply(null, mDates));
                earliestDate.setDate(earliestDate.getDate() - 31);

                if (latestDate) {
                    cmp.set('v.locationMonthlyLatestDate', latestDate);
                }
                if (earliestDate) {
                    cmp.set('v.locationMonthlyEarliestDate', earliestDate);
                }
            }


        categoryData.sort(function(a,b){return a.getTime() - b.getTime()});

        return {
            categoryData : categoryData,
            valueData : valueData
        };
    },
    /**
     * Build dataset for YOY Chart.
     *
     * @param cmp
     * @param arr
     * @returns {{monthsArray: Array, min: number, max: number, allDataSeries: Array}}
     */
    buildMonthlyChartYoyData: function (cmp, arr) {
        var self = this;
        var allDataSeries = [];
        var dataSeriesYear = [];
        var hpdWraps;
        var allMonthsSet = new Set();
        var allMonthsIntSet = new Set();
        if (arr) {
            hpdWraps = arr;
        } else {
            hpdWraps = cmp.get('v.locationMonthlyData');
        }
        var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
        var mMonthNum_MonthString = new Map();
        for (var i = 0; i < months.length; i++) {
            mMonthNum_MonthString.set(i, months[i]);
        }
        var oVals = [];
        if (hpdWraps) {
            var m;
            var min = Math.min.apply(null, hpdWraps.map(function (a) {return a.locShare;}));
            var max = Math.max.apply(null, hpdWraps.map(function (a) {return a.locShare;}));
            var minYear = Math.min.apply(null, hpdWraps.map(function (a) {return a.hpdYear;}));
            var maxYear = Math.max.apply(null, hpdWraps.map(function (a) {return a.hpdYear;}));

            var colors =  ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'];//#TODO make this more enteries. after 11 years it will die.

            try {
                var idxColor =0;
                m = groupBy(hpdWraps, 'hpdYear');
                Object.keys(m).map(function (key, index) {
                    dataSeriesYear = m[key];
                    var mHpdsGroupedByYear = groupBy(dataSeriesYear, 'hpdMonth');

                    cleanseDataInYear(dataSeriesYear, mHpdsGroupedByYear, key, mMonthNum_MonthString);

                    var lineWidth = 2;
                    if (Number(key) === maxYear) {
                        lineWidth = 4;
                    } else {
                        lineWidth = 2;
                    }
                    var tmpMap = new Map();
                    for (var y = 0; y < 12; y++) {
                        tmpMap.set(y, 0);
                    }
                    var dataSeries = {
                        name: key,
                        type: 'line',
                        stack: key,
                        data: [],
                        connectNulls: true,
                        lineStyle: {width: lineWidth},
                        symbol: 'circle',
                        symbolSize: 6,
                        showAllSymbol: 'auto',

                    };
                    if (Number(key) === maxYear) {
                        var label = {
                            normal: {
                                show: true,
                                position: 'top'
                            }
                        };
                        dataSeriesYear.label = label;
                    }
                    dataSeriesYear.sort(function (a, b) {
                        return a.hpdMonth - b.hpdMonth;
                    });
                    for (var i = 0; i < dataSeriesYear.length; i++) {
                        var hpdWrap = dataSeriesYear[i];
                        var date = hpdWrap.hpdDate;

                        var dateAdj = new Date(hpdWrap.hpdDate);
                        dateAdj.setDate(dateAdj.getDate() + 1);

                        var oVal = {
                            locShare: hpdWrap.locShare,
                            date: dateAdj,
                            dateInt: dateAdj.getMonth(),
                            dateStr: $A.localizationService.formatDate(dateAdj, "MMM"),
                            yearInt: dateAdj.getFullYear()
                        };
                        oVals.push(oVal);
                        var iDateInt = dateAdj.getMonth();
                        tmpMap.set(iDateInt, hpdWrap.locShare);

                        var val = hpdWrap.locShare;
                        dataSeries.data.push(val);

                        allMonthsSet.add(months[dateAdj.getMonth()]);
                        allMonthsIntSet.add(dateAdj.getMonth());
                    }

                    allDataSeries.push(dataSeries);
                });
                idxColor ++;
            } catch (e) {
                alert(e);
            }
            var allMonths2 = [];
            for (const pair of mMonthNum_MonthString) {
                allMonths2.push(pair[1]);
            }
            return {
                allDataSeries: allDataSeries,
                monthsArray: allMonths2,
                min: min,
                max: max
            };
        }

        function groupBy(data, key) {
            // `data` is an array of objects, `key` is the key (or property accessor) to group by
            // reduce runs this anonymous function on each element of `data` (the `item` parameter,
            // returning the `storage` parameter at the end
            return data.reduce(function(storage, item) {
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
        }
        /**
         *
         * @param data                  - the hpd wrapper data.
         * @param mHpdsGroupedByYear    - grouped by  year (1 indexed).
         * @param year                  - the year we are processing.
         * @param mMonthNum_MonthString - map month num => string month name (ZERO indexed)
         */
        function cleanseDataInYear(data, mHpdsGroupedByYear, year, mMonthNum_MonthString) {
            if (data) {
                for (const pair of mMonthNum_MonthString) {
                    var key = pair[0];
                    var hpdMapKey = key + 1;
                    if (!mHpdsGroupedByYear.hasOwnProperty(hpdMapKey)) {
                        var d = new Date(year, key, 0);
                        var hpdDate = d;
                        var hpdWrap = {
                            amtPlayed: 0,
                            amtWon: 0,
                            fundsIn: 0,
                            fundsOut: 0,
                            hpdDate: hpdDate,
                            hpdMonth: hpdMapKey,
                            hpdYear: year,
                            locShare: null,
                            netFunds: 0,
                            netRevenue: 0
                        };
                        data.push(hpdWrap);
                    }
                }
            }
        }
    },
    buildMonthlyEchartPieData: function (cmp, arr) {

        var locShareTotal = cmp.get('v.pieChartLocShareTotal');
        locShareTotal = 0;
        var hpdWrapsByAccount;
        //alert(JSON.stringify(arr));
        if (arr) {
            hpdWrapsByAccount = arr;
            this.log(cmp,'pulling array','info',arr);
        } else {
           // hpdWrapsByAccount = cmp.get('v.hpdWrapsByAccount');
            hpdWrapsByAccount = cmp.get('v.hpdWrapsByAccountByFreq');
            this.log(cmp,'pulling hpdWrapsByAccountFreq','info',hpdWrapsByAccount);
        }
        var legendData = [];
        var seriesData = [];
        var selected = {};

        if(hpdWrapsByAccount) {
            //sort locshare desc
            hpdWrapsByAccount.sort(function(a,b) {return b.locShare - a.locShare;});
        }
        for (var x = 0; x < hpdWrapsByAccount.length; x++) {
            var hpdWrap = hpdWrapsByAccount[x];
            legendData.push(hpdWrap.accountPhysicalStreet);
            seriesData.push({
                name: hpdWrap.accountPhysicalStreet,
                value: hpdWrap.locShare,
                id: hpdWrap.accountId
            });
            locShareTotal += hpdWrap.locShare;
        }
        this.log(cmp,'------------- setting locShareTotal for pie chart!','info',locShareTotal);
        cmp.set('v.pieChartLocShareTotal',locShareTotal);
        return {
            legendData: legendData,
            seriesData: seriesData,
            selected: selected
        };
    },
    processAreaChartButtonClick: function(cmp,event,helper,btnName) {
        //alert('change scope of data above.. and....modify pie on right?');
        $A.util.addClass(cmp.find("apexcharts-location-area-by-month"), "slds-hide");
        $A.util.removeClass(cmp.find("apexcharts-location-area"), "slds-hide");

        var btnName;
        if(event) {
            var target = event.getSource();
            btnName = target.get('v.name');
        }

        var timeMin;

        //--- play games to ensure we don't get caught with nasty ass pass by ref shit.
        var dataLatestDate = cmp.get('v.locationMonthlyLatestDate');
        var dataEarliestDate = cmp.get('v.locationMonthlyEarliestDate');
        var tmpLatestDate = new Date(dataLatestDate.valueOf());
        var tmpEarliestDate = new Date(dataEarliestDate.valueOf());
        var timeMax = tmpLatestDate.getTime();
        var subtitle = cmp.get('v.chartAllLocsSubTitle');
        var iFreq = 0;

        var btnIds = ["6MTH", "1YR", "YOY", "ALL"];

        window.setTimeout(function () {
            for (var i = 0; i < btnIds.length; i++) {
                var btnId = btnIds[i];
                var btnCmp = cmp.find(btnId);
                if (btnId === btnName) $A.util.addClass(btnCmp, "accel-btn-is-selected");
                else $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            }
        }, 0);
        cmp.set('v.currentFreq', btnName);
        helper.log(cmp, 'current chart freq changing', 'info', cmp.get('v.currentFreq'));
        switch (btnName) {
            case '1YR':
                try {
                    tmpEarliestDate.setFullYear(tmpLatestDate.getFullYear() - 1);
                    timeMin = tmpEarliestDate.getTime();
                } catch (e) {
                    alert(e);
                }
                subtitle += ' (over the past year)';
                iFreq = 12;
                //alert('@TODO handle 1 year mode.. ie. grid data changes complete but now we must recode pie chart as well and expand multiple methods');
                this.filterLocDataByCurrentFreq(cmp);
                //--------------------helper.filterMonthlyPieChartByCurrentFreq(cmp);
                this.locationMonthlyChart.clear();
                this.renderEChartComplexArea(cmp, event, helper);
                this.retrieveMonthlyPieData(cmp, '1YR');
                cmp.set('v.pieChartSubTitle','All locations (over the past year)');
                break;
            case 'YOY':
                this.locationMonthlyChart.clear();
                this.resetAreaChartSeriesMonthly(cmp, null, null, btnName);
                break;
            case 'ALL':
                timeMin = cmp.get('v.locationMonthlyEarliestDate').getTime();
                subtitle += ' (lifetime)';
                iFreq = -1;
                this.locationMonthlyChart.clear();
                this.filterLocDataByCurrentFreq(cmp);
                this.renderEChartComplexArea(cmp, event, helper);
                this.retrieveMonthlyPieData(cmp, 'ALL');
                cmp.set('v.pieChartSubTitle','All locations (lifetime)');
                break;
        }
        try {
            this.log(cmp, 'locationMonthlyData raw list size:' + cmp.get('v.locationMonthlyData').length);
            var evt = $A.get("e.c:Accel_ChartLocShareTotalsLoaded");
            evt.setParams({
                "locationMonthlyData": cmp.get('v.locationMonthlyData'),
                "locationMonthlyFrequency": iFreq,
                "locationMonthlyDataDescription": subtitle
            });
            this.log(cmp, 'firing ChartLocShareTotalsLoadedEvent', 'info');
            evt.fire();
        } catch (e) {
            self.log(cmp, 'error attempting to fire ChartLocShareTotalsEvent', 'error', e);
        }
        if (timeMin && timeMax) {
            if (this.locationMonthlyChart) {
                this.locationMonthlyChart.updateOptions({
                    xaxis: {
                        min: timeMin,
                        max: timeMax
                    },
                    subtitle: {
                        text: subtitle
                    }
                });
            }
        }
    },
    //---------------------- @TODO the below 2 should be merged..
    /**
     *
     * @param prefix
     * @param value
     * @param fixed
     * @returns {*}
     */
    formatYAxisValues: function (prefix, value, fixed) {
        var num = value;
        if (num === null) {
            return null;
        } // terminate early
        if (num === 0) {
            return '0';
        } // terminate early
        fixed = (!fixed || fixed < 0) ? 0 : fixed; // number of decimal places to show
        var b = (num).toPrecision(2).split("e"), // get power
            k = b.length === 1 ? 0 : Math.floor(Math.min(b[1].slice(1), 14) / 3), // floor at decimals, ceiling at trillions
            c = k < 1 ? num.toFixed(0 + fixed) : (num / Math.pow(10, k * 3)).toFixed(1 + fixed), // divide by power
            d = c < 0 ? c : Math.abs(c), // enforce -0 is 0
            e = d + ['', 'K', 'M', 'B', 'T'][k]; // append power
        var ret = '';
        if (prefix) {
            ret = prefix + e;
        } else {
            ret = e;
        }
        return ret;
    },
    /**
     * @TODO there seems to be a bug here were it's always showing 1 dec pt.
     * @param prefix
     * @param value
     * @param fixed
     * @returns {*}
     */
    formatDataLabelValues: function (prefix, value, fixed) {
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
    //
    //====================================================== DATATABLE UTILS ===========================================
    initAccountTreeGridColumns: function (cmp) {
        cmp.set('v.gridColumns', [
            {label: 'Location', fieldName: 'ConcatName', type: 'text'},
            {label: '1 Mth HPD', fieldName: 'hpd4Week', type: 'currency', cellAttributes: {alignment: 'left'}},
            {label: '3 Mth HPD', fieldName: 'hpd8Week', type: 'currency', cellAttributes: {alignment: 'left'}},
            {label: '12 Mth HPD', fieldName: 'hpd12Week', type: 'currency', cellAttributes: {alignment: 'left'}}
        ]);
    },
    initLocationDatatableColumns: function (cmp) {
        cmp.set('v.locationColumns', [
            {label: 'Location', fieldName: 'fullLocationName', type: 'String', sortable: true},
            {
                label: '4 Week Location Share Total',
                fieldName: 'hpdLocShare4Week',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'TTM Location Share Total',
                fieldName: 'hpdLocShareTtm',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Lifetime Location Share Total',
                fieldName: 'hpdLocShareLifetime',
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
            pageList.push(2, 3, 4, 5, 6);
        } else if (pageNumber > (totalPage - 5)) {
            pageList.push(totalPage - 5, totalPage - 4, totalPage - 3, totalPage - 2, totalPage - 1);
        } else {
            pageList.push(pageNumber - 2, pageNumber - 1, pageNumber, pageNumber + 1, pageNumber + 2);
        }
        cmp.set("v.pageList", pageList);
        cmp.set("v.showSpinner", false);
    },
    sortData: function (cmp, data, fieldName, sortDirection) {
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        this.log( cmp,'in helper sort data after sort');
        cmp.set('v.locHpdExprData',data);

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
    scrollToTop: function (cmp) {
        // setTimeout($A.getCallback(function () {
        //     try {
        //         var target = cmp.find("accelTop");
        //         var ele = target.getElement();
        //         var rect = ele.getBoundingClientRect();
        //         window.scrollTo({top: rect, behavior: "smooth"});
        //     } catch (e) {
        //         console.error(e);
        //     }
        // }));
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
                var cmpName = '--- Accel_CommunityHomeLocationPerformance CMP --- ';
                var cLogger = this.loggingUtils;
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
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    windowResizing: function (cmp, evt, helper) {
        var self = this;
        if(self.locationPieChart) {
            self.locationPieChart.resize();
        }
        if(self.locationMonthlyChart) {
            self.locationMonthlyChart.resize();
        }
        //self.log(cmp,'helper window is resizing');
    },
    fireDevMsg: function (cmp) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Development Message',
            message: 'Charts have little interactivity at this time. That functionality is currently being developed.',
            duration:' 5000',
            key: 'info_alt',
            type: 'info',
            mode: 'dismissible'
        });
        toastEvent.fire();
    }
});