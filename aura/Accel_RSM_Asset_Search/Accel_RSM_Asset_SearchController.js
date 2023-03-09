({
    /**
     * Retrieve custom metadata and init datatable columns.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    init: function (cmp, evt, helper) {
        helper.retrieveSearchSettings(cmp, helper);
        helper.initDatatableColumns(cmp);
    },
    /**
     * Fired every keypress in search input. check for enter key and fire search if enter
     * @param cmp
     * @param evt
     * @param helper
     * @TODO move to helper?
     */
    checkEnterKey: function (cmp, evt, helper) {
        if (evt.which === 13) {
            //doSearch(cmp,evt,helper);
            var searchField = cmp.find('searchField');
            if (searchField) {
                try {
                    var isValueMissing = searchField.get('v.validity').valueMissing;
                    // // if value is missing show error message and focus on field
                    if (isValueMissing) {
                        searchField.showHelpMessageIfInvalid();
                        searchField.focus();
                    } else {
                        // else call helper function
                        helper.retrieveCases(cmp, event);
                    }
                } catch (e) {
                    console.error(e);
                }
            }
        }
    },
    /**
     * Fire the search
     * @param component
     * @param event
     * @param helper
     * @todo move to helper
     */
    doSearch: function (component, event, helper) {
        var searchField = component.find('searchField');

        if (searchField) {
            try {
                var isValueMissing = searchField.get('v.validity').valueMissing;
                // // if value is missing show error message and focus on field
                if (isValueMissing) {
                    searchField.showHelpMessageIfInvalid();
                    searchField.focus();
                } else {
                    // else call helper function
                    helper.retrieveCases(component, event);
                }
            } catch (e) {
                console.error(e);
            }
        }
    },
    /**
     * update the sorting
     * @param cmp
     * @param event
     * @param helper
     * @TODO why is spinner not showing?
     */
    updateColumnSorting: function (cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    onNext: function (component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber + 1);
        helper.buildData(component, helper);
    },

    onPrev: function (component, event, helper) {
        var pageNumber = component.get("v.currentPageNumber");
        component.set("v.currentPageNumber", pageNumber - 1);
        helper.buildData(component, helper);
    },

    processMe: function (component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        helper.buildData(component, helper);
    },

    onFirst: function (component, event, helper) {
        component.set("v.currentPageNumber", 1);
        helper.buildData(component, helper);
    },

    onLast: function (component, event, helper) {
        component.set("v.currentPageNumber", component.get("v.totalPages"));
        helper.buildData(component, helper);
    }
})