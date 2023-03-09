({
    reInit: function(cmp, event, helper) {
        cmp.set("v.initialized",false);
        helper.doInit(cmp);
    },

    doInit: function(cmp, event, helper) {
        helper.doInit(cmp);
    },

    handleClick: function(cmp, event, helper) {
        var mainDiv = cmp.find('main-div');
        $A.util.addClass(mainDiv, 'slds-is-open');
    },

    handleSelection: function(cmp, event, helper) {
        var item = event.currentTarget;
        if (item && item.dataset) {
            var value = item.dataset.value;
            var selected = item.dataset.selected;

            var options = cmp.get("v.options_");

            //shift key ADDS to the list (unless clicking on a previously selected item)
            //also, shift key does not close the dropdown (uses mouse out to do that)
            if (event.shiftKey) {
                options.forEach(function(element) {
                    if (element.value == value) {
                        element.selected = selected == "true" ? false : true;
                    }
                });
            } else {
                options.forEach(function(element) {
                    if (element.value == value) {
                        element.selected = selected == "true" ? false : true;
                    } else {
                      // rjn removed  element.selected = false;
                    }
                });
                // rjn removed var mainDiv = cmp.find('main-div');
               // rjn removed $A.util.removeClass(mainDiv, 'slds-is-open');
            }
            cmp.set("v.options_", options);
            var values = helper.getSelectedValues(cmp);
            var labels = helper.getSelectedLabels(cmp);

            helper.setInfoText(cmp, labels);
            helper.fireSelectChangeEvent(cmp, values);

        }
    },

    handleMouseLeave: function(cmp, event, helper) {
        cmp.set("v.dropdownOver", false);
        var mainDiv = cmp.find('main-div');
        $A.util.removeClass(mainDiv, 'slds-is-open');
    },

    handleMouseEnter: function(cmp, event, helper) {
        cmp.set("v.dropdownOver", true);
    },

    handleMouseOutButton: function(cmp, event, helper) {
        window.setTimeout(
            $A.getCallback(function() {
                if (cmp.isValid()) {
                    //if dropdown over, user has hovered over the dropdown, so don't close.
                    if (cmp.get("v.dropdownOver")) {
                        return;
                    }
                    var mainDiv = cmp.find('main-div');
                    $A.util.removeClass(mainDiv, 'slds-is-open');
                }
            }), 200
        );
    }

})