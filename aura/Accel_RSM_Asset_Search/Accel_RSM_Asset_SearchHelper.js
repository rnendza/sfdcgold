({
    /**
     * initial config of data table.
     * @param cmp
     */
    initDatatableColumns: function (cmp) {
    //,Asset.SAS__c, Asset.GP_Manufacturer__c

        cmp.set('v.columns', [
            {label: 'Case', fieldName: 'Show_Record__c', sortable:true, type: "url",typeAttributes: {label: { fieldName: 'CaseNumber' } }} ,
            {label: 'Asset', fieldName: 'AssetShowRecord', sortable:true, type: "url",typeAttributes: {label: { fieldName: 'AssetName' } }} ,
            {label: 'SAS Pos', fieldName: 'AssetSAS', sortable: true, type: 'text'},
            {label: 'GP Mfgr', fieldName: 'AssetGP_Manufacturer', sortable: true, type: 'text'},
            {label: 'Account', fieldName: 'AccountName', sortable: true, type: 'text'},
            {label: 'Status', fieldName: 'Status', sortable: true, type: 'text'},
            {label: 'Date Opened', fieldName: 'CreatedDate',  sortable: true, type: 'date-local' },
            {label: 'G2S Updated', fieldName: 'G2SUpdatedText',  sortable: true, type: 'text' },
            {label: 'Work Type', fieldName: 'WorkTypeName', sortable: true, type: 'text'},
            {label: 'Solution', fieldName: 'Solution__c', sortable: true, type: 'text' },
            {label: 'Tech Notes', fieldName: 'Tech_Notes__c', sortable: true, type: 'text'},
            {label: 'Assigned', fieldName: 'AssignedResourceName', sortable: true, type: 'text' }
        ]);
    },
    /**
     * Retrieve search custom meta data.
     * @param cmp
     * @param helper
     */
    retrieveSearchSettings: function (cmp, helper) {
        var action = cmp.get('c.retrieveSearchSettings');
        var self = this;
        var collectionUtils = cmp.find('collectionUtils');
        action.setCallback(this, $A.getCallback(function (response) {
            var state = response.getState();
            var searchMdt;
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                console.log(JSON.stringify(dto));
                if(dto.isSuccess) {
                    collectionUtils.getMapValue('MAP_KEY_SEARCH_SETTINGS', dto.values, function (value) {
                        searchMdt = value;
                        console.log(JSON.stringify(searchMdt));
                        cmp.set('v.searchMdt', searchMdt);
                    });
                } else {
                    self.log(cmp, 'search mdt retrieval failed.. ', 'error', dto);
                    // self.displayUiMsg(cmp, dto.severity, dto.message);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                try {
                    self.displayUiMsg(cmp, 'error', JSON.stringify(errors));
                } catch (e) {
                    console.error(e);
                }
                self.log(cmp, '', 'error', errors)
            }
        }));
        self.log(cmp, 'Enqueuing call to retrieve customer search mdt info');
        $A.enqueueAction(action);
    },
    /**
     * Get the cases for the search criteria.
     * @param cmp
     * @param evt
     */
    retrieveCases: function (cmp, evt) {
        var searchTerm = cmp.get('v.searchKeyword');
        var self = this;
        cmp.set("v.showSpinner", true);
        var action = cmp.get('c.searchCases');
        var collectionUtils = cmp.find('collectionUtils');

        action.setParams({"searchTerm": searchTerm});

        action.setCallback(this, $A.getCallback(function (response) {
            var self = this;
            var state = response.getState();
            var cases = [];
/*
     {label: 'SAS Pos', fieldName: 'AssetSAS', sortable: true, type: 'text'},
            {label: 'GP Mfgr', fieldName: 'AssetGP_Manufacturer', sortable: true, type: 'text'},


 */
            if (state === "SUCCESS") {
                var dto = response.getReturnValue();
                console.log(JSON.stringify(dto));
                collectionUtils.getMapValue('CASE_LIST', dto.values, function (value) {
                    cases = value;
                });
                //---- flatten related fields. datatables suck and dont allow things like Account.Name
                for (var i = 0; i < cases.length; i++) {
                    var cse = cases[i];
                    if (cse.Account) cse.AccountName = cse.Account.Name;
                    if (cse.Asset) {
                        cse.AssetName = cse.Asset.Name;
                        cse.AssetShowRecord = cse.Asset.Show_Record__c;
                        cse.AssetSAS = cse.Asset.SAS__c;
                        cse.AssetGP_Manufacturer = cse.Asset.GP_Manufacturer__c;
                    }
                    if (cse.G2S_Updated__c)  {
                        if(cse.G2S_Updated__c === true) {
                            cse.G2SUpdatedText = 'Yes';
                        } else {
                            cse.G2SUpdatedText = 'No';
                        }
                    } else {
                        cse.G2SUpdatedText = 'No';
                    }
                    if(cse.Work_Type__r) cse.WorkTypeName = cse.Work_Type__r.Name;
                    if(cse.Assigned_Resource__r) cse.AssignedResourceName = cse.Assigned_Resource__r.Name;
                }
                cmp.set('v.data', cases);
                cmp.set('v.rawData', cases);
                cmp.set("v.totalPages", Math.ceil(cases.length/cmp.get("v.pageSize")));
                cmp.set("v.currentPageNumber",1);
                cmp.set("v.showSpinner", false);
                self.buildData(cmp);
                if(dto.severity === 'warning') {
                    self.log(cmp, dto.severity, dto.message);
                    self.displayUiMsg(cmp, dto.severity, dto.message);
                }
                if (!dto.isSuccess) {
                    self.log(cmp, 'case retrieval failed.. ', 'error', dto);
                    // self.displayUiMsg(cmp, dto.severity, dto.message);
                }
            } else if (state === "ERROR") {
                cmp.set("v.showSpinner", false);
                var errors = response.getError();
                console.log(JSON.stringify(errors));
                self.log(cmp, '', 'error', errors)

            }
            cmp.set('v.searchExecuted',true);
        }));
        self.log(cmp, 'Enqueuing call to retrieve case data for searchTerm:' + searchTerm, 'info');
        $A.enqueueAction(action);

    },

    /*
    * this function will build table data
    * based on current page selection
    * */
    buildData : function(component, helper) {
        var self = this;
        var data = [];
        var pageNumber = component.get("v.currentPageNumber");
        var pageSize = component.get("v.pageSize");
        var allData = component.get("v.rawData");
        var x = (pageNumber-1)*pageSize;

        //creating data-table data
        for(; x<=(pageNumber)*pageSize; x++){
            if(allData[x]){
                data.push(allData[x]);
            }
        }
        component.set("v.data", data);
      //  component.set("v.showSpinner", false);
        self.generatePageList(component, pageNumber);
    },
    /**
     *
     * @param cmp
     * @param fieldName
     * @param sortDirection
     */
    sortData: function (cmp, fieldName, sortDirection) {
        var self = this;
        var data = cmp.get("v.rawData");
        var reverse = sortDirection !== 'asc';
        data.sort(self.sortBy(fieldName, reverse));
        cmp.set("v.data", data);
        self.buildData(cmp);
       // cmp.set('v.rawData', data);
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
    },
    displayUiMsg: function (cmp, type, msg) {
        var cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
    /*
    * this function generate page list
    * */
    generatePageList : function(component, pageNumber){
        pageNumber = parseInt(pageNumber);
        var pageList = [];
        var totalPage = component.get("v.totalPages");
        if(pageNumber<5){
            pageList.push(2,3,4,5,6);
        } else if(pageNumber>(totalPage-5)){
            pageList.push(totalPage-5, totalPage-4, totalPage-3, totalPage-2, totalPage-1);
        } else{
            pageList.push(pageNumber-2, pageNumber-1, pageNumber, pageNumber+1, pageNumber+2);
        }
        component.set("v.pageList", pageList);
        component.set("v.showSpinner", false);
    },
    /**
     * SFDC will leave a validation method by the input. (some might call it a bug)
     * Do this to "touch" the control.
     * @param cmp
     * @param evt
     * @param helper
     */
    doSearchInputValRefresh:function(cmp){
        cmp.set('v.searchInputValRefresher',false);
        cmp.set('v.searchInputValRefresher',true);
    }
})