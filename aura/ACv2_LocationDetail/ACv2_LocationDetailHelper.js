({
    MAP_KEY_ACCOUNT_LICENSE_WRAPPERS : 'ACCOUNT_LICENSE_WRAPPERS',
    MAP_KEY_ACCOUNT_LICENSE_SUMMARY  : 'ACCOUNT_LICENSE_SUMMARY',
    collectionUtils:null,
    loggingUtils:null,
    formatUtils: null,
    uiMessagingUtils: null,
    //https://accel-entertainment.monday.com/boards/286658657/
    friendlyErrorMsg:'Error default to be replaced by label',
    friendlyErrorMsgMode:'dismissible',
    friendlyErrorMsgDuration:20000, //20 seconds
    /**
     * Calls the server to retrieve account licensing data and then processes it for display placing it attributes
     * to pass to the child.
     *
     * @param cmp
     */
    retrieveLocationLicenseData: function (cmp) {
        cmp.lax.enqueue('c.retrieveAccountLicenses')
            .then(response => {
                this.processLocationLicenses(cmp, response);
            })
            .catch(errors => {
                cmp.set('v.errorThrown',true); //@TODO check this. not sure this is working as intended on the child cmp.
                this.log(cmp,'generic','error',JSON.stringify(errors));
            });
    },
    /**
     * Rolls through response from server call setting attributes that will be passed to the child accordion which
     * displays the location and license data.
     *
     * @param cmp`
     * @param response  The response from the server containing a ResponseDto object.
     */
    processLocationLicenses: function(cmp,response) {
        let dto = response;
        let locLicenseWraps = [];
        let locationLicenseSummary = null;
        //-- deprecated
        // this.collectionUtils.getMapValue(this.MAP_KEY_ACCOUNT_LICENSE_WRAPPERS, dto.values, function (value) {locLicenseWraps = value;});
        // this.collectionUtils.getMapValue(this.MAP_KEY_ACCOUNT_LICENSE_SUMMARY, dto.values, function (value) {locationLicenseSummary = value;});
        locLicenseWraps = this.collectionUtils.getData(this.MAP_KEY_ACCOUNT_LICENSE_WRAPPERS,dto.values);
        locationLicenseSummary = this.collectionUtils.getData(this.MAP_KEY_ACCOUNT_LICENSE_SUMMARY,dto.values);

        let activeSections = [];
        if (locLicenseWraps) {
            activeSections.push(locLicenseWraps[0].accountId); //  always expand the first section of the accordion.
            if(locLicenseWraps.length > 1) {
                for (let i = 1; i < locLicenseWraps.length; i++) {
                    let locLicenseWrap = locLicenseWraps[i];
                    //  If any license is expired or expiring, expand the section.
                    if(locLicenseWrap &&  ( locLicenseWrap.anyLicenseExpired || locLicenseWrap.anyLicenseExpiring) ) {
                        activeSections.push(locLicenseWrap.accountId);
                    }
                }
            }
            //<!-- https://accel-entertainment.monday.com/boards/286658657/pulses/311323513 -->
            cmp.set('v.locationLicenseSummary',locationLicenseSummary);
            cmp.set('v.locationLicenseData', locLicenseWraps);
            //--- Note there is a value change handler on the child watching this so never move it to a loop! ie
            //--- the set of the activeSections attribute.
            cmp.set('v.activeSections', activeSections);
            cmp.set('v.locDataTabLoaded',true);
        } else  {
           // cmp.set('v.noLicenseDataFoundMsg','No License Data Found!');
            this.uiMessagingUtils.displayUiMsg('warn','There was a problem retrieving location data. Please' +
                ' contact your administrator.');
        }

        //check for expiring or expired.
    },
    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders. also bold the text on the selected tab
     * @media only screen and (max-width: 896px)
     <style>
     .cAccel_CommunityServiceMobileThemeLayout .accel-content
     */
    buildOverrideCss: function(cmp) {
        const mobile = 767;
        let css = '@media only screen and (max-width: '+mobile+'px) {';
        css+='.cAccel_CommunityServiceMobileThemeLayout .accel-content {';
        css+='padding:2px 8px 2px 4px!important} ';
        css+='.slds-col_padded, .slds-col--padded{padding-left:2px;padding-right:2px;padding-top:5px}';
        css+='.siteforceContentArea .comm-layout-column:not(:empty) {padding-top: 10px }}';

        const style = document.createElement('style');
        style.innerText = css;
        let target = document.querySelector('.fake-theme-overrides-class');
        target.appendChild(style);
    },
    /**
     *
     * @param cmp
     * @param msg    if msg is an error and contains generic. will toast a generic error msg.
     * @param level
     * @param jsonObj
     */
    log: function (cmp, msg, level, jsonObj) {
        var lvl;
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
                var cmpName = '--- ACv2_LocationDetail CMP --- ';
                var cLogger = this.loggingUtils;
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
    },
});