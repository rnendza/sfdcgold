/**
 * Created by Zach on 2/14/2019.
 */
({
    customLogout: function( cmp ) {
        console.log('logging out');
        var logoutEvent =  $A.get("e.c:Accel_CustomLogoutEvent");
        logoutEvent.fire();
    },
    navToSettings: function(cmp){
        console.log('firing settings page load');
        let urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({"url": '/my-settings'});
        urlEvent.fire();
    }

})