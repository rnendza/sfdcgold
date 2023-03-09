({
    /**
     *
     * @param cmp
     * @TODO This might not be 'supported' but I see no better way to do it as SFDC has always been a PITA
     * when it's about overriding standard logout functionality.
     */
    customLogout: function( cmp ) {
        var logoutEvent =  $A.get("e.force:logout");
        logoutEvent.fire();
    },
    /**
     *
     * @param cmp
     * @param pageName  the name of the page to navigate to (must be lowercase)
     */
    navToPage : function (cmp, pageName) {
        let navService = cmp.find("navService");
        // Sets the route to [Org url]/[Community uri]/[pageName]
        let pageReference = {
            // community page. See https://developer.salesforce.com/docs/atlas.en-us.lightning.meta/lightning/components_navigation_page_definitions.htm
            type: "comm__namedPage",
            attributes: {
                pageName: pageName
            }
        };
        navService.navigate(pageReference);
    }
});