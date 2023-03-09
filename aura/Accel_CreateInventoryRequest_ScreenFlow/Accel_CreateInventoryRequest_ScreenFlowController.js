({
    /**
     *
     * @param cmp
     */
    doInit: function(cmp,event,helper) {
        let rtId  = cmp.get("v.pageReference").state.recordTypeId;
        console.log('--------- page ref='+JSON.stringify(cmp.get('v.pageReference').state));
        cmp.set("v.selectedRecordTypeId", rtId);
        helper.initUtils(cmp);
        helper.retrieveRecordTypeViaId(cmp);
        helper.storeCurrentTabId(cmp);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    onFlowStatusChange: function(cmp,event,helper) {
        let s = event.getParam('status');
        if(s === 'FINISHED') {
            let outputVars = event.getParam('outputVariables');
            helper.parseFlowOutputVars(cmp,outputVars);
            helper.closeCurrentTab(cmp);
        } else if (s === 'STARTED') {
          //---------------------  helper.focusFirstFlowFormField(cmp);
        }
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleViewCreateIrHelp: function(cmp,event,helper) {
       helper.handleViewCreateIrHelp(cmp,event,helper);
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
    onButtonPressed: function(cmp,event,helper) {
        var actionClicked = event.getSource().getLocalId();
        // Fire that action
        var navigate = cmp.get('v.navigateFlow');
        navigate(actionClicked);
    }
});