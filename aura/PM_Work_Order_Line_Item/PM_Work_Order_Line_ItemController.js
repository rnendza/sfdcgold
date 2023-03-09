({
	doInit : function(component, event, helper) {
  
    	component.set('v.Disable5', true);
        component.set('v.Disable7', true);
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
        
        
        
      var lookup = component.find('hideLookup');
     var close = component.find('HideClosed');

        var equipment = component.find('EquipmentClass');
        $A.util.addClass(equipment, "toggle14");

       // alert(component.get('v.Details'));
      //  var check = component.find('Hidecheck');
        var picklist = component.find('HidePicklist');
         $A.util.addClass(picklist,'toggle15');
        $A.util.addClass(close,'toggle14');
   //     $A.util.addClass(check,'toggle13');
   //     
   var Check1 =  component.find('HideSticker');
          	$A.util.addClass(Check1, "toggle16");
        	$A.util.addClass(lookup, "toggle16");
        
          component.set('v.SaveDisable', false);
        component.set('v.Disable',false);
        
          var Check1 =  component.find('HideSticker');
        var Check2 =  component.find('HideSticker2');
        var Check3 =  component.find('HideSticker3');
        var Check4 =  component.find('HideSticker4');
        var Check5 =  component.find('HideSticker5');
        var Check6 =  component.find('HideSticker6');
        var Check7 =  component.find('HideSticker7');
        var Check8 =  component.find('HideSticker8');
        var Check9 =  component.find('HideSticker9');
        var Check10 =  component.find('HideSticker10');
        var Check11 =  component.find('HideSticker11');
        var Check12 = component.find('HideStickerten');
      
          	$A.util.addClass(Check1, "toggle16");
        $A.util.addClass(Check2, "toggle16");
        $A.util.addClass(Check3, "toggle16");
        $A.util.addClass(Check4, "toggle16");
        $A.util.addClass(Check5, "toggle16");
        $A.util.addClass(Check6, "toggle16");
        $A.util.addClass(Check7, "toggle16");
        $A.util.addClass(Check8, "toggle16");
        $A.util.addClass(Check9, "toggle16");
        $A.util.addClass(Check10, "toggle16");
        $A.util.addClass(Check11, "toggle16");
        $A.util.addClass(Check12, "toggle16");
        	
        
        
       // component.set('v.SaveDisable', true);
        console.log('Hello');
        
              var navService = component.find("navService");
        // Sets the route to /lightning/o/Account/home
        var pageReference = {
            type: 'standard__objectPage',
            attributes: {
                objectApiName: 'Account',
                actionName: 'home'
            }
        };
        
     var thing =  component.find('Status').get('v.value');
		       
        component.set('v.val',thing);
        component.set("v.pageReference", pageReference);
        
		       	
        
        if(component.get('v.userinfo.ProfileId') == '00e1I000000ZxflQAC'){
            var appEvent = $A.get("e.c:CheckBox");
                 
                 appEvent.setParam(
                     'Value','No');
                
				
                appEvent.fire();
            
             var wellnessEvent = $A.get("e.c:Wellness");
                 
                 wellnessEvent.setParam('Visit', 'Yes');
                     

				
                wellnessEvent.fire();
    
   

        }
        
       
        
        
	},
    
    SetValues : function(component, event, helper){
        	var equipment= 	component.find('AssetEquipment').get('v.value');
        
        component.find('HideEquipment').set('v.value', equipment);
       // alert( component.find('HideEquipment').get('v.value'));
        
    },
    
    Special : function(component, event, helper){
        component.find('Real-pic').set('v.value', component.find('Special-P').get('v.value'));
        
    },
    
    
    
    
     PMapp :function(component,event, helper){
  var lookup =    component.find('hideLookup');
      var hideClose =    component.find('HideClosed');  
           var hideCheck =    component.find('Hidecheck');  
        $A.util.removeClass(lookup, 'toggle16');
         $A.util.removeClass(hideClose, 'toggle14');
         $A.util.addClass(hideCheck, 'toggle16');
      //  component.set('v.selectedLookUpRecord','');
             if (component.find('PmApp').get('v.value')==true){
            //     component.set('v.selectedLookUpRecord','');
                 component.set('v.SaveDisable',false);
                 component.set('v.CheckDisable',false);
                 
                 
                 if(component.get('v.Details')!=null){
                // this.GetAccount(component,event, helper);
                     var a = component.get('c.GetAccount');
   				     $A.enqueueAction(a);
                 }
              	var appEvent = $A.get("e.c:CheckBox");
                 
                 appEvent.setParam("Value", "Yes");
                     

				
                appEvent.fire();
                 
                 
       
                 
                 if(component.find('Account').get('v.value')==null){
                    $A.util.addClass(hideClose, 'toggle14');
             }
                 if(component.find('Account').get('v.value')!=null){
                     $A.util.removeClass(hideClose, 'toggle14');
                 }
                 
             }
        
        
        if (component.find('PmApp').get('v.value')==false){
               $A.util.addClass(hideClose, 'toggle14');
            	 $A.util.addClass(lookup, 'toggle16');
            	$A.util.removeClass(hideCheck, 'toggle16');
            
           
                 
        //    component.set('v.SaveDisable',true);
        }
        
        
        
    },
    
    
    
    
    
    Amusement: function(component,event, helper){

        var equipment = component.find('EquipmentClass');
        if (component.find('Amusement').get('v.value')==='Amusement PM'){
            component.find('AmusementPic').set('v.value', component.find('Amusement').get('v.value'))
            $A.util.removeClass(equipment, "toggle14");
       }

        else{
            $A.util.addClass(equipment, 'toggle14');
            component.find('AmusementPic').set('v.value', component.find('Amusement').get('v.value'))
        }


    },
    
    
    
    
    
    
    
    Project :function(component,event, helper){
                  var lookup =  component.find('hideLookup');
            $A.util.removeClass(lookup, 'toggle16');

         var selectedAccountGetFromEvent = component.find('CustomLookup');
                var HideClose = component.find('HideClosed');
            
                //console.log(selectedAccountGetFromEvent);
               var test=selectedAccountGetFromEvent.Childmethod();
        		var recordval = selectedAccountGetFromEvent.Childmethod2();
   
                    var Hide1 = component.find('Hide1');
          var Hide2 = component.find('Hide2');
          var Hide3 = component.find('Hide3');
          var Hide4 = component.find('Hide4');
          var Hide5 = component.find('Hide5');
          var Hide6 = component.find('Hide6');
          var Hide7 = component.find('Hide7');
          var Hide8 = component.find('Hide8');
          var Hide9 = component.find('Hide9');
        	var Hide10 = component.find('Hide10');
           var HideRed = component.find('HideRed');
        var HideRed2 = component.find('HideRed2');
        

        
        
        if (component.find('specialproject').get('v.value')==true){
            
            
            	var appEvent = $A.get("e.c:CheckBox");
                 
                 appEvent.setParam(
                     'Value','Other');
                
				
                appEvent.fire();
            
              var Pm = component.find('PMCheck');
            $A.util.addClass(Pm, 'toggle16');
                 var picklist = component.find('HidePicklist');
         $A.util.removeClass(picklist,'toggle15');
            component.set("v.CheckDisable",true);
        component.find("realsp").set('v.value',true);
            
            $A.util.addClass(component.find("HideAll"), "toggle");

            
            
        
     component.find('Grade').set('v.value','N/A( Location Closed)');
        
  
        }
        
      
        
        else if (component.find('specialproject').get('v.value')==false){
       
            var equipment = component.find('EquipmentClass');
            $A.util.addClass(equipment, "toggle14");
          
            
            
                        $A.util.removeClass(component.find("HideAll"), "toggle");

            
            
             var picklist = component.find('HidePicklist');
         $A.util.addClass(picklist,'toggle15');
            
            
            var lookup =  component.find('hideLookup');
            
            $A.util.addClass(lookup,'toggle16');
                 var Pm = component.find('PMCheck');
            $A.util.removeClass(Pm, 'toggle16');
            
            
            
          
            if(component.get('v.Details')!=null){
           var numb = 1;
            
            
            
             var baction = component.get("c.getAsset");
   				//var Acc = component.find('Account').get('v.value');
   				 var yes = component.get('V.Details');
        //console.log(yes.Id);

         var stuff =   component.get('v.VGTL');
            
            
            
        if(numb!==2 && component.find("SAS1").get('v.value')!==''){ // if(yes.VGT_1__r.SAS__c!='1' && yes.VGT_2__r.SAS__c!='1' && yes.VGT_3__r.SAS__c!='1' && yes.VGT_4__r.SAS__c!='1' && yes.VGT_5__r.SAS__c!='1'){ //  
            component.find("Model1").set("v.value","");
                component.find("SAS1").set("v.value",""); 
                    component.find("Asset1").set("v.value", "");
 
          
        //    gotit = component.find('SAS1').get('v.value');
} 
         
            
          component.find('Grade').set('v.value','Select Choice');
     
                            
       
         if(yes.VGT_1__c){
         if (yes.VGT_1__r.SAS__c==="1"){
              
                   component.find("Model1").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_1__r.SAS__c); 
                    component.find("Asset1").set("v.value", yes.VGT_1__c);
              numb + 1;
           var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');

                }

         }
        
  
      
            if(yes.VGT_2__c){
                if(yes.VGT_2__r.SAS__c==="1"){
                     
                       component.find("Model1").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset1").set("v.value", yes.VGT_2__c);
                     numb + 1;
                   var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
               
                }
   
             }
       
          

        
        
              if(yes.VGT_3__c){
                    if(yes.VGT_3__r.SAS__c==="1"){
                      
                            component.find("Model1").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset1").set("v.value", yes.VGT_3__c);
                        numb + 1;
                     var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');

                    }
  
             }
                               
          

             
              if(yes.VGT_4__c){
                  if(yes.VGT_4__r.SAS__c==="1"){
                     
                            component.find("Model1").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset1").set("v.value", yes.VGT_4__c);
                     numb +1;
                    var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                  }
   
                    }
                      
   
                     
                   if(yes.VGT_5__c){
                     if(yes.VGT_5__r.SAS__c==="1"){
                          
                            component.find("Model1").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset1").set("v.value", yes.VGT_5__c);
                        numb +1;
               var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                     
                     }
  
		     }
                     

          

             
          if(yes.VGT_6__c){
                     if(yes.VGT_6__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_6__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
  
                   }
        
        
        
        
          if(yes.VGT_7__c){
                     if(yes.VGT_7__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_7__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
    
 
                   }
   
      
          
   
        
        
        
        if(yes.VGT_8__c){
                     if(yes.VGT_8__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_8__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
  
 
        
        if(yes.VGT_9__c){
                     if(yes.VGT_9__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_9__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
        if(yes.VGT_10__c){
                     if(yes.VGT_10__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_10__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
      
   
          
          //------------PoSITION 2--------------------//
        if(numb!==2 && component.find("SAS2").get('v.value')!==''){
             component.find("Model2").set("v.value","");
                component.find("SAS2").set("v.value",""); 
                    component.find("Asset2").set("v.value", "");
      
        
        }
        if(yes.VGT_1__r){
                 if (yes.VGT_1__r.SAS__c==="2"){
                   component.find("Model2").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_1__r.SAS__c); 
                        component.find("Asset2").set("v.value", yes.VGT_1__c);
                        var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                }
          }
 
        
       if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="2"){
                       component.find("Model2").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset2").set("v.value", yes.VGT_2__c);
                             var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                }
        }
  
       if(yes.VGT_3__r){
                    if(yes.VGT_3__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset2").set("v.value", yes.VGT_3__c);
                                var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                    }
        }

        
      if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset2").set("v.value", yes.VGT_4__c);
                              var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                    }
        
    }		
     
 if(yes.VGT_5__r){
                      if(yes.VGT_5__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset2").set("v.value", yes.VGT_5__c);
                                  var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                     }
    
          }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_6__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_7__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_8__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_9__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
          if(yes.VGT_10__r){
                     if(yes.VGT_9__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_10__c);
                            var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
     
                   }
              
                //-------------Position ------3////
                if(numb!==2 && component.find("SAS3").get('v.value')!==''){
             component.find("Model3").set("v.value","");
                component.find("SAS3").set("v.value",""); 
                    component.find("Asset3").set("v.value", "");
      
        
        }
             if(yes.VGT_1__r){
                if (yes.VGT_1__r.SAS__c==="3"){
                   component.find("Model3").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_1__r.SAS__c);
                     component.find("Asset3").set("v.value", yes.VGT_1__c);
                        var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');
            
                }
              }

       if(yes.VGT_2__r){
                if(yes.VGT_2__r.SAS__c==="3"){
                       component.find("Model3").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset3").set("v.value", yes.VGT_2__c);
                      var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                }
        }

       if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_3__r.SAS__c);
                         component.find("Asset3").set("v.value", yes.VGT_3__c);
       var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                    }
        }

	 if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset3").set("v.value", yes.VGT_4__c)
                         var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                    }
            
        }

      if(yes.VGT_5__r){
                      if(yes.VGT_5__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset3").set("v.value", yes.VGT_5__c)
                       var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                     }
                
             }
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_6__c);
                         var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_7__c);
                  var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_8__c);
                    var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_9__c);
               var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
   if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_10__c);
                            var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');
                            }
     
                   }
   
                //------------POSITION--4----------------///
                       if(numb!==2 && component.find("SAS4").get('v.value')!==''){
             component.find("Model4").set("v.value","");
                component.find("SAS4").set("v.value",""); 
                    component.find("Asset4").set("v.value", "");
           
        
        }
 if(yes.VGT_1__r){
                if (yes.VGT_1__r.SAS__c==="4"){
                   component.find("Model4").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_1__r.SAS__c); 
                     component.find("Asset4").set("v.value", yes.VGT_1__c);
              var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                }
 }

        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="4"){
                       component.find("Model4").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset4").set("v.value", yes.VGT_2__c);
              var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                }
        }
 
        if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_3__r.SAS__c);
                         component.find("Asset4").set("v.value", yes.VGT_3__c);
      var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                    }
        }

        
        if(yes.VGT_4__r){
                 if(yes.VGT_4__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset4").set("v.value", yes.VGT_4__c);
  var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                    }
        }

        if(yes.VGT_5__r){
        	
                     if(yes.VGT_5__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_5__c);
  var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                     }
                         }
     if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_6__c);
         var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_7__c);
            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_8__c);
            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_9__c);
             var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
         if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_10__c);
                            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
     
                   }
   
       //------------POSITION --5--------------------///
        
            //  var Hidesection1 = component.find('Hide5');
         //  $A.util.toggleClass(Hidesection1, "toggle5"); 
        

       
               if(numb!==2 && component.find("SAS5").get('v.value')!==''){
             component.find("Model5").set("v.value","");
                component.find("SAS5").set("v.value",""); 
                    component.find("Asset5").set("v.value", "");
        }
        
     
        
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="5"){
                   component.find("Model5").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset5").set("v.value", yes.VGT_1__c);
        var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');

                }
        }
        
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="5"){
                       component.find("Model5").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset5").set("v.value", yes.VGT_2__c);
             var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset5").set("v.value", yes.VGT_3__c);
                   var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset5").set("v.value", yes.VGT_4__c);
                 var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_5__c);
                var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_6__c);
                   var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_7__c);
           var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_8__c);
      var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_9__c);
                 var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_10__c);
                            var Hidesection5 = component.find('Hide5');
              $A.util.removeClass(Hidesection5, 'toggle5');
                            }
     
                   }
        //------------POSITION --6--------------------///
               if(numb!==2 && component.find("SAS6").get('v.value')!==''){
             component.find("Model6").set("v.value","");
                component.find("SAS6").set("v.value",""); 
                    component.find("Asset6").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="6"){
                   component.find("Model6").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset6").set("v.value", yes.VGT_1__c);
                 var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="6"){
                       component.find("Model6").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset6").set("v.value", yes.VGT_2__c);
                     var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset6").set("v.value", yes.VGT_3__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset6").set("v.value", yes.VGT_4__c);
                      var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_5__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_6__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_7__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_8__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_9__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection, "toggle6");
                            }
                   }
        
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_10__c);
                            var Hidesection6 = component.find('Hide6');
              $A.util.removeClass(Hidesection6, 'toggle6');
                            }
     
                   }
            //------------POSITION --7--------------------///
               if(numb!==2 && component.find("SAS7").get('v.value')!==''){
             component.find("Model7").set("v.value","");
                component.find("SAS7").set("v.value",""); 
                    component.find("Asset7").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="7"){
                   component.find("Model7").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset7").set("v.value", yes.VGT_1__c);
                 
                 var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="7"){
                       component.find("Model7").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset7").set("v.value", yes.VGT_2__c);
                     
                                 var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset7").set("v.value", yes.VGT_3__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset7").set("v.value", yes.VGT_4__c);
                      
                                  var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_5__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_6__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_7__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_8__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_9__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
         if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_10__c);
                            var Hidesection7 = component.find('Hide7');
              $A.util.removeClass(Hidesection7, 'toggle7');
                            }
     
                   }
            //------------POSITION --8--------------------///
               if(numb!==2 && component.find("SAS8").get('v.value')!==''){
             component.find("Model8").set("v.value","");
                component.find("SAS8").set("v.value",""); 
                    component.find("Asset8").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="8"){
                   component.find("Model8").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset8").set("v.value", yes.VGT_1__c);
                             var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                 
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="8"){
                       component.find("Model8").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset8").set("v.value", yes.VGT_2__c);
                                var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset8").set("v.value", yes.VGT_3__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset8").set("v.value", yes.VGT_4__c);
                                 var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_5__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_6__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_7__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_8__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_9__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
                
                
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_10__c);
                            var Hidesection8 = component.find('Hide8');
              $A.util.removeClass(Hidesection8, 'toggle8');
                            }
     
                   }
                
                
      if(numb!==2 && component.find("Asset6").get('v.value')!==''){
             component.find("Model6").set("v.value","");
            
                    component.find("Asset6").set("v.value", "");
            
        
        } 
        
            //------------POSITION --9--------------------///
               if(numb!==2 && component.find("SAS9").get('v.value')!==''){
             component.find("Model9").set("v.value","");
                component.find("SAS9").set("v.value",""); 
                    component.find("Asset9").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="9"){
                   component.find("Model9").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset9").set("v.value", yes.VGT_1__c);
                   var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="9"){
                       component.find("Model9").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset9").set("v.value", yes.VGT_2__c);
                     
                           var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset9").set("v.value", yes.VGT_3__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset9").set("v.value", yes.VGT_4__c);
                      
                            var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_5__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_6__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_7__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_8__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_9__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
            
             if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_10__c);
                            var Hidesection9 = component.find('Hide9');
              $A.util.removeClass(Hidesection9, 'toggle9');
                            }
     
                   }
                
                //------------POSITION --10--------------------///
               if(numb!==2 && component.find("SAS10").get('v.value')!==''){
             component.find("Model10").set("v.value","");
                component.find("SAS10").set("v.value",""); 
                    component.find("Asset10").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="10"){
                   component.find("Model10").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS10").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset10").set("v.value", yes.VGT_1__c);
                             var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                 
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="10"){
                       component.find("Model10").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS810").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset10").set("v.value", yes.VGT_2__c);
                                var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset10").set("v.value", yes.VGT_3__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS10").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset10").set("v.value", yes.VGT_4__c);
                                 var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_5__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_6__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_7__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_8__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_9__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
                
                
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_10__c);
                            var Hidesection10 = component.find('Hide10');
              $A.util.removeClass(Hidesection10, 'toggle12');
                            }
     
                   }
                
                
                
                
                
                
                
                
            
                 if(yes.Redemption__r){
            					numb +1;
                            component.find("Redemption").set("v.value",yes.Redemption__c);
                         component.find("RedModel").set('v.value',yes.Redemption__r.Model__c);
                     $A.util.removeClass(HideRed, "toggle10");
        }
            
           if(stuff){
                for (var i=0; i <stuff.length; i++){
                 var item = stuff[i];
                    //alert(item.Name);
                    //component.set('v.String','');
                    if (item.Id !== component.find('Redemption').get('v.value')){
                        component.find('RedModel2').set('v.value', item.Model__c);
                        component.find("Redemption2").set('v.value', item.Id);
                        component.set('v.String', item.Id);
                        //var gethide = component.find('HideRed2');
                        $A.util.removeClass(HideRed2,'toggle11');
                    }
                    
					                    
                         
            
                }
            
               //$A.util.addClass(HideRed2, "toggle11");
               }
            
            
            if(component.find('RedModel2').get('v.value')==null)
            {
                	$A.util.addClass(HideRed2,'toggle11');
            }
                
            }
            
        } 
        
},
    
    Hide :function(component,event, helper){
         var selectedAccountGetFromEvent = component.find('CustomLookup');
                
            
                //console.log(selectedAccountGetFromEvent);
               var test=selectedAccountGetFromEvent.Childmethod();
        		var recordval = selectedAccountGetFromEvent.Childmethod2();
   
                    var Hide1 = component.find('Hide1');
          var Hide2 = component.find('Hide2');
          var Hide3 = component.find('Hide3');
          var Hide4 = component.find('Hide4');
          var Hide5 = component.find('Hide5');
          var Hide6 = component.find('Hide6');
          var Hide7 = component.find('Hide7');
          var Hide8 = component.find('Hide8');
          var Hide9 = component.find('Hide9');
        var Hide10 = component.find('Hide10');
           var HideRed = component.find('HideRed');
        var HideRed2 = component.find('HideRed2');
            var CheckHide= component.find('Hidecheck');
        
 
        
        if (component.find('checkbox').get('v.value')==true){
            
        
   $A.util.addClass(Hide1, "toggle");
        $A.util.addClass(Hide2, "toggle2");
        $A.util.addClass(Hide3, "toggle3");
        $A.util.addClass(Hide4, "toggle4");
        $A.util.addClass(Hide5, "toggle5");
        $A.util.addClass(Hide6, "toggle6");
        $A.util.addClass(Hide7, "toggle7");
        $A.util.addClass(Hide8, "toggle8");
        $A.util.addClass(Hide9, "toggle9");
             $A.util.addClass(Hide10, "toggle12");
     $A.util.addClass(HideRed, "toggle10");
             $A.util.addClass(HideRed2, "toggle11");
            $A.util.addClass(CheckHide,'toggle13');
        
     component.find('Grade').set('v.value','N/A( Location Closed)');
        
        component.find('Model1').set('v.value','');
          component.find('Model2').set('v.value','');
          component.find('Model3').set('v.value','');
          component.find('Model4').set('v.value','');
          component.find('Model5').set('v.value','');
          component.find('Model6').set('v.value','');
          component.find('Model7').set('v.value','');
          component.find('Model8').set('v.value','');
          component.find('Model9').set('v.value','');
            component.find('Model10').set('v.value','');
            component.find('RedModel').set('v.value','');
            component.find('RedModel2').set('v.value', '');
            component.find('Status').set('v.value','');
            component.find('Status2').set('v.value','');
            component.find('Status3').set('v.value','');
            component.find('Status4').set('v.value','');
            component.find('Status5').set('v.value','');
            component.find('Status6').set('v.value','');
            component.find('Status7').set('v.value','');
            component.find('Status8').set('v.value','');
            component.find('Status9').set('v.value','');
            component.find('Status10').set('v.value','');
            component.find('RedStatus').set('v.value','');
            component.find('RedStatus2').set('v.value','');
        }
        
      
        
        else if (component.find('checkbox').get('v.value')==false){
          //  alert(component.find('CustomLookup').get('v.selectedRecord'));
           var numb = 1;
             $A.util.removeClass(CheckHide,'toggle13');
            
             var baction = component.get("c.getAsset");
   				//var Acc = component.find('Account').get('v.value');
   				 var yes = component.get('V.Details');
        //console.log(yes.Id);

         var stuff =   component.get('v.VGTL');
            
            
            
        if(numb!==2 && component.find("SAS1").get('v.value')!==''){ // if(yes.VGT_1__r.SAS__c!='1' && yes.VGT_2__r.SAS__c!='1' && yes.VGT_3__r.SAS__c!='1' && yes.VGT_4__r.SAS__c!='1' && yes.VGT_5__r.SAS__c!='1'){ //  
            component.find("Model1").set("v.value","");
                component.find("SAS1").set("v.value",""); 
                    component.find("Asset1").set("v.value", "");
 
          
        //    gotit = component.find('SAS1').get('v.value');
} 
         
            
          component.find('Grade').set('v.value','Select Choice');
     
             
                            
       
             if(yes.VGT_1__c){
         if (yes.VGT_1__r.SAS__c==="1"){
              
                   component.find("Model1").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_1__r.SAS__c); 
                    component.find("Asset1").set("v.value", yes.VGT_1__c);
              numb + 1;
           var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');

                }

         }
        
  
      
            if(yes.VGT_2__c){
                if(yes.VGT_2__r.SAS__c==="1"){
                     
                       component.find("Model1").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset1").set("v.value", yes.VGT_2__c);
                     numb + 1;
                   var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
               
                }
   
             }
       
          

        
        
              if(yes.VGT_3__c){
                    if(yes.VGT_3__r.SAS__c==="1"){
                      
                            component.find("Model1").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset1").set("v.value", yes.VGT_3__c);
                        numb + 1;
                     var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');

                    }
  
             }
                               
          

             
              if(yes.VGT_4__c){
                  if(yes.VGT_4__r.SAS__c==="1"){
                     
                            component.find("Model1").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset1").set("v.value", yes.VGT_4__c);
                     numb +1;
                    var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                  }
   
                    }
                      
   
                     
                   if(yes.VGT_5__c){
                     if(yes.VGT_5__r.SAS__c==="1"){
                          
                            component.find("Model1").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset1").set("v.value", yes.VGT_5__c);
                        numb +1;
               var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                     
                     }
  
		     }
                     

          

             
          if(yes.VGT_6__c){
                     if(yes.VGT_6__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_6__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
  
                   }
        
        
        
        
          if(yes.VGT_7__c){
                     if(yes.VGT_7__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_7__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
    
 
                   }
   
      
          
   
        
        
        
        if(yes.VGT_8__c){
                     if(yes.VGT_8__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_8__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
  
 
        
        if(yes.VGT_9__c){
                     if(yes.VGT_9__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_9__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
        if(yes.VGT_10__c){
                     if(yes.VGT_10__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_10__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
      
   
          
          //------------PoSITION 2--------------------//
        if(numb!==2 && component.find("SAS2").get('v.value')!==''){
             component.find("Model2").set("v.value","");
                component.find("SAS2").set("v.value",""); 
                    component.find("Asset2").set("v.value", "");
      
        
        }
        if(yes.VGT_1__r){
                 if (yes.VGT_1__r.SAS__c==="2"){
                   component.find("Model2").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_1__r.SAS__c); 
                        component.find("Asset2").set("v.value", yes.VGT_1__c);
                        var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                }
          }
 
        
       if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="2"){
                       component.find("Model2").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset2").set("v.value", yes.VGT_2__c);
                             var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                }
        }
  
       if(yes.VGT_3__r){
                    if(yes.VGT_3__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset2").set("v.value", yes.VGT_3__c);
                                var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                    }
        }

        
      if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset2").set("v.value", yes.VGT_4__c);
                              var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                    }
        
    }		
     
 if(yes.VGT_5__r){
                      if(yes.VGT_5__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset2").set("v.value", yes.VGT_5__c);
                                  var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                     }
    
          }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_6__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_7__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_8__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_9__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
          if(yes.VGT_10__r){
                     if(yes.VGT_9__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_10__c);
                            var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
     
                   }
              
                //-------------Position ------3////
                if(numb!==2 && component.find("SAS3").get('v.value')!==''){
             component.find("Model3").set("v.value","");
                component.find("SAS3").set("v.value",""); 
                    component.find("Asset3").set("v.value", "");
      
        
        }
             if(yes.VGT_1__r){
                if (yes.VGT_1__r.SAS__c==="3"){
                   component.find("Model3").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_1__r.SAS__c);
                     component.find("Asset3").set("v.value", yes.VGT_1__c);
                        var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');
            
                }
              }

       if(yes.VGT_2__r){
                if(yes.VGT_2__r.SAS__c==="3"){
                       component.find("Model3").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset3").set("v.value", yes.VGT_2__c);
                      var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                }
        }

       if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_3__r.SAS__c);
                         component.find("Asset3").set("v.value", yes.VGT_3__c);
       var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                    }
        }

	 if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset3").set("v.value", yes.VGT_4__c)
                         var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                    }
            
        }

      if(yes.VGT_5__r){
                      if(yes.VGT_5__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset3").set("v.value", yes.VGT_5__c)
                       var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                     }
                
             }
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_6__c);
                         var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_7__c);
                  var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_8__c);
                    var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_9__c);
               var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
   if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_10__c);
                            var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');
                            }
     
                   }
   
                //------------POSITION--4----------------///
                       if(numb!==2 && component.find("SAS4").get('v.value')!==''){
             component.find("Model4").set("v.value","");
                component.find("SAS4").set("v.value",""); 
                    component.find("Asset4").set("v.value", "");
           
        
        }
 if(yes.VGT_1__r){
                if (yes.VGT_1__r.SAS__c==="4"){
                   component.find("Model4").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_1__r.SAS__c); 
                     component.find("Asset4").set("v.value", yes.VGT_1__c);
              var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                }
 }

        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="4"){
                       component.find("Model4").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset4").set("v.value", yes.VGT_2__c);
              var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                }
        }
 
        if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_3__r.SAS__c);
                         component.find("Asset4").set("v.value", yes.VGT_3__c);
      var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                    }
        }

        
        if(yes.VGT_4__r){
                 if(yes.VGT_4__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset4").set("v.value", yes.VGT_4__c);
  var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                    }
        }

        if(yes.VGT_5__r){
        	
                     if(yes.VGT_5__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_5__c);
  var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                     }
                         }
     if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_6__c);
         var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_7__c);
            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_8__c);
            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_9__c);
             var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
         if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_10__c);
                            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
     
                   }
   
       //------------POSITION --5--------------------///
        
            //  var Hidesection1 = component.find('Hide5');
         //  $A.util.toggleClass(Hidesection1, "toggle5"); 
        

       
               if(numb!==2 && component.find("SAS5").get('v.value')!==''){
             component.find("Model5").set("v.value","");
                component.find("SAS5").set("v.value",""); 
                    component.find("Asset5").set("v.value", "");
        }
        
     
        
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="5"){
                   component.find("Model5").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset5").set("v.value", yes.VGT_1__c);
        var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');

                }
        }
        
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="5"){
                       component.find("Model5").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset5").set("v.value", yes.VGT_2__c);
             var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset5").set("v.value", yes.VGT_3__c);
                   var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset5").set("v.value", yes.VGT_4__c);
                 var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_5__c);
                var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_6__c);
                   var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_7__c);
           var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_8__c);
      var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_9__c);
                 var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_10__c);
                            var Hidesection5 = component.find('Hide5');
              $A.util.removeClass(Hidesection5, 'toggle5');
                            }
     
                   }
        //------------POSITION --6--------------------///
               if(numb!==2 && component.find("SAS6").get('v.value')!==''){
             component.find("Model6").set("v.value","");
                component.find("SAS6").set("v.value",""); 
                    component.find("Asset6").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="6"){
                   component.find("Model6").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset6").set("v.value", yes.VGT_1__c);
                 var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="6"){
                       component.find("Model6").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset6").set("v.value", yes.VGT_2__c);
                     var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset6").set("v.value", yes.VGT_3__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset6").set("v.value", yes.VGT_4__c);
                      var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_5__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_6__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_7__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_8__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_9__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_10__c);
                            var Hidesection6 = component.find('Hide6');
              $A.util.removeClass(Hidesection6, 'toggle6');
                            }
     
                   }
            //------------POSITION --7--------------------///
               if(numb!==2 && component.find("SAS7").get('v.value')!==''){
             component.find("Model7").set("v.value","");
                component.find("SAS7").set("v.value",""); 
                    component.find("Asset7").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="7"){
                   component.find("Model7").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset7").set("v.value", yes.VGT_1__c);
                 
                 var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="7"){
                       component.find("Model7").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset7").set("v.value", yes.VGT_2__c);
                     
                                 var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset7").set("v.value", yes.VGT_3__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset7").set("v.value", yes.VGT_4__c);
                      
                                  var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_5__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_6__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_7__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_8__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_9__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
         if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_10__c);
                            var Hidesection7 = component.find('Hide7');
              $A.util.removeClass(Hidesection7, 'toggle7');
                            }
     
                   }
            //------------POSITION --8--------------------///
               if(numb!==2 && component.find("SAS8").get('v.value')!==''){
             component.find("Model8").set("v.value","");
                component.find("SAS8").set("v.value",""); 
                    component.find("Asset8").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="8"){
                   component.find("Model8").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset8").set("v.value", yes.VGT_1__c);
                             var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                 
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="8"){
                       component.find("Model8").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset8").set("v.value", yes.VGT_2__c);
                                var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset8").set("v.value", yes.VGT_3__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset8").set("v.value", yes.VGT_4__c);
                                 var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_5__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_6__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_7__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_8__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_9__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
                
                
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_10__c);
                            var Hidesection8 = component.find('Hide8');
              $A.util.removeClass(Hidesection8, 'toggle8');
                            }
     
                   }
                
                
      if(numb!==2 && component.find("Asset6").get('v.value')!==''){
             component.find("Model6").set("v.value","");
            
                    component.find("Asset6").set("v.value", "");
            
        
        } 
        
            //------------POSITION --9--------------------///
               if(numb!==2 && component.find("SAS9").get('v.value')!==''){
             component.find("Model9").set("v.value","");
                component.find("SAS9").set("v.value",""); 
                    component.find("Asset9").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="9"){
                   component.find("Model9").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset9").set("v.value", yes.VGT_1__c);
                   var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="9"){
                       component.find("Model9").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset9").set("v.value", yes.VGT_2__c);
                     
                           var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset9").set("v.value", yes.VGT_3__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset9").set("v.value", yes.VGT_4__c);
                      
                            var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_5__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_6__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_7__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_8__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_9__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
            
             if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_10__c);
                            var Hidesection9 = component.find('Hide9');
              $A.util.removeClass(Hidesection9, 'toggle9');
                            }
     
                   }
                
                //------------POSITION --10--------------------///
               if(numb!==2 && component.find("SAS10").get('v.value')!==''){
             component.find("Model10").set("v.value","");
                component.find("SAS10").set("v.value",""); 
                    component.find("Asset10").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="10"){
                   component.find("Model10").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS10").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset10").set("v.value", yes.VGT_1__c);
                             var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                 
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="10"){
                       component.find("Model10").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS810").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset10").set("v.value", yes.VGT_2__c);
                                var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset10").set("v.value", yes.VGT_3__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS10").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset10").set("v.value", yes.VGT_4__c);
                                 var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_5__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_6__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_7__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_8__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_9__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
                
                
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_10__c);
                            var Hidesection10 = component.find('Hide10');
              $A.util.removeClass(Hidesection10, 'toggle12');
                            }
     
                   }
                
                
                            
            
            
                 if(yes.Redemption__r){
            					numb +1;
                            component.find("Redemption").set("v.value",yes.Redemption__c);
                         component.find("RedModel").set('v.value',yes.Redemption__r.Model__c);
                     $A.util.removeClass(HideRed, "toggle10");
        }
            
           if(stuff){
                for (var i=0; i <stuff.length; i++){
                 var item = stuff[i];
                    //alert(item.Name);
                    //component.set('v.String','');
                    if (item.Id !== component.find('Redemption').get('v.value')){
                        component.find('RedModel2').set('v.value', item.Model__c);
                        component.find("Redemption2").set('v.value', item.Id);
                        component.set('v.String', item.Id);
                        //var gethide = component.find('HideRed2');
                        $A.util.removeClass(HideRed2,'toggle11');
                    }
                    
					                    
                         
            
                }
            
               //$A.util.addClass(HideRed2, "toggle11");
               }
            
            
            if(component.find('RedModel2').get('v.value')==null)
            {
                	$A.util.addClass(HideRed2,'toggle11');
            }
            
        } 
        
},
    
    	onSingleSelectChange: function(cmp) {
         var selectCmp = cmp.find("Site_Grade");
         var resultCmp = cmp.find("singleResult");
         resultCmp.set("v.value", selectCmp.get("v.value"));
	 },
    
    handleTouchMove: function(component, event, helper) {
    event.stopPropagation();
},
    
    DisableSave : function(component, event, helper) {
        
       // component.set("v.SaveDisable", true);
    },
    
    
    
    
    Submit: function(component, event, helper){
           //component.set('v.SaveDisable', true);
		
       helper.CreateWorkOrder(component, event, helper);
     
        
    },
    
    
        navigate: function(component,event, helper){
            // var recId = component.get('V.Details');
        var ids = recId.Id;
            var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({
      "recordId":'0WO7A000000Dip1WAC',
      "slideDevName": "Detail"
    });
    navEvt.fire();  
        },
    
   
        

    GetAccount: function(component, event, helper) {
    /* document.getElementById('Status').value='';*/
        	var close = component.find('HideClosed');
        var check = component.find('Hidecheck');
       
        $A.util.removeClass(close,'toggle14');
        $A.util.removeClass(check,'toggle13');
         if(component.find('specialproject').get('v.value')==true){
            $A.util.addClass(close,'toggle14');
        };
      component.set('v.val',' ');
        
        var today = new Date();
var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();
        
        component.find('time').set('v.value',today);
       // var currentTime= new Date().toLocaleTimeString()
        
     //alert(component.get('v.val'));
       component.find("Status").set("v.value", ' ');
  	
        component.find("Status2").set("v.value",  ' ');
        component.find("Status3").set("v.value", ' ');
        component.find("Status4").set("v.value",  component.get('v.val'));
        component.find("Status5").set("v.value",  component.get('v.val'));
        component.find("Status6").set("v.value",component.get('v.val'));
        component.find("Status7").set("v.value",component.get('v.val'));
        component.find("Status8").set("v.value",  component.get('v.val'));
        component.find("Status9").set("v.value", component.get('v.val'));
        component.find("Status10").set("v.value", component.get('v.val'));
        component.find("RedStatus").set("v.value",component.get('v.val'));
        component.find("RedStatus2").set("v.value",component.get('v.val')); 
        
        
      
        
       component.find('Grade').set('v.value', 'Select Choice'); 
        
        
        
        
        
        component.find("Notes1").set("v.value"," ");
        component.find("Notes 2").set("v.value"," ");
        component.find("Notes 3").set("v.value"," ");
        component.find("Notes 4").set("v.value"," ");
        component.find("Notes 5").set("v.value"," ");
        component.find("Notes 6").set("v.value"," ");
        component.find("Notes 7").set("v.value"," ");
        component.find("Notes 8").set("v.value"," ");
        component.find("Notes 9").set("v.value"," ");
        component.find("Notes 10").set("v.value"," ");
        component.find("Notes 11").set("v.value"," ");
        component.find("Notes ten").set("v.value","");
    	component.find("SiteNote").set("v.value", " ");
       
     // $A.get('e.force:refreshView').fire();
        
        var numb = 1;
        var Acc = event.getParam('OneAccount');
         var gotit;
        component.set('v.Details', Acc);
         var yes = component.get('V.Details');
        
      //  var AccountId =  component.find('Account').get("v.value");
        var baction = component.get("c.getAsset");
   
        //console.log(yes.Id);
        baction.setParams({
            'key' : Acc.Id});
        
        baction.setCallback(this, function(response){
            var get = response.getState();
            //alert(get);
            //console.log(get);
            if (get === 'SUCCESS'){
              var Gotit = response.getReturnValue();
              component.set('v.VGTL', Gotit);
              // var item = component.get('v.VGTL')[0];
              
                for (var i=0; i <Gotit.length; i++){
                 var item = Gotit[i];
                    //alert(item.Name);
                    //component.set('v.String','');
                    if (item.Id !== component.find('Redemption').get('v.value')){
                        component.find('RedModel2').set('v.value', item.Model__c);
                        component.find("Redemption2").set('v.value', item.Id);
                        component.set('v.String', item.Id);
                        var gethide = component.find('HideRed2');
                        $A.util.removeClass(gethide,'toggle11');
                    }
                    
                
                   
                };
                
                
             
            };
            });
        $A.enqueueAction(baction);
        
        var item = component.get('v.AccountAsset');
      
   		component.find('SiteNote').set('v.value','');
      
        //--------Position--1----------//
         component.find('Account').set('v.value',yes.Id);
        component.find('checkbox').set('v.value',false);
  		 //  var Test = component.find("SAS1").get('v.value');
  		// alert(yes.	IGB_License__c);
      component.find('Address').set('v.value',yes.ShippingStreet);
           var Hidesection = component.find('Hide1');
         $A.util.addClass(Hidesection, "toggle");
        
        var Hidesection1 = component.find('Hide5');
           $A.util.addClass(Hidesection1, "toggle5"); 
       
        var Hidesection2 = component.find('Hide2');
           $A.util.addClass(Hidesection2, "toggle2"); 
        
        var Hidesection3 = component.find('Hide3');
           $A.util.addClass(Hidesection3, "toggle3");
        
        var Hidesection4 = component.find('Hide4');
            $A.util.addClass(Hidesection4, "toggle4");
        
        var Hidesection6 = component.find('Hide6');
            $A.util.addClass(Hidesection6, "toggle6");
        
        var Hidesection7 = component.find('Hide7');
            $A.util.addClass(Hidesection7, "toggle7");
        
        var Hidesection8 = component.find('Hide8');
            $A.util.addClass(Hidesection8, "toggle8");
        
        var Hidesection9 = component.find('Hide9');
            $A.util.addClass(Hidesection9, "toggle9");
        
        var Hidesection10 = component.find('Hide10');
        $A.util.addClass(Hidesection10, "toggle12");
        
         var HideRed = component.find('HideRed');
        	$A.util.addClass(HideRed, "toggle10");
        
        var HideRed2 = component.find('HideRed2');
        	$A.util.addClass(HideRed2, "toggle11");
        
        
              var Check1 =  component.find('HideSticker');
           var Check2 =  component.find('HideSticker2');
           var Check3 =  component.find('HideSticker3');
           var Check4 =  component.find('HideSticker4');
           var Check5 =  component.find('HideSticker5');
           var Check6 =  component.find('HideSticker6');
           var Check7 =  component.find('HideSticker7');
           var Check8 =  component.find('HideSticker8');
           var Check9 =  component.find('HideSticker9');
           var Check10 =  component.find('HideSticker10');
           var Check11 =  component.find('HideSticker11');
        	var Check12 = component.find('HideStickerten');
              
  //  var Hidesection1 = component.find('Hide5');
     //     $A.util.toggleClass(Hidesection1, "toggle"); 

        
    var cook = yes.County__c;
        
        var loc = yes.Location_Type__c;
        
        //alert(loc);
               // if(yes.County__c) {    
        
            
            
          //  if(cook.includes('Cook') && loc != "VFW" && loc != 'Fraternal' && loc != 'American Legion'){
               if(cook === 'Cook' && loc != "VFW" && loc != 'Fraternal' && loc != 'American Legion'){

   
          	$A.util.removeClass(Check1, "toggle16");
          $A.util.removeClass(Check2, "toggle16");
          $A.util.removeClass(Check3, "toggle16");
          $A.util.removeClass(Check4, "toggle16");
          $A.util.removeClass(Check5, "toggle16");
          $A.util.removeClass(Check6, "toggle16");
          $A.util.removeClass(Check7, "toggle16");
          $A.util.removeClass(Check8, "toggle16");
          $A.util.removeClass(Check9, "toggle16");
          $A.util.removeClass(Check10, "toggle16");
          $A.util.removeClass(Check11, "toggle16");
          $A.util.removeClass(Check12, "toggle16");
          
       }
            
     
            
        
       /// }
       //
   
          else{
  
              
              
          	$A.util.addClass(Check1, "toggle16");
              $A.util.addClass(Check2, "toggle16");
              $A.util.addClass(Check3, "toggle16");
              $A.util.addClass(Check4, "toggle16");
              $A.util.addClass(Check5, "toggle16");
              $A.util.addClass(Check6, "toggle16");
              $A.util.addClass(Check7, "toggle16");
              $A.util.addClass(Check8, "toggle16");
              $A.util.addClass(Check9, "toggle16");
              $A.util.addClass(Check10, "toggle16");
              $A.util.addClass(Check11, "toggle16");
              $A.util.addClass(Check12, "toggle16");
   
              component.find('Sticker1').set('v.value',false);
              component.find('Sticker2').set('v.value',false);
              component.find('Sticker3').set('v.value',false);
              component.find('Sticker4').set('v.value',false);
              component.find('Sticker5').set('v.value',false);
              component.find('Sticker6').set('v.value',false);
              component.find('Sticker7').set('v.value',false);
              component.find('Sticker8').set('v.value',false);
              component.find('Sticker9').set('v.value',false);
              component.find('Stickerten').set('v.value', false);
              component.find('Sticker10').set('v.value',false);
              component.find('Sticker11').set('v.value',false);
             
          
        }    
        
        
        
        
        
        
        
        
      if(numb!==2 && component.find("SAS1").get('v.value')!==''){ // if(yes.VGT_1__r.SAS__c!='1' && yes.VGT_2__r.SAS__c!='1' && yes.VGT_3__r.SAS__c!='1' && yes.VGT_4__r.SAS__c!='1' && yes.VGT_5__r.SAS__c!='1'){ //  
            component.find("Model1").set("v.value","");
                component.find("SAS1").set("v.value",""); 
                    component.find("Asset1").set("v.value", "");
          
          
 
          
        //    gotit = component.find('SAS1').get('v.value');
} 
        
      
       
     
      
        
        if(component.find("SAS1").get('v.value')===''){
            component.find('Model1').set("v.value",'');
        }
        
        
       
        
             if(yes.VGT_1__c){
         if (yes.VGT_1__r.SAS__c==="1"){
              
                   component.find("Model1").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_1__r.SAS__c); 
                    component.find("Asset1").set("v.value", yes.VGT_1__c);
              numb + 1;
           var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');

                }

         }
        
  
      
            if(yes.VGT_2__c){
                if(yes.VGT_2__r.SAS__c==="1"){
                     
                       component.find("Model1").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset1").set("v.value", yes.VGT_2__c);
                     numb + 1;
                   var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
               
                }
   
             }
       
          

        
        
              if(yes.VGT_3__c){
                    if(yes.VGT_3__r.SAS__c==="1"){
                      
                            component.find("Model1").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset1").set("v.value", yes.VGT_3__c);
                        numb + 1;
                     var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');

                    }
  
             }
                               
          

             
              if(yes.VGT_4__c){
                  if(yes.VGT_4__r.SAS__c==="1"){
                     
                            component.find("Model1").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset1").set("v.value", yes.VGT_4__c);
                     numb +1;
                    var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                  }
   
                    }
                      
   
                     
                   if(yes.VGT_5__c){
                     if(yes.VGT_5__r.SAS__c==="1"){
                          
                            component.find("Model1").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS1").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset1").set("v.value", yes.VGT_5__c);
                        numb +1;
               var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                     
                     }
  
		     }
                     

          

             
          if(yes.VGT_6__c){
                     if(yes.VGT_6__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_6__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
  
                   }
        
        
        
        
          if(yes.VGT_7__c){
                     if(yes.VGT_7__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_7__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
    
 
                   }
   
      
          
   
        
        
        
        if(yes.VGT_8__c){
                     if(yes.VGT_8__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_8__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
  
 
        
        if(yes.VGT_9__c){
                     if(yes.VGT_9__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_9__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
        if(yes.VGT_10__c){
                     if(yes.VGT_10__r.SAS__c==="1"){
                            component.find("Model1").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS1").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset1").set("v.value", yes.VGT_10__c);
                            var Hidesection = component.find('Hide1');
              $A.util.removeClass(Hidesection, 'toggle');
                            }
     
                   }
      
   
          
          //------------PoSITION 2--------------------//
        if(numb!==2 && component.find("SAS2").get('v.value')!==''){
             component.find("Model2").set("v.value","");
                component.find("SAS2").set("v.value",""); 
                    component.find("Asset2").set("v.value", "");
      
        
        }
        if(yes.VGT_1__r){
                 if (yes.VGT_1__r.SAS__c==="2"){
                   component.find("Model2").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_1__r.SAS__c); 
                        component.find("Asset2").set("v.value", yes.VGT_1__c);
                        var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                }
          }
 
        
       if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="2"){
                       component.find("Model2").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset2").set("v.value", yes.VGT_2__c);
                             var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                }
        }
  
       if(yes.VGT_3__r){
                    if(yes.VGT_3__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset2").set("v.value", yes.VGT_3__c);
                                var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                    }
        }

        
      if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset2").set("v.value", yes.VGT_4__c);
                              var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                    }
        
    }		
     
 if(yes.VGT_5__r){
                      if(yes.VGT_5__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS2").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset2").set("v.value", yes.VGT_5__c);
                                  var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                     }
    
          }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_6__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_7__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_8__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_9__c);
                                 var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
                   }
        
          if(yes.VGT_10__r){
                     if(yes.VGT_9__r.SAS__c==="2"){
                            component.find("Model2").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS2").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset2").set("v.value", yes.VGT_10__c);
                            var Hidesection2 = component.find('Hide2');
              $A.util.removeClass(Hidesection2, 'toggle2');
                            }
     
                   }
              
                //-------------Position ------3////
                if(numb!==2 && component.find("SAS3").get('v.value')!==''){
             component.find("Model3").set("v.value","");
                component.find("SAS3").set("v.value",""); 
                    component.find("Asset3").set("v.value", "");
      
        
        }
             if(yes.VGT_1__r){
                if (yes.VGT_1__r.SAS__c==="3"){
                   component.find("Model3").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_1__r.SAS__c);
                     component.find("Asset3").set("v.value", yes.VGT_1__c);
                        var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');
            
                }
              }

       if(yes.VGT_2__r){
                if(yes.VGT_2__r.SAS__c==="3"){
                       component.find("Model3").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_2__r.SAS__c);  
                     component.find("Asset3").set("v.value", yes.VGT_2__c);
                      var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                }
        }

       if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_3__r.SAS__c);
                         component.find("Asset3").set("v.value", yes.VGT_3__c);
       var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                    }
        }

	 if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset3").set("v.value", yes.VGT_4__c)
                         var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                    }
            
        }

      if(yes.VGT_5__r){
                      if(yes.VGT_5__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS3").set("v.value",yes.VGT_5__r.SAS__c); 
                          component.find("Asset3").set("v.value", yes.VGT_5__c)
                       var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                     }
                
             }
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_6__c);
                         var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_7__c);
                  var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_8__c);
                    var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_9__c);
               var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');

                            }
                   }
   if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="3"){
                            component.find("Model3").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS3").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset3").set("v.value", yes.VGT_10__c);
                            var Hidesection3 = component.find('Hide3');
              $A.util.removeClass(Hidesection3, 'toggle3');
                            }
     
                   }
   
                //------------POSITION--4----------------///
                       if(numb!==2 && component.find("SAS4").get('v.value')!==''){
             component.find("Model4").set("v.value","");
                component.find("SAS4").set("v.value",""); 
                    component.find("Asset4").set("v.value", "");
           
        
        }
 if(yes.VGT_1__r){
                if (yes.VGT_1__r.SAS__c==="4"){
                   component.find("Model4").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_1__r.SAS__c); 
                     component.find("Asset4").set("v.value", yes.VGT_1__c);
              var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                }
 }

        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="4"){
                       component.find("Model4").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset4").set("v.value", yes.VGT_2__c);
              var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                }
        }
 
        if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_3__r.SAS__c);
                         component.find("Asset4").set("v.value", yes.VGT_3__c);
      var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                    }
        }

        
        if(yes.VGT_4__r){
                 if(yes.VGT_4__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset4").set("v.value", yes.VGT_4__c);
  var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                    }
        }

        if(yes.VGT_5__r){
        	
                     if(yes.VGT_5__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_5__r.Model__c);
                component.find("SAS4").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_5__c);
  var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                     }
                         }
     if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_6__c);
         var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_7__c);
            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_8__c);
            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_9__c);
             var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
                   }
         if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="4"){
                            component.find("Model4").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS4").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset4").set("v.value", yes.VGT_10__c);
                            var Hidesection4 = component.find('Hide4');
              $A.util.removeClass(Hidesection4, 'toggle4');
                            }
     
                   }
   
       //------------POSITION --5--------------------///
        
            //  var Hidesection1 = component.find('Hide5');
         //  $A.util.toggleClass(Hidesection1, "toggle5"); 
        

       
               if(numb!==2 && component.find("SAS5").get('v.value')!==''){
             component.find("Model5").set("v.value","");
                component.find("SAS5").set("v.value",""); 
                    component.find("Asset5").set("v.value", "");
        }
        
     
        
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="5"){
                   component.find("Model5").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset5").set("v.value", yes.VGT_1__c);
        var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');

                }
        }
        
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="5"){
                       component.find("Model5").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset5").set("v.value", yes.VGT_2__c);
             var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset5").set("v.value", yes.VGT_3__c);
                   var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS5").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset5").set("v.value", yes.VGT_4__c);
                 var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_5__c);
                var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_6__c);
                   var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_7__c);
           var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_8__c);
      var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_9__c);
                 var Hidesection1 = component.find('Hide5');
              $A.util.removeClass(Hidesection1, 'toggle5');
                            }
                   }
        
        if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="5"){
                            component.find("Model5").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS5").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset5").set("v.value", yes.VGT_10__c);
                            var Hidesection5 = component.find('Hide5');
              $A.util.removeClass(Hidesection5, 'toggle5');
                            }
     
                   }
        //------------POSITION --6--------------------///
      
             /*  if(numb!==2 && component.find("SAS6").get('v.value')!==''){
             component.find("Model6").set("v.value","");
                component.find("SAS6").set("v.value",""); 
                    component.find("Asset6").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }*/
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="6"){
                   component.find("Model6").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset6").set("v.value", yes.VGT_1__c);
                 var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="6"){
                       component.find("Model6").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset6").set("v.value", yes.VGT_2__c);
                     var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset6").set("v.value", yes.VGT_3__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS6").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset6").set("v.value", yes.VGT_4__c);
                      var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_5__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="6"){
                     
                        // component.find("Notes 6").set("v.value", yes.VGT_6__r.Model__c);
                            component.find("Model6").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_6__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_7__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_8__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_9__c);
                         var Hidesection6 = component.find('Hide6');
            $A.util.removeClass(Hidesection6, "toggle6");
                            }
                   }
        
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="6"){
                            component.find("Model6").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS6").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset6").set("v.value", yes.VGT_10__c);
                            var Hidesection6 = component.find('Hide6');
              $A.util.removeClass(Hidesection6, 'toggle6');
                            }
     
                   }
            //------------POSITION --7--------------------///
               if(numb!==2 && component.find("SAS7").get('v.value')!==''){
             component.find("Model7").set("v.value","");
                component.find("SAS7").set("v.value",""); 
                    component.find("Asset7").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="7"){
                   component.find("Model7").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset7").set("v.value", yes.VGT_1__c);
                 
                 var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="7"){
                       component.find("Model7").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset7").set("v.value", yes.VGT_2__c);
                     
                                 var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset7").set("v.value", yes.VGT_3__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS7").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset7").set("v.value", yes.VGT_4__c);
                      
                                  var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_5__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_6__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_7__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_8__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_9__c);
                         
                                     var Hidesection7 = component.find('Hide7');
            $A.util.removeClass(Hidesection7, "toggle7");
                            }
                   }
        
         if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="7"){
                            component.find("Model7").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS7").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset7").set("v.value", yes.VGT_10__c);
                            var Hidesection7 = component.find('Hide7');
              $A.util.removeClass(Hidesection7, 'toggle7');
                            }
     
                   }
            //------------POSITION --8--------------------///
               if(numb!==2 && component.find("SAS8").get('v.value')!==''){
             component.find("Model8").set("v.value","");
                component.find("SAS8").set("v.value",""); 
                    component.find("Asset8").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="8"){
                   component.find("Model8").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset8").set("v.value", yes.VGT_1__c);
                             var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                 
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="8"){
                       component.find("Model8").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset8").set("v.value", yes.VGT_2__c);
                                var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset8").set("v.value", yes.VGT_3__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset8").set("v.value", yes.VGT_4__c);
                                 var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_5__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_6__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_7__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_8__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_9__c);
                                    var Hidesection8 = component.find('Hide8');
            $A.util.removeClass(Hidesection8, "toggle8");
                            }
                   }
                
                
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="8"){
                            component.find("Model8").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS8").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset8").set("v.value", yes.VGT_10__c);
                            var Hidesection8 = component.find('Hide8');
              $A.util.removeClass(Hidesection8, 'toggle8');
                            }
     
                   }
                
                
    /*  if(numb!==2 && component.find("Asset6").get('v.value')!==''){
             component.find("Model6").set("v.value","");
            
                    component.find("Asset6").set("v.value", "");
            
        
        } */
        
            //------------POSITION --9--------------------///
               if(numb!==2 && component.find("SAS9").get('v.value')!==''){
             component.find("Model9").set("v.value","");
                component.find("SAS9").set("v.value",""); 
                    component.find("Asset9").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="9"){
                   component.find("Model9").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset9").set("v.value", yes.VGT_1__c);
                   var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="9"){
                       component.find("Model9").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset9").set("v.value", yes.VGT_2__c);
                     
                           var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset9").set("v.value", yes.VGT_3__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS9").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset9").set("v.value", yes.VGT_4__c);
                      
                            var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_5__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_6__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_7__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_8__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_9__c);
                         
                               var Hidesection9 = component.find('Hide9');
            $A.util.removeClass(Hidesection9, "toggle9");
                            }
                   }
            
             if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="9"){
                            component.find("Model9").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS9").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset9").set("v.value", yes.VGT_10__c);
                            var Hidesection9 = component.find('Hide9');
              $A.util.removeClass(Hidesection9, 'toggle9');
                            }
     
                   }
                
                //------------POSITION --10--------------------///
               if(numb!==2 && component.find("SAS10").get('v.value')!==''){
             component.find("Model10").set("v.value","");
                component.find("SAS10").set("v.value",""); 
                    component.find("Asset10").set("v.value", "");
           //   var Hidesection = component.find('Hide5');
           // $A.util.toggleClass(Hidesection, "toggle5");
        
        }
        if(yes.VGT_1__r)
        {
             if (yes.VGT_1__r.SAS__c==="10"){
                   component.find("Model10").set("v.value",yes.VGT_1__r.Model__c);
                component.find("SAS10").set("v.value",yes.VGT_1__r.SAS__c); 
                  component.find("Asset10").set("v.value", yes.VGT_1__c);
                             var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                 
                }
        }
        if(yes.VGT_2__r){
                 if(yes.VGT_2__r.SAS__c==="10"){
                       component.find("Model10").set("v.value",yes.VGT_2__r.Model__c);
                component.find("SAS810").set("v.value",yes.VGT_2__r.SAS__c); 
                     component.find("Asset10").set("v.value", yes.VGT_2__c);
                                var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                }
        }
           	if(yes.VGT_3__r){
                     if(yes.VGT_3__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_3__r.Model__c);
                component.find("SAS8").set("v.value",yes.VGT_3__r.SAS__c); 
                         component.find("Asset10").set("v.value", yes.VGT_3__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                    }
           }
               if(yes.VGT_4__r){
                  if(yes.VGT_4__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_4__r.Model__c);
                component.find("SAS10").set("v.value",yes.VGT_4__r.SAS__c); 
                      component.find("Asset10").set("v.value", yes.VGT_4__c);
                                 var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                    }
               }
                    if(yes.VGT_5__r){
                     if(yes.VGT_5__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_5__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_5__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_5__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
          if(yes.VGT_6__r){
                     if(yes.VGT_6__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_6__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_6__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_6__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
         if(yes.VGT_7__r){
                     if(yes.VGT_7__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_7__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_7__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_7__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
        if(yes.VGT_8__r){
                     if(yes.VGT_8__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_8__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_8__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_8__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
        
        if(yes.VGT_9__r){
                     if(yes.VGT_9__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_9__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_9__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_9__c);
                                    var Hidesection10 = component.find('Hide10');
            $A.util.removeClass(Hidesection10, "toggle12");
                            }
                   }
                
                
                 if(yes.VGT_10__r){
                     if(yes.VGT_10__r.SAS__c==="10"){
                            component.find("Model10").set("v.value",yes.VGT_10__r.Model__c);
              component.find("SAS10").set("v.value",yes.VGT_10__r.SAS__c);
                          component.find("Asset10").set("v.value", yes.VGT_10__c);
                            var Hidesection10 = component.find('Hide10');
              $A.util.removeClass(Hidesection10, 'toggle12');
                            }
     
                   }
        //------------REDEMPTION-----------------//
        if(yes.Redemption__r){
            					numb +1;
                            component.find("Redemption").set("v.value",yes.Redemption__c);
                         component.find("RedModel").set('v.value',yes.Redemption__r.Model__c);
            			$A.util.removeClass(HideRed, "toggle10");
                       // $A.util.removeClass(HideRed, "toggle10");
                       // 
        
        }
        
        if(yes.Redemption__r===undefined){
            component.find("RedModel").set("v.value","");
        }
       
           
        	
        
        
                        
              //   component.find("Asset6").set("v.value",yes.Redemption__c);
                    //     component.find("Model6").set('v.value',yes.Redemption__r.Model__c); }
        
                     /*    else if (yes.VGT_5__c==null){
                             component.find("Model1").set("v.value",null);
                component.find("SAS1").set("v.value",null);
                          component.find("Asset1").set("v.value", null);
                             
                             component.find("Model2").set("v.value",null);
                component.find("SAS2").set("v.value",null);
                          component.find("Asset2").set("v.value", null);componenet
                             
                             component.find("Model3").set("v.value",null);
                component.find("SAS3").set("v.value",null);
                          component.find("Asset3").set("v.value", null);
                             
                             component.find("Model4").set("v.value",null);
                component.find("SAS4").set("v.value",null);
                          component.find("Asset4").set("v.value", null);
                             
                             component.find("Model5").set("v.value",null);
                component.find("SAS5").set("v.value",null);
                          component.find("Asset5").set("v.value", null);
                             
                             component.find("Model6").set("v.value",null);
                component.find("SAS6").set("v.value",null);
                          component.find("Asset6").set("v.value", null);
                             
                         }*/
        component.set("v.SaveDisable",false);
        
        if(component.find('specialproject').get('v.value')==true){
             var Hide1 = component.find('Hide1');
          var Hide2 = component.find('Hide2');
          var Hide3 = component.find('Hide3');
          var Hide4 = component.find('Hide4');
          var Hide5 = component.find('Hide5');
          var Hide6 = component.find('Hide6');
          var Hide7 = component.find('Hide7');
          var Hide8 = component.find('Hide8');
          var Hide9 = component.find('Hide9');
            var Hide10 = component.find('Hide10');
           var HideRed = component.find('HideRed');
        var HideRed2 = component.find('HideRed2');
            
            
            
            $A.util.addClass(Hide1, "toggle");
        $A.util.addClass(Hide2, "toggle2");
        $A.util.addClass(Hide3, "toggle3");
        $A.util.addClass(Hide4, "toggle4");
        $A.util.addClass(Hide5, "toggle5");
        $A.util.addClass(Hide6, "toggle6");
        $A.util.addClass(Hide7, "toggle7");
        $A.util.addClass(Hide8, "toggle8");
        $A.util.addClass(Hide9, "toggle9");
            $A.util.addClass(Hide10, "toggle12");
     $A.util.addClass(HideRed, "toggle10");
             $A.util.addClass(HideRed2, "toggle11");
         // $A.util.addClass(HideClose,"toggle14");
        
     component.find('Grade').set('v.value','N/A( Location Closed)');
        
        component.find('Model1').set('v.value','');
          component.find('Model2').set('v.value','');
          component.find('Model3').set('v.value','');
          component.find('Model4').set('v.value','');
          component.find('Model5').set('v.value','');
          component.find('Model6').set('v.value','');
          component.find('Model7').set('v.value','');
          component.find('Model8').set('v.value','');
          component.find('Model9').set('v.value','');
            component.find('Model10').set('v.value','');
            component.find('RedModel').set('v.value','');
            component.find('RedModel2').set('v.value', '');
            component.find('Status').set('v.value','');
            component.find('Status2').set('v.value','');
            component.find('Status3').set('v.value','');
            component.find('Status4').set('v.value','');
            component.find('Status5').set('v.value','');
            component.find('Status6').set('v.value','');
            component.find('Status7').set('v.value','');
            component.find('Status8').set('v.value','');
            component.find('Status9').set('v.value','');
            component.find('Status10').set('v.value','');
            component.find('RedStatus').set('v.value','');
            component.find('RedStatus2').set('v.value','');
        }
    
    },    
 //   SaveWork: function(component, event, helper) {
        
   // },
    
      handleSuccess2: function(component,event, helper) {
           var payload = event.getParams().response;
       // alert(payload.id);
       component.set('v.SubmittedId',payload.id); 
        //  alert('test');
       // alert(component.get('v.SubmittedId'));
     
        
    },
    
        handleSuccess3: function(component,event, helper) {
           var payload2 = event.getParams().response;
       // alert(payload.id);
       component.set('v.SubmittedId',payload2.id); 
         //   alert('Test');
       // alert(component.get('v.SubmittedId'));
     
        
    },
    
        handleSuccess4: function(component,event, helper) {
           var payload = event.getParams().response;
       // alert(payload.id);
       component.set('v.SubmittedId',payload.id); 
      //  alert(component.get('v.SubmittedId'));
     
        
    },
    
        handleSuccess5: function(component,event, helper) {
           var payload = event.getParams().response;
       // alert(payload.id);
       component.set('v.SubmittedId',payload.id); 
       // alert(component.get('v.SubmittedId'));
     
        
    },
        handleSuccess6: function(component,event, helper) {
           var payload = event.getParams().response;
       // alert(payload.id);
       component.set('v.SubmittedId',payload.id); 
       // alert(component.get('v.SubmittedId'));
     
        
    },
      handleSuccess7: function(component,event, helper) {
           var payload = event.getParams().response;
       // alert(payload.id);
       component.set('v.SubmittedId',payload.id); 
       // alert(component.get('v.SubmittedId'));
     
        
    },
    
    
 
    
    handleSuccess: function(component, event, helper) {
   var params = event.getParams(); //get event params
        var recordId = params.response.id; //get record id
        component.set('v.recordId', recordId);
        	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
				
				today = mm + '/' + dd + '/' + yyyy;
        if(recordId){
            component.find("Date/Time").set("v.value", today);
                setTimeout(function(){ helper.LineItems(component, event, helper);}, 5000);
                setTimeout(function(){ $A.get('e.force:refreshView').fire();}, 6500); 
        }
        
        else{
            alert('Error Creating Work Order');
        }
     
    },
    
    update: function(component,event, helper){
	

	 var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
				
				today = mm + '/' + dd + '/' + yyyy;
                
               
    
   var got =   component.find('Grade').get('v.value');     
   var hot =  component.find('SiteNote').get('v.value');    
	    //alert(hot);    
        component.set('v.Sites', hot);
       // alert(component.get('v.Sites'));
        component.find('Site_Grade').set('v.value', got);
       component.find('Site_Notes').set('v.value', hot); 
        
        var Grade = component.find('Site_Grade').get('v.value');
        var Acc = component.find('Account').get('v.value');
        
        if(Acc ===null){
            alert('Select An Account');
        }
       else if(Grade==="Select Choice") {
            alert('Select a Site Grade');
        }
        
        else{
            component.find("Date/Time").set("v.value", today);
        component.find('WorkOrder').submit();
            component.set("v.Disable",true);
             component.set('v.SaveDisable', false);
            
        
        $A.enqueueAction(a);
        } 
       // var payload = event.getParams().response;
      //  var recordId = payload.Id; //get record id
       // component.set("v.recordId", recordId);
    },
    
    
    
    
    selectAsset : function(component, event, helper) {
        var getSelectAsset = component.get('v.oAsset');
        var compEvent = Component.getEvent('v.oselectedAccountEvent');
        compEvent.setParams ({
            "AssetbyEvent" : getSelectAsset
        });
        compEvent.fire();
    },
    
 
  
 
    

	 selectAccount : function(component, event, helper){      
    // get the selected Account from list  
      var getSelectAccount = component.get("v.oAccount");
    // call the event   
      var compEvent = component.getEvent("oSelectedAccountEvent");
    // set the Selected Account to the event attribute.  
         compEvent.setParams({"AssetByEvent" : getSelectAccount });  
    // fire the event  
         compEvent.fire();
    },
    
        Redirect : function(component, event, helper) {
        var navService = component.find("navService");        
	var recId = component.get("v.recordId");
        console.log(recId);
    var pageReference = {
        type: 'standard__recordPage',
        attributes: {
            "recordId": recId,
            "objectApiName": "WorkOrder",
            "actionName": "home" //view//
        }
    }
    

    
   // event.preventDefault();
    //navService.navigate(pageReference);  
    }, 
    

    EnRoute : function(component, event, helper){
 
        
        component.set('v.Disable1', true);
        
    
                	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
        	today = mm + '/' + dd + '/' + yyyy;
        
        var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       // alert(date);
        component.find('Testing').set('v.value',String(date));
         
        component.set('v.ENR', date);
     
              setTimeout(function(){ component.find('WellnessWO').submit(); }, 1000);   


    },
    
    
     Arrival : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
         
   
         
         if(component.get('v.Disable1')!=true){
             alert("Must Select Enroute before Arrival");
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.ARR', date);
             
            
             
              var Wellness = component.find('Well');
             $A.util.removeClass(Wellness, "WellnessFields");
        component.set('v.Disable2', true);
                           setTimeout(function(){ component.find('WellnessWO').submit(); }, 8000);   

           // alert(component.get('v.SubmittedId'));
         }
    },
    
    
     Departure : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
         if(component.get('v.Disable1')!= true || component.get('v.Disable2')!= true){
             alert('Cannot Depart before Arriving or being EnRoute');
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "MM/dd/yyyy hh:mm:ss a");
      
       
         
        component.set('v.DEP', date);
        component.set('v.Disable3', true);
             component.set('v.Disable5', false);
         }
    },
 
     EnRoute2 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
        component.set('v.Disable1', true);
        
     /*    var today = new Date();
var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();*/
        
                	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
        	today = mm + '/' + dd + '/' + yyyy;
        
        var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
        component.find('Testing2').set('v.value',String(date));
         
        component.set('v.ENR', date);
               setTimeout(function(){ component.find('InventoryWO').submit(); }, 1000);
     

     //  alert(component.get('v.ENR'));
       // component.find("EnRoute").set("v.value", "test");
        
     //   component.find('WAccount').set('v.value', component.find('CustomLookup').get('v.selectedRecord'));
        // $A.localizationService.formatDate(new Date(), "YYYY-MM-DD")
      

    },
    
     EnRoute3 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
        component.set('v.Disable1', true);
        
     /*    var today = new Date();
var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();*/
        
                	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
        	today = mm + '/' + dd + '/' + yyyy;
        
        var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
        component.find('Testing3').set('v.value',String(date));
         
        component.set('v.ENR', date);
         
         setTimeout(function(){ component.find('SoftwareWO').submit(); }, 1000);  
        
     //  alert(component.get('v.ENR'));
       // component.find("EnRoute").set("v.value", "test");
        
     //   component.find('WAccount').set('v.value', component.find('CustomLookup').get('v.selectedRecord'));
        // $A.localizationService.formatDate(new Date(), "YYYY-MM-DD")
      

    },
    
     EnRoute4 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
        component.set('v.Disable1', true);
        
     /*    var today = new Date();
var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();*/
        
                	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
        	today = mm + '/' + dd + '/' + yyyy;
        
        var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
        component.find('Testing4').set('v.value',String(date));
         
        component.set('v.ENR', date);
               setTimeout(function(){ component.find('ProjectWO').submit(); }, 1000);   

        
     //  alert(component.get('v.ENR'));
       // component.find("EnRoute").set("v.value", "test");
        
     //   component.find('WAccount').set('v.value', component.find('CustomLookup').get('v.selectedRecord'));
        // $A.localizationService.formatDate(new Date(), "YYYY-MM-DD")
      

    },
    
     EnRoute5 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
        component.set('v.Disable1', true);
        
     /*    var today = new Date();
var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();*/
        
                	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
        	today = mm + '/' + dd + '/' + yyyy;
        
        var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
        component.find('Testing5').set('v.value',String(date));
         
        component.set('v.ENR', date);
         
               setTimeout(function(){ component.find('VehicleWO').submit(); }, 1000);   

        
     //  alert(component.get('v.ENR'));
       // component.find("EnRoute").set("v.value", "test");
        
     //   component.find('WAccount').set('v.value', component.find('CustomLookup').get('v.selectedRecord'));
        // $A.localizationService.formatDate(new Date(), "YYYY-MM-DD")
      

    },
    
     EnRoute6 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
        component.set('v.Disable1', true);
        
     /*    var today = new Date();
var time = today.getHours() + ":" + today.getMinutes() + ":" + today.getSeconds();*/
        
                	  var today = new Date();
				var dd = String(today.getDate()).padStart(2, '0');
				var mm = String(today.getMonth() + 1).padStart(2, '0'); //January is 0!
				var yyyy = today.getFullYear();
        	today = mm + '/' + dd + '/' + yyyy;
        
        var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
        component.find('Testing6').set('v.value',String(date));
         
        component.set('v.ENR', date);
               setTimeout(function(){ component.find('ColleagueWO').submit(); }, 1000);   

        
     //  alert(component.get('v.ENR')); //
       // component.find("EnRoute").set("v.value", "test");
        
     //   component.find('WAccount').set('v.value', component.find('CustomLookup').get('v.selectedRecord'));
        // $A.localizationService.formatDate(new Date(), "YYYY-MM-DD")
      

    },
    
    
    
    
     Arrival2 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
         
   
         
         if(component.get('v.Disable1')!=true){
             alert("Must Select Enroute before Arrival");
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.ARR', date);
            

             
             
        component.set('v.Disable2', true);
             var Wellness = component.find('Invent');
             $A.util.removeClass(Wellness, "InventFields");
                 component.set('v.Disable7', false);
                   setTimeout(function(){ component.find('InventoryWO').submit(); }, 8000);   

         }
    },
    
    Arrival3 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
         
   
         
         if(component.get('v.Disable1')!=true){
             alert("Must Select Enroute before Arrival");
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.ARR', date);
            

             
             
        component.set('v.Disable2', true);
             var Software = component.find('Soft');
             $A.util.removeClass(Software, "SoftwareFields");
                 component.set('v.Disable7', false);
             setTimeout(function(){ component.find('SoftwareWO').submit(); }, 8000);  
         }
    },
    
     Arrival5 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
         
   
         
         if(component.get('v.Disable1')!=true){
             alert("Must Select Enroute before Arrival");
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.ARR', date);
            

             
             
        component.set('v.Disable2', true);
             var Software = component.find('VHM');
             $A.util.removeClass(Software, "VehicleFields");
                 component.set('v.Disable7', false);
                   setTimeout(function(){ component.find('VehicleWO').submit(); }, 8000);   

         }
    },
    
    
    
         Arrival6 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
         
   
         
         if(component.get('v.Disable1')!=true){
             alert("Must Select Enroute before Arrival");
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.ARR', date);
            

             
             
        component.set('v.Disable2', true);
             var Software = component.find('CAssis');
             $A.util.removeClass(Software, "ColleagueFields");
                 component.set('v.Disable7', false);
                   setTimeout(function(){ component.find('ColleagueWO').submit(); }, 8000);   

         }
    },
    
         Arrival4 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
         
   
         
         if(component.get('v.Disable1')!=true){
             alert("Must Select Enroute before Arrival");
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.ARR', date);
            

             
             
        component.set('v.Disable2', true);
             var Software = component.find('Proj');
             $A.util.removeClass(Software, "ProjectFields");
                 component.set('v.Disable7', false);
                   setTimeout(function(){ component.find('ProjectWO').submit(); }, 8000);   

         }
    },
    
    
     Departure2 : function(component, event, helper){
        //
    /*  let button = component.find('Enroute');
        button.set('v.disabled', true);*/
        
         if(component.get('v.Disable1')!= true || component.get('v.Disable2')!= true){
             alert('Cannot Depart before Arriving or being EnRoute');
         }
         else{
             var date = $A.localizationService.formatDateTime(new Date(), "MM/dd/yyyy hh:mm:ss a");
      
       
         
        component.set('v.DEP', date);
        component.set('v.Disable3', true);
             component.set('v.Disable5', false);
              component.set('v.Disable7', false);
         }
    },
 
    SetWellNessAccount : function(component, event, helper){
      // if(component.get("v.userInfo.ProfileId")=="00e1I000000ZxflQAC"){
            
     
        
       // alert('test123');
         var Acc1 = event.getParam('Account');
       // alert(Acc1);
            //   }
              	  var stop = component.find('SelectApp').get('v.value');

        if(stop=='Wellness Visit'){
            component.find('WAccount').set('v.value', Acc1.Id);
        component.find('WAddress').set('v.value', Acc1.ShippingStreet);
        }
        
     /* else  if(stop=='Inventory Check'){
                component.find('WAccount2').set('v.value', Acc1.Id);
        component.find('WAddress2').set('v.value', Acc1.ShippingStreet);
        }*/
        
       else  if(stop=='Software Updates'){
                component.find('WAccount2').set('v.value', Acc1.Id);
        component.find('WAddress2').set('v.value', Acc1.ShippingStreet);
        }
        
         else  if(stop=='Project'){
                component.find('WAccount3').set('v.value', Acc1.Id);
        component.find('WAddress3').set('v.value', Acc1.ShippingStreet);
        }
             else  if(stop=='Vehicle Maintenance'){
                component.find('WAccount4').set('v.value', Acc1.Id);
        component.find('WAddress4').set('v.value', Acc1.ShippingStreet);
        }
        
    },
    
    SubmitWellness: function(component, event, helper){
        component.find('WellnessWO').submit();
        
        component.set('v.Disable5', true);
    },
    
       SubmitInventory: function(component, event, helper){
        component.find('InventoryWO').submit();
        
        component.set('v.Disable7', true);
    },
    
       SubmitSoftware: function(component, event, helper){
        component.find('SoftwareWO').submit();
        
        component.set('v.Disable7', true);
    },
    
        SubmitColleague: function(component, event, helper){
        component.find('ColleagueWO').submit();
        
        component.set('v.Disable7', true);
    },

    Cancel: function(component, event, helper){
        
         var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
        //alert(date);
       
         
        component.set('v.SUB', date);
        
        component.set('v.Disable4', true);
        
      setTimeout(function(){ component.find('WellnessWO').submit(); }, 1000);   
        
        setTimeout(function(){    window.location.reload(); }, 2000); 
  
    },
    
   
     Cancel2: function(component, event, helper){
        
         var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.SUB', date);
        
        component.set('v.Disable4', true);
        
      setTimeout(function(){ component.find('InventoryWO').submit(); }, 1000);   
        
        setTimeout(function(){    window.location.reload(); }, 2000); 
  
    },
    
       
     Cancel3: function(component, event, helper){
        
         var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.SUB', date);
        
        component.set('v.Disable4', true);
        
      setTimeout(function(){ component.find('SoftwareWO').submit(); }, 1000);   
        
        setTimeout(function(){    window.location.reload(); }, 2000); 
  
    },
    
     
     Cancel4: function(component, event, helper){
        
         var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.SUB', date);
        
        component.set('v.Disable4', true);
        
      setTimeout(function(){ component.find('ProjectWO').submit(); }, 1000);   
        
        setTimeout(function(){    window.location.reload(); }, 2000); 
  
    },  
    
      Cancel5: function(component, event, helper){
        
         var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.SUB', date);
        
        component.set('v.Disable4', true);
        
      setTimeout(function(){ component.find('VehicleWO').submit(); }, 1000);   
        
        setTimeout(function(){    window.location.reload(); }, 2000); 
  
    },  
    Refresh: function(component, event, helper){
        setTimeout(function(){    window.location.reload(); }, 2000); 
    },
    
    
    Cancel6: function(component, event, helper){
        
         var date = $A.localizationService.formatDateTime(new Date(), "yyyy-MM-dd hh:mm:ss a");
      
       
         
        component.set('v.SUB', date);
        
        component.set('v.Disable4', true);
        
      setTimeout(function(){ component.find('ColleagueWO').submit(); }, 1000);   
        
        setTimeout(function(){    window.location.reload(); }, 2000); 
  
    },  
 
    
    AppType: function(component, event, helper){
    
      /*var Well =  component.find('WellnessStuff');
        alert(component.find('Wellness1').get('v.value'));*/
  	  var stop = component.find('SelectApp').get('v.value');
        
      //  alert(stop);
       component.set('v.Disable8', true);
      if(stop=='Wellness Visit'){
        	   $A.util.removeClass(component.find('WellnessWO'), 'WellnessStuff');
            
        }
        
        if(stop!='Wellness Visit'){
            $A.util.addClass(component.find('WellnessWO'), 'WellnessStuff');
        }
        
        
       if(stop=='Inventory Check'){
            $A.util.removeClass(component.find('InventoryWO'), 'Inventory');

        }
        
        
    
        
        if(stop!='Inventory Check'){
            $A.util.addClass(component.find('InventoryWO'), 'Inventory');

        }
        
        if(stop=='Software Updates'){
            $A.util.removeClass(component.find('SoftwareWO'), ' SoftwareUpdates');
        }
       
    	  if(stop!='Software Updates'){
            $A.util.addClass(component.find('SoftwareWO'), ' SoftwareUpdates');
        }
        
        
              if(stop=='Project'){
            $A.util.removeClass(component.find('ProjectWO'), 'Project');
        }
       
    	  if(stop!='Project'){
            $A.util.addClass(component.find('ProjectWO'), 'Project');
        }
        
                   if(stop=='Vehicle Maintenance'){
            $A.util.removeClass(component.find('VehicleWO'), 'Vehicle');
        }
       
    	  if(stop!='Vehicle Maintenance'){
            $A.util.addClass(component.find('VehicleWO'), 'Vehicle');
        }
        
        
           if(stop=='Colleague Assistance'){
            $A.util.removeClass(component.find('ColleagueWO'), 'ColleagueA');

        }
        
           if(stop!='Colleague Assistance'){
            $A.util.addClass(component.find('ColleagueWO'), 'ColleagueA');

        }

}

})