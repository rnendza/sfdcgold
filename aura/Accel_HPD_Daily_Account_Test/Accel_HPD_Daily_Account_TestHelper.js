({
    retrieveAccountsHpds: function (cmp) {
        var self = this;
        var action = cmp.get('c.retrieveAccountHpds');

        action.setCallback(this, $A.getCallback(function (response) {
            var self = this;
            var state = response.getState();
            var accounts = [];
            if (state === "SUCCESS") {
                var hpds  = response.getReturnValue();
            } else if (state === "ERROR") {
                var errors = response.getError();
                console.log(JSON.stringify(errors));
            }
        }));
        //self.log(cmp, 'Enqueuing call to accounts', 'info');
        $A.enqueueAction(action);
    }
})