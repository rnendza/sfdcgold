({
    /**
     * initial config of data table.
     * @param cmp
     */
    initDatatableColumns: function (cmp) {
        let isMobile = $A.get("$Browser.isPhone");
            //--- override.. helps for testing on browser version of salesforce1 as the above evals to false
        if(isMobile === false) {
            let templateWidth = window.innerWidth;
            if (templateWidth && templateWidth <= 700) {
                isMobile = true;
            }
        }
        let cellAlign = isMobile ? 'right' : 'left';
        cmp.set('v.isMobile',isMobile);

        let datatableClasses = 'slds-table_fixed-layout slds-max-medium-table_stacked-horizontal';
        let dateLabel = 'Date';
        if(isMobile) {
            datatableClasses += ' slds-table_striped';
            dateLabel = 'HPD Month'
        } else {
            datatableClasses += ' accel-desktop-table';
        }
        cmp.set('v.datatableClasses',datatableClasses);

        cmp.set('v.columns', [
            {
                label: dateLabel,
                fieldName: 'Date__c',
                type: 'date-local',
                typeAttributes: {
                    month: 'short',
                    year: 'numeric'
                },
                sortable: true,
                cellAttributes: {}
            },
            {
                label: 'Avg HPD',
                fieldName: 'HPD__c',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: cellAlign}
            },
            {
                label: 'VGT Count',
                fieldName: 'VGT_Count__c',
                type: 'number',
                sortable: true,
                cellAttributes: {alignment: cellAlign}
            },
            {
                label: 'NTI',
                fieldName: 'NTI__c',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: cellAlign}
            },
            {
                label: 'Funds In',
                fieldName: 'Funds_In__c',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: cellAlign}
            },
            {
                label: 'Location Share',
                fieldName: 'Location_Share__c',
                type: 'currency',
                sortable: true,
                cellAttributes: {alignment: cellAlign}
            }
        ]);
    },
    /**
     *
     * @param cmp
     * @param helper
     */
    retrieveHpdAccountSettings: function (cmp, helper) {
        var action = cmp.get('c.retrieveHpdAccountSettings');
        var self = this;
        var collectionUtils = cmp.find('collectionUtils');
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            var hpdAccountMdt;

            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                console.log(JSON.stringify(dto));
                if(dto.isSuccess) {
                    var hpdAccountMdt;
                    collectionUtils.getMapValue('MAP_KEY_HPD_ACCOUNT_SETTINGS', dto.values, function (value) {
                        hpdAccountMdt = value;
                        console.log(JSON.stringify(hpdAccountMdt));
                        cmp.set('v.hpdAccountMdt', hpdAccountMdt);
                    });
                } else {
                    self.log(cmp, 'hpdAccountMdt retrieval failed.. ', 'error', dto);
                    // self.displayUiMsg(cmp, dto.severity, dto.message);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                alert(JSON.stringify(errors));
                self.log(cmp, '', 'error', errors)
            }
        }));
        self.log(cmp, 'Enqueuing call to retrieve customer hpdAccountMdt info');
        $A.enqueueAction(action);
    },
    /**
     *
     * @param cmp
     */
    retrieveHpds: function (cmp) {
        var recordId = cmp.get('v.recordId');

        var self = this;
        cmp.set("v.showSpinner", true);
        var action = cmp.get('c.retrieveHpds');
        var collectionUtils = cmp.find('collectionUtils');

        action.setParams({"accountId": recordId});

        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            var hpds = [];
            cmp.set('v.processingComplete',true);
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                collectionUtils.getMapValue('LOCATION_HPDS', dto.values, function (value) {
                    hpds = value;
                });
                cmp.set('v.data', hpds);
                cmp.set('v.rawData', hpds);
                cmp.set("v.showSpinner", false);
                if(dto.isSuccess) { //hpd total record came back
                    if(dto.sObj) { //hpd total record came back
                        //alert('debug='+JSON.stringify(dto.sObj))
                        //cmp.set("v.hpdTotal", dto.sObj);
                        console.log('-----> hpd total id='+dto.sObj.Id);
                        cmp.set("v.hpdTotalId", dto.sObj.Id);
                    }
                } else {
                    self.log(cmp, 'hpd retrieval failed.. ', 'warn', dto);
                    // self.displayUiMsg(cmp, dto.severity, dto.message);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                self.log(cmp, '', 'error', errors)
            }
            cmp.set("v.showSpinner", false);
        }));
        self.log(cmp, 'Enqueuing call to retrieve Hpd data for account id:' + cmp.get('v.recordId'), 'info');
        $A.enqueueAction(action);

    },
    /**
     *
     * @param cmp
     * @param fieldName
     * @param sortDirection
     */
    sortData: function (cmp, fieldName, sortDirection) {
        var data = cmp.get("v.data");
        var reverse = sortDirection !== 'asc';
        data.sort(this.sortBy(fieldName, reverse));
        cmp.set("v.data", data);
        cmp.set('v.rawData', data);
    },
    /**
     *  A general alpha sort algo.
     *
     * @param field
     * @param reverse
     * @param primer
     * @returns {function(*=, *=)}
     */
    sortBy: function (field, reverse, primer) {
        var key = primer ?
            function (x) {
                return primer(x[field])
            } :
            function (x) {
                return x[field]
            };
        reverse = !reverse ? 1 : -1;
        return function (a, b) {
            return a = key(a), b = key(b), reverse * ((a > b) - (b > a));
        }
    },
    /**
     * @TODO Grab this dynamically
     * @param cmp
     */
    setHpdSummaryHelpHeaderText: function(cmp) {
        const fourWk = 'Based on Monthly HPD Records. Aggregates HPD data for 1 Month.. (Revenue Total / # of Vgts) / 1. If Not enough data available, will display a blank value.';
        const eightWk = 'Based on Monthly HPD Records. Aggregates HPD data for 2 Months.. (Revenue Total / # of Vgts) / 2. If Not enough data available, will display a blank value.';
        const twelveWk = 'Based on Monthly HPD Records. Aggregates HPD data for 3 Months.. (Revenue Total / # of Vgts) / 3. If Not enough data available, will display a blank value.';
        cmp.set('v.hpdHelp4Wk',fourWk);
        cmp.set('v.hpdHelp8Wk',eightWk);
        cmp.set('v.hpdHelp12Wk',twelveWk);
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
        try {
            if (cmp.get("v.debugConsole") || level === 'error') {
                var cmpName = '--- Accel_Location_HPD ';
                var cLogger = cmp.find('loggingUtils');
                cLogger.log(cmpName, level, msg, jsonObj);
            }
        } catch (e) {
            console.error(e);
            console.log('was going to log msg=' + msg);
            if (jsonObj) {
                console.log(jsonObj);
            }
        }
    }
})