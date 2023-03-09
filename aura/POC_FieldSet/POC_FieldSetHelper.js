({
    MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS : 'FS_WRAPS_AND_MEMBERS',
    PAGE_CAT_FIELD_API_NAME             : 'Page_Category__c', //@TODO grab dynamically with design prop.
    collectionUtils:null, loggingUtils:null, uiMessagingUtils: null,
    /**
     * Retrieves field set(s) wraps (based on user selected values) and their child field sets members (ie fields)
     *
     * @param cmp
     * @see apex class FieldSetWrapper
     * @see apex class FieldSetMember.
     * ie. FieldSetWrapper:
     *        fieldSetApiName
     *        fieldSetSObjectApiName
     *        List<FieldSetMemberWrapper> fieldSetMemberWrappers
     *        (FieldSetMemberWrapper):
     */
    retrieveSpecificFieldSetWrappersAndFieldSetMembers: function (cmp) {
        let fieldSets = cmp.get('v.selectedFieldSets');
        let _self = this;
        let params = {
            sObjectApiName: cmp.get('v.selectedSObjectApiName'),
            sObjectRecordId: cmp.get('v.selectedSObjectRecordId'),
            fieldSetApiNames: fieldSets
        };
        this.log(cmp,'calling apex to retrieve fs.. with params','debug',params);
        cmp.lax.enqueue('c.retrieveSpecificFieldSetWrappersAndFieldSetMembers', params)
            .then(dto => {
                this.log(cmp,'dto from retrieving data','warn',dto);
                if(dto.isSuccess) {
                    cmp.set('v.fieldSetWrappers',null);
                    let fsWraps = this.collectionUtils.getData(this.MAP_KEY_FIELD_SET_WRAPS_AND_MEMBERS, dto.values);
                    cmp.set('v.fieldSetWrappersExist', fsWraps && fsWraps.length>0);
                    this.checkExistenceOfFieldSetFields(cmp,fsWraps);
                    cmp.set('v.fieldSetWrappers',fsWraps);
                    cmp.set('v.showFsSpinner', false);
                    cmp.set('v.displayMode','view');

                } else {
                    cmp.set('v.showFsSpinner',false);
                    let msg = 'There was an issue retrieving your data.';
                    this.displayUiMsg(cmp,'error',msg);
                }
            })
            .catch(errors => {
                this.log(cmp, 'generic', 'error', JSON.stringify(errors));
                this.displayUiMsg(cmp,'error',dto.message);
                cmp.set('v.showFsSpinner', false);
               // alert('CEDRIC TESTING AGAIN '+dto.title);

            });
    },
    specifyViewFormContainerSize: function(cmp) {
       // const fsWrap = cmp.find('fieldSetViewContainer');
        let fsWrap = document.getElementById('fieldSetViewContainer');
        if(fsWrap) {
            let domRect = fsWrap.getBoundingClientRect();
            if(domRect) {
                cmp.set('v.viewContainerHeight',domRect.height + 'px');
            }
        }
    },
    /**
     * Roll through the field set wraps and dynamically set a property on the fs wrap to indicate to the ui
     * that members (ie fields exist) so that the save button can appear.
     *
     * @param cmp
     * @param fsWraps
     */
    checkExistenceOfFieldSetFields: function (cmp, fsWraps) {
        if (fsWraps) {
            for (let i = 0; i < fsWraps.length; i++) {
                let fsWrap = fsWraps[i];
                fsWrap.fieldSetMembersExist = fsWrap.fieldSetMemberWrappers && fsWrap.fieldSetMemberWrappers.length > 0;
                if (fsWrap.fieldSetMembersExist) {
                    this.tagLookupsWithInitialValue(cmp, fsWrap.fieldSetMemberWrappers);
                }
            }
        }
    },
    /**
     * Update Opportunity with values edited in the form. forces a refresh of the entire page as well.. then swaps
     * mode to view mode. We must Essentially refresh the entire view (standard and custom components) as a simple
     * swap to the view form pulls up data cached by SFDC (known issue with SFDC)
     *
     * @param cmp
     * @param sObj   A valid Opportunity sObject with fields from the currently edited FieldSet form.
     */
    updateSObject: function(cmp, sObj,fsMembers) {
        let _self = this;

        if(sObj) {
            //  Sets Opportunity.Page_Category__c with the currently selected picklist value.
            let catSelected = cmp.get('v.pageCategorySelected');
            if(catSelected) {
                sObj[ this.PAGE_CAT_FIELD_API_NAME ] = catSelected;
            }
        }
        let params = {sObj: sObj,doRefresh: false};
      
        cmp.lax.enqueue('c.updateSObject', params)
            .then(dto => {
               // var Border = cmp.find('ErrorBorder');
                var Border = document.getElementById('ErrorBorder');

                if(dto.isSuccess) {
                    window.setTimeout(
                        $A.getCallback(function() {$A.util.removeClass(cmp.find('ErrorBorder'), 'Border');}), 50
                    );

                    var appEvent = $A.get("e.c:FieldSetName");
                    if(fsMembers) {
                        fsMembers.forEach(function (fsMember) {
                            console.log(fsMember.fieldSetName +'CEDRIC AGAIN');
                            appEvent.setParams({"FieldSetName": fsMember.FieldSetName});

                            appEvent.fire();


                        });
                    }

                    cmp.set("v.ErrorValue", '');

                    $A.util.removeClass(Border, 'Border');
                    this.log(cmp,'sObject successfully updated','info',JSON.stringify(dto.sObj));
                    cmp.set('v.updatedSObject',dto.sObj);
                    cmp.set('v.displayMode','view');
                    $A.get('e.force:refreshView').fire();
                    //  Note: we should not have to do this but without it refreshView will cause a double toast.
                    window.setTimeout(
                        $A.getCallback(function() {_self.displayUiMsg(cmp,'success',dto.message);}), 1000
                    );
                    this.scrollToTop(cmp);
                } else {
                    window.setTimeout(
                        $A.getCallback(function() {$A.util.addClass(cmp.find('ErrorBorder'), 'Border');}), 50
                    );
                    $A.util.addClass(Border, 'Border');

                    this.displayUiMsg(cmp, 'error', dto.message);
                    this.log(cmp, 'updateSObject dto', 'debug', dto);
                  //  cmp.set("v.DtoMessage",'ERROR FIELD: '+dto.title);
                    cmp.set("v.DtoField",dto.title);
                    cmp.set("v.ErrorValue", '* DOES NOT MATCH FILTER CRITERIA *');

                  /*  if (dto.title) {

                        var cmpTarget = cmp.find('Error');
                       $A.util.addClass(cmpTarget, 'Hide');
                    }*/
                    console.log('CEDRIC TESTING AGAIN ' + dto.title);


                    var highlight = cmp.find('highlight');
                    $A.util.addClass(highlight, "HighlightField");
                    if (fsMembers) {
                        fsMembers.forEach(function (fsMember) {
                                if (fsMember.fieldType === 'REFERENCE') {


                                        cmp.set("v.ErrorValue", fsMember.sObjectReferenceToNameFieldValue);
                                       // alert(cmp.get('v.ErrorValue'));
                                        var cmpTarget = cmp.find('Error');
                                        $A.util.addClass(cmpTarget, 'Hide');



                                }
                            }
                        )
                    }
                }
                cmp.set('v.showFsSpinner', false);
            })
            .catch(errors => {
                this.log(cmp, 'generic', 'error', JSON.stringify(errors));
                this.displayUiMsg(cmp,'error', 'Update failed: '+ JSON.stringify(errors));
                cmp.set('v.showFsSpinner', false);
            });
    },
    /**
     * Utilize the fields param in the recordEditForm and translate to an sObject to send to the server for an
     * explicit update / insert.
     *
     * @param cmp
     * @param event
     * @param helper
     * @returns {{Id: *, sobjectType: *}}
     */
    parseFormData: function(cmp,event,helper) {
        let _self = this;
        let eventFields = event.getParam("fields");
        let sObject = { 'sobjectType': cmp.get('v.selectedSObjectApiName'), Id: cmp.get('v.selectedSObjectRecordId')};
        Object.keys(eventFields).forEach(function(field) {
            let fieldValue = eventFields[field];
            if(!_self.isObject(fieldValue)) {
                sObject[field] = fieldValue;
            } else {
                _self.log(cmp,'discarding field as its prob a FF','warning', fieldValue);
            }
        });
        return sObject;
    },

    //===============================  General Utils Stuff =============================================================
    initUtils:  function(cmp) {
        this.collectionUtils = cmp.find('collectionUtils');
        this.loggingUtils = cmp.find('loggingUtils');
        this.uiMessagingUtils = cmp.find('uiMessagingUtils');
    },
    /**
     * Simply wraps a toast however this kinda shit does not work when 'previewing an app' (sfdc lameness)
     * So we wrap it an fire an alert if we are in preview mode.
     *
     * @param cmp
     * @param type      The type of toast. ie. success, warning, info, error.
     * @param msg
     */
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        try {
            cUiMessagingUtils.displayUiMsg(type, msg);
        } catch (e) {
            alert(msg);
            this.log(cmp, 'error popping toast','error',e);
        }
    },
    /**
     *
     * @param obj
     * @returns {boolean}
     */
    isObject : function(obj) {
        return obj !== undefined && obj !== null && obj.constructor == Object;
    },
    /**
     * Somewhat experimental. The idea is to not remain at the bottom of the form on a cancel or save edit
     * but this might not work in all version of mobile.
     *
     * @param cmp
     */
    scrollToTop: function(cmp) {
        try {
            window.scroll(0, 1);
        } catch (e) {
            this.log(cmp,'scrollToTop','error',e);
        }
    },
    /**
     * Merely a wrapper for console.log so that we can easily switch logging on and off in one place.
     * @param cmp
     * @param msg
     * @param level
     * @param jsonObj
     */
    log: function (cmp, msg, level, jsonObj) {
        let lvl;
        if (arguments.length === 0) {
            console.error('you must minimally pass the cmp ref and message to the log function');
            return;
        } else if (arguments.length === 1) {
            console.error('could not find message to log');
            return;
        } else if (arguments.length === 2) {
            lvl = 'debug';
        } else {
            lvl = level;
        }
        try {
            if (cmp.get("v.debugConsole") || lvl === 'error') {
                let cmpName = '--- '+cmp.getName() + '--- ';
                let cLogger = this.loggingUtils;
                cLogger.log(cmpName, lvl, msg, jsonObj);
                if(lvl === 'error' && msg.includes('generic')) {
                    let easyMsg = this.friendlyErrorMsg;
                    this.uiMessagingUtils.displayUiMsg(lvl, easyMsg,this.friendlyErrorMsgMode,this.friendlyErrorMsgDuration);
                }
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    },
                
                
                
                    tagLookupsWithInitialValue: function(cmp,fsMembers) {
      if(fsMembers) {
          fsMembers.forEach(function (fsMember) {
              if(fsMember.fieldType === 'REFERENCE') {

                  switch(fsMember.sObjectReferenceToApi){
                      case 'Account' :
                      fsMember.sObjectApiIconName ='action:new_account';
                      break;

                      case 'Contact' :
                          fsMember.sObjectApiIconName ='action:new_contact';
                          break;

                      case 'User' :
                          fsMember.sObjectApiIconName = 'action:User';
                          break;

                      default:
                          fsMember.sObjectApiIconName = 'action:custom9';
                          break;






                  }




			    console.log('Test Cedric '+fsMember.sObjectApiIconName);
                  let   recordName = {};
                  if(fsMember.fieldValue) {





                      //  let initialSelection = {'sobjectType': fsMember.sObjectReferenceToApi, Id: fsMember.fieldValue, Name: 'Test'};
                  let initialSelection = {};
                  
                  /*  var action = cmp.get('c.GetRecord');
                
                action.setParams({
                    
                    'recId': fsMember.fieldValue,
                    'RecName': fsMember.sObjectReferenceToApi

            });


        action.setCallback(this, function(response){
                            var state = response.getState();
                console.log(state);
          console.log(fsMember.sObjectReferenceToNameFieldValue); 
            if (state === 'SUCCESS'){
              var apiname = response.getReturnValue();
             //alert(cmp.find('AccountS').get('v.selectRecordId')); 
            }
            })     
             
            $A.enqueueAction(action);
 		//	cmp.find('lookupField').set('v.value', fsMember.fieldValue); */
             
                  
                  }
                  
             else{
                 var stuff={};
                 cmp.set('v.selectedLookupRecord',stuff);
                 
                // let appEvent2 = $A.get("e.c:Empty");
                 
             //    appEvent2.setParams({'EmptyField' : 'True'});
                 
               //  appEvent2.fire();
                      console.log('DO RAY ME FAH SO');
                  } 

                 
                   
                
              }
          });
      }
    }
});