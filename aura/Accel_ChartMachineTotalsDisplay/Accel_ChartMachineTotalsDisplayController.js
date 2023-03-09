({

    /**
     * Fire the callback with the dto containing the chart options.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    buildMachineTotalsPieOptions: function (cmp, evt, helper) {
        let validationDto = helper.validateParamsAllChart(cmp, evt);
        if (!validationDto.isSuccess) {
            helper.callback(helper.responseDto);
        } else {
            let dto = helper.buildMachineTotalsPieOptions(cmp, evt);
            helper.callback(dto);
        }
    },
    /**
     * Fire the callback with the dto containing the graphic
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    generateNegLocShareGraphic: function (cmp, evt, helper) {
        let validationDto = helper.validateParamsNegLocShares(cmp, evt);
        if (!validationDto.isSuccess) {
            helper.callback(helper.responseDto);
        } else {
            let dto = {graphic: null};
            let graphic = helper.generateNegLocShareGraphic(cmp, evt);
            dto.graphic = graphic;
            helper.callback(dto);
        }
    }
});