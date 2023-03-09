({
    /**
     * Set attributes (if in ctx) using implemented interfaces for record pages. If the record Id is available,
     * Retrieve the line item data and evaluate security.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function(cmp,event,helper) {
        if(cmp.get('v.recordId')) {
            cmp.set('v.selectedRecordId', cmp.get('v.recordId'));
           helper.retrieveInitData(cmp);
        }
    },
    /**
     * Handle button click of create assets and fire flow.
     * @param cmp
     * @param evt
     * @param helper
     */
    handleCreateAssets: function(cmp,evt,helper) {
        helper.fireIrLineFlow(cmp);
    },
    /**
     * Handle button click of delete assets and call apex to delete the assets.
     * @param cmp
     * @param evt
     * @param helper
     */
    handleDeleteAssets: function(cmp,evt,helper) {
        helper.deleteAssets(cmp);
    },
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleRefreshComponent: function (cmp,evt,helper) {
        cmp.set('v.cmpCollapsed',false);
        helper.retrieveInitData(cmp);
    },
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleCollapseComponent: function (cmp,evt,helper) {
        cmp.set('v.cmpCollapsed',true);
    },
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleExpandComponent: function (cmp,evt,helper) {
        cmp.set('v.cmpCollapsed',false);
    },
    /**
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleEligibleToggle: function(cmp,evt,helper) {
        const irLine = cmp.get('v.inventoryRequestLineItem');
        let isEligible = irLine.Eligible_to_Create_Assets__c;
        if(isEligible) {
            if(!irLine.All_Line_Assets_Created__c) {
                helper.makeIrLineEligibleToCreateAssets(cmp);
            } else {
                let msg = 'Cannot make this request eligible to create assets. You need to delete at lease one asset';
                helper.displayUiMsg(cmp, 'error', msg);
            }
        } else {
           helper.makeIrLineInEligibleToCreateAssets(cmp);
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
            cmp.set('v.showFireButton', false);
            cmp.set('v.showSpinner',false);
            let outputVars = event.getParam('outputVariables');
            helper.parseFlowOutputVars(cmp,outputVars);
        }
    },
});