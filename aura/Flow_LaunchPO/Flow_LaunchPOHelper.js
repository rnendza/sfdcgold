({
    /**
     * Calls the server to the purchase order record then
     * Fires the flow with appropriate input vars.
     *
     * @param cmp
     */
    retrievePo: function (cmp) {
        cmp.set("v.showSpinner", true);
        let poId = cmp.get('v.recordId');
        let params = {"poId": poId};
        let action = 'c.retrievePo';
        this.log(cmp,'calling apex retrievePo with params','debug',JSON.stringify(params));
        cmp.lax.enqueue(action, params)
            .then(response => {
            this.firePoFlow(cmp, response);
        }).catch(errors => {
            cmp.set("v.showSpinner", false);
            let msg = 'Error retrieving the purchase order.';
            this.handleErrors(cmp, errors,msg);
        });
    },
    /**
     * Evaluates the dto containing the purchase order. if we already created software, do not fire the flow and
     * toast a msg / close modal, otherwise fire the flow with po and qty data.
     *
     * @param cmp
     * @param response the response from the call to the server to retrieve the po.
     */
    firePoFlow: function (cmp, response) {
        let dto = response;
        let flowName = cmp.get('v.flowName');
        if (dto.isSuccess) {
            let po = dto.sObj;
            let collectionUtils = cmp.find('collectionUtils');
            let customSetting = null;
            collectionUtils.getMapValue('SW_ASSET_CONFIG', dto.values, function (value) {customSetting = value;});
            this.log(cmp,'custom setting info retrieved.','debug',JSON.stringify(customSetting));
            let maxQty = 500;
            if (customSetting) {
                if (customSetting.Max_Single_Trans_Assets__c) {
                    maxQty = customSetting.Max_Single_Trans_Assets__c;
                }
            }
            if (!po.Quantity_of_Software_Created__c) {
                po.Quantity_of_Software_Created__c = 0;
            }
            if (!po.Quantity__c || po.Quantity__c === 0) {
                cmp.set('v.alreadyCreated', true);
                let msg = 'Software cannot be created for this PO (Please check the Qty field).';
                this.displayUiMsg(cmp, 'error', msg);
                $A.get("e.force:closeQuickAction").fire();
            } else {
                if (po.Quantity_of_Software_Created__c !== po.Quantity__c) {
                    let qtyToCreate = (po.Quantity__c - po.Quantity_of_Software_Created__c);
                    if (qtyToCreate >= maxQty) {
                        qtyToCreate = maxQty;
                        let msg = 'Limiting creation to the max number of assets that can be created per run:  ' +
                            qtyToCreate + '. Please click create software again when this process is complete . ';
                        this.displayUiMsg(cmp, 'warning', msg);
                    }
                    cmp.set('v.qtyToCreate', qtyToCreate);
                    let flow = cmp.find("flowData");
                    let arrQty = [];
                    for (var i = 0; i <= qtyToCreate; i++) {
                        arrQty.push(i);
                    }
                    let inputVariables = [
                        {name: "varInputRecordId", type: "String", value: po.Id},
                        {name: "varInputPo", type: "SObject", value: po},
                        {name: 'varInputQuantity', type: "Number", value: qtyToCreate},
                        {name: 'varQuantityCollection', type: "Number", value: arrQty}
                    ];
                    try {
                        this.log(cmp,'flowName being fired=' + flowName,'debug');
                        this.log(cmp,'input vars to flow','debug',JSON.stringify(inputVariables));
                        flow.startFlow(flowName, inputVariables);
                        cmp.set('v.isRunningFlow', true);
                    } catch (e) {
                        alert('ERROR!' + JSON.stringify(e));
                    }
                } else {
                    cmp.set('v.alreadyCreated', true);
                    let msg = 'Software has already been created for this Purchase Order. Please check the quantity of software created field and any associated assets';
                    this.displayUiMsg(cmp, 'error', msg);
                    $A.get("e.force:closeQuickAction").fire();
                }
            }
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
    /**
     * Rolls through the outputVar collection returned from the flow and grabs
     * the total number of assets created output variable.
     *
     * @param cmp
     * @param outputVariables
     */
    debugFlowOutputVars: function (cmp,outputVariables) {
        let outputVar;
        this.log(cmp,'outputvariables','debug',JSON.stringify(outputVariables));
        for(let i = 0; i < outputVariables.length; i++) {
            outputVar = outputVariables[i];
            if(outputVar.name === 'varQtyAssetsCreated') {
                let totalCreated = cmp.get('v.totalNbrOfAssetsCreated');
                totalCreated += outputVar.value;
                cmp.set('v.totalNbrOfAssetsCreated', totalCreated);
            }
        }
    }
});