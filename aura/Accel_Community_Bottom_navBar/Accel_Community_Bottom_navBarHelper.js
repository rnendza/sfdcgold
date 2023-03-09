({
    collectionUtils: null, loggingUtils : null, uiMessagingUtils: null,
    MAP_KEY_CONTACT : 'CONTACT_SOBJECT',MAP_KEY_COMMUNITY_METADATA : 'COMMUNITY_METADATA',
    MAP_KEY_CURRENT_SESSION : 'CURRENT_SESSION',
    EXTERNAL_LOGIN_USER_TYPE : 'CspLitePortal',
    EXTERNAL_LOGIN_LOGIN_TYPE : 'Chatter Communities External User',
    /**
     * Pop the terms acceptance modal using Accel_Community_TermsOfUse for it's content.
     * @param cmp
     */
    doOpenTerms: function (cmp) {
        this.log(cmp,'Attempting open of Terms of Use Dialog');
        $A.createComponent("c:Accel_Community_TermsOfUse", {},
            function (content, status) {
                if (status === "SUCCESS") {
                    let showCloseButton = cmp.get('v.communityTermsAccepted');
                    let header = $A.get("$Label.c.Terms_of_Service_Modal_Header");
                    cmp.find('bottomNavOverlayLib').showCustomModal({
                        header: header,
                        body: content,
                        showCloseButton: showCloseButton,
                        cssClass: "slds-modal_large",
                    })
                }
            });
    },
    /**
     *
     * @param cmp
     */
    doOpenWhatsNew: function (cmp) {
        this.log(cmp,'Attempting open of Whats New Modal');
        var self = this;
        try {
            $A.createComponent("c:Accel_CommunityWhatsNew", {},
                function (content, status) {
                    self.log(cmp, 'Attempting open of Whats New Modal callback status' + status);
                    if (status === "SUCCESS") {
                        let showCloseButton = true;
                        let header = $A.get("$Label.c.Whats_New_Modal_Header");
                        cmp.find('bottomNavOverlayLib').showCustomModal({
                            header: header,
                            body: content,
                            showCloseButton: showCloseButton,
                            cssClass: "slds-modal_large",
                        })
                    }
                });
        } catch (e) {
            self.log(cmp,'error creating whats new comp','error',JSON.stringify(e));
            alert(e);
        }
    },
    /**
     *
     * @param cmp
     */
    doOpenPrivacy: function (cmp) {
        this.log(cmp,'Attempting open of Whats New Modal');
        var self = this;
        try {
            $A.createComponent("c:Accel_CommunityPrivacy", {},
                function (content, status) {
                    self.log(cmp, 'Attempting open of Privacy Modal callback status' + status);
                    if (status === "SUCCESS") {
                        let showCloseButton = true;
                        let header = $A.get("$Label.c.Privacy_Modal_Header");
                        cmp.find('bottomNavOverlayLib').showCustomModal({
                            header: header,
                            body: content,
                            showCloseButton: showCloseButton,
                            cssClass: "slds-modal_large",
                        })
                    }
                });
        } catch (e) {
            self.log(cmp,'error creating whats new comp','error',JSON.stringify(e));
            alert(e);
        }
    },
    /**
     * Check cookie if exists. we are good.. if not check contact date field. if exists we are good.. if not pop modal.
     * @TODO deprecate the use of cookies.
     * @param cmp
     */
    checkForTermsAcceptance: function (cmp) {
        this.checkContactRecord(cmp);
    },
    /**
     *
     * @param cmp
     */
    retrieveCommunityMetadata: function(cmp) {
        console.log(cmp,'Calling server for retrieveCommunityMdt');
        cmp.lax.enqueue('c.retrieveCommunityMetadata')
            .then(response => {
                let dto = response;
                let communityMdt =  null;
                this.collectionUtils.getMapValue(this.MAP_KEY_COMMUNITY_METADATA, dto.values, function (value) {communityMdt = value;});
                cmp.set('v.communityMdt',communityMdt);
                this.log(cmp, 'community Mdt','info',JSON.stringify(cmp.get('v.communityMdt')));
                if(communityMdt) {
                    if(communityMdt.Display_Bottom_Nav_Options__c === true) {
                        cmp.set('v.displayBottomNavOptions', true)
                        if(communityMdt.Display_Privacy_Link__c === true) {
                            cmp.set('v.displayPrivacyLink',true);
                        }
                    }
                    // if(communityMdt.Disable_License_Expiration_Messaging__c === true) {
                    //     cmp.set('v.disableLicenseExpirationMessaging',true);
                    //     this.log( cmp,'disabling license expiration messaging!');
                    // }
                } else {
                    this.log(cmp,'Community Metadata to Display_Bottom_Nav_Options__c not found or false.. ');
                }
            })
            .catch(errors => {
                console.error(errors);
            });
    },
    /**
     *
     * @param cmp
     */
    checkContactRecord: function(cmp) {
        console.log(cmp,'Calling server for retrieveUserContact');
        cmp.lax.enqueue('c.retrieveUserContact')
            .then(response => {
                let dto = response;
                let contact = null;
                this.collectionUtils.getMapValue(this.MAP_KEY_CONTACT, dto.values, function (value) {
                    contact = value;
                });

                let communityMdt = null;
                this.collectionUtils.getMapValue(this.MAP_KEY_COMMUNITY_METADATA, dto.values, function (value) {
                    communityMdt = value;
                });
                cmp.set('v.communityMdt', communityMdt);
                this.log(cmp, 'community Mdt', 'info', JSON.stringify(cmp.get('v.communityMdt')));

                if (communityMdt && communityMdt.Display_Bottom_Nav_Options__c === true) {
                    cmp.set('v.displayBottomNavOptions', true)
                } else {
                    this.log(cmp, 'Community Metadata to Display_Bottom_Nav_Options__c not found or false.. ');
                }
                if (!contact) {
                    //situation where there is no contact related to the user record yet we are in communities.
                    //generally should not happen but may if a system admin is logged in SFDC and simply does
                    //setup all communities and clicks hte community link yet never set himself up as a true
                    //community user.
                    this.log(cmp, 'contact is undefined and not passed back from server.. just exiting ', dto);
                    return;
                }
                const session = this.collectionUtils.getData(this.MAP_KEY_CURRENT_SESSION, dto.values);

                if (contact && contact.Community_Terms_Accepted_Date__c) {
                    console.log('user does have contact record flagged with Community Terms Accepted date: contact=' + JSON.stringify(contact));
                    cmp.set('v.communityTermsAccepted', true);
                } else {
                    console.log('no value on contact for communityTermsAcceptedDate.. contact=' + JSON.stringify(contact));
                    if (communityMdt && communityMdt.Disable_Terms_of_Service_Autodisplay__c !== true) {
                        if (this.isExternalLogin(session)) {
                            this.log(cmp, 'autodisplaying modal');
                            this.doOpenTerms(cmp);
                        }
                    } else {
                        this.log(cmp, 'bypassing autodisplay of modal due to custom settting:' + JSON.stringify(communityMdt));
                    }
                }
                if(!this.isExternalLogin(session) && communityMdt && communityMdt.Allow_Impersonation_Toast__c) {
                    let msg = 'You are currently impersonating user ' + session.Username+'.';
                    if (contact && !contact.Community_Terms_Accepted_Date__c) {
                        msg += ' They have not accepted Terms of Service.';
                    }
                    //this.log(cmp,'session from dto','info',session);
                    this.displayUiMsg(cmp,'info', msg);
                }
            })
            .catch(errors => {
               console.error(errors);
            });
    },
    /**
     * Uses Session info returned from retrieveUserContact to determine if it's an external login (ie not impersonated)
     * @param session        See link below for possible values.
     * @return {boolean}     True if use used the login page, otherwise false.
     *
     * @see https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_class_Auth_SessionManagement.htm
     */
    isExternalLogin: function(session) {
        let isExternal = false;
        if (session &&
            session.UserType === this.EXTERNAL_LOGIN_USER_TYPE || session.LoginType === this.EXTERNAL_LOGIN_LOGIN_TYPE) {
            isExternal = true;
        }
        return isExternal;
    },
    displayUiMsg: function (cmp, type, msg) {
        if(this.uiMessagingUtils) {
            this.uiMessagingUtils.displayUiMsg(type, msg);
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
    }
});