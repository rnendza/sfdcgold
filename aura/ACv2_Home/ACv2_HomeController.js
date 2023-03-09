/**
 * Created by Zach on 3/19/2019.
 */
({
    doInit: function (cmp, evt, helper) {
        // https://accel-entertainment.monday.com/boards/286658657/
        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.formatUtils = cmp.find('formatUtils');
        helper.retrieveCommunityUserSettings(cmp);
      //===================> Moved call to callback of retrieveCommunitySettings  helper.retrieveAccounts(cmp);
        //helper.defaultSelectionDates(cmp);
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
    },
    scriptsLoaded: function (cmp, evt, helper) {
        if (typeof (echarts) == 'undefined') {
            alert(cmp, 'echarts not loaded!', 'error');
        } else {
            helper.log(cmp, 'echarts lib successfully loaded ', 'info');
           //----- moved to doInit / in retrieveCommunitySettings callback for timing reasons helper.retrieveHpdData(cmp);
            cmp.set('v.scriptsWereLoaded', true);
        }
    },
    onChangeAccount: function (cmp, event, helper) {
        var selectedVal = event.getParam('value');
        var graphType = cmp.get('v.selectedGraphBtn');
        cmp.set('v.selectedAccountId',selectedVal);
        var accounts = cmp.get('v.userAccounts');
        if(selectedVal) {
            if(selectedVal ==='All Locations' && graphType==='Daily'){
                helper.retrieveAllLocationsData(cmp);
                cmp.set('v.selectedAccount', '');
            }else if(selectedVal ==='All Locations' && graphType==='Monthly') {
                helper.retrieveMonthlyHpdData(cmp);
                cmp.set('v.selectedAccount', '');
            }else if(selectedVal ==='All Locations' && graphType==='YoY') {
                helper.retrieveAllYoyHpdData(cmp);
                cmp.set('v.selectedAccount', '');
            }else if(graphType==='Daily'){
                var selectedAccArrayIndex = helper.getAccountById(accounts,selectedVal);
                cmp.set('v.selectedAccount',selectedAccArrayIndex);
                cmp.set('v.selectedAccountType',selectedAccArrayIndex.Location_Type__c);
                helper.retrieveDailyAvgData(cmp);
            }else if(graphType==='Monthly'){
                var selectedAccArrayIndex = helper.getAccountById(accounts,selectedVal);
                cmp.set('v.selectedAccount',selectedAccArrayIndex);
                cmp.set('v.selectedAccountType',selectedAccArrayIndex.Location_Type__c);
                helper.retrieveMonthlyAvgData(cmp);
            }else if(graphType==='YoY'){
                var selectedAccArrayIndex = helper.getAccountById(accounts,selectedVal);
                cmp.set('v.selectedAccount',selectedAccArrayIndex);
                cmp.set('v.selectedAccountType',selectedAccArrayIndex.Location_Type__c);
                helper.retrieveSingleYoyHpdData(cmp);
            }
        }
    },
    handleGraphBtn: function(cmp, event, helper){
        if (event) {
            helper.processGraphButtonClick(cmp, event);
        }
    }



})