({
    doInit: function(cmp,evt,helper) {
      helper.formatUtils = cmp.find('formatUtils');
    },
    /**
     * Fire the callback with the dto containing the chart options.
     * 
     * @param cmp
     * @param evt
     * @param helper
     */
    buildChartOptions: function (cmp, evt, helper) {
        let validationDto = helper.validateParams(cmp, evt);
        if (!validationDto.isSuccess) {
            helper.callback(helper.responseDto);
        } else {
            let dto = helper.buildChartOptions();
            helper.callback(dto);
        }
    }
})