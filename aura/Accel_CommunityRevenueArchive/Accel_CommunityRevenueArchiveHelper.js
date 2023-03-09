/**
 * Replaced alerts with call to error logging which will pop toast as well.
 * https://accel-entertainment.monday.com/boards/286658657/
 */
({
    collectionUtils: null,
    loggingUtils:null,
    //https://accel-entertainment.monday.com/boards/286658657/
    uiMessagingUtils:null,
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:20000, //20 seconds

    retrieveAccounts: function(cmp){
        cmp.lax.enqueue('c.retrieveAccounts') //getUserAccounts
            .then(response => {
                this.processUserAccounts(cmp,response);
                this.retrieveFiles(cmp);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },

    retrieveFiles: function (cmp) {
        let start = cmp.get('v.startDate');
        let end = cmp.get('v.endDate');
        let id = cmp.get('v.selectedAccountId');
        const params = {id: id, startDate: start, endDate: end};
        cmp.lax.enqueue('c.getRevenueFiles', params)
            .then(response => {
                cmp.set('v.revenueFiles', response);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
                //this.handleInitErrors(cmp,errors);
            });
        cmp.lax.enqueue('c.getOtherFiles')
            .then(response => {
                cmp.set('v.otherFileList', response);
                this.displayFilteredFiles(cmp);
            })
            .catch(errors => {
                this.log(cmp,'generic','error',JSON.stringify(errors));
                //this.handleInitErrors(cmp,errors);
            });
    },

    processUserAccounts: function (cmp, response) {
        let dto = response;
        let accounts = [];
        //--deprecated this.collectionUtils.getMapValue('ACCOUNT_LIST', dto.values, function (value) {accounts = value;});
        //https://accel-entertainment.monday.com/boards/286658657/pulses/319255455
        accounts = this.collectionUtils.getData('ACCOUNT_LIST',dto.values);

        cmp.set('v.userAccounts', accounts);
        this.setUserAccountOptions(cmp); //---- translate user account array to options array for combo box (location filter)

        let accountId = this.getUrlParam('accountId');
        if (accountId && accountId !== '') {
            cmp.set('v.selectedAccountId', accountId);
        } else {
            accountId = accounts[0].Id;
            cmp.set('v.selectedAccountId', accounts[0].Id);
        }
        cmp.set('v.selectedAccount', this.getAccountById(accounts, accountId));
        let startDateRange = new Date();
        let endDateRange =  new Date();
        startDateRange.setDate(startDateRange.getDate() - 62);
        endDateRange.setDate(endDateRange.getDate() - 2);
        let startDate = $A.localizationService.formatDate(startDateRange, 'YYYY-MM-dd');
        let endDate = $A.localizationService.formatDate(endDateRange, 'YYYY-MM-dd');
        cmp.set('v.endDate', endDate);
        cmp.set('v.startDate', startDate);
    },
    setUserAccountOptions: function (cmp) {
        let accounts = cmp.get('v.userAccounts');
        let accountOptions = [];
        if(accounts) {
            for(let i=0; i<accounts.length; i++) {
                let account = accounts[i];
                let concatName = account.Name + ' - ' + account.ShippingStreet + ' - ' + account.ShippingCity ;
                let accountOption = {'label': concatName, 'value': account.Id};
                accountOptions.push(accountOption);
            }
        }
        cmp.set('v.userAccountOptions',accountOptions);
    },
    getUrlParam: function (paramName) {
        var sPageURL = decodeURIComponent(window.location.search.substring(1)),
            sURLVariables = sPageURL.split('&'),
            sParameterName,
            i;

        for (i = 0; i < sURLVariables.length; i++) {
            sParameterName = sURLVariables[i].split('=');

            if (sParameterName[0] === paramName) {
                return sParameterName[1] === undefined ? true : sParameterName[1];
            }
        }
    },
    getAccountById: function (arr, value) {
        for (let i = 0; i < arr.length; i++) {
            if (arr[i].Id === value) {
                return arr[i];
            }
        }
    },
    displayFilteredFiles: function(cmp){
        let revenueFiles = cmp.get('v.revenueFiles');
        let otherFiles = cmp.get('v.otherFileList');
        let accId = cmp.get('v.selectedAccountId');
        let filteredFileList = [];
        let filteredOtherList = [];
        /*if(revenueFiles){
            for(let i=0; i<revenueFiles.length; i++) {
                let rFile=revenueFiles[i];
                if(rFile.LinkedEntityId=== accId){
                    filteredFileList.push(rFile);
                }
            }
        } */
        if(otherFiles){
            for(let i=0; i<otherFiles.length; i++) {
                let rFile=otherFiles[i];
                if(rFile.LinkedEntityId=== accId){
                    filteredOtherList.push(rFile);
                }
            }
        }
        //cmp.set('v.selectedAccountRevenueFiles', filteredFileList);
        cmp.set('v.selectedAccountOtherFiles', filteredOtherList);
    },
    /**
     * Simply a wrapper around The Utils Component / log method.
     * https://accel-entertainment.monday.com/boards/286658657/
     *
     * @param cmp
     * @param msg - the message to log... if includes generic and an error.. will fire toast.
     * @param level [debug,info,warn,error]
     * @param jsonObj  optional a JSON OBJECT and not a string!
     */
    log: function (cmp, msg, level, jsonObj) {
        let lvl;
        let self = this;
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
                let cmpName = '--- '+cmp.getName() + ' CMP --- ';
                let cLogger = self.loggingUtils;
                cLogger.log(cmpName, lvl, msg, jsonObj);
                // https://accel-entertainment.monday.com/boards/286658657/
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
    }
});