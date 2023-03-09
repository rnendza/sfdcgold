({
    collectionUtils:null, loggingUtils:null,
    MAP_KEY_ACCOUNTS:'MAP_KEY_ACCOUNTS',

    retrieveAccountsForIrSelection: function(cmp) {
        const action = 'c.retrieveAccountsForIrSelection';
        const params = {whereCriteria : cmp.get('v.accountWhereCriteria')};

        this.log(cmp,'calling retrieveAccountsForIrSelection','debug',JSON.stringify(params));
        cmp.lax.enqueue(action,params)
            .then(response => {
                if(response) {
                    let dto = response;
                    this.log(cmp, 'cb of retrieveAccountsForIrSelection: ','debug',dto);
                    if(dto.isSuccess) {
                        let accounts = this.collectionUtils.getData(this.MAP_KEY_ACCOUNTS, dto.values);
                        if(accounts) {
                            let options = this.shapeAccountsToOptions(accounts,cmp);
                            if(options) {
                                cmp.set('v.options',options);
                            }
                        }
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
     * @param accounts
     * @returns {[]}
     */
    shapeAccountsToOptions: function(accounts,cmp) {
        let options = [];
        let defaultSelectedValue = cmp.get('v.defaultSelectedValue');
        let defaultSelectedAccountName = cmp.get('v.defaultSelectedAccountName');

        let defaultSet = false;
        accounts.forEach( account  => {
            let option = {};
            option.label = account.Name;
            option.value = account.Id;
            // --- Prefer to default by label (Set in screen flow)
            if(defaultSelectedAccountName) {
                if(account.Name === defaultSelectedAccountName) {
                    this.log(cmp,'setting default selected to '+defaultSelectedAccountName,'debug');
                    cmp.set('v.selectedValue',account.Id);
                    option.selected = true;
                    defaultSet = true;
                }
            } else if(defaultSelectedValue) { /* label wasn't provided use ID (BAD) */
                if(account.Id === defaultSelectedValue) {
                    this.log(cmp,'setting default selectd to '+defaultSelectedValue,'debug');
                    cmp.set('v.selectedValue',defaultSelectedValue);
                    option.selected = true;
                    defaultSet = true;
                }
            }
            options.push(option);
        });
        if(!defaultSet) {
            cmp.set('v.selectedValue',accounts[0].Id);
        }
        return options;
    },

    simulateServerRequest: function (onResponse) {
        setTimeout(function () {
            let serverResponse = {
                selectedAccountId: '',
                accounts: [
                    { id: '', label: 'Accel Entertainment - HQ', selected: true },
                    { id: '', label: 'Accel Entertainment - Warehouse A'}
                ]
            };
            onResponse.call(null, serverResponse);
        }, 2000);
    },
    /**
     * Set focus to first input in the flow.. The Evil Mr. Locker service will probably shut this down via
     * DOM isolation eventually so we are surrounding this in try / catch for now.
     * @param cmp
     */
    focusFirstFlowFormField: function(cmp) {
        try {
            let focusable = document.querySelectorAll('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])');
            alert('test---' + JSON.stringify(focusable));
            if (focusable) {

                let firstFocusable = focusable[0];
                if(firstFocusable) {
                    firstFocusable.focus();
                }
            }
        } catch (e) {
            console.error(e);
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