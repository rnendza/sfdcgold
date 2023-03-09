({
    collectionUtils: null, loggingUtils : null,
    MAP_KEY_RELEASE_NOTES: 'RELEASE_NOTES',
    /**
     *
     * @param cmp
     */
    retrieveReleaseNotes: function(cmp) {
        this.log(cmp,'Calling server for retrieveReleaseNotes');
        cmp.lax.enqueue('c.retrieveCommunityReleaseNotes')
            .then(response => {
                this.processReleaseNotes(cmp,response);
            })
            .catch(errors => {
                //  cmp.set("v.showComparisonSpinner", false);
                this.handleErrors(cmp, errors); //@TODO handle errors should be beefed up.
            });
    },
    /**
     *
     * @param cmp
     * @param response
     */
    processReleaseNotes: function(cmp, response) {
        let dto = response;
        this.log(cmp,'evaluating dto','info',dto);
        let notes = null;
        this.collectionUtils.getMapValue(this.MAP_KEY_RELEASE_NOTES, dto.values, function (value) {notes = value;});
        cmp.set('v.releaseNotes',notes);
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

});