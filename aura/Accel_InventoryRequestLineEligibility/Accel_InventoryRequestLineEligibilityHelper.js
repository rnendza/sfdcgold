({
    _validPolicyClass : 'fas fa-check-circle accel-success-checks', _invalidPolicyClass : 'fas fa-exclamation-triangle accel-error-checks',
    _validPolicyTextClass : 'accel-success-text',_invalidPolicyTextClass : 'accel-error-text',

    /**
     * Process all checks that must pass prior to displaying the Create Assets button.
     * Will populate an array [lineItemChecks] to be displayed in the UI for user guidance.
     *
     * @param cmp
     */
    processItemChecks: function (cmp) {
        this.log(cmp, '---------> process item checks','debug');
        let lineItem = cmp.get('v.inventoryRequestLineItem');
        const validationObj = {iconClass: this._validPolicyClass, description:'',textClass:this._validPolicyTextClass};

        if(lineItem) {
            let suppressPostApprovalChecks = false;
            let lineChecks = [];
            lineChecks.push( this.processFinalApprovedCheck( lineItem, validationObj ) );
            let status = lineItem.Inventory_Request__r.Status__c;
            if(status === 'Open' || status === 'IR Request Pending Approval') {//  @todo probably want to use Final_Approved_Ind__c?
                suppressPostApprovalChecks = true;
            }
            if(!suppressPostApprovalChecks) { //  Do not show additional val warnings until after approval!
                lineChecks.push(this.processIrApprovedDateCheck(lineItem,validationObj));
                lineChecks.push(this.processPoNumberCheck(lineItem, validationObj));
                lineChecks.push(this.processPoSubmittedDateCheck(lineItem, validationObj));
                lineChecks.push(this.processVendorCheck(lineItem, validationObj));
                lineChecks.push(this.processReceivedDateCheck(lineItem, validationObj));
                lineChecks.push(this.processReceivedQuantityCheck(lineItem, validationObj));
            }
            cmp.set('v.lineItemChecks', lineChecks);
            this.calcProgressBar(cmp,lineChecks);
        } else {
            alert('no line item found!');
        }
    },
    // --------------------------- Various field specific checks on the line and parent IR Request --------------------

    processFinalApprovedCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(lineItem.Inventory_Request__r) {
            if (!lineItem.Inventory_Request__r.Final_Approved_Indicator__c) {
                let status = lineItem.Inventory_Request__r.Status__c;
                if(status === 'Open') {
                    lineCheck.description = 'Request must be Approved. (After all lines have been added, click the <b>View';
                    lineCheck.description += ' Inventory Request</b> Button to return to the Request and then the Submit for';
                    lineCheck.description += ' Approval button at the top of the page.)';
                } else {
                    lineCheck.description = 'Request is awaiting approval';
                }

                lineCheck.iconClass = this._invalidPolicyClass;
                lineCheck.textClass = this._invalidPolicyTextClass;
                lineCheck.valid = false;
            } else {
                lineCheck.description = 'Request has been approved';
                lineCheck.valid = true;
            }
        }
        return lineCheck;
    },
    processPoNumberCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(lineItem.Inventory_Request__r) {
            if (!lineItem.Inventory_Request__r.PO_Number__c) {
                lineCheck.description = 'Request must be assigned a PO Number.';
                lineCheck.iconClass = this._invalidPolicyClass;
                lineCheck.textClass = this._invalidPolicyTextClass;
                lineCheck.valid = false;
            } else {
                lineCheck.description = 'Request PO Number: ' + lineItem.Inventory_Request__r.PO_Number__c;
                lineCheck.valid = true;
            }
        }
        return lineCheck;
    },
    processPoSubmittedDateCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(!lineItem.Inventory_Request__r.PO_Submitted_Date__c) {
            lineCheck.description = 'Request must be assigned a PO Submitted Date.';
            lineCheck.iconClass = this._invalidPolicyClass;
            lineCheck.textClass = this._invalidPolicyTextClass;
            lineCheck.valid = false;
        } else {
            let date = this.localizeDate( lineItem.Inventory_Request__r.PO_Submitted_Date__c );
            lineCheck.description = 'Request PO Submitted Date: '+date;
            lineCheck.valid = true;
        }
        return lineCheck;
    },
    /**
     * Ensures Inventory_Request__r.IR_Approved_Date__c is populated (there was one time this was not
     * set on a valid approved record)
     *
     * @param lineItem       The IR Line Item
     * @param validationObj  {iconClass: this._validPolicyClass, description:'',textClass:this._validPolicyTextClass};
     * @return {*}           A populated validationObj.
     */
    processIrApprovedDateCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(!lineItem.Inventory_Request__r.IR_Approved_Date__c) {
            lineCheck.description = 'Request must be assigned an Approved Date.';
            lineCheck.iconClass = this._invalidPolicyClass;
            lineCheck.textClass = this._invalidPolicyTextClass;
            lineCheck.valid = false;
        } else {
            let date = this.localizeDate( lineItem.Inventory_Request__r.IR_Approved_Date__c );
            lineCheck.description = 'Request Approved Date: '+date;
            lineCheck.valid = true;
        }
        return lineCheck;
    },

    /**
     * OBSOLETE
     * @param lineItem
     * @param validationObj
     * @returns {any}
     */
    processVendorCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(!lineItem.Vendor__c) {
            lineCheck.description = 'Line item Vendor must be selected.';
            lineCheck.iconClass = this._invalidPolicyClass;
            lineCheck.textClass = this._invalidPolicyTextClass;
            lineCheck.valid = false;
        } else {
            lineCheck.description = 'Line item Vendor: '+lineItem.Vendor__r.Name;
            lineCheck.valid = true;
        }
        return lineCheck;
    },
    processReceivedDateCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(!lineItem.Received_Date__c) {
            lineCheck.description = 'Line item Received Date must be entered.';
            lineCheck.iconClass = this._invalidPolicyClass;
            lineCheck.textClass = this._invalidPolicyTextClass;
            lineCheck.valid = false;
        } else {
            let date = this.localizeDate(lineItem.Received_Date__c);
            lineCheck.description = 'Line item Received Date: '+date;
            lineCheck.valid = true;
        }
        return lineCheck;
    },
    processReceivedQuantityCheck: function( lineItem, validationObj ) {
        let lineCheck = Object.assign({}, validationObj);
        if(!lineItem.Received_Quantity__c) {
            lineCheck.description = 'Line item Quantity to create must have a value > 0.';
            lineCheck.iconClass = this._invalidPolicyClass;
            lineCheck.textClass = this._invalidPolicyTextClass;
            lineCheck.valid = false;
        } else {
            lineCheck.description = 'Line item Quantity to Create: '+lineItem.Received_Quantity__c;
            lineCheck.valid = true;
        }
        return lineCheck;
    },
    /**
     * Calculate the % value for the progress bar. This will take in the array of line item checks and parent record
     * data checks. . e line received date / parent po submitted date etc and determine the validity of each check
     * in order to come up with the final pct (CORRECT / TOTAL % CHECKS * 100)
     *
     * @param cmp
     * @param lineChecks
     */
    calcProgressBar: function(cmp,lineChecks) {

        if(lineChecks && Array.isArray(lineChecks)) {
            const iTotalChecks = lineChecks.length;
            let   iNumCorrect = 0;
            lineChecks.forEach( lineCheck  => {
                if(lineCheck.valid) {
                    iNumCorrect++;
                }
            });
            let pct = iNumCorrect / iTotalChecks * 100;
            if(pct > 0 ) {
                pct = pct.toFixed(0);
            }
            cmp.set('v.progressBarValue',pct);
        }
    },
    /**
     *
     * @param date
     * @returns {string}
     */
    localizeDate: function(date) {
        if(date) {
            date= $A.localizationService.formatDate(date);
        }
        return date;
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