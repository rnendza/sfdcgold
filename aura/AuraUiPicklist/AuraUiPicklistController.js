({
    /**
     * Re-fire child comp event so we can pass to aura sibling.
     *
     * @param cmp
     * @param event
     */
    handleOptionSelectedEvent: function(cmp,event) {
        let appEvent = $A.get("e.c:appEvent");
        let payload = event.getParam('payload');
        if(appEvent && payload) {
            console.log('firing appEvent from AuraUiPicklist with payload='+JSON.stringify(payload));
            appEvent.setParams({"payload": payload});
            appEvent.fire();
        }
    },




    handleFieldSetName: function(cmp, event) {
        var fieldsetname =  event.getParam("FieldSetName");

        console.log(fieldsetname +'Cedric Test');
        cmp.set('v.picklistDefaultOverride',fieldsetname);


    },
});