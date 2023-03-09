({
    onClick : function(component, event, helper) {
        var id = event.target.dataset.menuItemId;
        if (id && id!=="Logout" && id!=="Settings") {
            component.getSuper().navigate(id);
            var menu=document.getElementById('accel-mobile-menu-toggle');
            var btn = document.getElementById('menu-btn');
            menu.className = 'accel-mobile-menu';
            btn.checked=false;
        }else if(id === "Logout"){
            helper.customLogout(component);
        }else if(id === "Settings"){
            helper.navToSettings(component);
            var menu=document.getElementById('accel-mobile-menu-toggle');
            var btn = document.getElementById('menu-btn');
            menu.className = 'accel-mobile-menu';
            btn.checked=false;
        }
    }
})