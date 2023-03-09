({
    getColumnDefinitions: function () {
        var columns = [
            {label: 'Product', fieldName: 'productUrl', type: 'url', typeAttributes: {label: { fieldName: 'productName'}}, editable: false},
            {label: 'Quantity', fieldName: 'Quantity__c', type: 'number', typeAttributes: { required: true }, editable: true},
            {
                label: 'Date', fieldName: 'Service_Date__c', type: 'date-local', editable: true,
                typeAttributes: {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric'
                }
            },
            {label: 'Line Description', fieldName: 'Description__c', type: 'text', editable: true}
        ];

        return columns;
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