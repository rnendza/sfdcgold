({
    doInit: function(cmp,evt, helper) {
        //console.log('accel init of accordion license data cmp');
    },
    /**
     * SFDC Accordion seems to have a lifecycle issue when iterating a list and using data from the list identify
     * the active section name.. We need to.
     *
     * 1. Put a value change handler on the passed in attribute.
     * 2. Copy the passed in attribute to a private attribute after the render cycle.
     *
     * @param cmp
     */
    handleActiveAccordionSectionsChange : function( cmp ) {
        let activeSections = cmp.get('v.activeSections');
        // Wait for the render cycle and copy the public (passed in attribute to the local private attribute.
        setTimeout($A.getCallback(
            () => cmp.set("v.localActiveSections", activeSections)
        ));
    },
});