({
    doInit: function (component, event, helper) {
        var url = $A.get('$Resource.loginbackground');
        component.set('v.Loginbackground', url);
    }

})