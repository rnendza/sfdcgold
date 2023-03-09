/**
 * Replaced alerts with call to error logging which will pop toast as well.
 * https://accel-entertainment.monday.com/boards/286658657/
 */
({
    collectionUtils:null,
    loggingUtils:null,
    formatUtils: null,
    map: null,
    //https://accel-entertainment.monday.com/boards/286658657/
    uiMessagingUtils:null,
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:20000, //20 seconds
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
                    cmp.set('v.displayMap',true);
                    cmp.set('v.displayAreaChart',true);
                    // cmp.set('v.allHidden',false);
                    this.log(cmp,'sObject Community_User_Setting__c not found for logged in user!','error');
                } else {
                    cmp.set('v.communityUserSettingsNotFound',false);
                    cmp.set('v.displayMap',communityUserSettings.Display_Map__c);
                    cmp.set('v.displayAreaChart',communityUserSettings.Display_Area_Chart__c);
                    // cmp.set('v.allHidden', !communityUserSettings.Display_Area_Chart__c && !communityUserSettings.Display_Map__c
                    //     && !communityUserSettings.Display_Ranking_Table__c && !communityUserSettings.Display_Area_Metrics__c);
                    //@TODO call method that sets flags to prevent chained queries and stuff that is hidden.
                    this.log(cmp,'communityUserSettings','info',JSON.stringify(communityUserSettings));
                }
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    /* retrieveLocTypes: function(cmp){
        cmp.lax.enqueue('c.retrieveLocTypes')
            .then(response=>{
                cmp.set('v.locTypes',response);
            })
            .catch(errors=>{
                alert('Retrieve LocTypes errors: '+errors);
            })
    }, */
    retrieveCity: function(cmp, city){
        const params = {city: city};
        cmp.lax.enqueue('c.getCity', params)
            .then(response => {
                this.processCityCenter(cmp, response, city);
                this.retrieveRadiusHpds(cmp, 'city');
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    processCityCenter: function(cmp, response, city){
        let res = response;
        if(response.length > 0){
            cmp.set('v.cityCenter', response);
            cmp.set('v.cityname', response[0].Name);
        }
    },
    retrieveAccounts: function(cmp) {
        cmp.lax.enqueue('c.retrieveAccounts') //getUserAccounts
            .then(response => {
                this.processUserAccounts(cmp, response);
                return this.retrieveRadiusHpds(cmp, 'Radius');
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    processUserAccounts: function (cmp, response) {
        let dto = response;
        let accounts =  this.collectionUtils.getData('ACCOUNT_LIST',dto.values);
        //--DEPRECATED this.collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
        cmp.set('v.userAccounts', accounts);
        this.setUserAccountOptions(cmp); //---- translate user account array to options array for combo box (location filter)

        let accountId = this.getUrlParam('accountId');
        if (accountId && accountId !== '') {
            cmp.set('v.selectedAccountId', accountId);
            //need latitude/longitude for param
        } else {
            accountId = accounts[0].Id;
            let dist = cmp.get('v.distance');
            cmp.set('v.selectedAccountId', accounts[0].Id);
            cmp.set('v.cityname', 'Selected '+dist+' mile area');
            cmp.set('v.selectedLat', accounts[0].ShippingLatitude);
            cmp.set('v.selectedLong', accounts[0].ShippingLongitude);
        }
    },
    retrieveRadiusHpds: function(cmp, type){
        let id = cmp.get('v.selectedAccountId');
        let dist = cmp.get('v.distance');
        let accType = cmp.get('v.accountType');
        let date = cmp.get('v.oldestDate');
        let city = cmp.get('v.cityname');
        cmp.set('v.mapSpinner', true);
        if(type==='Radius') {
            const params = {id: id, accType: accType, dist: dist, oldest: date};
            cmp.lax.enqueue('c.getRadiusHpds', params)
                .then(response => {
                    console.info('--->res',response);
                    this.processRadiusHpds(cmp, response, 'RADIUS_HPDS');
                    this.initMap(cmp, 'Radius');
                    cmp.set('v.mapSpinner', false);
                    return this.retrieveRadiusYoYData(cmp);
                })
                .catch(errors => {
                    cmp.set('v.mapSpinner', false);
                    this.log(cmp,'generic','error',JSON.stringify(errors));
                });
        }else if(type === 'state') {
            const params = {accType: accType, oldest: date};
            cmp.lax.enqueue('c.getAllHpds', params)
                .then(response => {
                    this.processRadiusHpds(cmp, response, 'ALL_HPDS');
                    this.initMap(cmp, 'State');
                    cmp.set('v.mapSpinner', false);
                    return this.retrieveAllYoYData(cmp);
                })
                .catch(errors => {
                    cmp.set('v.mapSpinner', false);
                    this.log(cmp,'generic','error',JSON.stringify(errors));
                });


        }else {
            const params = {cityName: city, oldest: date};
            cmp.lax.enqueue('c.getCityHpds', params)
                .then(response => {
                    this.processRadiusHpds(cmp, response, 'CITY_HPDS');
                    this.initMap(cmp, 'city');
                    cmp.set('v.mapSpinner', false);
                    return this.retrieveCityMetrics(cmp);
                })
                .catch(errors => {
                    cmp.set('v.mapSpinner', false);
                    this.log(cmp,'generic','error',JSON.stringify(errors));
                });
        }
    },
    retrieveAllYoYData: function(cmp){
        let accType = cmp.get('v.accountType');
        let date = cmp.get('v.oldestDate');
        const params = {accType: accType, oldest: date};
        cmp.lax.enqueue('c.getAllYoYHpds', params)
            .then(response => {
                this.processAllYoYData(cmp,response);
            })
            .catch(errors =>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            })
    },
    processAllYoYData: function(cmp, response){
        let dto = response;
        let radiusHpds =  this.collectionUtils.getData('ALL_YOY_HPDS',dto.values);
        //--- deprecated this.collectionUtils.getMapValue('ALL_YOY_HPDS', dto.values, function(value){radiusHpds = value;});
        cmp.set('v.cityYoYHpds', radiusHpds);
        cmp.set('v.cityname', 'Illinois');
        this.renderPieChart(cmp, 'State');
        this.buildRadiusMetrics(cmp, 'All');
    },
    retrieveRadiusYoYData: function(cmp){
        let id = cmp.get('v.selectedAccountId');
        let dist = cmp.get('v.distance');
        let accType = cmp.get('v.accountType');
        let date = cmp.get('v.oldestDate');
        const params = {id: id, accType: accType, dist: dist, oldest: date};
        cmp.lax.enqueue('c.getRadiusYoYHpds', params)
            .then(response => {
                this.processRadiusYoYData(cmp,response);
            })
            .catch(errors =>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            })
    },
    processRadiusYoYData: function(cmp, response){
        let dto = response;
        let radiusHpds =  this.collectionUtils.getData('RADIUS_YOY_HPDS',dto.values);
        let dist = cmp.get('v.distance');
        let ty = cmp.get('v.accountType');
        //---DEPRECATED this.collectionUtils.getMapValue('RADIUS_YOY_HPDS', dto.values, function(value){radiusHpds = value;});

        cmp.set('v.cityYoYHpds', radiusHpds);
        cmp.set('v.cityname', 'Selected '+dist+' mile area');
        this.renderPieChart(cmp, 'Radius');
        if(ty==='All'){
            this.buildRadiusMetrics(cmp, 'All');
        }else{
            this.buildRadiusMetrics(cmp, ty);
        }
    },
    buildRadiusMetrics: function(cmp, type) {
        let data = cmp.get('v.radiusHpds');
        let yoyData = cmp.get('v.cityYoYHpds');
        let title = type;
        if (title === 'All') {
            cmp.set('v.cityType', 'All Location Types');
            cmp.set('v.cityNumberLocations', data.length);
            let totalHpd = 0;
            let totalFunds = 0;
            let yoyTotalHpd=0;
            let totHpdYoYValid = 0;
            let yoyValidLength = 0;
            let dataValidLength = 0;
            for (let i = 0; i < data.length; i++) {
                totalHpd = totalHpd + (data[i].hpd / data[i].distinctDateCount);
                totalFunds = totalFunds + (data[i].fundsIn / data[i].distinctDateCount);
            }
            let dStart = new Date(cmp.get('v.oldestDate'));
            let lStart = new Date(dStart.getFullYear(),dStart.getMonth()+3, 15);
            for(let i=0; i<data.length; i++){
                if(new Date(data[i].hpdDate) <= lStart){
                    dataValidLength = dataValidLength + 1;
                    totHpdYoYValid = totHpdYoYValid +(data[i].hpd / data[i].distinctDateCount);
                }
            }
            for(let i=0; i < yoyData.length; i++){
                if(new Date(yoyData[i].hpdDate) <= lStart) {
                    yoyValidLength = yoyValidLength +1;
                    yoyTotalHpd = yoyTotalHpd + (yoyData[i].hpd / yoyData[i].distinctDateCount);
                }
            }
            cmp.set('v.cityAvgHpd', '$' + this.formatNumberWithCommas((totalHpd / data.length).toFixed(0)));
            cmp.set('v.cityAvgFundsIn', '$' + this.formatNumberWithCommas((totalFunds / data.length).toFixed(0)));
            cmp.set('v.yoyHpdValue', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2));
            cmp.set('v.yoyHpdGrowth', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2)+'%');
        }else{
            let count =0;
            let totalHpd=0;
            let totalFunds=0;
            let yoyTotalHpd=0;
            let totHpdYoYValid = 0;
            let yoyValidLength = 0;
            let dataValidLength = 0;
            for(let i=0; i<data.length; i++){
                if(data[i].hpdName === title){
                    count=count+1;
                    totalHpd = totalHpd + (data[i].hpd / data[i].distinctDateCount);
                    totalFunds = totalFunds + (data[i].fundsIn / data[i].distinctDateCount);
                }
            }
            let dStart = new Date(cmp.get('v.oldestDate'));
            let lStart = new Date(dStart.getFullYear(),dStart.getMonth()+3, 15);
            for(let i=0; i<data.length; i++){
                if(new Date(data[i].hpdDate) <= lStart && data[i].hpdName === title){
                    dataValidLength = dataValidLength + 1;
                    totHpdYoYValid = totHpdYoYValid +(data[i].hpd / data[i].distinctDateCount);
                }
            }
            for(let i=0; i < yoyData.length; i++){
                if(new Date(yoyData[i].hpdDate) <= lStart && yoyData[i].hpdName === title){
                    yoyValidLength = yoyValidLength +1;
                    yoyTotalHpd = yoyTotalHpd + (yoyData[i].hpd / yoyData[i].distinctDateCount);
                }
            }
            cmp.set('v.cityType', title+' Locations');
            cmp.set('v.cityNumberLocations', count);
            cmp.set('v.cityAvgHpd', '$' + this.formatNumberWithCommas((totalHpd / count).toFixed(0)));
            cmp.set('v.cityAvgFundsIn', '$' + this.formatNumberWithCommas((totalFunds / count).toFixed(0)));
            cmp.set('v.yoyHpdValue', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2));
            cmp.set('v.yoyHpdGrowth', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2)+'%');
        }
    },
    processRadiusHpds: function(cmp, response, arr){
        let dto = response;
        let hpds = this.collectionUtils.getData(arr,dto.values); //@TODO arr as map key????
        //this.collectionUtils.getMapValue(arr, dto.values, function (value) {hpds = value;});
        cmp.set('v.radiusHpds', hpds);
        this.buildRadiusDataTable(cmp);
    },
    buildRadiusDataTable: function(cmp){
      let data = cmp.get('v.radiusHpds');
      let rankings = [];

      for(let i=0; i<data.length; i++){
          let currRecord = data[i];
          rankings.push({
              rank: 0,
              hpd: (currRecord.hpd/currRecord.distinctDateCount).toFixed(0),
              fundsIn: (currRecord.fundsIn/currRecord.distinctDateCount).toFixed(0),
              name: currRecord.accountName,
              street: currRecord.accountPhysicalStreet,
              city: currRecord.accountPhysicalCity,
              zip: currRecord.accountZip,
              latitude: currRecord.accountLat,
              longitude: currRecord.accountLong,
          });
      }
      //sort the ranking array
        rankings.sort(function(a,b) { return b.hpd - a.hpd;});
        for(let i=1; i<=rankings.length; i++){
            rankings[i-1].rank = i;
            if(i===1||(i) <= .2*rankings.length){
                rankings[i-1].color = 'top20';
            }else if(i>=rankings.length - .2*rankings.length){
                rankings[i-1].color = 'bottom20';
            }else{
                rankings[i-1].color = 'normalColor';
            }
        }
        for(let i=0; i<rankings.length; i++){
            rankings[i].hpd = '$'+rankings[i].hpd;
        }
        cmp.set('v.rankings', rankings);
    },
    initMap: function(cmp, type){
        if(!cmp.get('v.displayMap')) {
            return;
        }
        let lat;
        let long;
        let rZoom;
        let rDist = cmp.get('v.distance');
        if(type!=='city') {
            lat = cmp.get('v.selectedLat');
            long = cmp.get('v.selectedLong');
            switch (rDist){
                case "1":
                    rZoom = 14;
                    break;
                case "2":
                    rZoom = 13;
                    break;
                case "5":
                    rZoom = 12;
                    break;
                case "10":
                    rZoom = 11;
                    break;
                case "25":
                    rZoom = 10;
                    break;
                case "50":
                    rZoom = 9;
                    break;
            }
        }else if (type === 'State'){
            rZoom = 8;
            lat = 40.35606;
            long = -88.9686;
        }else{
            let cityCenter = cmp.get('v.cityCenter');
            //lat long in 0 index of array
            lat = cityCenter[0].CityCenter__Latitude__s;
            long = cityCenter[0].CityCenter__Longitude__s;
            rZoom = 11;
        }

        let mapDiv = cmp.find("map").getElement();
        //add logic for only initializing new map if already doesnt exist
        if(map != undefined){
            map.remove();
        }
        map = new L.map(mapDiv);
        L.tileLayer('https://api.mapbox.com/styles/v1/{id}/tiles/{z}/{x}/{y}?access_token=pk.eyJ1IjoiYWNjZWxlbnQiLCJhIjoiY2s2am54emM0MGRzbTNsbnVyYmVqaXpncCJ9.YsdKgiAYZ-drheOX_CGuxQ', {
            attribution: 'Map data &copy; <a href="https://www.openstreetmap.org/">OpenStreetMap</a> contributors, <a href="https://creativecommons.org/licenses/by-sa/2.0/">CC-BY-SA</a>, Imagery © <a href="https://www.mapbox.com/">Mapbox</a>',
            maxZoom: 18,
            tileSize: 512,
            zoomOffset: -1,
            id: 'mapbox/streets-v11'
        }).addTo(map);
        map.setView([lat,long], rZoom);
        map.scrollWheelZoom.disable();

        let accounts = cmp.get('v.rankings');
        let percent = .2 * accounts.length;
        for(let i=0; i<accounts.length; i++){
            let numMarker;
            let zIndex;
            if((accounts.length > 0 && i === 0) || (i+1) <= percent){
                numMarker = L.AwesomeMarkers.icon({
                    icon: '',
                    markerColor: 'green',
                    prefix: 'fa',
                    html: (i+1)
                });
               let markerVar = L.marker([accounts[i].latitude, accounts[i].longitude], {icon: numMarker, zIndexOffset: 1000-i});
               markerVar.bindTooltip("Rank: "+accounts[i].rank+"<br>HPD: "+accounts[i].hpd+"<br>"+accounts[i].name, {direction: 'top', offset: [0,-30]});
               markerVar.addTo(map);
            }else if(i+1 >= accounts.length - percent){
                numMarker = L.AwesomeMarkers.icon({
                    icon: '',
                    markerColor: 'red',
                    prefix: 'fa',
                    html: (i+1)
                });
                let markerVar = L.marker([accounts[i].latitude, accounts[i].longitude], {icon: numMarker}).addTo(map);
                markerVar.bindTooltip("Rank: "+accounts[i].rank+"<br>HPD: "+accounts[i].hpd+"<br>"+accounts[i].name, {direction: 'top', offset: [0,-30]});
                markerVar.addTo(map);
            }else {
                numMarker = L.AwesomeMarkers.icon({
                    icon: '',
                    markerColor: 'blue',
                    prefix: 'fa',
                    html: (i + 1)
                });
                let markerVar = L.marker([accounts[i].latitude, accounts[i].longitude], {icon: numMarker}).addTo(map);
                markerVar.bindTooltip("Rank: "+accounts[i].rank+"<br>HPD: "+accounts[i].hpd+"<br>"+accounts[i].name, {direction: 'top', offset: [0,-30]});
                markerVar.addTo(map);
            }
        }
    },
    retrieveCityMetrics: function(cmp){
        let city = cmp.get('v.cityname');
        let date = cmp.get('v.oldestDate');
        const params = {cityName: city, oldest: date};
        cmp.lax.enqueue('c.getCityHpds', params)
            .then(response => {
                this.processCityMetrics(cmp,response);
                return this.retrieveCityYoYData(cmp);
            })
            .catch(errors =>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            })
    },
    retrieveCityYoYData: function(cmp){
        let city = cmp.get('v.cityname');
        let date = cmp.get('v.oldestDate');
        const params = {cityName: city, oldest: date};
        cmp.lax.enqueue('c.getCityYoYHpds', params)
            .then(response => {
                this.processCityYoYData(cmp,response);
            })
            .catch(errors =>{
                this.log(cmp,'generic','error',JSON.stringify(errors));
            })
    },
    processCityMetrics: function(cmp, response){
        let dto = response;
        let cityHpds = this.collectionUtils.getData('CITY_HPDS',dto.values);
        //---deprecated this.collectionUtils.getMapValue('CITY_HPDS', dto.values, function(value){cityHpds = value;});
        cmp.set('v.cityHpds', cityHpds);
    },
    processCityYoYData: function(cmp, response){
        let dto = response;
        let cityHpds = this.collectionUtils.getData('CITY_YOY_HPDS',dto.values);
        //--DEPRECATED this.collectionUtils.getMapValue('CITY_YOY_HPDS', dto.values, function(value){cityHpds = value;});
        cmp.set('v.cityYoYHpds', cityHpds);
        this.renderPieChart(cmp, 'city');
        this.buildCityMetrics(cmp, 'All');
    },
    buildCityMetrics: function(cmp, type) {
        let data = cmp.get('v.cityHpds');
        let yoyData = cmp.get('v.cityYoYHpds');
        let title = type;
        if (title === 'All') {
            cmp.set('v.cityType', 'All Location Types');
            cmp.set('v.cityNumberLocations', data.length);
            let totalHpd = 0;
            let totalFunds = 0;
            let yoyTotalHpd=0;
            let totHpdYoYValid = 0;
            let yoyValidLength = 0;
            let dataValidLength = 0;
            for (let i = 0; i < data.length; i++) {
                totalHpd = totalHpd + (data[i].hpd / data[i].distinctDateCount);
                totalFunds = totalFunds + (data[i].fundsIn / data[i].distinctDateCount);
            }
            let dStart = new Date(cmp.get('v.oldestDate'));
            let lStart = new Date(dStart.getFullYear(),dStart.getMonth()+3, 15);
            for(let i=0; i<data.length; i++){
                if(new Date(data[i].hpdDate) <= lStart){
                    dataValidLength = dataValidLength + 1;
                    totHpdYoYValid = totHpdYoYValid +(data[i].hpd / data[i].distinctDateCount);
                }
            }
            for(let i=0; i < yoyData.length; i++){
                if(new Date(yoyData[i].hpdDate) <= lStart) {
                    yoyValidLength = yoyValidLength +1;
                    yoyTotalHpd = yoyTotalHpd + (yoyData[i].hpd / yoyData[i].distinctDateCount);
                }
            }
            cmp.set('v.cityAvgHpd', '$' + this.formatNumberWithCommas((totalHpd / data.length).toFixed(0)));
            cmp.set('v.cityAvgFundsIn', '$' + this.formatNumberWithCommas((totalFunds / data.length).toFixed(0)));
            cmp.set('v.yoyHpdValue', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2));
            cmp.set('v.yoyHpdGrowth', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2)+'%');
        }else{
            let count =0;
            let totalHpd=0;
            let totalFunds=0;
            let yoyTotalHpd=0;
            let totHpdYoYValid = 0;
            let yoyValidLength = 0;
            let dataValidLength = 0;
            for(let i=0; i<data.length; i++){
                if(data[i].hpdName === title){
                    count=count+1;
                    totalHpd = totalHpd + (data[i].hpd / data[i].distinctDateCount);
                    totalFunds = totalFunds + (data[i].fundsIn / data[i].distinctDateCount);
                }
            }
            let dStart = new Date(cmp.get('v.oldestDate'));
            let lStart = new Date(dStart.getFullYear(),dStart.getMonth()+3, 15);
            for(let i=0; i<data.length; i++){
                if(new Date(data[i].hpdDate) <= lStart && data[i].hpdName === title){
                    dataValidLength = dataValidLength + 1;
                    totHpdYoYValid = totHpdYoYValid +(data[i].hpd / data[i].distinctDateCount);
                }
            }
            for(let i=0; i < yoyData.length; i++){
                if(new Date(yoyData[i].hpdDate) <= lStart && yoyData[i].hpdName === title){
                    yoyValidLength = yoyValidLength +1;
                    yoyTotalHpd = yoyTotalHpd + (yoyData[i].hpd / yoyData[i].distinctDateCount);
                }
            }
            cmp.set('v.cityType', title+' Locations');
            cmp.set('v.cityNumberLocations', count);
            cmp.set('v.cityAvgHpd', '$' + this.formatNumberWithCommas((totalHpd / count).toFixed(0)));
            cmp.set('v.cityAvgFundsIn', '$' + this.formatNumberWithCommas((totalFunds / count).toFixed(0)));
            cmp.set('v.yoyHpdValue', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2));
            cmp.set('v.yoyHpdGrowth', ((((yoyTotalHpd /  yoyValidLength) - (totalHpd / dataValidLength ))/(yoyTotalHpd /  yoyValidLength))*100).toFixed(2)+'%');
        }
    }
    ,
    renderPieChart: function(cmp, type){
      let self = this;
      let data = self.buildPieData(cmp, type);
      let option = {
          title: {
              show: true,
              text: 'Gaming Locations and Types',
              top: 0,
              left: '45%',
              textStyle: {
                  fontSize: 13
              }
          },
          toolbox : {
              show : true,
              feature : {
                  mark : {show: false},
                  dataView : {show: false, readOnly: false},
                  restore : {show: true},
                  saveAsImage : {show: false}
              },
              showTitle: false,
              right: 45,
              top: 18
          },
          series: [{
              type: 'pie',
              minAngle: 5,
              labelLine: {
                  length: 5,
                  length2: 5
              },
              radius: '75%',
              center: ['65%', '57%'],
              data: data.seriesData
          },{
              type: 'pie',
              minAngle: 5,
              label: {
                  position: 'inside',
                  fontSize: 10,
                  color: '#FFFFFF',
                  formatter: function (params) {
                      return params.value;
                      /* if(params.percent < 3){
                          return '';
                      }else if(params.percent < 6) {
                          return params.percent.toFixed(0)+'%';
                      }else {
                          return params.percent.toFixed(1) + '%';
                      } */
                  },

              },
              radius: '75%',
              center: ['65%', '57%'],
              data: data.seriesData,
          }]
      };
      if(cmp.get('v.displayAreaChart')) {
          let pieDiv = cmp.find("city-piechart").getElement();
          this.pieChart = echarts.init(pieDiv);
          if (window.matchMedia("(max-width: 896px)").matches) {
              //mobile
              this.pieChart.setOption(option);
          } else {
              this.pieChart.setOption(option);
          }
          this.pieChart.on('restore', function (params) {
              //insert function to rebuild line graph trend chart
              if (type === 'City') {
                  self.buildCityMetrics(cmp, 'All');
              } else {
                  self.buildRadiusMetrics(cmp, 'All');
              }
          });
          this.pieChart.on('click', function (params) {
              let data = params.data;
              if (type === 'city') {
                  self.buildCityMetrics(cmp, data.name);
              } else {
                  self.buildRadiusMetrics(cmp, data.name);
              }
          });
      }
    },
    buildPieData: function(cmp, type) {
        let hpdArray;
        if(type==='city'){
            hpdArray= cmp.get('v.cityHpds');
        }else{
           hpdArray= cmp.get('v.radiusHpds');
        }
        let seriesData = [];
        let typeArray = [];
        typeArray = [... new Set(hpdArray.map(x => x.hpdName))];
        for(let i=0; i<typeArray.length; i++){
            if(typeArray[i]){
                let val = typeArray[i];
                let count=0;
               for(let j=0; j<hpdArray.length; j++){
                   if(hpdArray[j].hpdName === val){
                       count=count+1;
                   }
               }
               seriesData.push({
                   name: val,
                   value: count
               });
            }
        }
        if(seriesData){
            seriesData.sort(function(a,b) { return b.value - a.value;});
        }
        return {
            seriesData: seriesData
        }
    },
    initColumns: function (cmp) {
        cmp.set('v.columns', [
            {   label: 'Rank',
                fieldName: 'rank',
                initialWidth: 80,
                type: 'number',
                sortable: false,
                cellAttributes: {alignment: 'center', class:{fieldName: 'color'}}
            },
            {   label: 'HPD',
                fieldName: 'hpd',
                initialWidth: 80,
                type: 'text',
                sortable: false,
                //cellAttributes: {class:{fieldName: 'color'}
                //}
            },
            {   label: 'Location',
                fieldName: 'name',
                type: 'text',
                sortable: false,
               // cellAttributes: {class:{fieldName: 'color'}
               // }
            }
        ]);
    },
    setCoords: function(cmp){
        let acc = cmp.get("v.userAccounts");
        let id = cmp.get("v.selectedAccountId");
        let dist = cmp.get('v.distance');
        for(let i=0; i<acc.length; i++){
            if(id===acc[i].Id){
                cmp.set("v.selectedLat", acc[i].ShippingLatitude);
                cmp.set("v.selectedLong", acc[i].ShippingLongitude);
                cmp.set("v.cityname", 'Selected '+dist+' mile area');
            }
        }
    },
    processBtnClick: function(cmp, event){
        let target;
        let btnClicked;
        if(event){
            target=event.getSource();
            btnClicked = target.get('v.name');
        }
        let btnIds = ["MyLocations", "Search"];
        window.setTimeout(function () {
            for(let i = 0; i < btnIds.length; i++) {
                let btnId = btnIds[i];
                let btnCmp = cmp.find(btnId);
                if (btnId === btnClicked) $A.util.addClass(btnCmp, "accel-btn-is-selected");
                else $A.util.removeClass(btnCmp, "accel-btn-is-selected");
            }
        }, 0);

        if(btnClicked ==='MyLocations'){
            if(cmp.get('v.filter')!=='My Locations'){
                cmp.set('v.filter', 'MyLocations');
                cmp.find('radius').set('v.value', "2");
                cmp.set('v.distance',"2");
                cmp.set('v.accountType', "All");
                this.setCoords(cmp);
                this.retrieveRadiusHpds(cmp, 'Radius');
            }

        }else if(btnClicked === 'Search') {
            cmp.set('v.filter', 'Search');

        }else if(btnClicked === 'AllLocations'){
            cmp.set('v.filter', 'AllLocations');
            this.retrieveRadiusHpds(cmp, 'state');
        }

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
    setUserAccountOptions: function (cmp) {
        let accounts = cmp.get('v.userAccounts');
        console.log(accounts);
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
    formatNumberWithCommas: function(x){
        var parts = x.toString().split(".");
        parts[0] = parts[0].replace(/\B(?=(\d{3})+(?!\d))/g, ",");
        return parts.join(".");
    },
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    windowResizing: function (cmp, evt, helper) {
        let self = this;
        if(self.pieChart) {
            self.pieChart.resize();
        }
    },
    /**
     * Simply a wrapper around The Utils Component / log method.
     * https://accel-entertainment.monday.com/boards/286658657/
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
    }

});