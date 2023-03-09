import {api, LightningElement, track} from 'lwc';

export default class ClRouteOptimizeAssistance extends LightningElement {

    @api selectedCollectionRegionPlOption;
    @api selectedTerritoryPlOption;
    @api selectedLocStartType;
    @api selectedStartAccount;
    @api totalNumStopsSelected;
    @api maxWayPoints;
    @api wayPointRows;
    @api wayPointRowsSelected = [];
    @api showOptimizeButton;

    @track showAdvancedOptions = false;

    handleHideAdvancedOptions(evt) {
        this.showAdvancedOptions = false;
        this.dispatchEvent( new CustomEvent('toggleadvancedform', {detail: { showIt: false }}) );
    }
    handleShowAdvancedOptions(evt) {
        this.showAdvancedOptions = true;
        this.dispatchEvent( new CustomEvent('toggleadvancedform', {detail: { showIt: true }}) );
    }

    get showTerritorySelected() {
        return this.selectedTerritoryPlOption;
    }
    get showCollectionRegionSelected() {
        return this.selectedCollectionRegionPlOption;
    }
    get showSelectedLocStartType() {
        return this.selectedLocStartType;
    }
    get showSelectedStartAccount() {
        if(this.selectedStartAccount) {
            console.log('selectedStartAccount=', JSON.parse(JSON.stringify(this.selectedStartAccount)));
        }
        return this.selectedStartAccount;
    }
    get showStartAccountInfo() {
        let showIt =  this.selectedLocStartType && this.selectedLocStartType !== 'Current Address';
        console.log('--- show start account info:'+showIt);
        return showIt;
    }
    get showTotalStopsInfo() {
        let showIt = false;
        if(this.selectedLocStartType === 'Current Address') {
            showIt = true;
        } else {
            if(this.selectedLocStartType && this.selectedStartAccount) {
                showIt = true;
            }
        }
        return showIt;
    }
    get showTotalNumStopsSelected() {
        return this.totalNumStopsSelected && this.totalNumStopsSelected > 0;
    }

    get showWayPointRows() {
        return this.wayPointRows && this.wayPointRowsSelected.length > 1;
    }
    get showWayPointRowsSelected() {
        return this.wayPointRowsSelected && this.wayPointRowsSelected.length > 1;
    }
    get showRunItInfo() {
        return this.showOptimizeButton;
    }
    get showWayPointInfo() {
        return this.showTotalNumStopsSelected;
    }

    get showMoreStopsNeeded(){
        return this.wayPointRowsSelected && this.totalNumStopsSelected < this.wayPointRowsSelected.length;
    }

    get numberOfMoreLocsNeeded() {
        let x = 0;
        x = this.wayPointRowsSelected ? this.totalNumStopsSelected - this.wayPointRowsSelected.length : this.totalNumStopsSelected;
        return x;
    }




}