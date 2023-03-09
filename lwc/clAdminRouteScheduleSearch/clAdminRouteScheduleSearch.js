import {LightningElement, api, wire, track} from 'lwc';
import mainTemplate from './clAdminRouteScheduleSearch.html';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {refreshApex} from "@salesforce/apex";
import {reduceErrors} from 'c/ldsUtils';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {themeOverrider} from 'c/clAdminOnlyCardTheme';
import retrieveRouteSchedules from '@salesforce/apex/clAdminUtilsController.retrieveRouteSchedules';
import {subscribe, unsubscribe,publish, APPLICATION_SCOPE, MessageContext} from 'lightning/messageService';
import clAdminUtilsMsgChannel from '@salesforce/messageChannel/CashLogiticsUtilsMessageChannel__c';
import {CurrentPageReference} from "lightning/navigation";

const columns = [{
    label: 'Route Schedule Name',
    fieldName: 'rsLink',
    type: 'url',
    hideDefaultActions: true,
    typeAttributes: {label: { fieldName: 'name' }, target: '_parent'},
    sortable: true
},
    {
        label: 'Collection Dt',
        fieldName: 'rsCollectionDate',
        type: 'date',
        hideDefaultActions: true,
        typeAttributes:{
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
        },
        sortable:true
    },
    {
        label: 'Fill Dt',
        fieldName: 'rsFillDate',
        type: 'date',
        hideDefaultActions: true,
        typeAttributes:{
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
        },
        sortable:true
    },
    {
        label: '# Accts',
        fieldName: 'totalAccounts',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: '# RPS',
        fieldName: 'totalRps',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: '# MRs',
        fieldName: 'totalMeterReadings',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: 'Last Modified',
        fieldName: 'rsLastModifiedDate',
        type: 'date',
        hideDefaultActions: true,
        typeAttributes:{
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit"
        },
        sortable:true
    }
];
const  MIN_CARD_HEIGHT = '33em';

export default class ClAdminRouteScheduleSearch extends LightningElement {

    @track value;
    @track error;
    @track page = 1;
    @track items = [];
    @track data = [];
    @track columns;
    @track startingRecord = 1;
    @track endingRecord = 0;
    @track pageSize = 10;
    @track totalRecountCount = 0;
    @track totalPage = 0;

    @api sortedDirection = 'asc';
    @api sortedBy = 'Name';
    @api searchKey = '';
    @api collectionDate = null;

    result;

    _minCardHeight = MIN_CARD_HEIGHT;
    _wiredRoutes;
    _wiredRouteSchedules;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _rowLimit = 20;
    _subscription = null;

    constructor() {
        super();
    }

    render() {
        return mainTemplate;
    }
    connectedCallback() {
        this._isLoading = true;
        this.subscribeToMessageChannel();
    }
    disconnectedCallback() {
        this.unsubscribeToMessageChannel();
    }
    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            themeOverrider.buildAdminCardOverrideCss(this);
        }
    }
    @wire(CurrentPageReference)
    pageRef;

    @wire(MessageContext)
    messageContext;

    @wire(retrieveRouteSchedules, {searchKey: '$searchKey',collectionDate : '$collectionDate',  iLimit : '$_rowLimit'})
    wiredRouteSchedules(wiredData) {
        this._wiredRouteSchedules = wiredData;
        const { data, error } = wiredData;
        if (data) {
            console.log('---> data=',JSON.stringify(data));
            this.items = data.map(row=>{return{...row, rsLink: '/' + row.rsId, name:row.rsName}});
            this.totalRecountCount = data.length;
            this.totalPage = Math.ceil(this.totalRecountCount / this.pageSize);
            this.data = this.items.slice(0,this.pageSize);
            this.endingRecord = this.pageSize;
            this.columns = columns;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.data = undefined;
            console.error(error);
        }
    }
    handleMessage(message) {
       console.log('message recieved:'+JSON.stringify(message));
        this._cacheBust = Math.random();
        refreshApex(this._wiredRouteSchedules);
    }
    previousHandler() {
        if (this.page > 1) {
            this.page = this.page - 1; //decrease page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    nextHandler() {
        if((this.page<this.totalPage) && this.page !== this.totalPage){
            this.page = this.page + 1; //increase page by 1
            this.displayRecordPerPage(this.page);
        }
    }

    displayRecordPerPage(page){
        this.startingRecord = ((page -1) * this.pageSize) ;
        this.endingRecord = (this.pageSize * page);
        this.endingRecord = (this.endingRecord > this.totalRecountCount)
            ? this.totalRecountCount : this.endingRecord;
        this.data = this.items.slice(this.startingRecord, this.endingRecord);
        this.startingRecord = this.startingRecord + 1;
    }

    sortColumns( event ) {
        // this.sortedBy = event.detail.fieldName;
        // this.sortedDirection = event.detail.sortDirection;
        // return refreshApex(this.result);
    }

    handleKeyChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.result);
    }

    get cardTitleStyle() {
        return themeOverrider.getCardTitleStyle(this);
    }

    handleDatatableSort(event) {
        let fieldName = event.detail.fieldName;
        let sortDirection = event.detail.sortDirection;
        this.sortedBy = fieldName;
        this.sortedDirection = sortDirection;
        this.state.records = this.sortData(this.state.records,fieldName, sortDirection);
    }
    sortData(data, fieldname, direction) {
        // serialize the data before calling sort function
        //  @todo this is slow on large results use a spread or deep copy instead..
        let parseData = JSON.parse(JSON.stringify(data));

        // Return the value stored in the field
        let keyValue = (a) => { return a[fieldname];};
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';
            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });
        // set the sorted data to data table data
        return parseData;
    }

    subscribeToMessageChannel() {
        if (!this._subscription) {
            this._subscription = subscribe(
                this.messageContext,
                clAdminUtilsMsgChannel,
                (message) => this.handleMessage(message),
                { scope: APPLICATION_SCOPE }
            );
        }
    }

    unsubscribeToMessageChannel() {
        unsubscribe(this._subscription);
        this._subscription = null;
    }
}