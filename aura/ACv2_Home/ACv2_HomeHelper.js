/**
 * Replaced alerts with call to error logging which will pop toast as well.
 * https://accel-entertainment.monday.com/boards/286658657/
 */
({
    collectionUtils:null,
    loggingUtils:null,
    formatUtils: null,
    uiMessagingUtils:null,
    //https://accel-entertainment.monday.com/boards/286658657/
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:10000, //10 seconds
    COMMUNITY_SETTINGS:'CONTACT_CONTROLLED_COMMUNITY_SETTINGS',


    /**
     * We need to call this in init as due to lifecycle issues. the DOM needs be set on aura if before
     * echart inits.
     *
     * @param cmp
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
                    cmp.set('v.renderTrendChart',true);
                    this.log(cmp,'sObject Community_User_Setting__c not found for logged in user!','error');
                } else {
                    cmp.set('v.renderTrendChart',communityUserSettings.Display_Trend_Chart__c);
                    cmp.set('v.communityUserSettingsNotFound',false);
                    //@TODO call method that sets flags to prevent chained queries and stuff that is hidden.
                    this.log(cmp,'communityUserSettings','info',JSON.stringify(communityUserSettings));
                }
                this.retrieveAccounts(cmp);
                this.retrieveHpdData(cmp);//  Moved from after scripts loaded to here
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });

    },
    retrieveAccounts: function(cmp) {
        cmp.lax.enqueue('c.retrieveAccounts') //getUserAccounts
            .then(response => {
                this.processUserAccounts(cmp, response);
            })
            .catch(errors => {
                this.log(cmp,'error in retrieveAccounts','error',JSON.stringify(errors));
            });
    },
    retrieveHpdData: function(cmp){
        cmp.set("v.showDailySpinner", true);
        this.log(cmp,'retrieveHpdData','debug');
        cmp.lax.enqueue('c.retrieveHpdData')
            .then(response => {
                cmp.set('v.HpdData',response);
                this.processHpdData(cmp);
                cmp.set("v.showDailySpinner", false);
            })
            .catch(errors =>{
                cmp.set("v.showDailySpinner", false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    retrieveMonthlyHpdData: function(cmp){
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.retrieveMonthlyHpdData')
            .then(response => {
                this.processMonthlyHpdData(cmp, response);
                cmp.set("v.showDailySpinner", false);
            })
            .catch(errors =>{
                cmp.set("v.showDailySpinner", false);
                this.log(cmp,'error in retrieveMonthlyHpdData','error',JSON.stringify(errors));
            });
    },
    processMonthlyHpdData: function(cmp, response){
        let dto = response;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //  https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('HPD_MONTHLY_WRAPPER_LIST',dto.values);
        //------ deprecated collectionUtils.getMapValue('HPD_MONTHLY_WRAPPER_LIST', dto.values, function (value) {hpdWraps = value;});

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.holdPerDayWrappers', hpdWraps);
            this.renderDailyChart(cmp, 'All', 'Monthly');
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for your criteria. Please modify your search criteria.');
        }
    },
    retrieveDailyAvgData: function(cmp){
        let accountId = cmp.get("v.selectedAccountId");
        let accountType = cmp.get("v.selectedAccountType");
        const params = {id: accountId, accType: accountType};
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.getClosestAccounts',params)
            .then(response=>{
                this.processAvgAccounts(cmp, response);
                cmp.set("v.showDailySpinner", false);
                let accList = cmp.get('v.avgAccountIdList');
                const param = {accIds: accList};
                cmp.set("v.showDailySpinner", true);
                return cmp.lax.enqueue('c.getClosestHpds', param)
                    .then( data=>{
                        this.processDailyAvgData(cmp, data);
                        cmp.set("v.showDailySpinner", false);
                        return this.retrieveSingleAccountDailyData(cmp);
                    })
                    .catch( err=>{
                        cmp.set("v.showDailySpinner", false);
                        this.log(cmp,'generic','error',JSON.stringify(errors));
                    })
            })
            .catch( error => {
                cmp.set("v.showDailySpinner", false);
                //alert('getClosestAccounts error '+error);
            });
    },
    retrieveSingleAccountDailyData: function(cmp){
        let accountId = cmp.get("v.selectedAccountId");
        const params = {id: accountId};
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.getAccountDailyData', params)
            .then(response=>{
                this.processDailyAccountData(cmp, response);
                cmp.set("v.showDailySpinner", false);
            })
            .catch(error=>{
                cmp.set("v.showDailySpinner", false);
                this.log(cmp,'error in retrieveSingleAccountDailyData','error',JSON.stringify(errors));
            });
    },
    retrieveMonthlyAvgData: function(cmp){
        let accountId = cmp.get("v.selectedAccountId");
        let accountType = cmp.get("v.selectedAccountType");
        const params = {id: accountId, accType: accountType};
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.getClosestAccounts',params)
            .then(response=>{
                this.processAvgAccounts(cmp, response);
                cmp.set("v.showDailySpinner", false);
                let accList = cmp.get('v.avgAccountIdList');
                const param = {accIds: accList};
                cmp.set("v.showDailySpinner", true);
                return cmp.lax.enqueue('c.getClosestMonthlyHpds', param)
                    .then( data=>{
                        this.processMonthlyAvgData(cmp, data);
                        cmp.set("v.showDailySpinner", false);
                        return this.retrieveSingleAccountMonthlyData(cmp);
                    })
                    .catch( err=>{
                        cmp.set("v.showDailySpinner", false);
                        this.log(cmp,'generic','error',JSON.stringify(errors));
                    })
            })
            .catch( error => {
                cmp.set("v.showDailySpinner", false);
                //alert('getClosestAccounts error '+error);
            });
    },
    retrieveSingleAccountMonthlyData: function(cmp){
        let accountId = cmp.get("v.selectedAccountId");
        const params = {id: accountId};
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.getAccountMonthlyData', params)
            .then(response=>{
                this.processMonthlyAccountData(cmp, response);
                cmp.set("v.showDailySpinner", false);
            })
            .catch(error=>{
                cmp.set("v.showDailySpinner", false);
                this.log(cmp,'errors in retrieveSingleAccountMontlhyData','error',JSON.stringify(errors));
            });
    },
    retrieveAllYoyHpdData: function(cmp){
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.retrieveAllAccountsYoyData')
            .then(response => {
                //  https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
                //  set response to cmp attribute and consume later!
                let dto = response;
                cmp.set('v.AllAccountsYoyData',dto);
                this.processYoyHpdData(cmp);
                cmp.set("v.showDailySpinner", false);
            })
            .catch(errors =>{
                cmp.set("v.showDailySpinner", false);
                this.log(cmp,'error in retrieveAllAccountsYoyData','error',JSON.stringify(errors));
            });
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
     * Consume server response from cmp attribute as opposed to directly!
     * @param cmp
     */
    processYoyHpdData: function (cmp) {
        let dto = cmp.get('v.AllAccountsYoyData');
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //---- deprecated collectionUtils.getMapValue('ACCOUNT_ALL_YOY_HPD', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('ACCOUNT_ALL_YOY_HPD',dto.values);

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.holdPerDayWrappers', hpdWraps);
            this.renderDailyChart(cmp, 'All', 'YoY');
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for this YoY.');
        }
    },
    retrieveSingleYoyHpdData: function(cmp){
        let accountId = cmp.get("v.selectedAccountId");
        const params = {id: accountId};
        cmp.set("v.showDailySpinner", true);
        cmp.lax.enqueue('c.retrieveSingleAccountYoyData', params)
            .then(response => {
                let dto = response;
                cmp.set('v.SingleAccountYoyData',dto);
                this.processSingleYoyHpdData(cmp);
                cmp.set("v.showDailySpinner", false);
            })
            .catch(errors =>{
                cmp.set("v.showDailySpinner", false);
                this.log(cmp,'error in retrieveSingleYoyHpdData','error',JSON.stringify(errors));
            });
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
     * @param cmp
     */
    processSingleYoyHpdData: function(cmp) {
        let dto = cmp.get('v.SingleAccountYoyData');
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //collectionUtils.getMapValue('ACCOUNT_SINGLE_YOY_HPD', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('ACCOUNT_SINGLE_YOY_HPD',dto.values);

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.holdPerDayWrappers', hpdWraps);
            this.renderDailyChart(cmp, 'Single', 'YoY');
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for this Single YoY.');
        }
    },
    processMonthlyAccountData: function(cmp, response){
        let dto = response;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //collectionUtils.getMapValue('ACCOUNT_MONTHLY_HPD', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('ACCOUNT_MONTHLY_HPD',dto.values);

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.holdPerDayWrappers', hpdWraps);
            cmp.set('v.singleAccountHpdLength', hpdWraps.length);
            this.renderDailyChart(cmp, 'Single', 'Monthly');
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for this account.');
        }
    },
    processMonthlyAvgData: function(cmp, data){
        //load single locations 10 nearby neighbors averages into variables to be loaded into chart
        let dto = data;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //collectionUtils.getMapValue('HPD_WRAPPER_CLOSEST_MONTHLY', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('HPD_WRAPPER_CLOSEST_MONTHLY',dto.values);

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.avgHoldPerDayWrappers', hpdWraps);
        } else {
            this.displayUiMsg(cmp, 'warning', 'Could not find nearby location monthly averages');
        }
    },
    retrieveAllLocationsData: function(cmp){
        //already have the data stored in component variable from pageload
        let allLocationsHpd = cmp.get('v.allLocationsHpd');
        cmp.set('v.holdPerDayWrappers', allLocationsHpd);
        this.renderDailyChart(cmp, 'All', 'Daily');
    },
    processDailyAccountData: function(cmp, response){
        let dto = response;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //collectionUtils.getMapValue('ACCOUNT_DAILY_HPD', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('ACCOUNT_DAILY_HPD',dto.values);

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.holdPerDayWrappers', hpdWraps);
            cmp.set('v.singleAccountHpdLength', hpdWraps.length);
            this.renderDailyChart(cmp, 'Single', 'Daily');
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for this account.');
        }
    },
    processDailyAvgData: function(cmp, data){
        //load single locations 10 nearby neighbors averages into variables to be loaded into chart
        let dto = data;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        //collectionUtils.getMapValue('HPD_WRAPPER_CLOSEST', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('HPD_WRAPPER_CLOSEST',dto.values);

        if (hpdWraps && hpdWraps.length > 0) {
            cmp.set('v.avgHoldPerDayWrappers', hpdWraps);
        } else {
            this.displayUiMsg(cmp, 'warning', 'Could not find nearby location averages');
        }

    },
    processAvgAccounts: function(cmp, response){
      let dto  = response;
      let collectionUtils = cmp.find('collectionUtils');
      let avgAccounts = [];
      let avgAccountIds = [];
      //collectionUtils.getMapValue('ACCOUNT_CLOSEST', dto.values, function(value){avgAccounts = value;});
      //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
      avgAccounts = collectionUtils.getData('ACCOUNT_CLOSEST',dto.values);

      if(avgAccounts && avgAccounts.length >0){
          cmp.set('v.avgAccountList', avgAccounts);
          for(let i=0; i<avgAccounts.length; i++){
              avgAccountIds.push(avgAccounts[i].Id);
          }
          cmp.set('v.avgAccountIdList', avgAccountIds);
      }else{
          this.displayUiMsg(cmp, 'warning', 'No close accounts found for area average calculation.');
      }
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
     * Consume server response from cmp attribute as opposed to directly!
     * @param cmp
     */
    processHpdData: function(cmp){
        let dto = cmp.get('v.HpdData');
        let _self = this;
        let collectionUtils = cmp.find('collectionUtils');
        let hpdWraps = [];
        this.log(cmp,'processHpdData consuming HPD_WRAPPER_LIST','debug');

        //---collectionUtils.getMapValue('HPD_WRAPPER_LIST', dto.values, function (value) {hpdWraps = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        hpdWraps = collectionUtils.getData('HPD_WRAPPER_LIST',dto.values);
        this.log(cmp,'processHpdData checking HpdWraps','debug',hpdWraps);
        if (hpdWraps && hpdWraps.length > 0) {
           // this.concatAccountName(cmp,hpdWraps);
            cmp.set('v.holdPerDayWrappers', hpdWraps);
            cmp.set('v.allLocationsHpd', hpdWraps);
            this.renderDailyChart(cmp, 'All', 'Daily');
        } else {
            this.displayUiMsg(cmp, 'warning', 'No data was found for your criteria. Please modify your search criteria.');
        }
    },
    processUserAccounts: function (cmp, response) {
        let dto = response;
        let accounts = [];
        //---this.collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        accounts = this.collectionUtils.getData('ACCOUNT_LIST',dto.values);
        accounts.unshift("All Locations");
        cmp.set('v.userAccounts', accounts);
        this.setUserAccountOptions(cmp); //---- translate user account array to options array for combo box (location filter)
        let accountId = accounts[0];
        cmp.set('v.selectedAccountId', accountId); //even though type is ID, 'll Locations' passes through
    },

    renderDailyChart: function(cmp, type, style){
        let self = this;
        let chartData;
        let leg;
        if(type==='All' && style !== 'YoY'){
            chartData=self.buildTimeSeriesDailyData(cmp, 'All');
        }else if(type==='Single' && style !== 'YoY'){
            chartData=self.buildTimeSeriesDailyData(cmp, 'Single');
        }else if(style==='YoY'){
            chartData=self.buildMonthlyChartYoyData(cmp, null);
        }
        let allDailyOption = {
            grid:{
                containLabel: true,
              left: 0,
              right: 45,
              top: '8%',
              bottom: 10,
            },
            legend: {
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                }]
            },
            toolbox: {
                top: 0,
                right: 90,
                showTitle: false,
                feature: {
                  saveAsImage:{
                      show: false,
                  },
                  restore:{
                      show: true
                  },
                  dataView: {
                      show: false
                  },
                  dataZoom: {
                      show: false
                  },
                  magicType: {
                      show: false
                  },
                  brush: {
                      show: false
                  }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                    startValue: chartData.zoomStart,
                    endValue: chartData.zoomEnd
                }
            ],
            tooltip: {
                show: true,
                trigger: 'axis',
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                },
                axisPointer: {
                    type: 'cross',
                    snap: true
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                  show: true,
                    interval: 4,
                    areaStyle:{
                      opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                  label: {
                      formatter: function (oParams) {
                          var date = new Date(oParams.value);
                          date.setDate(date.getDate() + 1);
                          var localizedDate =  $A.localizationService.formatDate(date, "EEE MM/dd/yyyy");
                          return localizedDate;
                      }
                  }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 12,
                    margin: 12,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (value, index) {
                        var date = new Date(value);
                        date.setDate(date.getDate() +1);
                        return '  '+$A.localizationService.formatDate(date, "MM/dd")+'  ';
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#00bfff'],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            }, {
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            }]
        };
        let mobile_allDailyOption = {
            grid:{
                left: 15,
                right: 45,
                top: 45,
                bottom: 30,
            },
            legend: {
                top: 0,
                left: 15,
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                }]
            },
            toolbox: {
                top: 0,
                right: 10,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                    startValue: chartData.zoomStart,
                    endValue: chartData.zoomEnd
                }
            ],
            tooltip: {
                show: true,
                confine: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true,
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "EEE MM/dd/yyyy");
                            return localizedDate;
                        }
                    }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 9,
                    margin: 12,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (value, index) {
                        var date = new Date(value);
                       date.setDate(date.getDate() +1);
                        return '  '+$A.localizationService.formatDate(date, "MM/dd")+'  ';
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        fontSize: 10,
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#00bfff'],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            }, {
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            }]
        };
        let singleDailyOption = {
            grid:{
                containLabel: true,
                left: 0,
                right: 45,
                top: '8%',
                bottom: 10,
            },
            legend: {
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                         name: 'My Location Share',
                     },{
                         name: 'My Funds In',
                     },{
                        name: 'Average Location Share',
                    },{
                    name: 'Average Funds In',
                }],
                selected: {
                    'Average Location Share': false,
                    'Average Funds In': false,
                    'My Funds In': true,
                    'My Locations Share': true
                },
                tooltip: {
                    show: true,
                    formatter: function(param){
                        let labelSuffix = '10 Similar Accounts';
                        if(param.name === 'Average Location Share'){
                            return 'Average Location Share of Nearest'+'<br/>'+ labelSuffix;
                        }else if(param.name === 'Average Funds In'){
                            return 'Average Funds In of Nearest'+'<br/>'+ labelSuffix;
                        }else if(param.name === 'My Funds In'){
                            return 'My Locations\' Funds In';
                        }else if(param.name === 'My Location Share'){
                            return 'My Locations\' Share';
                        }
                    },
                    textStyle: {
                        fontSize: 10
                    }
                }
            },
            toolbox: {
                top: 0,
                right: 90,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                    startValue: chartData.zoomStart,
                    endValue: chartData.zoomEnd
                }
            ],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            //global axis label, for some reason this fixs a weird echart bug that applies a 100 left padding to the X axis
            //for some locations - likely related to the hidden y axis 'double chart' functionality goin on - curiously doesnt happen on mobile
            axisLabel: {
                inside: false,
                fontStyle: 'normal',
                fontWeight: 'bold',
                fontSize: 12,
                margin: 12,
                textStyle: {
                    color: 'black'
                },
                formatter: function (value, index) {
                    var date = new Date(value);
                    date.setDate(date.getDate() +1);
                    return '  '+$A.localizationService.formatDate(date, "MM/dd")+'  ';
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 12,
                    margin: 12,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (value, index) {
                        var date = new Date(value);
                        date.setDate(date.getDate() +1);
                        return '  '+$A.localizationService.formatDate(date, "MM/dd")+'  ';
                    }
                },
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "EEE MM/dd/yyyy");
                            return localizedDate;
                        }
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#DAA520','#00bfff','#DAA520'],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            },{
                name: 'Average Location Share',
                type: 'line',
                symbol: 'none',
                smooth: true,
                showSymbol: false,
                data: chartData.seriesAvgLocShareData,
                lineStyle: {
                    color: '#DAA520',
                    width: 2
                }
            }, {
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            },{
                name: 'Average Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesAvgFundsInData,
                itemStyle: {
                    color: '#DAA520'
                }
            }]
        };
        let mobile_singleDailyOption = {
            grid:{
                left: 15,
                right: 45,
                top: 45,
                bottom: 30,
            },
            legend: {
                top: 0,
                left: 15,
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                },{
                    name: 'Average Location Share',
                },{
                    name: 'Average Funds In',
                }],
                selected: {
                    'Average Location Share': false,
                    'Average Funds In': false,
                    'My Funds In': true,
                    'My Locations Share': true
                },
                textStyle: {
                    fontSize: 11
                },
                tooltip: {
                    show: true,
                    formatter: function(param){
                        let labelSuffix = '10 Similar Accounts';
                        if(param.name === 'Average Location Share'){
                            return 'Average Location Share of Nearest'+'<br/>'+ labelSuffix;
                        }else if(param.name === 'Average Funds In'){
                            return 'Average Funds In of Nearest'+'<br/>'+ labelSuffix;
                        }else if(param.name === 'My Funds In'){
                            return 'My Locations\' Funds In';
                        }else if(param.name === 'My Location Share'){
                            return 'My Locations\' Share';
                        }
                    },
                    textStyle: {
                        fontSize: 10
                    }
                }
            },
            toolbox: {
                top: 0,
                right: 10,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                    startValue: chartData.zoomStart,
                    endValue: chartData.zoomEnd
                }
            ],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "EEE MM/dd/yyyy");
                            return localizedDate;
                        }
                    }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 9,
                    margin: 12,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (value, index) {
                        var date = new Date(value);
                        date.setDate(date.getDate() +1);
                        return '  '+$A.localizationService.formatDate(date, "MM/dd")+'  ';
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        fontSize: 10,
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#DAA520','#00bfff','#DAA520'],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            },{
                name: 'Average Location Share',
                type: 'line',
                symbol: 'none',
                smooth: true,
                showSymbol: false,
                data: chartData.seriesAvgLocShareData,
                lineStyle: {
                    color: '#DAA520',
                    width: 2
                }
            }, {
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            },{
                name: 'Average Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesAvgFundsInData,
                itemStyle: {
                    color: '#DAA520'
                }
            }]
        };
        let singleMonthlyOption = {
            grid:{
                containLabel: true,
                left: 0,
                right: 45,
                top: '8%',
                bottom: '3%',
            },
            legend: {
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                },{
                    name: 'Average Location Share',
                },{
                    name: 'Average Funds In',
                }],
                selected: {
                    'Average Location Share': false,
                    'Average Funds In': false,
                    'My Funds In': true,
                    'My Locations Share': true
                },
                tooltip: {
                    show: true,
                    formatter: function(param){
                        let labelSuffix = '10 Similar Accounts';
                        if(param.name === 'Average Location Share'){
                            return 'Average Location Share of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'Average Funds In'){
                            return 'Average Funds In of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'My Funds In'){
                            return 'My Locations\' Funds In';
                        }else if(param.name === 'My Location Share'){
                            return 'My Locations\' Share';
                        }
                    },
                    textStyle: {
                        fontSize: 10
                    }
                }
            },
            toolbox: {
                top: 0,
                right: 90,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [{
                    type: 'inside',
                    startValue: chartData.zoomStart,
                    endValue: chartData.zoomEnd
                }],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams, index) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "MMM 'yy");
                            return localizedDate;
                        }
                    }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 12,
                    margin: 12,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (oParams) {
                        var date = new Date(oParams);
                        date.setDate(date.getDate() + 1);
                        var localizedDateMonth =  $A.localizationService.formatDate(date, "MMM");
                        var localizedDateYear =  $A.localizationService.formatDate(date, "'yy");
                        return ' '+localizedDateMonth+' \n'+localizedDateYear;
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#DAA520','#00bfff','#DAA520'],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            },{
                name: 'Average Location Share',
                type: 'line',
                symbol: 'none',
                smooth: true,
                showSymbol: false,
                data: chartData.seriesAvgLocShareData,
                lineStyle: {
                    color: '#DAA520',
                    width: 2
                }
            }, {
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            },{
                name: 'Average Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesAvgFundsInData,
                itemStyle: {
                    color: '#DAA520'
                }
            }]

        };
        let mobile_singleMonthlyOption = {
            grid:{
                left: 15,
                right: 45,
                top: 45,
                bottom: 30,
            },
            legend: {
                top: 0,
                left: 15,
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                },{
                    name: 'Average Location Share',
                },{
                    name: 'Average Funds In',
                }],
                selected: {
                    'Average Location Share': false,
                    'Average Funds In': false,
                    'My Funds In': true,
                    'My Locations Share': true
                },
                textStyle: {
                    fontSize: 11
                },
                tooltip: {
                    show: true,
                    formatter: function(param){
                        let labelSuffix = '10 Similar Accounts';
                        if(param.name === 'Average Location Share'){
                            return 'Average Location Share of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'Average Funds In'){
                            return 'Average Funds In of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'My Funds In'){
                            return 'My Location Funds In';
                        }else if(param.name === 'My Location Share'){
                            return 'My Locations Share';
                        }
                    },
                    textStyle: {
                        fontSize: 10
                    }
                }
            },
            toolbox: {
                top: 0,
                right: 10,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [{
                type: 'inside',
                startValue: chartData.zoomStart,
                endValue: chartData.zoomEnd
            }],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 5,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams, index) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "MMM 'yy");
                            return localizedDate;
                        }
                    }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 9,
                    margin: 7,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (oParams) {
                        var date = new Date(oParams);
                        date.setDate(date.getDate() + 1);
                        var localizedDateMonth =  $A.localizationService.formatDate(date, "MMM");
                        var localizedDateYear =  $A.localizationService.formatDate(date, "'yy");
                        return ' '+localizedDateMonth+' \n'+localizedDateYear;
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        fontSize: 10,
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#DAA520','#00bfff','#DAA520'],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            },{
                name: 'Average Location Share',
                type: 'line',
                symbol: 'none',
                smooth: true,
                showSymbol: false,
                data: chartData.seriesAvgLocShareData,
                lineStyle: {
                    color: '#DAA520',
                    width: 2
                }
            }, {
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            },{
                name: 'Average Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesAvgFundsInData,
                itemStyle: {
                    color: '#DAA520'
                }
            }]

        };
        let allMonthlyOption = {
            grid:{
                containLabel: true,
                left: 0,
                right: 45,
                top: '8%',
                bottom: '3%',
            },
            legend: {
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                }],
                selected: {
                    'My Funds In': true,
                    'My Locations Share': true
                },
                tooltip: {
                    show: true,
                    formatter: function(param){
                        let labelSuffix = '10 Similar Accounts';
                        if(param.name === 'Average Location Share'){
                            return 'Average Location Share of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'Average Funds In'){
                            return 'Average Funds In of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'My Funds In'){
                            return 'My Locations\' Funds In';
                        }else if(param.name === 'My Location Share'){
                            return 'My Locations\' Share';
                        }
                    },
                    textStyle: {
                        fontSize: 10
                    }
                }
            },
            toolbox: {
                top: 0,
                right: 90,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [{
                type: 'inside',
                startValue: chartData.zoomStart,
                endValue: chartData.zoomEnd
            }],
            tooltip: {
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams, index) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "MMM 'yy");
                            return localizedDate;
                        }
                    }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 12,
                    margin: 12,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (oParams) {
                        var date = new Date(oParams);
                        date.setDate(date.getDate() + 1);
                        var localizedDateMonth =  $A.localizationService.formatDate(date, "MMM");
                        var localizedDateYear =  $A.localizationService.formatDate(date, "'yy");
                        return ' '+localizedDateMonth+' \n'+localizedDateYear;
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#00bfff',],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            },{
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            }]

        };
        let mobile_allMonthlyOption = {
            grid:{
                left: 15,
                right: 45,
                top: 45,
                bottom: 30,
            },
            legend: {
                top: 0,
                left: 15,
                type: 'plain',
                show: true,
                orient: 'horizontal',
                data: [{
                    name: 'My Location Share',
                },{
                    name: 'My Funds In',
                }],
                selected: {
                    'My Funds In': true,
                    'My Locations Share': true
                },
                tooltip: {
                    show: true,
                    formatter: function(param){
                        let labelSuffix = '10 Similar Accounts';
                        if(param.name === 'Average Location Share'){
                            return 'Average Location Share of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'Average Funds In'){
                            return 'Average Funds In of Nearest'+'<br/>'+labelSuffix;
                        }else if(param.name === 'My Funds In'){
                            return 'My Locations\' Funds In';
                        }else if(param.name === 'My Location Share'){
                            return 'My Locations\' Share';
                        }
                    },
                    textStyle: {
                        fontSize: 10
                    }
                }
            },
            toolbox: {
                top: 0,
                right: 10,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [{
                type: 'inside',
                startValue: chartData.zoomStart,
                endValue: chartData.zoomEnd
            }],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' + self.formatNumberWithCommas(param[i].data.value) + '<br/>';
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.dataAxis,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 5,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 4,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisPointer:{
                    label: {
                        formatter: function (oParams, index) {
                            var date = new Date(oParams.value);
                            date.setDate(date.getDate() + 1);
                            var localizedDate =  $A.localizationService.formatDate(date, "MMM 'yy");
                            return localizedDate;
                        }
                    }
                },
                axisLabel: {
                    inside: false,
                    fontStyle: 'normal',
                    fontWeight: 'bold',
                    fontSize: 9,
                    margin: 7,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (oParams) {
                        var date = new Date(oParams);
                        date.setDate(date.getDate() + 1);
                        var localizedDateMonth =  $A.localizationService.formatDate(date, "MMM");
                        var localizedDateYear =  $A.localizationService.formatDate(date, "'yy");
                        return ' '+ localizedDateMonth+' \n'+localizedDateYear;
                    }
                }
            },
            yAxis:[
                {
                    //name: 'Location Share',
                    type: 'value',
                    position: 'right',
                    axisPointer: {
                        label: {
                            formatter: function(param){
                                if(param.value===0){
                                    return '$0';
                                }
                                return '$'+ self.formatNumberWithCommas(param.value);
                            }
                        }
                    },
                    axisLabel: {
                        fontSize: 10,
                        textStyle: {
                            color: 'black',
                            fontWeight: 'bolder'
                        },
                        formatter: function (value, index) {
                            if(value===0){
                                return '$0';
                            }
                            var shortVal;
                            shortVal = self.formatValue('$',value,0);
                            return shortVal;
                        }
                    },
                    splitLine: {
                        lineStyle: {
                            opacity: .5
                        }
                    }
                },
                {
                    show: false,
                    type: 'value',
                    name: 'Funds In',
                    max: chartData.axisMax,
                    axisPointer: {
                        show: false
                    }
                }
            ],
            color: ['#6fb696','#00bfff',],
            series: [{
                name: 'My Location Share',
                type: 'line',
                symbol: 'none',
                showSymbol: false,
                data: chartData.seriesLocShareData,
                lineStyle: {
                    color: '#6fb696',
                    width: 3
                }
            },{
                name: 'My Funds In',
                type: 'bar',
                yAxisIndex: 1,
                showSymbol: false,
                barGap: 0,
                data: chartData.seriesFundsInData,
                itemStyle: {
                    color: '#00bfff'
                }
            }]

        };
        let singleYoyOption = {
            grid:{
                containLabel: true,
                left: 40,
                right: 45,
                top: '8%',
                bottom: 10,
            },
            legend: {
                type: 'scroll',
                show: true,
                orient: 'horizontal',
                selected: chartData.defaultLegend
            },
            toolbox: {
                top: 0,
                right: 90,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                }
            ],
            tooltip: {
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'line',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' ;
                            if(param[i].value){
                                ret+= self.formatNumberWithCommas(param[i].value) + '<br/>';
                            }else{
                                ret+= '----<br/>';
                            }
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.monthsArray,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 0,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLine: {
                    onZero: false
                },
                axisLabel:{
                    margin: 12,
                    fontWeight: 'bolder',
                    fontSize: 12
                }
            },
            yAxis:{
                //name: 'Location Share',
                type: 'value',

                position: 'right',
                boundaryGap: ['5%', '2%'],
                scale: true,
                axisLabel: {
                    textStyle: {
                        color: 'black',
                        fontWeight: 'bolder'
                    },
                    formatter: function (value, index) {
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    }
                },
                splitLine: {
                    lineStyle: {
                        opacity: .5
                    }
                }
            },
            color: ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'],
            series: chartData.allDataSeries
        };
        let mobile_singleYoyOption = {
            grid:{
                left: 15,
                right: 45,
                top: 45,
                bottom: 30,
            },
            legend: {
                top: 0,
                left: 15,
                show: true,
                orient: 'horizontal',
                selected: chartData.defaultLegend
            },
            toolbox: {
                top: 0,
                right: 10,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                }
            ],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'line',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' ;
                            if(param[i].value){
                                ret+= self.formatNumberWithCommas(param[i].value) + '<br/>';
                            }else{
                                ret+= '----<br/>';
                            }
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.monthsArray,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 7,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 0,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLabel: {
                    fontWeight: 'bold'
                },
                axisLine: {
                    onZero: false
                },
            },
            yAxis:{
                //name: 'Location Share',
                type: 'value',

                position: 'right',
                boundaryGap: ['5%', '2%'],
                scale: true,
                axisLabel: {
                    fontSize: 10,
                    textStyle: {
                        color: 'black',
                        fontWeight: 'bolder'
                    },
                    formatter: function (value, index) {
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    }
                },
                splitLine: {
                    lineStyle: {
                        opacity: .5
                    }
                }
            },
            color: ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'],
            series: chartData.allDataSeries
        };
        let allYoyOption = {
        grid:{
            containLabel: true,
            left: 40,
            right: 45,
            top: '8%',
            bottom: 10,
        },
        legend: {
            type: 'scroll',
            show: true,
            orient: 'horizontal',
            selected: chartData.defaultLegend
        },
        toolbox: {
            top: 0,
            right: 90,
            showTitle: false,
            feature: {
                saveAsImage:{
                    show: false,
                },
                restore:{
                    show: true
                },
                dataView: {
                    show: false
                },
                dataZoom: {
                    show: false
                },
                magicType: {
                    show: false
                },
                brush: {
                    show: false
                }
            }
        },
        dataZoom: [
            {
                type: 'inside',
            }
        ],
        tooltip: {
            show: true,
            trigger: 'axis',
            axisPointer: {
                type: 'line',
                snap: true
            },
            formatter: function(param){
                var len = param.length;
                var ret='';
                var i;
                if(len > 0){
                    ret += param[0].axisValueLabel + '<br/>';
                    for(i=0; i<len; i++) {
                        ret += param[i].marker + ' ' + param[i].seriesName + ': $' ;
                        if(param[i].value){
                            ret+= self.formatNumberWithCommas(param[i].value) + '<br/>';
                        }else{
                            ret+= '----<br/>';
                        }
                    }
                    return ret;
                }
            }
        },
        xAxis: {
            type: 'category',
            data: chartData.monthsArray,
            boundaryGap: true,
            z: 3,
            axisTick: {
                length: 8,
                alignWithLabel: true
            },
            splitArea: {
                show: true,
                interval: 0,
                areaStyle:{
                    opacity: .65
                }
            },
            axisLine: {
                onZero: false
            },
            axisLabel:{
                margin: 12,
                fontWeight: 'bolder',
                fontSize: 12
            }
        },
        yAxis:{
                //name: 'Location Share',
                type: 'value',

                position: 'right',
                boundaryGap: ['5%', '2%'],
                scale: true,
                axisLabel: {
                    textStyle: {
                        color: 'black',
                        fontWeight: 'bolder'
                    },
                    formatter: function (value, index) {
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    }
                },
                splitLine: {
                    lineStyle: {
                        opacity: .5
                    }
                }
        },
        color: ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'],
        series: chartData.allDataSeries
    };
        let mobile_allYoyOption = {
            grid:{
                left: 15,
                right: 45,
                top: 45,
                bottom: 30,
            },
            legend: {
                top: 0,
                left: 15,
                type: 'plain',
                show: true,
                orient: 'horizontal',
                selected: chartData.defaultLegend
            },
            toolbox: {
                top: 0,
                right: 10,
                showTitle: false,
                feature: {
                    saveAsImage:{
                        show: false,
                    },
                    restore:{
                        show: true
                    },
                    dataView: {
                        show: false
                    },
                    dataZoom: {
                        show: false
                    },
                    magicType: {
                        show: false
                    },
                    brush: {
                        show: false
                    }
                }
            },
            dataZoom: [
                {
                    type: 'inside',
                }
            ],
            tooltip: {
                confine: true,
                show: true,
                trigger: 'axis',
                axisPointer: {
                    type: 'line',
                    snap: true
                },
                formatter: function(param){
                    var len = param.length;
                    var ret='';
                    var i;
                    if(len > 0){
                        ret += param[0].axisValueLabel + '<br/>';
                        for(i=0; i<len; i++) {
                            ret += param[i].marker + ' ' + param[i].seriesName + ': $' ;
                            if(param[i].value){
                                ret+= self.formatNumberWithCommas(param[i].value) + '<br/>';
                            }else{
                                ret+= '----<br/>';
                            }
                        }
                        return ret;
                    }
                }
            },
            xAxis: {
                type: 'category',
                data: chartData.monthsArray,
                boundaryGap: true,
                z: 3,
                axisTick: {
                    length: 8,
                    alignWithLabel: true
                },
                splitArea: {
                    show: true,
                    interval: 0,
                    areaStyle:{
                        opacity: .65
                    }
                },
                axisLabel: {
                    fontWeight: 'bold'
                },
                axisLine: {
                    onZero: false
                },
            },
            yAxis:{
                //name: 'Location Share',
                type: 'value',

                position: 'right',
                boundaryGap: ['5%', '2%'],
                scale: true,
                axisLabel: {
                    fontSize: 10,
                    textStyle: {
                        color: 'black',
                        fontWeight: 'bolder'
                    },
                    formatter: function (value, index) {
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    }
                },
                splitLine: {
                    lineStyle: {
                        opacity: .5
                    }
                }
            },
            color: ['#c23531','#2f4554', '#61a0a8', '#d48265', '#91c7ae','#749f83',  '#ca8622', '#bda29a','#6e7074', '#546570', '#c4ccd3'],
            series: chartData.allDataSeries
        };
        if(!cmp.get('v.renderTrendChart')) {
            return;
        }
        let eleDiv = cmp.find("dailychart").getElement();
        this.dailyChart = echarts.init(eleDiv, 'light');
        if (window.matchMedia("(max-width: 767px)").matches) {
            //mobile detected
            if(type==='All'){
                if(style==='Monthly'){
                    this.dailyChart.setOption(mobile_allMonthlyOption);
                }else if(style ==='Daily'){
                    this.dailyChart.setOption(mobile_allDailyOption);
                }else if(style ==='YoY'){
                    this.dailyChart.setOption(mobile_allYoyOption);
                }
            }else if(type==='Single'){
                if(style==='Monthly'){
                    this.dailyChart.setOption(mobile_singleMonthlyOption);
                }else if(style ==='Daily'){
                    this.dailyChart.setOption(mobile_singleDailyOption);
                }else if(style ==='YoY'){
                    this.dailyChart.setOption(mobile_singleYoyOption);
                }
            }
        } else {
            if(type==='All'){
                if(style==='Monthly'){
                    this.dailyChart.setOption(allMonthlyOption);
                }else if(style ==='Daily'){
                    this.dailyChart.setOption(allDailyOption);
                }else if(style ==='YoY'){
                    this.dailyChart.setOption(allYoyOption);
                }
            }else if(type==='Single'){
                if(style==='Monthly'){
                    this.dailyChart.setOption(singleMonthlyOption);
                }else if(style ==='Daily'){
                    this.dailyChart.setOption(singleDailyOption);
                }else if(style ==='YoY'){
                    this.dailyChart.setOption(singleYoyOption);
                }

            }
            this.dailyChart.on('click', function (params) {
                const ALL_LOCATIONS     = 1;
                const SPECIFIC_LOCATION = 2;
                let chartStyle = style;
                let chartType  = type;

                if (chartStyle && chartStyle === 'YoY') {
                    self.log(cmp, 'chartStyle = YoY exiting onclick event per requirement', 'warn');
                    return;
                }
                if (params.seriesIndex === SPECIFIC_LOCATION) {     //  A specific location was selected
                    let id = cmp.get('v.selectedAccountId');
                    let date = new Date(params.name);
                    date.setDate(date.getDate() + 1);
                    let fDate = $A.localizationService.formatDate(date, 'YYYY-MM-dd');
                    let dayParam = '&day=' + fDate;
                    let urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({"url": '/machine-performance?accountId=' + id + dayParam});
                    urlEvent.fire();
                } else if (params.seriesIndex === ALL_LOCATIONS) {  // All location option was selected
                    self.log(cmp,'in ALL_LOCATIONS SCENARIO.. chartStyle='+chartStyle + '..chartType='+chartType);
                    let date = new Date(params.name);
                    date.setDate(date.getDate() + 1);
                    let fDate = $A.localizationService.formatDate(date, 'YYYY-MM-dd');
                    let urlParams = '?locShareDateClicked=' + fDate +'&locShareChartStyle='+chartStyle;
                    self.log(cmp,'params='+urlParams,'debug');
                    let urlEvent = $A.get("e.force:navigateToURL");
                    //@TODO there must be a better way to maintain state between 2 different community page.
                    //@TODO community is a bit weaker then reg lightning comps as there are ways with aura comps outside of communities.
                    urlEvent.setParams({"url": '/location-performance' + urlParams});
                    //@see ACv2_LocationPerformance.processLocationShareTrendChartClick
                    urlEvent.fire();
                }
            });
        }
    },
    buildTimeSeriesDailyData: function(cmp, type, style){
        let self = this;
        let dataAxis = [];
        let seriesLocShareData = [];
        let seriesFundsInData = [];
        let seriesAvgLocShareData = [];
        let seriesAvgFundsInData = [];
        let maxFunds = 0;
        let maxShare = 0;
        let maxAvgShare = 0;
        let maxAvgFunds = 0;
        let zoomStart = 0;
        let zoomEnd = 0;
        let dailyData = cmp.get('v.holdPerDayWrappers');
        let avgData;
        let maxIndex=0;
        if(type==='Single'){
            //avg data should be populated in attribute variable
            avgData=cmp.get('v.avgHoldPerDayWrappers');
            maxIndex = cmp.get('v.singleAccountHpdLength');
            if(avgData && avgData.length > 0){
                let maxLength = maxIndex < avgData.length ? maxIndex: avgData.length;
                for(let i=0; i<maxLength; i++){
                    let currRecord = avgData[i];
                    let denom = currRecord.distinctAccountCount;
                    if(denom!==0){
                        let date = new Date(currRecord.hpdDate);
                        if(maxAvgShare < (currRecord.locShare/denom)){
                            maxAvgShare = (currRecord.locShare/denom);
                        }
                        seriesAvgLocShareData.push({
                            value: (currRecord.locShare/denom).toFixed(2)
                        });
                        if(maxAvgFunds < (currRecord.fundsIn/denom)){
                            maxAvgFunds = (currRecord.fundsIn/denom);
                        }
                        seriesAvgFundsInData.push({
                            value: (currRecord.fundsIn/denom).toFixed(2)
                        });
                    }
                }
                seriesAvgLocShareData.reverse();
                seriesAvgFundsInData.reverse();
            }
        }
        if(dailyData && dailyData.length > 0){
            //set zoom for initial chart window
            zoomEnd =dailyData.length -1;
            if(dailyData.length > 30){
                zoomStart = dailyData.length - 30;
            }
            for(let i=0; i<dailyData.length; i++){
                let currRecord = dailyData[i];
                let date = new Date(currRecord.hpdDate);
                if(maxShare < currRecord.locShare){
                    maxShare = currRecord.locShare;
                }
                seriesLocShareData.push({
                    value: currRecord.locShare
                });
                if(maxFunds < currRecord.fundsIn){
                    maxFunds = currRecord.fundsIn;
                }
                seriesFundsInData.push({
                    value: currRecord.fundsIn
                });
                dataAxis.push(date);
            }
        }
        seriesLocShareData .reverse();
        seriesFundsInData .reverse();
        dataAxis.sort(function (a, b) {return a.getTime() - b.getTime()});
        let axisMax= maxFunds > maxAvgFunds ? 3*maxFunds: 3*maxAvgFunds;
        let shareMax=maxShare;

        if(maxShare!==0){
            shareMax=1.05*maxShare;
        }
        return {
            zoomStart: zoomStart,
            zoomEnd: zoomEnd,
            dataAxis: dataAxis,
            axisMax: axisMax,
            shareMax: shareMax,
            seriesLocShareData: seriesLocShareData,
            seriesFundsInData: seriesFundsInData,
            seriesAvgLocShareData: seriesAvgLocShareData,
            seriesAvgFundsInData: seriesAvgFundsInData
        };
    },
    buildMonthlyChartYoyData: function (cmp, arr) {
        var self = this;
        var allDataSeries = [];
        var dataSeriesYear = [];
        var defaultLegend = {};
        var hpdWraps;
        var allMonthsSet = new Set();
        var allMonthsIntSet = new Set();
        if (arr) {
            hpdWraps = arr;
        } else {
            hpdWraps = cmp.get('v.holdPerDayWrappers');
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

                    var lineWidth = 3;
                    var nk = Number(key);
                    if (Number(key) === maxYear) {
                        lineWidth = 5;
                        defaultLegend[nk] = true;
                    } else if(Number(key) === maxYear - 1){
                        lineWidth = 3;
                        defaultLegend[nk] = true;
                    } else {
                        lineWidth = 3;
                        defaultLegend[nk] = false;
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
                        symbol: 'rect'

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
                            fundsIn: hpdWrap.fundsIn,
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
                alert('Error: ACV2.Home 2904: '+ e);
            }
            var allMonths2 = [];
            for (const pair of mMonthNum_MonthString) {
                allMonths2.push(pair[1]);
            }
            return {
                allDataSeries: allDataSeries,
                defaultLegend: defaultLegend,
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
                            fundsIn: 0,
                            hpdDate: hpdDate,
                            hpdMonth: hpdMapKey,
                            hpdYear: year,
                            locShare: null,
                        };
                        data.push(hpdWrap);
                    }
                }
            }
        }
    },
    processGraphButtonClick: function(cmp, event){
        let target;
        let btnClicked;
        if(event){
            target=event.getSource();
            btnClicked = target.get('v.name');
        }
        let btnIds = ["Daily", "Monthly", "YoY"];
        window.setTimeout(function () {
            for(let i = 0; i < btnIds.length; i++) {
                let btnId = btnIds[i];
                let btnCmp = cmp.find(btnId);
                if (btnId === btnClicked) $A.util.addClass(btnCmp, "accel-btn-is-selected");
                else $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            }
        }, 0);
        let graphType = cmp.get('v.selectedAccountId');
        let currGraphBtn = cmp.get('v.selectedGraphBtn');
        if(btnClicked==='Daily' && currGraphBtn !== 'Daily'){
            cmp.set('v.selectedGraphBtn', 'Daily');
            cmp.set('v.graphTitle', 'My Daily Location Share Trend');
            if(graphType==='All Locations'){
                //render initial graph
                this.retrieveAllLocationsData(cmp);
                cmp.set('v.selectedAccount', '');
            }else{
                //render individual location graph
                this.retrieveDailyAvgData(cmp);
            }
        }else if(btnClicked==='Monthly' && currGraphBtn !== 'Monthly'){
            cmp.set('v.selectedGraphBtn', 'Monthly');
            cmp.set('v.graphTitle', 'My Monthly Location Share Trend');
            if(graphType==='All Locations'){
                //retrieve monthly all hpd data chain
                this.retrieveMonthlyHpdData(cmp);
            }else{
                //retrieve monthly single hpd data chain
                this.retrieveMonthlyAvgData(cmp);
            }
        }else if(btnClicked==='YoY' && currGraphBtn !== 'YoY'){
            cmp.set('v.selectedGraphBtn', 'YoY');
            cmp.set('v.graphTitle', 'My Location Share Year-Over-Year');
            if(graphType==='All Locations'){
                this.retrieveAllYoyHpdData(cmp);
            }else{
                this.retrieveSingleYoyHpdData(cmp);
            }
        }
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
    defaultSelectionDates: function (cmp) {
        let endDate = new Date();
        let sEndDate = $A.localizationService.formatDate(endDate, 'YYYY-MM-dd');
        cmp.set('v.endDate', sEndDate);
        let startDate = new Date(endDate.valueOf());
        startDate.setDate(startDate.getDate() - 30);
        let sStartDate = $A.localizationService.formatDate(startDate, 'YYYY-MM-dd');
        cmp.set('v.startDate', sStartDate);

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
                }else{
                    concatName = account;
                    let accountOption = {'label': concatName, 'value': 'All Locations'};
                    accountOptions.push(accountOption);
                }
            }
        }
        cmp.set('v.userAccountOptions',accountOptions);
    },
    getAccountById: function (arr, value) {
        for (let i = 0, iLen = arr.length; i < iLen; i++) {
            if (arr[i].Id === value) return arr[i];
        }
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
     *
     * @param cmp
     * @param msg    if msg is an error and contains generic. will toast a generic error msg.
     * @param level
     * @param jsonObj
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
                var cmpName = '--- Accel_CommunityHome CMP --- ';
                var cLogger = this.loggingUtils;
                cLogger.log(cmpName, lvl, msg, jsonObj);
                // https://accel-entertainment.monday.com/boards/286658657/
                if(lvl === 'error' && msg ==='generic') {
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
        if(self.dailyChart){
            self.dailyChart.resize();
        }
        //if(self.locationPieChart) {
        //    self.locationPieChart.resize();
       // }
       // if(self.locationMonthlyChart) {
        //    self.locationMonthlyChart.resize();
        //}
        //self.log(cmp,'helper window is resizing');
    },
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
                var cmpName = '--- Accel_CommunityHome --- ';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, lvl, msg, jsonObj);
                if(lvl === 'error' && msg.includes('generic')) {
                    let easyMsg = this.friendlyErrorMsg;
                    this.uiMessagingUtils.displayUiMsg(lvl, easyMsg);
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

})