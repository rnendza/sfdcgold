({
afterRender: function (component, helper) {
     // if(component.find("mainContainer").getElement() != null){
               if(component.get('v.userInfo.ProfileId')!='00e1I000000ZxflQAC' || component.get('v.userInfo.ProfileId')!='00e1I000000mcVaQAI'){

        this.superAfterRender();
        var targetEl = component.find("mainContainer").getElement();
        targetEl.addEventListener(
           "touchmove", 
            helper.scrollStopPropagation, 
           true // we use capture!
       );
               }
        if(component.get('v.userInfo.ProfileId')=='00e1I000000ZxflQAC' || component.get('v.userInfo.ProfileId')=='00e1I000000mcVaQAI'){
     this.superRerender();
           var targetE2 = component.find("mainContainer1").getElement();
        targetE2.addEventListener(
           "touchmove", 
            helper.scrollStopPropagation, 
          true // we use capture!
       );
          }
    
      }
 /* else if(component.find("mainContainer1").getElement() != null){
           var targetE2 = component.find("mainContainer1").getElement();
        targetE2.addEventListener(
           "touchmove", 
            helper.scrollStopPropagation, 
           true // we use capture!
       );
    }
}*/,
    
      rerender: function(component, helper){
          if(component.get('v.userInfo.ProfileId')=='00e1I000000ZxflQAC' || component.get('v.userInfo.ProfileId')=='00e1I000000mcVaQAI'){
     this.superRerender();
           var targetE2 = component.find("mainContainer1").getElement();
        targetE2.addEventListener(
           "touchmove", 
            helper.scrollStopPropagation, 
          true // we use capture!
       );
          }
      }
})