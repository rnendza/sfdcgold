import {LightningElement,api,track} from 'lwc';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {loadScript } from 'lightning/platformResourceLoader';
import ECHARTS_FULL  from '@salesforce/resourceUrl/echart4';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {reduceErrors} from 'c/ldsUtils';

const SFDC_FONT = 'Salesforce Sans, Arial, sans-serif';
const SLDS_GREEN = 'rgb(75, 202, 129)';
/**
 * The responsibility of this class is to consume tableData and tableColumns passed from the parent. it will
 * then, when the setter of tableData is called.. load the eChart script in a promise.. upon successful return of the promise.
 * it will init the eChart with proper options.  This was a better procedure then your typical renderedCallback as,
 * since it takes forever for eCharts to load (sometimes 3 seconds), the parent would render nothing until it was done.
 * Now at least we can provide perceived performance and display something while waiting for eCharts to load.
 *
 * 1. Echarts is bulky AF 700k as used in aura.. 350k in the one imported here. Both WAY Too Large. Use Highcharts! 140k
 * 2. Communities is slow AF loading 3rd party libs from static resources.  The Community CDN Should probably be
 *    set up by someone is Accel to mitigate this. https://help.salesforce.com/articleView?id=community_builder_cdn.htm&type=5
 */
export default class AcGrowthChartLocRevenue extends LightningElement {


    //  Internal / private
    _hpdCompareData;
    _debugConsole = true; //@TODO passed in property / custom meta.
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _locGrowthChart;
    _className = 'AcGrowthChartLocRevenue';
    _locShareTitlePrefix = 'Location share % change from';
    _locShareTableData;
    _locShareSeriesData;
    _echartsLoaded = false;
    _chartBaseHeight = 300;

    @api chartLoaded = false;
    @api chartRowSizeIncrement = 30;_chartBaseNonRowHeight=150;
    @api selectedFilters;
    @api startMonth;
    @api endMonth;
    @api locType;
    @api startMonthDisplay = 'Month 1';
    @api endMonthDisplay  = 'Month 2';
    @api isMobile = false;
    @api communityUserSettings;

    @track isAnyChartData = false;
    @track displayNoDataMsg = false;
    @track chartOuterContainerClass = '';
    @track chartStyle;
    @track headerIconSize = 'small';
    @track error;

    //---- Lifecycle methods -------------------------------------------------------------------------------------------
    connectedCallback() {
        this.chartStyle = 'height:305px';
        this._accelUtils.logDebug(this._className+ ' --- connected callback ---');
    }
    /**
     * Register window events on first rendered callback.
     */
    renderedCallback() {
        if (this.alreadyRendered) return;
        this.alreadyRendered = true;
        this.registerWindowEvents();
        let templateWidth = this.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
        this.determineHeaderIconSize(templateWidth);
    }

    //---- public reactive accessors -----------------------------------------------------------------------------------
    @api
    get sectionTitle() {
        let title = 'All ';
        if(this.locType !== 'All Types') {
            title = this.locType + ' ';
        }
        title += 'Location Growth';
        return title;
    }
    @api
    get hpdCompareData() {
        return this._hpdCompareData;
    }
    /**
     * Public and reactive variable passed in from the parent.
     * @param hpdCompareData
     */
    set hpdCompareData(hpdCompareData) {
        this.chartLoaded = false;
        if(hpdCompareData && hpdCompareData.length > 0) {
            this.isAnyChartData = true;
            this.displayNoDataMsg = false;
            this.chartOuterContainerClass = '';
            if(this._locGrowthChart) {
                this._locGrowthChart.resize();
            }
        } else {
            this.displayNoDataMsg = true;
            this.isAnyChartData = false;
            if(this._locGrowthChart) {
                this._locGrowthChart.clear();
            }
        }
        this._hpdCompareData = hpdCompareData; // we need to effectively clone this as wire data is immutable.
        this._locShareTableData =  JSON.parse(JSON.stringify(hpdCompareData));
        this._accelUtils.logDebug(this._className+ ' --- setHpdCompareData ---',hpdCompareData);
        this.setMonthDisplayValues();
        if(!this._echartsLoaded) {
            this.loadScripts();
        } else {
            this.buildLocShareChartOptions();
        }
    }
    @api
    get locShareTableData() {
        return this._locShareTableData;
    }
    set locShareTableData(locShareTableData) {
        this._locShareTableData = locShareTableData;
    }

    /**
     * we hide the echart via css as opposed to removing it from the DOM as completely removing it from the DOM
     * and then reloading it with new data creates strange lifecycle issues.
     * @returns {string}
     */
    @api
    get locShareChartParentContainerClass() {
        return this.displayNoDataMsg ? 'slds-hide' : 'slds-show';
    }

    //---- Build location share echart. --------------------------------------------------------------------------------
    buildLocShareChartData() {
        let yAxisData = [];
        let locShareSeriesData = [];
        //this._locShareTableData = this.queryForDatatable();
        //  Sort by loc share pct change desc
        this._locShareTableData.sort((a, b) => (a._locSharePctChange > b._locSharePctChange) ? 1 : -1);
        let locSharePctChangeArr = this._locShareTableData.map(a => a._locSharePctChange * 100);
        let medianValue = this._accelUtils.findArrayMedian(locSharePctChangeArr);
        for (let i = 0; i < this._locShareTableData.length; i++) {
            let rowData = this._locShareTableData[i];
            let locSharePct = rowData._locSharePctChange * 100;
            let fundsInPct = rowData._fundsInPctChange * 100;

            let color = SLDS_GREEN;
            let position = 'insideRight'; //  Positive values
            if (locSharePct < 0) {
                color = 'rgb(212, 80, 76)'; //  SFDC Red
                position = 'insideLeft';
            }
            if(locSharePct > 0 && locSharePct <= medianValue) {
                if(this.isMobile) {
                    position = 'insideLeft';
                } else {
                    position = 'insideRight';
                }
            }
            let locSeries = {
                value: locSharePct,
                itemStyle: {color: color},
                label: {normal: {position: position}},
                dbaName: rowData.dbaName,
                street: rowData.address,
                fundsInPctChange: fundsInPct,
                month1FundsIn: rowData.startDateFundsIn,
                month2FundsIn: rowData.endDateFundsIn,
                month1LocShare: rowData.startDateLocShare,
                month2LocShare: rowData.endDateLocShare
            };
            let yAxisLabel = this.communityUserSettings && this.communityUserSettings.Display_Location_Address__c
                ? rowData.address : rowData.dbaName;
            yAxisData.push(yAxisLabel);
            locShareSeriesData.push(locSeries);
        }
        return {yAxisData: yAxisData, locShareSeriesData: locShareSeriesData}
    }
    /**
     *
     */
    buildLocShareChartOptions() {
        self = this;
        this._accelUtils.logDebug('building loc share chart options');
        if (!this._locShareTableData || this._locShareTableData.length < 1) {
            if(this._locGrowthChart) {
                this._locGrowthChart.clear();
            }
            this.chartLoaded = true;
            return;
        }
        let allData = this.buildLocShareChartData();
        let yAxisData = allData.yAxisData;
        this._locShareSeriesData = allData.locShareSeriesData;

        let selectedStartMonth = this.startMonthDisplay;
        let selectedEndMonth = this.endMonthDisplay;
        //  @TODO technically the below block should be moved out to another method.
        try {
            let gridTop = this.isMobile ? '5%' : '10%';
            let onlyOneSeriesRow = this._locShareSeriesData.length === 1;

            let option = {
                grid: {
                    show: true, top: gridTop, left: '3%', right: '2%', bottom: '3%', containLabel: true,
                    borderColor: 'rgb(255, 251, 240)'
                },
                title: {
                    text: this._locShareTitlePrefix + ' '+selectedStartMonth+' to '+selectedEndMonth,
                    textStyle: {fontSize: 14, fontWeight: 'bolder'}, left: 'center'
                },
                subTitle: {show: false},
                legend: {show: false},
                tooltip: {
                    trigger:'axis',show:true,axisPointer: {type: 'shadow'}, confine: true, textStyle: {fontSize: 14},
                    formatter: function (param) {
                        return self.formatTooltip(param);
                    }
                },
                xAxis: [
                    {
                        type: 'value',
                        axisLabel: {
                            fontSize: 15, fontFamily: SFDC_FONT, fontWeight: 'bolder', margin: 10,
                            formatter: function (value) {
                                return value + '%';
                            },
                        },
                    }
                ],
                yAxis: [
                    {
                        type: 'category',
                        axisTick: { show: !onlyOneSeriesRow, lineStyle: {type: 'solid', color: 'black'},},
                        axisLine: { show: true, lineStyle: {type: 'solid', color: 'black', onZero: false}},
                        splitArea: {show: true, interval: 0, areaStyle: { opacity: .45}},
                        data: yAxisData, position: 'right',
                        axisLabel: {
                            formatter: function (name) {
                              return self.yAxisLabelFormatter(name);
                            },
                            align: 'left', inside: false, margin: 5, fontFamily: SFDC_FONT, interval: 0
                        }
                    },
                ],
                series: [
                    {
                        name: 'Location Share % Change', type: 'bar',
                        label: {
                            normal: {
                                show: true, fontWeight: 'normal', fontSize: 10, color: 'black',
                                formatter: function (params) {
                                    if(self.isMobile) {
                                        return  self.mobileBarLabelFormatter(params);
                                    } else {
                                        return  self.desktopBarLabelFormatter(params);
                                    }
                                },
                                rich: {
                                    RT_locSharePctVal: {
                                        fontSize:11,color:'black',fontWeight:'bold'
                                    },
                                    RT_dbaName: {
                                        fontSize:10,color:'black'
                                    }
                                },
                            },
                        },
                        data: this._locShareSeriesData,
                    }
                ],
            };
            if (!this._locGrowthChart) {
                const ele = this.template.querySelector('[data-id="charts-container-data-id"]');
                this._locGrowthChart = echarts.init(ele, 'light');
                this._accelUtils.logDebug('initing locshare chart');
            }
            this._locGrowthChart.setOption(option);

            let viewOptions;
            let templateWidth = self.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
           // if(window.matchMedia("(max-width: 896px)").matches){
            if(templateWidth && templateWidth >= this._accelUtils.DESKTOP_CHART_WIDTH) { //@TODO get back to this.
                viewOptions = this.getDesktopSpecificOptions();
            } else {
                viewOptions = this.getMobileSpecificOptions();
           }
            this._locGrowthChart.setOption(viewOptions);

            this._accelUtils.logDebug('calling set option with option=',option);
            if(this._locGrowthChart) {
                this.chartRowSizeIncrement = 25;
                this._locGrowthChart.resize();
                this._accelUtils.logDebug('calling resize on chart');
            }
            this.chartLoaded = true;
        } catch (e) {
            console.error(e);
            this.showToast('Error',e);

        }
    }

    /**
     *
     * @param name
     * @returns {*|string}
     */
    yAxisLabelFormatter( name ) {
        if(!name) { return '';}
        let sFormattedName = name.length > 40 ? name.substring(0,37)+'...' : name;
        return sFormattedName.hardWrap(18, 10, '\n');  //  @see AccelUtilsSvc
    }

    /**
     *
     * @param params
     * @returns {string}
     */
    desktopBarLabelFormatter(params) {
        let ret = '';
        let val = params.value;
        let formattedVal = 0;
        let formattedName = params.data.dbaName;
        if (val !== 0) {
            formattedVal =  val.toFixed(1) + '%';
        }
        ret = '{RT_locSharePctVal|'+formattedVal+'}';
        return ret;
    }
    /**
     * WIP
     *
     * @param params
     * @returns {string}
     */
    mobileBarLabelFormatter(params) {
        let ret = '';
        let val = params.value;
        let formattedVal = 0;
        let formattedName = params.data.dbaName;
        formattedName = formattedName.length > 35 ? formattedName.substring(0,32)+'...' : formattedName;


        if (val !== 0) {
            formattedVal =  val.toFixed(0) + '%';
        }
        let medianValue = 0;
        if(this._locShareSeriesData) {
            medianValue = this._accelUtils.findArrayMedian(this._locShareSeriesData.map(a => a.value));
        }
        if(val > 0 && val > medianValue) {
            formattedName =formattedName.hardWrap(24, 10, '\n');  //  @see AccelUtilsSvc
            ret = '{RT_dbaName|'+formattedName+'}   {RT_locSharePctVal|'+formattedVal+'}';
        } else {
            formattedName =formattedName.hardWrap(18, 10, '\n');  //  @see AccelUtilsSvc
            ret = '{RT_locSharePctVal|'+formattedVal+'}   {RT_dbaName|'+formattedName+'}';
        }
        return ret;
    }

    /**
     *
     */
    getMobileSpecificOptions() {
        this.isMobile = true;
        return  {
            grid: [{right:'4%',left:'3%',top:'6%'}],
            yAxis: [ { axisLabel: {fontSize:9, show:false},splitArea: { opacity: .25}}],
            xAxis: [{ axisLabel: {fontSize:12,fontWeight:'bold'} }],
            title: [{textStyle: {fontSize: 10}}],
            series: [{label: {normal: {fontSize: 12, color: 'black',fontWeight:'bold'}}}],
            tooltip: [{triggerOn:'click',textStyle: {fontSize: 11}}],
        };
    }

    // showContent: true,
    // triggerOn: 'click',

    /**
     *
     */
    getDesktopSpecificOptions() {
        this.isMobile = false;
        return  {
            grid: [{right:'2%',left:'3%',top:'10%'}],
            yAxis: [{ axisLabel: {fontSize:11,show:true,inside:false,align: 'left',verticalAlign:'middle'},splitArea: { opacity: .25}}],
            xAxis: [{ axisLabel: {fontSize:13,fontWeight:'bold'} }],
            splitArea: { opacity: .45},
            title: [{textStyle: {fontSize: 14}}],
            series: [{barCategoryGap:'20%',label: {normal: {fontSize: 12, color: 'black',fontWeight:'bold'}}} ],
            tooltip: [{triggerOn:'mousemove|click',textStyle: {fontSize: 14}}],
        };
    }
    /**
     * Build the main tool tip.
     * @param param
     * @returns {string}
     */
    formatTooltip(param) {
        let text = '';
        try {
            let sNew = '';
            let name = param[0].data.dbaName;
            if (name.length > 80) {
                sNew = name.substring(0, 78) + '...';
            } else {
                sNew = name;
            }

            let currencyOptions = {style: 'currency', currency: 'USD'};
            sNew = self._accelUtils.StringHelpers.titleCase(sNew);
            sNew = sNew.hardWrap(30, 10, '<br\>');
            text = text + '<b>' + sNew + '</b><br/>';
            //address
            text += param[0].data.street + '</br>';
            let formattedLocSharePctChange = param[0].value.toFixed(1) + '%';
            text += param[0].seriesName + ': <span style="font-weight:bold">' + formattedLocSharePctChange + '</span><br/>';
            let formattedFundsInPctChange = param[0].data.fundsInPctChange.toFixed(1) + '%';
            text += 'Funds In % Change : <span style="font-weight:bold">' + formattedFundsInPctChange + '</span><br/>';
            text += self.startMonthDisplay + ' Funds In: ' + param[0].data.month1FundsIn.toLocaleString('en-US', currencyOptions) + '</br>';
            text += self.endMonthDisplay + ' Funds In: ' + param[0].data.month2FundsIn.toLocaleString('en-US', currencyOptions) + '</br>';
            text += self.startMonthDisplay + ' Loc Share: ' + param[0].data.month1LocShare.toLocaleString('en-US', currencyOptions) + '</br>';
            text += self.endMonthDisplay + ' Loc Share: ' + param[0].data.month2LocShare.toLocaleString('en-US', currencyOptions) + '</br>';
        } catch (e) {
            console.error(e);
        }
        return text;
    }
    /**
     *
     * @todo generally we add events to the template but resize only works on the window object.
     * @todo move the below options outside to a mobile options / desktop options for reuse purposes.
     */
    // last_known_scroll_position = 0;
    // ticking = false;
    //
    // hideToolTips() {
    //
    // }
    registerWindowEvents() {
        let self = this;
        window.addEventListener('resize', function() {
            if(self._locGrowthChart) {
                let templateWidth = self.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
                let option;
                if(templateWidth && templateWidth >= self._accelUtils.DESKTOP_CHART_WIDTH) { //@TODO get back to this.
                    option = self.getDesktopSpecificOptions(); //bouncing back and forth on template width.
                } else {
                    option = self.getMobileSpecificOptions();
                }
                self.determineHeaderIconSize(templateWidth);
                self.buildLocShareChartData(); //i don't like doing this but have to for position on mobile.
                self._locGrowthChart.setOption(option);
                self._locGrowthChart.resize();
            }
        });
        // window.addEventListener('scroll', function(e) {
        //     self.last_known_scroll_position = window.scrollY;
        //
        //     if (!ticking) {
        //         window.requestAnimationFrame(function() {
        //             doSomething(last_known_scroll_position);
        //             self.ticking = false;
        //         });
        //
        //         self.ticking = true;
        //     }
        // });

    }
    /**
     * Load any external js libs.
     */
    loadScripts() {
        loadScript(this, ECHARTS_FULL)
            .then(() => {
                this._accelUtils.logDebug(this._className + ' --- promise back from loading echart  now ---');
                this._echartsLoaded = true;
                this.buildLocShareChartOptions();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Echarts',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }
    /**
     *
     */
    setMonthDisplayValues() {
        let options = {year: 'numeric', month: 'short'};
        if(this.startMonth) {
            this.startMonthDisplay = this.formatMonthDisplay(this.startMonth, 'Month 1', options);
        }
        if(this.endMonth) {
            this.endMonthDisplay = this.formatMonthDisplay(this.endMonth, 'Month 2', options);
        }
    }
    determineHeaderIconSize(templateWidth) {
        if(templateWidth > this._accelUtils.MOBILE_CHART_WIDTH) {
            this.headerIconSize = 'small';
        } else {
            this.headerIconSize = 'x-small';
        }
    }
    /**
     * Takes a apex date such as '2019-07-01' .. creates a new js dhate which gives us
     * 'Sun Jun 30 2019 19:00:00 GMT-0500 (Central Daylight Time)' then appropriately converts this
     * back to 'Mon Jul 01 2019 00:00:00 GMT-0500 (Central Daylight Time)'
     *
     * @param sDate
     * @returns {Date}
     */
    convertApexStringDateToLocalDate(sDate) {
        let utcDate = new Date(sDate);
        return new Date(utcDate.getTime() + utcDate.getTimezoneOffset() * 60000);
    }
    /**
     * Takes a apex date such as '2019-07-01' .. creates a new js dhate which gives us
     * 'Sun Jun 30 2019 19:00:00 GMT-0500 (Central Daylight Time)' then appropriately converts this
     * back to 'Mon Jul 01 2019 00:00:00 GMT-0500 (Central Daylight Time)'
     *
     * @param sDate     an apex date ie. 2019-07-01
     * @returns {Date}  ie Mon Jul 01 2019 00:00:00 GMT-0500
     */
    convertApexDateToJsLocalDate(sDate) {
        let utcDate = new Date(sDate);
        return new Date(utcDate.getTime() + utcDate.getTimezoneOffset() * 60000);
    }
    /**
     *
     * @param monthDate   the reactive date value selected in the picklist.
     * @param monthChoice ie ['Month 1' or 'Month 2']
     * @returns {string} of the formatted Month ie. Jan 2019
     *
     * @TODO safety checking.
     */
    formatMonthDisplay( monthDate, monthChoice, options ) {
        let monthString = monthChoice;
        //let dt = new Date(monthDate);
        let dt = this.convertApexDateToJsLocalDate(monthDate);
        monthString = dt.toLocaleDateString('en-US', options);
        return monthString;
    }
    /**
     * @param title The Title of the toast.
     * @param msg   The Msg to display in the toast.
     * @TODO move to utils
     */
    showToast(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
        });
        this.dispatchEvent(evt);
    }
    //-----------------------------    STRESS TEST with Fake Data ----------------------------------------------------
    /**
     * Realistic max is about 100 locations. tested up to 500 locations but there is redraw stuttering and
     * very slow performance on a phone. After about 50 locations. one should come up with an additional filtering
     * mechanism.
     */
    queryForDatatable() {
        let arr = [];
        let testM1FundsIn = 8000;
        let testM2FundsIn = testM1FundsIn + 2456;
        let testM1LocShare = testM1FundsIn * .33;
        let testM2LocShare = testM2FundsIn * .33;
        let fundsInPctChange = (testM2FundsIn - testM1FundsIn) / testM1FundsIn ;
        let locSharePctChange = (testM2LocShare - testM1LocShare) /  testM1LocShare;

        for(let i=0;i<2;i++) {
            let testM1FundsIn = i*1000;
            if(i === 0) {
                testM1FundsIn = .5 * -1000;
            }
            let testM2FundsIn = testM1FundsIn + 2456;
            let testM1LocShare = testM1FundsIn * .33;
            let testM2LocShare = testM2FundsIn * .33;
            let fundsInPctChange = (testM2FundsIn - testM1FundsIn) / testM1FundsIn ;
            let locSharePctChange = (testM2LocShare - testM1LocShare) /  testM1LocShare;
            let fakeRow = {
               dbaName: i+ 'TEST DBA NAME: '+i,
                //dbaName: i+ 'test name:'+i,
                address: i+ ' - Random Test Address',
                city: i+' - Random City',
                startDateFundsIn : testM1FundsIn,
                endDateFundsIn : testM2FundsIn,
                fundsInPctChange : fundsInPctChange,
                _fundsInPctChange : fundsInPctChange,
                startDateLocShare : testM1LocShare,
                endDateLocShare : testM2LocShare,
                locSharePctChange : locSharePctChange,
                _locSharePctChange : locSharePctChange,
            };
            arr.push(fakeRow);
        }
        return arr;
    }
}