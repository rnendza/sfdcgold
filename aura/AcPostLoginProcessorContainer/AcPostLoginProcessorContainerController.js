({
    /**
     * Uses force:showToast to fire a toast event.
     * payload is a js object set with the event to build the toast..
     *
     * Fox Example:
     *
     *   let payload = { msg:msg, linkUrl:url, linkLabel:'VIEW LOCATION DETAILS',title:'',
     *                  msgTemplate : msgTemplate, type:'warning',mode:'dismissible',duration:999999};
     * @param cmp
     * @param event
     */
    handleShowNotification : function(cmp, event) {
        let payload = event.getParam('payload');
        if(payload) {
            let toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                mode: payload.mode,
                title: payload.title,
                duration: payload.duration,
                type : payload.type,
                message: 'Sample',
                messageTemplate: payload.msgTemplate,
                messageTemplateData: [
                    payload.msg,
                    {
                        url: payload.linkUrl,
                        label: payload.linkLabel,
                    }
                ]
            });
            try {
                toastEvent.fire();
            } catch (e) {
                console.error(e);
            }
        }
    }
});