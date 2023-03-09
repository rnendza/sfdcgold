import {LightningElement,api} from 'lwc';
import { getConstants } from 'c/clConstantUtil';
const GLOBAL_CONSTANTS = getConstants();

export default class AccelAdminUtilsContainer extends LightningElement {
    @api debugConsole;
    @api showAssistance;
    @api auditTrailDefaultSearchToOpen;

    @api paAdvisoryCustomMdtDevName;
    @api paDebugConsole;
    @api paAdvisoryCreatedRecordsListViewFilterName = '';
    @api paGalleryAllowFilters;
    @api paGalleryUseInfiniteScroll;
    @api paGalleryCardTitle = 'PA Advisories';
    @api paGalleryCardIcon = 'custom:custom86';
    @api paGalleryInfiniteScrollMaxImageItems = 30;
    @api paGalleryInfiniteScrollMaxTableItems = 30;
    @api scrollContainerStyle = 'max-height:700px';

    @api paGalleryScrollContainerStyle = 'max-height:700px';
    @api paGalleryAllowMouseOverHighlight;
    @api paGalleryAllowListVsImageToggle;
    @api paGalleryTableAllowCsvExport;
    @api paGalleryShowTableRowNumColumn;
    @api paGalleryDtContainerStyle;

    @api paGalleryFiltersUserPlaceHolder = 'Enter name...';
    @api paGalleryFiltersCityPlaceHolder = 'Enter city...';
    @api paGalleryFiltersFiltersLabel = 'Filters';
    @api paGalleryFiltersFiltersAppliedLabel = 'Filters Applied';
    @api paGalleryFiltersMinFilterChars = 2;
    @api paGalleryExportStatusLabel = 'Creating your csv export (All Items) ........';

    _activeTabValue = 'tab_utils_home';

    constructor() {
        super();
        console.info('%c----> /lwc/accelAdminUtilsContainer', GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this.paGalleryAllowMouseOverHighlight = true;
        this.paGalleryAllowListVsImageToggle = true;
        this.paGalleryTableAllowCsvExport = true;
        this.paGalleryAllowFilters = true;
        this.paGalleryUseInfiniteScroll = true;
    }

    connectedCallback() {
        this.debugConsole = true;
        this.showAssistance = true;
        //this.auditTrailDefaultSearchToOpen = true;
    }

    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }

    handleUtilsModuleOptionSelected(event) {
        let currentModule = event.detail.payload.moduleSelected;
        this._activeTabValue = currentModule.id;
        //alert(JSON.stringify(currentModule));

    }
}