/**
 * Created by rnend on 1/6/2019.
 */
({
    initialize: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();
    },
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        alert(expId);
        if (expId) {
            component.set("v.expid", expId);
        } else { //RJN Add
            component.set("v.expid", component.get("v.defaultExpId"));
        }
        helper.setBrandingCookie(component, event, helper);
    }
})