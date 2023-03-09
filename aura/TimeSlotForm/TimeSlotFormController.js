({
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleLoad : function(cmp,event,helper) {
        helper.retrieveTimeSlotToClone(cmp);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleSubmit : function(cmp,event,helper) {
        event.preventDefault();       // stop the form from submitting
        var fields = event.getParam('fields');
       // var sStartTime = cmp.get('v.startTime');
        let sStartTime = cmp.find('fldStartTime').get('v.value');
        let sEndTime  =  cmp.find('fldEndTime').get('v.value');
        //hack but needs something. ie user didn't change time at all from clone time is coming as 23:15 (no seconds or anything)
        if(sStartTime.length < 7) {
            sStartTime += ':00.000'
        }
        if(sEndTime.length < 7) {
            sEndTime += ':00.000';
        }
        fields["StartTime"] = sStartTime;
        fields["EndTime"] = sEndTime;

        fields["OperatingHoursId"] = cmp.get('v.sObjectTimeSlot').OperatingHoursId;
        console.log(JSON.stringify(fields));
        cmp.find('cloneTimeSlotForm').submit(fields); // Submit form
        cmp.set('v.showSpinner',true);
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleSuccess: function(cmp,event,helper) {
        let payload = event.getParams().response;
        console.log('payload='+JSON.stringify(payload));
        cmp.set('v.showSpinner',false);

        let evt = $A.get("e.c:Accel_Evt_Generic");
        let params = {type: 'success', payload: payload};
        cmp.find("overlayLib").notifyClose();
        try {
            evt.setParams({param: params});
            console.log('2firing appEventCopyTimeSlotSuccess with payload:'+JSON.stringify(params));
            evt.fire();
        } catch (e) {
            alert(e);
            console.error(e);
        }
        //$A.get('e.force:refreshView').fire();
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleError: function(cmp,event,helper) {
        let error = event.getParams().error;
        let payload=error;
        console.log('payload='+JSON.stringify(error));
        let msg;
        try {
            msg = payload.body.output.errors[0].message;
        } catch (e) {
            console.error(e);
        }
        if(!msg) {
            try {
                msg = payload.body.message;
            } catch (e) {
                console.error(e);
            }
        }
        if(msg) {
            helper.displayUiMsg(cmp, 'error', msg);
        }
        cmp.set('v.showSpinner',false);
        cmp.find("overlayLib").notifyClose();
    },
    handleCancel : function(cmp, event, helper) {
        //closes the modal or popover from the component
        cmp.find("overlayLib").notifyClose();
    }
});