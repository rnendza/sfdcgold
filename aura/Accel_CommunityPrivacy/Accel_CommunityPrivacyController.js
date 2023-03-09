({
    doInit: function (cmp,evt,helper) {
        helper.loggingUtils = cmp.find("loggingUtils");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.retrievePrivacy(cmp);
    },
});