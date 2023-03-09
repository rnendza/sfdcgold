import {LightningElement,wire,track,api} from 'lwc';
import {getConstants} from "c/clConstantUtil";
import AccelUtilsSvc from 'c/accelUtilsSvc';
import {reduceErrors} from "c/ldsUtils";
import {uiHelper} from './clRouteScheduleSelectionRpsRecordsUiHelper';
import retrieveRPS from '@salesforce/apex/clRouteScheduleSelection.retrieveRouteProcessingSheets';

const GLOBAL_CONSTANTS = getConstants();
const MAP_KEY_RPS_WRAPPERS  = 'RPS_WRAPPERS';

const columns = [
    {
        label: 'Stop #',
        hideDefaultActions: true,
        fieldName: 'stopNumber',
        sortable:true
    },
    { label: 'Location',
        hideDefaultActions: true,
        fieldName: 'locName',
        cellAttributes: { iconName: 'standard:account' },
        sortable: true
    },
    { label: 'Address',
        hideDefaultActions: true,
        fieldName: 'rpsLocAddy'
    },
    { label: 'Access Time',
        hideDefaultActions: true,
        fieldName: 'rpsLocAccessTime'
    }
];

export default class ClRouteScheduleSelectionRpsRecords extends LightningElement {

    @api routeScheduleId;       // required!
    @api totalNumAccounts = 0;
    @api columnWidthsMode = 'auto';
    @api hideCheckboxColumn;
    @api tableAriaLabel = 'Location details for route';
    @api tableKeyField = 'rpsId';

    @track routeProcessingSheets;
    @track routeScheduleName;
    @track tableColumns = columns;
    @track rowOffset = 0;

    sortedBy;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';

    _wiredRpsDto;
    _debugConsole = false;
    _accelUtils = new AccelUtilsSvc(this._debugConsole);

    constructor(){
        super();
        console.info('%c----> /lwc/clRouteScheduleSelectionRpsRecords',GLOBAL_CONSTANTS.CONSOLE_MODULE_STYLE);
        this.hideCheckboxColumn = true;
    }

    renderedCallback() {
        if (!this._hasRendered) {
            uiHelper.overrideDatatableStyles(this);
            this._hasRendered = true;
        }
    }


    @wire(retrieveRPS, {routeScheduleId: '$routeScheduleId'})
    retrieveRpsData(wiredDto) {
        this._wiredRpsDto = wiredDto;
        const { data, error } = this._wiredRpsDto;
        if(data) {
            const dto = data;
            if(dto.isSuccess) {
                let rpsRecords = this._accelUtils.getMapValue(MAP_KEY_RPS_WRAPPERS, dto.values);
                this.shapeTableData(rpsRecords);
            } else {

            }
        } else if (error) {
            console.error(JSON.stringify(error));
            this.error = reduceErrors(error);
            //uiHelper.showToast(this,'','Problem retrieving route processing sheet data: '+this.error,'error');
        }
    }
    handleSort( event ) {

        const { fieldName: sortedBy, sortDirection } = event.detail;

        this.routeProcessingSheets.sort( uiHelper.sortBy( sortedBy, sortDirection === 'asc' ? 1 : -1 ) );
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;

    }

    get showDataTable() {
        return this.routeProcessingSheets && this.routeProcessingSheets.length > 0;
    }
    get noRpsMsg() {
        let msg = 'Route schedule has '+this.totalNumAccounts + ' locations and no route processing sheets!';
        return msg;
    }
    /**
     * Clone the data in case we need to sort / modify etc.
     * @param rpss
     */
    shapeTableData(rpss) {
        let newRpss = [];
        rpss.forEach( (rps,index) => {
            let newRps = Object.assign({},rps);
            newRps.rpsName = rps.rpsName;
            newRps.rpsId = rps.rpsId;
            newRps.linkName = '/'+newRps.rpsId;
            newRps.locName = rps.rpsLocName;
            newRps.stopNumber = rps.rpsStopNumber;
            newRps.rpsLocAddy = rps.rpsLocAddy;
            newRps.rpsLocAccessTime = rps.rpsLocAccessTime;
            if(index === 0) {
                this.routeScheduleName = rps.routeScheduleName;
            }
            newRpss.push(newRps);
        });
       this.routeProcessingSheets = newRpss;
    }
}