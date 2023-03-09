({
    /**
     * Call server to with the passed recordId from the parent cmp to get the full TimeSlot sObject.
     * If successful, pre pop form field values.
     *
     * @param cmp
     */
    retrieveTimeSlotToClone: function (cmp) {
        let timeSlotId = cmp.get('v.recordId');
        let params = {tsId:timeSlotId};

        cmp.lax.enqueue('c.retrieveTimeSlot',params)
            .then(response => {
            this.popFormFields(cmp, response);
        })
        .catch(errors => {
            //cmp.set("v.showSpinner", false);
            //this.handleInitErrors(cmp,errors);
        });
    },
    popFormFields: function(cmp,response) {
        var dto = response;
        if(dto.isSuccess) {
            try {
                console.log('------ prepop -----------');
                console.log(dto);
                let collectionUtils = cmp.find('collectionUtils');
                let tsDateWrap;
                collectionUtils.getMapValue('TS_DATE_WRAP', dto.values, function (value) {
                    tsDateWrap = value;
                });
                cmp.set('v.sObjectTimeSlot',dto.sObj);
                cmp.find('dayOfWeek').set('v.value','');
                cmp.find('type').set('v.value',dto.sObj.Type);
                console.log('TimeSlot sObject='+JSON.stringify(cmp.get('v.sObjectTimeSlot')));
                let dbStartTime = dto.sObj.StartTime; //numeric millisecond value.
                let dbEndTime = dto.sObj.EndTime; //numeric millisecond value.
                if(dbStartTime) {
                    console.log('---dbStartTime='+dbStartTime);
                    let sStart = tsDateWrap.sStartDateLocal; //converted up in apex as it's a pita down here with this time ui object.
                    console.log('---start='+sStart);
                    cmp.set('v.startTime', sStart);
                    cmp.find('fldStartTime').set('v.value',sStart);
                }
                if(dbEndTime) {
                    console.log('---dbEndTime='+dbEndTime);
                    let sEnd = tsDateWrap.sEndDateLocal; //converted up in apex as it's a pita down here with this time ui object.
                    console.log('---end='+sEnd);
                    cmp.set('v.endTime', sEnd);
                    cmp.find('fldEndTime').set('v.value',sEnd);
                }
                cmp.find('opHrsName').set('v.value',dto.sObj.OperatingHours.Name);
                cmp.set("v.showSpinner", false);
                cmp.find('dayOfWeek').getElement().focus();
            } catch (e) {
                console.error(e);
                cmp.set("v.showSpinner", false);
            }
        } else {
            cmp.set("v.showSpinner", false);
        }
    },
    handleErrors: function(cmp) {
        //handle ss errors.
    },
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    }
})