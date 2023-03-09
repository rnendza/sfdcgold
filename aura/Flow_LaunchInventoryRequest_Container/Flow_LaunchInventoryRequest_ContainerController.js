({
    /**
     * Merely set attributes to pass to child from implemented interfaces for record pages.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function(cmp,event,helper) {
        if(cmp.get('v.recordId')) {
            cmp.set('v.selectedRecordId', cmp.get('v.recordId'));
            helper.retrieveIr(cmp);
        }
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
           //------------------------------ let msg = cmp.get('v.totalNbrOfAssetsCreated') + ' software assets successfully created!';
            helper.displayUiMsg(cmp,'success',msg);
            $A.get("e.force:closeQuickAction").fire();
            $A.get('e.force:refreshView').fire();
        }
    },
    handleCreateAssets: function(cmp,evt,helper) {
        alert('@TODO fire flow.. hide button.. show status info..etc');
        cmp.set('v.fireFlow',true);
        cmp.set('v.isRunningFlow',true);
    }
});