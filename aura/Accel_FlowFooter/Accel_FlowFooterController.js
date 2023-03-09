({
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    init : function(cmp, event, helper) {
        helper.setIsConsoleNavigation(cmp);
        // Figure out which buttons to display
        let availableActions = cmp.get('v.availableActions');
        for (let i = 0; i < availableActions.length; i++) {
            if (availableActions[i] === "PAUSE") {
                cmp.set("v.canPause", true);
            } else if (availableActions[i] === "BACK") {
                cmp.set("v.canBack", true);
            } else if (availableActions[i] === "NEXT") {
                cmp.set("v.canNext", true);
            } else if (availableActions[i] === "FINISH") {
                cmp.set("v.canFinish", true);
            }
        }
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    onButtonPressed: function(cmp, event, helper) {
        // Figure out which action was called
        var actionClicked = event.getSource().getLocalId();
        if(actionClicked !== 'CANCEL') {
            // Fire that action
            var navigate = cmp.get('v.navigateFlow');
            navigate(actionClicked);
        } else if(actionClicked === 'CANCEL' ){
            if(cmp.get('v.isConsoleNavigation')) {
                helper.closeFocusedTab(cmp);
            } else {
                const msg = 'Cancel currently only supported in console applications.';
                helper.displayUiMsg(cmp,'warning',msg);
                console.warn(msg);
            }
        }
    }
});