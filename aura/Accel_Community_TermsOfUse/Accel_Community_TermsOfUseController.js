({
    doInit: function (cmp,evt,helper) {
        helper.loggingUtils = cmp.find("loggingUtils");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.retrieveTermsOfUse(cmp);
    },
    handleAccept: function(cmp,event,helper) {
        helper.handleAccept(cmp);
    }
});