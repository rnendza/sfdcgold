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
            cmp.set('v.showBackButton',true);
        }
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleBackToRequest: function(cmp,event,helper) {
        helper.navigateToMasterRecord(cmp);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleRecordChanged: function(cmp, event, helper) {
        switch(event.getParams().changeType) {
            case "ERROR":
                console.error('record change error..'+JSON.stringify(cmp.get('v.recordError')));
                break;
            case "LOADED":
                helper.log(cmp,'----- LDS LOADED -----','debug');
                helper.log(cmp, 'LDS LOADED record: ','debug',JSON.stringify(cmp.get("v.record")));
                break;
            case "REMOVED":
                cmp.set('v.initCompleted',false);
                helper.log(cmp,'----- LDS REMOVED -----','debug');
                break;
            case "CHANGED":
                cmp.set('v.initCompleted',false);
                helper.log(cmp,'----- LDS CHANGED -----','debug');
                helper.log(cmp, 'LDS CHANGED record: ','debug',JSON.stringify(cmp.get("v.record")));
                helper.retrieveInitData(cmp);
                break;
        }
    },
    /**
     * 
     * @param cmp
     * @param event
     * @param helper
     */
    handleViewCreateAssetsHelp: function(cmp,event,helper) {
        let recordId = cmp.get('v.contentDocumentRecordId');
        if(recordId) {
            try {
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [recordId]
                });
            } catch (e) {
                alert(e); //not sure this works. @TODO find way to handle above error.
            }
        }
    },
    /**
     *
     * @param cmp
     * @param event
     */
    handleApplicationEvent: function (cmp,event,helper) {
        let payload = event.getParam("payload");
        //@TODO Double check payload before refresh.
        helper.log(cmp,'handle in ri container:','debug',JSON.stringify(payload));
        cmp.set('v.initCompleted',false);
        helper.retrieveInitData(cmp);
    },
    /**
     * Handle button click of create assets and fire flow.
     * @param cmp
     * @param evt
     * @param helper
     */
    handleCreateAssets: function(cmp,evt,helper) {
        cmp.set('v.showBackButton',false);
        helper.fireIrLineFlow(cmp);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleOpenFiles: function(cmp, event, helper) {
        let msg = 'Opening files: ' + event.getParam('recordIds').join(', ');
        helper.log(cmp,msg,'debug');
    },
});