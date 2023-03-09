import { LightningElement, track, api, wire } from 'lwc';

import { loadScript } from "lightning/platformResourceLoader";

import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import { reduceErrors } from 'c/ldsUtils';
import { getConstants } from 'c/clConstantUtil';

import retrieveLocsData   from '@salesforce/apex/clLocationReorderController.retrieveLocations';
import doUpdateStopNumbers from '@salesforce/apex/clLocationReorderController.doUpdateStopNumbers';

import SORTABLE_RESOURCE  from '@salesforce/resourceUrl/sortable';
import { uiHelper } from "./clLocationReordererUiHelper";
import Logger from 'c/logger'

import {refreshApex} from "@salesforce/apex";

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_LOCATIONS = 'MAP_KEY_LOCATIONS';
const DEFAULT_CARD_ASSISTANCE_TEXT = 'Move your stops into the desired order via long pressing any card and moving up or down.';
const DEFAULT_ALL_ZEROS_WARNING_TEXT = 'All your stops currently have no stop number. Drag any stop to initiate an auto sort by alpha. Then drag it again to your desired stop number.';
const DND_EASING = 'cubic-bezier(.17,.67,.83,.67)';
const DND_GHOST_CLASS = 'accel-dnd-ghost';
const DND_CHOSEN_CLASS = 'accel-dnd-chosen';
const DND_ANIMATION_TIME = 100;
const DND_DELAY_TIME = 50;
const SORTABLE_LIB_PATH = '/Sortable.min.js';
const ERROR='error',INFO='info',DEBUG='debug',WARN='warn';

/**
 * This class will allow for the reordering and sorting of locations for a route or route schedule.
 * @see clLocationReorderController.apex
 */
export default class ClLocationReorderer extends LightningElement {

    //  ===    Public API   =====
    @api objectApiName;                 //  ie. Route__c or Route_Schedule__c
    @api recordId;                      //  Passed in automagically.
    @api cardTitle;                     //  Admin configurable
    @api showCardAssistance;            //  Admin configurable
    @api cardAssistanceText;            //  Admin configurable
    @api showAllStopsAreZeroPrompt;     //  Admin configurable
    @api allStopsAreZerosText;          //  Admin configurable
    @api showMoveStatusUpdates;         //  Admin configurable
    //  Admin configurable
    @api
    get debugConsole() {
        return this._debugConsole;
    }
    set debugConsole(value) {
        this._debugConsole = value;
        this._logger = new Logger(this.debugConsole);
    }

    //  Private
    @track locRecords;
    _wiredLocsDto;
    _isLoading = true;
    _dndOnEndMsg;
    _dataRefreshTime
    _isAllZeros;
    _logger;
    @track _recReplaced;
    _sortableLoaded;

    constructor() {
        super();
        console.info('%c----> /lwc/clLocationReorderer',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
    }

    /**
     * Loads the 3rd party lib SortableJs
     * @see https://github.com/SortableJS
     */
    connectedCallback() {
        this.loadSortable();
        this.showCardAssistance = false;
    }

    /**
     * Destroy the 3rd party lib.
     */
    disconnectedCallback() {
        this.unregisterDragDropEvents();
    }

    /**
     * DnD is done here because we cannot be sure the library is loaded in connected callback.
     * This should only occur once due to the _sortable variable.
     */
    renderedCallback() {
        if(this.locRecords && !this._sortable && this._sortableLoaded) {
            this.registerDragDropEvents();
        }
    }

    /**
     * Retrieve location records with stop data. sObject api name and record id are in context
     * via being on a record page. Shacked the cache so we can manipulate the records.
     * Check if all stops are zero if the cmp property is checked.
     *
     * @param wiredDto
     */
    @wire(retrieveLocsData, {sObjectApiName: '$objectApiName',parentRecordId:'$recordId'})
    wiredRetrieveLocsData(wiredDto) {

        this._wiredLocsDto = wiredDto;
        const {data, error} = this._wiredLocsDto;

        if(data) {
            this._isLoading = false;
            if (data.isSuccess) {
                let results = [...uiHelper.getMapValue(MAP_KEY_LOCATIONS, data.values)];
                this.locRecords = JSON.parse(JSON.stringify(results));
                this.log(DEBUG,'loc records retrieved',this.locRecords);
                this.reSortStops();
                this._dataRefreshTime = new Date().getTime();

                if(this.showAllStopsAreZeroPrompt) {
                    this.checkForAllZeroStops();
                }
            } else {
                this.log(WARN,data.technicalMsg);
                this.locRecords = [];
            }
        } else if (error) {
            this._isLoading = false;
            this.error = reduceErrors(error);
            this.log(ERROR,error);
            uiHelper.showToast(this,'',this.error,'error','pester');
        }
    }

    /**
     * Update all records with their new stop numbers. call native getRecordNotifyChange to update
     * related list on record page.
     */
    updateStopNumbers() {
        let updates = [];
        let updatedRecordIds = [];

        //  Build new compact array to send to the server.
        this.locRecords.forEach(record => {
            let upd = {};
            updatedRecordIds.push(record.recordId);
            upd.Id = record.recordId;
            upd.Stop_Number__c = record.stopNumber;
            updates.push(upd);
        });
        let params = { allRecords:updates };
        if(this.debugConsole) {
            this.log(DEBUG,'---> calling update with params',params);
        }

        //  Call the server side update.
        doUpdateStopNumbers(params)
            .then((result) => {
                if(this.showAllStopsAreZeroPrompt) {
                    this.checkForAllZeroStops();
                }
                if(this.debugConsole) {
                   this.log(DEBUG,'----> update dto', result);
                }
                const updatedRecords = updatedRecordIds.map(recId => {
                    return { 'recordId': recId };
                });
                //  Refresh the route account / route schedule account related list.
                this.reSortStops();
                getRecordNotifyChange(updatedRecords);
                this._dataRefreshTime = new Date().getTime();
                if(this._isAllZeros && this.showAllStopsAreZeroPrompt) {
                    this.handleRefresh();
                }
            })
            .catch((error) => {
                console.error(error);
                this.error = reduceErrors(error);
                uiHelper.showToast(this,'',this.error,'error','pester');
            });
    }

    /**
     * Check if all stops are currently Zero. if true, show a toast to the user.
     * ie. currently it is difficult to sort when all stops are the same number. User
     * must take action to move a stop to cause an auto-sort. then move the stop again.
     */
    checkForAllZeroStops() {
        if(this.locRecords) {
            this._isAllZeros = !Object.values(this.locRecords).some(record => record.stopNumber !== 0);
            if(this._isAllZeros) {
                if(this.debugConsole) {
                    this.log(WARN,'---> all stops are zeros!');
                }
            }
        }
    }

    /**
     * Msg Passed in from public api.
     * @returns {*|string}
     */
    get allStopsAreZerosMsgText() {
        let text = this.allStopsAreZerosText ? this.allStopsAreZerosText : DEFAULT_ALL_ZEROS_WARNING_TEXT;
        return text;
    }

    /**
     * Sort the stops array by stop number asc.
     */
    reSortStops() {
        let tmp =  JSON.parse(JSON.stringify(this.locRecords));
        tmp.sort((a,b) => a.stopNumber - b.stopNumber);
        this.locRecords = tmp;
    }

    /**
     * Remove the previous update message.
     * @param evt
     */
    handleDndOnMove(evt) {
        this._dndOnEndMsg = null;
        const replacedRecordId = evt.related.dataset.recordid;
        let recReplaced = this.locRecords.find(record => record.recordId === replacedRecordId);
        console.log('--> dnd on move.. rec replaced id='+replacedRecordId+'... stopNumber:'+recReplaced.stopNumber);
        this._recReplaced = recReplaced;
    }

    /**
     * Trigger by sortableJs. Finds the dragged list element and its associated item in the saved array.
     * Find the record id clicked and use the index of the event to change the stop number.
     * Find all other records in the array and update the stop number and location display.
     *
     * @param evt
     */
    handleDndOnEnd(evt) {
        const recordId = evt.item.dataset.recordid;

        if (recordId) {
            let recDragged = this.locRecords.find(record => record.recordId === recordId);
            const oldStopNumber = recDragged.stopNumber.valueOf();

            console.log('--> dnd on end.. rec dragged id='+recordId+'... stopNumber:'+oldStopNumber);
            if(this._recReplaced) {
                const newStopNumber = this._recReplaced.stopNumber.valueOf();
                this._dndOnEndMsg = `Moved  ${recDragged.locName} from stop ${oldStopNumber} to stop ${newStopNumber}`;
                recDragged.stopNumber = newStopNumber;
                this.formatLocName(recDragged);
                this._recReplaced.stopNumber = oldStopNumber;
                this.formatLocName(this._recReplaced);
                this.updateStopNumbers();
            }
        }
    }

    /**
     * This is sort of a 'hack' since the parameters to the server side apex call are not changing. SFDC
     * will not refresh the cache.. we need to artifically change the param.. call the apex SS call. get back nothing,
     * then change it correctly again and call it back.
     *
     * @param evt
     * @todo  change to use a cachebust method via passing randomly generated double to apex.
     */
    handleRefresh(evt) {
        const oldSObjectApiName = this.objectApiName.split('').join(''); // shake the reference to the string object
        this.objectApiName = 'blah';
        refreshApex(this._wiredLocsDto);
        this.objectApiName = oldSObjectApiName;
        refreshApex(this._wiredLocsDto);
    }

    /**
     * Config and fire up the Sortable lib
     * @todo occasionally this still fires an uncaught error on first time of lib loaded (not cached) how is that possible?
     */
    registerDragDropEvents() {
        if(this.debugConsole) {
            this.log(DEBUG,'---> registerDragDrop');
        }
        let tileContainer = this.template.querySelector('.accel-tile-container');
        let config = {
            animation: DND_ANIMATION_TIME,
            delay: DND_DELAY_TIME,
            delayOnTouchOnly: true,
            easing: DND_EASING,
            ghostClass: DND_GHOST_CLASS,
            chosenClass: DND_CHOSEN_CLASS,
            dragoverBubble: true,
            onEnd: this.handleDndOnEnd.bind(this),
            onMove: this.handleDndOnMove.bind(this)
        }
        try {
            if (Sortable) {
                try {
                    this._sortable = Sortable.create(tileContainer, config);
                    console.log('-->sortable created!');
                } catch (e) {
                    this.log(ERROR, 'sortable create error', e);
                }
            }
        } catch (e1) {
            console.error(e1);
        }
    }

    /**
     * Unregister DnD events and destroy the sortable lib.
     */
    unregisterDragDropEvents() {
        if(this.debugConsole) {
            this.log(DEBUG,'---> unRegisterDragDrop');
        }
        try {
            if(this._sortable) {
                this._sortable.destroy();
            }
        } catch (e) {
            this.log(ERROR,'unregister error',e);
        }
        this._sortable = undefined;
    }

    /**
     * Format the location name to something like (2) Joe's Bar  ([Stop Number]) Account Name.
     * @param record
     */
    formatLocName(record) {
        if(record) {
            record.formattedLocName = '(' + record.stopNumber + ') ' + record.locName;
        }
    }

    get cardAssistanceHelpText() {
        return this.cardAssistanceText ? this.cardAssistanceText : DEFAULT_CARD_ASSISTANCE_TEXT;
    }

    get showRecords() {
        return this.locRecords &&  this.locRecords.length > 0;
    }

    /**
     * Load SortableJs
     * https://github.com/SortableJS
     */
    loadSortable() {
        loadScript(this, SORTABLE_RESOURCE + SORTABLE_LIB_PATH)
            .then(() => {
                this._sortableLoaded = true;
                let tileContainer = this.template.querySelector('.accel-tile-container');
                if(tileContainer) {
                    this.registerDragDropEvents();
                }
                if(this.debugConsole) {
                    this.log(DEBUG,'----> sortable loaded!');
                }
            })
            .catch(error => {
                this.error = reduceErrors(error);
                this.log(ERROR,'Error loading sortable',this.error);
                this.log(ERROR,'Full error',error);
            });
    }
    /**
     *
     * @param logType  The type of log (see the constants).
     * @param msg      The string msg to log.
     * @param obj      an optional obj (internally will attempt to deconstruct to avoid proxy issues)
     */
    log(logType, msg, obj) {
        if (this._logger) {
            switch (logType) {
                case DEBUG:
                    this._logger.logDebug(msg,obj);
                    break;
                case ERROR:
                    this._logger.logError(msg,obj);
                    break;
                case INFO:
                    this._logger.logInfo(msg,obj);
                    break;
                default:
                    this._logger.log(msg, obj);
            }
        }
    }
}