({
    /**
     * Merely sets the background image for the theme.
     * @param component
     * @param event
     * @param helper
     */
    doInit: function (component, event, helper) {
        component.set('v.backgroundImage',   $A.get('$Resource.loginbackground'));
    }
});