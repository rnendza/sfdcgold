import {LightningElement, track, api, wire} from 'lwc';
import { refreshApex } from '@salesforce/apex';
import {subscribe, unsubscribe, onError, setDebugFlag, isEmpEnabled} from 'lightning/empApi';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

import retrieveAllWatchdogData              from '@salesforce/apex/SvcWatchdogController.retrieveCasesMissingAssignedResourcesCacheable';
import retrieveUsersToBypassNotification    from '@salesforce/apex/SvcWatchdogControllerBypass.retrieveAssignedResourceToBypassManualNotification';
import retrieveNotificationSchedulingInfo   from '@salesforce/apex/SvcWatchdogController.retrieveNotificationSchedulingInfo';
import retrieveRunningUserData              from '@salesforce/apex/SvcWatchdogController.retrieveRunningUserData';
import noAssignedResourcesTitle             from '@salesforce/label/c.No_Assigned_Resource_Title';

const  MAP_KEY_WATCHDOG_WRAPPERS_ALERT     =   'WATCHDOG_WRAPPERS_TO_ALERT';
const  MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE   =   'WATCHDOG_WRAPPERS_TO_OBSERVE';
const  MAP_KEY_WATCHDOG_UTILITY_MDT        =   'WATCHDOG_UTILITY_MDT_NO_ASSIGNED_RESOURCE';
const  MAP_KEY_WATCHDOG_NOT_DISPATCHED_MDT =   'WATCHDOG_UTILITY_MDT_NOT_DISPATCHED';
const  MAP_KEY_USER_PROFILE_DATA           =   'USER_PROFILE_DATA';
const  MAP_KEY_CRON_TRIGGERS               =   'WATCHDOG_CRON_TRIGGERS';
const  MAP_KEY_SVC_WATCHDOG_UTIL_SETTINGS  =   'WATCHDOG_UTILITY_SETTINGS';
const  MAP_KEY_USERS_TO_BYPASS             =   'MAP_KEY_USERS_TO_BYPASS';
const  WATCH_TYPE_ALERT                    =   'ALERT';
const  WATCH_TYPE_OBSERVE                  =   'OBSERVE';
const  SCH_JOB_NAME                        =   'Accel_Schedule_Svc_Automated_Notifications';
//  @todo put this in custom mdt! This is to disable the notification indicator for these profiles
//  https://accel-entertainment.monday.com/boards/942883797/pulses/3101982498
const  PROFILES_TO_BYPASS                  =   ['Accel Regional Service Management V2','Accel Service User V2'];

/**
 * This class is the key client side class for the Service Watchdog timers.
 * Note: it does have methods running on intervals and is registering with the empApi for Platform Events.
 * Also. it's generally intended to be used with an aura parent so that it can utilized the utility bar API.
 * Note Platform Events, at the time of this modules creation, were proven unreliable this the interval polling
 * added every 5 seconds as well as a backup.
 */
export default class SvcWatchdogTimer extends LightningElement {

    @track error;
    @track isSubscribeDisabled                      = false;
    @track isUnsubscribeDisabled                    = !this.isSubscribeDisabled;
    @track svcApptIdClickedForNotification;
    @track allowNotDispatchedCustomNotifications    = false;
    @track firstScheduledJob;
    // https://accel-entertainment.monday.com/boards/942883797/pulses/3101982498
    @track profilesToBypass = PROFILES_TO_BYPASS;
    @track usersToBypass;

    /**
     *
     * @type {*[]}
     * @TODO dynamic icon Names!
     */
    @track
    menuFilterItems = [
        {id: 'menu-item-no-ass', label: 'No Assigned Resource', value: 'noass', checked: true, iconName: 'utility:resource_absence'},
        {id: 'menu-item-rejected', label: 'Rejected', value: 'rejected', checked: true, iconName: 'utility:dislike'},
        {id: 'menu-item-notdispatched', label: 'Unaccepted / Not Dispatched', value: 'notdispatched', checked: true, iconName: 'utility:waits'}
    ];
    @api svcObserve                         = [];
    @api svcAlert                           = [];
    @api displayedSvcAlert                  = [];
    @api wiredArDto;
    @api wiredUserDto;
    @api wiredSchedulingDto;
    @api isRunningFlow                      = false;
    @api allowCustomNotifications           = false;
    @api scheduledJobName                   = SCH_JOB_NAME;
    @api schedulerData;


    _allSubscriptions                       = [];
    _cName                                  = '';
    _timeIntervalInstance;
    _backupTimeIntervalInstance;
    _userProfile;
    _user;
    _svcWatchdogUtilityBarSettings;
    _notificationCounts;

    _caseAssignedResourcesPe                = [];
    _svcAppointmentStatusChangePe           = [];
    _svcAppointmentRejectedPe               = [];
    _svcAppointmentNotDispatchedPe          = [];
    _caseClosedPe                           = [];
    //https://accel-entertainment.monday.com/boards/286657232/pulses/314982925
    _forceCloseFilterMenu                   = false;
    autoPoppedOnce                          = false;  // avoid user annoyance.

    svcUtilityBarSettingMdt;
    svcWatchdogNotDispatchedSettingMdt;

    label = {noAssignedResourcesTitle};

    /**
     * Fires then the cmp instance is created.
     * Note. you can't really do much here so only use if you know what you're doing! ie. this is not the
     * equiv of an init handler in aura!
     */
    constructor() {
        super();
        this._cName = this.constructor.name;
    }
    /**
     * Fires of an initial retrieve of case data that meets the criteria and pops ui toolbar if applicable.
     * @TODO Bulk Subscribe? is it possible?
     */
    connectedCallback() {
        this.log(' connected callback =========');
        this.handleSubscribe('/event/Case_Assigned_Resource_PE__e');
        this.handleSubscribe('/event/Case_Closed_PE__e');
        this.handleSubscribe('/event/Service_Appointment_Rejected_PE__e');
        this.handleSubscribe('/event/Not_Dispatched_Platform_Event__e');
        this.handleSubscribe('/event/Service_Appointment_Status_Change_PE__e');
        this.startWatchdogTimerBackup();
    }
    /**
     * Fires when a cmp is removed from the DOM. Unsubscribe from Platform Event.
     */
    disconnectedCallback() {
        this.log(' disconnected callback =========');
        this.handleUnsubscribeAll();
    }

    /**
     * Fires after the cmp has finished rendering.
     * This will append a style tag inside of the alert card so that we can override the header (title area)
     * of the standard slds card as well as other base slds css.
     *
     * We can't do this in our css due to current LWC Shadow Dom Limitations.
     * We need to get tricky here.
     *
     * @TODO move styling to custom meta data or somewhere outside this code!
     */
    renderedCallback() {
        if (this.hasRendered) return;
        this.hasRendered = true;
        const style = document.createElement('style');
        style.innerText = '.slds-card__header { background-color:#F3F2F2;padding-bottom:5px;border-bottom:1px solid rgb(221, 219, 218);}';
        style.innerText += '.slds-form-element__icon{padding-top:0!important;} /*override*/';
        let target = this.template.querySelector('.fake-lightning-card-class');
        target.appendChild(style);
        this.buildFakeOverridesCss();
    }
   /*
   * May be called multiple times as per decided by the sfdc platform and cache. also manually called via refreshApex
   * upon reception of a Platform Event.
   *
   * Retrieves SS case data and metadata. Deep clones received array to tracked array for display (svcAlert).
   * Deep clones received array to track array for observation (ie counter incrementing) (svcObserve).
   * Dispatches an event to open ui toolbar if necessary. Starts the watchdog timer if any data to observe.
   *
   * @param wiredArDto  Passed by the Platform via wire api.
   * @see https://salesforce.stackexchange.com/questions/252699/when-do-wire-methods-run-lwc
   */
    @wire(retrieveAllWatchdogData)
    wiredWatchdogData(wiredArDto) {

        this.wiredArDto = wiredArDto;       // track the provisioned value
        const {data, error} = wiredArDto;  // destructure it for convenience
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item); // magic deep clone!

        if (data) {
            this.storeCustomMetadata(data);
            this.log(' dto from apex ' + JSON.stringify(data));

            if (data.isSuccess) { // Deep clone these sobs or u will experience massive pain!
                let tmpObserve = this.constructor.getMapValue(MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE, data.values);
                let tmpAlert = this.constructor.getMapValue(MAP_KEY_WATCHDOG_WRAPPERS_ALERT, data.values);
                this.filterAlerts(tmpAlert);
                this.svcAlert = tmpAlert; //I don't think the below is working as desired. .sort it server side for now
                // this.svcAlert = this.sortByAttribute(clone(tmpAlert), '-caseAgeSeconds');
                this.svcObserve = clone(tmpObserve);
                if (this.svcAlert.length > 0) { // We have Service Alerts
                    this.setUtilityLabel('Service Alerts (' + this.svcAlert.length + ')');
                    this.setUtilityHighlighted(true);
                    if(this.allowCustomNotifications) {
                        this.checkCustomNotifications(this.displayedSvcAlert, 'NOT_DISPATCHED','Manual',this.usersToBypass);
                    }
                    if (!this.svcUtilityBarSettingMdt.Disable_Utility_Bar_Auto_Open__c) {
                        this.openUtility(this.svcAlert);
                    } else if (!this.autoPoppedOnce) {
                        this.autoPoppedOnce = true;
                        this.openUtility(this.svcAlert);
                    }
                } else {
                    this.log(' no cases found to alert');
                    this.setUtilityLabel('Service Alerts (0)');
                }
                if (!this._timeIntervalInstance) {
                    this.startWatchDogTimer();  // Starts the Timer for case age minutes.
                }
            } else {
                this.log(' no cases found to alert or observe dto');
                this.setUtilityLabel('Service Alerts (0)');
                this.clearAllWatcherData();
            }
        } else if (error) {
            //@TODO Toast!
            console.error(JSON.stringify(error));
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
        this._notificationCounts = this.countAlertsByNotificationReason(this.svcAlert);
        this.log(' notification counts='+JSON.stringify(this._notificationCounts));
        this.setFilterMenuLabels();
    }
    /**
     * Retrieves user profile data.
     * @param wiredUserData Passed by the Platform via wire api.
     */
    @wire(retrieveRunningUserData)
    wiredRunningUserData(wiredUserDto) {
        this.wiredUserDto = wiredUserDto;      // track the provisioned value
        const { data, error } = wiredUserDto;  // destructure it for convenience
        if(data) {
            this._userProfile = this.constructor.getMapValue(MAP_KEY_USER_PROFILE_DATA, data.values);
            this._user = this.constructor.getMapValue('USER',data.values);
            this._svcWatchdogUtilityBarSettings = this.constructor.getMapValue(MAP_KEY_SVC_WATCHDOG_UTIL_SETTINGS,data.values);
            this.log(' user profile ' + JSON.stringify(this._userProfile));
            this.log('accel: svc watchdog utility bar settings='+ JSON.stringify(this._svcWatchdogUtilityBarSettings));
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    }

    /**
     * Retrieves information on whether the scheduled queueable job is running that sends automated notifications.
     *
     * @param error
     * @param data
     */
    @wire(retrieveNotificationSchedulingInfo,{jobName: '$scheduledJobName'})
    schedulingInfo (wiredData) {
        this.wiredSchedulingDto = wiredData;
        const {data, error} = wiredData;

        if (data) {
            this.schedulerData = this.constructor.getMapValue(MAP_KEY_CRON_TRIGGERS,data.values);
            this.log('accel: cronTriggers for ' +SCH_JOB_NAME + ' '  + JSON.stringify(this.schedulerData));
            this.firstScheduledJob = this.schedulerData.find(x=>x!==undefined);
            //alert(JSON.stringify(this.firstScheduledJob));
       } else if (error) {
            console.error(JSON.stringify(error));
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    }

    /**
     * With the profile names, retrieve all active users (user ids) for the passed profiles.
     *
     * @param wiredDto  - Data received in this call back from the wired method.
     * @see https://accel-entertainment.monday.com/boards/942883797/pulses/3101982498
     */
    @wire(retrieveUsersToBypassNotification,{profilesToBypass:'$profilesToBypass'})
    wiredUserData(wiredDto) {
        this.wiredBypassUserDto = wiredDto;
        const {data, error} = wiredDto;
        if(data) {
            let userIds = this.constructor.getMapValue(MAP_KEY_USERS_TO_BYPASS, data.values);
            if(userIds) {
               this.log('----> userIds to bypass for assigned resource..'+JSON.stringify(userIds));
            }
            this.usersToBypass = userIds;
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = 'Unknown error';
            if (Array.isArray(error.body)) {
                this.error = error.body.map(e => e.message).join(', ');
            } else if (typeof error.body.message === 'string') {
                this.error = error.body.message;
            }
        }
    }

    /**
     *
     * @param data
     */
    storeCustomMetadata(data) {
        this.svcUtilityBarSettingMdt = this.constructor.getMapValue(MAP_KEY_WATCHDOG_UTILITY_MDT, data.values);
        this.svcWatchdogNotDispatchedSettingMdt = this.constructor.getMapValue(MAP_KEY_WATCHDOG_NOT_DISPATCHED_MDT,data.values);

        if(this.svcWatchdogNotDispatchedSettingMdt) {
            if(this.svcWatchdogNotDispatchedSettingMdt.Allow_Custom_Notifications__c) {
                this.allowNotDispatchedCustomNotifications =
                    this.svcWatchdogNotDispatchedSettingMdt.Allow_Custom_Notifications__c;
            }
        }
    }
    /**
     * Handles the selection of the menu filter. Will filter the svcAlerts arr via clone / filter
     * and check / uncheck the menu item.
     *
     * @param event
     */
    handleMenuSelect(event) {
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);
        const selectedItemValue = event.detail.value;
        this.log('handleMenuSelect.. selectedItemValue:'+selectedItemValue);
        const menuItem = this.menuFilterItems.find(function (item) {
            return item.value === selectedItemValue;
        });
        menuItem.checked = !menuItem.checked;
        this.log(' menuItem=' + JSON.stringify(menuItem));
        let tmpArr = clone(this.svcAlert);
        this.log(' tmpArr:' + JSON.stringify(tmpArr));
        this.filterAlerts(tmpArr);
        let x = this.highlightFilter;
    }
    /**
     * Filters the clonedArray via notificationReason.
     *
     * @param clonedArr
     * @TODO rewrite this its probably slow as hell with a ton of alerts.  given the inner loop
     */
    filterAlerts(clonedArr) {
        if (clonedArr.length > 0) {
            let newArr = [];
            for (let i = 0; i < clonedArr.length; i++) {
                let oTmp = {};
                oTmp = Object.assign(oTmp, clonedArr[i]);
                oTmp.showSendingCustomNotificationSpinner = false;
                for(let x = 0; x < this.menuFilterItems.length; x++) {
                    let menuItem = this.menuFilterItems[x];
                    if (oTmp.notificationReason === menuItem.label) {
                        oTmp.showWrap = menuItem.checked;

                    } else {
                        //console.log('accell in else in filter.. menuItemChecked='+menuItem.checked
                        // + '.. menuItem.label='+menuItem.label + '... oTmp.notificationReason='+oTmp.notificationReason);
                    }
                }
                newArr[i] = oTmp;
            }
            this.displayedSvcAlert = newArr;
            this.checkCustomNotifications(this.displayedSvcAlert, 'NOT_DISPATCHED','Manual',this.usersToBypass);
        }
    }
    /**
     * Dynamically add disableNotDisplayedNotification to the svcAlert object default to false but search through
     * child array of all the notifications sent for this service appointment for the alertType. if it hits on at least
     * one then disable the send of further notifications. (must be manual to disable it. automated will not disable it)
     *
     * @param svcAlerts         A mutable array!
     * @param alertType         The type of alert (Check Custom_Notifications_Sent__c.Alert_Type__c pl for possible values.
     * @param notificationType  The type of notification. [Manual,Automated]
     */
    checkCustomNotifications(svcAlerts, alertType,notificationType, usersToBypass) {
        if(this.allowCustomNotifications && svcAlerts && Array.isArray(svcAlerts)) {
            svcAlerts.forEach( function (svcAlert) {
               // console.log('----> svcAlert',svcAlert);
                svcAlert.disableNotDispatchedNotification = false;
                if(svcAlert.customNotificationsSent && svcAlert.customNotificationsSent.length > 0) {
                    let manualNotification = svcAlert.customNotificationsSent.find(x => x.Alert_Type__c === alertType && x.Notification_Type__c === notificationType);
                    let automatedNotification = svcAlert.customNotificationsSent.find(x => x.Alert_Type__c === alertType && x.Notification_Type__c === 'Automated');
                    if(automatedNotification) {
                        svcAlert.disabledDueToNotification = automatedNotification;
                        svcAlert.notificationSentClass = 'accel-notification-sent-text';
                        svcAlert.showNotDispatchedNotificationSent = true;
                        svcAlert.isAutomated  = true;
                    }
                    if(manualNotification) {  //  undefined if it doesn't find anything
                        svcAlert.disableNotDispatchedNotification = true;
                        svcAlert.disabledDueToNotification = manualNotification;
                        svcAlert.notificationSentClass = 'accel-notification-sent-text';
                        svcAlert.showNotDispatchedNotificationSent = true;
                        svcAlert.isAutomated = false;
                    }
                }
                if(svcAlert.assignedResourceId) {
                    if(usersToBypass){
                        if(usersToBypass.includes(svcAlert.assignedResourceId)) {
                            svcAlert.disableDueToProfiles = true;
                        }
                    }
                }
            });
        }
    }

    /**
     * High level kill switch is allowCustomNotifications (passed in from parent which means for any notification
     * type. Next level is specific to type of alert.
     * @return {boolean|boolean}
     */
    @api
    get showNotDispatchedCustomNotifications() {
        return this.allowCustomNotifications && this.allowNotDispatchedCustomNotifications;
    }
    /**
     * https://accel-entertainment.monday.com/boards/286657232/pulses/314982925
     *
     * @returns {boolean}
     */
    @api
    get forceCloseFilterMenu() {
        return this._forceCloseFilterMenu;
    }
    set forceCloseFilterMenu(forceIt) {
        this._forceCloseFilterMenu = forceIt;
    }
    /**
     *
     * @returns {string}
     */
    @api
    get filterIconClass() {
        let iconClass = '';
        if(this.highlightFilter) {
            iconClass = 'accel-filter-icon-highlighted';
        }
        return iconClass;
    }
    /**
     *
     * @returns {boolean}
     */
    @api
    get highlightFilter() {
        let bDoIt = false;
        //  Check if any menu item is unchecked.
        let o = this.menuFilterItems.find(x => !x.checked); //  undefined if it doesn't find anything.
        if(o) {
            bDoIt = true;
        }
        return bDoIt;
    }
    /**
     * Getter informs the ui if any service alerts are being displayed.
     * @returns {number}
     */
    @api
    get isAnyDisplayedSvcAlerts() {
        return (this.displayedSvcAlert && this.displayedSvcAlert.length > 0);
    }
    /**
     * Getter that wraps the number of service alerts.
     * @returns {number}
     */
    @api
    get numAlerts() {
        return (this.svcAlert && this.svcAlert.length > 0) ?this.svcAlert.length : 0;
    }
    /**
     * Getter for Boolean on whether we show Observe Data for debugging...
     *
     * @returns {*|string|string|boolean|Array}
     */
    @api
    get showObserveData() {
        return (this._userProfile && this._userProfile.Name
            && ( this._userProfile.Name.includes('System Administrator')
                || this._userProfile.Name.includes( 'SA Clone') )
            && this.svcObserve && this.svcObserve.length > 0);
    }

    @api
    get showSchedulerData() {
        return (this._user && this._user.Username
            && ( this._user.Username.includes('rick@chicago')
                || this._user.Username.includes( 'jeffn@accel') )
            && this.schedulerData && this.schedulerData.length > 0);
    }
    /**
     *
     * @returns {Array|boolean}
     */
    @api
    get showAlertSendUnacceptedButton() {
        return ( this.svcAlert && this.svcAlert.length > 0 && !this.isRunningFlow);
    }
    /**
     *
     * @returns {Array|boolean}
     */
    @api
    get showAlerts() {
        return ( this.svcAlert && this.svcAlert.length > 0 );
    }
    /**
     *
     * @returns {boolean}
     */
    @api
    get showFilterPicklist() {
        return this.isAnyDisplayedSvcAlerts && this.displayedSvcAlert.length > 1;
    }

    /**
     *
     * @param ary
     * @param classifier
     * @returns {*}
     */
    count(ary, classifier) {
        classifier = classifier || String;
        return ary.reduce(function (counter, item) {
            let p = classifier(item);
            counter[p] = counter.hasOwnProperty(p) ? counter[p] + 1 : 1;
            return counter;
        }, {})
    }

    /**
     *
     * @param alertArr
     * @returns {*}
     */
    countAlertsByNotificationReason (alertArr) {
        let countObj;
        countObj = this.count(alertArr, function (item) {
            return item.notificationReason;
        });
        return countObj;
    };
    /**
     * Not used yet .. for future enhancments.
     *
     * @param field
     * @param reverse
     * @param primer
     * @returns {function(*=, *=): number}
     */
    sort_by = function(field, reverse, primer){
        let key = function (x) {return primer ? primer(x[field]) : x[field]};

        return function (a,b) {
            let A = key(a), B = key(b);
            return ( (A < B) ? -1 : ((A > B) ? 1 : 0) ) * [-1,1][+!!reverse];
        }
    };

    /**
     *
     * @param array
     * @param attrs
     * @returns {*}
     */
    sortByAttribute(array, ...attrs) {
        // generate an array of predicate-objects contains
        // property getter, and descending indicator
        let predicates = attrs.map(pred => {
            let descending = pred.charAt(0) === '-' ? -1 : 1;
            pred = pred.replace(/^-/, '');
            return {
                getter: o => o[pred],
                descend: descending
            };
        });
        return array.map(item => {
            return {
                src: item,
                compareValues: predicates.map(predicate => predicate.getter(item))
            };
        }).sort((o1, o2) => {
                let i = -1, result = 0;
                while (++i < predicates.length) {
                    if (o1.compareValues[i] < o2.compareValues[i]) result = -1;
                    if (o1.compareValues[i] > o2.compareValues[i]) result = 1;
                    if (result *= predicates[i].descend) break;
                }
                return result;
            })
            .map(item => item.src);
    }
    /**
     * Opens the utility bar popup.
     * @param wraps
     * @TODO deprecate wraps.
     */
    openUtility(wraps) {
        this.log(' firing showcases evt ');
        const openUtilityEvent = new CustomEvent('openutility', {detail: {wraps}});
        this.dispatchEvent(openUtilityEvent);
    }
    /**
     * Highlights the utility bar item.
     * @param highlightIt  If True, highlight it, otherwise unhighlight it if necessary.
     */
    setUtilityHighlighted(highlightIt) {
        const highlightUtilityEvent = new CustomEvent('highlightutility', {detail: {highlightIt}});
        this.dispatchEvent(highlightUtilityEvent);
        this.log(' firing highlight detail:' + highlightIt);
    }
    /**
     * Sets the label of the utility bar item.
     * @param utilityLabel
     */
    setUtilityLabel(utilityLabel) {
        const  setNbrOfAlertsEvent = new CustomEvent('setnbrofalerts', {detail: {utilityLabel}});
        this.dispatchEvent(setNbrOfAlertsEvent);
    }
    /**
     * Clears all watcher data so things play nicely and sets alerts to zero as well as un-highlights the utility bar.
     */
    clearAllWatcherData() {
        this.svcAlert                           = [];
        this.displayedSvcAlert                  = [];
        this.svcObserve                         = [];
        let highlightIt                         = false;
        let utilityLabel                        = 'Service Alerts (0)';
        const highlightUtilityEvent             = new CustomEvent('highlightutility', {detail: {highlightIt}});
        this.dispatchEvent(highlightUtilityEvent);
        const  setNbrOfAlertsEvent = new CustomEvent('setnbrofalerts', {detail: {utilityLabel}});
        this.dispatchEvent(setNbrOfAlertsEvent);
    }
    /**
     * Fired on the reception of a platform event.
     */
    retrieveCasesMissingAssignedResourcesOnPlatformEvent() {
        this.log('manually calling refreshApex with wiredArDto');
        refreshApex( this.wiredArDto );
        refreshApex( this.wiredSchedulingDto );
    }

    /**
     *
     * @param s  the amount of second to reformat.
     * @returns {string} in the form of M SS
     */
    fmtMSS(s){
        return(s-(s%=60))/60+(9<s?':':':0')+s
    }
    fmtHHMMSS(s) {
        var sec_num = parseInt(s, 10); // don't forget the second param
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num - (hours * 3600)) / 60);
        var seconds = sec_num - (hours * 3600) - (minutes * 60);

        // if (hours   < 10) {hours   = "0"+hours;}
        // if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}

        if(hours > 0 ) {
            if (minutes < 10) {minutes = "0"+minutes;}
            hours = hours+':';
        }
        let ret = hours + minutes + ':'+seconds;
        return ret;
    }
    /*
     * @param clonedArr - an array that has been deep cloned from anything reactive.
     * @returns {Array} - a fresh new array with incremented times.
     */
    calcDuration(clonedArr,watchType){
        let newArr = [];
        let incrementSeconds =this.svcUtilityBarSettingMdt.Client_Side_Eval_Increment_Seconds__c;
        if(clonedArr.length > 0) {
            for(let i=0; i<clonedArr.length; i++) {
                let oTmp = {};
                oTmp = Object.assign(oTmp, clonedArr[i]);
                oTmp.caseAgeSeconds += incrementSeconds;
                oTmp.caseAgeMinutes = oTmp.caseAgeSeconds / 60;
                //oTmp.caseFormatedMSS = this.fmtMSS(oTmp.caseAgeSeconds); //dynamically add property
                oTmp.caseFormatedMSS = this.fmtHHMMSS(oTmp.caseAgeSeconds);



                if('Unaccepted / Not Dispatched' === oTmp.notificationReason) { //@TODO Custom label
                    if(oTmp.servicePendingAcceptanceTimeMins) {
                        // @TODO int check?
                        oTmp.servicePendingAcceptanceTimeSecs += incrementSeconds;
                        oTmp.servicePendingAcceptanceTimeMins = oTmp.servicePendingAcceptanceTimeSecs / 60;
                        oTmp.servicePendingAcceptanceTimeFormatedMSS = this.fmtHHMMSS(oTmp.servicePendingAcceptanceTimeSecs);
                    }
                }
                if(watchType === WATCH_TYPE_ALERT) {
                    oTmp.timeDisplayClass = 'accel-danger-text';
                } else if (watchType === WATCH_TYPE_OBSERVE) {
                    oTmp.timeDisplayClass = 'accel-success-text';
                }
                newArr[i] = oTmp;
            }
        }
        return newArr;
    }

    /**
     * Backup for when PE long polling isnt working
     */
    startWatchdogTimerBackup() {
        let _self = this;
        let backupIncrement = 5000;
        this._backupTimeIntervalInstance = setInterval(function() {
            // if (newSvcObserves.some(e => e.caseAgeSeconds === maxSeconds || e.servicePendingAcceptanceTimeSecs === maxSeconds)) {
            //     //  We have hit the max threshold ie 5 minutes. clear the interval / cause a refreshApex()
            //     //  which will start a new interval.
            //     clearInterval(_self._timeIntervalInstance);
            //     _self._timeIntervalInstance = null;
                _self.retrieveCasesMissingAssignedResourcesOnPlatformEvent();
          //  }
        }, backupIncrement);
    }
    /**
     *  Fire a js interval (every second or whatever the custom metadata says). this will essentially deep clone
     *  the current public array so that it can mutate it's props. and then set the public (ie watched) array
     *  with a new array.
     */
    startWatchDogTimer() {
        let _self = this;
        let incrementSeconds = this.svcUtilityBarSettingMdt.Client_Side_Eval_Increment_Seconds__c;
        let incrementMilliseconds = incrementSeconds * 1000;
        this.log('starting watchdog timer to repeat at :'+incrementSeconds + ' seconds');
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item);

        this._timeIntervalInstance = setInterval(function() {
            //let tmpSvcAlertClone        = clone(_self.svcAlert);
            let tmpSvcAlertClone        = clone(_self.displayedSvcAlert);
            let tmpSvcObserveClone      = clone(_self.svcObserve);
            let newSvcAlerts            = _self.calcDuration(tmpSvcAlertClone, WATCH_TYPE_ALERT);
            let newSvcObserves          = _self.calcDuration(tmpSvcObserveClone, WATCH_TYPE_OBSERVE);

            // _self.svcAlert      = newSvcAlerts;
            _self.displayedSvcAlert = newSvcAlerts;
            _self.svcObserve    = newSvcObserves;
            let maxSeconds      = _self.svcUtilityBarSettingMdt.Max_Age_of_Cases__c * 60;
           // let maxSeconds = 30;
            //if (newSvcObserves.some(e => e.caseAgeSeconds === maxSeconds)) {
           // if (newSvcObserves.some(e => e.caseAgeSeconds >= maxSeconds || e.servicePendingAcceptanceTimeSecs >= maxSeconds)) {
            if (newSvcObserves.some(e => e.caseAgeSeconds === maxSeconds || e.servicePendingAcceptanceTimeSecs === maxSeconds)) {
                //  We have hit the max threshold ie 5 minutes. clear the interval / cause a refreshApex()
                //  which will start a new interval.
                clearInterval(_self._timeIntervalInstance);
                _self._timeIntervalInstance = null;
                _self.retrieveCasesMissingAssignedResourcesOnPlatformEvent();
            }
        }, incrementMilliseconds);
    }

    /**
     * @param title The Title of the toast.
     * @param msg   The Msg to display in the toast.
     */
    showToast(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
        });
        this.dispatchEvent(evt);
    }
    /**
     * A simple util to roll through a map and get the value of given key.
     *
     * @param mKey    The key of the map.
     * @param values  The object / array of objects associated with key of the map.
     * @returns {*}   The object / array in the map.
     */
    static getMapValue(mKey, values) {
        let retValue;
        for (let key in values) {
            if (key === mKey) {
                retValue = values[key];
                break;
            }
        }
        return retValue;
    }
    /**
     * Wraps console.log to allow for switching on and off via custom setting.
     * @param msg
     */
    log(msg) {
        if(this._svcWatchdogUtilityBarSettings && this._svcWatchdogUtilityBarSettings.Debug_Console__c) {
            console.log('accel: csvcWatchdogTimer' + ' ' + msg);
        }
    }
    /**
     * Basically no matter what happens cause a server side query to refreshed the combined observe / alert arrays.
     * @param platformEvent
     */
    evalWatchDogs( platformEvent ) {
        this.log(' in evalWatchDogs with Pe: '+JSON.stringify(platformEvent));
        try {
            let pe = platformEvent;
            let payload = pe.data.payload;
            if (payload && payload.DML_Action__c ) {
                this.log('evalWatchDogs channel: '+pe.channel);
                if(payload.DML_Action__c === 'DELETE') {
                    this.log(' we have a delete to eval!');
                    this.retrieveCasesMissingAssignedResourcesOnPlatformEvent();
                } else if (payload.DML_Action__c === 'INSERT') {
                    this.log('accel: ' + this._cName + ' we have a insert to eval!');
                    this.retrieveCasesMissingAssignedResourcesOnPlatformEvent();
                } else if (payload.DML_Action__c === 'UPDATE') {
                    this.log('accel: ' + this._cName + ' we have an update to eval!');
                    this.retrieveCasesMissingAssignedResourcesOnPlatformEvent();
                }
            }
        } catch (e) {
            console.error(e);
            console.error('accel: error in evalWatchDogs '+JSON.stringify(e));
        }
    }

    @api
    handleFlowError(event) {
        this.isRunningFlow = false;
        console.error(JSON.stringify(event));
        //------------------------------------refreshApex( this.wiredArDto );
        const evt = new ShowToastEvent({
            title: 'Notification Failed!',
            message: 'There was a problem sending the notification. Most likely a security issue! ',
            variant: 'error'
        });
        this.dispatchEvent(evt);
    }

    /**
     * Parses the outputs of the flow and fires a toast to inform the user of the results.
     * @param outputVariables - The outputs from the autolaunched flow.
     */
    @api
    handleFlowResults(outputVariables) {
        this.isRunningFlow = false;
        let userName;
        console.error(outputVariables);
        for(let i = 0; i < outputVariables.length; i++) {
            let outputVar = outputVariables[i];
            if(outputVar.name === 'varOutputUserName') {
                userName = outputVar.value;
            }
        }
        //------------------------------------refreshApex( this.wiredArDto );
        const evt = new ShowToastEvent({
            title: 'Notification Sent!',
            message: 'Success in sending notification to Assigned Resource: '+userName,
            variant: 'success'
        });
        this.dispatchEvent(evt);
    }

    /**
     * Dispatch event to parent aura cmp with payload of saId and userId to fire flow.
     * @param event
     */
    handleSendSingleAlertClick(event) {
        let sendNotification = true;
        let serviceAppointmentId =  event.currentTarget.dataset.svcaptid;
        this.svcApptIdClickedForNotification = serviceAppointmentId;
        let serviceAppointmentAssignedResourceId = event.currentTarget.dataset.svcaptassignedresourceid;

        if (this.usersToBypass && this.usersToBypass.includes(serviceAppointmentAssignedResourceId)) {
            let clickedSvcAlert = this.displayedSvcAlert.find(x => x.serviceAptId === serviceAppointmentId);
            sendNotification = false;
            const evt = this.buildInvalidProfileEvent(clickedSvcAlert);
            this.dispatchEvent(evt);
        } else {
            if (this.displayedSvcAlert) {
                let clickedSvcAlert = this.displayedSvcAlert.find(x => x.serviceAptId === serviceAppointmentId);
                clickedSvcAlert.showSendingCustomNotificationSpinner = true;
                if (clickedSvcAlert && clickedSvcAlert.disableNotDispatchedNotification) {
                    if (clickedSvcAlert.disabledDueToNotification) {
                        sendNotification = false;
                        const evt = this.buildNotificationAlreadyViewedEvent(clickedSvcAlert);
                        this.dispatchEvent(evt);
                    }
                }
            }
            if (sendNotification) {
                const sendServiceAppointmentNotificationEvent = new CustomEvent('sendserviceappointmentnotification', {
                    detail: {
                        serviceAppointmentId: serviceAppointmentId,
                        assignedResourceId: serviceAppointmentAssignedResourceId
                    }
                });
                this.isRunningFlow = true;
                this.dispatchEvent(sendServiceAppointmentNotificationEvent);
            }
        }
    }
    /**
     *
     * @param clickedSvcAlert
     * @return {module:lightning/platformShowToastEvent.ShowToastEvent}
     */
    buildNotificationAlreadyViewedEvent(clickedSvcAlert) {
        let notification = clickedSvcAlert.disabledDueToNotification;
        let toastWarningMsg = 'A notification titled '+notification.Msg_Title__c;
        toastWarningMsg += '\n has already been sent to ';
        toastWarningMsg += notification.User__r.Name + ' delivered by ' + notification.CreatedBy.Name;
        if(notification.CreatedDate) {
            const options = {
                day: 'numeric', month: 'long',
                hour: 'numeric', minute: 'numeric',
                timeZoneName: 'short', timeZone: 'America/Chicago',
            };
            const dateTimeFormat = new Intl.DateTimeFormat('en-US',options);
            let dt = new Date(notification.CreatedDate);
            let formattedDt = dateTimeFormat.format(dt);
            toastWarningMsg += ' on ' + formattedDt + '.';
        }
        return new ShowToastEvent({
            title: 'Duplicate Notification Warning!',
            message: toastWarningMsg,
            variant: 'warning'
        });
    }
    // https://accel-entertainment.monday.com/boards/942883797/pulses/3101982498
    buildInvalidProfileEvent(clickedSvcAlert) {

        let toastWarningMsg = 'You may not send notifications to resources with the following profiles: '+PROFILES_TO_BYPASS;

        return new ShowToastEvent({
            title: 'Custom Notification Send Denied.',
            message: toastWarningMsg,
            variant: 'warning',
            mode: 'sticky'
        });
    }
    /**
     *
     * @param event
     */
    handleRecordClick(event){
        this.log(JSON.stringify(event.target));
        let recordId =  event.target.dataset.id;
        this.log(' recordId clicked='+recordId);
        const recordClickedEvt = new CustomEvent('recordclicked', {detail: { recordId },});
        // Fire the custom event
        this.dispatchEvent(recordClickedEvt);
    }
    /**
     *
     * @param channelName
     */
    handleSubscribe( channelName ) {
        // Callback invoked whenever a new event message is received
        var _self = this;
        this.log(' in handle subscribe..');
        const messageCallback = function (response) {
            _self.log('New message received : '+ JSON.stringify(response));
            try {
                let pe = response;
                if(pe.channel === '/event/Case_Assigned_Resource_PE__e') {
                    _self.log('case assigned resources pe='+JSON.stringify(pe));
                    _self._caseAssignedResourcesPe.push(pe);
                    _self.evalWatchDogs(pe);
                } else if (pe.channel === '/event/Service_Appointment_Rejected_PE__e')  {
                    _self.log('accel: service appointment rejected pe=' + JSON.stringify(pe));
                    _self._svcAppointmentRejectedPe.push(pe);
                    _self.evalWatchDogs(pe);
                } else if (pe.channel === '/event/Not_Dispatched_Platform_Event__e') {
                    _self.log('service appointment not dispatched pe=' + JSON.stringify(pe));
                    _self._svcAppointmentNotDispatchedPe.push(pe);
                    _self.evalWatchDogs(pe);
                } else if (pe.channel === '/event/Case_Closed_PE__e') {
                    _self.log('accel: case closed pe=' + JSON.stringify(pe));
                    _self._caseClosedPe.push(pe);
                    _self.evalWatchDogs(pe);
                } else if (pe.channel === '/event/Service_Appointment_Status_Change_PE__e') {
                    _self.log('accel: service appointment status change pe=' + JSON.stringify(pe));
                    _self._svcAppointmentStatusChangePe.push(pe);
                    _self.evalWatchDogs(pe);
                } else {
                    _self.log('accel: invalid channel pe='+JSON.stringify(pe.channel));
                }
            } catch (e) {
                console.log('accel: error 1');
                console.error(e);
            }
        };
        this.log(' attempting subscribe to channel ' + channelName);
        subscribe(channelName, -1, messageCallback).then(response => {
            _self.log('Successfully subscribed to : ', JSON.stringify(response.channel));
            this._allSubscriptions.push(response);
        });
    }

    /**
     * Called on disconnected callback. Unsubscribes from Platform Event.
     */
    handleUnsubscribeAll() {
        try {
            if (this._allSubscriptions && this._allSubscriptions.length > 0) {
                for (let i = 0; i < this._allSubscriptions.length; i++) {
                    let sub = this._allSubscriptions[i];
                    unsubscribe(sub, response => {
                        this.log('unsubscribe() response: ', JSON.stringify(response));
                    });
                }
            }
        } catch (e) {
            console.error(JSON.stringify(e));
        }
    }
    buildFakeOverridesCss() {
        const style = document.createElement('style');
        style.innerText = '.toastMessage.forceActionsText{ white-space : pre-line !important;} ';
        let target = this.template.querySelector('.fake-overrides-class');
        target.appendChild(style);
    }
    /**
     * @TODO not really sure what this does yet.. / when to call it. research!
     */
    registerErrorListener() {
        // Invoke onError empApi method
        onError(error => {
            //alert('registerError');
            console.error('accel: Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    /**
     * For a future enhancement. ie.. Set the menu filter labels with count's from each applicable
     * ServiceAppointment Status.
     */
    setFilterMenuLabels() {
        this.log('setFilterMenuLabels:'+JSON.stringify(this._notificationCounts));
        let obj = this._notificationCounts;
        if(obj) {
            // Object.keys(obj).forEach(e =>
            //     this.log('key=', e, 'value=', obj[e])
            // );
        }
    }
}