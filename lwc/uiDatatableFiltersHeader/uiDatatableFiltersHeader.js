import {LightningElement,api} from 'lwc';

export default class UiDatatableFiltersHeader extends LightningElement {

    @api showFiltersActions;
    @api showTableTotalRows;                    //  ie. show '5 rows found'
    @api dtEntityLabel;                         //  5 'Cases'.. 10 'Opportunities' etc.
    @api refreshedLabel = 'Refreshed';          //  i.e 'Refreshed'
    @api totalNumberOfResults;
    @api filteredNumberOfResults;
    @api dtRefreshTime;
    @api clientSideFiltersIconTooltip;
    @api numberOfFiltersApplied = 0;

    _displayFilters;


    handleRefresh(evt) {
        const payload = {}; //  for future use
        const customEvt = new CustomEvent('refresh', { bubbles : true, detail: payload, composed : true });
        this.dispatchEvent(customEvt);
    }

    /**
     * Handle the server side search or client side filters button click.
     * @param evt
     */
    handleIconButtonClick(evt) {
        const buttonId = evt.currentTarget.dataset.iconbuttonid;
        switch (buttonId) {
            case 'btnDisplaySearch':
                this._displayServerSideSearch = !this._displayServerSideSearch;
                break;
            case 'btnDisplayFilters':
                this._displayFilters = !this._displayFilters;
                const payload = {displayIt:this._displayFilters};
                const customEvt = new CustomEvent('filtersiconclick', { bubbles : true, detail: payload, composed : true });
                this.dispatchEvent(customEvt);
                break;
        }
    }

    get showNumberOfFiltersApplied() {
        return this.numberOfFiltersApplied && this.numberOfFiltersApplied > 0;
    }

    // get clientSideFiltersIconTooltip() {
    //     return this._displayFilters ? 'Hide datatable filters' : 'Display datatable filters';
    // }
}