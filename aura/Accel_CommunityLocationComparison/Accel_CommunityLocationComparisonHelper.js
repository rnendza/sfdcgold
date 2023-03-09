({  formatUtils: null,
    locationComparisonChart: null,

    mockUserAccounts: function (cmp) {
        let accounts = [];
        accounts.push({Id:'rickId',Name:'Casa de Rick'});
        for(let i = 1; i<21;i++) {
            let account = {Id:i,Name:'account '+i,ShippingStreet:'street '+i,ShippingCity: 'city '+i};
            accounts.push(account);
            cmp.set('v.userAccounts',accounts);
        }
    },
    mockLocTypes: function(cmp) {
        let locTypes = [];
        locTypes.push({label : 'American Legion', value: 'American Legion'});
        locTypes.push({label : 'Bar', value: 'Bar'});
        locTypes.push({label : 'Bar & Grill', value: 'Bar & Grill'});
        locTypes.push({label : 'Bowling Alley', value: 'Bowling Alley'});
        locTypes.push({label : 'C-Store', value: 'C-Store'});
        locTypes.push({label : 'C-Store W/O Gas', value: 'C-Store W/O Gas'});
        locTypes.push({label : 'Gaming Parlor', value: 'Gaming Parlor'});
        locTypes.push({label : 'Restaurant', value: 'Restaurant'});
        locTypes.push({label : 'Truck Stop', value: 'Truck Stop'});
        locTypes.push({label : 'VFW', value: 'VFW'});
        cmp.set('v.locTypes',locTypes);
    },
    mockDistances: function(cmp) {
        let distances = [];
        for(let i = 1; i<21;i++) {
            let distance = {label: i +' Miles',value: i};
            distances.push(distance);
        }
        distances.sort(function(a, b) {return b.value - a.value;});
        cmp.set('v.distances',distances);
    },
    mockMapInfo: function(cmp) {
        this.renderMap(cmp);
    },
    mockDatatableData: function(cmp) {
        let resultDatas = [];
        let uas = cmp.get('v.userAccounts');
        if(uas && uas.length > 0) {
            for (let i = 1; i < uas.length; i++) {
                let ua = uas[i];
                let hpdUnformatted = (300 / i) + (22 + i);
                let infoToFormat = {prefix: '$', value: hpdUnformatted, fixed: 2};
                let hpdFormatted = 0;
                this.formatUtils.formatNumericValue(infoToFormat, function (dto) { hpdFormatted = dto.value;});
                let resultData = {rank: i, hpd: hpdFormatted, location: ua.Name};
                resultDatas.push(resultData);
            }
        }
        cmp.set('v.resultData',resultDatas);
    },
    initDatatableColumns: function(cmp) {
            cmp.set('v.resultColumns', [
                {label: 'Rank', fieldName: 'rank', type: 'number', sortable: true, cellAttributes: {alignment: 'left'}},
                {label: 'HPD', fieldName: 'hpd', type: 'text', sortable: true, cellAttributes: {alignment: 'left'}},
                {label: 'Location', fieldName: 'location', type: 'text', sortable: true, cellAttributes: {alignment: 'left'}}
            ]);
    },
    renderMap: function(cmp) {
        cmp.set('v.mapMarkers', [
            {
                location: {
                    Street: '4916 Main Street',
                    City: 'Lisle',
                    PostalCode: '60532',
                    State: 'IL',
                    Country: 'USA',
                },

                icon: 'utility:salesforce1',
                title: 'Ricks House title',
                description: 'Ricks House Title'
            },
            {
                location: {
                    Street: '1940 Internationale Pkwy',
                    City: 'Woodridge',
                    PostalCode: '60517',
                    State: 'IL',
                    Country: 'USA',
                },

                icon: 'utility:salesforce1',
                title: 'American Video Gaming LLC',
            }
        ]);
        cmp.set('v.center', {
            location: {
                City: 'Woodridge'
            }
        });
        cmp.set('v.zoomLevel', 11);
        cmp.set('v.markersTitle', 'blah markers title');
        cmp.set('v.showFooter', true);
    },
    mockChart: function (cmp) {
        var option = {
            backgroundColor: '#0f375f',
            tooltip : {
                trigger: 'axis',
                axisPointer: {
                    type: 'cross',
                    label: {
                        backgroundColor: '#6a7985'
                    }
                }
            },
            legend: {
                data:['Area Avg','Casa de Rick']
            },
            toolbox: {
                // feature: {
                //     saveAsImage: {}
                // }
            },
            grid: {
                top: '10%',
                left: '5%',
                right: '5%',
                bottom: '5%',
                containLabel: true
            },
            xAxis : [
                {   color :'white',
                    type : 'category',
                    boundaryGap : false,
                    data : ['Sept 18','Oct 18','Nov 18','Dec 18','Jan 19','Feb 19','Mar 19']

                }
            ],
            yAxis : [
                {   color: 'white',
                    type : 'value'
                }
            ],
            series : [
                {
                    name:'Area Avg',
                    type:'line',
                    areaStyle: {normal: {}},
                    data:[320, 332, 301, 334, 390, 330, 320]
                },
                {
                    name:'Casa de Rick',
                    type:'line',
                    label: {
                        normal: {
                            show: true,
                            position: 'top'
                        }
                    },
                    areaStyle: {normal: {}},
                    data:[820, 932, 901, 934, 1290, 1330, 1320]
                }
            ]
        };
        this.locationComparisonChart = echarts.init(cmp.find("echartsLocationComparison").getElement(),'dark');
        this.locationComparisonChart.setOption(option);
    }
});