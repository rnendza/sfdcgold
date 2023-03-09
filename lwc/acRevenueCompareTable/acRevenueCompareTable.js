import {LightningElement,track,api} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import accelLwcStyles from '@salesforce/resourceUrl/lwc_styles';
import { loadStyle } from 'lightning/platformResourceLoader';

/**
 *
 */
export default class AcRevenueCompareTable extends LightningElement {
    @track tableData;
    @track tableColumns;
    @api tableColumnLabelMap;
    @api columns;
    @api month1;
    @api month2;
    month1Display = 'Month 1';
    month2Display = 'Month 2';
    @track showBigDatatable = false;
    @track showSmallDatatable = false;
    @track sortBy;
    @track sortDirection;
    @track headerIconSize = 'small';

    _debugConsole                       = true; //@TODO passed in property / custom meta.
    _accelUtils                         = new AccelUtilsSvc(this._debugConsole);
    _className                          = 'AcRevenueCompareTable';
    _hpdCompareData;
    _exportToCsvColumns;

    /**
     *
     */
    constructor() {
        super();
        this._accelUtils.logDebug(this._className+ ' --- constructor ---');
    }
    /**
     *
     */
    connectedCallback() {
        this._accelUtils.logDebug(this._className+ ' --- connectedCallback ---');
    }

    /**
     *
     */
    renderedCallback() {
        if (this.hasRendered) return;
        loadStyle(this, accelLwcStyles + '/lwc_datatable_styles.css').then( () => {
           this._accelUtils.logDebug(this._className + 'lwc_datatable_styles loaded');
        }).catch (error => {
            console.log(error);
        });
        this.hasRendered = true;
        this._accelUtils.logDebug(this._className+ ' --- renderedCallback ---');
        let templateWidth = this.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
        this.determineDatatableSize(templateWidth);
        this.determineHeaderIconSize(templateWidth);
        this.registerWindowEvents();
    }
    @api
    get hpdCompareData() {
        return this._hpdCompareData;
    }
    set hpdCompareData(hpdCompareData) {
        const clone = (items) => items.map(item => Array.isArray(item) ? clone(item) : item); // magic deep clone!
        this.setDatatableColumns();
        this.buildColumnLabelMap();
        this._accelUtils.logDebug(this._className + '--- setHpdCompareData hpdCompareData=', hpdCompareData);
        this._hpdCompareData = hpdCompareData;
        this.tableData =  clone(hpdCompareData);


        if(this.tableData) {
            //  Sort by loc share pct change desc
            this.tableData.sort((a, b) => (a.locSharePctChange < b.locSharePctChange) ? 1 : -1);
            for(let i=0; i < this.tableData.length; i++) {
                let row = this.tableData[i];
                if(row.locSharePctChange > 0) {
                    row.showClass = 'accel-positive-number';
                } else {
                    row.showClass = 'accel-negative-number';
                }
            }
        }
        // datatable col headers
        let options = {year: 'numeric', month: 'short'};
        this.month1Display = this.formatMonthDisplay(this.month1,'Month 1',options);
        this.month2Display = this.formatMonthDisplay(this.month2, 'Month 2',options);
        this.setExportColumns();
    }
    @api
    get displayNoDataMsg() {
        let showIt = false;
        if(this.hasRendered && (!this.tableData || this.tableData.length === 0)) {
            showIt=true;
        }
        return showIt;
    }
    @api
    get tableHeader() {
        let options = {year: 'numeric', month: 'short'};
        let month1 = this.formatMonthDisplay(this.month1,'Month 1',options);
        let month2 = this.formatMonthDisplay(this.month2, 'Month 2',options);
        let size = this.tableData ? this.tableData.length : 0;
        return month1 + ' to ' + month2 + ' Details ('+size+')';
    }
    @api
    get month1FundsInLabel() {
        let options = {year: 'numeric', month: 'short'};
        let suffix = ' Funds In';
        let label = this.month1 ? this.formatMonthDisplay(this.month1,'Month 1',options) + suffix
                                : 'Month 1 ' + suffix;
        return label;
    }
    @api
    get month2FundsInLabel() {
        let options = {year: 'numeric', month: 'short'};
        let suffix = ' Funds In';
        let label = this.month2 ? this.formatMonthDisplay(this.month2,'Month 2',options) + suffix
            : 'Month 2 ' + suffix;
        return label;
    }
    @api
    get month1LocShareInLabel() {
        let options = {year: 'numeric', month: 'short'};
        let suffix = ' Loc Share';
        let label = this.month1 ? this.formatMonthDisplay(this.month1,'Month 1',options) + suffix
            : 'Month 1 ' + suffix;
        return label;
    }
    @api
    get month2LocShareInLabel() {
        let options = {year: 'numeric', month: 'short'};
        let suffix = ' Loc Share';
        let label = this.month2 ? this.formatMonthDisplay(this.month2,'Month 2',options) + suffix
            : 'Month 2 ' + suffix;
        return label;
    }
    /**
     * Takes a apex date such as '2019-07-01' .. creates a new js dhate which gives us
     * 'Sun Jun 30 2019 19:00:00 GMT-0500 (Central Daylight Time)' then appropriately converts this
     * back to 'Mon Jul 01 2019 00:00:00 GMT-0500 (Central Daylight Time)'
     *
     * @param sDate     an apex date ie. 2019-07-01
     * @returns {Date}  ie Mon Jul 01 2019 00:00:00 GMT-0500
     */
    convertApexDateToJsLocalDate(sDate) {
        let utcDate = new Date(sDate);
        return new Date(utcDate.getTime() + utcDate.getTimezoneOffset() * 60000);
    }
    /**
     *
     * @param monthDate   the reactive date value selected in the picklist.
     * @param monthChoice ie ['Month 1' or 'Month 2']
     * @returns {string} of the formatted Month ie. Jan 2019
     *
     * @TODO safety checking.
     */
    formatMonthDisplay( monthDate, monthChoice, options ) {
        let monthString = monthChoice;
        let dt = this.convertApexDateToJsLocalDate(monthDate);
        monthString = dt.toLocaleDateString('en-US', options);
        return monthString;
    }
    buildColumnLabelMap() {
        let colLabelMap = new Map();
        this.tableColumns.forEach(function(column) {
            console.log(column);
            colLabelMap.set(column.fieldName,column.label);
        });
        this.tableColumnLabelMap = colLabelMap;
    }
    handleDownload(event) {
        //this.showToast('--- debug ---','export not yet built');
        try {
            // Creating anchor element to download

            let csvString = this._accelUtils.convertDataTableToCsvString(this._hpdCompareData,this._exportToCsvColumns);
            let downloadElement = document.createElement('a');
            // This  encodeURI encodes special characters, except: , / ? : @ & = + $ # (Use encodeURIComponent() to encode these characters).
            downloadElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csvString);
            downloadElement.target = '_self';
            // CSV File Name
            downloadElement.download = 'Location Growth Comparison.csv';
            // below statement is required if you are using firefox browser
            document.body.appendChild(downloadElement);
            // click() Javascript function to download CSV file
            downloadElement.click();
        } catch (e) {
            alert(e);
        }
    }
    /**
     * Specific to lwc datatable.. set the column info.
     */
    setDatatableColumns() {
        let allowColSort = true;
        this.tableColumns = [
            {
                label: 'DBA',
                fieldName: 'dbaName',
                type: "text",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Address',
                fieldName: 'address',
                type: "text",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'City',
                fieldName: 'city',
                type: "text",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label:  this.month1FundsInLabel,
                fieldName: 'startDateFundsIn',
                type: "currency",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: this.month2FundsInLabel,
                fieldName: 'endDateFundsIn',
                type: "currency",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Funds In % Change',
                fieldName: 'fundsInPctChange',
                type: "percent",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: this.month1LocShareInLabel,
                fieldName: 'startDateLocShare',
                type: "currency",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: this.month2LocShareInLabel,
                fieldName: 'endDateLocShare',
                type: "currency",
                sortable: allowColSort,
                cellAttributes: {alignment: 'left'}
            },
            {
                label: 'Loc Share % Change',
                fieldName: 'locSharePctChange',
                type: "percent",
                sortable:allowColSort,
                cellAttributes: {alignment: 'left', class: {fieldName: 'showClass'} }
            },
        ];
    }

    /**
     * Set csv columns that we want to export (limit hpdcompare) data and only export chosen props on that object.
     * Also set dynamic headers.
     */
    setExportColumns() {
        this._exportToCsvColumns = [
            { label: 'Location', fieldName: 'dbaName'},
            { label: 'Street', fieldName: 'address'},
            { label: 'City', fieldName: 'city'},
            { label: this.month1LocShareInLabel, fieldName: 'startDateLocShare'},
            { label: this.month2LocShareInLabel, fieldName: 'endDateLocShare'},
            { label: this.month1FundsInLabel, fieldName: 'startDateFundsIn'},
            { label: this.month2FundsInLabel, fieldName: 'endDateFundsIn'},
            { label: 'Funds In % Change', fieldName: '_fundsInPctChange'},
            { label: 'Location Share % Change', fieldName: '_locSharePctChange'}
        ];
    }
    handleSortClick(event) {
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.sortData(event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(this.tableData));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        // set the sorted data to data table data
        this.tableData = parseData;
    }
    determineHeaderIconSize(templateWidth) {
        if(templateWidth > this._accelUtils.MOBILE_CHART_WIDTH) {
            this.headerIconSize = 'small';
        } else {
            this.headerIconSize = 'x-small';
        }
    }
    /**
     *
     * @param templateWidth
     */
    determineDatatableSize(templateWidth) {
        if(templateWidth > this._accelUtils.DESKTOP_DATATABLE_WIDTH) {
            this.showBigDatatable = true;
            this.showSmallDatatable = false;
        } else {
            this.showBigDatatable = false;
            this.showSmallDatatable = true;
        }
    }
    /**
     *
     */
    registerWindowEvents() {
        let self = this;
        window.addEventListener('resize', function() {
            let templateWidth = self.template.querySelector('[data-id="widthMeasurement"]').getBoundingClientRect().width;
            self.determineDatatableSize(templateWidth);
            self.determineHeaderIconSize(templateWidth);
        });
    }
    /**
     * @param title The Title of the toast.
     * @param msg   The Msg to display in the toast.
     * @TODO move to utils
     */
    showToast(title, msg) {
        const evt = new ShowToastEvent({
            title: title,
            message: msg,
        });
        this.dispatchEvent(evt);
    }
}