import {LightningElement,api} from 'lwc';

export default class PortalAdminUtilsContainer extends LightningElement {

    @api paAdvisoryCustomMdtDevName;
    @api paDebugConsole;
    @api paAdvisoryCreatedRecordsListViewFilterName = '';
    @api paGalleryAllowFilters;
    @api paGalleryUseInfiniteScroll;
    @api paGalleryCardTitle;
    @api paGalleryCardIcon = 'custom:custom86';
    @api paGalleryInfiniteScrollMaxImageItems = 30;
    @api paGalleryInfiniteScrollMaxTableItems = 30;
    @api paGalleryScrollContainerStyle = '';
    @api paGalleryAllowMouseOverHighlight;
    @api paGalleryAllowListVsImageToggle;
    @api paGalleryAllowSortIcon;
    @api paGalleryTableAllowCsvExport;
    @api paGalleryShowTableRowNumColumn;
    @api paGalleryDtContainerStyle;
    @api paGalleryPhotoStyle;
    @api paGalleryPhotoCls;

    @api paGalleryFiltersUserPlaceHolder = 'Enter name...';
    @api paGalleryFiltersCityPlaceHolder = 'Enter city...';
    @api paGalleryFiltersFiltersLabel = 'Filters';
    @api paGalleryFiltersFiltersAppliedLabel = 'Filters Applied';
    @api paGalleryFiltersMinFilterChars = 2;
    @api paGalleryExportStatusLabel = 'Creating your csv export (All Items) ........';

    _activeTabValue = 'tab_utils_home';

    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }
}