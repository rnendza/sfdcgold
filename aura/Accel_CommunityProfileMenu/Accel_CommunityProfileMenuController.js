({
    /**
     * RJN Added. otherwise there was really no other way to get to My Settings in desktop mode.
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function(cmp,event,helper) {
      let desktopOpts = cmp.get('v.desktop_options');
      if(desktopOpts && desktopOpts.length > 0) {
          desktopOpts.push('My Settings');
      }
      cmp.set('v.desktop_options',desktopOpts);
    },
    handleClick : function(component, event, helper) {
        var source = event.getSource();
        var label = source.get("v.label");
        if(label=="My Settings"){
            // nav to My Settings Page
            helper.navToPage(component,'my-settings');
        }else if(label =="Logout"){
            //nav to Logout url
           // window.location.replace("https://uat-accelentertainment.cs78.force.com/community/secur/logout.jsp");
        }
        //------ RJN Added the below to allow logout
        var actionMenuCmp = component.find("actionMenu");
        if(actionMenuCmp) {
            var menuItemLabel = event.getSource().get('v.label').trim();
            switch ( menuItemLabel ) {
                case 'Logout':
                    helper.customLogout(component);
                    break;
                default :
            }
        }
    },
    handleCustomLogout: function(component, event, helper){
        helper.customLogout(component);
    }
})