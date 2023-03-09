({
    collectionUtils:null, loggingUtils:null,
    MAP_KEY_ASSETS:'MAP_KEY_ASSETS',

    retrieveParentAssetsForIrSelection: function(cmp) {
        const action = 'c.retrieveParentAssetsForIrSelection';
        const params = {whereCriteria : cmp.get('v.assetWhereCriteria')};


        this.log(cmp,'calling retrieveParentAssetsForIrSelection','debug',JSON.stringify(params));
        cmp.lax.enqueue(action,params)
            .then(response => {
                if(response) {
                    let dto = response;
                    this.log(cmp, 'cb of retrieveParentAssetsForIrSelection: ','debug',dto);
                    if(dto.isSuccess) {
                        let assets = this.collectionUtils.getData(this.MAP_KEY_ASSETS, dto.values);
                        if(assets) {
                            let options = this.shapeAssetsToOptions(assets,cmp);
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
    shapeAssetsToOptions: function(assets,cmp) {
        let options = [];
        let defaultSelectedValue = cmp.get('v.defaultSelectedValue');
        let defaultSelectedAssetName = cmp.get('v.defaultSelectedAssetName');

        let defaultSet = false;
        assets.forEach( asset  => {
            let option = {};
            option.label = asset.Name;
            option.value = asset.Id;

                // --- Prefer to default by label (Set in screen flow)
                if(defaultSelectedAssetName) {
                    if(asset.Name === defaultSelectedAssetName) {
                        this.log(cmp,'setting default selected to '+defaultSelectedAssetName,'debug');
                        cmp.set('v.selectedValue',asset.Id);
                        option.selected = true;
                        defaultSet = true;
                    }
                } else if(asset.Id === defaultSelectedValue) {
                    this.log(cmp,'setting default selected to '+defaultSelectedValue,'debug');
                    cmp.set('v.selectedValue',defaultSelectedValue);
                    option.selected = true;
                    defaultSet = true;
                }
            options.push(option);
        });
        if(!defaultSet) {
            cmp.set('v.selectedValue',assets[0].Id);
        }
        return options;
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