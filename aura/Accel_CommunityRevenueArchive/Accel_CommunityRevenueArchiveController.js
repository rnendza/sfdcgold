/**
 * Created by ZacharyM on 3/14/2019.
 */
({

    doInit: function (cmp, evt, helper) {
        // https://accel-entertainment.monday.com/boards/286658657/
        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        //---
        helper.retrieveAccounts(cmp);
        // moved above to be sure avail for retrieve accounts
        // helper.collectionUtils = cmp.find('collectionUtils');
        // helper.loggingUtils = cmp.find('loggingUtils');
    },

    onChangeAccount: function (cmp, event, helper) {
        var selectedPlVal = event.getParam('value');
        cmp.set('v.selectedAccountId',selectedPlVal);
        if(selectedPlVal) {
            var accounts = cmp.get('v.userAccounts');
            var acc = helper.getAccountById(accounts,selectedPlVal);
            cmp.set('v.selectedAccount', acc);
            helper.retrieveFiles(cmp);
        }
    },

    onDateUpdated: function(cmp, event, helper){
        helper.retrieveFiles(cmp);
    }
})