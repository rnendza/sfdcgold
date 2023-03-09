({
	//searchHelper : function(component,event,getinputKeyword) {
        
      //  var action = component.get("c.getAssets");
      //  action.setParams({
       //     'searchKeyWord': getinputKeyword
       // });
       // action.setCallback(this, function(response) {
                           //var state = response.getState();
            				//if(state === 'SUCCESS'){
                             //   var storeResponse = response.getReturnValue();
                             //   if(storeResponse.length == 0) {
                              //      component.set("v.Message",'No Result Found...');
                              //  } else{
                               //     component.set("v.Message", 'Search Results...');
                               // }
                                
                              //  component.set("v.listOfSearchRecords",storeResponse);
                              //  }
                          //  });
        					//$A.enqueueAction(action);
                          // },
                          // 
    	EvalAccount: function(Account, SAS){
        if(Account){
            if(SAS==='5'){
                if (Account.VGT_5__r){
                    return Account.VGT_5__r;
                }
            }
        }  
    },
        
    LineItems: function(component, event, helper){
        var yes = component.get('V.Details');
        
        //component.find('WorkOrder').submit();
        //component.find('Acc').submit();
       var one=  component.find('Status').get('v.value');
       var two =  component.find('Status2').get('v.value');
       var three =  component.find('Status3').get('v.value');
       var four =  component.find('Status4').get('v.value');
        var five = component.find('Status5').get('v.value');
        var six = component.find('RedStatus').get('v.value');
        
        
        //alert(five);
        
      //  component.find('one').submit();
       // component.find('two').submit();
       // component.find('three').submit();
       // component.find('four').submit();
       // component.find('five').submit();
        //var six = component.find('Status6').get('v.value');
  		
      if (component.find('Model1').get('v.value')!='' && one=='') {

            alert("Select PM Status for Position:1");
            
        }
    

 else if (component.find('Model2').get('v.value')!='' && two=='')   {

           alert("Select PM Status for Position:2");
          
        }
    		
        
	else if (component.find('Model3').get('v.value')!='' && three ==''){
   
            alert("Select PM Status for Position:3");
        
        }


     else  if (component.find('Model4').get('v.value')!=''  && four==''){
   
           alert("Select PM Status for Position:4");  
         
        }

        

     else   if (component.find('Model5').get('v.value')!=''  && five==''){
             alert("Select PM Status for Position:5");
         
        }


       else  if (component.find('RedModel').get('v.value')!=''  && six=='') {
   
               alert("Select PM Status for the Redemption Terminal")
           
        }
        else{
            if (component.find('Model1').get('v.value')!=''){
               component.find('one').submit();  
            }
             if (component.find('Model2').get('v.value')!=''){
               component.find('two').submit();  
            }
           if (component.find('Model3').get('v.value')!=''){
               component.find('three').submit();  
            } 
             if (component.find('Model4').get('v.value')!=''){
               component.find('four').submit();  
            } 
          if (component.find('Model5').get('v.value')!=''){
               component.find('five').submit();  
            }
            
              if (component.find('Model6').get('v.value')!=''){
               component.find('six').submit();  
            }
              if (component.find('Model7').get('v.value')!=''){
               component.find('seven').submit();  
            }
              if (component.find('Model8').get('v.value')!=''){
               component.find('eight').submit();  
            }
            
              if (component.find('Model9').get('v.value')!=''){
               component.find('nine').submit();  
            }
            
            if (component.find('Model10').get('v.value')!=''){
               component.find('ten').submit();  
            }
 if (component.find('RedModel').get('v.value')!=''){
               component.find('red').submit();  
  }
            
             if (component.find('RedModel2').get('v.value')!=''){
               component.find('red2').submit();  
  }
    
            //component.find('six').submit(); 
        
       
        
       // var got =   component.find('Grade').get('v.value');     
   //var hot =  component.find('SiteNote').get('v.value');
        
 
      var Id =   component.get("v.recordId");
            alert('Work Order Id: '+Id);
        //component.find('six').submit();
        // component.set("v.SaveDisable", true);
     
      // var recId = component.get('V.Details');
     //   var ids = recId.Id;
         // var Acc = component.find('Account').get('v.value');
   /* var urlRedirect= $A.get("e.force:navigateToURL");
       // console.log(urlRedirect);
        urlRedirect.setParams({
            "url": '/lightning/r/WorkOrder/' + '0WO7A000000DhoWWAS'
        });
        urlRedirect.fire(); */
    
      //setTimeout(function(){ window.location ='/lightning/page/home'; }, 3000);
       
   //   setTimeout(function(){ window.location ='/lightning/r/WorkOrder/'+Id+'/view/';}, 7000); //+"&output=embed"
   //   
   	//	 var navService = component.find("navService");
        // Uses the pageReference definition in the init handler
    //    var pageReference = component.get("v.pageReference");
     //   event.preventDefault();
     //   
         //Find the text value of the component with aura:id set to "address"
 //   var address = component.find("address").get("v.value");

   /* var urlEvent = $A.get("e.force:navigateToSObject");
    urlEvent.setParams({
     "recordId": Id,
      "slideDevName": "Detail"
    });*/
            
  var urlEvent = $A.get("e.force:navigateToURL");
    urlEvent.setParams({
       // "url":"/" + '01Z1I000000fA94UAE'
       "url":"/" +'01Z1I000000fAKbUAM'
    });
    
            setTimeout(function(){urlEvent.fire();},1000); 
            
      //  }
        }  
    },
    
    
    
    CreateWorkOrder: function(component, event, helper){
      //  console.log('hello again');
       // var PMStat1 = component.find("PMStat1");
       // alert(PMStat1);
         //componet.find('Status').set('v.value', PMStat1);
         //
         //
       
		//component.find('AmusementPic').set('v.value', component.find('Amusement').get('v.value'));
       // component.find('Real-pic').set('v.value', component.find('Special-P').get('v.value'));
       component.find('Status').set('v.value', component.find('Astatus').get('v.value'));  
       component.find('realsp').set('v.value',component.find('specialproject').get('v.value'));
        component.find('CallSign').set('v.value', component.find('CheckCallSign').get('v.value'));
      //  component.find('HideEquipment').set('v.value', equipment);
        
	    component.find('CitySticker1').set('v.value', component.find('Sticker1').get('v.value'));
            component.find('CitySticker2').set('v.value', component.find('Sticker2').get('v.value'));
            component.find('CitySticker3').set('v.value', component.find('Sticker3').get('v.value'));
            component.find('CitySticker4').set('v.value', component.find('Sticker4').get('v.value'));
            component.find('CitySticker5').set('v.value', component.find('Sticker5').get('v.value'));
            component.find('CitySticker6').set('v.value', component.find('Sticker6').get('v.value'));
            component.find('CitySticker7').set('v.value', component.find('Sticker7').get('v.value'));
            component.find('CitySticker8').set('v.value', component.find('Sticker8').get('v.value'));
            component.find('CitySticker9').set('v.value', component.find('Sticker9').get('v.value'));
            component.find('CitySticker10').set('v.value', component.find('Sticker10').get('v.value'));
            component.find('CitySticker11').set('v.value', component.find('Sticker11').get('v.value'));
        	component.find('CityStickerten').set('v.value', component.find('Stickerten').get('v.value'));
            //component.find('CitySticker1').set('v.value', component.find('Sticker1').get('v.value'));

        
        
         component.find('Status2').set('v.value', component.find('Astatus2').get('v.value'));  
         component.find('Status3').set('v.value', component.find('Astatus3').get('v.value'));  
         component.find('Status4').set('v.value', component.find('Astatus4').get('v.value'));  
         component.find('Status5').set('v.value', component.find('Astatus5').get('v.value'));  
         component.find('Status6').set('v.value', component.find('Astatus6').get('v.value'));  
         component.find('Status7').set('v.value', component.find('Astatus7').get('v.value'));
         component.find('Status8').set('v.value', component.find('Astatus8').get('v.value')); 
         component.find('Status9').set('v.value', component.find('Astatus9').get('v.value')); 
        component.find('Status10').set('v.value', component.find('Astatusten').get('v.value'));
         component.find('RedStatus').set('v.value', component.find('Astatus10').get('v.value'));  
         component.find('RedStatus2').set('v.value', component.find('Astatus11').get('v.value'));  
        
         var one=  component.find('Status').get('v.value');
       // alert(one)
       var two =  component.find('Status2').get('v.value');
       var three =  component.find('Status3').get('v.value');
       var four =  component.find('Status4').get('v.value');
        var five = component.find('Status5').get('v.value');
         var six = component.find('Status6').get('v.value');
         var seven = component.find('Status7').get('v.value');
         var eight = component.find('Status8').get('v.value');
         var nine = component.find('Status9').get('v.value');
        var ten = component.find('Status10').get('v.value');
        var red = component.find('RedStatus').get('v.value');
        var red2 = component.find('RedStatus2').get('v.value');
        
	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
				
				today = mm + '/' + dd + '/' + yyyy;
                
               
    
   var got = component.find('Grade').get('v.value');     
   var hot = component.find('SiteNote').get('v.value'); 
        var time = component.find('Duration').get('v.value');
	    //alert(hot);    
        component.set('v.Sites', hot);
       // alert(component.get('v.Sites'));
        component.find('Site_Grade').set('v.value', got);
       component.find('Site_Notes').set('v.value', hot); 
       // component.find('PmDate').set('v.value', today);
        
        var Grade = component.find('Site_Grade').get('v.value');
        var Acc = component.find('Account').get('v.value');
        
           component.find('WorkStatus').set('v.value','Completed');
        
           if(component.find('Grade').get('v.value')=='N/A( Location Closed)' && component.find('specialproject').get('v.value')==false){
              component.find('WorkStatus').set('v.value','New');
          }
        
        
        if(Acc ===null){
            alert('Select An Account');
        }
		
       
        
         else if (component.find('Model1').get('v.value')!='' && (one=='' || one==' ')&& component.find('specialproject').get('v.value')==false) {

            alert("Select PM Status for Position:1");
            
        }


 else if (component.find('Model2').get('v.value')!='' && (two=='' || two==' ')&& component.find('specialproject').get('v.value')==false)   {

           alert("Select PM Status for Position:2");
          
        }
    		
        
	else if (component.find('Model3').get('v.value')!='' && (three =='' || three==' ')&& component.find('specialproject').get('v.value')==false){
   
            alert("Select PM Status for Position:3");
        
        }


     else  if (component.find('Model4').get('v.value')!=''  && (four=='' || four==' ')&& component.find('specialproject').get('v.value')==false){
   
           alert("Select PM Status for Position:4");  
         
        }

        

     else   if (component.find('Model5').get('v.value')!=''  && (five=='' || five==' ')&& component.find('specialproject').get('v.value')==false){
             alert("Select PM Status for Position:5");
         
        }
        
         else   if (component.find('Model6').get('v.value')!=''  && (six=='' || six==' ')&& component.find('specialproject').get('v.value')==false){
             alert("Select PM Status for Position:6");
         
        }
        
         else   if (component.find('Model7').get('v.value')!=''  && (seven=='' || seven==' ')&& component.find('specialproject').get('v.value')==false){
             alert("Select PM Status for Position:7");
                    
        }
        
         else   if (component.find('Model8').get('v.value')!=''  && (eight=='' || eight==' ')&& component.find('specialproject').get('v.value')==false){
             alert("Select PM Status for Position:8");
         
        }
        
         else   if (component.find('Model9').get('v.value')!=''  && (nine=='' || nine==' ')&& component.find('specialproject').get('v.value')==false){
             alert("Select PM Status for Position:9");
         
        }

         else   if (component.find('Model10').get('v.value')!=''  && (ten=='' || ten==' ') && component.find('specialproject').get('v.value')==false ){
             alert("Select PM Status for Position:10");
         
        }

       else  if (component.find('RedModel').get('v.value')!=''  && (red=='' || red==' ') && component.find('specialproject').get('v.value')==false) {
   
               alert("Select PM Status for the Redemption Terminal")
           
        }
        
        
        
           else  if (component.find('RedModel2').get('v.value')!=''  && (red2=='' || red2==' ')&& component.find('specialproject').get('v.value')==false) {
   
               alert("Select PM Status for the Redemption Terminal 2")
           
        }
        
       else  if ((one =='Incomplete' || one =='NotComplete') && (component.find('Notes1').get('v.value'))==" "){
              alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:1');
        }
        else if ((two =='Incomplete' || two =='NotComplete') && component.find('Notes 2').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:2');
        }
        
           else  if ((three =='Incomplete' || three =='NotComplete') && component.find('Notes 3').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:3');
        }
        
         else  if ((four =='Incomplete' || four =='NotComplete') && component.find('Notes 4').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:4');
        }
        
         else  if ((five =='Incomplete' || five =='NotComplete') && component.find('Notes 5').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:5');
        }
        
         else if ((six =='Incomplete' || six =='NotComplete') && component.find('Notes 6').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:6');
        }
        
        else  if ((seven =='Incomplete' || seven =='NotComplete') && component.find('Notes 7').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:7');
        }
        
         else if ((eight =='Incomplete'|| eight =='NotComplete') && component.find('Notes 8').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:8');
        }
        
         else if ((nine =='Incomplete' || nine =='NotComplete') && component.find('Notes 9').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:9');
        }
        
        else if ((ten =='Incomplete' || ten =='NotComplete') && component.find('Notes ten').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Position:9');
        }
         else if ((red =='Incomplete' || red =='NotComplete') && component.find('Notes 10').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Redemption Terminal');
        }
        
           else if ((red2 =='Incomplete' || red2 =='NotComplete') && component.find('Notes 11').get('v.value')==" "){
            alert('Status = Not Complete OR Partially Completed. Enter Additional Notes for Redemption Terminal 2');
        }
        
      else if(Grade==="Select Choice") {
            alert('Select a Site Grade');
        }
        
       /*   else if(time== null){
              alert('Enter Total Time of PM Appointment(Hours.Minutes)');
          }*/
           
       else if(Grade==="N/A( Location Closed)" && component.find('SiteNote').get('v.value')=='') {
            alert('N/A OR Location Closed. Enter Site Notes');
        }
         
     
          else if(component.find('specialproject').get('v.value')==true && component.find('SiteNote').get('v.value')==''){
              alert('Enter Site Notes');
          }  
        

              else if(component.find('specialproject').get('v.value')==true && component.find('Real-pic').get('v.value')=='Select Choice'){
                  alert('Select Project Type');
              }
        
        
                
        
            else{
                         // component.find("Date/Time").set("v.value", today);
          component.find('WorkOrder').submit();
        //  component.find('HideAccount').submit();

           // component.set("v.Disable",true);
            // component.set('v.SaveDisable', false);
           alert('Creating New Work Order');
            component.set("v.SaveDisable", true);
            }
         
       // var payload = event.getParams().response;
      //  var recordId = payload.Id; //get record id
       // component.set("v.recordId", recordId);
         },
    
    
     scrollStopPropagation: function(e) {
        e.stopPropagation();
    },
    
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
	  // call the apex class method 
     var action = component.get("c.fetchLookUpValues");
      // set param to method  
        action.setParams({
            'searchKeyWord': getInputkeyWord,
            'ObjectName' : component.get("v.objectAPIName")
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
                // set searchResult list with return value from server.
                component.set("v.listOfSearchRecords", storeResponse);
            }
 
        });
      // enqueue the Action  
        $A.enqueueAction(action);
    
	},
    
	
})