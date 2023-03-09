({
    collectionUtils: null, loggingUtils : null,
    TERMS_OF_USE_TEXT: 'TERMS_OF_USE_TEXT', MAP_KEY_CONTACT : 'CONTACT_SOBJECT',
    /**
     *
     * @param cmp
     */
    retrieveTermsOfUse: function(cmp) {
        this.log(cmp,'Calling server for retrieveTermsOfUse');
        cmp.lax.enqueue('c.retrieveTermsOfUse')
            .then(response => {
                this.processTermsOfUse(cmp,response);
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
    processTermsOfUse: function(cmp, response) {
        let dto = response;
        this.log(cmp,'evaluating dto','info',dto);
        let termsOfUseText = '';
        this.collectionUtils.getMapValue(this.TERMS_OF_USE_TEXT, dto.values, function (value) {termsOfUseText = value;});
        cmp.set('v.termsOfUseText',termsOfUseText)
    },
    /**
     *
     * @param cmp
     */
    handleAccept: function(cmp) {
        this.log(cmp,'Calling server to update contact acceptance date');
        const params = {accept:true};
        cmp.lax.enqueue( 'c.updateContactTermsAcceptance', params )
            .then(response => {
                let dto = response;
                if(dto.isSuccess) {
                    this.displayUiMsg(cmp,dto.severity,dto.message);
                    let contact = null;
                    this.collectionUtils.getMapValue(this.MAP_KEY_CONTACT, dto.values, function (value) {contact = value;});
                    // this.writeCookie(cmp,contact);  DEPRICATED
                } else {
                    this.log(cmp, dto.message,dto.severity, dto);
                }
                cmp.find("bottomNavOverlayLib").notifyClose();
            })
            .catch(errors => {
                this.handleErrors(cmp, errors);
                cmp.find("bottomNavOverlayLib").notifyClose();
            });
    },
    //----- DEPRECATED
    // writeCookie: function(cmp,contact) {
    //     if(contact) {
    //         try {
    //             let uid = cmp.get('v.currentUserId');
    //             let cookieName = uid + '_termsAcceptanceDate';
    //             localStorage.setItem(cookieName, contact.Community_Terms_Accepted_Date__c);
    //             let acceptanceDate = localStorage.getItem( cookieName);
    //             this.log( cmp,'terms acceptanceDate set in local storage (cookie) named ' + cookieName + ' value='+acceptanceDate);
    //         } catch (e) {
    //             this.log(cmp,'error writing cooking','error',e);
    //         }
    //     }
    // },
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