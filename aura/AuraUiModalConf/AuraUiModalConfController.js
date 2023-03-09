({
    handleCancelClick : function(cmp, event, helper) {
        let evt = cmp.getEvent("confirm");
        //evt.setParam('confirmButton','cancel');
        evt.setParams({"confirmButton" : "cancel"});
        evt.fire();
    },
    handleOkClick : function(cmp, event, helper) {
        let evt = cmp.getEvent("confirm");
        evt.setParams({"confirmButton" : "ok"});
        evt.fire();
    }
});