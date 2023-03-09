({
    /**
     * Sets static var for various helper objects. Fire the query to retrieve all field set wraps and members
     * if we have a list of selected field sets in ctx.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    doInit: function(cmp,event,helper) {
        cmp.set('v.showFsSpinner',true);
        helper.initUtils(cmp);
        var highlight = cmp.find('highlight');

        $A.util.addClass(highlight, 'HighlightField');

    },
    /**
     * Calls a server side update with the sObject. (maybe branch off for validation or whatever else is necessary here
     * as well.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    updateForm: function(cmp,event,helper) {
        cmp.set('v.showFsSpinner',true);
        event.preventDefault();
        let sObject = helper.parseFormData(cmp,event,helper); //roll the eventFields param and build sObject.
        helper.updateSObject(cmp,sObject);
    },


  setFields: function(cmp,event,helper,fsMembers) {
		let getid = event.getParam('selectRecord');
	
      if(fsMembers) {
          fsMembers.forEach(function (fsMember) {
              if(fsMember.fieldType === 'REFERENCE') {
			
              let   recordName = {};
                  if(fsMember.fieldValue) {
                    
                      
                fsMember.fieldValue = getId;
                  }
                  
              }
          
          }
                           )}
  
                            
       // cmp.set('v.selectedLookUpRecord', getid);
    }   ,

    /**
     * Evaluates an event fired by uiPicklist to determine what field set(s) to retrieve.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handlePageCategorySelectedEvent: function (cmp, event, helper) {
        let payload = event.getParam('payload');
        helper.log(cmp,cmp.getName()+'.handlePageCategorySelect','info',JSON.stringify(payload));
        if (payload) {
            if (payload.objectApiName === 'Opportunity' && payload.fieldApiName === 'Page_Category__c') {
                let payloadCopy = Object.assign({}, payload);
                let selectedValue = payloadCopy.value;
                let pageCategoryFieldApiName = payload.fieldApiName;
                if (selectedValue) {
                    cmp.set('v.fieldSetWrappersExist', false); //clear the dom.. record edit form gets weird if you don't
                    cmp.set('v.pageCategorySelected', selectedValue);
                    cmp.set('v.pageCategoryFieldApiName',pageCategoryFieldApiName);
                    selectedValue = selectedValue.replace(/ /g, '_').toLowerCase();
                    let selected = [];
                    selected.push(selectedValue);
                    cmp.set('v.selectedFieldSets', selected);
                    cmp.set('v.showFsSpinner', true);
                    helper.retrieveSpecificFieldSetWrappersAndFieldSetMembers(cmp);
              
                }
            }
        }
    },
    /**
     * Handles click of the edit button while in view mode. to toggle over to edit mode.
     */
    handleEditClick: function (cmp,event,helper) {
        cmp.set('v.showFsSpinner',false);
        cmp.set('v.displayMode','edit');
    },
    /**
     * Pops the confirm dialog when canceling edit. Attempts to scroll to top otherwise viewport ends up towards the
     * bottom.
     */
    handleCancelClick: function (cmp,event,helper) {
        cmp.set('v.displayMode','view');
        helper.scrollToTop(cmp);
    },
    //-----------------------------------------------  FOR FUTURE USE -------------------------------------------------
    handleTouchMove: function(cmp,event) {
        //--------------event.stopPropagation();
        // console.log('---> touchmove');
        // console.log('touches-->'+JSON.stringify(event.touches));
    },
    handleTouchStart: function(cmp,e) {
        // console.log('---> touchstart');
        // let clientX = e.touches[0].clientX;
        // let clientY = e.touches[0].clientY;
        // console.log('x, y-->'+clientX + ',' +clientY);
    },
    handleTouchCancel: function(cmp,event) {
        // console.log('---> touchcancel');
    },
    handleTouchEnd: function(cmp,event) {
        // console.log('---> touchend');
    },
    onRender: function(cmp,event,helper) {
        const fsWrapCmp = cmp.find('fieldSetViewContainer');
        let _self = this;
        if(fsWrapCmp) {
            //we found it give it some time to paint the record form inputs..
            // window.setTimeout(
            //      $A.getCallback(function() {
            //        helper.specifyViewFormContainerSize(cmp);
            //      }), 2000
            // );
        }
    }
});