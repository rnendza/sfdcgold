({
    doInit: function (cmp,evt,helper) {
        helper.loggingUtils = cmp.find("loggingUtils");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.retrieveReleaseNotes(cmp);
    },
    handleCancel: function(cmp,evt,helper) {
        cmp.find("bottomNavOverlayLib").notifyClose();
    }
});