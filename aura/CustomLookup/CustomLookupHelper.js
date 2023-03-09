({
	    
    AccountHelper: function(component, AccountId) {
        var action = component.get("c.getAccount");
        action.setParams({
            'key' : AccountId});
        action.setCallback(this,function(response){
            var state = response.getState();
            var Store = response.getReturnValue();
           
                component.set("v.AccountAsset".VGT_1__c,Store);
           
        });
        $A.enqueueAction(action);
        },
    
    
    
    
        Redirect : function(component, event, helper) {
    //var payload = event.getParams().response;
    var navService = component.find("navService");
	//var recId = Component.get("v.recordId");
    var pageReference = {
        type: 'standard__recordPage',
        attributes: {
            "recordId": Component.get("v.recordId"),
            "objectApiName": "WorkOrder",
            "actionName": "view"
        }
    }
    event.preventDefault();
    navService.navigate(pageReference);  
    }, 

    searchHelper : function(component,event,getInputkeyWord) {
         if(component.get('v.userInfo.ProfileId') === '00e1I000000ZxflQAC' || component.get('v.userInfo.ProfileId') ===  '00e1I000000mcVaQAI'){
                    component.set('v.CheckParam', 'Other');
                }
        
       if( component.get('v.userinfo.ProfileId') === '00e1I000000mcVaQAI'){
 component.set('v.CheckParam', 'Other');
        }
                   
		 if(component.get('v.userInfo.ProfileId') === '00e1I000000NeZSQA0' && component.get('v.CheckParam')=== 'No'){
                    component.set('v.CheckParam', 'Other');
                }
        //alert(component.get('v.CheckParam'));
	  // call the apex class method 
     var action = component.get("c.fetchLookUpValues");
      // set param to method  
      var setName = component.get("c.getUserName");
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName' : component.get("v.objectAPIName"),
            'CheckParam' : component.get('v.CheckParam')
          });
      // set a callBack    
        action.setCallback(this, function(response) {
          $A.util.removeClass(component.find("mySpinner"), "slds-show");
            var state = response.getState();
            if (state === "SUCCESS") {
                var storeResponse = response.getReturnValue();
              // if storeResponse size is equal 0 ,display No Result Found... message on screen.                }
                if (storeResponse.length == 0) {
                    component.set("v.Message", 'No Result Found...');
                } else {
                    component.set("v.Message", '');
                }
                console.log(storeResponse);
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
 
        });
      // enqueue the Action  
        $A.enqueueAction(action);
    
	},
})