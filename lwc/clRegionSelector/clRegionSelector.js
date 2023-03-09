import {LightningElement,wire,track,api} from 'lwc';
import Id from '@salesforce/user/Id';
import retrieveRegions from '@salesforce/apex/clRouteScheduleSelection.retrieveCollectorLocationInfo';
import Logger from 'c/logger'
import {uiHelper} from "./clRegionSelectorUiHelper";

const MAP_KEY_COLLECTOR_LOC_WRAPPERS     = 'COLLECTOR_LOC_WRAPPERS';

export default class ClRegionSelector extends LightningElement {

    @api   selectLabel = 'Region Test';
    @api   allRegionsLabel = ' - All Regions - ';
    @api   allRegionsValue = '*';
    @api   suppressedRegionValues;
    @api
    get debugConsole() { return this._debugConsole;}
    set debugConsole(value) { this._debugConsole = value; this._logger = new Logger(this._debugConsole);}

    @track regionPlOptions;

    _userId = Id;
    _wiredDto;
    _logger;
    _isLoading = true;
    _debugConsole;

    constructor() {
        super();
        this._isLoading = true;
    }

    connectedCallback() {
        this._logger.logDebug('----> /lwc/clRegionSelector','connectedCbk');
    }

    /**
     * Retrieve region pl values.
     * @param wiredDto
     */
    @wire(retrieveRegions, {uid: '$_userId',suppressedValues: '$suppressedRegionValues'})
    retrievePlValues(wiredDto) {
        this._wiredDto = wiredDto;
        const { data, error } = this._wiredDto;
        if(data) {
            if(data.isSuccess) {
                this.regionPlOptions = [...uiHelper.getMapValue(MAP_KEY_COLLECTOR_LOC_WRAPPERS,data.values)];
                this.regionPlOptions.unshift({value:this.allRegionsValue,label:this.allRegionsLabel,selected:false});
                this._logger.logDebug('-->  wired  retrievePlValues',this.regionPlOptions);
                this._logger.logDebug('-->  wired  retrievePlValues tech msg',data.technicalMsg);
            } else {
                this._logger.logError('--> wired retrievePlValues not retrieved successfully',data);
            }
            this._isLoading = false;
        } else if (error) {
            this.logError(error,'wired retrievePlValues');
            const errorDisplay = uiHelper.reduceErrors(error);
            uiHelper.showToast(this,'',errorDisplay,'sticky');
            this._isLoading = false;
        }
    }

    /**
     * Handle the change event of the picklist and fire an event so the parent can listen.
     * @param evt
     */
    handlePlChange(evt) {
        let value = evt.target.value;
        this.dispatchEvent(new CustomEvent('regionoptionselected', {detail: value}));
    }

    get showPlValues() {
        return this.regionPlOptions;
    }
    get showStencil() {
        return this._isLoading;
    }

    /**
     * Super generic error logging.
     *
     * @param error         The error object.
     * @param methodName    The method name.
     */
    logError(error, methodName) {
        this._logger.logError('---> full '+methodName+ ' error',error);
        const errorDisplay = uiHelper.reduceErrors(error);
        this._logger.logError('---> reduced '+methodName+ 'error', errorDisplay);
    }
}