import {LightningElement, api, wire, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import retrieveAllAccountsYoyData from '@salesforce/apex/Accel_CommunityHome.retrieveAllAccountsYoyData';
import HIGHCHARTS from   '@salesforce/resourceUrl/highcharts';
import HIGHCHARTS_STOCK from   '@salesforce/resourceUrl/highcharts';
import {loadScript, loadStyle} from 'lightning/platformResourceLoader';

export default class RicksHpdShitClass extends LightningElement {
    @api buttonText;
    @track yoyData;
    @track error;
    @track loaded = false;
    @track tableLoadingState = true;
    highchartsInitialized = false;
    highchartsStockInitialized = false;
    @track columns = [
        {
            label: 'Date',
            fieldName: 'hpdDate',
            type: "date-local",
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
            label: 'Location Share',
            fieldName: 'locShare',
            type: 'currency',
            sortable: true,
            cellAttributes: {alignment: 'left'}
        }];

    connectedCallback() {
        this.handleLoad();
    }

    renderedCallback() {
        this.highchartsInitialized = true;
        this.highchartsStockInitialized = true;

        Promise.all([
            loadScript(this, HIGHCHARTS + '/highcharts.js'),
            loadScript(this, HIGHCHARTS_STOCK + '/modules/stock.js'),
        ])
            .then(() => {
                this.initializeHighcharts();
            })
            .catch(error => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error loading Highcharts',
                        message: error.message,
                        variant: 'error',
                    }),
                );
            });
    }

    showToast(title, msg) {
        const event = new ShowToastEvent({
            title: title,
            message: msg,
        });
        this.dispatchEvent(event);
    }

    initializeHighcharts() {
        if (typeof (Highcharts) == 'undefined') {
            this.showToast('', 'highcharts not found!');
        } else  {

        }
    }
    mockStockChart() {
        Highcharts.stockChart('container', {


            rangeSelector: {
                selected: 1
            },

            title: {
                text: 'AAPL Stock Price'
            },

            series: [{
                name: 'AAPL',
                data: data,
                tooltip: {
                    valueDecimals: 2
                }
            }]
        });
    }
    mockHighChart() {
        const ele = this.template.querySelector('.highcharts-container');
        var chartOptions =
            {
                chart: {
                    type: 'bar'
                },
                title: {
                    text: 'Previous Day by Location'
                },
                xAxis: {
                    categories: ['Loc 1 ddasf asdfsa fdsaf adsf', 'Loc 2 asdfasf dasf asdf asdf', 'Loc 3'],
                    title: {
                        text: null
                    }
                },
                yAxis: {
                    min: 0,
                    title: {
                        text: 'Amount',
                        align: 'high'
                    },
                    labels: {
                        overflow: 'justify'
                    }
                },
                tooltip: {
                    valueSuffix: ' millions'
                },
                plotOptions: {
                    bar: {
                        dataLabels: {
                            enabled: true
                        }
                    }
                },
                legend: {
                    layout: 'horizontal',
                    align: 'left',
                    verticalAlign: 'bottom',
                    x: 0,
                    y: 50,
                    floating: true,
                    borderWidth: 1,
                    backgroundColor: ((Highcharts.theme && Highcharts.theme.legendBackgroundColor) || '#FFFFFF'),
                    shadow: true
                },
                credits: {
                    enabled: false
                },
                responsive: {
                    rules: [{
                        condition: {
                            maxWidth: 500
                        },
                        chartOptions: {
                            legend: {
                                align: 'left',
                                verticalAlign: 'bottom',
                                layout: 'horizontal'
                            }
                        }
                    }]
                },
                series: [{
                    name: 'Location Share',
                    data: [107, 31, 635],
                    color: {
                        linearGradient: {
                            x1: 0,
                            x2: 0,
                            y1: 0,
                            y2: 1
                        },
                        stops: [
                            [0, '#d2ff52'],
                            [1, '#91e842']
                        ]
                    }
                }, {
                    name: 'Funds In',
                    data: [133, 156, 947]
                }]
            };
            var myChart = Highcharts.chart(ele,chartOptions);
    }
    handleLoad() {
        retrieveAllAccountsYoyData() /*Apex method name */
            .then(result => {
                let dto = result;
                console.log(dto);
                this.loaded = true;
                if (dto.isSuccess) {
                    // alert(JSON.stringify(dto));
                    this.yoyData = this.getMapValue('ACCOUNT_ALL_YOY_HPD', dto.values);
                    this.tableLoadingState = false;
                    console.log(JSON.stringify(this.yoyData));
                    //this.mockChart();
                    this.mockHighChart();
                } else {
                    this.showToast('', 'no success on dto');
                }
            })
            .catch(error => {
                this.error = error;
                console.log(JSON.stringify(error));
                alert(error);
                this.showToast(JSON.stringify(error));
            });
    }
    getMapValue(mKey, values) {
        var retValue;
        for (var key in values) {
            if (key === mKey) {
                retValue = values[key];
                break;
            }
        }
        return retValue;
    }
}