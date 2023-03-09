/**
 * Created by Zach on 4/8/2019.
 */
({

    doInit: function (cmp, evt, helper) {
        // https://accel-entertainment.monday.com/boards/286658657/
        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        //---
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.formatUtils = cmp.find('formatUtils');
        helper.retrieveCommunityUserSettings(cmp);
        //helper.retrieveLocTypes(cmp);
        let locs = ['Bar', 'Restaurant', 'C-Store', 'Truck Stop', 'Gaming Parlor', 'Fraternal/VFW', 'Other'];
        cmp.set('v.locTypes', locs);
        helper.initColumns(cmp);
        cmp.find('radius').set('v.value', "2");
        cmp.set('v.distance',"2");

    },
    scriptsLoaded: function (cmp, evt, helper) {
        window.addEventListener('resize', $A.getCallback(function () {
            if (cmp.isValid()) {
                helper.windowResizing(cmp, evt, helper);
            }
        }));
       helper.retrieveAccounts(cmp);
       cmp.set('v.scriptsWereLoaded', true);

    },
    changeFilters: function(cmp, evt, helper){
        helper.processBtnClick(cmp, evt, helper);
    },
    onChangeAccount: function(cmp, evt, helper){
        helper.setCoords(cmp);
        helper.retrieveRadiusHpds(cmp, 'Radius');
    },
    onChangeLocType: function(cmp, evt, helper){
        cmp.set('v.accountType', evt.getSource().get('v.value'));
        helper.retrieveRadiusHpds(cmp, 'Radius');
    },
    onChangeRadius: function(cmp, evt, helper){
        cmp.set('v.distance', evt.getSource().get('v.value'));
        helper.retrieveRadiusHpds(cmp, 'Radius');
    },
    handleSearch: function(cmp, evt, helper){
        if(evt.which === 13){
            let searchVal = cmp.find("map-search").get("v.value");
            helper.retrieveCity(cmp, searchVal);
        }
    }
})