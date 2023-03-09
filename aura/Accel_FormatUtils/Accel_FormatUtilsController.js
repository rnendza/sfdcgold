({
    formatNumericValue: function(cmp,evt,helper) {
        let formatDto = helper.formatNumericValue(cmp,evt);
        let callback = evt.getParam('arguments').callback;
        callback(formatDto);
    }
});