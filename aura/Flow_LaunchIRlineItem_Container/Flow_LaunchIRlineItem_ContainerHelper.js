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
        const securityParams = {"customPermissionApiName": cmp.get('v.customPermissionCreateAssetsApiName')};
        const securityAction = 'c.doesUserHavePermission';

        this.log(cmp,'calling apex retrieveInventoryRequestLineItem with params','debug', JSON.stringify(liParams));
        this.log(cmp,'calling apex doesUserHavePermission','debug', JSON.stringify(securityParams));

        cmp.lax.enqueueAll([      //   Call multiple concurrent actions.
            {name: liAction, params: liParams},
            {name: securityAction, params: securityParams}
        ])
            .then(response => {
                const liResponse = response[0];
                const securityResponse = response[1];
                const liDto = liResponse;
                this.log(cmp,'response from retrieveInventoryRequestLineItem','debug', JSON.stringify(liResponse));
                if (liDto.isSuccess) {
                    cmp.set('v.inventoryRequestLineItem', liDto.sObj);
                } else {
                    const msg = 'unable to find Inventory_Request_Line_Item__c with params:';
                    this.log(cmp,msg,'error', JSON.stringify(liParams));
                }
                cmp.set('v.doesUserHaveCreateAssetPermission', securityResponse);
                const msg = 'Security to get assets:' + securityResponse;
                this.log(cmp, msg, 'debug');
                // double check (this should get caught in component settings in the record page.
                this.checkSecurityToCreateAssets(cmp);
                cmp.set('v.initCompleted',true);
            })
            .catch(errors => {
                let msg = 'Error retrieving the inventory request.';
                this.handleInitErrors(cmp, errors, msg);
            });
    },
    /**
     * This is essentially a double check as this is primarily controlled via component visibility settings in the
     * record page editor.
     * @param cmp
     */
    checkSecurityToCreateAssets: function(cmp) {
      let showIt = false;
      let lineItem = cmp.get('v.inventoryRequestLineItem');
      if(cmp.get('v.doesUserHaveCreateAssetPermission')) {
        if(lineItem && lineItem.Eligible_to_Create_Assets__c) {
            showIt = true;
        }
      }
      cmp.set('v.showFireButton',showIt);
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
     *
     * @param cmp
     */
    navigateToMasterRecord: function (cmp) {
        let navSvc = cmp.find("navService");
        let ir = cmp.get('v.inventoryRequestLineItem');
        if(ir && ir.Inventory_Request__c) {
            let recordId = ir.Inventory_Request__c;
            let pageRef = {
                type: 'standard__recordPage',
                attributes: {
                    actionName: 'view',
                    objectApiName: 'Inventory_Request__c',
                    recordId: recordId
                },
            };
            navSvc.navigate(pageRef, true);
        }
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
        let outputErrorMsg = '';
        for(let i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            if(outputVar.name === 'varOutputNumberOfAssetsCreated') {
                cmp.set('v.numberOfAssetsCreated', outputVar.value);
            } else if ( outputVar.name === 'varOutputErrorMsg'){
                outputErrorMsg = outputVar.value;
            }
        }
        if(cmp.get('v.numberOfAssetsCreated') === 0) {
            success = false;
            msg = 'There was a problem creating assets. No assets were created. ';
            if(outputErrorMsg && outputErrorMsg !== '') {
                msg += '\n\n '+outputErrorMsg;
            }
        } else {
            success = true;
            msg = 'Assets created successfully';
            //------------ push this as refresh view is not always going to work for this component..
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