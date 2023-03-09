({
    responseDto:    { option:null, message:'', isSuccess:false },
    callback:       null,
    chartData:  {data  : [], dataAxis  : [], sStartDate : null, sEndDate : null, subText : '', bShowBarValues : true},
    formatUtils: null,
    /**
     * Build the options array with data passed from calling component.
     * Return it as a prop in a dto object.
     *
     * @param cmp
     * @param evt
     * @returns {responseDto|{message, option, isSuccess}}
     */
    buildDailyLocShareBarOptions: function( cmp,evt ) {
        console.log('----- building daily loc share bar options');
        console.log(this.chartData);
        var self = this;
        var option = {
            title: {
                text: 'Location Share: '+this.chartData.sStartDate +' to ' + this.chartData.sEndDate,
                subtext: this.chartData.subText,
                x:'left',
                textStyle : {
                    fontSize: 14
                },
                subtextStyle : {
                    color: 'black'
                },
                top:10
            },
            grid: {
                left: '5%',
                containLabel: true,
                show: true,
                right: '5%',
                bottom: '3%',
                borderColor: 'white',
                top:'17%',
                backgroundColor: 'rgb(255,255,255)'
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
            tooltip: {
                trigger: 'axis',
                formatter: function (oParams) {

                    var param = oParams[0];
                    var date = new Date(param.name);
                    date.setDate(date.getDate() + 1);
                    var value = param.value;
                    var localizedDate =  $A.localizationService.formatDate(date, "MMM dd yyyy");
                    return localizedDate + ' - ' + value;
                }
            },
            xAxis: {
                data: this.chartData.dataAxis,
                axisLabel: {
                    inside: false,
                    rotate: 45,
                    fontStyle: 'normal',
                    fontSize: 11.5,
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (value, index) {
                        var sDate = value;
                        //console.log(sDate);
                        var dDate = new Date(sDate);
                        dDate.setDate(dDate.getDate() + 1);
                        var val =  $A.localizationService.formatDate(dDate, "MM-DD-YY");
                        return val;
                    }
                },
                min: 'dataMin',
                max: 'dataMax',
                axisTick: {
                    show: true
                },
                splitLine: {
                    show:false,
                    lineStyle: {
                        /*color: ['red']*/
                        type: 'dashed'
                    }
                },
                /*axisLine: {onZero: false},*/

            },
            yAxis: {
                splitLine: {
                    show:true,
                    lineStyle: {
                        /*color: ['red']*/
                        type: 'dashed'
                    }
                },
                /*axisLine: {onZero: false},*/
                axisTick: {
                    show: true
                },
                axisLabel: {
                    textStyle: {
                        color: 'black'
                    },
                    formatter: function (value, index) {
                        var shortVal;
                        shortVal = self.formatValue('$',value,2);
                        return shortVal;
                    }

                }
            },
            dataZoom: [
                {
                    type: 'inside'
                }
            ],
            series: [
                { // For shadow
                    type: 'bar',
                    itemStyle: {
                        /*normal: {color: 'rgba(0,0,0,0.05)'}*/
                        normal : {

                        }
                    },
                    label: {
                        normal: {
                            show: this.chartData.bShowBarValues,
                            position: 'insideBottom',
                            color: 'black',
                            itemStyle: {
                                color: 'black'
                            },
                            formatter: function(params) {
                                //console.log(params.data);
                                var shortVal = self.formatValue('',params.data,0);
                                return  shortVal;
                            },
                            fontSize: 11
                        }
                    },
                    /* barGap:'-100%',
                     barCategoryGap:'40%', */
                    data: this.chartData.data,
                    animation: true
                },
                /*
                {
                    type: 'bar',
                    itemStyle: {
                      normal : {

                      }
                    },
                    data: data
                }
                */
            ]

        };
        this.responseDto.option = option;
        this.responseDto.isSuccess = true;
        return this.responseDto;
    },

    /**
     * Not really validating anything yet but placed where for future purposes.
     *
     * @param cmp
     * @param evt
     * @returns {{isSuccess: boolean}}
     */
    validateParamsAllChart: function( cmp,evt ) {
        let params = evt.getParam('arguments');
        this.callback = params.callback;
        this.chartData.data = params.chartData.data;
        this.chartData.dataAxis = params.chartData.dataAxis;
        this.chartData.sStartDate = params.chartData.sStartDate;
        this.chartData.sEndDate = params.chartData.sEndDate;
        this.chartData.subText = params.chartData.subText;
        this.chartData.bShowBarValues = params.chartData.bShowBarValues;
        //---- @TODO validate here!
        return {isSuccess:true};
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
});