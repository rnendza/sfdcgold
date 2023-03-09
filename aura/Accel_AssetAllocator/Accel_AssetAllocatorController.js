({
    /**
     * Not really doing much.. just init statusMetadata as an object (defaulting objects in aura attributes is flaky)
     * Also copying the selected record id.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function(cmp,event,helper) {
        let statusMetaData = {};
        cmp.set('v.statusMetadata',statusMetaData);
        if(cmp.get('v.recordId')) {
            cmp.set('v.selectedRecordId', cmp.get('v.recordId'));
        }
    },
    /**
     * Handle LDS Record Changed Event.. Branch off when required.
     * @param cmp
     * @param event
     * @param helper
     */
    handleRecordChanged: function(cmp, event, helper) {
        switch(event.getParams().changeType) {
            case "ERROR":
                helper.log('record change error..','error',JSON.stringify(cmp.get('v.recordError')));
                break;
            case "LOADED":
                helper.log(cmp,'----- LDS LOADED -----','debug');
                helper.log(cmp, 'LDS LOADED simple record: ','debug',JSON.stringify(cmp.get("v.simpleRecord")));
                helper.log(cmp, 'LDS LOADED record: ','debug',JSON.stringify(cmp.get("v.record")));
                helper.processStatus(cmp);
                break;
            case "REMOVED":
                cmp.set('v.initCompleted',false);
                helper.log(cmp,'----- LDS REMOVED -----','debug');
                break;
            case "CHANGED":
                cmp.set('v.initCompleted',false);
                helper.log(cmp,'----- LDS CHANGED -----','debug');
                helper.log(cmp, 'LDS CHANGED record: ','debug',JSON.stringify(cmp.get("v.record")));
                helper.processStatus(cmp);
                break;
        }
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleViewHelp:  function (cmp,event,helper) {
        let recordId = cmp.get('v.contentDocumentRecordId');
        if(recordId) {
            try {
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [recordId]
                });
            } catch (e) {
                helper.log(cmp,'error handling help view','error',JSON.stringify(e)); //not sure this works. @TODO find way to handle above error.
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
});