/**
 * Replaced alerts with call to error logging which will pop toast as well when msg is set
 * as generic.
 * https://accel-entertainment.monday.com/boards/286658657/
 */
({
    collectionUtils:null,
    loggingUtils:null,
    formatUtils: null,
    csvExporter: null,
    uiMessagingUtils:null,
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:20000,//20 seconds
    disabledRadarChartTitle:'Select lifetime or choose a month',
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
                    cmp.set('v.displayPctOfNetRevChart',true);
                    //cmp.set('v.displayAverageChart',true);
                    this.log(cmp,'sObject Community_User_Setting__c not found for logged in user!','error');
                } else {
                    cmp.set('v.communityUserSettingsNotFound',false);
                    cmp.set('v.displayPctOfNetRevChart',communityUserSettings.Display_Revenue_Chart__c);
                    //cmp.set('v.displayAverageChart',communityUserSettings.Display_Average_Chart__c);
                    //@TODO call method that sets flags to prevent chained queries and stuff that is hidden.
                    this.log(cmp,'communityUserSettings','info',JSON.stringify(communityUserSettings));
                }
                //all below moved here from init in controller.
                this.processUrlParams(cmp);
                this.initColumns(cmp);
                this.setYesterday(cmp);
                this.retrieveMonthlyHpdDates(cmp);
                // Below moved from onScriptsLoaded
                this.retrieveAggregateLifetimeHpdData(cmp);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    retrieveAccounts: function(cmp) {
        cmp.lax.enqueue('c.retrieveAccounts') //getUserAccounts
            .then(response => {
                this.log(cmp, 'after call to retrieveAccounts response..','debug',response);
                this.processUserAccounts(cmp, response);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    retrieveMonthlyHpdDates: function(cmp){
      cmp.lax.enqueue('c.retrieveMonthlyHpdDates')
          .then(response =>{
              this.log(cmp, 'after call to retrieveMonthlyHpdDates response..','debug',response);
              this.processMonthlyHpdDates(cmp, response);
          })
          .catch(errors => {
              this.log(cmp,'generic','error',JSON.stringify(errors));
          })
    },
    retrieveAggregateLifetimeHpdData: function(cmp){
        cmp.lax.enqueue('c.retrieveAggregateLifetimeHpdData')
            .then( response => {
                this.log(cmp, 'after call to retrieveAggregateLifetimeData response..','debug',response);
                this.processAggregateLifetimeHpd(cmp, response);
                return this.retrieveAggregateMonthlyAverages(cmp);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    retrieveMonthlyPieData: function(cmp, date){
      const params = {dateString: date};

      cmp.lax.enqueue('c.retrieveAggregateMonthlyHpdData', params)
          .then(response =>{
              this.processAggregateMonthlyHpd(cmp, response);
              return this.refreshAggregateAllMonthlyAverages(cmp);
          })
          .catch(errors =>{
              this.log(cmp,'generic','error',JSON.stringify(errors));
          });
    },
    retrieveCustomPieData: function(cmp, start, end){
        const params = {startDate: start, endDate: end};
        cmp.lax.enqueue('c.retrieveAggregateCustomHpdData', params)
            .then(response =>{
                this.log(cmp,'retrieveCustomPieData response from server retrieveAggregateCustomHpdData','info',response);
                this.processAggregateCustomHpd(cmp, response);
            })
            .catch(errors =>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    /**
     *  https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     */
    retrieveAggregateMonthlyAverages: function(cmp){
      cmp.lax.enqueue('c.retrieveAggregateMonthlyAverages')
          .then(response =>{
              this.log(cmp, 'after call to retrieveAggregateMonthlyAverages response..','debug',response);
              this.processAggregateMonthlyAverages(cmp, response);
              if(this.wasLocShareChartClicked(cmp)) {
                  this.processLocationShareTrendChartClick(cmp);
              }
          })
          .catch (errors=>{
              this.log(cmp,'generic','error',JSON.stringify(errors));
          });
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     * Merely checks the attributes on a component to see if we came from the
     * bottom home page chart which passes these attributes as url params.
     *
     * @param cmp
     * @returns {*}
     */
    wasLocShareChartClicked: function(cmp) {
      return cmp.get('v.locShareDateClicked') && cmp.get('v.locShareChartStyle');
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     * @param cmp
     */
    processLocationShareTrendChartClick: function (cmp) {
        let locShareDateClicked = cmp.get('v.locShareDateClicked');
        let locShareChartStyle = cmp.get('v.locShareChartStyle');
        let startDate;

        //  Ensure we are not being called when we shouldn't be.
        if (!locShareDateClicked || locShareDateClicked === '') {
            let msg = 'Exiting processLocationShareTrendChartClick.. Invalid params=';
            msg += ' locShareDateClicked=' + locShareDateClicked + '...locShareChartStyle=' + locShareChartStyle;
            this.log(cmp, msg, 'error');
            return;
        }
        cmp.set('v.locationSelected', 'All Locations');
        startDate = new Date(locShareDateClicked);
        //  Date method converts time to day before for some reason, bump it up again
        startDate.setDate(startDate.getDate() + 1);
        cmp.set('v.startDate', $A.localizationService.formatDate(startDate, 'YYYY-MM-dd'));

        switch (locShareChartStyle) {
            case 'Daily':
                cmp.set('v.selectedDate', 'Cust'); //  This is the Custom Range option in the drop down in the top left.
                cmp.set('v.pieType', 'Custom');
                cmp.set('v.endDate', cmp.get('v.startDate'));
                this.log(cmp, 'calling retrieveCustomPieData', 'debug');
                this.retrieveCustomPieData( cmp, cmp.get('v.startDate'), cmp.get('v.endDate') );
                break;
            case 'Monthly':
                cmp.set('v.selectedDate', cmp.get('v.startDate')); // This is a Specific Month in the drop down top / left.
                cmp.set('v.pieType', 'Monthly');
                this.log(cmp, 'calling retrieveMonthlyPieData', 'debug');
                this.retrieveMonthlyPieData( cmp, cmp.get('v.startDate') );
                break;
            default:
                this.log(cmp, 'Unsupported locShareChartStyle passed: ', 'error', locShareChartStyle);
        }
        locShareDateClicked = null;
        locShareChartStyle = null;
        window.history.replaceState(null, null, window.location.pathname);
    },
    retrieveSingleAccountAggregateMonthlyAverages: function(cmp, id, type, numberAccs, data){
        const params = {accId: id};
        cmp.lax.enqueue('c.retrieveSingleAccountAggregateMonthlyAverages', params)
            .then(response =>{
                this.processSingleAccountAggregateMonthlyAverages(cmp, response, type, numberAccs, data);
            })
            .catch (errors=>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    processSingleAccountAggregateMonthlyAverages: function(cmp, response, type, numberAccs, data){
        let dto =  response;
        let hpdData = [];
        //--- deprecated this.collectionUtils.getMapValue('HPD_WRAPPER_SINGLE_MONTHLY_AVERAGES', dto.values, function(value) {hpdData = value;});
        hpdData = this.collectionUtils.getData('HPD_WRAPPER_SINGLE_MONTHLY_AVERAGES',dto.values);
        cmp.set('v.averageSingleAccountMonthlyHpds', hpdData);
        this.renderRadar(cmp, type, numberAccs, data);
    },
    processAggregateMonthlyAverages: function(cmp, response){
        let dto =  response;
        let hpdData = [];
        //--- deprecated this.collectionUtils.getMapValue('HPD_WRAPPER_MONTHLY_AVERAGES', dto.values, function(value) {hpdData = value;});
        hpdData = this.collectionUtils.getData('HPD_WRAPPER_MONTHLY_AVERAGES',dto.values);
        cmp.set('v.averageAllMonthlyHpds', hpdData);
        this.renderRadar(cmp, 'Lifetime', 'All', null);
    },
    refreshAggregateMonthlyAverages: function(cmp){
      this.renderRadar(cmp, 'Lifetime', 'All', null);
    },
    refreshAggregateAllMonthlyAverages: function(cmp){
      this.renderRadar(cmp, 'Monthly', 'All', null);
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293968845
     */
    processAggregateCustomHpd: function(cmp, response){
        let dto =  response;
        let hpdData = [];
        // deprecated this.collectionUtils.getMapValue('HPD_WRAPPER_CUSTOM_DATA', dto.values, function(value) {hpdData = value;});
        hpdData = this.collectionUtils.getData('HPD_WRAPPER_CUSTOM_DATA',dto.values);
        this.log(cmp,'processAggregateCustomHpd hpdData=','debug',JSON.stringify(hpdData));
        cmp.set('v.aggregateCustomHpds', hpdData);
        cmp.set('v.dataTable', hpdData);
        this.sortData(cmp, 'netRevenue','desc');
        this.renderPieChart(cmp, 'Custom');
        this.disableRadar(cmp);
    },
    processAggregateMonthlyHpd: function(cmp, response){
        let dto =  response;
        let hpdData = [];
        //--- DEPRECATED this.collectionUtils.getMapValue('HPD_WRAPPER_MONTHLY_DATA', dto.values, function(value) {hpdData = value;});
        hpdData = this.collectionUtils.getData('HPD_WRAPPER_MONTHLY_DATA',dto.values);
        cmp.set('v.aggregateMonthlyHpds', hpdData);
        cmp.set('v.dataTable', hpdData);
        this.sortData(cmp, 'netRevenue','desc');
        this.renderPieChart(cmp, 'Monthly');
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/311009951
     */
    processMonthlyHpdDates: function (cmp, response) {
        let dto = response;
        let hpdDates = [];
        let hpdFormattedDates = [];
        //--DEPRECATED this.collectionUtils.getMapValue('HPD_WRAPPER_MONTHS', dto.values, function (value) {hpdDates = value;});
        hpdDates = this.collectionUtils.getData('HPD_WRAPPER_MONTHS',dto.values);
        //-------
        for (let i = 0; i < hpdDates.length; i++) {
            hpdFormattedDates.push({
                value: hpdDates[i].hpdDate,
                label: $A.localizationService.formatDate(hpdDates[i].hpdDate, "MMM YYYY")
            });
        }
        cmp.set('v.dateSelectOptions', hpdFormattedDates);
    },
    /**
     *  https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     *
     *  The nature of this component appears to be to pull all possible data from the server upon load of page. Then,
     *  filter most of it client side when selecting a filter option such as custom range, or a specific month.
     *  As opposed to rewriting it all only pull data it needs from the server.. This will fire renderPieChat
     *  (which chains other calls historically.
     */
    processAggregateLifetimeHpd: function (cmp, response) {
        let dto = response;
        let hpdWrappers = [];
        //--DEPRECATED this.collectionUtils.getMapValue('HPD_WRAPPER_LIST', dto.values, function (value) {hpdWrappers = value;});
        hpdWrappers =  this.collectionUtils.getData('HPD_WRAPPER_LIST',dto.values);

        cmp.set('v.aggregateLifetimeHpds', hpdWrappers);
        cmp.set('v.dataTable', hpdWrappers);
        console.log('wrappers');
        console.log(hpdWrappers);
        this.sortData(cmp, 'netRevenue', 'desc');
        // 293964783
        let locShareDateClicked = cmp.get('v.locShareDateClicked');
        if (!locShareDateClicked || locShareDateClicked === '') {
            this.renderPieChart(cmp, 'All');
        }
        //----------
    },
    refreshPieLifetime: function(cmp){
        //data already exists and is sitting in v.aggregateLifetimeHpds, no need to go reget so just re render chart
        let data= cmp.get('v.aggregateLifetimeHpds');
        cmp.set('v.dataTable', data);
        this.sortData(cmp, 'netRevenue','desc');
        this.renderPieChart(cmp, 'All');
    },
    processUserAccounts: function (cmp, response) {
        let dto = response;
        let accounts =  this.collectionUtils.getData('ACCOUNT_LIST',dto.values);
        //--- deprecated this.collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
        //accounts.unshift("All Locations");
        cmp.set('v.userAccounts', accounts);
        this.setUserAccountOptions(cmp); //---- translate user account array to options array for combo box (location filter)
    },
    renderPieChart: function(cmp, type){
        let self = this;
        this.log(cmp,'renderPieChart');

        let data = self.buildPieData(cmp, type);
        let option = {
            title: {
                show: true,
                text: 'Total % of Net Revenue',
                top: 12,
                left: 'center',
                textStyle: {
                    fontSize: 16
                }
            },
            legend: {
                type: 'scroll',
                orient: 'horizontal',
                left: 5,
                bottom: 5,
                data: data.legendData
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
                right: 5,
                top: 10
            },
            tooltip: {
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.name+'</b><br/>';
                    text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    text=text+'Location Share: $'+self.formatNumberWithCommas(param.data.locShare.toFixed(2))+'<br/>';
                    text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    return text;
                }
            },
            series: [{
                type: 'pie',
                label: {
                    formatter: function (params) {
                        if (params.name.length > 15) {
                            return params.name.substring(0, 12) + "...";
                        } else {
                            return params.name;
                        }
                    },

                },
                labelLine: {
                    length: 6,
                    length2: 6
                },
                radius: '55%',
                center: ['50%', '50%'],
                data: data.seriesData,
            },{
                type: 'pie',
                label: {
                    position: 'inside',
                    fontSize: 11,
                    color: '#000000',
                    formatter: function (params) {
                        if(params.percent < 3){
                            return '';
                        }else if(params.percent < 6) {
                            return params.percent.toFixed(0)+'%';
                        }else {
                            return params.percent.toFixed(1) + '%';
                        }
                    },

                },
                radius: '55%',
                center: ['50%', '50%'],
                data: data.seriesData,
            }],


        };
        if(cmp.get('v.displayPctOfNetRevChart')) {
            var pieDiv = cmp.find("accel-piechart").getElement();
            this.pieChart = echarts.init(pieDiv, 'light');
            if (window.matchMedia("(max-width: 896px)").matches) {
                //mobile
                this.pieChart.setOption(option);
            } else {
                this.pieChart.setOption(option);
            }
        }
        if(this.pieChart) {
            this.pieChart.on('restore', function (params) {
                let type = cmp.get('v.pieType');
                cmp.set('v.locationSelected', 'All Locations');
                let hpdArray;
                if (type === 'All') {
                    hpdArray = cmp.get('v.aggregateLifetimeHpds');
                    self.refreshAggregateMonthlyAverages(cmp);
                } else if (type === 'Monthly') {
                    hpdArray = cmp.get('v.aggregateMonthlyHpds');
                    self.refreshAggregateAllMonthlyAverages(cmp);
                } else if (type === 'Custom') {
                    hpdArray = cmp.get('v.aggregateCustomHpds');
                    //still to build
                }
                let sRevenue = 0;
                let sLocShare = 0;
                let sFundsIn = 0;
                let sFundsOut = 0;
                let sAmtPlayed = 0;
                let sAmtWon = 0;
                for (let i = 0; i < hpdArray.length; i++) {
                    let currRecord = hpdArray[i];
                    sRevenue += currRecord.netRevenue;
                    sLocShare += currRecord.locShare;
                    sFundsIn += currRecord.fundsIn;
                    sFundsOut += currRecord.fundsOut;
                    sAmtPlayed += currRecord.amtPlayed;
                    sAmtWon += currRecord.amtWon;
                }
                cmp.set('v.locationSelectedRevenue', '$' + self.formatNumberWithCommas(sRevenue.toFixed(2)));
                cmp.set('v.locationSelectedLocShare', '$' + self.formatNumberWithCommas(sLocShare.toFixed(2)));
                cmp.set('v.locationSelectedFundsIn', '$' + self.formatNumberWithCommas(sFundsIn.toFixed(0)));
                cmp.set('v.locationSelectedFundsOut', '$' + self.formatNumberWithCommas(sFundsOut.toFixed(2)));
                cmp.set('v.locationSelectedAmtPlayed', '$' + self.formatNumberWithCommas(sAmtPlayed.toFixed(2)));
                cmp.set('v.locationSelectedAmtWon', '$' + self.formatNumberWithCommas(sAmtWon.toFixed(2)));
                cmp.set('v.walkAway', (((sFundsOut / sFundsIn).toFixed(4)) * 100).toFixed(2) + '%');
                cmp.set('v.payoutPercent', (((sAmtWon / sAmtPlayed).toFixed(4)) * 100).toFixed(2) + '%');
            });
            this.pieChart.on('click', function (params) {
                let data = params.data;
                let type = cmp.get('v.pieType');
                if (type === 'All') {
                    self.retrieveSingleAccountAggregateMonthlyAverages(cmp, data.accId, 'Lifetime', 'Single', data);
                    //https://accel-entertainment.monday.com/boards/286658657/pulses/293968275
                    cmp.set('v.locationIdSelected', data.accId);
                } else if (type === 'Monthly') {
                    self.retrieveSingleAccountAggregateMonthlyAverages(cmp, data.accId, 'Monthly', 'Single', data);
                    //https://accel-entertainment.monday.com/boards/286658657/pulses/293968275
                    cmp.set('v.locationIdSelected', data.accId);
                    cmp.set('v.displayMachinePerformanceLink', true);
                    //===============
                } else if (type === 'Custom') {
                    //still to build
                }
                //
                let communityUserSettings = cmp.get('v.communityUserSettings');
                let accountDisplayVal = data.dbaName;
                if (communityUserSettings && communityUserSettings.Display_Location_Address__c) {
                    accountDisplayVal = data.dbaName + ' - ' + data.name;
                }
                cmp.set('v.locationSelected', accountDisplayVal);
                //cmp.set('v.locationSelected', data.dbaName +' - '+data.name);

                cmp.set('v.locationSelectedRevenue', '$' + self.formatNumberWithCommas(data.value.toFixed(2)));
                cmp.set('v.locationSelectedLocShare', '$' + self.formatNumberWithCommas(data.locShare.toFixed(2)));
                cmp.set('v.locationSelectedFundsIn', '$' + self.formatNumberWithCommas(data.fundsIn.toFixed(0)));
                cmp.set('v.locationSelectedFundsOut', '$' + self.formatNumberWithCommas(data.fundsOut.toFixed(2)));
                cmp.set('v.locationSelectedAmtPlayed', '$' + self.formatNumberWithCommas(data.amtPlayed.toFixed(2)));
                cmp.set('v.locationSelectedAmtWon', '$' + self.formatNumberWithCommas(data.amtWon.toFixed(2)));
                cmp.set('v.walkAway', (((data.fundsOut / data.fundsIn).toFixed(4)) * 100).toFixed(2) + '%');
                cmp.set('v.payoutPercent', (((data.amtWon / data.amtPlayed).toFixed(4)) * 100).toFixed(2) + '%');
            });
        }
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293968845
     *
     * Modify the title of the chart to indicate it's disabled. Empty out the series data. Hide the legend and
     * the tooltips. Technically, the way this module was designed there should always be an instance of this chart
     * in memory so simply modify the options on the fly. This only changes the chart options it needs to.
     *
     * @param cmp
     */
    disableRadar: function( cmp ) {
        let _self = this;
        if(_self.radarChart) {
            let title = _self.disabledRadarChartTitle; //  Custom Label
            let options = {
                title: {
                    text: title,
                    textStyle: {
                        color:'white',
                        fontSize: 11,
                    }
                },
                backgroundColor : '#545351',
                tooltip: {show: false},
                legend: {show: false},
                series: [{type:'radar',data: []},{type:'radar',data: []}], //  Probably a better way to do this?
            };
            try {
                _self.radarChart.setOption(options);
            } catch (e) {
                this.log(cmp,'Error attempting to disable radar chart','error',e);
            }
        } else {
            this.log(cmp,'No instance of radarChart to disable!','warn');
        }
    },
    renderRadar: function(cmp, type, numAccs, pData){
        //disable radar for the time being
        if(true){
            return;
        }
        let self = this;
        let d = [];
        let s = [];
        let maxSizes = [];
        let minSizes = [];
        let zAvg =0;
        let zSel =0;

        let data = self.buildRadarData(cmp, type, numAccs, pData);
        d.push(data.seriesData);
        maxSizes.push(data.indicatorMaxSizes);
        let options;
        let bgColor = '#161627';
        this.log(cmp,'selectedDate'+cmp.get('v.selectedDate'));


        if(type === 'Monthly'){
            let title= 'Averaging: '+cmp.get('v.locationSelected');
            this.log(cmp,'renderRadar: Selected Date','debug',cmp.get('v.selectedDate'));
            //console.log(cmp.get('v.selectedDate'));
            let dDate = new Date(cmp.get('v.selectedDate'));
            dDate.setDate(dDate.getDate()+1);
            let legendName = $A.localizationService.formatDate(dDate, "MMM YYYY");
            s.push(data.singleAccountData);
            minSizes.push(data.indicatorMinSizes);
            zAvg=data.zAvg;
            zSel=data.zSel;


            options = {
                title: {
                    text: title,
                    textStyle:{
                        color: '#FFF',
                        fontSize: 14
                    },
                    show: true,
                    top: 5,
                    left: 5,
                },
                backgroundColor: bgColor,
                tooltip: {
                    formatter: function(param){
                        var text = '';
                        text='<b>'+param.seriesName+'</b><br/>';
                        text=text+'Net Revenue: '+ '$'+self.formatNumberWithCommas(param.data[0].toFixed(2))+'<br/>';
                        text=text+'Funds In: '+'$'+self.formatNumberWithCommas(param.data[1].toFixed(0))+'<br/>';
                        text=text+'Amount Played: '+'$'+self.formatNumberWithCommas(param.data[2].toFixed(2))+'<br/>';
                        text=text+'Location Share: '+'$'+self.formatNumberWithCommas(param.data[3].toFixed(2))+'<br/>';
                        text=text+'Amount Won: '+'$'+self.formatNumberWithCommas(param.data[4].toFixed(2))+'<br/>';
                        text=text+'Funds Out: '+'$'+self.formatNumberWithCommas(param.data[5].toFixed(2))+'<br/>';
                        return text;
                    }
                },
                legend: {
                    show: true,
                    data: [{
                        name: legendName
                    },{
                        name: 'Lifetime Monthly Averages'
                    }],
                    textStyle: {
                        color: '#fff',
                        fontSize: 14
                    },
                    bottom: 5
                },
                radar: {
                    indicator: [
                        {name: 'Net Revenue', max: maxSizes[0][0], min: minSizes[0][0]},
                        {name: 'Funds In', max: maxSizes[0][1], min: minSizes[0][1]},
                        {name: 'Amount Played', max: maxSizes[0][2], min: minSizes[0][2]},
                        {name: 'Location Share', max: maxSizes[0][3], min: minSizes[0][3]},
                        {name: 'Amount Won', max: maxSizes[0][4], min: minSizes[0][4]},
                        {name: 'Funds Out', max: maxSizes[0][5], min: minSizes[0][5]},
                    ],
                    shape: 'circle',
                    radius: '55%',
                    center: ['50%', '50%'],
                    splitNumber: 5,
                    name: {
                        textStyle: {
                            color: 'rgb(238, 197, 102)'
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            color: [
                                'rgba(238, 197, 102, 0.1)', 'rgba(238, 197, 102, 0.2)',
                                'rgba(238, 197, 102, 0.4)', 'rgba(238, 197, 102, 0.6)',
                                'rgba(238, 197, 102, 0.8)', 'rgba(238, 197, 102, 1)'
                            ].reverse()
                        }
                    },
                    splitArea: {
                        show: false
                    },
                    axisLine: {
                        lineStyle: {
                            color: 'rgba(238, 197, 102, 0.5)'
                        }
                    }
                },
                series: [{
                    name: legendName,
                    type: 'radar',
                    data: s,
                    symbol: 'none',
                    z: zSel,
                    areaStyle: {
                        normal: {
                            opacity: 0.4
                        }
                    },
                    itemStyle: {
                        normal: {
                            color: '#B3E4A1'
                        }
                    },
                },{
                    name: 'Lifetime Monthly Averages',
                    type: 'radar',
                    data: d,
                    symbol: 'none',
                    z: zAvg,
                    areaStyle: {
                        normal: {
                            opacity: 0.4
                        }
                    },
                    itemStyle: {
                        normal: {
                            color: '#F9713C'
                        }
                    },
                }]
            };
        }
        else if(type === 'Lifetime') {
            let title= 'Averaging: '+cmp.get('v.locationSelected');
            options = {
                title: {
                    text: title,
                    textStyle:{
                        color: '#FFF',
                        fontSize: 13
                    },
                    show: true,
                    top: 5,
                    left: 5
                },
                backgroundColor: bgColor,
                legend: {
                    show: true,
                    data: [{
                        name: 'Lifetime Monthly Averages'
                    }],
                    textStyle: {
                        color: '#fff',
                        fontSize: 14
                    },
                    bottom: 5

                },
                tooltip: {
                    formatter: function(param){
                        var text = '';
                        text='<b>'+param.seriesName+'</b><br/>';
                        text=text+'Net Revenue: '+ '$'+self.formatNumberWithCommas(param.data[0].toFixed(2))+'<br/>';
                        text=text+'Funds In: '+'$'+self.formatNumberWithCommas(param.data[1].toFixed(0))+'<br/>';
                        text=text+'Amount Played: '+'$'+self.formatNumberWithCommas(param.data[2].toFixed(2))+'<br/>';
                        text=text+'Location Share: '+'$'+self.formatNumberWithCommas(param.data[3].toFixed(2))+'<br/>';
                        text=text+'Amount Won: '+'$'+self.formatNumberWithCommas(param.data[4].toFixed(2))+'<br/>';
                        text=text+'Funds Out: '+'$'+self.formatNumberWithCommas(param.data[5].toFixed(2))+'<br/>';
                        return text;
                    }
                },
                radar: {
                    indicator: [
                        {name: 'Net Revenue', max: maxSizes[0][0]},
                        {name: 'Funds In', max: maxSizes[0][1]},
                        {name: 'Amount Played', max: maxSizes[0][2]},
                        {name: 'Location Share', max: maxSizes[0][3]},
                        {name: 'Amount Won', max: maxSizes[0][4]},
                        {name: 'Funds Out', max: maxSizes[0][5]},
                    ],
                    shape: 'circle',
                    radius: '55%',
                    center: ['50%', '50%'],
                    splitNumber: 5,
                    name: {
                        textStyle: {
                            color: 'rgb(238, 197, 102)'
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            color: [
                                'rgba(238, 197, 102, 0.1)', 'rgba(238, 197, 102, 0.2)',
                                'rgba(238, 197, 102, 0.4)', 'rgba(238, 197, 102, 0.6)',
                                'rgba(238, 197, 102, 0.8)', 'rgba(238, 197, 102, 1)'
                            ].reverse()
                        }
                    },
                    splitArea: {
                        show: false
                    },
                    axisLine: {
                        lineStyle: {
                            color: 'rgba(238, 197, 102, 0.5)'
                        }
                    }
                },
                series: {
                    name: 'Lifetime Monthly Averages',
                    type: 'radar',
                    data: d,
                    symbol: 'none',
                    areaStyle: {
                        normal: {
                            opacity: 0.4
                        }
                    },
                    itemStyle: {
                        normal: {
                            color: '#F9713C'
                        }
                    },
                }
            };
        }
        if(cmp.get('v.displayAverageChart')) {
            let radarDiv = cmp.find("accel-radar").getElement();
            this.radarChart = echarts.init(radarDiv, 'light');
            if (window.matchMedia("(max-width: 896px)").matches) {
                //mobile
                this.radarChart.setOption(options);
            } else {
                this.radarChart.setOption(options);
            }
        }
    },
    buildRadarData: function(cmp, type, numAccs, data){
        let hpdArray;
        let avgArray;
        let paramData;
        let sRevenue = 0;
        let sLocShare = 0;
        let sFundsIn = 0;
        let sFundsOut = 0;
        let sAmtPlayed = 0;
        let sAmtWon = 0;
        let revSize = 0;
        let locShareSize =0;
        let fundsInSize = 0;
        let fundsOutSize =0;
        let amtPlayedSize = 0;
        let amtWonSize = 0;
        let zAvg = 0;
        let zSel = 0;
        let indicatorMaxSizes = [];
        let indicatorMinSizes = [];
        let singleAccountData = [];
        let seriesData = [];
        if(type === 'Lifetime' && numAccs === 'All'){
            hpdArray = cmp.get('v.averageAllMonthlyHpds');
            for(let i=0; i<hpdArray.length; i++){
                let currRecord = hpdArray[i];
                let numMonths = currRecord.distinctDateCount;
                sRevenue += currRecord.netRevenue/numMonths;
                sLocShare += currRecord.locShare/numMonths;
                sFundsIn += currRecord.fundsIn/numMonths;
                sFundsOut += currRecord.fundsOut/numMonths;
                sAmtPlayed += currRecord.amtPlayed/numMonths;
                sAmtWon += currRecord.amtWon/numMonths;
            }
            seriesData.push(sRevenue);
            seriesData.push(sFundsIn);
            seriesData.push(sAmtPlayed);
            seriesData.push(sLocShare);
            seriesData.push(sAmtWon);
            seriesData.push(sFundsOut);

            revSize=sRevenue*1.3;
            fundsInSize=sFundsIn*1.3;
            amtPlayedSize=sAmtPlayed*1.3;
            locShareSize=sLocShare*1.3;
            amtWonSize=sAmtWon*1.3;
            fundsOutSize=sFundsOut*1.3;

            indicatorMaxSizes.push(revSize);
            indicatorMaxSizes.push(fundsInSize);
            indicatorMaxSizes.push(amtPlayedSize);
            indicatorMaxSizes.push(locShareSize);
            indicatorMaxSizes.push(amtWonSize);
            indicatorMaxSizes.push(fundsOutSize);

            return {
                indicatorMaxSizes: indicatorMaxSizes,
                seriesData: seriesData
            }
        }
        else if(type === 'Lifetime' && numAccs ==='Single') {
            paramData = data;
            hpdArray = cmp.get('v.averageSingleAccountMonthlyHpds');
            for(let i=0; i<hpdArray.length; i++){
                let currRecord = hpdArray[i];
                let numMonths = currRecord.distinctDateCount;
                sRevenue += currRecord.netRevenue/numMonths;
                sLocShare += currRecord.locShare/numMonths;
                sFundsIn += currRecord.fundsIn/numMonths;
                sFundsOut += currRecord.fundsOut/numMonths;
                sAmtPlayed += currRecord.amtPlayed/numMonths;
                sAmtWon += currRecord.amtWon/numMonths;
            }
            seriesData.push(sRevenue);
            seriesData.push(sFundsIn);
            seriesData.push(sAmtPlayed);
            seriesData.push(sLocShare);
            seriesData.push(sAmtWon);
            seriesData.push(sFundsOut);

            revSize=sRevenue*1.3;
            fundsInSize=sFundsIn*1.3;
            amtPlayedSize=sAmtPlayed*1.3;
            locShareSize=sLocShare*1.3;
            amtWonSize=sAmtWon*1.3;
            fundsOutSize=sFundsOut*1.3;

            indicatorMaxSizes.push(revSize);
            indicatorMaxSizes.push(fundsInSize);
            indicatorMaxSizes.push(amtPlayedSize);
            indicatorMaxSizes.push(locShareSize);
            indicatorMaxSizes.push(amtWonSize);
            indicatorMaxSizes.push(fundsOutSize);


            return {
                indicatorMaxSizes: indicatorMaxSizes,
                seriesData: seriesData,
                singleAccountData: singleAccountData
            }

        }
        else if(type ==='Monthly' && numAccs ==='All'){
            hpdArray = cmp.get('v.aggregateMonthlyHpds');
            avgArray = cmp.get('v.averageAllMonthlyHpds');
            for(let i=0; i<hpdArray.length; i++){
                let currRecord = hpdArray[i];
                sRevenue += currRecord.netRevenue;
                sLocShare += currRecord.locShare;
                sFundsIn += currRecord.fundsIn;
                sFundsOut += currRecord.fundsOut;
                sAmtPlayed += currRecord.amtPlayed;
                sAmtWon += currRecord.amtWon;
            }
            singleAccountData.push(sRevenue);
            singleAccountData.push(sFundsIn);
            singleAccountData.push(sAmtPlayed);
            singleAccountData.push(sLocShare);
            singleAccountData.push(sAmtWon);
            singleAccountData.push(sFundsOut);

            let ssRevenue=0;
            let ssLocShare=0;
            let ssFundsIn=0;
            let ssFundsOut=0;
            let ssAmtPlayed=0;
            let ssAmtWon=0;

            for(let i=0; i<avgArray.length; i++){
                let currRecord = avgArray[i];
                let numMonths = currRecord.distinctDateCount;
                ssRevenue += currRecord.netRevenue/numMonths;
                ssLocShare += currRecord.locShare/numMonths;
                ssFundsIn += currRecord.fundsIn/numMonths;
                ssFundsOut += currRecord.fundsOut/numMonths;
                ssAmtPlayed += currRecord.amtPlayed/numMonths;
                ssAmtWon += currRecord.amtWon/numMonths;
            }
            seriesData.push(ssRevenue);
            seriesData.push(ssFundsIn);
            seriesData.push(ssAmtPlayed);
            seriesData.push(ssLocShare);
            seriesData.push(ssAmtWon);
            seriesData.push(ssFundsOut);

            let revMax= sRevenue > ssRevenue ? 1.05*sRevenue: 1.05*ssRevenue;
            indicatorMaxSizes.push(revMax);
            let fundsInMax= sFundsIn > ssFundsIn ? 1.05*sFundsIn: 1.05*ssFundsIn;
            indicatorMaxSizes.push(fundsInMax);
            let amtPlayedMax= sAmtPlayed > ssAmtPlayed ? 1.05*sAmtPlayed: 1.05*ssAmtPlayed;
            indicatorMaxSizes.push(amtPlayedMax);
            let locShareMax= sLocShare > ssLocShare ? 1.05*sLocShare: 1.05*ssLocShare;
            indicatorMaxSizes.push(locShareMax);
            let amtWonMax= sAmtWon > ssAmtWon ? 1.05*sAmtWon: 1.05*ssAmtWon;
            indicatorMaxSizes.push(amtWonMax);
            let fundsOutMax= sFundsOut > ssFundsOut ? 1.05*sFundsOut: 1.05*ssFundsOut;
            indicatorMaxSizes.push(fundsOutMax);

            let revMin= sRevenue > ssRevenue ? .75*ssRevenue: .75*sRevenue;
            indicatorMinSizes.push(revMin);
            let fundsInMin= sFundsIn > ssFundsIn ? .75*ssFundsIn: .75*sFundsIn;
            indicatorMinSizes.push(fundsInMin);
            let amtPlayedMin= sAmtPlayed > ssAmtPlayed ? .75*ssAmtPlayed: .75*sAmtPlayed;
            indicatorMinSizes.push(amtPlayedMin);
            let locShareMin= sLocShare > ssLocShare ? .75*ssLocShare: .75*sLocShare;
            indicatorMinSizes.push(locShareMin);
            let amtWonMin= sAmtWon > ssAmtWon ? .75*ssAmtWon: .75*sAmtWon;
            indicatorMinSizes.push(amtWonMin);
            let fundsOutMin= sFundsOut > ssFundsOut ? .75*ssFundsOut: .75*sFundsOut;
            indicatorMinSizes.push(fundsOutMin);

            if(sRevenue > ssRevenue){
                zAvg=3;
                zSel=2;
            }else{
                zAvg=2;
                zSel=3;
            }
            return {
                zAvg: zAvg,
                zSel: zSel,
                indicatorMaxSizes: indicatorMaxSizes,
                indicatorMinSizes: indicatorMinSizes,
                seriesData: seriesData,
                singleAccountData: singleAccountData
            }

        }
        else if(type ==='Monthly' && numAccs ==='Single'){
            paramData = data;
            hpdArray = cmp.get('v.averageSingleAccountMonthlyHpds');
            for(let i=0; i<hpdArray.length; i++){
                let currRecord = hpdArray[i];
                let numMonths = currRecord.distinctDateCount;
                sRevenue += currRecord.netRevenue/numMonths;
                sLocShare += currRecord.locShare/numMonths;
                sFundsIn += currRecord.fundsIn/numMonths;
                sFundsOut += currRecord.fundsOut/numMonths;
                sAmtPlayed += currRecord.amtPlayed/numMonths;
                sAmtWon += currRecord.amtWon/numMonths;
            }
            seriesData.push(sRevenue);
            seriesData.push(sFundsIn);
            seriesData.push(sAmtPlayed);
            seriesData.push(sLocShare);
            seriesData.push(sAmtWon);
            seriesData.push(sFundsOut);

            singleAccountData.push(paramData.value);
            singleAccountData.push(paramData.fundsIn);
            singleAccountData.push(paramData.amtPlayed);
            singleAccountData.push(paramData.locShare);
            singleAccountData.push(paramData.amtWon);
            singleAccountData.push(paramData.fundsOut);

            let revMax= sRevenue > paramData.value ? 1.05*sRevenue: 1.05*paramData.value;
            indicatorMaxSizes.push(revMax);
            let fundsInMax= sFundsIn > paramData.fundsIn ? 1.05*sFundsIn: 1.05*paramData.fundsIn;
            indicatorMaxSizes.push(fundsInMax);
            let amtPlayedMax= sAmtPlayed > paramData.amtPlayed ? 1.05*sAmtPlayed: 1.05*paramData.amtPlayed;
            indicatorMaxSizes.push(amtPlayedMax);
            let locShareMax= sLocShare > paramData.locShare ? 1.05*sLocShare: 1.05*paramData.locShare;
            indicatorMaxSizes.push(locShareMax);
            let amtWonMax= sAmtWon > paramData.amtWon ? 1.05*sAmtWon: 1.05*paramData.amtWon;
            indicatorMaxSizes.push(amtWonMax);
            let fundsOutMax= sFundsOut > paramData.fundsOut ? 1.05*sFundsOut: 1.05*paramData.fundsOut;
            indicatorMaxSizes.push(fundsOutMax);

            let revMin= sRevenue > paramData.value ? .75*paramData.value: .75*sRevenue;
            indicatorMinSizes.push(revMin);
            let fundsInMin= sFundsIn > paramData.fundsIn ? .75*paramData.fundsIn: .75*sFundsIn;
            indicatorMinSizes.push(fundsInMin);
            let amtPlayedMin= sAmtPlayed > paramData.amtPlayed ? .75*paramData.amtPlayed: .75*sAmtPlayed;
            indicatorMinSizes.push(amtPlayedMin);
            let locShareMin= sLocShare > paramData.locShare ? .75*paramData.locShare: .75*sLocShare;
            indicatorMinSizes.push(locShareMin);
            let amtWonMin= sAmtWon > paramData.amtWon ? .75*paramData.amtWon: .75*sAmtWon;
            indicatorMinSizes.push(amtWonMin);
            let fundsOutMin= sFundsOut > paramData.fundsOut ? .75*paramData.fundsOut: .75*sFundsOut;
            indicatorMinSizes.push(fundsOutMin);

            if(sRevenue > paramData.value){
                zAvg=2;
                zSel=3;
            }else if(!(sRevenue > paramData.value && sFundsIn > paramData.fundsIn && sAmtPlayed > paramData.amtPlayed && sLocShare > paramData.locShare && sAmtWon > paramData.amtWon && sFundsOut > paramData.fundsOut)){
                //no way for user to get tooltip on lifetime average series, generally shouldnt happen
                zAvg=3;
                zSel=2;
            }else{
                zAvg=3;
                zSel=2;
            }

            return {
                zAvg: zAvg,
                zSel: zSel,
                indicatorMaxSizes: indicatorMaxSizes,
                indicatorMinSizes: indicatorMinSizes,
                seriesData: seriesData,
                singleAccountData: singleAccountData
            }

        }
        else if(type === 'Custom'&& numAccs ==='All'){
            hpdArray = cmp.get('v.aggregateCustomHpds');
        }
        else if(type === 'Custom'&& numAccs ==='Single'){

        }
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/311009951
     * If the community user setting is checked. Use the address to display, if not use the DBA Name.
     *
     * @param cmp
     * @param type Indicates the type of filter selected for the pie chart [All,Monthly,Custom]
     * @returns {{seriesData: *, legendData: *}}
     */
    buildPieData: function(cmp, type){
        let hpdArray;
        if(type === 'All'){
            hpdArray = cmp.get('v.aggregateLifetimeHpds');
        }else if(type === 'Monthly'){
            hpdArray = cmp.get('v.aggregateMonthlyHpds');
        }else if(type === 'Custom'){
            hpdArray = cmp.get('v.aggregateCustomHpds');
        }
        let sRevenue = 0;
        let sLocShare = 0;
        let sFundsIn = 0;
        let sFundsOut = 0;
        let sAmtPlayed = 0;
        let sAmtWon = 0;
        let legendData = [];
        let seriesData = [];
        if(hpdArray){
            //sort pie largest to smallest
            hpdArray.sort(function(a,b) { return b.locShare - a.locShare;});
        }
        let communityUserSettings = cmp.get('v.communityUserSettings');

        for(let i=0; i<hpdArray.length; i++){
            let currRecord = hpdArray[i];
            let accountDisplayVal = currRecord.accountName;
            if (communityUserSettings && communityUserSettings.Display_Location_Address__c) {
                accountDisplayVal = currRecord.accountPhysicalStreet;
            }
            //legendData.push(currRecord.accountPhysicalStreet);
            legendData.push(accountDisplayVal);
            seriesData.push({
                accId: currRecord.accountId,
                name: accountDisplayVal,
                dbaName: currRecord.accountName,
                value: currRecord.netRevenue,
                fundsIn: currRecord.fundsIn,
                fundsOut: currRecord.fundsOut,
                amtPlayed: currRecord.amtPlayed,
                amtWon: currRecord.amtWon,
                locShare: currRecord.locShare
                //id: currRecord.accountId
            });
            sRevenue += currRecord.netRevenue;
            sLocShare += currRecord.locShare;
            sFundsIn += currRecord.fundsIn;
            sFundsOut += currRecord.fundsOut;
            sAmtPlayed += currRecord.amtPlayed;
            sAmtWon += currRecord.amtWon;
        }
        cmp.set('v.locationSelectedRevenue', '$'+this.formatNumberWithCommas(sRevenue.toFixed(2)));
        cmp.set('v.locationSelectedLocShare', '$'+this.formatNumberWithCommas(sLocShare.toFixed(2)));
        cmp.set('v.locationSelectedFundsIn', '$'+this.formatNumberWithCommas(sFundsIn.toFixed(0)));
        cmp.set('v.locationSelectedFundsOut', '$'+this.formatNumberWithCommas(sFundsOut.toFixed(2)));
        cmp.set('v.locationSelectedAmtPlayed', '$'+this.formatNumberWithCommas(sAmtPlayed.toFixed(2)));
        cmp.set('v.locationSelectedAmtWon', '$'+this.formatNumberWithCommas(sAmtWon.toFixed(2)));
        cmp.set('v.walkAway', (((sFundsOut/sFundsIn).toFixed(4))*100).toFixed(2)+'%');
        cmp.set('v.payoutPercent', (((sAmtWon/sAmtPlayed).toFixed(4))*100).toFixed(2)+'%');

        return {
            legendData: legendData,
            seriesData: seriesData
        }
    },

    initColumns: function (cmp) {
        cmp.set('v.columns', [
            {   label: 'Date',
                fieldName: 'dateValue',
                type: 'text',
                sortable: false,
            },
            {   label: 'Location',
                fieldName: 'accountName',
                type: 'text',
                sortable: true,
                cellAttributes: {class: 'slds-no-row-hover'}
            },
            {   label: 'Address',
                fieldName: 'accountPhysicalStreet',
                type: 'text',
                sortable: true
            },
            {   label: 'City',
                fieldName: 'accountPhysicalCity',
                type: 'text',
                sortable: true
            },
            //  RJN 8-12-2019 SFCOMM-291515455
            {   label: 'VGT Live Date',
                fieldName: 'accountAccelVgtLiveDate',
                type: 'date',
                sortable: true,
            },
            {
                label: 'Revenue',
                fieldName: 'netRevenue',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Location Share',
                fieldName: 'locShare',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Funds In',
                fieldName: 'fundsIn',
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
                label: 'Amount Played',
                fieldName: 'amtPlayed',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Amount Won',
                fieldName: 'amtWon',
                type: 'currency',
                sortable: true,
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
                if(account!=='All Locations') {
                    concatName = account.Name + ' - ' + account.ShippingStreet + ' - ' + account.ShippingCity;
                    let accountOption = {'label': concatName, 'value': account.Id};
                    accountOptions.push(accountOption);
               // }else{
                //    concatName = account;
               //     let accountOption = {'label': concatName, 'value': 'All Locations'};
               //     accountOptions.push(accountOption);
                }
            }
        }
        cmp.set('v.userAccountOptions',accountOptions);
    },
    setYesterday: function(cmp) {
        let d = new Date();             //  d = End Date
        let s = new Date();             //  s = Start Date
        d.setDate(d.getDate() - 1);
        s.setDate(d.getDate() - 29); //default start date for Last 30 Days option
        cmp.set('v.yesterday', $A.localizationService.formatDate(d, 'YYYY-MM-dd'));
        cmp.set('v.startDate', $A.localizationService.formatDate(s, 'YYYY-MM-dd'));
        cmp.set('v.endDate', $A.localizationService.formatDate(d, 'YYYY-MM-dd'));
    },
    formatNumberWithCommas: function(x){
        var parts = x.toString().split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    },
    /**
     * If the level is error and the message includes generic, this will fire a toast with user friendly
     * message stored in a custom label.
     *
     * @param cmp
     * @param msg
     * @param level
     * @param jsonObj
     *
     * @TODO this should prob be an lwc class that also excepts event to wrap all this stuff.
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
                var cmpName = '---- ACV2_LocationPerformance cmp ---';
                var cLogger = this.loggingUtils;
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
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    windowResizing: function (cmp, evt, helper) {
        var self = this;
        if(self.pieChart){
            self.pieChart.resize();
        }
        if(self.radarChart){
            self.radarChart.resize();
        }

    },
    prepCsvExport: function(cmp) {
        if(cmp.get('v.dataTable')) {
            let arr = cmp.get('v.dataTable');
            //let fields = {};
            let fields = ['dateValue','accountName', 'accountPhysicalStreet', 'accountPhysicalCity', 'netRevenue', 'locShare', 'fundsIn', 'fundsOut', 'amtPlayed', 'amtWon'];
            let fileName  = 'Location Performance.csv';
            let dto;
            this.csvExporter.doExport(arr,fields,fileName, function(value) {dto = value;});
            this.displayUiMsg(cmp,dto.severity,dto.message);
        }
    },
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.dataTable");
        var reverse = sortDirection !== 'asc';
        //sorts the rows based on the column header that's clicked
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.dataTable", data);
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
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     * @param paramName
     * @returns a string pararm value if found.
     *
     * @TODO This needs to be moved to a utils component.
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
     * https://accel-entertainment.monday.com/boards/286658657/pulses/293964783
     * Merely strip urls params and store them in attributes.
     *
     * @param cmp
     */
    processUrlParams: function(cmp) {
        cmp.set('v.locShareDateClicked', this.getUrlParam('locShareDateClicked'));
        cmp.set('v.locShareChartStyle', this.getUrlParam('locShareChartStyle'));
        if(cmp.get('v.locShareDateClicked')) {
            this.log(   cmp, 'in processUrlParams: locShareDateClicked='+cmp.get('v.locShareDateClicked')
                +'..locShareChartStyle='+ cmp.get('v.locShareChartStyle'),'debug');
        }
    },
});