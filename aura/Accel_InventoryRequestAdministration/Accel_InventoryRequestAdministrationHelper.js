({
    /**
     * Calls the server to retrieve the Inventory_Request_Line_Item__c based on the context ie recordId
     * Will also check if the user has the custom permission to create assets. (@
     *
     * @param cmp
     */
    retrieveInitData: function (cmp) {
        let irLineItemId = cmp.get('v.selectedRecordId');       // record id in ctx

        //   Line item related retrieval
        const liParams = {"irLineItemId": irLineItemId};
        const liAction = 'c.retrieveInventoryRequestLineItem';
        //   Security related retrieval.
        const securityAction = 'c.retrieveUserProfile';
        //   Asset existence related retrieval
        const lineItemAssetsExistAction = 'c.doesIrLineItemHaveAssets';

        this.log(cmp,'calling apex retrieveInventoryRequestLineItem with params','debug', JSON.stringify(liParams));
        this.log(cmp,'calling apex retrieveUserProfile','debug');
        this.log(cmp,'calling apex doesIrLineItemHaveAssets with params:','debug',JSON.stringify(liParams));
        cmp.set('v.showSpinner',true);
        cmp.lax.enqueueAll([      //   Call multiple concurrent actions.
            {name: liAction, params: liParams},
            {name: securityAction},
            {name: lineItemAssetsExistAction, params: liParams},
        ])
            .then(response => {
                const liResponse = response[0];
                const securityResponse = response[1];
                const lineItemsExistResponse = response[2];
                const liDto = liResponse;

                this.log(cmp,'response from retrieveInventoryRequestLineItem','debug', JSON.stringify(liResponse));
                if (liDto.isSuccess) {
                    cmp.set('v.inventoryRequestLineItem', liDto.sObj);
                } else {
                    const msg = 'unable to find Inventory_Request_Line_Item__c with params:';
                    this.log(cmp,msg,'error', JSON.stringify(liParams));
                }
                cmp.set('v.runningUserProfile',securityResponse);
                cmp.set('v.doesIrLineItemHaveAssets',lineItemsExistResponse);
                cmp.set('v.showSpinner',false);
                cmp.set('v.doneWithInit',true);
            })
            .catch(errors => {
                let msg = 'Error retrieving the inventory request.';
                cmp.set('v.showSpinner',false);
                this.handleInitErrors(cmp, errors, msg);
            });
    },
    /**
     * Evaluates the dto containing the purchase order. if we already created software, do not fire the flow and
     * toast a msg / close modal, otherwise fire the flow with po and qty data.
     *
     * @param cmp
     * @param response the response from the call to the server to retrieve the po.
     */
    fireIrLineFlow: function (cmp) {
        const flowName = cmp.get('v.flowName');
        const flow = cmp.find("flowData");
        cmp.set('v.fireFlow',true);
        cmp.set('v.isRunningFlow',true);

        const irLine = cmp.get('v.inventoryRequestLineItem');
        let inputVariables = [
            {name: "varInputRecordId", type: "String", value: irLine.Id}
        ];
        try {
            this.log(cmp,'flowName being fired=' + flowName,'debug');
            this.log(cmp,'input vars to flow','debug',JSON.stringify(inputVariables));
            flow.startFlow(flowName, inputVariables);
            cmp.set('v.isRunningFlow', true);
            cmp.set('v.showSpinner',true);
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
        for(let i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            if(outputVar.name === 'varOutputNumberOfAssetsCreated') {
                cmp.set('v.numberOfAssetsCreated', outputVar.value);
            } else if ( outputVar.name === 'varOutputNumberOfAssetsCreated')  {

            }
        }
        if(cmp.get('v.numberOfAssetsCreated') === 0) {
            success = false;
            msg = 'There was a problem creating assets. No assets were created.';
        } else {
            success = true;
            msg = 'Assets created successfully';
            this.retrieveInitData(cmp);
            $A.get('e.force:refreshView').fire();
        }
        cmp.set('v.createError',!success);
        if(success) {
            this.displayUiMsg(cmp,'success',msg);
        } else {
            this.displayUiMsg(cmp,'error',msg);
            cmp.set('v.showFireButton',true);
        }
    },
    deleteAssets: function (cmp) {
        const irLine = cmp.get('v.inventoryRequestLineItem');
        const deleteParams = {"irLineItemId": irLine.Id};
        const deleteAction = 'c.deleteIrLineItemAssets';
        cmp.set('v.showSpinner',true);
        cmp.lax.enqueue(deleteAction,deleteParams)
            .then(response => {
                let msg = 'Assets Could not be deleted!';
                let type = 'error';
                if(response) {
                    let dto = response;
                    if(dto.isSuccess) {
                        msg = dto.message;
                        type = 'success';
                        this.retrieveInitData(cmp);
                        $A.get('e.force:refreshView').fire();
                    } else {
                        msg = dto.message;
                        type = 'error';
                    }
                }
                this.displayUiMsg(cmp,type,msg);
                cmp.set("v.showSpinner", false);
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleInitErrors(cmp,errors);
            });
    },
    makeIrLineEligibleToCreateAssets: function (cmp) {
        const irLine = cmp.get('v.inventoryRequestLineItem');
        const params = {"irLineItemId": irLine.Id};

        const action = 'c.makeIrLineEligibleToCreateAssets';
        cmp.set('v.showSpinner',true);
        this.log(cmp,'calling makeIrLineEligibleToCreateAssets','debug',JSON.stringify(params));
        cmp.lax.enqueue(action,params)
            .then(response => {
                let msg = 'Record could not be updated';
                let type = 'error';
                if(response) {
                    let dto = response;
                    if(dto.isSuccess) {
                        msg = dto.message;
                        type = 'success';
                        this.retrieveInitData(cmp);
                        $A.get('e.force:refreshView').fire();
                    } else {
                       // irLine.Eligible_to_Create_Assets__c = false;
                        this.retrieveInitData(cmp);
                        //$A.get('e.force:refreshView').fire();
                        msg = dto.message;
                        type = 'error';
                    }
                }
                this.displayUiMsg(cmp,type,msg);
                cmp.set("v.showSpinner", false);
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleInitErrors(cmp,errors);
            });
    },
    makeIrLineInEligibleToCreateAssets: function (cmp) {
        const irLine = cmp.get('v.inventoryRequestLineItem');
        const params = {"irLineItemId": irLine.Id};

        const action = 'c.makeIrLineInEligibleToCreateAssets';
        cmp.set('v.showSpinner',true);
        this.log(cmp,'calling makeIrLineInEligibleToCreateAssets','debug',JSON.stringify(params));
        cmp.lax.enqueue(action,params)
            .then(response => {
                let msg = 'Record could not be updated';
                let type = 'error';
                if(response) {
                    let dto = response;
                    if(dto.isSuccess) {
                        msg = dto.message;
                        type = 'success';
                        this.retrieveInitData(cmp);
                        $A.get('e.force:refreshView').fire();
                    } else {
                        // irLine.Eligible_to_Create_Assets__c = false;
                        //$A.get('e.force:refreshView').fire();
                        msg = dto.message;
                        type = 'error';
                    }
                }
                this.displayUiMsg(cmp,type,msg);
                cmp.set("v.showSpinner", false);
            })
            .catch(errors => {
                cmp.set("v.showSpinner", false);
                this.handleInitErrors(cmp,errors);
            });
    },
    /**
     * Toast an error msg with user friendly msg.
     *
     * @param cmp
     * @param errors
     */
    handleInitErrors: function(cmp, errors,msg) {
        console.error(JSON.stringify(errors));
        this.displayUiMsg(cmp,'error',msg);
        cmp.set('v.showSpinner',false);
    },
    /**
     * Fires a toast..
     *
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