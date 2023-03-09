({
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    doExport: function (cmp, evt, helper) {
        console.log('Accel_SimpleCsvExporter  received calling message.');
        if(!helper.validateIncomingParams(cmp,evt)) {
            try {
                let params = evt.getParam('arguments');
                params.callback(helper.responseDto);
            } catch (e) {
                helper.responseDto.technicalMsg = e.message;
                console.error(helper.responseDto);
            }
        } else {
            console.log('Accel_SimpleCsvExporter  calling helper doExport.');
            helper.doExport(cmp, evt, helper);
            if(!helper.responseDto.isSuccess) {
                //callback?
            }
        }
    }
});