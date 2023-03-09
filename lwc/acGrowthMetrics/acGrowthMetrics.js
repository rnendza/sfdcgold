import {LightningElement, track, api, wire} from 'lwc';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import retrieveRevComparisonData   from '@salesforce/apex/AcGrowthMetricsController.retrieveRevComparisonData';
import retrieveCommunityUserSettings  from '@salesforce/apex/AcGrowthMetricsController.retrieveCommunityUserSettings';
import searchFormHelp from '@salesforce/label/c.Community_Help_Growth_Metrics_Search_Form';
import locShareChartHelp from '@salesforce/label/c.Community_Help_Growth_Metrics_Loc_Share_Chart';
import growthMetricsDatatableHelp from '@salesforce/label/c.Community_Help_Growth_Metrics_Datatable';
import {reduceErrors} from 'c/ldsUtils';
import {refreshApex} from '@salesforce/apex';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';

const   MAP_KEY_HPD_WRAPPER_MONTHS           =      'HPD_WRAPPER_MONTHS';
const   MAP_KEY_DEFAULT_DATE_SUGGESTIONS     =      'DEFAULT_DATE_SUGGESTIONS';
const   MAP_KEY_HPD_COMPARE_DATA             =      'HPD_COMPARE_DATA';
const   MAP_KEY_COMMUNITY_SETTINGS           =      'CONTACT_CONTROLLED_COMMUNITY_SETTINGS';
/**
 * This is the ultimate parent component for displaying revenue. comparison growth metrics.
 * It's responsibility is to query for data and pass that data via attributes to child components
 * if needed. It's also responsible for handling child component events and re-firing the wired server query.
 *
 * General Arch  (Subject to refactor / rename ie. it's hard to name this stuff when your not sure what it is when you start it)
 *
 * AcGrowthMetrics (Parent)
 *    - AcLocTypePl (Child) - merely a ui combobox
 *    - AcStartDateEndDate (Child) - contains both start month and end month combo boxes.
 *    - AcGrowthChartLocRevenue (Child) - big boy building chart options and instantiating eCharts.
 *    - Ac
 */
export default class AcGrowthMetrics extends LightningElement {

    //---- private stuff
    _debugConsole = true; //@TODO passed in property / custom meta.
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _className = 'AcGrowthMetrics';
    _showHelpIcons = true; //@TODO passed in property / custom meta

    label = {
        searchFormHelp,locShareChartHelp,growthMetricsDatatableHelp
    };
    @track  dataLoaded      = false;   //  Used by this components spinners so we can render ASAP before chart renders.
    @track  displayNothing = false;
    @track error;

    @track  wiredMonthlyHpdDatesDto;
    @track  wiredCommunityUserSettingsDto;

    @api    hpdCompareData;     //  Main HpdWrapper Data passed down to chart and table.
    @api    hpdDates;           //  All Dates for HPD Date data
    @api    dateSuggestions;    //  Default dates when page loads.
    @api    selectedLocType;    //  Passed down to child cmps.
    @api    startMonth;
    @api    endMonth;
    @api    communityUserSettings= {};
    @api    customSecurityOverride = false;

    @api
    get displaySearchFormHelp() {
        return this.label.searchFormHelp && this.label.searchFormHelp !== 'none';
    }
    @api
    get displayLocShareChartHelp() {
        return this.label.locShareChartHelp && this.label.locShareChartHelp !== 'none';
    }
    @api
    get displayMetricsDatatableHelp() {
        return this.label.growthMetricsDatatableHelp && this.label.growthMetricsDatatableHelp !== 'none';
    }
    /**
     * Class constructor. Config the datatable columns array to pass to the child cmp.
     */
    constructor() {
        super();
        this._accelUtils.logDebug(this._className + ' --- constructor ---');
        this.startMonth = null;
        this.endMonth = null;
        this.selectedLocType = 'All';
        // let o = {Display_Location_Growth_Chart__c : true, Display_Location_Growth_Datatable__c : true};
        // this.communityUserSettings = o;
    }
    /**
     *
     */
    connectedCallback() {
        this._accelUtils.logDebug(this._className+ ' --- connectedCallback calling refreshApex on settings ---');
        if(!this.customSecurityOverride) {
            refreshApex(this.wiredCommunityUserSettingsDto);
        } else {
            let o = {Display_Location_Growth_Chart__c : true, Display_Location_Growth_Datatable__c : true};
            this.communityUserSettings = o;
        }
    }
    /**
     * Defeat the evil SFDC Shadow DOM / CSS Isolation! But only do it once.
     */
    renderedCallback() {
        if (this.hasRendered) return;
        this._accelUtils.logDebug(this._className+ ' --- renderedCallback ---');
        this.hasRendered = true;
        if(this.customSecurityOverride) {
            let o = {Display_Location_Growth_Chart__c : true, Display_Location_Growth_Datatable__c : true};
            this.communityUserSettings = o;
        }
        this.buildOverrideCss();
    }
    /**
     *
     * @param wiredCommunityUserSettingsDto
     */
    @wire(retrieveCommunityUserSettings)
    wiredCommunityUserSettingsData(wiredCommunityUserSettingsDto) {
        this._accelUtils.logDebug(this._className +' start of wired call for community user settings');
        this.wiredCommunityUserSettingsDto = wiredCommunityUserSettingsDto;
        const { data, error } = this.wiredCommunityUserSettingsDto;
       // error = 'blah u suck';
        if(data) {
            this._accelUtils.logDebug(this._className+ 'in wired call for community user settings we have server data returned..');
           let tmp = this._accelUtils.getMapValue(MAP_KEY_COMMUNITY_SETTINGS,data.values);
           if(tmp) {
               this.communityUserSettings = tmp;
           }
            if(this.communityUserSettings) {
                this.displayNothing = !this.communityUserSettings.Display_Location_Growth_Chart__c
                    && !this.communityUserSettings.Display_Location_Growth_Datatable__c;
            }
            this._accelUtils.logInfo('communityUserSettings',JSON.stringify(this.communityUserSettings));
        } else if (error) {
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving custom settings data: '+this.error,'error');
            this._accelUtils.logError(this._className,this.error);
        } else {
            this._accelUtils.logDebug(this._className +' wired no data yet ');
        }
    }
    /**
     *
     * @param wiredMonthlyHpdDatesDto
     */
    @wire(retrieveRevComparisonData, {locType: '$selectedLocType', startMonth: '$startMonth', endMonth: '$endMonth' } )
    wiredMonthlyHpdDatesData(wiredMonthlyHpdDatesDto) {
        this._accelUtils.logDebug(this._className +' after wired call startMonth=',this.startMonth);
        this.wiredMonthlyHpdDatesDto = wiredMonthlyHpdDatesDto;
        const { data, error } = wiredMonthlyHpdDatesDto;
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item); // magic deep clone!
        if(data) {
            this._accelUtils.logDebug(this._className+ 'in wired call we have server data returned..');
            try {
                //this.hpdDates = this.fixHpdDates(clone(this._accelUtils.getMapValue(MAP_KEY_HPD_WRAPPER_MONTHS, data.values)));
                this.hpdDates = clone(this._accelUtils.getMapValue(MAP_KEY_HPD_WRAPPER_MONTHS, data.values));
                this.dateSuggestions = this._accelUtils.getMapValue(MAP_KEY_DEFAULT_DATE_SUGGESTIONS, data.values);
                let hpdWrappers = this._accelUtils.getMapValue(MAP_KEY_HPD_COMPARE_DATA, data.values);
                this._accelUtils.logDebug(this._className, 'setting hpdComparedDAta in parent obj');
                this.hpdCompareData = this._accelUtils.reshapeHpdCompareData(hpdWrappers);
                this.dataLoaded = true;
                this.setDefaultReactiveDates();
            } catch (e) {
                console.error(e);
                this.dataLoaded = true;
            }
        } else if (error) {
            this.error = reduceErrors(error);
            this.showToast('','Problem retrieving location growth data: '+this.error,'error');
            this._accelUtils.logError(this._className,this.error);
        } else {
            this._accelUtils.logDebug(this._className +' wired no data yet ');
        }
    }
    /**
     * Handle event passed up from child cmp when user selects a loc type.  set reactive prop which fires query.
     * @param event - object detail contains the selected start date.
     */
    selectedLocTypeHandler(event) {
        const selectedLocType = event.detail;
        this._accelUtils.logInfo(this._className +' selected log type',selectedLocType);
        this.selectedLocType = selectedLocType;
    }
    /**
     * Handle event passed up from child cmp when user selects a start date. set reactive prop which fires query.
     * @param event - object detail contains the selected start date.
     */
    selectedStartDateHandler(event) {
        const selectedStartDate = event.detail;
        this._accelUtils.logInfo(this._className +' selected start date..',selectedStartDate);
        this.startMonth = selectedStartDate;
    }
    /**
     * Handle event passed up from child cmp when user selects a start date. set reactive prop which fires query.
     * @param event  - object detail contains the selected end date.
     */
    selectedEndDateHandler(event) {
        const selectedEndDate = event.detail;
        this._accelUtils.logInfo(this._className +' selected end date..',selectedEndDate);
        this.endMonth = selectedEndDate;
    }
    /**
     * Gets around LWC shadow DOM limitations. We are trying to override the theme here in the case of smaller devices
     * as we don't need so much padding on the left and right borders. also bold the text on the selected tab
     * @media only screen and (max-width: 896px)
     <style>
     .cAccel_CommunityServiceMobileThemeLayout .accel-content
     */
    buildOverrideCss() {
        const mobile = this._accelUtils.MOBILE_FORM_WIDTH;
        let css = '@media only screen and (max-width: '+mobile+'px) {';
        css+='.cAccel_CommunityServiceMobileThemeLayout .accel-content {';
        css+='padding:0px 8px 0px 4px!important} ';
        css+='.slds-col_padded, .slds-col--padded{padding-left:0px;padding-right:0px;padding-top:5px}';
        css+='.siteforceContentArea .comm-layout-column:not(:empty) {padding-top: 10px }}';

        const style = document.createElement('style');
        style.innerText = css;
        let target = this.template.querySelector('.fake-theme-overrides-class');
        target.appendChild(style);
    }
    /**
     *
     */
    setDefaultReactiveDates() {
        if(this.dateSuggestions) {
            if (!this.startMonth) {
                this.startMonth = this.dateSuggestions.suggestedDefaultMonthlyStartDate;
            }
            if (!this.endMonth) {
                this.endMonth = this.dateSuggestions.suggestedDefaultMonthlyEndDate;
            }
        }
    }
    /**
     * @param title The Title of the toast.
     * @param msg   The Msg to display in the toast.
     * @variant [warning,error,success]
     * @TODO move to utils
     */
    showToast(title, msg, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
            variant: variant
        });
        this.dispatchEvent(evt);
    }
}