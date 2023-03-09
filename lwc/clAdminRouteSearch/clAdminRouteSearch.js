import {LightningElement, api, wire, track} from 'lwc';
// import stencil from './clAdminRouteCloneStencil.html';
import mainTemplate from './clAdminRouteSearch.html';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import cloneRoute from '@salesforce/apex/clRouteSchAdminOnly.cloneRoute';
import retrieveRouteData from '@salesforce/apex/clRouteSchAdminOnly.retrieveRoutes';
import {refreshApex} from "@salesforce/apex";
import {reduceErrors} from 'c/ldsUtils';
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {themeOverrider} from 'c/clAdminOnlyCardTheme';
import retrieveRoutes from '@salesforce/apex/clAdminUtilsController.retrieveRoutes';

import {NavigationMixin} from "lightning/navigation";
// import {animationHelper} from "../clMeterReadings/clMeterReadingsAnimation";

const  MAP_KEY_ROUTES = 'ROUTE_DATA';
const  MAP_KEY_ROUTE = 'ROUTE';
const  RESULT_MSG_TEXT_DISPLAY_TIME = 10000;
const  MIN_CARD_HEIGHT = '33em';

const columns = [{
    label: 'Route Name',
    fieldName: 'routeLink',
    type: 'url',
    hideDefaultActions: true,
    typeAttributes: {label: { fieldName: 'name' }, target: '_parent'},
    sortable: true
    },
    {
        label: 'Fill Cycle #',
        fieldName: 'Cycle_Number__c',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: 'Col Cycle #',
        fieldName: 'Collection_Cycle_Number__c',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: 'Next Fill Dt',
        fieldName: 'Next_Fill_Date__c',
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
        label: 'Next Col Dt',
        fieldName: 'Next_Collection_Date__c',
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
        fieldName: 'Total_Accounts__c',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: 'Proc. Loc',
        fieldName: 'Processing_Location__c',
        hideDefaultActions: true,
        sortable: true
    },
    {
        label: 'Last Modified',
        fieldName: 'LastModifiedDate',
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


export default class ClAdminRouteSearch extends LightningElement {
    @track routes;
    @track value;
    @track error;
    @track page = 1;
    @track items = [];
    @track data = [];
    @track columns;
    @track startingRecord = 1;
    @track endingRecord = 0;
    @track pageSize = 5;  
    @track totalRecountCount = 0;
    @track totalPage = 0;

    @api sortedDirection = 'asc';
    @api sortedBy = 'Cycle_Number__c';
    @api searchKey;
    @api fillCycleNumber = null;
    @api current
    result;


    _minCardHeight = MIN_CARD_HEIGHT;
    _wiredRoutes;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);
    _rowLimit = 20;

    constructor() {
        super();
    }

    render() {
        return mainTemplate;
    }
    connectedCallback() {
        this._isLoading = true;
    }

    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            themeOverrider.buildAdminCardOverrideCss(this);
        }
    }

    @wire(retrieveRoutes, { searchKey: '$searchKey', sortBy: '$sortedBy', sortDirection: '$sortedDirection',
                                    iLimit : '$_rowLimit', cycleNumber: '$fillCycleNumber'})
    wiredRoutes({ error, data }) {
        if (data) {
            console.log('---> data=',JSON.stringify(data));
            try {
                this.items = data.map(row => {
                        return {
                            ...row, routeLink: '/' + row.Id, name: row.Name
                        }
                    }
                );
            } catch (e) {
                alert(e);
            }
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
        this.sortedBy = event.detail.fieldName;
        this.sortedDirection = event.detail.sortDirection;
        return refreshApex(this.result);
    }
    handleKeyChange( event ) {
        this.searchKey = event.target.value;
        return refreshApex(this.result);
    }

    get cardTitleStyle() {
        return themeOverrider.getCardTitleStyle(this);
    }

}