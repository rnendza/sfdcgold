({
    collectionUtils:null, loggingUtils:null,
    /**
     * Take the record type id from the pageReference from the record type selection page and use it to call the
     * server to get the developername so we can pass it to the screen flow.
     * @param cmp
     */
    retrieveRecordTypeViaId: function(cmp) {
        const action = 'c.retrieveRecordTypeViaId';
        const params = {rtId : cmp.get('v.selectedRecordTypeId')};

        this.log(cmp,'calling retrieveRecordTypeViaId','debug',JSON.stringify(params));
        cmp.lax.enqueue(action,params)
            .then(response => {
                if(response) {
                    let dto = response;
                    this.log(cmp, 'cb of retrieveRecordTypeViaId: ','debug',dto);
                    if(dto.isSuccess) {
                        cmp.set('v.irRecordType',dto.sObj);
                        this.fireFlow(cmp);
                    } else {
                        let msg = dto.message;
                        let type = 'error';
                        this.log(cmp, dto.technicalMsg,'error',dto);
                        this.displayUiMsg(cmp,type,msg);
                    }
                }
            })
            .catch(errors => {
                this.handleInitErrors(cmp,errors);
            });
    },
    /**
     *
     * @param cmp
     */
    fireFlow: function (cmp) {
        const flowName = cmp.get('v.flowName');
        const flow = cmp.find("flowData");

        const recordType = cmp.get('v.irRecordType');
        let inputVariables = [
            {name: "varInputIrRecordTypeDevName", type: "String", value: recordType.DeveloperName}
        ];
        try {
            console.log('---------- firing flow with params:'+JSON.stringify(inputVariables));
            flow.startFlow(flowName, inputVariables);
        } catch (e) {
            alert('ERROR!' + JSON.stringify(e));
        }
    },
    /**
     * Rolls through the outputVar collection returned from the flow and grabs
     * the total number of assets created output variable.
     *
     * @param cmp
     * @param outputVariables
     */
    parseFlowOutputVars: function (cmp,outputVariables) {
        let outputVar;
        let success = false;
        let msg = '';

        this.log(cmp,'outputvariables','debug',JSON.stringify(outputVariables));
        let ir;

        for(let i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            if(outputVar.name === 'varInventoryRequest') {
                ir = outputVar.value;
            } else if ( outputVar.name === 'varOutputNumberOfAssetsCreated')  {

            }
        }
        if(ir) {
            if(ir.Name) {
               success = true;
               msg = 'Inventory Request '+ir.Name + ' created successfully.';
            }
        }
        if(!success) {
            msg = 'There was a probably creating the inventory request.';
        }
        if(success) {
             this.displayUiMsg(cmp,'success',msg);
        } else {
             this.displayUiMsg(cmp,'error',msg);
        }
    },
    /**
     *
     * @param cmp
     */
    closeCurrentTab: function (cmp) {
        let currentTabId = cmp.get('v.currentTabId');
        if(currentTabId) {
            let workspaceAPI = cmp.find("workspace");
            try {
                workspaceAPI.closeTab({tabId: currentTabId});
            } catch (e) {
                alert('here3');
                alert(e);
            }
        }
    },
    /**
     *
     * @param cmp
     */
    storeCurrentTabId: function(cmp) {

        if(this.isConsoleNavigation(cmp)) {
            try {
                let workspaceAPI = cmp.find("workspace");
                workspaceAPI.getFocusedTabInfo().then(function (response) {
                    let focusedTabId = response.tabId;
                    cmp.set('v.currentTabId', focusedTabId);
                })
                    .catch(function (error) {
                        alert(error);
                        console.log(error);
                    });
            } catch (e) {
                console.error(e);
            }
        }
    },
    /**
     * Init general aura utils.
     * @param cmp
     */
    initUtils:  function(cmp) {
        this.collectionUtils = cmp.find('collectionUtils');
        this.loggingUtils = cmp.find('loggingUtils');
        this.uiMessagingUtils = cmp.find('uiMessagingUtils');
    },
    /**
     *
     * @param cmp
     * @param event
     * @param helper
     */
    handleViewCreateIrHelp: function(cmp,event,helper) {
        let recordId = cmp.get('v.contentDocumentRecordId');
        if(recordId) {
            try {
                $A.get('e.lightning:openFiles').fire({
                    recordIds: [recordId]
                });
            } catch (e) {
                alert(e); //not sure this works. @TODO find way to handle above error.
            }
        }
    },
    /**
     * Determine if we are in a console app or not.
     * @param cmp
     * @return true if in a console app, otherwise false
     */
    isConsoleNavigation : function(cmp) {
        let workspaceAPI = cmp.find("workspace");
        let inConsole = false;
        workspaceAPI.isConsoleNavigation().then(function(response) {
            inConsole = response;
            return inConsole;
        })
            .catch(function(error) {
                console.log(error);
                return inConsole;
            });
    },
    /**
     * Toast an error msg with user friendly msg.
     * @param cmp
     * @param errors
     */
    handleInitErrors: function(cmp, errors,msg) {
        console.error(JSON.stringify(errors));
        this.displayUiMsg(cmp,'error',msg);
    },
    /**
     * Fires a toast..
     * @param cmp
     * @param type [success,warning,error]
     * @param msg
     */
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    /**
     * Simply a wrapper around The Utils Component / log method.
     *
     * @param cmp
     * @param msg - the message to logn...
     * @param level [debug,info,warn,error]
     * @param jsonObj  optional a JSON OBJECT and not a string!
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
        } else  {
            lvl = level;
        }
        try {
            if (cmp.get("v.debugConsole") || lvl === 'error') {
                var cmpName = '---- '+cmp.getName() + ' ----';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, lvl, msg, jsonObj);
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