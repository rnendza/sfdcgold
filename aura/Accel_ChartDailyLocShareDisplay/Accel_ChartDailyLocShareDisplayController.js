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
    buildDailyLocShareBarOptions: function (cmp, evt, helper) {
        let validationDto = helper.validateParamsAllChart(cmp, evt);
        if (!validationDto.isSuccess) {
            helper.callback(helper.responseDto);
        } else {
            let dto = helper.buildDailyLocShareBarOptions(cmp, evt);
            helper.callback(dto);
        }
    },
});