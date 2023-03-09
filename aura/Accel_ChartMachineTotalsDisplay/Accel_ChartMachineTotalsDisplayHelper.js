({
    responseDto:    { option:null, message:'', isSuccess:false },
    callback:       null,
    chartData:      {   legendData : null, echartData: null, negativeDailys : [], aggregatedDailys : [],
                        locShareTotalFormatted : null, dateSelected : null, sStartDate :null, sEndDate : null,
                        totalLocShare : null },
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
        //---- @TODO validate here!
        this.chartData.legendData = params.chartData.legendData;
        this.chartData.echartData = params.chartData.echartData;
        this.chartData.negativeDailys = params.chartData.negativeDailys;
        this.chartData.aggregatedDailys = params.chartData.aggregatedDailys;
        this.chartData.locShareTotalFormatted = params.chartData.locShareTotalFormatted;
        this.chartData.dDateSelected = params.chartData.dDateSelected;
        this.chartData.sStartDate = params.chartData.sStartDate;
        this.chartData.sEndDate = params.chartData.sEndDate;
        this.chartData.totalLocShare = params.chartData.totalLocShare;
        return {isSuccess:true};
    },
    /**
     * Not really validating anything yet but placed where for future purposes.
     *
     * @param cmp
     * @param evt
     * @returns {{isSuccess: boolean}}
     */
    validateParamsNegLocShares: function( cmp,evt ) {
        let params = evt.getParam('arguments');
        this.callback = params.callback;
        //---- @TODO validate here!
        this.chartData.negativeDailys = params.chartData.negativeDailys;
        return {isSuccess:true};
    },
    /**
     * Build the options array with data passed from calling component.
     * Return it as a prop in a dto object.
     *
     * @param cmp
     * @param evt
     * @returns {responseDto|{message, option, isSuccess}}
     */
    buildMachineTotalsPieOptions: function( cmp,evt ) {
        var scale = 1;
        var self = this;

        //@TODO use formatter for this instead. it works but is an extra loop even though we are only looping 5 here so n/a
        var seriesDatas = this.chartData.echartData;
        for(let i = 0; i<seriesDatas.length;i++) {
            var seriesData = seriesDatas[i];
            if(seriesData.value) {
                seriesData.value = parseFloat(seriesData.value.toFixed(2));
            }
        }


        var rich = {
            green: {
                color: "rgb(4, 132, 75)",
                fontSize: 19 * scale,
                padding: [3, 10],
                align: 'center'
            },
            red: {
                color: "red",
                fontSize: 20 * scale,
                padding: [5, 4],
                align: 'center'
            },
            black: {
                color: "black",
                align: 'center',
                fontSize: 11 * scale,
                padding: [0, 0]
            },
            hr: {
                borderColor: 'rgb(4, 132, 75)',
                width: '100%',
                borderWidth: 1,
                height: 0,
            },
            richTitle: {
                backgroundColor: 'rgb(242,242,242)',
                borderColor: '#aaa',
                borderWidth: 1,
                borderRadius: 4,
                padding: [4, 10],
                lineHeight: 26,
            }
        };
        var sMainTitle = '';
        if(!this.chartData.dDateSelected) {
            sMainTitle =  'Machine Totals: '+this.chartData.sStartDate + ' to ' + this.chartData.sEndDate;
        } else {
            sMainTitle = 'Machine Totals: '+ this.chartData.sStartDate;
        }
        var titles = [];
        var title = {
            text: sMainTitle,
            subtext: 'Total Location Share: '+this.chartData.locShareTotalFormatted,
            x: 'left',
            textStyle: {
                fontSize: 15
            },
            subtextStyle: {
                color: 'black'
            },
            top: 10
        };
        var sColor = "rgb(4, 132, 75)";
        if(this.chartData.totalLocShare < 0) {
            sColor = 'red';
        }
        var titlePieMiddle = {
            top:'50%',
            right: '44%',
            textStyle : {
                fontSize: 22,
                color: sColor,
                fontFamily: 'Microsoft YaHei',
            },
            subtextStyle : {
                color: 'black'
            },
            text: this.chartData.locShareTotalFormatted
        };
        titles.push(title);
        titles.push(titlePieMiddle);
        var graphics =  [];
        if(this.chartData.negativeDailys.length > 0) {
            graphics.push(this.generateNegLocShareGraphic(this.chartData.negativeDailys));
        }
        var option = {
            title: titles,
            grid: {
                left: '2%',
                containLabel: true,
                show: false,
                right: '2%',
                bottom: '5%',
                top: '15%',
                /* backgroundColor: 'rgb(255,255,255)'*/
            },
            tooltip : {
                trigger: 'item',
                formatter: "{a} <br/>{b} : ${c} ({d}%)"
            },
            legend: {
                orient: 'horizontal',
                align: 'left',
                data: this.chartData.legendData,
                top: 60,
                bottom: 20,
                /*right:10*/
            },
            toolbox: {
                show: true,
                feature: {
                    mark: {show: true},
                    dataView: {show: false, readOnly: false},
                    restore: {show: true},
                    saveAsImage: {show: false}
                },
                showTitle: false,
                right: '2%'
            },
            graphic: graphics, /* negative or zero values */
            series : [
                {
                    name: 'Machine',
                    type: 'pie',
                    radius: ['30%', '35%'],
                    center: ['50%', '55%'],
                    data: this.chartData.echartData,
                    stillShowZeroSum: false,
                    itemStyle: {
                        emphasis: {
                            shadowBlur: 10,
                            shadowOffsetX: 0,
                            shadowColor: 'rgba(0, 0, 0, 0.5)'
                        }
                    },
                    labelLine: {
                        smooth: true
                    },
                    label: {
                        show:true,
                        /*  position: 'inner',*/
                        formatter: function (params) {
                            var total = 0;
                            var percent = 0;
                            self.chartData.echartData.forEach(function(value, index, array) {
                                total += value.value;
                            });
                            percent = ((params.value / total) * 100).toFixed(1);
                            var color = 'green';
                            if(params.value < 0) {
                                color = 'red';
                            }
                            var str = '{'+color+'|' + params.value.toFixed(0) + '}\n{black|' + params.name + '}';
                            //return '{black|' + params.name + '}\n{'+color+'|' + params.value.toFixed(0) + '}';
                            return str;
                        },
                        rich: rich,
                    }
                }
            ]
        };
        //--- @TODO error checking.
        this.responseDto.option = option;
        this.responseDto.isSuccess = true;
        return this.responseDto;
    },
    generateNegLocShareGraphic: function(negativeDailys) {
        var children = [];
        var iTop = 0;
        for(var i = 0; i<negativeDailys.length;i++) {
            var negDaily = negativeDailys[i];
            var childMachine = {
                type: 'text', style: {
                    fill: 'black',
                    z: 100,
                    text:negDaily.machineName,
                    font: 'normal .9em "Microsoft YaHei", sans-serif',
                },
                left: 0, top:iTop
            };
            var sColor = 'red';
            if(negDaily.locShareTotal === 0) {
                sColor = 'black';
            }
            var childLocShare = {
                type: 'text',
                style: {
                    fill: sColor,
                    z:100,
                    // weight | size | family
                    font: 'normal .9em "Microsoft YaHei", sans-serif',
                    text: negDaily.locShareTotal
                },
                right: 10,top:iTop
            };
            children.push(childMachine);
            children.push(childLocShare);
            iTop += 15;
        }
        var childLine =  {
            type: 'line',
            style: {
                color: 'black'
            },
            left: 0, top:iTop + 20,
            right:0
        };
        children.push(childLine);

        var graphic = {
            type: 'group',
            left: 'center',
            bottom: 5,
            width: '275',
            bounding: 'all',
            children: children
        };
        return graphic;
    },
});