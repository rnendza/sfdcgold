/**
 * Replaced alerts with call to error logging which will pop toast as well.
 * https://accel-entertainment.monday.com/boards/286658657/
 */
({
    collectionUtils:null,
    loggingUtils:null,
    formatUtils: null,
    csvExporter: null,
    //https://accel-entertainment.monday.com/boards/286658657/
    uiMessagingUtils:null,
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:10000, //10 seconds
    chartStyle: null,
    COMMUNITY_SETTINGS:'CONTACT_CONTROLLED_COMMUNITY_SETTINGS',

    /**
     * Retrieve Community_User_Setting__c sObject for the running user.
     * @TODO Move to utils?
     */
    retrieveCommunityUserSettings: function(cmp) {
        let errors = [];
        cmp.lax.enqueue('c.retrieveCommunityUserSettings')
            .then(response => {
                let dto = response;
                let communityUserSettings = this.collectionUtils.getData(this.COMMUNITY_SETTINGS,dto.values);
                cmp.set('v.communityUserSettings',communityUserSettings);
                if(!communityUserSettings) {
                    cmp.set('v.communityUserSettingsNotFound',true);
                    cmp.set('v.renderMachineTabs', true);
                    cmp.set('v.renderMachineChart', true);
                    this.log(cmp,'sObject Community_User_Setting__c not found for logged in user!','error');
                } else {
                    cmp.set('v.communityUserSettingsNotFound',false);
                    cmp.set('v.renderMachineTabs',communityUserSettings.Display_Machine_Tabs__c);
                    cmp.set('v.renderMachineChart',communityUserSettings.Display_Machine_Chart__c);
                    //@TODO call method that sets flags to prevent chained queries and stuff that is hidden.
                    this.log(cmp,'communityUserSettings','info',JSON.stringify(communityUserSettings));
                }
                this.retrieveAccounts(cmp);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    retrieveAccounts: function(cmp) {
        cmp.lax.enqueue('c.retrieveAccounts') //getUserAccounts
            .then(response => {
                this.processUserAccounts(cmp, response);
                this.setYesterday(cmp);
                this.setHistoricalDataDates(cmp);
                this.log(cmp,'from retrieveAccounts about to call retrieveAggregateMachineData','debug');
                this.retrieveMachineTabData(cmp);
                this.retrieveHistoricalData(cmp);
                return this.retrieveAggregateMachineData(cmp);
            })
            .catch(errors => {
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    processUserAccounts: function (cmp, response) {
        let dto = response;
        let accounts = [];
        //--deprecated this.collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
        accounts =  this.collectionUtils.getData('ACCOUNT_LIST',dto.values);
        cmp.set('v.userAccounts', accounts);
        this.setUserAccountOptions(cmp); //---- translate user account array to options array for combo box (location filter)
        let accountId = this.getUrlParam('accountId');
        this.log(cmp,'processUserAccounts getUrlParam accountId=','debug',accountId);
        if (accountId && accountId !== '') {
            cmp.set('v.selectedAccountId', accountId);
        } else {
            accountId = accounts[0].Id;
            cmp.set('v.selectedAccountId', accounts[0].Id);
        }
    },
    retrieveMonthlyHpdDates: function(cmp){
        // note this is fired on init but there is an asycn call after scripts loaded  that is chained,
        // and then boxcarred so we need to kill the spinner somewhere in there.
        cmp.set('v.showMachinePerfSpinner',true);
        cmp.lax.enqueue('c.retrieveMonthlyHpdDates')
            .then(response =>{
                this.log(cmp,'retrieveMonthlyHpdDates response:','debug',response);
                this.processMonthlyHpdDates(cmp, response);
            })
            .catch(errors => {
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            })
    },
    processMonthlyHpdDates: function(cmp, response){
        let dto =  response;
        let hpdDates = [];
        let hpdFormattedDates = [];
        //-- Deprecated this.collectionUtils.getMapValue('HPD_WRAPPER_MONTHS', dto.values, function(value) {hpdDates = value;});
        hpdDates = this.collectionUtils.getData('HPD_WRAPPER_MONTHS',dto.values);

        for(let i=0; i<hpdDates.length; i++){
            hpdFormattedDates.push({
                value: hpdDates[i].hpdDate,
                label: $A.localizationService.formatDate(hpdDates[i].hpdDate, "MMM YYYY")
            });
        }
        cmp.set('v.dateSelectOptions', hpdFormattedDates);
        //  8-23-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        let serverYesterdayDate;
        //---this.collectionUtils.getMapValue('YESTERDAY_DATE', dto.values, function(value) {serverYesterdayDate = value;});
        serverYesterdayDate =  this.collectionUtils.getData('YESTERDAY_DATE',dto.values);
        this.log(cmp,'server yesterday date='+serverYesterdayDate);
        if(serverYesterdayDate) {
            cmp.set('v.serverYesterdayDate',serverYesterdayDate);
        }
        // //  Community User Settings
        // let communityUserSettings = this.collectionUtils.getData(this.COMMUNITY_SETTINGS,dto.values);
        // cmp.set('v.communityUserSettings',communityUserSettings);
        // if(!communityUserSettings) {
        //     cmp.set('v.communityUserSettingsNotFound',true);
        //     this.log(cmp,'sObject Community_User_Setting__c not found for logged in user!','error');
        // } else {
        //     //@TODO call method that sets flags to prevent chained queries and stuff that is hidden.
        //     this.log(cmp,'communityUserSettings','info',JSON.stringify(communityUserSettings));
        // }


        //---------------------------
    },
    retrieveDailyMachineData: function(cmp){
        //unnecessary function until machine performance vs time visualization is required
        let start = cmp.get('v.startDate');
        let end = cmp.get('v.endDate');
        let id = cmp.get('v.selectedAccountId');
        const params = {id: id, startDate: start, endDate: end};
        cmp.lax.enqueue('c.retrieveDailyMachineData', params)
            .then(response =>{
                this.processDailyMachineData(cmp, response);
                this.log(cmp,'in retrieveDailyMachineData calling `retrieveAggre`gateMachineData','debug');
                return this.retrieveAggregateMachineData(cmp);
            })
            .catch(errors=>{
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    retrieveHistoricalData: function(cmp){
      let start = cmp.get('v.startHDate');
      let end = cmp.get('v.endHDate');
      let id = cmp.get('v.selectedAccountId');
      let freq = cmp.get('v.selectedFrequency');
      const params = {id: id, startDate: start, endDate: end, freq: freq};
      cmp.lax.enqueue('c.retrieveHistoricalData', params)
          .then( response =>{
              this.processHistoricalData(cmp, response);
          })
          .catch( errors =>{
              this.log(cmp,'generic','error',JSON.stringify(errors));
          })
    },
    retrieveMachineTabData: function(cmp){
        let start = cmp.get('v.startDate');
        let end = cmp.get('v.endDate');
        let id = cmp.get('v.selectedAccountId');
        const params = {id: id, startDate: start, endDate: end};
        cmp.lax.enqueue('c.retrieveMachineImageData', params)
            .then( response =>{
                this.log(cmp,'retrieveMachineImageData response','debug',response);
                this.processMachineImageData(cmp, response);
            })
            .catch( errors =>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            })
    },
    retrieveAggregateMachineData: function(cmp){
        let start = cmp.get('v.startDate');
        let end = cmp.get('v.endDate');
        let id = cmp.get('v.selectedAccountId');
        const params = {id: id, startDate: start, endDate: end};
        cmp.lax.enqueue('c.retrieveAggregateMachineData', params)
            .then(response =>{
                this.log(cmp,'retrieveAggregateMachineData response','debug',response);
                this.processAggregateMachineData(cmp, response);
                return this.retrieveYearMonthToDateData(cmp, response);
            })
            .catch(errors =>{
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    processHistoricalData: function(cmp, response){
      let dto = response;
      let historicalData = [];
      historicalData = this.collectionUtils.getData('HISTORICAL_DATA', dto.values);
      cmp.set('v.historicalData', historicalData);
      this.buildHistoricalTable(cmp);
    },
    processMachineImageData: function(cmp, response){
        let dto = response;
        let machineImageData = [];
        let prevMachineImageData = [];
        let cityMachineImageData = [];
        let prevCityMachineImageData = [];
        machineImageData = this.collectionUtils.getData('MACHINE_IMAGE_DATA', dto.values);
        prevMachineImageData = this.collectionUtils.getData('PREV_MACHINE_IMAGE_DATA', dto.values);
        cityMachineImageData = this.collectionUtils.getData('CITY_MACHINE_IMAGE_DATA', dto.values);
        prevCityMachineImageData = this.collectionUtils.getData('PREV_CITY_MACHINE_IMAGE_DATA', dto.values);
        cmp.set('v.machineImageData', machineImageData);
        cmp.set('v.prevMachineImageData', prevMachineImageData);
        cmp.set('v.cityMachineImageData', cityMachineImageData);
        cmp.set('v.prevCityMachineImageData', prevCityMachineImageData);
        this.buildMachineTabs(cmp);
    },
    retrieveYearMonthToDateData: function(cmp){
        let id = cmp.get('v.selectedAccountId');
        const params = {id: id};
        cmp.lax.enqueue('c.retrieveYTDRevenue', params)
            .then (response =>{
                this.processYTDRevenue(cmp, response);
                //I'm guessing this is the longest one. as these are not chained in promises
                cmp.set('v.showMachinePerfSpinner',false);
            })
            .catch(errors=>{
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        cmp.lax.enqueue('c.retrieveMTDRevenue', params)
            .then(response=>{
                this.processMTDRevenue(cmp, response);
            })
            .catch(errors=>{
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        cmp.lax.enqueue('c.retrieveESTRevenue', params)
            .then(response=>{
                this.processESTRevenue(cmp, response);
            })
            .catch(errors=>{
                cmp.set('v.showMachinePerfSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    processESTRevenue: function(cmp, response){
        let dto = response;
        let estData= [];
        //--- deprecated this.collectionUtils.getMapValue('EST_DATA', dto.values, function (value) {estData = value;});
        estData =  this.collectionUtils.getData('EST_DATA',dto.values);
        let estimatedRevenueMonthName = '';
        let lastMonth;
        let lastYearMonth;
        let lastYearPrevMonth;
        let seasonality;
        let estMonthRevenue = 0;

        if(estData.length>=1){
            //----deprecated this.collectionUtils.getMapValue('ESTIMATED_REVENUE_MONTH_NAME', dto.values,
            // function (value) {estimatedRevenueMonthName = value;});
            estimatedRevenueMonthName =  this.collectionUtils.getData('ESTIMATED_REVENUE_MONTH_NAME',dto.values);
            lastMonth = estData[0].netRevenue;
            if(estData.length>=2){
                lastYearPrevMonth = estData[1].netRevenue;
                lastYearMonth = estData[2].netRevenue;

                seasonality = (lastYearMonth - lastYearPrevMonth) / lastYearPrevMonth;
                if(lastMonth >0){
                    estMonthRevenue = lastMonth*(1+seasonality);
                }else{
                    estMonthRevenue = lastMonth*(1-seasonality);
                }
                cmp.set('v.estRevenueDiff', (seasonality*100).toFixed(2));
                cmp.set('v.estRevenueDiffString', (seasonality*100).toFixed(2));
                cmp.set('v.estRevenue', this.formatNumberWithCommas(estMonthRevenue.toFixed(2)));
                cmp.set('v.estimatedRevenueMonthName',estimatedRevenueMonthName);
            }else{
                //backup formula for locations with no daily data from 12 months ago?
                cmp.set('v.estRevenueDiff', 1);
                cmp.set('v.estRevenueDiffString', '--');
                cmp.set('v.estRevenue', '-----');
            }
        }else{
            //no data from last month, newly live
            cmp.set('v.estRevenueDiff', 1);
            cmp.set('v.estRevenueDiffString', '--');
            cmp.set('v.estRevenue', '-----');
        }

        /*
        let lastMonth =[];
        let lastYearMonth = [];
        let lastYearPrevMonth = [];
        let seasonality = [];
        let thisMonthEst = [];
        let yesterday = ( d => new Date(d.setDate(d.getDate()-1)) )(new Date);
        let totalEstimateRevenue = 0;

        //populate last months daily values
        if(estData.length >=7) {
            for (let i = 0; i < 7; i++) {
                lastMonth.push(estData[i].netRevenue/(estData[i].distinctDateCount/estData[i].hpdYear));
            }
            //populate last year prev months daily values
            if (estData.length >= 14) {
                for (let i = 7; i < 14; i++) {
                    lastYearPrevMonth.push(estData[i].netRevenue/(estData[i].distinctDateCount/estData[i].hpdYear));
                }
                console.log(lastYearPrevMonth);
                for (let i = 14; i < 21; i++) {
                    lastYearMonth.push(estData[i].netRevenue/(estData[i].distinctDateCount/estData[i].hpdYear));
                }
                console.log(lastYearMonth);
                for(let i=0; i<7; i++){
                    seasonality.push((lastYearMonth[i]-lastYearPrevMonth[i])/(lastYearPrevMonth[i]));
                }
                console.log(seasonality);
                for(let i=0; i<7; i++){
                    if(lastMonth[i]<0){
                        thisMonthEst.push(lastMonth[i]*(1-seasonality[i]));
                    }else{
                        thisMonthEst.push(lastMonth[i]*(1+seasonality[i]));
                    }
                }
                console.log(lastMonth);
                console.log(thisMonthEst);
                for(let i=0; i<7; i++){
                    let numWeekday = this.weekdaysInMonth(yesterday.getFullYear(), yesterday.getMonth(), i);
                    console.log('weekday: '+i+' = '+numWeekday);
                    totalEstimateRevenue += numWeekday * thisMonthEst[i];
                }
                console.log(totalEstimateRevenue);
            } else {
                //backup formula for locations with no daily data from 12 months ago?
            }
        }else{
            //no data from last month, newly live
        }
        */


        /*
        if(ytdData.length === 2 && ytdData[1].netRevenue !== 0){
            let x=((ytdData[0].netRevenue - ytdData[1].netRevenue)/ytdData[1].netRevenue)*100;
            cmp.set('v.ytdRevenueDiff', x.toFixed(2));
            cmp.set('v.ytdRevenueDiffString', x.toFixed(2));
        }
        */
        //cmp.set('v.ytdRevenue', this.formatNumberWithCommas(ytdData[0].netRevenue));

    },
    processYTDRevenue: function(cmp, response){
        let dto = response; //array with 2 wrappers in it
        let ytdData= [];
        //---this.collectionUtils.getMapValue('YTD_DATA', dto.values, function (value) {ytdData = value;});
        ytdData = this.collectionUtils.getData('YTD_DATA',dto.values);
        if(ytdData.length === 2 && ytdData[1].netRevenue !== 0){
            let x=((ytdData[0].netRevenue - ytdData[1].netRevenue)/ytdData[1].netRevenue)*100;
            cmp.set('v.ytdRevenueDiff', x.toFixed(2));
            cmp.set('v.ytdRevenueDiffString', x.toFixed(2));
        }

        cmp.set('v.ytdRevenue', this.formatNumberWithCommas(ytdData[0].netRevenue));

        //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        if(ytdData && ytdData.length > 0) {
            let revenueYtdYear = this.collectionUtils.getData('REVENUE_YTD_YEAR',dto.values);
            //=== DEPRECATED this.collectionUtils.getMapValue('REVENUE_YTD_YEAR', dto.values, function (value) {revenueYtdYear = value;});

            if(revenueYtdYear && this.isInt(revenueYtdYear)) {
                cmp.set('v.year',revenueYtdYear);
            }
        }
        //---
    },
    processMTDRevenue: function(cmp, response){
        let dto = response; //array with 2 wrappers in it
        let mtdData =  this.collectionUtils.getData('MTD_DATA',dto.values);
        //--- DEPRECATED this.collectionUtils.getMapValue('MTD_DATA', dto.values, function (value) {mtdData = value;});
        if(mtdData.length >= 3 && mtdData[2].netRevenue !== 0){
            let x=((mtdData[1].netRevenue - mtdData[2].netRevenue)/mtdData[2].netRevenue)*100;
            cmp.set('v.mtdRevenueDiffMOM', x.toFixed(2));
            cmp.set('v.mtdRevenueDiffMOMString', x.toFixed(2));
        }
        if(mtdData.length === 4 && mtdData[3].netRevenue !== 0){
            let y=((mtdData[0].netRevenue - mtdData[3].netRevenue)/mtdData[3].netRevenue)*100;
            cmp.set('v.mtdRevenueDiffYOY', y.toFixed(2));
            cmp.set('v.mtdRevenueDiffYOYString', y.toFixed(2));
        }
        cmp.set('v.mtdRevenue', this.formatNumberWithCommas(mtdData[0].netRevenue));
        //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        if(mtdData && mtdData.length>0) {
            let revenueMtdMonthName =  this.collectionUtils.getData('REVENUE_MTD_MONTH_NAME',dto.values);
            // deprecated this.collectionUtils.getMapValue('REVENUE_MTD_MONTH_NAME', dto.values,
            //     function (value) {revenueMtdMonthName = value;});
            cmp.set('v.revenueMtdMonthName',revenueMtdMonthName);
        }
        //---
    },
    processAggregateMachineData: function(cmp, response){
        let dto =  response;
        let hpdData = [];
        //--deprecated this.collectionUtils.getMapValue('HPD_WRAPPER_MACHINE_AGGREGATE', dto.values, function(value) {hpdData = value;});
        hpdData = this.collectionUtils.getData('HPD_WRAPPER_MACHINE_AGGREGATE',dto.values);
        cmp.set('v.aggregateMachineData', hpdData);
        this.buildDataTable(cmp);

            if (this.chartStyle === 'fundsin') {
                this.renderFundsPieChart(cmp);
            } else {
                this.renderPieChart(cmp);
            }
        //this.renderPieChart(cmp);
    },
    processDailyMachineData: function(cmp, response){
        let dto =  response;
        let hpdData = [];
        //-deprecated this.collectionUtils.getMapValue('HPD_WRAPPER_MACHINE_DAILY', dto.values, function(value) {hpdData = value;});
        hpdData = this.collectionUtils.getData('HPD_WRAPPER_MACHINE_DAILY',dto.values);
        cmp.set('v.dailyMachineData', hpdData);
        //this.render3dChart(cmp, 'Revenue');
    },
    /*render3dChart: function(cmp, metric){
        let self= this;
       // let chartDiv = cmp.find("accel-3d-canvas").getElement();
        let rawData=self.build3dData(cmp, metric);
        let data = [];
        let models = rawData.models;
        let dates = rawData.dates;
        let xData = rawData.xData;
        let yData = rawData.yData;
        let zData = rawData.zData;
        for(let i=0; i<xData.length; i++){
            data.push([xData[i], yData[i], zData[i]]);
       }
        console.log('models');
        console.log(models);
        console.log('dates');
        console.log(dates);
        console.log('data');
        console.log(data);
        let option = {
            grid3D: {
                show: true
            },
            xAxis3D: {
                type: 'category',
                data: models
            },
            yAxis3D: {
                type: 'category',
                data: yData
            },
            zAxis3D: {

            },
            visualMap: {},
            dataset: {
                dimensions: [
                    'Date', 'Revenue', 'Model'
                ],
                source: data
            },
            series: [{
                type: 'bar3D',
                shading: 'lambert',
                encode: {
                    x: 'Model',
                    y: 'Date',
                    z: 'Revenue',
                    tooltip: [2,0,1]
                }
            }]

        };

        //this.machineChart = echarts.init(chartDiv, 'light');


        if(window.matchMedia("(max-width: 896px)").matches){
            //mobile
            //this.machineChart.setOption(option);
        }else{
            //this.machineChart.setOption(option);
        }
    }, */
    renderPieChart: function(cmp){
        if(!cmp.get('v.renderMachineChart')) {
            return;
        }
        let self = this;
        if(this.pieChart){
            this.pieChart.clear();
        }

        let pieDiv = cmp.find("machinePie").getElement();
        let data=self.buildPieData(cmp);
        let option = {
            title: {
                show: false,
                text: 'Revenue Breakdown',
                top: 0,
                left: 'center',
                textStyle: {
                    fontSize: 18
                }
            },
            legend: {
                show: false,
                type: 'scroll',
                orient: 'horizontal',
                top: 0,
                left: 'center',
                data: data.legendData
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
                right: 5,
                top: 0
            },
            tooltip: {
                formatter: function(param){
                    if(param.data.netRevenue) {
                        var text = '';
                        text = '<b>' + param.name + '</b><br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(param.data.netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(param.data.locShare.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(param.data.fundsIn.toFixed(0)) + '<br/>';
                        text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2)) + '<br/>';
                        text = text+ 'Payout: ' + (param.data.amtPlayed > 0 ? ((param.data.amtWon/param.data.amtPlayed)*100).toFixed(2)+'%': '--');
                        //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                        return text;
                    }else{
                        var text = '';
                        text = '<b>' + param.name + '</b><br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(param.value.toFixed(2)) + '<br/>';
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(param.data.locShare.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(param.data.fundsIn.toFixed(0)) + '<br/>';
                        text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2)) + '<br/>';
                        text = text+ 'Payout: ' + (param.data.amtPlayed > 0 ? ((param.data.amtWon/param.data.amtPlayed)*100).toFixed(2)+'%': '--');
                        //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                        return text;
                    }
                }
            },
            series: [{
                type: 'pie',
                minAngle: 5,
                label: {
                    fontSize: 14,
                    fontWeight: 'bolder',
                    formatter: function (params) {
                        if (params.name.length > 12) {
                            var title = params.name.split(' ');
                            title.forEach(function(item, i, title){
                                if(title.length>2){
                                    //three words in model split on 2nd space
                                    if(i==1){
                                        title[i]+= "\n";
                                    }else{
                                        title[i] += ' ';
                                    }
                                }else { //two words in model split on first space
                                    if (i == 0) {
                                        title[i] += "\n";
                                    } else {
                                        title[i] += ' ';
                                    }
                                }
                            });
                            return title.join('')+'\n';
                        } else {
                            return params.name +'\n';
                        }
                    },
                },
                labelLine: {
                    length: 8,
                    length2: 8
                },
                radius: '68%',
                center: ['50%', '50%'],
                data: data.seriesData,
            },{
                type: 'pie',
                minAngle: 5,
                label: {
                    position: 'inside',
                    fontSize: 13,
                    fontWeight: 'bold',
                    color: '#000000',
                    formatter: function (params) {
                        if(params.percent < 3){
                            return '';
                        }else if(params.percent < 6) {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }else {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }
                    },

                },
                radius: '68%',
                center: ['50%', '50%'],
                data: data.seriesData,
            }],


        };
        let mOption = {
            title: {
                show: false,
                text: 'Revenue Breakdown',
                top: 0,
                left: 'center',
                textStyle: {
                    fontSize: 18
                }
            },
            legend: {
                show: false,
                type: 'plain',
                orient: 'horizontal',
                top: 0,
                left: 'center',
                textStyle:{
                    fontSize: 9
                },
                data: data.legendData
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
                right: 5,
                top: 0
            },
            tooltip: {
                confine: true,
                formatter: function(param){
                    if(param.data.netRevenue) {
                        var text = '';
                        text = '<b>' + param.name + '</b><br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(param.data.netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(param.data.locShare.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(param.data.fundsIn.toFixed(0)) + '<br/>';
                        text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2)) + '<br/>';
                        text = text+ 'Payout: ' + (param.data.amtPlayed > 0 ? ((param.data.amtWon/param.data.amtPlayed)*100).toFixed(2)+'%': '--');
                        //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                        return text;
                    }else{
                        var text = '';
                        text = '<b>' + param.name + '</b><br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(param.value.toFixed(2)) + '<br/>';
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(param.data.locShare.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(param.data.fundsIn.toFixed(0)) + '<br/>';
                        text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2)) + '<br/>';
                        text = text+ 'Payout: ' + (param.data.amtPlayed > 0 ? ((param.data.amtWon/param.data.amtPlayed)*100).toFixed(2)+'%': '--');
                        //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                        return text;
                    }
                }
            },
            series: [{
                type: 'pie',
                minAngle: 10,
                label: {
                    fontSize: 8,
                    color: '#000000',
                    fontWeight: 'bold',
                    formatter: function (params) {
                        if (params.name.length > 12) {
                            var title = params.name.split(' ');
                            title.forEach(function(item, i, title){
                                if(title.length>2){
                                    //three words in model split on 2nd space
                                    if(i==1){
                                        title[i]+= "\n";
                                    }else{
                                        title[i] += ' ';
                                    }
                                }else { //two words in model split on first space
                                    if (i == 0) {
                                        title[i] += "\n";
                                    } else {
                                        title[i] += ' ';
                                    }
                                }
                            });
                            return title.join('')+'\n';
                        } else {
                            return params.name +'\n';
                        }
                    },
                },
                labelLine: {
                    length: 3,
                    length2: 3
                },
                radius: '73%',
                center: ['50%', '50%'],
                data: data.seriesData,
            },{
                type: 'pie',
                minAngle: 10,
                label: {
                    position: 'inside',
                    fontSize: 9,
                    fontWeight: 'bold',
                    color: '#000000',
                    formatter: function (params) {
                        if(params.percent < 3){
                            return '';
                        }else if(params.percent < 6) {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }else {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }
                    },

                },
                radius: '73%',
                center: ['50%', '50%'],
                data: data.seriesData,
            }],


        };
        this.pieChart = echarts.init(pieDiv, 'light');
        let mQuery = window.matchMedia("(max-width: 767px)");
        if(mQuery.matches){
            //mobile
            this.pieChart.setOption(mOption);
        }else{
            this.pieChart.setOption(option);
        }
        self.chartStyle = 'revenue';
    },
    renderFundsPieChart: function(cmp){
        let self = this;
        if(this.pieChart){
            this.pieChart.clear();
        }
        let pieDiv = cmp.find("machinePie").getElement();
        let data=self.buildFundsPieData(cmp);
        let option = {
            title: {
                show: false,
                text: 'Funds In Breakdown',
                top: 0,
                left: 'center',
                textStyle: {
                    fontSize: 18
                }
            },
            legend: {
                show: false,
                type: 'scroll',
                orient: 'horizontal',
                top: 15,
                left: 'center',
                data:  data.seriesData
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
                right: 5,
                top: 10
            },
            tooltip: {
                formatter: function(param){
                    var text = '';
                    text = '<b>' + param.name + '</b><br/>';
                    text = text + 'Net Revenue: $' + self.formatNumberWithCommas(param.data.revenue.toFixed(2)) + '<br/>';
                    text = text + 'Location Share: $' + self.formatNumberWithCommas(param.data.locShare.toFixed(2)) + '<br/>';
                    text = text + 'Funds In: $' + self.formatNumberWithCommas(param.value.toFixed(0)) + '<br/>';
                    text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    text = text + 'Amount Played: $' + self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2)) + '<br/>';
                    text = text+ 'Payout: ' + (param.data.amtPlayed > 0 ? ((param.data.amtWon/param.data.amtPlayed)*100).toFixed(2)+'%': '--');
                    //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    return text;
                }
            },
            series: [{
                type: 'pie',
                minAngle: 5,
                label: {
                    fontSize: 14,
                    fontWeight: 'bolder',
                    formatter: function (params) {
                        if (params.name.length > 12) {
                            var title = params.name.split(' ');
                            title.forEach(function(item, i, title){
                                if(title.length>2){
                                    //three words in model split on 2nd space
                                    if(i==1){
                                        title[i]+= "\n";
                                    }else{
                                        title[i] += ' ';
                                    }
                                }else { //two words in model split on first space
                                    if (i == 0) {
                                        title[i] += "\n";
                                    } else {
                                        title[i] += ' ';
                                    }
                                }
                            });
                            return title.join('')+'\n';
                        } else {
                            return params.name +'\n';
                        }
                    },
                },
                labelLine: {
                    length: 8,
                    length2: 8
                },
                radius: '68%',
                center: ['50%', '50%'],
                data: data.seriesData,
            },{
                type: 'pie',
                minAngle: 5,
                label: {
                    position: 'inside',
                    fontSize: 13,
                    fontWeight: 'bold',
                    color: '#000000',
                    formatter: function (params) {
                        if(params.percent < 3){
                            return '';
                        }else if(params.percent < 6) {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }else {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }
                    },

                },
                radius: '68%',
                center: ['50%', '50%'],
                data: data.seriesData,
            }],


        };
        let mOption = {
            title: {
                show: false,
                text: 'Funds In Breakdown',
                top: 0,
                left: 'center',
                textStyle: {
                    fontSize: 18
                }
            },
            legend: {
                show: false,
                type: 'plain',
                orient: 'horizontal',
                top: 35,
                left: 'center',
                textStyle:{
                    fontSize: 11
                },
                data:  data.seriesData
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
                right: 5,
                top: 0
            },
            tooltip: {
                confine: true,
                formatter: function(param){
                    var text = '';
                    text = '<b>' + param.name + '</b><br/>';
                    text = text + 'Net Revenue: $' + self.formatNumberWithCommas(param.data.revenue.toFixed(2)) + '<br/>';
                    text = text + 'Location Share: $' + self.formatNumberWithCommas(param.data.locShare.toFixed(2)) + '<br/>';
                    text = text + 'Funds In: $' + self.formatNumberWithCommas(param.value.toFixed(0)) + '<br/>';
                    text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    text = text + 'Amount Played: $' + self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2)) + '<br/>';
                    text = text+ 'Payout: ' + (param.data.amtPlayed > 0 ? ((param.data.amtWon/param.data.amtPlayed)*100).toFixed(2)+'%': '--');
                    //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    return text;
                }
            },
            series: [{
                type: 'pie',
                minAngle: 10,
                label: {
                    fontSize: 8,
                    color: '#000000',
                    fontWeight: 'bold',
                    formatter: function (params) {
                        if (params.name.length > 12) {
                            var title = params.name.split(' ');
                            title.forEach(function(item, i, title){
                                if(title.length>2){
                                    //three words in model split on 2nd space
                                    if(i==1){
                                        title[i]+= "\n";
                                    }else{
                                        title[i] += ' ';
                                    }
                                }else { //two words in model split on first space
                                    if (i == 0) {
                                        title[i] += "\n";
                                    } else {
                                        title[i] += ' ';
                                    }
                                }
                            });
                            return title.join('')+'\n';
                        } else {
                            return params.name +'\n';
                        }
                    },
                },
                labelLine: {
                    length: 3,
                    length2: 3
                },
                radius: '73%',
                center: ['50%', '50%'],
                data: data.seriesData,
            },{
                type: 'pie',
                minAngle: 10,
                label: {
                    position: 'inside',
                    fontSize: 9,
                    color: '#000000',
                    fontWeight: 'bold',
                    formatter: function (params) {
                        if(params.percent < 3){
                            return '';
                        }else if(params.percent < 6) {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }else {
                            if(params.value<1000){
                                return self.formatValue('$',params.value,0) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }else{
                                return self.formatValue('$',params.value,1) + '\n'+'('+ params.percent.toFixed(0)+'%)';
                            }
                        }
                    },

                },
                radius: '73%',
                center: ['50%', '50%'],
                data: data.seriesData,
            }],


        };
        this.pieChart = echarts.init(pieDiv, 'light');

        if(window.matchMedia("(max-width: 767px)").matches){
            //mobile
            this.pieChart.setOption(mOption);
        }else{
            this.pieChart.setOption(option);
        }
        self.chartStyle = 'fundsin';
    },
    /* build3dData: function(cmp, metric){
        let hpdArray;
        hpdArray=cmp.get('v.dailyMachineData');
        let models = []; //model names
        let xData = []; //coordinate mapping to model names
        let yData = []; //date
        let zData = []; //value, using revenue
        let assetId;
        let assetModelName;
        let assetModelNameIndex =0;

        const dates = [...new Set(hpdArray.map( x => x.hpdDate))];
        dates.sort();

        if(hpdArray){
            assetId = hpdArray[0].assetId;
            assetModelName = hpdArray[0].assetModel;
            models.push(assetModelName);
            for (let i = 0; i < hpdArray.length; i++) {
                let currRecord = hpdArray[i];
                if(assetId !== currRecord.assetId){
                    //update model index
                    assetModelNameIndex = assetModelNameIndex +1;
                    //update model name
                    assetModelName = currRecord.assetModel;
                    //update assetId
                    assetId=currRecord.assetId;
                    //push new model name into array
                    models.push(currRecord.assetModel);
                }
                xData.push(assetModelNameIndex);
                yData.push(dates.indexOf(currRecord.hpdDate));
                if(metric ==='Revenue'){
                    zData.push(currRecord.netRevenue);
                }else if(metric==='Funds In'){
                    zData.push(currRecord.fundsIn);
                }else if(metric ==='Amount Played'){
                    zData.push(currRecord.fundsIn)
                }
            }
        }

        return{
            models: models,
            dates: dates,
            xData: xData,
            yData: yData,
            zData: zData
        }
    }, */
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/294451317
     * Finds duplicate asset model names and models to the model name to [Model Name] (i) ie. WMS Blue Bird2 (1)
     *
     * @param cmp     the current component instance.
     * @param hpdArr  the array of HpdWrapper Objects (original array modified if needed per standard js pass by ref rules)
     *
     * @TODO probably can be generalized to pass in property to check for dup on but that should be moved to a utils svv object.
     */
    fixDuplicateModelNames: function ( cmp,hpdArr ) {
        if(hpdArr && hpdArr.length > 1) {
            //  Use reduce to make a counter lookup table based on the assetModel key and filter to remove any items
            //  that appear only once... O(n) time complexity.
            const lookup = hpdArr.reduce((a, e) => {
                a[e.assetModel] = e.assetModel in a ? ++a[e.assetModel] : 0;
                return a;
            }, {});
            let hpdModelDups = hpdArr.filter(e => lookup[e.assetModel]);
            //  Roll through the dups and modify the asset Model name by with a suffix of (i),
            if(hpdModelDups && hpdModelDups.length > 0) {
                for(let i=0; i<hpdModelDups.length; i++) {
                    let hpdModelDup  = hpdModelDups[i];
                    hpdModelDup.assetModel += ' ('+(i+1)+')';
                }
            }
        }
    },
    buildPieData: function(cmp){
        let self = this;
        let hpdArray;
        hpdArray=cmp.get('v.aggregateMachineData');
        let seriesData = [];
        let legendData = [];
        let revTotal =0;
        let fundsInTotal = 0;
        let amtWon = 0;

        if(hpdArray){
            // https://accel-entertainment.monday.com/boards/286658657/pulses/294451317
            try {
                this.fixDuplicateModelNames(cmp, hpdArray);
            } catch (e) {
                this.log(cmp,'Error fixing duplicate asset model names','error',e);
            }
            hpdArray.sort(function(a,b) { return b.locShare - a.locShare;});
        }
        for(let i=0; i<hpdArray.length; i++){
            let currRecord=hpdArray[i];
            revTotal += currRecord.netRevenue;
            fundsInTotal += currRecord.fundsIn;
            amtWon += currRecord.amtWon;
            legendData.push({
                name: currRecord.assetModel,
                value: currRecord.assetId
            });
            if(currRecord.netRevenue<0){
                seriesData.push({
                    name: currRecord.assetModel,
                    value: 0,
                    netRevenue: currRecord.netRevenue,
                    fundsIn: currRecord.fundsIn,
                    fundsOut: currRecord.fundsOut,
                    amtPlayed: currRecord.amtPlayed,
                    amtWon: currRecord.amtWon,
                    locShare: currRecord.locShare,
                });
            }else {
                seriesData.push({
                    name: currRecord.assetModel,
                    value: currRecord.netRevenue,
                    fundsIn: currRecord.fundsIn,
                    fundsOut: currRecord.fundsOut,
                    amtPlayed: currRecord.amtPlayed,
                    amtWon: currRecord.amtWon,
                    locShare: currRecord.locShare
                });
            }
        }
        cmp.set('v.totalRevenue', '$'+self.formatNumberWithCommas(revTotal.toFixed(2)));
        cmp.set('v.totalFundsIn', '$'+self.formatNumberWithCommas(fundsInTotal.toFixed(0)));
        cmp.set('v.totalAmountWon', '$'+self.formatNumberWithCommas(amtWon.toFixed(2)));
        return{
            legendData: legendData,
            seriesData: seriesData
        }
    },
    buildFundsPieData: function(cmp){
        let self = this;
        let hpdArray;
        hpdArray=cmp.get('v.aggregateMachineData');
        let seriesData = [];
        let legendData = [];
        let revTotal =0;
        let fundsInTotal = 0;
        let amtWon = 0;


        if(hpdArray){
            hpdArray.sort(function(a,b) { return b.fundsIn - a.fundsIn;});
        }
        for(let i=0; i<hpdArray.length; i++){
            let currRecord=hpdArray[i];
            revTotal += currRecord.netRevenue;
            fundsInTotal += currRecord.fundsIn;
            amtWon += currRecord.amtWon;
            legendData.push({
                name: currRecord.assetModel,
                value: currRecord.assetId
            });
            seriesData.push({
                name: currRecord.assetModel,
                value: currRecord.fundsIn,
                revenue: currRecord.netRevenue,
                fundsOut: currRecord.fundsOut,
                amtPlayed: currRecord.amtPlayed,
                amtWon: currRecord.amtWon,
                locShare: currRecord.locShare
            });
        }
        cmp.set('v.totalRevenue', '$'+self.formatNumberWithCommas(revTotal.toFixed(2)));
        cmp.set('v.totalFundsIn', '$'+self.formatNumberWithCommas(fundsInTotal.toFixed(0)));
        cmp.set('v.totalAmountWon', '$'+self.formatNumberWithCommas(amtWon.toFixed(2)));
        return{
            legendData: legendData,
            seriesData: seriesData
        }
    },
    buildDataTable: function(cmp){
        let data = cmp.get('v.aggregateMachineData');
        let dataTable = [];
        let revTotal =0;
        let fundsInTotal = 0;
        let amtPlayedTotal = 0;
        let mostProfitMachine = '';
        let mostProfitMachineVar = 0;
        let mostPopularMachine = '';
        let mostPopularMachineVar = 0;
        for(let i=0; i<data.length; i++){
            revTotal=revTotal+data[i].netRevenue;
            fundsInTotal = fundsInTotal+data[i].fundsIn;
            amtPlayedTotal = amtPlayedTotal+data[i].amtPlayed;
            if(data[i].netRevenue > mostProfitMachineVar){
                mostProfitMachineVar = data[i].netRevenue;
                mostProfitMachine = data[i].assetModel;
            }
            if(data[i].fundsIn > mostPopularMachineVar){
                mostPopularMachineVar = data[i].fundsIn;
                mostPopularMachine = data[i].assetModel;
            }
        }
        if(revTotal !==0) {
            cmp.set('v.mostProfitableMachine', mostProfitMachine + ' (' + ((mostProfitMachineVar / revTotal)*100).toFixed(2) + '%)');
        }
        if(fundsInTotal !==0){
            cmp.set('v.mostPopularMachine', mostPopularMachine + ' ('+ ((mostPopularMachineVar / fundsInTotal)*100).toFixed(2) + '%)');
        }

        for(let i=0; i<data.length; i++){
            let currRecord=data[i];
            dataTable.push({
                assetModel: currRecord.assetModel,
                //netRevenue: (currRecord.netRevenue > 0 ? '$'+this.formatNumberWithCommas(currRecord.netRevenue)+' ('+((currRecord.netRevenue/revTotal)*100).toFixed(2)+'%)' : '$0 (0%)'),
                netRevenue: '$'+this.formatNumberWithCommas(currRecord.netRevenue)+' ('+((currRecord.netRevenue/revTotal)*100).toFixed(2)+'%)',
                fundsIn: (currRecord.fundsIn > 0 ? '$'+this.formatNumberWithCommas(currRecord.fundsIn)+' ('+((currRecord.fundsIn/fundsInTotal)*100).toFixed(2)+'%)' : '$0 (0%)'),
                amtPlayed: (currRecord.amtPlayed > 0 ? '$'+this.formatNumberWithCommas(currRecord.amtPlayed)+' ('+((currRecord.amtPlayed/amtPlayedTotal)*100).toFixed(2)+'%)' : '$0 (0%)'),
                payout: (currRecord.amtPlayed > 0 ? ((currRecord.amtWon/currRecord.amtPlayed)*100).toFixed(2)+'%': '0%'),
                walkaway: (currRecord.fundsIn > 0 ? ((currRecord.fundsOut/currRecord.fundsIn)*100).toFixed(2)+'%': '0%')
            });
        }
        cmp.set('v.dataTable', dataTable);
    },
    buildHistoricalTable: function(cmp){
        let self = this;
        let data = cmp.get('v.historicalData');
        let format = cmp.get('v.selectedFrequency');
        let dataTable = [];
        for(let i=0; i<data.length; i++){
            let currRecord=data[i];
            dataTable.push({
                hpdId: currRecord.hpdId,
                hpdDate: (format === 'Daily' ? $A.localizationService.formatDate(currRecord.hpdDate, 'MMM d, YYYY') : $A.localizationService.formatDate(currRecord.hpdDate, 'MMM YYYY') ),
                locShare: '$'+self.formatNumberWithCommasFraction((currRecord.locShare*1).toFixed(2),2),
                netRevenue: '$'+self.formatNumberWithCommasFraction((currRecord.netRevenue*1).toFixed(2),2),
                fundsIn: '$'+self.formatNumberWithCommasFraction(currRecord.fundsIn,0),
                fundsOut: '$'+self.formatNumberWithCommasFraction((currRecord.fundsOut*1).toFixed(2),2),
                amtPlayed: '$'+self.formatNumberWithCommasFraction((currRecord.amtPlayed*1).toFixed(2),2),
                amtWon: '$'+self.formatNumberWithCommasFraction((currRecord.amtWon*1).toFixed(2),2),
            });
        }
      cmp.set('v.historicalDataTable', dataTable);
    },
    processMonth: function(cmp, dateString){
      let d = new Date(dateString);
      d.setDate(d.getDate() +1);
      let lastDay = new Date(d.getFullYear(),d.getMonth()+1, 0);
     cmp.set('v.startDate', $A.localizationService.formatDate(d, 'YYYY-MM-dd'));
     cmp.set('v.endDate', $A.localizationService.formatDate(lastDay, 'YYYY-MM-dd'));
     this.log(cmp,'in processMonth calling retrieveAggregateMachineData');
     this.retrieveAggregateMachineData(cmp);
    },
    /* old formatNumberWithCommas: function(x){
        var parts = x.toString().split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    },
  */
    setHistoricalDataDates: function(cmp){
      let serverYesterdayDate = cmp.get('v.serverYesterdayDate');
        //set historical data start date
        let startHDate = new Date();
        let endHDate = new Date();
        endHDate.setDate(startHDate.getDate() - 1);
        if(serverYesterdayDate){
            cmp.set('v.endHDate', serverYesterdayDate);
            startHDate = new Date(serverYesterdayDate);
            startHDate.setDate(startHDate.getDate()-28);
            cmp.set('v.startHDate', $A.localizationService.formatDate(startHDate, 'YYYY-MM-dd'));

        }else{
            //@todo @rick why would this execute before serverYesterdayDate is set thus the need for below? happened a few times before midnight
            startHDate.setDate(startHDate.getDate()-30);
            cmp.set('v.startHDate', $A.localizationService.formatDate(startHDate, 'YYYY-MM-dd'));
            cmp.set('v.endHDate', $A.localizationService.formatDate(endHDate, 'YYYY-MM-dd'));

        }

    },

    setYesterday: function(cmp) {
        let sMonthSelected = this.getUrlParam('month');
        let sDaySelected = this.getUrlParam('yesterday');
        let homeSingleDay = this.getUrlParam('day');
        this.log(cmp,'setYesterday getUrlParam sMonthSelected=','debug',sMonthSelected);
        this.log(cmp,'homeSingleDay getUrlParams homeSingleDay=','debug',homeSingleDay);
        //  8-23-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
        let serverYesterdayDate = cmp.get('v.serverYesterdayDate');
        if(sDaySelected ==='true'){
            //home page click on account in yesterday bar graph in yesterdayshare.cmp
            let startDate = new Date();
            startDate.setDate(startDate.getDate() - 1);
            //  8-23-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
            let yesterday;
            if(serverYesterdayDate) {
                yesterday = serverYesterdayDate;
            } else {
                yesterday = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
            }
            //  ------------------
            cmp.set('v.yesterday', yesterday);
            cmp.set('v.endDate', yesterday);
            cmp.set('v.startDate', yesterday);
            cmp.set('v.selectedDate', 'Yesterday');
        }else if(homeSingleDay){
            //home page single account graph click on daily chart
            this.log(cmp,'setYesterday.. homeSingleDay='+homeSingleDay,'debug');
            let startDate = new Date(homeSingleDay);
            //converts time to day before for some reason, bump it up again
            startDate.setDate(startDate.getDate()+1);
            let fDate = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
            let yesterday = new Date();
            yesterday.setDate(startDate.getDate() - 1);
            let yesterdayF = $A.localizationService.formatDate(yesterday, 'YYYY-MM-dd');
            cmp.set('v.yesterday', $A.localizationService.formatDate(yesterdayF, 'YYYY-MM-dd'));
            cmp.set('v.endDate', fDate);
            cmp.set('v.startDate', fDate);
            cmp.set('v.selectedDate', 'Cust');
            this.log(cmp,'setYesterday set v.selecteDate=Cust','debug');
        }else if (!sMonthSelected) {
            //normal function upon navigation to page
            let d = new Date();
            let daysBack = cmp.get('v.selectedDate');
            d.setDate(d.getDate() - 1);
            
            let s = new Date(new Date().setDate(new Date().getDate() - daysBack));
            //  8-23-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017-->
            let yesterday;
            if(serverYesterdayDate) {
                yesterday = serverYesterdayDate;
            } else {
                //  yesterday = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
                //8-27-2019.. above was causing error:start date is undefined.. use local d as opposed to startDate
                yesterday = $A.localizationService.formatDate(d, 'YYYY-MM-dd');
            }
            //----------------
            cmp.set('v.yesterday', yesterday);
            cmp.set('v.startDate', $A.localizationService.formatDate(s, 'YYYY-MM-dd'));
            cmp.set('v.endDate', $A.localizationService.formatDate(d, 'YYYY-MM-dd'));
        }else {
            //home page clicked on specific month for single account in bottom chart
            let d = new Date();
            d.setDate(d.getDate() - 1);
            //  8-23-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017-->
            //cmp.set('v.yesterday', $A.localizationService.formatDate(d, 'YYYY-MM-dd'));
            let yesterday;
            if(serverYesterdayDate) {
                yesterday = serverYesterdayDate;
            } else {
                yesterday = $A.localizationService.formatDate(d, 'YYYY-MM-dd');
            }
            // ---------------
            let startDate = new Date();
            startDate.setTime(sMonthSelected);
            let lastDayOfMonth = getLastDayofMonth(startDate.getFullYear(), startDate.getMonth());
            let endDate = new Date(startDate).setDate(lastDayOfMonth);
            let sEndDate = $A.localizationService.formatDate(endDate, 'YYYY-MM-dd');
            cmp.set('v.endDate', sEndDate);
            let sStartDate = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
            cmp.set('v.startDate', sStartDate);
            cmp.set('v.selectedDate', sStartDate);
        }
        function getLastDayofMonth(y, m) {
            return new Date(y, m + 1, 0).getDate();
        }
        window.history.replaceState(null, null, window.location.pathname);
    },
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
    initColumns: function (cmp) {
        cmp.set('v.columns', [
            {   label: 'Date',
                fieldName: 'hpdDate',
                type: 'text',
                sortable: false,
                fixedWidth: 83
            },{
                label: 'Location Share',
                fieldName: 'locShare',
                type: 'currency',
                sortable: false,
                fixedWidth: 97,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Revenue',
                fieldName: 'netRevenue',
                type: 'currency',
                sortable: false,
                fixedWidth: 97,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Funds In',
                fieldName: 'fundsIn',
                type: 'currency',
                sortable: false,
                fixedWidth: 97,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Funds Out',
                fieldName: 'fundsOut',
                type: 'currency',
                sortable: false,
                fixedWidth: 97,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Amount Played',
                fieldName: 'amtPlayed',
                type: 'currency',
                sortable: false,
                fixedWidth: 97,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Amount Won',
                fieldName: 'amtWon',
                type: 'currency',
                sortable: false,
                fixedWidth: 97,
                cellAttributes: {alignment: 'left'}
            }
        ]);
    },

    setUserAccountOptions: function (cmp) {
        let accounts = cmp.get('v.userAccounts');
        let accountOptions = [];
        if(accounts) {
            for(let i=0; i<accounts.length; i++) {
                let account = accounts[i];
                let concatName;
                concatName = account.Name + ' - ' + account.ShippingStreet + ' - ' + account.ShippingCity;
                let accountOption = {'label': concatName, 'value': account.Id};
                accountOptions.push(accountOption);

            }
        }
        cmp.set('v.userAccountOptions',accountOptions);
    },
    getAccountById: function (arr, value) {
        for (let i = 0, iLen = arr.length; i < iLen; i++) {
            if (arr[i].Id === value) return arr[i];
        }
    },
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    windowResizing: function (cmp, evt, helper) {
        let self = this;
        let tabSelection = cmp.get('v.mainTabsetSelectedTab');
        if(self.pieChart){
            // resize function did not re-evaluate media width to change setOptions, work around
            //self.pieChart.resize();

            //only resize if on the performance tab otherwise resizing while tab has 0 width causes no chart
            if(tabSelection === 'perfTab') {
                if (self.chartStyle === 'revenue') {
                    self.renderPieChart(cmp);
                } else if (self.chartStyle === 'fundsin') {
                    self.renderFundsPieChart(cmp);
                }
            }
        }
    },
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function(x) {return primer(x[field])} :
            function(x) {return x[field]};
        //checks if the two rows should switch places
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    weekdaysInMonth: function(year, month, weekday){
        var day, counter, date;
        day = 1;
        counter = 0;
        date = new Date(year, month, day);
        while (date.getMonth() === month) {
            if (date.getDay() === weekday) { // Sun=0, Mon=1, Tue=2, etc.
                counter += 1;
            }
            day += 1;
            date = new Date(year, month, day);
        }
        return counter;
    },
    processBtnClick: function(cmp, event){
        let target;
        let btnClicked;
        if(event){
            target=event.getSource();
            btnClicked = target.get('v.name');
        }
        let btnIds = ["Revenue", "FundsIn"];
        window.setTimeout(function () {
            for(let i = 0; i < btnIds.length; i++) {
                let btnId = btnIds[i];
                let btnCmp = cmp.find(btnId);
                if (btnId === btnClicked) $A.util.addClass(btnCmp, "accel-btn-is-selected");
                else $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            }
        }, 0);

        if(btnClicked !=='Revenue'){
            cmp.set('v.pieTitle', 'Funds In by Machine');
            this.renderFundsPieChart(cmp);

        }else {
            cmp.set('v.pieTitle', 'Revenue by Machine');
            this.renderPieChart(cmp);
        }

    },
    //  8-21-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
    /**
     * Determines if value is an int (or a string representation of an int)
     * @param value
     * @returns {boolean|*}
     * @TODO move to some utils component.
     */
    isInt: function isInt(value) {
        return !isNaN(value) && (function(x) { return (x | 0) === x; })(parseFloat(value))
    },
    formatNumberWithCommasFraction: function(x,y){
        let result = 0;
        try {
            result = Number(parseFloat(x).toFixed(y)).toLocaleString('en', {
                minimumFractionDigits: y
            });

        } catch (e) {
            console.log('error in formatNumberWithCommasFraction function');
            console.error(e);
        }
        return result;
    },
    formatNumberWithCommas: function(x){
        //let parts;
        let result = 0;
        try {
            // parts = x.toString().split(".");
            // parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
            // parts = parts.join(".");
            result = Number(parseFloat(x).toFixed(0)).toLocaleString('en', {
                minimumFractionDigits: 0
            });

        } catch (e) {
            console.log('error in formatNumberWithCommas function');
            console.error(e);
        }
        return result;
    },
    formatValue: function (prefix, value, fixed) {
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

    /**
     * Simply a wrapper around The Utils Component / log method.
     *
     * @param cmp
     * @param msg - the message to log... if includes generic and an error.. will fire toast.
     * @param level [debug,info,warn,error]
     * @param jsonObj  optional a JSON OBJECT and not a string!
     */
    log: function (cmp, msg, level, jsonObj) {
        let lvl;
        let self = this;
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
                let cmpName = '--- '+cmp.getName() + ' CMP --- ';
                let cLogger = self.loggingUtils;
                cLogger.log(cmpName, lvl, msg, jsonObj);
                // https://accel-entertainment.monday.com/boards/286658657/
                if(lvl === 'error' && msg.includes('generic')) {
                    let easyMsg = this.friendlyErrorMsg;
                    this.uiMessagingUtils.displayUiMsg(lvl, easyMsg,this.friendlyErrorMsgMode,this.friendlyErrorMsgDuration);
                }
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    },
    /**
     * Build array dynamically as needed using whatever syntax
     * @param cmp
     */

    /* VARIABLE REFACTORING NEEDED -initially comparison was done by city, but now moved to statewide average for that location type, variables do NOT represent this but work fine */
    buildMachineTabs: function(cmp){
        let self=this;
        let folderName = 'VGTAssets';
        let machineData = cmp.get('v.machineImageData');
        let prevMachineData = cmp.get('v.prevMachineImageData');
        let cityMachineData = cmp.get('v.cityMachineImageData');
        let prevCityMachineData = cmp.get('v.prevCityMachineImageData');
       // console.log(prevMachineData);
       // console.log(cityMachineData);
       // console.log(prevCityMachineData);
        //sort reverse alphabet to try and get WMS machines to show first, they look the best..
        machineData.sort(function(a,b){
            if( a.assetModel < b.assetModel) return -1;
            if( a.assetModel > b.assetModel) return 1;
            return 0;});
        machineData.reverse();

        let machineArrays = [];
        //loop through each model
        for(let i=0; i<machineData.length; i++){
            //set my machine variables for this model
            let numDays = machineData[i].distinctDateCount;
            let modelName = machineData[i].assetModel;
            let avgFundsIn = Number(machineData[i].fundsIn).toFixed(0);
            let vgtUid = machineData[i].vgtUid;
            let fDate = $A.localizationService.formatDate(machineData[i].hpdDate, "M/d/YYYY");
            modelName = modelName.split(' ').join('');
            modelName = modelName.replace('/', '');
            let avgDiff;
            for(let j=0; j<prevMachineData.length; j++){
                if(prevMachineData[j].vgtUid === vgtUid){
                    if(avgFundsIn && prevMachineData[j].fundsIn){
                        let prevAvgFundsIn = Number(prevMachineData[j].fundsIn).toFixed(0);
                        avgDiff = (100*(avgFundsIn - prevAvgFundsIn)/prevAvgFundsIn).toFixed(2);
                    }
                }
            }
            //set city machine stats for this model -NOT CITY VALUES, STATEWIDE VALUES
            let municipalityAvg;
            let municipalityAvgDiff;
            for(let j=0; j<cityMachineData.length; j++){
                if(cityMachineData[j].assetModel === machineData[i].assetModel){
                    if(cityMachineData[j].fundsIn){
                        municipalityAvg = Number(cityMachineData[j].fundsIn).toFixed(0);
                    }
                }
            }
            for(let j=0; j<prevCityMachineData.length; j++){
                if(prevCityMachineData[j].assetModel === machineData[i].assetModel){
                    if(municipalityAvg && prevCityMachineData[j].fundsIn){
                        let prevCityAvgFundsIn = Number(prevCityMachineData[j].fundsIn).toFixed(0);
                        municipalityAvgDiff = (100*(municipalityAvg - prevCityAvgFundsIn)/prevCityAvgFundsIn).toFixed(2);
                    }
                }
            }

            //display machine averages if machine has been live for 3 months (80 instead of 90 incase sgi portal issues..)
            if(numDays >80){
                let md = {
                    index: i +1,
                    tabName: machineData[i].assetModel,
                    imageName: modelName,
                    imageFolder: folderName,
                    imageType:'png',
                    igbTag: machineData[i].vgtUid,
                    liveDate: fDate,
                    avgFundsIn: '$'+avgFundsIn,
                    avgDiff: (avgDiff ? avgDiff : '---'),
                    avgDiffString: (avgDiff ? avgDiff: '---'),
                    municipalityAvg: (municipalityAvg ? municipalityAvg : '---'),
                    municipalityAvgDiff: (municipalityAvgDiff ? municipalityAvgDiff : '---'),
                    municipalityAvgDiffString: (municipalityAvgDiff ? municipalityAvgDiff : '---')
                };
                machineArrays.push(md);
            }else{
                //dont display my machine averages yet
                let md = {
                    index: i+1,
                    tabName: machineData[i].assetModel,
                    imageName: modelName,
                    imageFolder: folderName,
                    imageType:'png',
                    igbTag: machineData[i].vgtUid,
                    liveDate: fDate,
                    avgFundsIn: '$----',
                    avgDiff: 0,
                    avgDiffString: '---',
                    municipalityAvg: (municipalityAvg ? municipalityAvg : '---'),
                    municipalityAvgDiff: (municipalityAvgDiff ? municipalityAvgDiff : '---'),
                    municipalityAvgDiffString: (municipalityAvgDiff ? municipalityAvgDiff : '---')
                };
                machineArrays.push(md);
            }
        }
        cmp.set('v.machineTabData', machineArrays);
    },
    prepCsvExport: function(cmp) {
        if(cmp.get('v.historicalDataTable')) {
            let arr = cmp.get('v.historicalDataTable');
            let fields = ['hpdDate','locShare', 'netRevenue', 'fundsIn', 'fundsOut', 'amtPlayed', 'amtWon'];
            let columns = [
                { label: 'Date', fieldName: 'hpdDate'},
                { label: 'Location Share', fieldName: 'locShare'},
                { label: 'Net Revenue', fieldName: 'netRevenue'},
                { label: 'Funds In', fieldName: 'fundsIn'},
                { label: 'Funds Out', fieldName: 'fundsOut'},
                { label: 'Amt Played', fieldName: 'amtPlayed'},
                { label: 'Amt Won', fieldName: 'amtWon'},
            ];

            let fileName  = 'Location Performance.csv';
            let dto;
            this.csvExporter.doExport(arr,fields,fileName,columns, function(value) {dto = value;});
            this.displayUiMsg(cmp,dto.severity,dto.message);
        }
    },
});