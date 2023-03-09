({
    doInit: function(cmp,event,helper) {
        helper.initUtils(cmp);
        helper.retrieveIrProgressIndicators(cmp);
    },
    /**
     *
     * @param component
     * @param event
     * @param helper
     */
    handleSelect : function (component, event, helper) {
        var stepName = event.getParam("detail").value;
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": "Success!",
            "message": "Toast from " + stepName
        });
        toastEvent.fire();
    },
    handleLockedPillRemove: function(cmp,event,helper) {
        cmp.set('v.hideLockedPill',true);
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
                console.error('---- error in handle record changed!');
                console.error(JSON.stringify(event.getParams()));
                let recordLoadError = cmp.get('v.recordLoadError');
                console.error(recordLoadError);
                helper.displayUiMsg(cmp,'error',recordLoadError);
                break;
            case "LOADED":
                helper.log(cmp,'----- LDS LOADED -----','debug');
                console.log('---------- LOADED ---------------');
                helper.log(cmp, 'record: ','debug',JSON.stringify(cmp.get("v.record")));
                helper.log(cmp, 'simplerecord: ','debug',JSON.stringify(cmp.get("v.simpleRecord")));
                helper.flagCurrentProgressIndicator(cmp);
                break;
            case "REMOVED":
                helper.log(cmp,'----- LDS REMOVED -----','debug');
                break;
            case "CHANGED":
                // more stuff
                helper.log(cmp,'----- LDS CHANGED -----','debug');
                helper.log(cmp, 'record: ','debug',JSON.parse(JSON.stringify(cmp.get("v.record"))));
                //@TODO RJN is this correct?
                helper.retrieveIrProgressIndicators(cmp);
                helper.flagCurrentProgressIndicator(cmp);
                //  Fire event so create assets cmp on line item can listen for changes.
                let payload = {record: cmp.get('v.record')};
                helper.fireAppEvent(cmp,payload);
                break;
        }
    },
    /**
     * Open the content document.
     *
     * @param cmp
     * @param event
     * @param helper
     *
     * @TODO dynamically retrieve the record id below (it's not easy).
     */
    handleViewLifecycleHelp:  function (cmp,event,helper) {
        let recordId = cmp.get('v.contentDocumentRecordId');
        if(recordId) {
            try {
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [recordId]
                });
            } catch (e) {
                //not sure this works. @TODO find way to handle above error.
            }
        }
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
});