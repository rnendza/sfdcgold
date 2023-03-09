/**
 * Created by Zach on 2/14/2019.
 */
({

    mobileMenuToggle:function(){
        var menu=document.getElementById('accel-mobile-menu-toggle');
        var btn = document.getElementById('menu-btn');
        if(btn.checked==true){

            menu.className += ' mobile-menu-visible';
        }else {

            menu.className = 'accel-mobile-menu';
        }


    }

})