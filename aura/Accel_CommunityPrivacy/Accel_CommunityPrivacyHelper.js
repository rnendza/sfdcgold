({
    collectionUtils: null, loggingUtils : null,
    PRIVACY_TEXT: 'PRIVACY_TEXT',
    /**
     *
     * @param cmp
     */
    retrievePrivacy: function(cmp) {
        cmp.lax.enqueue('c.retrievePrivacy')
            .then(response => {
                this.processPrivacy(cmp,response);
            })
            .catch(errors => {
                this.handleErrors(cmp, errors); //@TODO handle errors should be beefed up.
            });
    },
    /**
     *
     * @param cmp
     * @param response
     */
    processPrivacy: function(cmp, response) {
        let dto = response;
        let privacyText  = '';
        this.collectionUtils.getMapValue(this.PRIVACY_TEXT, dto.values, function (value) {privacyText = value;});
        cmp.set('v.privacyText',privacyText)
    },
    /**
     * A generic catch 'all' method. Originally meant for catching SS errors but here for future
     * refinement.
     *
     * @param cmp
     * @param errors
     */
    handleErrors : function(cmp,error) {
        this.log(cmp, 'errors in init server side retrieval calls', 'error', error);
        console.error(error); //in case the logging util missis it!
        try {
            var name = error.name;
            switch (name) {
                case 'ApexActionError':
                    //do nothing wtf are we going to do with this anyway!
                    break;
            }
            //@TODO pop ui msg on other stuff.
        } catch (e) {
            this.log(cmp, 'error handling errors lol','error',e);
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
        var lvl;
        var self = this;
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
                var cmpName = '--- '+cmp.getName() + ' CMP --- ';
                var cLogger = self.loggingUtils;
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
     *
     * @param cmp
     * @param type
     * @param msg
     */
    displayUiMsg: function (cmp, type, msg) {
        let cUiMessagingUtils = cmp.find('uiMessagingUtils');
        cUiMessagingUtils.displayUiMsg(type, msg);
    },
});