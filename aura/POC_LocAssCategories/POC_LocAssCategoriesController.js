({
    /**
     * Merely set attributes to pass to child from implemented interfaces for record pages.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function(cmp,event,helper) {
        const DEFAULT_DISPLAY_MODE = 'view';
        if(cmp.get('v.sObjectName')) {
            cmp.set('v.selectedSObjectName', cmp.get('v.sObjectName'));
        }
        if(cmp.get('v.recordId')) {
            cmp.set('v.selectedRecordId', cmp.get('v.recordId'));
        }
        // cmp.set('v.displayMode',DEFAULT_DISPLAY_MODE);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleToggleDisplayMode: function(cmp,event,helper) {
        let payload = event.getParam('payload');
        if(payload) {
            console.log('Container ('+cmp.getName()+'received payload on toggle display mode event:'+JSON.stringify(payload));
            if(payload && payload.displayMode) {
                cmp.set('v.displayMode',payload.displayMode);
                if(payload.displayMode === 'edit') {
                    let cmpEdit = cmp.find('childEditCmp');
                    cmpEdit.refreshAfterModeToggle();
                } else {
                    let cmpView = cmp.find('childViewCmp');
                    cmpView.refreshAfterModeToggle();
                }
            }
        }
    },
    /**
     * Not really doing anything but here for future use.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleApplicationEvent: function(cmp,event,helper) {
        cmp.set('v.selectedPath',event.getParam('lwcEvent'));
    },
});