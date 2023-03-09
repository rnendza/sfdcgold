({
    init: function (cmp, event, helper) {
        cmp.set("v.showSpinner", true);
        helper.initDatatableColumns(cmp);
        helper.getUserTerritories(cmp);
    },
    updateColumnSorting: function (cmp, event, helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
    handleCopyTimeSlotSuccess: function(cmp,event,helper) {
        let param = event.getParam('param');
        let type = param.type;
        let payload = param.payload;
        let msg = 'TimeSlot successfully created for '+payload.fields.DayOfWeek.displayValue + ' from ' + payload.fields.StartTime.displayValue + ' to ' +payload.fields.EndTime.displayValue;
        helper.displayUiMsg(cmp,type,msg);
        helper.getTimeSlotData(cmp);
    },
    /**
     * A hack to account for the fact that force:editRecord does not provide a callback.
     * Ie. we have to attach a handler to the toast.
     *
     * @param cmp
     * @param event
     * @param helper
     */
    refreshAll: function (cmp, event, helper) {
        var eventType = event.getParam('type');
        var indexCall = 0; // to make it call only 1 time.
        if (eventType == 'SUCCESS') {
            if (indexCall == 0) {
                indexCall += 1;
                if(cmp && cmp.isValid()) {
                    try {
                        helper.getTimeSlotData(cmp);
                    } catch (e) {
                        console.error(e);
                    }
                }
            }
        }
    },
    onChangeServiceMember: function (cmp, event, helper) {
        cmp.set('v.showSpinner',true);
        var selectedServiceMemberId = cmp.get('v.selectedServiceMemberId');
        helper.getTimeSlotData(cmp);
    },
    onChangeDaysOfWeek: function (cmp, event, helper) {
        cmp.set('v.showSpinner',true);
        helper.getTimeSlotData(cmp);
    },
    onChangeTerritory: function (cmp, event, helper) {
        cmp.set('v.showSpinner',true);
        var selectedTerritoryId = cmp.get('v.selectedTerritoryId');
        var userTerritories = cmp.get('v.userTerritories');
        for (var i = 0; i < userTerritories.length; i++) {
            var userTerritory = userTerritories[i];
            if (userTerritory.FSL__ServiceTerritory__c === selectedTerritoryId) {
                cmp.set('v.currentTerritory', userTerritory);
                break;
            }
        }
        cmp.set('v.selectedServiceMemberId', null);
        cmp.set('v.showServiceMbrPl',true);
        helper.getTimeSlotData(cmp);
    },
    handleNewClick: function (cmp, event, helper) {
        var createRecordEvent = $A.get("e.force:createRecord");
        var windowHash = window.location.hash;
        createRecordEvent.setParams({
            "entityApiName": "TimeSlot",
            "panelOnDestroyCallback": function(event) {
                window.location.hash = windowHash;
            }
        });
        createRecordEvent.fire();
    },
    handleServiceMemberChange: function (cmp, event, helper) {
        //alert('handle t change='+event.getParam('value'));
    },
    handleRowAction: function (cmp, event, helper) {
        var action = event.getParam('action');
        var row = event.getParam('row');
        console.log(action.name);
         switch (action.name) {
             case 'editRecord':
                 var editRecordEvent = $A.get("e.force:editRecord");
                 editRecordEvent.setParams({"recordId": row.timeSlotId});
                 editRecordEvent.fire();
                 break;
             case 'deleteRecord':
                 if(confirm('Are you sure?')) {
                    helper.deleteTimeSlot(cmp,row);
                 }
                 break;
             case 'cloneRecord':
                helper.doOpenCloneModal(cmp, row);
                break;
         }
    }
})