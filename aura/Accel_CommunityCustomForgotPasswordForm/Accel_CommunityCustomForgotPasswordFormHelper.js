({
    qsToEventMap: {
        'expid'  : 'e.c:setExpId'
    },

    handleForgotPassword: function (component, event, helper) {
        var username = component.find("username").get("v.value");
        var checkEmailUrl = component.get("v.checkEmailUrl");
        var action = component.get("c.forgotPassword");
        console.log('handle forgot password for '+username);
        action.setParams({username:username, checkEmailUrl:checkEmailUrl});
        action.setCallback(this, function(a) {
            var rtnValue = a.getReturnValue();
            if (rtnValue != null) {
                component.set("v.errorMessage",rtnValue);
                component.set("v.showError",true);
                component.find("username").focus();
            }
        });
        $A.enqueueAction(action);
    },

    setBrandingCookie: function (component, event, helper) {
        var expId = component.get("v.expid");
        if (expId) {
            var action = component.get("c.setExperienceId");
            action.setParams({expId:expId});
            action.setCallback(this, function(a){ });
            $A.enqueueAction(action);
        }
    }
});