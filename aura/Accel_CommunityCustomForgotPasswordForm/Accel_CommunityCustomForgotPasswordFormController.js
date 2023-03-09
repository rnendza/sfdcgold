({
    handleForgotPassword: function (component, event, helper) {
        helper.handleForgotPassword(component, event, helper);
    },
    /**
     * Handles change on username input. if a value.. enable button.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleInputChange: function (cmp, event, helper) {
        let inputText = cmp.find("username").get("v.value");
        console.log('input='+inputText);
        // if(inputText){
        //     cmp.set('v.isButtonActive',true);
        // } else {
        //     cmp.set('v.isButtonActive',false);
        // }
    },
    onKeyUp: function(component, event, helper){
        //checks for "enter" key
        if (event.which === 13){
            helper.handleForgotPassword(component, event, helper);
        }
    },
    setExpId: function (component, event, helper) {
        var expId = event.getParam('expid');
        if (expId) {
            component.set("v.expid", expId);
        }
        helper.setBrandingCookie(component, event, helper);
    },
    initialize: function(component, event, helper) {
        $A.get("e.siteforce:registerQueryEventMap").setParams({"qsToEvent" : helper.qsToEventMap}).fire();
    }
});