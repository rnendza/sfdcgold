({

    doInit: function(cmp,event,helper) {
        helper.log(cmp, '---------> doInit IRLI Eligibility','debug',JSON.stringify(cmp.get('v.inventoryRequestLineItem')));
        helper.processItemChecks(cmp);
    },
    scriptsLoaded: function (cmp,evt,helper) {
        helper.log(cmp, '---------> scripts loaded','debug');
    },
    /**
     *
     * @param cmp
     * @param event
     */
    handleApplicationEvent: function (cmp,event,helper) {
        let payload = event.getParam("payload");
        //@TODO Double check payload before refresh.
        helper.log(cmp, '---------> handle in eligibility cmp:','debug',JSON.stringify(payload));
        helper.processItemChecks(cmp);
    },
});