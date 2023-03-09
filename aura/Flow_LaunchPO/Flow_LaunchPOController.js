({
    /**
     * Get the full PO Record and fire the flow if necessary.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function (cmp,event,helper) {
        helper.retrievePo(cmp);
    },
    /**
     * Detect status changes in the flow.  consume flow output vars for ui messaging.
     * @param cmp
     * @param event
     */
    statusChange: function (cmp, event,helper) {
        let s = event.getParam('status');
        if(s === 'FINISHED_SCREEN') {
            cmp.set('v.isRunningFlow',false);
            let outputVars = event.getParam('outputVariables');
            helper.debugFlowOutputVars(cmp,outputVars);
            let msg = cmp.get('v.totalNbrOfAssetsCreated') + ' software assets successfully created!';
            helper.displayUiMsg(cmp,'success',msg);
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        }
    },
    /**
     * Simply close the modal.
     * @param cmp
     * @param event
     * @param helper
     */
    cancelClick: function (cmp,event,helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
});