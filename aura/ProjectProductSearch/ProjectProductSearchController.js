({
	doInit : function(component, event, helper) {
        component.set('v.columns', helper.getColumnDefinitions());
        helper.queryProducts(component);
        helper.queryProjectLines(component);
	},

    search : function(component, event, helper) {
        // If enter key was pressed, reset query using search string
        if (event.which == 13){
            var queryOffset = component.get('v.queryOffset');
            queryOffset = 0;
            component.set('v.queryOffset', queryOffset);
            var products = [];
            component.set('v.data', products);
            var enableInfiniteLoading = true;
            component.set('v.enableInfiniteLoading', enableInfiniteLoading);
            helper.queryProducts(component);
        }
    },

    loadMoreData : function(component, event, helper) {
        var queryOffset = component.get('v.queryOffset');
        var loadMoreOffset = component.get('v.loadMoreOffset');
        queryOffset = queryOffset + loadMoreOffset;
        component.set('v.queryOffset', queryOffset);
        helper.queryProducts(component);
    },

    handleProductRemove: function(component, event, helper) {
        var productId = event.getParam('item').name;
        var selectedProductsList = component.get('v.selectedProductsList');
        var selectedProducts = component.get('v.selectedProducts');
        var selectedRows = component.get('v.selectedRows');
        var removedProductIndex = event.getParam('index');
        
        for(var i = 0; i < selectedRows.length; i++) {
            var selectedRowId = selectedRows[i];
            if(selectedRowId == productId) {
                selectedRows.splice(i, 1);    
            }
        }
        selectedProductsList.splice(removedProductIndex, 1);
        delete selectedProducts[productId];

        component.set('v.selectedRows', selectedRows);
        component.set('v.selectedProductsList', selectedProductsList);  
        component.set('v.selectedProducts', selectedProducts);
    },

    updateSelectedRows : function(component, event, helper) {
        var cmpSelectedRows = event.getParam('selectedRows');
        var selectedRows = Object();
        var selectedProducts = component.get('v.selectedProducts');
        var selectedRowsIds = [];

        for(var i = 0; i < cmpSelectedRows.length; i++) {
            var selectedRow = cmpSelectedRows[i];
            selectedRows[selectedRow.Id] = selectedRow;
            selectedProducts[selectedRow.Id] = selectedRow;
            selectedRowsIds.push(selectedRow.Id);
        }

        var products = component.get('v.data');

        for(i = 0; i < products.length; i++) {
            var product = products[i];

            if(!(product.Id in selectedRows)) {
                if(product.Id in selectedProducts) {
                    delete selectedProducts[product.Id];
                }
            } 
        }
        
        var selectedProductsList = helper.getSelectedProductsList(selectedProducts);
        
        component.set('v.selectedRows', selectedRowsIds);
        component.set('v.selectedProducts', selectedProducts);
        component.set('v.selectedProductsList', selectedProductsList);
    },

    editProducts: function(component, event, helper) {
        var selectedProducts = component.get('v.selectedProducts');
        var projectLines = helper.getUpdatedProjectLines(component, selectedProducts);
        component.set('v.projectLines', projectLines);

        var step = component.get('v.step');
        step++;
        component.set('v.step', step);
    },

    searchProducts: function(component, event, helper) {
        component.set('v.step', 0);
    },

    callSaveProjectLines : function(component, event, helper) {
        var productEditCmp = component.find('productEditCmp');
        productEditCmp.saveProjectLineItems(function(result) {
            $A.get('e.force:refreshView').fire();
            $A.get("e.force:closeQuickAction").fire();
        });
    },

    closeModal: function(component, event, helper) {
        $A.get("e.force:closeQuickAction").fire();
    }
})