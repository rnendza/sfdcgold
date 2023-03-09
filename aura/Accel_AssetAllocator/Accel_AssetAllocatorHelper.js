({
    /**
     * Dynamically add class property to simpleRecord based on Asset.Status
     * @param cmp
     */
    processStatus: function(cmp) {
        if(cmp.get('v.simpleRecord')) {
            let asset = cmp.get('v.simpleRecord');
            let statusMetadata = cmp.get('v.statusMetadata');
            if(asset.Status) {
                switch (asset.Status) {
                    case 'Available':
                        statusMetadata.cssClass = 'slds-text-color_weak';
                        break;
                    case 'Allocated':
                        statusMetadata.cssClass = 'slds-text-color_success';
                        break;
                    default:
                        statusMetadata.cssClass = '';
                }
                cmp.set('v.statusMetadata',statusMetadata);
            }
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