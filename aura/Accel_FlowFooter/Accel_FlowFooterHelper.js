({
    /**
     *
     * @param cmp
     */
    setIsConsoleNavigation : function(cmp) {
        let workspaceAPI = cmp.find("workspace");
        workspaceAPI.isConsoleNavigation().then(function(response) {
            cmp.set('v.isConsoleNavigation',response);
            cmp.set('v.showCancelButton',response);
        })
            .catch(function(error) {
                console.error(error);
            });
    },
    /**
     * Fires a toast..
     * @param cmp
     * @param type [success,warning,error]
     * @param msg
     */
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    /**
     *
     * @param cmp
     */
    closeFocusedTab: function (cmp) {
        let workspaceAPI = cmp.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function (response) {
            var focusedTabId = response.tabId;
            workspaceAPI.closeTab({tabId: focusedTabId});
        })
            .catch(function (error) {
                console.log(error);
            });

    },
});