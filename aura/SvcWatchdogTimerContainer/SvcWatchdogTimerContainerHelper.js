({
    SVC_WATCHDOG_PERMISSIONSET_API_NAME : 'Service_Watchdog_Component_Access',
    SVC_WATCHDOG_TITLE: 'Service Watchdog',
    loggingUtils:null, uiMessagingUtils: null,
    friendlyErrorMsg: 'An Error Occurred',friendlyErrorMsgDuration: 8,
    /**
     * Retrieves an instance of Service_Utility_Bar_Config__c (Custom Setting).
     * @param cmp
     */
    retrieveSvcWatchdogUtilityBarSettings: function (cmp) {
        let action = cmp.get('c.retrieveSvcWatchdogUtilityBarSettings');
        let _self = this;
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            let svcWatchdogSetting;
            if (state === "SUCCESS") {
                svcWatchdogSetting = response.getReturnValue();
                cmp.set( 'v.svcUtilityBarConfigSettings',svcWatchdogSetting );
                if(svcWatchdogSetting && svcWatchdogSetting.Debug_Console__c) {
                    cmp.set('v.debugConsole', svcWatchdogSetting.Debug_Console__c);
                }
                this.isUserInPermissionSet(cmp);
                _self.log(cmp,'utility bar config settings','info',JSON.stringify(svcWatchdogSetting));
            } else if (state === "ERROR") {
                let errors = response.getError();
                _self.log(cmp,'error retrieving utility bar config settings','error',JSON.stringify(errors));
            }
        }));
        $A.enqueueAction(action);
    },
    /**
     * Determines if user has appropriate permission set to view the watchdog.
     * @param cmp
     */
    isUserInPermissionSet: function (cmp) {
        let _self = this;
        let action = cmp.get('c.isUserInPermissionSet');
        action.setParams({ permissionSetApiName : this.SVC_WATCHDOG_PERMISSIONSET_API_NAME });
        action.setCallback(this, $A.getCallback(function (response) {
            let state = response.getState();
            let hasPermissionSet = false;
            if (state === "SUCCESS") {
                hasPermissionSet = response.getReturnValue();
                cmp.set( 'v.hasPermissionSet',hasPermissionSet );
                _self.dynamicallyConfigUtilityBar(cmp);
            } else if (state === "ERROR") {
                let errors = response.getError();
                _self.log(cmp,'error retrieving users permission set','error',JSON.stringify(errors));
            }
        }));
        $A.enqueueAction(action);
    },
    /**
     * Essentially just clear the utility bar title and icon if user does not have permission.
     * @param cmp
     */
    dynamicallyConfigUtilityBar: function(cmp) {
        let utilityBarAPI = cmp.find("utilitybar");
        if(utilityBarAPI) {
            if (!cmp.get('v.hasPermissionSet')) {
                utilityBarAPI.setUtilityIcon({icon: null});
                utilityBarAPI.setPanelHeaderLabel({label: null});
            } else {
                utilityBarAPI.setPanelHeaderLabel({label: this.SVC_WATCHDOG_TITLE});
            }
        } else {
            this.log(cmp,'no utility bar api in DOM yet','error');
        }
    },
    /**
     * Really all SFDC lets you do in analyze the click of the utility bar button (not interior of the popup) LAME!
     * Anyway this is called in after render to ensure we can find it (as opposed to on init of the cmp).
     *
     * @param cmp
     */
    registerUtilityClick : function(cmp) {
        let utilityBarAPI = cmp.find("utilitybar");
        let ubId;
        let _self = this;

        let eventHandler = function(response){
            _self.log(cmp,'ut bar evt handler response','debug',JSON.stringify(response));
            let hasPermissionSet = cmp.get('v.hasPermissionSet');
            if(!hasPermissionSet) {
                try {
                    let utilityBarAPI = cmp.find("utilitybar");
                    utilityBarAPI.setUtilityLabel({label: ""});
                    utilityBarAPI.setPanelHeaderLabel({label: ""});
                } catch (e) {
                    _self.log(cmp,'error setting utility bar label','error',JSON.stringify(e));
                }
            }
        };
        try {
            utilityBarAPI.getEnclosingUtilityId().then(function(utilityId) {
                ubId = utilityId;
                utilityBarAPI.onUtilityClick( {
                    eventHandler: eventHandler
                }).then(function (result) {
                    //  callback for future use
                }).catch(function (error) {
                    _self.log(cmp,'on click of utility bar error','error',JSON.stringify(error));
                });
            });
        } catch (e) {
            _self.log(cmp,'error getting enclosed utilitybar id','error',JSON.stringify(e));
        }
    },
    /**
     * Users the aura flow api to fire the service appointment alerts flow with contrived params.
     *
     * @param cmp
     * @param alertType             The type of Alert. Used by the flow for branching.
     * @param saId                  The service appointment Id.
     * @param assignedResourceId    The Assigned Resource Id of the Service Appointment.
     */
    fireSendServiceAppointmentAlertsFlow: function (cmp,alertType,saId,assignedResourceId) {
        const flowName = cmp.get('v.serviceAppointmentAlertsFlowName');
        const flow = cmp.find("serviceAppointmentsFlowData");
        const customNotificationApiName = cmp.get('v.serviceAppointmentCustomNotificationApiName');
        let _self = this;

        let inputVariables = [
            {name: "varInputAlertType", type: "String", value: alertType},
            {name: 'varInputOutputCustomNotificationApiName', type:"String", value: customNotificationApiName},
            {name: 'varInputOutputServiceAppointmentId', type:"String", value:saId},
            {name: 'varInputOutputAssignedResourceId', type:"String", value:assignedResourceId}
        ];
        try {
            _self.log(cmp,'flowName being fired','info',flowName);
            _self.log(cmp,'input vars to flow','info',JSON.stringify(inputVariables));
            flow.startFlow(flowName, inputVariables);
        } catch (e) {
            _self.log(cmp,'generic error','error',JSON.stringify(e));
        }
    },
    /**
     * If the user attempts a popout, Communication is lost with the popout and it will receive no updates.
     * Disable popout.
     *
     * @see https://accel-entertainment.monday.com/boards/286657232/pulses/314982925
     * @param cmp
     * @param event
     * @param helper
     */
    disableUtilityPopOut : function(cmp, event, helper) {
        let utilityAPI = cmp.find("utilitybar");
        utilityAPI.disableUtilityPopOut({
            disabled: true,
            disabledText: "Pop-out is disabled"
        });
    },
    /**
     * Sets a cmp boolean attribute determining if the cmp is visible or not.
     * @param cmp
     */
    isUtilityOpen : function (cmp) {
       let utilityAPI = cmp.find("utilitybar");
       utilityAPI.getUtilityInfo().then(function(result) {
           cmp.set('v.isWatchdogUtilityOpen',result.utilityVisible);
       });
    },
    //===============================  General Utils Stuff =============================================================
    /**
     * Sets a global variable to instances of the utilities.
     * @param cmp
     */
    initUtils:  function(cmp) {
        this.loggingUtils = cmp.find('loggingUtils');
        this.uiMessagingUtils = cmp.find('uiMessagingUtils');
    },
    /**
     * Merely a wrapper for console.log so that we can easily switch logging on and off in one place.
     *
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
});