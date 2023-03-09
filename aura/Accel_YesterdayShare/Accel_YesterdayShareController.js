/**
 * Created by Zach on 3/4/2019.
 */
({
    doInit: function (cmp,evt,helper) {

        /**
         *  Try to assist with Race error between init and scripts loaded below
         *  @see https://accel-entertainment.monday.com/boards/286658657/pulses/4021384789
         */
        cmp.set('v.communityUserSettings',{});

        helper.friendlyErrorMsg = $A.get("$Label.c.Community_Friendly_Error");
        helper.collectionUtils = cmp.find('collectionUtils');
        helper.loggingUtils = cmp.find('loggingUtils');
        helper.uiMessagingUtils = cmp.find('uiMessagingUtils');
        helper.formatUtils = cmp.find('formatUtils');
        helper.retrieveCommunityUserSettings(cmp);
        helper.setNumAccs(cmp);

    },
    scriptsLoaded: function (cmp, evt, helper) {
        if (typeof (echarts) == 'undefined') {
            console.log('---> in scripts loaded eharts object is undefined!');
        } else {
            helper.retrieveAllYesterdayData(cmp);

            window.addEventListener('resize', $A.getCallback(function () {
                if (cmp.isValid()) {
                    helper.windowResizing(cmp, evt, helper);
                }
            }));
            cmp.set('v.scriptsWereLoaded', true);
        }
    },
    changeGraph: function(cmp, evt, helper){
        helper.processBtnClick(cmp, evt, helper);
    },

    changeTab: function(cmp, evt, helper){
        helper.processTabChange(cmp, evt);
    }
})