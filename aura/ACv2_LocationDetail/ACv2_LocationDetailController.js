({
    /**
     * Simply inits general utilities and then retrieves all visible location data.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    doInit: function (cmp, evt, helper) {
        // https://accel-entertainment.monday.com/boards/286658657/
        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.formatUtils = cmp.find('formatUtils');
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.retrieveLocationLicenseData(cmp);
    },
});