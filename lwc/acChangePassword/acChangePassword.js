import {LightningElement, track, api, wire} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import { loadScript, loadStyle } from 'lightning/platformResourceLoader';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {reduceErrors} from 'c/ldsUtils';
import retrieveUserPwInfo   from '@salesforce/apex/AcChangePasswordController.retrieveUserPwInfo';
import updatePassword   from '@salesforce/apex/AcChangePasswordController.updatePassword';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';

//  @todo some of these should probably be design props / custom metadata
const   MAP_KEY_USER_PW_INFO                        =       'USER_PW_INFO';
const   MAP_KEY_COMMUNITY_PW_POLICY_STATEMENT       =       'COMMUNITY_PW_POLICY_STATEMENT';
const   ENTER_KEY                                   =       13;
const   OLD_PW_DATAID                               =       'currentPassword';
const   NEW_PW_DATAID                               =       'newPassword';
const   CONFIRM_PW_DATAID                           =       'confirmPassword';
const   MAX_OLD_PW_TRIES                            =       3;
const   MAX_PW_HELP_BREAKPOINT                      =       715;
const   MIN_PW_LENGTH                               =       8;
const   MIN_PW_NUMBERS                              =       1;
/**
 *  AcChangePassword is a class used to replace the OOTB community change password since it's functionality is
 *  severely limited.. styling is difficult for mobile, and it can't be branded.
 *  @todo there is currently too much code in here. This should probably be broken down into multiple child components.
 */
export default class AcChangePassword extends NavigationMixin(LightningElement) {

    //--- private / non reactive
    _debugConsole = true;
    _className = 'AcChangePassword';
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _allowForgotPasswordRedirect = true; //  If the user gets its wrong many times. display a link to forgot password.
    _oldPasswordIncorrectCount = 0;
    _oldPasswordCustomValidityMsg = '';
    _lastIncorrectOldPasswordValue;
    _validPolicyClass = 'fas fa-check-circle accel-pw-success-checks';
    _invalidPolicyClass = 'far fa-circle';
    _validPolicyTextClass = 'accel-pw-success-checks';
    _invalidPolicyTextClass = '';

    @track error;
    @track  wiredUserPwInfoDto;
    @track user;
    @track communityPwPolicyStatement;
    @track currentPassword;
    @track newPassword;
    @track confirmPassword;
    @track isRunningUpdate = false;
    @track displayOldPwHelp = false;
    @track showRightSidePasswordHelp = true;
    @track showInteriorPasswordHelp = false;
    @track minPasswordLength;
    @track minPasswordNumbers;
    @track passwordInputType = 'password';
    @track showPasswords = false;
    @track hidePasswords = true;

    @track _policyCharNumberCheckMarkClass = this._invalidPolicyClass;
    @track _policyCharNumberTextClass = this._invalidPolicyClass;
    @track _policyDigitsCheckMarkClass = this._invalidPolicyClass;
    @track _passwordsMatchCheckMarkClass = this._invalidPolicyClass;
    @track _policyDigitsTextClass = this._invalidPolicyTextClass;
    @track _displayPolicyCharNumberMsgGood = false;
    @track _displayPolicyCharNumberMsgBad = false;
    @track _displayPasswordsMatchMsgGood = false;
    @track _displayPasswordsMatchMsgBad = false;
    @track _displayPasswordsMatchMsgGoodSoFar = false;

    @api   sendConfirmEmail;
    @api   autoFocusOnInitialLoad;

    @api
    get policyCharNumberCheckMarkClass() { return this._policyCharNumberCheckMarkClass; }
    set policyCharNumberCheckMarkClass(val) { this._policyCharNumberCheckMarkClass = val; }
    @api
    get policyDigitsCheckMarkClass() { return this._policyDigitsCheckMarkClass; }
    set policyDigitsCheckMarkClass(val) { this._policyDigitsCheckMarkClass = val; }
    @api
    get passwordsMatchCheckMarkClass() { return this._passwordsMatchCheckMarkClass; }
    set passwordsMatchCheckMarkClass(val) { this._passwordsMatchCheckMarkClass = val; }
    @api
    get policyCharNumberTextClass() { return this._policyCharNumberTextClass; }
    set policyCharNumberTextClass(val) { this._policyCharNumberTextClass = val; }
    @api
    get policyDigitsTextClass() { return this._policyDigitsTextClass; }
    set policyDigitsTextClass(val) { this._policyDigitsTextClass = val; }
    @api
    get displayPolicyCharNumberMsgGood() { return this._displayPolicyCharNumberMsgGood; }
    set displayPolicyCharNumberMsgGood(val) { this._displayPolicyCharNumberMsgGood = val; }
    @api
    get displayPolicyCharNumberMsgBad() { return this._displayPolicyCharNumberMsgBad; }
    set displayPolicyCharNumberMsgBad(val) { this._displayPolicyCharNumberMsgBad = val; }
    @api
    get displayPasswordsMatchMsgGood() { return this._displayPasswordsMatchMsgGood; }
    set displayPasswordsMatchMsgGood(val) { this._displayPasswordsMatchMsgGood = val; }
    @api
    get displayPasswordsMatchMsgBad() { return this._displayPasswordsMatchMsgBad; }
    set displayPasswordsMatchMsgBad(val) { this._displayPasswordsMatchMsgBad = val; }
    @api
    get displayPasswordsMatchMsgGoodSoFar() { return this._displayPasswordsMatchMsgGoodSoFar; }
    set displayPasswordsMatchMsgGoodSoFar(val) { this._displayPasswordsMatchMsgGoodSoFar = val; }

    /**
     * Merely initializes some tracked properties.
     */
    constructor() {
        super();
        this.sendConfirmEmail = false;
        this.autoFocusOnInitialLoad = true;
        this.minPasswordLength = MIN_PW_LENGTH;
        this.minPasswordNumbers = MIN_PW_NUMBERS;
    }
    /**
     *  If public prop tells us to auto focus on load.. set focus to the old/current password input field for
     *  usability issues. Load font awesome css and js.  Determine if we want password help on the interior / near
     *  the controls (mobile / tablet) or on the right side (desktop)
     */
    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;
        this.loadFontAwesome();
        this.buildThemeOverrideCss();
        this.buildOverrideCss();

        //--- window.scrollTo(0, 1);
        const templateWidth = this.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
        this.determinePwHelpLocation(templateWidth);
        if (this.autoFocusOnInitialLoad /*&& this.showRightSidePasswordHelp*/) {
            const eleCurrentPw  = this.getFieldByDataId(OLD_PW_DATAID);
            if(eleCurrentPw) {
                eleCurrentPw.focus();
                eleCurrentPw.scrollIntoView(true);
            }
        }
        this.registerWindowEvents();
    }
    /**
     * Merely retrieves from the server the textual policy statement on the profile.
     * @param wiredUserPwInfoDto
     */
    @wire(retrieveUserPwInfo)
    wiredCommunityUserSettingsData(wiredUserPwInfoDto) {
        this._accelUtils.logDebug(this._className +' start of wired call for user  pw info');
        this.wiredUserPwInfoDto = wiredUserPwInfoDto;
        const { data, error } = this.wiredUserPwInfoDto;
        if(data) {
            this.user = this._accelUtils.getMapValue(MAP_KEY_USER_PW_INFO,data.values);
            this.communityPwPolicyStatement = this._accelUtils.getMapValue(MAP_KEY_COMMUNITY_PW_POLICY_STATEMENT,data.values);
        } else if (error) {
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving user pw info: '+this.error,'error');
            this._accelUtils.logError(this._className,this.error);
        } else {
            this._accelUtils.logDebug(this._className +' wired no data yet ');
        }
    }
    /**
     * Fires the SS update / Toasts a success (hopefully). Will send a confirmation email if this.sendConfirmEmail
     * is true. If there is a failure.. will toast the user.. if the old password is incorrect utilize the
     * evalOldPassword method for field notification.
     */
    updateUserPassword() {
        let params = {
            currentPassword: this.currentPassword, newPassword: this.newPassword,
            confirmPassword: this.confirmPassword, sendConfirmEmail: this.sendConfirmEmail
        };
        this._accelUtils.logDebug(this._className + ' calling updatePassword with params:' + JSON.stringify(params));
        console.log('before call');
        updatePassword(params)
            .then(result => {
                let dto = result;
                console.log(JSON.stringify(dto));
                if (dto.isSuccess) {
                    //------------------------ refreshApex(this.wiredUserPwInfoDto);
                    this.showToast('', 'Your password was changed successfully!', 'success');
                    this.navigate('home');
                } else {
                    this._accelUtils.logError(this._className + ' error in cb of updatePassword' + JSON.stringify(dto));
                    this.isRunningUpdate = false;
                    if (dto.message.includes('old')) {
                        this.evalOldPasswordFailure(dto);
                    }
                    this.showToast('', dto.message, 'error');
                }
            })
            .catch(error => {
                this._accelUtils.logError(this._className + ' error on call of updatePassword' + JSON.stringify(error));
                this.isRunningUpdate = false;
                this.showToast('', 'Error changing password', 'error');
            });
    }
    /**
     * Handles the onchange of current, new, confirm passwords and delegates validation if needed.
     * @param event
     */
    handleInputChange(event) {
        const field = event.target.name;
        const value = event.target.value;
        switch (field) {
            case  OLD_PW_DATAID:
                this.currentPassword = value;
                this.clearCurrentPwMessage();
                break;
            case  NEW_PW_DATAID:
                this.newPassword = value;
                //  Copy new pw data to confirm new password on Mobile since we aren't showing it (SFDC requires this)
                if(this.showInteriorPasswordHelp) {
                    this.confirmPassword = value;
                }
                this.validateNewPw(value);
                break;
            case  CONFIRM_PW_DATAID:
                this.confirmPassword = value;
                this.validateConfirmPw(value);
                break;
            default:
                console.log('huh? unless we added a new input this should not be hit.');
        }
    }
    /**
     * Capture the enter key on the last input
     * @param event
     */
    handleKeyPress(event) {
        if(event.which && event.which === ENTER_KEY) {
            this.handleChangePassword(event);
        }
    }
    /**
     * Delegate blue event to handleInputChange.
     * @param event
     */
    handleCurrentPasswordBlur(event) {
        this.handleInputChange(event);
    }
    /**
     *
     * Roll through all the inputs and check their validity.. if all is good. fire server update.. otherwise,
     * report validity.
     * @param event
     */
    handleChangePassword( event ) {
        event.preventDefault();
        this.isRunningUpdate = true;
        const allInputs = this.template.querySelectorAll("lightning-input");
        let allValid = true;
        allInputs.forEach(function(ele){
            if(!ele.checkValidity()) {
                ele.reportValidity();
                allValid = false;
            }
        });
        if(allValid) {
            this.updateUserPassword();
        } else {
            this.isRunningUpdate = false;
        }
    }
    /**
     * Do a simple redirect to forgot password.
     * @param event
     * @todo get current community name dynamically
     * @todo why does navigation mixin not work with directory qualifiers?
     * https://portal.accelentertainment.com/s/login/ForgotPassword
     */
    handleResetPw(event) {
        //window.location.href = '/community/s/login/ForgotPassword'; // @TODO hack make navigate work for this!
        //this.navigate('login/ForgotPassword'); //this doesn't work either.. community defect?
        window.location.href = '/s/login/ForgotPassword'; // @TODO hack make navigate work for this
    }
    /**
     * Hide / show passwords via changing swapping the input type between input / password (Mobile Only)
     * @param event
     */
    handleTogglePwDisplay(event) {
        this.showPasswords = !this.showPasswords;
        this.hidePasswords = !this.hidePasswords;
        this.passwordInputType = this.showPasswords ? 'text' : 'password';
    }
    /**
     * If we were prompted by the server that our old (ie current password was wrong) and the user is attempting
     * to fix this now.. remove warning.
     */
    clearCurrentPwMessage() {
        try {
            let ele  = this.getFieldByDataId(OLD_PW_DATAID);
            if (this._oldPasswordCustomValidityMsg.includes('old')) {
                ele.setCustomValidity('');
                ele.reportValidity();
                this._oldPasswordCustomValidityMsg = '';
            }
        } catch (e) {
            console.error(e);
        }
    }
    validateConfirmPw(value) {
        if(value && this.newPassword) {
            if(value === this.newPassword) {
                this.passwordsMatchCheckMarkClass = this._validPolicyClass;
                this.displayPasswordsMatchMsgGood = true;
            } else {
                this.passwordsMatchCheckMarkClass = this._invalidPolicyTextClass;
                this.displayPasswordsMatchMsgGood = false;
            }
            this.displayPasswordsMatchMsgBad = !this.newPassword.startsWith(value);
            this.displayPasswordsMatchMsgGoodSoFar = !this.displayPasswordsMatchMsgBad && !this.displayPasswordsMatchMsgGood;
        } else {
            this.displayPasswordsMatchMsgGood = false;
            this.displayPasswordsMatchMsgBad = false;
            this.displayPasswordsMatchMsgGoodSoFar = false;
        }
    }
    /**
     * Checks each password policy rule and toggles pw help icon (desktop / right side) as well
     * as interior form input text (ie. Good / Too Weak)
     * @param value
     * @todo this are static policy rules. find a way to pull them dynamically.
     */
    validateNewPw(value) {
        if(value && value.length >= this.minPasswordLength) {
            this.policyCharNumberCheckMarkClass = this._validPolicyClass;
            this.policyCharNumberTextClass = this._validPolicyTextClass;
        } else {
            this.policyCharNumberCheckMarkClass = this._invalidPolicyClass;
            this.policyCharNumberTextClass = this._invalidPolicyClass;
        }
        if(value && this.hasNumber(value)) {
            this.policyDigitsCheckMarkClass = this._validPolicyClass;
            this.policyDigitsTextClass = this._validPolicyTextClass;
        } else {
            this.policyDigitsCheckMarkClass = this._invalidPolicyClass;
            this.policyDigitsTextClass = this._invalidPolicyTextClass;
        }
        const ele  = this.getFieldByDataId(NEW_PW_DATAID);
        this.displayPolicyCharNumberMsgGood = ele.checkValidity();
        this.displayPolicyCharNumberMsgBad = !this.displayPolicyCharNumberMsgGood;
    }
    /**
     *
     * @param dto
     */
    evalOldPasswordFailure(dto) {
        let ele  = this.getFieldByDataId(OLD_PW_DATAID);
        ele.setCustomValidity(dto.message);
        ele.reportValidity();
        ele.focus();
        this._lastIncorrectOldPasswordValue = ele.value;
        this._oldPasswordCustomValidityMsg = dto.message;
        this._oldPasswordIncorrectCount++;
        if(this._oldPasswordIncorrectCount === MAX_OLD_PW_TRIES && this._allowForgotPasswordRedirect) {
            this.displayOldPwHelp = true;
        }
    }
    /**
     *
     * @param pageName
     * @todo this should work..
     */
    navigate(pageName) {
        try {
            this._accelUtils.logDebug(this._className +' attempting to nav to pageName:'+pageName);
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: pageName,
                },
            });
        } catch (e) {
            this._accelUtils.logError(this._className +' ERROR attempting to nav to pageName:'+JSON.stringify(e));
        }
    }
    /**
     * Looks data-id attribute on the html element and returns the element if found.
     * @param dataId
     * @returns {Element | any}
     */
    getFieldByDataId( dataId ) {
        return this.template.querySelector('[data-id="'+dataId+'"]');
    }
    /**
     *
     * @param title
     * @param msg
     * @param variant
     */
    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    /**
     * Based on the breakpoint set of the bounding div width, either put FULL pw help on right (Desktop) or a subset
     * on the interior of the form (mobile / tablet)
     *
     * @param templateWidth
     */
    determinePwHelpLocation(templateWidth) {
        if (templateWidth > MAX_PW_HELP_BREAKPOINT) {
            this.showRightSidePasswordHelp = true;
            this.showInteriorPasswordHelp = false;
        } else {
            this.showRightSidePasswordHelp = false;
            this.showInteriorPasswordHelp = true;
        }
    }
    /**
     * Register a window event to constantly determine the amount of real-estate (not including left nav) so we
     * can determine what device we are on. This is a bit more accurate and up to date then media queries.
     */
    registerWindowEvents() {
        let self = this;
        window.addEventListener('resize', function() {
            const templateWidth = self.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
            self.determinePwHelpLocation(templateWidth);
        });
    }
    /**
     * Loads font awesome js and css for fonts not available in SLDS.
     * @todo only load what is needed. we are probably loading too much here.
     */
    loadFontAwesome() {
        Promise.all([
            loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/all.css'),
        ])
            .then(() => {
                console.log('fa loaded');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }
    /**
     * Checks the string contains a number,
     * @param s
     * @returns {boolean}
     */
    hasNumber(s) {
        return /\d/.test(s);
    }
    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     * @media only screen and (max-width: {whatever mobile is set t}px)
     *
     * note: I hate doing this but the theme is to opinionated in its use of fixed headers and menus  as that throws everything else
     * off and eliminates a users a ability to pinch zoom which is generally an accessibility no no. I think users
     * are fairly used to the banner / menu hiding when scrolling down in order to save space and reappearing when
     * scrolling back up by now. The other side effect is that it removes the ability of chrome browsers to be smart enough
     * to hide / show the url bar and bottom tool bar.
     */
    buildThemeOverrideCss() {
        const mobile = this._accelUtils.MOBILE_FORM_WIDTH;
        let css = '@media only screen and (max-width: ' + mobile + 'px) {';
        css += '.cAccel_CommunityServiceMobileThemeLayout .accel-content {';
        css += 'padding:2px 8px 2px 4px!important;position:relative;top:0px;min-height: inherit;} ';
        css += '.slds-col_padded, .slds-col--padded{padding-left:2px;padding-right:2px;padding-top:5px}';
        css += '.siteforceContentArea .comm-layout-column:not(:empty) {padding-top: 0px }';
        //--- the below overrides the mobile nav from fixed to relativc
        css += '.cAccel_CommunityServiceMobileThemeLayout .accel-community-header {'
        css += 'position:relative;} ';
        //--- the below overrides the mobile menu from fixed to relative.
        css += '.cAccel_CommunityServiceMobileThemeLayout .accel-theme-mobile-menu {';
        css += 'position:relative;top:0px} ';
        css += '}';
        css += '}';
        const style = document.createElement('style');
        style.innerText = css;
        let target = this.template.querySelector('.fake-theme-overrides-class');
        target.appendChild(style);
    }

    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders.
     */
    buildOverrideCss() {
        let css = '@media only screen and (min-width: 768px) {';
        css += '.slds-input { background-color: rgb(255, 255, 255);width: 100%;display: inline-block;height: 40px; ';
        css += 'font-size: 16px;font-weight: 500;line-height: 40px;min-height: calc(1.875rem + 2px);border-width: 1px;';
        css += 'border-style: solid;border-color: rgb(219, 219, 219);border-image: initial;border-radius: 0.25rem;';
        css += 'transition: border 0.1s linear 0s, background-color 0.1s linear 0s;padding: .75rem;}';
        css+= '}';
        const style = document.createElement('style');
        style.innerText = css;
        let target = this.template.querySelector('.fake-input-overrides-class');
        target.appendChild(style);
    }
    /**
     * For future use.. looks like mr asshole lightning locker service won't let us do this currently. this can be useful
     * for, after setting focus, to move the cursor to the beginning if a password manager filled in the text input
     * (as opposed to the default end)
     *
     * @param el
     * @param caretPos
     * @returns {boolean}
     */
    // setCaretPosition(el, caretPos) {
    //     if (!el || !caretPos) {
    //         return false;
    //     }
    //     el.value = el.value;
    //     // ^ this is used to not only get "focus", but
    //     // to make sure we don't have it everything -selected-
    //     // (it causes an issue in chrome, and having it doesn't hurt any other browser)
    //     if (el.createTextRange) {
    //         let range = el.createTextRange();
    //         range.move('character', caretPos);
    //         range.select();
    //         return true;
    //     } else {
    //         if (el.selectionStart !== undefined) {
    //             el.focus();
    //             el.setSelectionRange(caretPos, caretPos);
    //             return true;
    //         } else {
    //             el.focus();
    //             return false;
    //         }
    //     }
    // }
}