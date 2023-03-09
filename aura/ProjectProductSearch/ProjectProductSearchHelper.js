({
	getColumnDefinitions: function () {
        var columns = [
            {label: 'Accel Name', fieldName: 'Name', type: 'text'},
            {label: 'Product Code', fieldName: 'ProductCode', type: 'text'},
            {label: 'List Price', fieldName: 'listPrice', type: 'currency', typeAttributes: { currencyCode: 'USD', currencyDisplayAs: 'symbol'}},
            {label: 'Product Description', fieldName: 'Description', type: 'text'},
            {label: 'Product Family', fieldName: 'Family', type: 'text'}
        ];

        return columns;
    },

    queryProjectLines: function(component) {
        var helper = this;
        this.executeAction(component, 'c.getProjectLineItems', {
            'recordId' : component.get('v.recordId')
        })
        .then($A.getCallback(function(projectLines) {
            for(var i = 0; i < projectLines.length; i++) {
                var projectLine = projectLines[i];
                projectLine.productUrl = '/' + projectLine.Product__c;
                projectLine.productName = projectLine.Product__r.Name;
                projectLines[i] = projectLine;
            }
            //component.set('v.projectLines', projectLines);
            helper.preSelectProducts(component);
        }))
        .catch($A.getCallback(function(error) {
            console.log(error.message);
        }));
    },

    getUpdatedProjectLines: function(component, selectedProducts) {
        var projectLines = component.get('v.projectLines');
        for(var productId in selectedProducts) {
            var selectedProduct = selectedProducts[productId];
            var productIdInProjectLines = false;
            for(var i = 0; i < projectLines.length; i++) {
                var projectLine = projectLines[i];
                if(projectLine.Product__c == productId) {
                    productIdInProjectLines = true;
                }
            }
            if(!productIdInProjectLines) {
                var projectLine = this.createNewProjectLine(selectedProduct);
                projectLines.push(projectLine);
            }
        }

        for(var i = 0; i < projectLines.length; i++) {
            var projectLine = projectLines[i];
            if(!(projectLine.Product__c in selectedProducts)) {
                projectLines.splice(i, 1);       
            }
        }

        return projectLines;
    },

    createNewProjectLine: function(selectedProduct) {
        var projectLine = {};
        projectLine.sobjectType = 'Project_Line__c';
        projectLine.Product__c = selectedProduct.Id;
        projectLine.Quantity__c = 1;
        projectLine.Description__c = '';
        projectLine.Service_Date__c = undefined;
        projectLine.productName = selectedProduct.Name;
        projectLine.productUrl = '/' + selectedProduct.Id;
        projectLine.Id = this.guid();
        return projectLine;
    },

    guid: function() {
        function s4() {
            return Math.floor((1 + Math.random()) * 0x10000)
                .toString(16)
                .substring(1);
        }
        return s4() + s4() + '-' + s4() + '-' + s4() + '-' + s4() + '-' + s4() + s4() + s4();
    },

    preSelectProducts: function(component) {
        var projectLines = component.get('v.projectLines');
        var products = component.get('v.data');

        var selectedRows = [];
        var selectedProducts = {};

        for(var i in projectLines) {
            var projectLine = projectLines[i];
            var selectedProduct = Object();
            selectedProduct.Id = projectLine.Product__c;
            selectedProduct.Name = projectLine.Product__r.Name;
            selectedProducts[selectedProduct.Id] = selectedProduct;
            for(var prodIndex = 0; prodIndex < products.length; prodIndex++) {
                var product = products[prodIndex];
                if(product.Id == selectedProduct.Id) {
                    selectedRows.push(selectedProduct.Id);
                }
            }
        }

        var selectedProductsList = this.getSelectedProductsList(selectedProducts);

        component.set('v.selectedRows', selectedRows);
        component.set('v.selectedProductsList', selectedProductsList);  
        component.set('v.selectedProducts', selectedProducts);
    },

    queryProducts: function(component) {
        this.executeAction(component, 'c.getProducts', {
            'searchString' : component.get('v.searchString'),
            'queryOffset' : component.get('v.queryOffset')
        })
        .then($A.getCallback(function(productResponse) {
            var products = component.get('v.data');
            var selectedProducts = component.get('v.selectedProducts');
            var selectedRowsIds = component.get('v.selectedRows');

            // Manage infinite loading bug with a list < 20 products
            var enableInfiniteLoading = component.get('v.enableInfiniteLoading');
            if(productResponse.productData.length > 0) {
                enableInfiniteLoading = true;
            } else {
                enableInfiniteLoading = false;
            }
            component.set('v.enableInfiniteLoading', enableInfiniteLoading);

            for(var i = 0; i < productResponse.productData.length; i++) {
                var product = productResponse.productData[i];
                var priceBookEntry = productResponse.priceData[product.Id];

                // Apply a price to the datatable object
                if(priceBookEntry) {
                    product.listPrice = priceBookEntry.UnitPrice;    
                } else {
                    product.listPrice = 0;
                }

                // If this product has previously been selected, 
                // make sure it is in the currently selected ids
                if(product.Id in selectedProducts) {
                    if(!selectedRowsIds.includes(product.Id)) {
                        selectedRowsIds.push(product.Id);    
                    }
                }
                component.set("v.selectedRows", selectedRowsIds);
                
                products.push(product);
            }
            component.set('v.data', products);
        }))
        .catch($A.getCallback(function(error) {
            console.log(error.message);
        }));
    },

    getSelectedProductsList: function(selectedProducts) {
        var selectedProductsList = [];
        for(var productId in selectedProducts) {
            var selectedProduct = selectedProducts[productId];
            selectedProduct.label = selectedProduct.Name;
            selectedProduct.name = selectedProduct.Id;
            selectedProduct.type = 'icon';
            selectedProduct.iconName = 'standard:product';
            selectedProductsList.push(selectedProduct);
        }
        return selectedProductsList;
    },

    executeAction: function(component, actionName, params) {
        return new Promise($A.getCallback(function(resolve, reject) {
            var action = component.get(actionName);

            action.setParams(params);
            action.setCallback(this, function(response) {
                if (component.isValid() && response.getState() === 'SUCCESS') {
                    resolve(response.getReturnValue());
                } else {
                    reject(response.getError()[0]);
                }
            });
            $A.enqueueAction(action);
        }));
    }
})