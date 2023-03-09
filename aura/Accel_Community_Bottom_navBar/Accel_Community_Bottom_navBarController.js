({
    /**
     * Check if the user already accepted upon init (ie only once after logging in).
     * First check for existance of a cookie named after the user id. if a date exists in there. They are good.
     * If not.. then hit the server with a query for contact record. .if date exists there. they are good.
     * If they have not yet accepted, pop the modal.
     */
    doInit: function (cmp, evt, helper) {
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find("loggingUtils");
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.retrieveCommunityMetadata(cmp);
        helper.checkForTermsAcceptance(cmp);
        try {
            //try to block the pesky escape key.
            window.addEventListener("keydown", function (event) {
                var kcode = event.code;
                if (kcode === 'Escape') {
                    helper.log(cmp,'escape key press');
                    event.preventDefault();
                    event.stopImmediatePropagation();
                }
            }, true);
        } catch (e) {
            helper.log(cmp,'error with escape logic','error',e);
        }
    },
    /**
     *  Open the terms modal.
     */
    handleTermsClick: function (cmp, evt, helper) {
        helper.doOpenTerms(cmp);
    },
    /**
     * Open the whats new modal.
     */
    handleWhatsNewClick: function (cmp, evt, helper) {
       helper.doOpenWhatsNew(cmp);
    },
    /**
     * Open the privacy modal
     */
    handlePrivacyClick: function (cmp, evt, helper) {
       helper.doOpenPrivacy(cmp);
    },
});