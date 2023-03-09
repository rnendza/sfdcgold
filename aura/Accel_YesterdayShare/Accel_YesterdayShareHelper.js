({
    collectionUtils: null,
    loggingUtils:null,
    formatUtils: null,
    uiMessagingUtils:null,
    //https://accel-entertainment.monday.com/boards/286658657/
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:10000, //10 seconds
    COMMUNITY_SETTINGS:'CONTACT_CONTROLLED_COMMUNITY_SETTINGS',

    setNumAccs: function(cmp){
      cmp.lax.enqueue('c.getNumAccounts')
          .then(response =>{
              let size = response;
              cmp.set('v.numAccounts', size);
          });
    },
    /**
     * We need to call this in init as due to lifecycle issues. the DOM needs be set on aura if before
     * echart inits.
     * @param cmp
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
                    this.log(cmp,'sObject Community_User_Setting__c not found for logged in user!','error');
                } else {
                    cmp.set('v.communityUserSettingsNotFound',false);
                    //@TODO call method that sets flags to prevent chained queries and stuff that is hidden.
                    this.log(cmp,'communityUserSettings','info',JSON.stringify(communityUserSettings));
                }
            })
            .catch(errors => {
                //alert('toss error');
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/294451871
     *
     * It's hard to tell when we are done here since these are async and probably boxcarred but lets throw it on what I
     * ....without really knowing what is going on here. think might be the longest running query. ie. this is related
     * to the spinner. Previously it was just shutting it off outside the promise returns which essentially shut it off
     * immediately.
     *
     * @param cmp
     */
    retrieveAllYesterdayData: function (cmp) {
        //cmp.set('v.showSpinner',true);
        cmp.set('v.showYesterdayShareSpinner',true);
        cmp.set('v.showWeekSpinner', true);
        let errors = [];
        // logic from

        cmp.lax.enqueue('c.retrieveYesterdaysAggregatedLocationTotals')
            .then(response => {
                this.log(cmp, 'response from retrieveYesterdaysAggregatedLocationTotals..', 'info', response);
                this.processYesterdayData(cmp,response);
                return this.retrieveCurrWeekData(cmp);
            })
            .catch(errors => {
                cmp.set('v.showYesterdayShareSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        cmp.lax.enqueue('c.retrieveYesterdayAverageTotals')
            .then(response=> {
                this.log(cmp, 'response from retrieveYesterdaysAverageTotals..', 'info', response);
                this.processYesterdayAverageTotals(cmp, response);
            })
            .catch(errors => {
                cmp.set('v.showYesterdayShareSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        cmp.lax.enqueue('c.retrieveYTDRevenue')
            .then (response =>{
                this.processYTDRevenue(cmp, response);
                cmp.set('v.showYesterdayShareSpinner',false);
            })
            .catch(errors=>{
                cmp.set('v.showYesterdayShareSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        cmp.lax.enqueue('c.retrieveMTDRevenue')
            .then(response=>{
                this.processMTDRevenue(cmp, response);
            })
            .catch(errors=>{
                cmp.set('v.showYesterdayShareSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        // https://accel-entertainment.monday.com/boards/286658657/pulses/294451871
        //cmp.set('v.showSpinner',false);
    },
    retrieveCurrWeekData: function(cmp){
        let hpdDate = cmp.get('v.yesterdayDate');
        const params = {d: hpdDate};
        cmp.lax.enqueue('c.retrieveCurrWeekAggregatedLocationTotals', params)
            .then(response => {
                this.log(cmp, 'response from retrieveCurrWeekAggregatedLocationTotals..', 'info', response);
                this.processCurrWeekData(cmp,response);
            })
            .catch(errors => {
                cmp.set('v.showCurrWeekSpinner',false);
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
        cmp.lax.enqueue('c.retrieveLastWeekAggregatedLocationTotals', params)
            .then(response => {
                this.log(cmp, 'response from retrieveLastWeekAggregatedLocationTotals..', 'info', response);
                this.processLastWeekData(cmp,response);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
     *
     * @param cmp
     * @param response
     */
    processYTDRevenue: function(cmp, response){
        let dto = response; //array with 2 wrappers in it
        let ytdData= [];
        //--deprecated this.collectionUtils.getMapValue('YTD_DATA', dto.values, function (value) {ytdData = value;});
        ytdData = this.collectionUtils.getData('YTD_DATA',dto.values);

        if(ytdData.length === 2 && ytdData[1].netRevenue !== 0){
            let x=((ytdData[0].netRevenue - ytdData[1].netRevenue)/ytdData[1].netRevenue)*100;
            cmp.set('v.ytdRevenueDiff', x.toFixed(2));
            cmp.set('v.ytdRevenueDiffString', x.toFixed(2));
        }
        cmp.set('v.ytdRevenue', this.formatNumberWithCommas(ytdData[0].netRevenue));
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
     * @param cmp
     * @param response
     */
    processMTDRevenue: function(cmp, response){
        let dto = response; //array with 2 wrappers in it
        let mtdData= [];
        //---  deprecated this.collectionUtils.getMapValue('MTD_DATA', dto.values, function (value) {mtdData = value;});
        mtdData = this.collectionUtils.getData('MTD_DATA',dto.values);
        this.log(cmp,'processMTDRevenue MTD_DATA returned','debug',dto);

        //-- 8-20-2019
        let revenueMtdMonthName;
        //--- deprecated this.collectionUtils.getMapValue('REVENUE_MTD_MONTHNAME', dto.values, function (value) {revenueMtdMonthName = value;});
        revenueMtdMonthName = this.collectionUtils.getData('REVENUE_MTD_MONTHNAME',dto.values);
        cmp.set('v.revenueMtdMonthName',revenueMtdMonthName);

        let validYesterdayDate;
        //---- deprecated this.collectionUtils.getMapValue('VALID_YESTERDAY_DATE', dto.values, function (value) {validYesterdayDate = value;});
        validYesterdayDate = this.collectionUtils.getData('VALID_YESTERDAY_DATE',dto.values);
        this.log(cmp,'valid yesterday date','debug',validYesterdayDate);

        let revenueYtdYear;
        //----- deprecated this.collectionUtils.getMapValue('REVENUE_YTD_YEAR', dto.values, function (value) {revenueYtdYear = value;});
        revenueYtdYear = this.collectionUtils.getData('REVENUE_YTD_DATA',dto.values);
        if(revenueYtdYear && this.isInt(revenueYtdYear)) {
            cmp.set('v.year',revenueYtdYear);
        }
        //--- end

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
    },
    /**
     * https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
     *
     * @param cmp
     * @param response
     */
    processYesterdayData: function(cmp,response) {
        let dto = response; //aggregated response object
        let arrYesterdayData = [];
        //---- deprecated this.collectionUtils.getMapValue('ALL_LOC_YESTERDAY_SUM', dto.values, function (value) {arrYesterdayData = value;});
        arrYesterdayData = this.collectionUtils.getData('ALL_LOC_YESTERDAY_SUM',dto.values);
        //---------------
        //  Community User Settings (Set in doInit)
        let communityUserSettings = cmp.get('v.communityUserSettings');
        let communityUserSettingsNotFound = cmp.get('v.communityUserSettingsNotFound');

        cmp.set('v.yesterdaysHpds',arrYesterdayData);
        //let ret = this.buildYesterdayData(cmp);
        //ret will contain the 2 object ur building ie. ret.seriesData and ret.categoryData


        /**
         * Without the below it would try to init to a non existent div Id.
         * @type {boolean}
         * @todo we should probably try to bypass all processing if hidden to speed page load.
         */

        /**
         *  2/20/2023 potential bug fix. ie. communityUserSettings.Display_Yesterday_Bar_Chart__c go BOOM!
         *
         *  community user settings is retrieved in the init lifecycle (controller) we are at this point in the code in the scripts loaded lifecycle.
         *
         *  The init lifecycle took too long to retrieve community user settings (echarts loaded first) thus the communityUserSettings
         *  object was never created yet. doing an object.prop will result in a null error. Ensure object exits b4 referencing property.
         *
         *  Possibly due to the fact that there are no way more community users thus the time to retrieve a setting takes longer then
         *  loading eCharts? Not sure.
         *
         *  @see https://accel-entertainment.monday.com/boards/286658657/pulses/4021384789
         */
        // communityUserSettings = null; <---  RJN Test Fix.
        // <--- OLD LOGIC ----> let renderBar = communityUserSettingsNotFound || communityUserSettings.Display_Yesterday_Bar_Chart__c;
        let renderBar = communityUserSettingsNotFound || !communityUserSettings || communityUserSettings.Display_Yesterday_Bar_Chart__c;
        cmp.set('v.showYesterdayShareSpinner',false);
         if(renderBar) {
             this.renderYesterdayLocationShareChart(cmp);
         }else{
             //some functionality chained from renderYesterdayLocationShareChart needs to be called, not best implementation
             let ret =this.buildYesterdayLocationShareData(cmp);
         }
        this.buildYesterdayFundsInData(cmp);

    },
    processCurrWeekData: function(cmp,response) {
        let dto = response; //aggregated response object
        let arrCurrWeekData = [];
        let currWeekLabel;
        //---- deprecated this.collectionUtils.getMapValue('ALL_LOC_CURR_WEEK_SUM', dto.values, function (value) {arrYesterdayData = value;});
        arrCurrWeekData = this.collectionUtils.getData('ALL_LOC_CURR_WEEK_SUM',dto.values);
        currWeekLabel = this.collectionUtils.getData('CURR_WEEK_LABEL', dto.values);

        cmp.set('v.currWeekHpds',arrCurrWeekData);
        cmp.set('v.currFiscalPeriod', currWeekLabel);
        //  Community User Settings (Set in doInit)
        let communityUserSettings = cmp.get('v.communityUserSettings');
        let communityUserSettingsNotFound = cmp.get('v.communityUserSettingsNotFound');
        /**
         * Without the below it would try to init to a non existent div Id.
         * @type {boolean}
         * @todo we should probably try to bypass all processing if hidden to speed page load.
         */
        /**
         *  2/20/2023 potential bug fix. ie. communityUserSettings.Display_Week_Chart__c; go BOOM!
         *
         *  community user settings is retrieved in the init lifecycle (controller) we are at this point in the code in the scripts loaded lifecycle.
         *
         *  The init lifecycle took too long to retrieve community user settings (echarts loaded first) thus the communityUserSettings
         *  object was never created yet. doing an object.prop will result in a null error. Ensure object exits b4 referencing property.
         *
         *  Possibly due to the fact that there are no way more community users thus the time to retrieve a setting takes longer then
         *  loading eCharts? Not sure.
         */
        let renderBar = communityUserSettingsNotFound || !communityUserSettings || communityUserSettings.Display_Week_Chart__c;
        //  ----> OLD LOGIC <----  let renderBar = communityUserSettingsNotFound || communityUserSettings.Display_Week_Chart__c;
        cmp.set('v.showWeekSpinner', false);
        if(renderBar) {
            this.renderCurrWeekChart(cmp);
         }

    },
    processLastWeekData: function(cmp,response) {
        let dto = response; //aggregated response object
        let arrLastWeekData = [];
        let lastWeekLabel;
        //---- deprecated this.collectionUtils.getMapValue('ALL_LOC_LAST_WEEK_SUM', dto.values, function (value) {arrYesterdayData = value;});
        arrLastWeekData = this.collectionUtils.getData('ALL_LOC_LAST_WEEK_SUM',dto.values);
        lastWeekLabel = this.collectionUtils.getData('LAST_WEEK_LABEL', dto.values);

        cmp.set('v.lastWeekHpds',arrLastWeekData);
        cmp.set('v.lastFiscalPeriod', lastWeekLabel);

        //  Community User Settings (Set in doInit)
        let communityUserSettings = cmp.get('v.communityUserSettings');
        let communityUserSettingsNotFound = cmp.get('v.communityUserSettingsNotFound');
        /**
         * Without the below it would try to init to a non existent div Id.
         * @type {boolean}
         * @todo we should probably try to bypass all processing if hidden to speed page load.
         */
    },
    renderYesterdayLocationShareChart: function(cmp){
        let self = this;
        let data = this.buildYesterdayLocationShareData(cmp);

        let cTitle = cmp.get('v.weekday')+' Total Location Share by Account';
        let title = {
            text: cTitle,
            subtext: '  Showing: Location Share',
            textStyle: {
                fontSize: 14
            },
            top: 10,
            left: 10,
        };
        let option = {
            title: title,
            legend: {
                show: false
            },
            grid: {
                left: 120,
                bottom: 24,
                right: 24
            },

            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function (value) {
                        return '$' + value;
                    },
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisLabel: {
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 108
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Previous Day Location Share',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                },
            }],
            tooltip: {
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    /*====================== RJN Commented out 6/10/2019
                    text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>
                     ======================== RJN END Comment*/


                    /*
                     * RJN Added defensive checks and coerced type to a number .
                     *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                     */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {locShare = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.fundsIn) {fundsIn = parseFloat(param.data.fundsIn);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        //self.log(cmp,'netRevenue='+netRevenue,'debug');
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };
        let mOption = {
            title: title,
            legend: {
                show: false
            },
            grid: {
                left: 100,
                bottom: 28,
                right: 20
            },

            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function (value) {
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    },
                    fontSize: 10,
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisTick: {
                    show: false
                },
                axisLabel: {
                    fontSize: 10,
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 90
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Previous Day Location Share',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                },
            }],
            tooltip: {
                confine: true,
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    /*====================== RJN Commented out 6/10/2019
                    text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>
                     ======================== RJN END Comment*/


                    /*
                     * RJN Added defensive checks and coerced type to a number .
                     *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                     */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {locShare = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.fundsIn) {fundsIn = parseFloat(param.data.fundsIn);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        //self.log(cmp,'netRevenue='+netRevenue,'debug');
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };
        if(data.seriesData.length > 0) {
            //  Community User Settings (Set in doInit)
            let communityUserSettings = cmp.get('v.communityUserSettings');
            let communityUserSettingsNotFound = cmp.get('v.communityUserSettingsNotFound');


            /**
             * Without the below it would try to init to a non existent div Id.
             * @type {boolean}
             * @todo we should probably try to bypass all processing if hidden to speed page load.
             */

            /**
             *  2/20/2023 potential bug fix. ie. communityUserSettings.Display_Yesterday_Bar_Chart__c; go BOOM!
             *
             *  community user settings is retrieved in the init lifecycle (controller) we are at this point in the code in the scripts loaded lifecycle.
             *
             *  The init lifecycle took too long to retrieve community user settings (echarts loaded first) thus the communityUserSettings
             *  object was never created yet. doing an object.prop will result in a null error. Ensure object exits b4 referencing property.
             *
             *  Possibly due to the fact that there are no way more community users thus the time to retrieve a setting takes longer then
             *  loading eCharts? Not sure.
             */
            let renderBar = communityUserSettingsNotFound || !communityUserSettings || communityUserSettings.Display_Yesterday_Bar_Chart__c;
            // let renderBar = communityUserSettingsNotFound || communityUserSettings.Display_Yesterday_Bar_Chart__c;
            if(renderBar) {
                let ecdiv = cmp.find("echarts-yesterday-area").getElement();
                this.yesterdayShareChart = echarts.init(ecdiv, 'light');
                if (window.matchMedia("(max-width: 767px)").matches) {
                    //mobile chart
                    this.yesterdayShareChart.setOption(mOption);
                } else {
                    //desktop chart
                    this.yesterdayShareChart.setOption(option);
                    this.yesterdayShareChart.on('click', function (params) {
                        var data = params.data;
                        var id = data.id;
                        var yesterdayParam = '&yesterday=true';
                        var urlEvent = $A.get("e.force:navigateToURL");
                        urlEvent.setParams({"url": '/machine-performance?accountId=' + id + yesterdayParam});
                        urlEvent.fire();
                    });
                }
            }
        }
    },
    buildYesterdayLocationShareData: function(cmp){
        let self = this;
        let yesterdayData = cmp.get('v.yesterdaysHpds');
        let categoryData = [];
        let seriesData = [];
        let totalLocationShare =0;
        //self.log(cmp,'building eChart yesterdayData','info',yesterdayData);
        if(yesterdayData && yesterdayData.length > 0) {
            //push date to component
            cmp.set('v.yesterdayDate',$A.localizationService.formatDate(yesterdayData[0].hpdDate, "MM/dd/YYYY"));
            cmp.set('v.yesterdayDateString',$A.localizationService.formatDate(yesterdayData[0].hpdDate, "EEEE"));
            cmp.set('v.weekday', $A.localizationService.formatDate(yesterdayData[0].hpdDate, "EEEE"));
            let communityUserSettings = cmp.get('v.communityUserSettings');
            for(let i=0;i<yesterdayData.length;i++) {
                let currentRecord = yesterdayData[i];
                // If the community user profile setting is checked. user the addesss to display if not use the DBA Name.
                if(communityUserSettings && communityUserSettings.Display_Location_Address__c ) {
                    currentRecord.categoryName  = currentRecord.accountPhysicalStreet;
                    currentRecord.categoryValue = currentRecord.accountPhysicalStreet;
                } else {
                    currentRecord.categoryName  = currentRecord.accountId;
                    currentRecord.categoryValue = currentRecord.accountName;
                }
                //-------------------------------------------------------------------------------
                let resultDebug = '';
                categoryData.push({
                    /* https://accel-entertainment.monday.com/boards/286658657/pulses/294459025
                     name: currentRecord.accountPhysicalStreet,
                     value: currentRecord.accountPhysicalStreet,
                     */
                    name: currentRecord.categoryName,
                    value: currentRecord.categoryValue,
                    sortVal: currentRecord.locShare,
                     //id: currentRecord.accountId
                 });
                //self.log(cmp,'pushed into category data:','info',JSON.stringify(categoryData[i]));
                 if(currentRecord.locShare >=0){
                     //push data styled as a green bar
                     seriesData.push({
                         //name: currentRecord.accountPhysicalStreet,
                         value: currentRecord.locShare,
                         id: currentRecord.accountId,
                         amtPlayed: currentRecord.amtPlayed,
                         amtWon: currentRecord.amtWon,
                         fundsIn: currentRecord.fundsIn,
                         fundsOut: currentRecord.fundsOut,
                         netRevenue: currentRecord.netRevenue,
                         dbaName: currentRecord.accountName,
                         street: currentRecord.accountPhysicalStreet,

                         itemStyle: {
                             color: '#6fb696'
                         }
                     });
                 }else {
                     //push data as red bar

                     seriesData.push({
                         //name: currentRecord.accountPhysicalStreet,
                         value: currentRecord.locShare,
                         id: currentRecord.accountId,
                         amtPlayed: currentRecord.amtPlayed,
                         amtWon: currentRecord.amtWon,
                         fundsIn: currentRecord.fundsIn,
                         fundsOut: currentRecord.fundsOut,
                         netRevenue: currentRecord.netRevenue,
                         dbaName: currentRecord.accountName,
                         street: currentRecord.accountPhysicalStreet,

                         itemStyle: {
                             color: '#FF0000'
                         }
                     });
                 }
                resultDebug += 'result=accountId='+currentRecord.accountId + '...shippingstreet='+currentRecord.accountPhysicalStreet;
                resultDebug += '...loc share='+currentRecord.locShare;
                this.log(cmp,resultDebug,'info',currentRecord);
                totalLocationShare +=currentRecord.locShare;
            }
            cmp.set('v.yesterdayLocShare', totalLocationShare.toFixed(2));
            cmp.set('v.yesterdayLocShareVal', this.formatNumberWithCommas(totalLocationShare.toFixed(2)));
        }

        if(categoryData &&  categoryData.length >1){
            categoryData.sort(function(a,b){return a.sortVal - b.sortVal});
        }
        if(seriesData && seriesData.length >1){
            seriesData.sort(function(a,b){return a.value - b.value});
        }
        return {
            seriesData: seriesData,
            categoryData: categoryData
        };
    },
    renderYesterdayFundsInChart: function(cmp){
        let self = this;
        let data = this.buildYesterdayFundsInData(cmp);
        let ecdiv = cmp.find("echarts-yesterday-area").getElement();
        let cTitle = cmp.get('v.weekday')+' Total Funds In by Account';
        let title = {
            text: cTitle,
            subtext: '  Showing: Funds In',
            textStyle: {
                fontSize: 14
            },
            top: 10,
            left: 10,
        };
        let option = {
            title: title,
            legend: {
                show: false
            },
            grid: {
                left: 120,
                bottom: 24,
                right: 24
            },
            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function (value) {
                        return '$' + value;
                    },
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisLabel: {
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 108
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Previous Day Funds In',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                }
            }],
            tooltip: {
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    // text=text+'<b>'+param.name+'</b><br/>';
                    // text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    // text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    // text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    // //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    // text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    // //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    //
                    //

                    /*
                    * RJN Added defensive checks and coerced type to a number .
                    *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                    */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {fundsIn = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.locShare) {locShare = parseFloat(param.data.locShare);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        //self.log(cmp,'netRevenue='+netRevenue,'debug');
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;



                    return text;
                }
            }
        };
        let mOption = {
            title: title,
            legend: {
                show: false
            },
            grid: {
                left: 100,
                bottom: 28,
                right: 20
            },

            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function (value) {
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    },
                    fontSize: 10,
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisTick: {
                    show: false
                },
                axisLabel: {
                    fontSize: 10,
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 90
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Previous Day Funds In',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                },
            }],
            tooltip: {
                confine: true,
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    /*====================== RJN Commented out 6/10/2019
                    text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>
                     ======================== RJN END Comment*/


                    /*
                     * RJN Added defensive checks and coerced type to a number .
                     *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                     */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {fundsIn = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.locShare) {locShare = parseFloat(param.data.locShare);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        //self.log(cmp,'netRevenue='+netRevenue,'debug');
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };

        if(data.seriesData.length > 0) {
            this.yesterdayFundsInChart = echarts.init(ecdiv, 'light');
            if (window.matchMedia("(max-width: 767px)").matches) {
                this.yesterdayFundsInChart.setOption(mOption);
            } else {
                this.yesterdayFundsInChart.setOption(option);
                this.yesterdayFundsInChart.on('click', function (params){
                    var data = params.data;
                    var id=data.id;
                    var yesterdayParam ='&yesterday=true';
                    var urlEvent = $A.get("e.force:navigateToURL");
                    urlEvent.setParams({"url": '/machine-performance?accountId=' + id + yesterdayParam});
                    urlEvent.fire();
                });
            }
        }
    },
    buildYesterdayFundsInData: function(cmp){
        let self = this;
        let yesterdayData = cmp.get('v.yesterdaysHpds');
        let categoryData = [];
        let seriesData = [];
        let totalFundsIn =0;
        //self.log(cmp,'building eChart yesterdayFundsIn','info',yesterdayData);
        if(yesterdayData && yesterdayData.length > 0) {
            //push date to component
            cmp.set('v.yesterdayDate',$A.localizationService.formatDate(yesterdayData[0].hpdDate, "MM/dd/YYYY"));
            let communityUserSettings = cmp.get('v.communityUserSettings');
            for(let i=0;i<yesterdayData.length;i++) {
                let currentRecord = yesterdayData[i];
                let resultDebug = '';
                let categoryName = communityUserSettings && communityUserSettings.Display_Location_Address__c
                    ? currentRecord.accountPhysicalStreet : currentRecord.accountName;

                categoryData.push({
                    // name: currentRecord.accountPhysicalStreet,
                    // value: currentRecord.accountPhysicalStreet,
                     name: categoryName,
                     value: categoryName,
                    sortVal: currentRecord.fundsIn,
                    //id: currentRecord.accountId
                });
                seriesData.push({
                    //name: currentRecord.accountPhysicalStreet,
                    value: currentRecord.fundsIn,
                    id: currentRecord.accountId,
                    amtPlayed: currentRecord.amtPlayed,
                    amtWon: currentRecord.amtWon,
                    fundsIn: currentRecord.fundsIn,
                    fundsOut: currentRecord.fundsOut,
                    netRevenue: currentRecord.netRevenue,
                    dbaName: currentRecord.accountName,
                    locShare: currentRecord.locShare,
                    street: currentRecord.accountPhysicalStreet,
                    itemStyle: {
                        color: '#00bfff'
                    }
                });
                resultDebug += 'result=accountId='+currentRecord.accountId + '...shippingstreet='+currentRecord.accountPhysicalStreet;
                resultDebug += '...funds in='+currentRecord.fundsIn;
                this.log(cmp,resultDebug,'info',currentRecord);
                totalFundsIn +=currentRecord.fundsIn;
            }
            cmp.set('v.yesterdayFundsIn', this.formatNumberWithCommas(totalFundsIn.toFixed(0)));
        }

        if(categoryData &&  categoryData.length >1){
            categoryData.sort(function(a,b){return a.sortVal - b.sortVal});
        }
        if(seriesData && seriesData.length >1){
            seriesData.sort(function(a,b){return a.value - b.value});
        }
        return {
            seriesData: seriesData,
            categoryData: categoryData
        };
    },
    renderCurrWeekChart: function(cmp){
        let self = this;
        let data = this.buildCurrWeekData(cmp);
        let ecdiv = cmp.find("echarts-curr-week").getElement();
        let option = {
            legend: {
                show: false
            },
            grid: {
                left: 120,
                bottom: 24,
                right: 24,
                top: 18
            },
            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function (value) {
                        return '$' + value;
                    },
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisLabel: {
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 108
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Current Week Location Share',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                }
            }],
            tooltip: {
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    // text=text+'<b>'+param.name+'</b><br/>';
                    // text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    // text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    // text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    // //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    // text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    // //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    //
                    //

                    /*
                    * RJN Added defensive checks and coerced type to a number .
                    *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                    */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {locShare = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.fundsIn) {fundsIn = parseFloat(param.data.fundsIn);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };
        let mOption = {
            legend: {
                show: false
            },
            grid: {
                left: 100,
                bottom: 28,
                right: 20,
                top:0
            },
            xAxis: {
                type: 'value',
                axisLabel: {
                   formatter: function(value){
                       if(value===0){
                           return '$0';
                       }
                       var shortVal;
                       shortVal = self.formatValue('$',value,0);
                       return shortVal;
                   },
                    fontSize: 10,
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisTick: {
                  show: false
                },
                axisLabel: {
                    fontSize: 10,
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 90
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Current Week Location Share',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                }
            }],
            tooltip: {
                confine: true,
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    // text=text+'<b>'+param.name+'</b><br/>';
                    // text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    // text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    // text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    // //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    // text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    // //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    //
                    //

                    /*
                    * RJN Added defensive checks and coerced type to a number .
                    *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                    */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {locShare = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.fundsIn) {fundsIn = parseFloat(param.data.fundsIn);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };

        if(data.seriesData.length > 0) {
            this.currWeekChart = echarts.init(ecdiv, 'light');
            if (window.matchMedia("(max-width: 767px)").matches) {
                this.currWeekChart.setOption(mOption);
            } else {
                this.currWeekChart.setOption(option);
                this.currWeekChart.on('click', function (params){
                    var data = params.data;
                    var id=data.id;
                    //var yesterdayParam ='&yesterday=true';
                    var urlEvent = $A.get("e.force:navigateToURL");
                    //urlEvent.setParams({"url": '/machine-performance?accountId=' + id + yesterdayParam});
                    //urlEvent.fire();
                });
            }
        }
    },
    buildCurrWeekData: function(cmp){
        let self = this;
        let currWeekData = cmp.get('v.currWeekHpds');
        let categoryData = [];
        let seriesData = [];
        let totalLocationShare =0;
        let totalWeekFunds = 0;
        //self.log(cmp,'building eChart currWeekData','info',currWeekData);
        if(currWeekData && currWeekData.length > 0) {
            //push date to component
            //cmp.set('v.yesterdayDate',$A.localizationService.formatDate(currWeekData[0].hpdDate, "MM/dd/YYYY"));
            //cmp.set('v.yesterdayDateString',$A.localizationService.formatDate(currWeekData[0].hpdDate, "EEEE"));
            let communityUserSettings = cmp.get('v.communityUserSettings');
            for(let i=0;i<currWeekData.length;i++) {
                let currentRecord = currWeekData[i];
                // If the community user profile setting is checked. user the addesss to display if not use the DBA Name.
                if(communityUserSettings && communityUserSettings.Display_Location_Address__c ) {
                    currentRecord.categoryName  = currentRecord.accountPhysicalStreet;
                    currentRecord.categoryValue = currentRecord.accountPhysicalStreet;
                } else {
                    currentRecord.categoryName  = currentRecord.accountId;
                    currentRecord.categoryValue = currentRecord.accountName;
                }
                //-------------------------------------------------------------------------------
                let resultDebug = '';
                categoryData.push({
                    /* https://accel-entertainment.monday.com/boards/286658657/pulses/294459025
                     name: currentRecord.accountPhysicalStreet,
                     value: currentRecord.accountPhysicalStreet,
                     */
                    name: currentRecord.categoryName,
                    value: currentRecord.categoryValue,
                    sortVal: currentRecord.locShare,
                    //id: currentRecord.accountId
                });
                //self.log(cmp,'pushed into category data:','info',JSON.stringify(categoryData[i]));
                if(currentRecord.locShare >=0){
                    //push data styled as a green bar
                    seriesData.push({
                        //name: currentRecord.accountPhysicalStreet,
                        value: currentRecord.locShare,
                        id: currentRecord.accountId,
                        amtPlayed: currentRecord.amtPlayed,
                        amtWon: currentRecord.amtWon,
                        fundsIn: currentRecord.fundsIn,
                        fundsOut: currentRecord.fundsOut,
                        netRevenue: currentRecord.netRevenue,
                        dbaName: currentRecord.accountName,
                        street: currentRecord.accountPhysicalStreet,

                        itemStyle: {
                            color: '#6fb696'
                        }
                    });
                }else {
                    //push data as red bar

                    seriesData.push({
                        //name: currentRecord.accountPhysicalStreet,
                        value: currentRecord.locShare,
                        id: currentRecord.accountId,
                        amtPlayed: currentRecord.amtPlayed,
                        amtWon: currentRecord.amtWon,
                        fundsIn: currentRecord.fundsIn,
                        fundsOut: currentRecord.fundsOut,
                        netRevenue: currentRecord.netRevenue,
                        dbaName: currentRecord.accountName,
                        street: currentRecord.accountPhysicalStreet,

                        itemStyle: {
                            color: '#FF0000'
                        }
                    });
                }
                resultDebug += 'result=accountId='+currentRecord.accountId + '...shippingstreet='+currentRecord.accountPhysicalStreet;
                resultDebug += '...loc share='+currentRecord.locShare;
                this.log(cmp,resultDebug,'info',currentRecord);
                totalLocationShare +=currentRecord.locShare;
                totalWeekFunds += currentRecord.fundsIn;
            }
            cmp.set('v.currWeekTotalShare', totalLocationShare.toFixed(2));
            cmp.set('v.currWeekTotalShareVal', '$'+this.formatNumberWithCommas(totalLocationShare.toFixed(2)));
            cmp.set('v.currWeekTotalFunds', totalWeekFunds.toFixed(2));
            cmp.set('v.currWeekTotalFundsVal', '$'+this.formatNumberWithCommas(totalWeekFunds.toFixed(2)));
        }

        if(categoryData &&  categoryData.length >1){
            categoryData.sort(function(a,b){return a.sortVal - b.sortVal});
        }
        if(seriesData && seriesData.length >1){
            seriesData.sort(function(a,b){return a.value - b.value});
        }
        return {
            seriesData: seriesData,
            categoryData: categoryData
        };
    },
    scheduleRenderLastWeekChart: function(cmp){
        let self = this;
      window.setTimeout(
          $A.getCallback(function(){
              self.renderLastWeekChart(cmp);
          }), 100
      );
    },
    scheduleRenderCurrWeekChart: function(cmp){
        let self = this;
        window.setTimeout(
            $A.getCallback(function(){
                self.renderCurrWeekChart(cmp);
            }), 100
        );
    },
    renderLastWeekChart: function(cmp){
        let self = this;
        let data = this.buildLastWeekData(cmp);
        let ecdiv = cmp.find("echarts-last-week").getElement();
        let option = {
            legend: {
                show: false
            },
            grid: {
                left: 120,
                bottom: 24,
                right: 24,
                top: 18
            },
            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function (value) {
                        return '$' + value;
                    },
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisLabel: {
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 108
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Last Week Location Share',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                }
            }],
            tooltip: {
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    // text=text+'<b>'+param.name+'</b><br/>';
                    // text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    // text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    // text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    // //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    // text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    // //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    //
                    //

                    /*
                    * RJN Added defensive checks and coerced type to a number .
                    *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                    */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {locShare = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.fundsIn) {fundsIn = parseFloat(param.data.fundsIn);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };
        let mOption = {
            legend: {
                show: false
            },
            grid: {
                left: 100,
                bottom: 28,
                right: 20,
                top:0
            },
            xAxis: {
                type: 'value',
                axisLabel: {
                    formatter: function(value){
                        if(value===0){
                            return '$0';
                        }
                        var shortVal;
                        shortVal = self.formatValue('$',value,0);
                        return shortVal;
                    },
                    fontSize: 10,
                    fontWeight: 'bold'
                }
            },
            yAxis: {
                type: 'category',
                z: 3,
                axisTick: {
                    show: false
                },
                axisLabel: {
                    fontSize: 10,
                    formatter: function (name) {
                        if (name.length > 15) {
                            return name.substring(0, 12) + "...";
                        } else {
                            return name;
                        }
                    },
                    align: 'left',
                    margin: 90
                },
                data: data.categoryData,
            },
            series: [{
                name: 'Last Week Location Share',
                type: 'bar',
                data: data.seriesData,
                label: {
                    show: true,
                    position: 'inside',
                    color: '#000',
                    fontWeight: 'bold',
                    distance: 7,
                    fontSize: 12,
                    formatter: function(params){
                        var val = params.value;
                        if(val!==0){
                            return '$'+ self.formatNumberWithCommas(val);
                        }else{
                            return '';
                        }
                    }
                }
            }],
            tooltip: {
                confine:true,
                formatter: function(param){
                    var text = '';
                    text='<b>'+param.data.dbaName+'</b><br/>';
                    text=text+'<b>'+param.data.street+'</b><br/>';
                    // text=text+'<b>'+param.name+'</b><br/>';
                    // text=text+'Location Share: $'+self.formatNumberWithCommas(param.value.toFixed(2))+'<br/>';
                    // text=text+'Net Revenue: $'+self.formatNumberWithCommas(param.data.netRevenue.toFixed(2))+'<br/>';
                    // text=text+'Funds In: $'+self.formatNumberWithCommas(param.data.fundsIn.toFixed(0))+'<br/>';
                    // //text=text+'Funds Out: $'+self.formatNumberWithCommas(param.data.fundsOut.toFixed(2))+'<br/>';
                    // text=text+'Amount Played: $'+self.formatNumberWithCommas(param.data.amtPlayed.toFixed(2))+'<br/>';
                    // //text=text+'Amount Won: $'+self.formatNumberWithCommas(param.data.amtWon.toFixed(2))+'<br/>';
                    //
                    //

                    /*
                    * RJN Added defensive checks and coerced type to a number .
                    *  ie. toFixed calls were blowing up on net revs of 1387.9199999999998
                    */
                    let locShare = 0;
                    let netRevenue = 0;
                    let fundsIn = 0;
                    let amtPlayed = 0;
                    if(param.value) {locShare = parseFloat(param.value);}
                    if(param.data && param.data.netRevenue){netRevenue = parseFloat(param.data.netRevenue);}
                    if(param.data && param.data.fundsIn) {fundsIn = parseFloat(param.data.fundsIn);}
                    if(param.data && param.data.amtPlayed) {amtPlayed = parseFloat(param.data.amtPlayed);}
                    try {
                        text = text + 'Location Share: $' + self.formatNumberWithCommas(locShare.toFixed(2)) + '<br/>';
                        text = text + 'Net Revenue: $' + self.formatNumberWithCommas(netRevenue.toFixed(2)) + '<br/>';
                        text = text + 'Funds In: $' + self.formatNumberWithCommas(fundsIn.toFixed(0)) + '<br/>';
                        text = text + 'Amount Played: $' + self.formatNumberWithCommas(amtPlayed.toFixed(2)) + '<br/>';
                    } catch (e) {
                        self.log(cmp,'Error in formatting tooltips','error',e);
                    }
                    return text;
                }
            }
        };

        if(data.seriesData.length > 0) {
            this.lastWeekChart = echarts.init(ecdiv, 'light');
            if (window.matchMedia("(max-width: 767px)").matches) {
                this.lastWeekChart.setOption(mOption);
            } else {
                this.lastWeekChart.setOption(option);
                this.lastWeekChart.on('click', function (params){
                    var data = params.data;
                    var id=data.id;
                    //var yesterdayParam ='&yesterday=true';
                    var urlEvent = $A.get("e.force:navigateToURL");
                   // urlEvent.setParams({"url": '/machine-performance?accountId=' + id + yesterdayParam});
                    //urlEvent.fire();
                });
            }
        }
    },
    buildLastWeekData: function(cmp){
        let self = this;
        let lastWeekData = cmp.get('v.lastWeekHpds');
        let categoryData = [];
        let seriesData = [];
        let totalLocationShare =0;
        let totalWeekFunds = 0;
        //self.log(cmp,'building eChart lastWeekData','info',lastWeekData);
        if(lastWeekData && lastWeekData.length > 0) {
            let communityUserSettings = cmp.get('v.communityUserSettings');
            for(let i=0;i<lastWeekData.length;i++) {
                let currentRecord = lastWeekData[i];
                // If the community user profile setting is checked. user the addesss to display if not use the DBA Name.
                if(communityUserSettings && communityUserSettings.Display_Location_Address__c ) {
                    currentRecord.categoryName  = currentRecord.accountPhysicalStreet;
                    currentRecord.categoryValue = currentRecord.accountPhysicalStreet;
                } else {
                    currentRecord.categoryName  = currentRecord.accountId;
                    currentRecord.categoryValue = currentRecord.accountName;
                }
                //-------------------------------------------------------------------------------
                let resultDebug = '';
                categoryData.push({
                    /* https://accel-entertainment.monday.com/boards/286658657/pulses/294459025
                     name: currentRecord.accountPhysicalStreet,
                     value: currentRecord.accountPhysicalStreet,
                     */
                    name: currentRecord.categoryName,
                    value: currentRecord.categoryValue,
                    sortVal: currentRecord.locShare,
                    //id: currentRecord.accountId
                });
                //self.log(cmp,'pushed into category data:','info',JSON.stringify(categoryData[i]));
                if(currentRecord.locShare >=0){
                    //push data styled as a green bar
                    seriesData.push({
                        //name: currentRecord.accountPhysicalStreet,
                        value: currentRecord.locShare,
                        id: currentRecord.accountId,
                        amtPlayed: currentRecord.amtPlayed,
                        amtWon: currentRecord.amtWon,
                        fundsIn: currentRecord.fundsIn,
                        fundsOut: currentRecord.fundsOut,
                        netRevenue: currentRecord.netRevenue,
                        dbaName: currentRecord.accountName,
                        street: currentRecord.accountPhysicalStreet,

                        itemStyle: {
                            color: '#6fb696'
                        }
                    });
                }else {
                    //push data as red bar

                    seriesData.push({
                        //name: currentRecord.accountPhysicalStreet,
                        value: currentRecord.locShare,
                        id: currentRecord.accountId,
                        amtPlayed: currentRecord.amtPlayed,
                        amtWon: currentRecord.amtWon,
                        fundsIn: currentRecord.fundsIn,
                        fundsOut: currentRecord.fundsOut,
                        netRevenue: currentRecord.netRevenue,
                        dbaName: currentRecord.accountName,
                        street: currentRecord.accountPhysicalStreet,

                        itemStyle: {
                            color: '#FF0000'
                        }
                    });
                }
                resultDebug += 'result=accountId='+currentRecord.accountId + '...shippingstreet='+currentRecord.accountPhysicalStreet;
                resultDebug += '...loc share='+currentRecord.locShare;
                this.log(cmp,resultDebug,'info',currentRecord);
                totalLocationShare +=currentRecord.locShare;
                totalWeekFunds += currentRecord.fundsIn;
            }
            cmp.set('v.lastWeekTotalShare', totalLocationShare.toFixed(2));
            cmp.set('v.lastWeekTotalShareVal', '$'+this.formatNumberWithCommas(totalLocationShare.toFixed(2)));
            cmp.set('v.lastWeekTotalFunds', totalWeekFunds.toFixed(2));
            cmp.set('v.lastWeekTotalFundsVal', '$'+this.formatNumberWithCommas(totalWeekFunds.toFixed(2)));
        }

        if(categoryData &&  categoryData.length >1){
            categoryData.sort(function(a,b){return a.sortVal - b.sortVal});
        }
        if(seriesData && seriesData.length >1){
            seriesData.sort(function(a,b){return a.value - b.value});
        }
        return {
            seriesData: seriesData,
            categoryData: categoryData
        };
    },
    /**
     *
     * @param cmp
     * @param response
     */
    processYesterdayAverageTotals: function(cmp, response){
        let dto = response; //aggregated response object
        let arrWeekdayAverageData = [];
        let fundsInTotal = 0;
        let numDates;
        //-- deprecated this.collectionUtils.getMapValue('ALL_LOC_WEEKDAY_AVERAGE', dto.values, function (value) {arrWeekdayAverageData  = value;});
        arrWeekdayAverageData = this.collectionUtils.getData('ALL_LOC_WEEKDAY_AVERAGE',dto.values);
        cmp.set('v.fundsInAverages', arrWeekdayAverageData);
        let fundsInArray = arrWeekdayAverageData;
        if(fundsInArray && fundsInArray.length > 0){
            //set the number of aggregate dates to divide by later, typically 14 but new single location owners could be less
            numDates=fundsInArray.length;
            cmp.set('v.weekday', fundsInArray[0].weekday);
            for(let i=0; i<fundsInArray.length; i++){
                let currentRecord = fundsInArray[i];
                let resultDebug = '';
                fundsInTotal+=currentRecord.fundsIn;
                resultDebug += 'Averaging...funds in='+currentRecord.fundsIn;
                this.log(cmp,resultDebug,'info',currentRecord);
            }
        }
        if(numDates && numDates > 0) {
            let totalFundsInAverage = fundsInTotal / numDates;
            cmp.set('v.averageFundsIn', this.formatNumberWithCommas(totalFundsInAverage.toFixed(0)));

            //sort the array in order of funds in value { best, 2nd best, third best... etc}
            let sorted = fundsInArray.slice().sort(function (a, b) {
                return b.fundsIn - a.fundsIn
            });
            //using the value at the original index, find that value in the new sorted array, the index in the sorted array is its rank
            let ranks = fundsInArray.slice().map(function (v) {
                return sorted.indexOf(v) + 1
            });
            //yesterday is always going to be [0] so ranks[0] gives us the ranking of yesterday in comparison to the other days
            let rankString = ranks[0];
            switch (rankString) {
                case 1:
                    rankString = rankString + 'st';
                    break;
                case 2:
                    rankString = rankString + 'nd';
                    break;
                case 3:
                    rankString = rankString + 'rd';
                    break;
                default:
                    rankString = rankString + 'th';
            }
            cmp.set('v.weekrank', rankString);
        }
    },
    processBtnClick: function(cmp, event){
        let target;
        let btnClicked;
        if(event){
            target=event.getSource();
            btnClicked = target.get('v.name');
        }
        let btnIds = ["LocationShare", "FundsIn"];
        window.setTimeout(function () {
            for(let i = 0; i < btnIds.length; i++) {
                let btnId = btnIds[i];
                let btnCmp = cmp.find(btnId);
                if (btnId === btnClicked) $A.util.addClass(btnCmp, "accel-btn-is-selected");
                else $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            }
        }, 0);

        if(btnClicked !=='LocationShare'){
            this.renderYesterdayFundsInChart(cmp);

        }else {
            this.renderYesterdayLocationShareChart(cmp);
        }

    },
    /**
     *
     * @param cmp
     * @param msg    if msg is an error and contains generic. will toast a generic error msg.
     * @param level
     * @param jsonObj
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
                var cmpName = '--- Accel_YesterdayShare --- ';
                var cLogger = cmp.find('loggingUtils');
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
    handleErrors : function(cmp,error) {
        this.log(cmp, 'errors in init server side retrieval calls', 'error', error);
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
     * RJN Added try catch error handling 6/10/2019
     * @param x
     * @returns {string}
     */
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
    windowResizing: function (cmp, evt, helper) {
        var self = this;
        if(self.yesterdayShareChart) {
            self.yesterdayShareChart.resize();
        }
        if(self.yesterdayFundsInChart){
            self.yesterdayFundsInChart.resize();
        }
        if(self.currWeekChart){
            self.currWeekChart.resize();
        }
        if(self.lastWeekChart){
            self.lastWeekChart.resize();
        }
    },
    processTabChange: function(cmp, evt){
        if(evt.target.id === 'tab-scoped-1__item'){
            $A.util.addClass( cmp.find("cfw"), "slds-active");
            $A.util.removeClass( cmp.find("lfw"), "slds-active");

            $A.util.removeClass( cmp.find("cfwdiv"), "slds-hide");
            $A.util.addClass( cmp.find("cfwdiv"), "slds-show");

            $A.util.removeClass( cmp.find("lfwdiv"), "slds-show");
            $A.util.addClass( cmp.find("lfwdiv"), "slds-hide");
            cmp.set("v.ariaCurrSelected", true);
            cmp.set("v.ariaLastSelected", false);

            this.scheduleRenderCurrWeekChart(cmp);
        }else{
            $A.util.addClass( cmp.find("lfw"), "slds-active");
            $A.util.removeClass( cmp.find("cfw"), "slds-active");

            $A.util.removeClass( cmp.find("lfwdiv"), "slds-hide");
            $A.util.addClass( cmp.find("lfwdiv"), "slds-show");

            $A.util.removeClass( cmp.find("cfwdiv"), "slds-show");
            $A.util.addClass( cmp.find("cfwdiv"), "slds-hide");
            cmp.set("v.ariaCurrSelected", false);
            cmp.set("v.ariaLastSelected", true);
            this.scheduleRenderLastWeekChart(cmp);

        }
    },

    //  8-20-2019 @see https://accel-entertainment.monday.com/boards/286658657/pulses/294454017
    /**
     * Determines if value is an int (or a string representation of an int)
     * @param value
     * @returns {boolean|*}
     * @TODO move to some utils component.
     */
    isInt: function isInt(value) {
        return !isNaN(value) && (function(x) { return (x | 0) === x; })(parseFloat(value))
    }
});