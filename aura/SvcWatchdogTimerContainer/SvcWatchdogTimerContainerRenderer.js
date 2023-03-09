({
    /**
     * Attempt to remove label and icon if the user has no permission. Note. in all reality this only works after the user
     * clicked on the utility bar item. So a bit too late but the best we can do for now given lack of a strong api.
     *
     * We must register event handlers on the after render as opposed to init of comp for the utility bar.
     */
    afterRender: function(cmp,helper){
        this.superAfterRender();
        try {
            helper.disableUtilityPopOut(cmp,helper);
            helper.registerUtilityClick(cmp);
        } catch (e) {
            helper.log(e,cmp);
        }
    },
    /**
     * https://accel-entertainment.monday.com/boards/286657232/pulses/314982925
     *
     * Attaches a click event handler to the window object. If we click on anything else but
     * DOM nodes owned by this component, hide the menu filter button in the child lwc
     * component and then reshow it after 1 second. If not redisplay it / do nothing depending on the state.
     *
     * Note: this is primarily a hack to account for what appears to be a bug
     * in the OOTB SFDC Button Menu Component where it gets confused on focus handlers when
     * embedded in a utility bar item and trying to minimize while focus exists on the menu
     * button.
     * https://developer.salesforce.com/docs/component-library/bundle/lightning-button-menu/example
     *
     * Side effect: possibly a small 'flash' of the button hiding / showing when working on a record
     * say outside this component (utility bar item) with the menu expanded and the utility bar
     * component not minimized. (Edge Case)
     *
     * @param cmp
     * @param helper
     *
     * @TODO check on api version updates ie winter 20 to see if this is fixed by SFDC.
     */
    rerender: function(cmp, helper) {
        this.superRerender();
        helper.windowClick = $A.getCallback(function(event){
            if(cmp.isValid()){
                const OUTSIDE_DOM_ELEMENTS = 'HTMLBodyElement';
                //  HTML Body element means anywhere outside the scope of this component
                //  Including the utility bar popup header (dismiss icon)
                try {
                    if(event.target) {
                        if (event.target.toString().includes(OUTSIDE_DOM_ELEMENTS)) {
                            cmp.set('v.forceCloseFilterMenu', true); // send child lwc cmp to hide filter.
                            window.setTimeout(function () {
                                cmp.set('v.forceCloseFilterMenu', false); //send child lwc cmp to show filter after 1 sec.
                            }, 1000);
                        } else {
                            cmp.set('v.forceCloseFilterMenu', false);   //send child lwc cmp to show filter.
                        }
                    }
                } catch (e) {
                    console.error(e);
                }
            }
        });
        document.addEventListener('click',helper.windowClick);
    },
    /**
     * Remove the windowClick event listener upon unrender of this component.
     *
     * @param cmp
     * @param helper
     */
    unrender: function (cmp,helper) {
        this.superUnrender();
        try {
            document.removeEventListener('click', helper.windowClick);
        } catch (e) {
            console.error(e);
        }
    }
});