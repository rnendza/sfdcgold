({
    /**
     *  We must set focus here since it's not the cmp may not yet exist on init.
     */
    afterRender: function (cmp, helper) {
        this.superAfterRender();
        cmp.find("username").focus();
    }
});