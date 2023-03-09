({
    
    doInit : function(component, event, helper){
     var action = component.get("c.fetchUser");
        action.setCallback(this, function(response){
            var state = response.getState();
            if (state==='SUCCESS'){
                var storeResponse = response.getReturnValue();
              //  alert(storeResponse.ProfileId);
              component.set('v.userInfo', storeResponse);
            }
        });
$A.enqueueAction(action);
        
    },

        
	 selectRecord : function(component, event, helper){      
    // get the selected record from list  
      var getSelectRecord = component.get("v.oRecord");
    // call the event   
      var compEvent = component.getEvent("oSelectedRecordEvent");
    // set the Selected sObject Record to the event attribute.  
         compEvent.setParams({"recordByEvent" : getSelectRecord });  
    // fire the event  
    //alert(getSelectRecord.VGT_1__r.Name);
         compEvent.fire();
         
         
    },
    
    setevent : function(component,event, helper){
       var getSelectAccount = component.get("v.accountId");
    // call the event   
    // var compEvent = component.getEvent("GetAccount");
    // set the Selected Account to the event attribute.  
     //   compEvent.setParams({OneAccount : getSelectAccount });  
    // fire the event  
     //   compEvent.fire();
        
        
       return getSelectAccount;
    },
    
    SpecialProject : function(cmp,event, helper){
        
        var action = cmp.get('c.fetchLookUpValues');
            var val =  event.getParam('Value');

            cmp.set('v.CheckParam', val);
      //  action.setParams({
         //   CheckParam: val
      //  });

     //   $A.enqueueAction(action);

        
      //  alert(action);

       // alert('This Is A Test');
        
 
        
        //alert(val);
        
        
    },

    
    
    
    
    
    
    handleStatusChange : function (component, event) {
10
      if(event.getParam("status") === "FINISHED") {
11
         // Get the output variables and iterate over them
12
         var outputVariables = event.getParam("outputVariables");
13
         var outputVar;
14
         for(var i = 0; i < outputVariables.length; i++) {
15
            outputVar = outputVariables[i];
16
            // Pass the values to the component's attributes
17
            if(outputVar.name === "AccountName") {
18
               component.set("v.AccountName", outputVar.value);
19
            } else {
20
              return null;
21
            }
22
         }
23
      }
        
24
   },
    
  onfocus : function(component,event,helper){
       $A.util.addClass(component.find("mySpinner"), "slds-show");
        var forOpen = component.find("searchRes");
            $A.util.addClass(forOpen, 'slds-is-open');
            $A.util.removeClass(forOpen, 'slds-is-close');
        // Get Default 5 Records order by createdDate DESC  
         var getInputkeyWord = '';
         helper.searchHelper(component,event,getInputkeyWord);
    },
    onblur : function(component,event,helper){       
        component.set("v.listOfSearchRecords", null );
        var forclose = component.find("searchRes");
        $A.util.addClass(forclose, 'slds-is-close');
        $A.util.removeClass(forclose, 'slds-is-open');
    },
    keyPressController : function(component, event, helper) {
       // get the search Input keyword   
         var getInputkeyWord = component.get("v.SearchKeyWord");
       // check if getInputKeyWord size id more then 0 then open the lookup result List and 
       // call the helper 
       // else close the lookup result List part.   
        if( getInputkeyWord.length > 0 ){
             var forOpen = component.find("searchRes");
               $A.util.addClass(forOpen, 'slds-is-open');
               $A.util.removeClass(forOpen, 'slds-is-close');
            helper.searchHelper(component,event,getInputkeyWord);
        }
        else{  
             component.set("v.listOfSearchRecords", null ); 
             var forclose = component.find("searchRes");
               $A.util.addClass(forclose, 'slds-is-close');
               $A.util.removeClass(forclose, 'slds-is-open');
          }
	},
    
  // function for clear the Record Selaction 
    clear :function(component,event,heplper){
         var pillTarget = component.find("lookup-pill");
         var lookUpTarget = component.find("lookupField"); 
        
         $A.util.addClass(pillTarget, 'slds-hide');
         $A.util.removeClass(pillTarget, 'slds-show');
        
         $A.util.addClass(lookUpTarget, 'slds-show');
         $A.util.removeClass(lookUpTarget, 'slds-hide');
      
         component.set("v.SearchKeyWord",null);
         component.set("v.listOfSearchRecords", null );
         component.set("v.selectedRecord", {} );   
    },
    
    getvalues:function(component, event, helper){
        var values = component.get("v.selectedRecord");
        return values;
    },
    
  // This function call when the end User Select any record from the result list.   
    handleComponentEvent : function(component, event, helper) {
        
        
 // get the selected Account record from the COMPONETN event 	 
       var selectedAccountGetFromEvent = event.getParam("recordByEvent");
        //alert(selectedAccountGetFromEvent);
	   component.set("v.selectedRecord" , selectedAccountGetFromEvent); 
        
/*         var appEvent = component.getEvent("WellAccount");
        
        appEvent.setParams({"Account":selectedAccountGetFromEvent});
        
        appEvent.fire();*/
           if(component.get('v.userInfo.ProfileId') != '00e1I000000ZxflQAC' && component.get('v.userInfo.ProfileId') != '00e1I000000mcVaQAI' ){
        
        var GetAcc = component.getEvent("GetAccount");
        GetAcc.setParams({"OneAccount" : selectedAccountGetFromEvent});
        GetAcc.fire();

           }
        
        
      
     //   alert('test');
        if(component.get('v.userInfo.ProfileId') === '00e1I000000ZxflQAC' || component.get('v.userInfo.ProfileId') == '00e1I000000mcVaQAI' ){
        
        
        
            
            var applicationEvent = $A.get("e.c:WellnessValue");
    applicationEvent.setParams({"Account" : selectedAccountGetFromEvent})
    applicationEvent.fire();
            
              
        /* var Get12 = component.getEvent("WellAccount");
        Get12.setParams({"Account" : selectedAccountGetFromEvent});
       
        Get12.fire();*/
       // alert('test');
       
        }
        
     
			/* var appEvent = $A.get("e.c:WellnessValue");
                 
                appEvent.setParam(
                    'Account',selectedAccountGetFromEvent);
              //  appEvent.setParam('Account', 'Test');
				
                appEvent.fire();*/
          //   alert(appEvent);
            
           

       // alert(selectedAccountGetFromEvent.Id);
       //ert(selectedAccountGetFromEvent.VGT_1__r.Name);
        component.set('v.accountId', selectedAccountGetFromEvent.Id);
       
        var forclose = component.find("lookup-pill");
           $A.util.addClass(forclose, 'slds-show');
           $A.util.removeClass(forclose, 'slds-hide');
  
        var forclose = component.find("searchRes");
           $A.util.addClass(forclose, 'slds-is-close');
           $A.util.removeClass(forclose, 'slds-is-open');
        
        var lookUpTarget = component.find("lookupField");
            $A.util.addClass(lookUpTarget, 'slds-hide');
            $A.util.removeClass(lookUpTarget, 'slds-show');  
       
      
	},
    
    wellnessEvent : function(component, event, helper){
 alert('Test');         
            var val =  event.getParam('Visit');

            component.set('v.true', val);
        alert(component.get('v.true'));
    },
    
    

	
})