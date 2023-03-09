({
    /**
     * Inits logging and ui messaging utils and retrieves the Svc Watchdog Utility Bar Custom Settings.
     */
    doInit: function(cmp,evt,helper) {
        helper.initUtils(cmp);
        helper.retrieveSvcWatchdogUtilityBarSettings(cmp);
    },
    /**
     * Sets the sum of the number of alerts on the utility bar.
     * @param cmp
     * @param evt
     */
    handleSetNbrOfAlerts: function( cmp, evt, helper) {
        let utilityAPI = cmp.find("utilitybar");
        let utilityLabel = evt.getParam('utilityLabel');
        utilityAPI.setUtilityLabel({ label : utilityLabel });
    },
    /**
     * Pops open the utility (1 time only)
     * @param cmp
     * @param evt  The custom Event fired by the lwc component.
     */
    handleOpenUtility: function( cmp, evt,helper) {
        let utilityAPI = cmp.find("utilitybar");
         utilityAPI.getUtilityInfo().then(function(result) {
            if(result.utilityVisible) {
                //  for future use.
            } else {
                if(cmp.get('v.hasPermissionSet')) {
                    utilityAPI.openUtility().then(function (result) {
                        if (result) {
                            helper.disableUtilityPopOut(cmp, evt, helper);
                        }
                    });
                }
            }
        });
    },
    /**
     * Highlights the utility bar when alerts exist.
     * @param cmp
     * @param evt
     */
    handleHighlightUtility: function(cmp,evt) {
        let utilityAPI = cmp.find("utilitybar");
        let highlighted = evt.getParam('highlightIt');
        try {
            if(cmp.get('v.hasPermissionSet')) {
                utilityAPI.setUtilityHighlighted({highlighted: highlighted});
            }
        } catch (e) {
            console.error(e);
        }
    },
    /**
     * Triggers the send of the service appointment custom notification (handle event triggered by child lwc) and fire
     * the flow.
     *
     * @param cmp
     * @param evt
     * @param helper
     */
    handleSendServiceAppointmentNotification: function(cmp,evt,helper) {
        const saId = evt.getParam('serviceAppointmentId');
        const assignedResourceId = evt.getParam('assignedResourceId');
        const alertType = cmp.get('v.alertType');
        helper.fireSendServiceAppointmentAlertsFlow(cmp,alertType,saId,assignedResourceId);
    },
    /**
     * Uses the workspaceApi to open a new primary console tab with the clicked caseId.
     *
     * @param cmp
     * @param evt  The custom Event fired by the lwc component upon clicking a case link
     * @param helper
     */
    handleRecordClicked: function(cmp, evt, helper) {
        let recordId = evt.getParam('recordId');
        let workspaceAPI = cmp.find("workspace");
        workspaceAPI.openTab({
            pageReference: {
                "type": "standard__recordPage",
                "attributes": {
                    "recordId":recordId,
                    "actionName":"view"
                },
                "state": {}
            },
            focus: true
        }).then(function(response) {
            workspaceAPI.getTabInfo({
                tabId: response
            }).then(function(tabInfo) {
                // callback for future use.
            });
        }).catch(function(error) {
            helper.log(cmp,'generic error','error',JSON.stringify(error));
        });
    },
    /**
     * Detect status changes in the flow.  consume flow output vars for ui messaging.
     *
     * @param cmp
     * @param event
     */
    statusChange: function (cmp, event ) {
        let s = event.getParam('status');
        const flowTitle = event.getParam('flowTitle');
        if(s === 'FINISHED_SCREEN') {
            let outputVars = event.getParam('outputVariables');
            let auraCmpLwcChild = cmp.find('svcWatchDogTimer');
            const lwcElm = auraCmpLwcChild.getElement();
            lwcElm.handleFlowResults(outputVars);
        } else if (s === 'Error' || s === 'ERROR') {
            let auraCmpLwcChild = cmp.find('svcWatchDogTimer');
            const lwcElm = auraCmpLwcChild.getElement();
            lwcElm.handleFlowError(event);
        }
    },
});