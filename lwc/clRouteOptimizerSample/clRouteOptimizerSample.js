import {api, LightningElement, track, wire} from 'lwc';
// import {ShowToastEvent} from "lightning/platformShowToastEvent";
// import {CurrentPageReference} from "lightning/navigation";
// import {fireEvent} from 'c/pubSub';
// import {refreshApex} from "@salesforce/apex";
//
// import retrieveAllTerritories from '@salesforce/apex/OpenrouteController.retrieveAllServiceTerritories';
// import retrieveAllRoutes from '@salesforce/apex/OpenrouteController.retrieveAllRoutes';
// import retrieveAllRouterRpsCollectionDates from '@salesforce/apex/OpenrouteController.retrieveAllRouteRpsCollectionDates';
// import retrieveRpsData from '@salesforce/apex/OpenrouteController.retrieveRouteProcessingSheets';
// import retrieveOptimizationResults from '@salesforce/apex/OpenrouteController.retrieveAccountOptimizationData';
// import retrieveDirectionsResults from '@salesforce/apex/OpenrouteController.retrieveAccountDirectionData';
// import retrieveStartLocGeoData from '@salesforce/apex/OpenrouteController.retrieveStartGeoData';
// import retrieveCollectionRegionData from '@salesforce/apex/OpenrouteController.retrieveCollectionRegions';
//
// import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';
//
// import {reduceErrors} from 'c/ldsUtils';
// import AccelUtilsSvc from 'c/accelUtilsSvc';
// import mainTemplate from './clRouteOptimizerSample.html'
// import stencil from './clRouteOptimizerSampleStencil.html';
// import {loadScript, loadStyle} from "lightning/platformResourceLoader";
//
// const MAP_KEY_ALL_TERRITORIES = 'ALL_TERRITORIES';
// const MAP_KEY_OPTIMIZATION_DATA = 'LOC_OPTIMIZATION_DATA';
// const MAP_KEY_OPTIMIZATION_RESULTS = 'LOC_OPTIMIZATION_RESULTS';
// const MAP_KEY_DIRECTION_RESULTS = 'LOC_DIRECTION_RESULTS';
// const MAP_KEY_START_ADDRESS_GEO = 'START_ADDRESS_GEO';
// const MAP_KEY_COLLECTION_REGIONS = 'ALL_COLLECTION_REGIONS';
// const MAX_WAYPOINTS = 10;
//
// const columns = [
//     {
//         label: 'Location',
//         fieldName: 'accountName',
//     },
//     {
//         label: 'Type',
//         fieldName: 'type',
//     },
//     {
//         label: 'Aggr travel time',
//         fieldName: 'totalTravelTimeFormatted',
//     },
//     {
//         label: 'Service time',
//         fieldName: 'dServiceTimeMinutes',
//     },
//     {
//         label: 'Vehicle',
//         fieldName: 'vehicleDesc',
//     },
//     {
//         label: 'Lat/Lng',
//         fieldName: 'latLng',
//     },
//     {
//         label: 'Time of arrival', fieldName: 'dtOfArrival', type: 'date',
//         typeAttributes: {hour: '2-digit',minute: '2-digit',second: '2-digit',hour12: true}
//     },
// ];
// const columnsUnassigned = [
//     {
//         label: 'Location',
//         fieldName: 'accountName',
//     },
//     {
//         label: 'Lat/Lng',
//         fieldName: 'latLng',
//     }
// ];
export default class ClRouteOptimizerSample extends LightningElement {

    // @api cardTitle = "Route Optimizer Query";
    // @api summaryCardTitle = 'Route Optimizer Results';
    // @api activeTabValue = 'route_overview';
    //
    // @track directionsData;
    // @track startOptions;
    // @track locStartOptions;
    // @track vehicleOptions;
    // @track territoryOptions;
    // @track routeOptions;
    // @track routeDateOptions;
    // @track locationOptions;
    // @track selectedTerritoryId;
    // @track selectedRouteId;
    // @track selectedCollectionRegion;
    // @track selectedRoute;
    // @track selectedRouteDate;
    // @track selectedLocStartId;
    // @track selectedVehicleId;
    // @track selectedLocStartType;
    // @track vehicleStartTime;
    // @track vehicleEndTime;
    // @track selectedStartAccountId;
    // @track selectedStartAccount;
    // @track selectedLocStartCoords;
    // @track optimizationData;
    // @track optimizationResults;
    // @track wayPointAccountIds = [];
    // @track wayPointRows = [];
    // @track wayPointRowsSelected = [];
    // @track advancedOptions = null;
    // @track showOptimizeButton = false;
    // @track totalNumberOfWaypoints = 0;
    // @track steps = [];
    // @track rowOffset = 0;
    // @track columns = columns;
    // @track columnsUnassigned = columnsUnassigned;
    // @track startLocGeoData;
    // @track showAdvancedOptions = false;
    // @track collectionRegionOptions = [];
    // @track unassigned;
    // @track _activeTab;
    //
    //
    //
    // @track _wiredTerritoriesDto;
    // @track _wiredRpsDto;
    // @track _wiredRoutesDto;
    // @track _wiredRouteDatesDto;
    // @track _wiredDirectionsDto;
    // @track _territoryData;
    // @track _routeData;
    // @track _routeDates;
    // @track _selectedTerritoryPlOption;
    // @track _selectedRoutePlOption;
    // @track _selectedCollectionRegionPlOption;
    // @track refreshAllAutocompletes = false;
    // @track userCurrentPosition;
    // @track userCoordinates;
    // @track originCoordinate;
    // @track destinationAccountIds;
    // @track selectedOriginGeo;
    // @track selectedDestinationGeo;
    // @track rpsData;
    //
    // @track originGeo;
    // @track destinationGeo;
    // @track wayPointGeos = [];
    //
    // _wiredStartLocGeoData;
    // _wiredCollectionRegionsDto;
    // _isProcessing = true;
    // _toggleAdvancedContainerClass = 'slds-col slds-size_1-of-1 slds-p-top_medium';
    // _isFormLoaded = false;
    // _isOptimizing = false;
    // _hasRendered;
    // _injectedThemeOverrides;
    // _lookupInputStyle;
    // _themeOverrideStyle;
    // _debugConsole = true;
    // _accelUtils = new AccelUtilsSvc(this._debugConsole);
    //
    // constructor() {
    //     super();
    //     this.buildThemeOverrideCss();
    // }
    //
    // connectedCallback() {
    //     this.getUsersCurrentPosition();
    //     this.showToast('DEV NOTE!','THIS Is currently obsolete.. Mods needed for new datamodel changes and to use real route info!','error');
    // }
    //
    // renderedCallback() {
    //     if (!this._hasRendered) {
    //         this._hasRendered = true;
    //         this.loadFontAwesome();
    //         this.buildVehiclePlOptions();
    //     }
    //     if (!this._injectedThemeOverrides) {
    //         this.injectThemeOverrideStyle();
    //     }
    // }
    //
    // render() {
    //     let template = this._isFormLoaded ? mainTemplate : stencil;
    //     return template;
    // }
    //
    // @wire(CurrentPageReference)
    // pageRef;
    //
    //
    //
    // @wire(retrieveStartLocGeoData,{ coords: '$userCoordinates' })
    // retrieveGeoData(wiredDto) {
    //     this._wiredStartLocGeoData = wiredDto;
    //     const {data, error} = this._wiredStartLocGeoData;
    //     if (data) {
    //         if (data.isSuccess) {
    //             this.startLocGeoData = this._accelUtils.getMapValue(MAP_KEY_START_ADDRESS_GEO, data.values);
//     //             console.log('--> retrieve start loc geo data success data='+JSON.stringify(data));
//                 this.buildLocStartPlOptions(this.selectedLocStartId);
//             } else {
//                 console.log('--> failed dto=',JSON.parse(JSON.stringify(data)));
//                 this.buildLocStartPlOptions(this.selectedLocStartId);
//                 //this.uiErrorMsg.body = 'No territories found!';
//             }
//         } else if (error) {
//             console.error(error);
//             this.error = reduceErrors(error);
//             this.showToast('', 'Problem retrieving user starting location geo data: ' + this.error, 'error');
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         }
//     }
//
//     @wire(retrieveCollectionRegionData)
//     retrieveCollectionRegions(wiredDto) {
//         this._wiredCollectionRegionsDto = wiredDto;
//         const {data, error} = this._wiredCollectionRegionsDto;
//         if (data) {
//             if (data.isSuccess) {
//                 console.log('--> col region dto=',JSON.parse(JSON.stringify(data)));
//                let tmp = this._accelUtils.getMapValue(MAP_KEY_COLLECTION_REGIONS, data.values);
//                 console.log('--> retrieve collection regions data success data=',JSON.parse(JSON.stringify(data)));
//                 this.buildCollectionRegionsPlOptions(tmp);
//             } else {
//                 console.log('--> failed dto=',JSON.parse(JSON.stringify(data)));
//             }
//         } else if (error) {
//             console.error(error);
//             this.error = reduceErrors(error);
//             this.showToast('', 'Problem retrieving collection region data: ' + this.error, 'error');
//         }
//     }
//
//     @wire(retrieveAllTerritories)
//     retrieveTerritoryData(wiredDto) {
//         this._wiredTerritoriesDto = wiredDto;
//         const {data, error} = this._wiredTerritoriesDto;
//         if (data) {
//             console.log('--> retrieve territory data success='+data.isSuccess);
//             if (data.isSuccess) {
//                 this._territoryData = this._accelUtils.getMapValue(MAP_KEY_ALL_TERRITORIES, data.values);
//                 this.buildTerritoryPlOptions(this._territoryData, this.selectedTerritoryId);
//             } else {
//                 this.uiErrorMsg.body = 'No territories found!';
//             }
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         } else if (error) {
//             this.error = reduceErrors(error);
//             this.showToast('', 'Problem retrieving territory data: ' + this.error, 'error');
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         }
//     }
//
//     @wire(retrieveAllRoutes)
//     retrieveRouteData(wiredDto) {
//         this._wiredRoutesDto = wiredDto;
//         const {data, error} = this._wiredRoutesDto;
//         if (data) {
//             console.log('--> retrieve route data success='+data.isSuccess);
//             if (data.isSuccess) {
//                 this._routeData = this._accelUtils.getMapValue('ALL_ROUTES', data.values);
//                 console.log('---> route data dto =',JSON.parse(JSON.stringify(data)));
//                 this.buildRoutePlOptions(this._routeData, this.selectedRouteId);
//             } else {
//                 this.uiErrorMsg.body = 'No routes found!';
//             }
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         } else if (error) {
//             this.error = reduceErrors(error);
//             this.showToast('', 'Problem retrieving route date data: ' + this.error, 'error');
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         }
//     }
//
//     @wire(retrieveRpsData,{routeId: '$selectedRouteId', collectionDate : '$selectedRouteDate'})
//     retrieveRpsData(wiredDto) {
//         this._wiredRpsDto = wiredDto;
//         const {data, error} = this._wiredRpsDto;
//         if (data) {
//             console.log('--> retrieve rps success='+data.isSuccess);
//             if (data.isSuccess) {
//                 this.rpsData = this._accelUtils.getMapValue('ROUTE_PROCESSING_SHEETS', data.values);
//                 console.log('---> rps dto =',JSON.parse(JSON.stringify(data)));
//                 //this.buildRouteDatePlOptions(this._routeDates, this.selectedRouteId);
//             } else {
//                 if(this.selectedRouteDate && this.selectedRouteDate !== '-1') {
//                     this.showToast('', 'No Route processing sheets for route and date selected!', 'error');
//                     //this.selectedRouteId = -1;
//                     //this.buildRouteDatePlOptions(this._routeDates,this.selectedRouteId);
//                 }
//             }
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         } else if (error) {
//             this.error = reduceErrors(error);
//             this.showToast('', 'Problem retrieving route processing sheets' + this.error, 'error');
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         }
//     }
//
//     @wire(retrieveAllRouterRpsCollectionDates,{routeId: '$selectedRouteId'})
//     retrieveRouteDates(wiredDto) {
//         this._wiredRouteDatesDto = wiredDto;
//         const {data, error} = this._wiredRouteDatesDto;
//         if (data) {
//             console.log('--> retrieve route dates success='+data.isSuccess);
//             if (data.isSuccess) {
//                 this._routeDates = this._accelUtils.getMapValue('ALL_ROUTE_RPS_COLLECTION_DATES', data.values);
//                 console.log('---> route dates data dto =',JSON.parse(JSON.stringify(data)));
//                 this.buildRouteDatePlOptions(this._routeDates, this.selectedRouteId);
//             } else {
//                 if(this.selectedRouteId) {
//                     this.showToast('', 'No Route processing sheets for route. Please choose an another route!', 'error');
//                     this.selectedRouteId = -1;
//                     this.buildRouteDatePlOptions(this._routeDates,this.selectedRouteId);
//                 }
//
//             }
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         } else if (error) {
//             this.error = reduceErrors(error);
//             this.showToast('', 'Problem retrieving route date data: ' + this.error, 'error');
//             this._isProcessing = false;
//             this._isFormLoaded = true;
//         }
//     }
//
//     handleVehicleStartTimeChange(evt) {
//         this.vehicleStartTime = evt.target.value;
//     }
//
//     doRetrieveDirectionsResults() {
//         //this._isOptimizing = true;
//
//         let params = {
//             accountIds: this.wayPointAccountIds,
//             coordinates: this.userCoordinates
//         }
//         console.log('---> calling retrieveDirectionsResults with,', params);
//         retrieveDirectionsResults(params)
//             .then((result) => {
//                 console.info('----> directions dto', JSON.parse(JSON.stringify(result)));
//                 this.directionsData = this._accelUtils.getMapValue(MAP_KEY_DIRECTION_RESULTS, result.values);
//                 this._isFormLoaded  = true;
//                 //this.shapeSteps();
//           //      this._isOptimizing = false;
//             })
//             .catch((error) => {
//                 console.error(error);
//                 this.error = reduceErrors(error);
//                 this.showToast('', 'Error in callout:' + this.error, 'error');
//             });
//     }
//
//
//     doRetrieveOptimizationResults() {
//         this._isOptimizing = true;
//         if(this.wayPointRows && this.wayPointRows.length > 0) {
//             let accountIds = [];
//             let lat = null,lng = null, addy = null;
//
//             if(this.selectedLocStartId == 1 && this.userCurrentPosition.coords.latitude && this.userCurrentPosition.coords.longitude) {
//                 lat = this.userCurrentPosition.coords.latitude;
//                 lng = this.userCurrentPosition.coords.longitude;
//                 addy = this.startLocGeoData;
//             } else {
//                 accountIds.push(this.selectedStartAccountId);
//                 this.wayPointAccountIds.push(this.selectedStartAccountId);
//             }
//
//             this.wayPointRows.forEach(x => {
//                 let accountId = x.sfdcid;
//                 if (accountId) {
//                     accountIds.push(accountId);
//                     this.wayPointAccountIds.push(accountId);
//                 }
//             });
//
//             let params = {
//                 accountIds : accountIds,
//                 lng: lng,
//                 lat: lat,
//                 addy: addy,
//                 advancedOptions: this.advancedOptions
//             }
//             console.log('---> calling retrieveOptimizationResults with,',params);
//             retrieveOptimizationResults( params )
//                 .then((result) => {
//                     this.showAdvancedOptions = false;
//                     console.info('----> opt dto', JSON.parse(JSON.stringify(result)));
//                     this.optimizationData = this._accelUtils.getMapValue(MAP_KEY_OPTIMIZATION_DATA, result.values);
//                     this.optimizationResults = this._accelUtils.getMapValue(MAP_KEY_OPTIMIZATION_RESULTS, result.values);
//                     console.info('----> opt results',JSON.parse(JSON.stringify(this.optimizationResults)));
//                     let msg = 'Optimization result code: '+this.optimizationResults.resultDesc;
//                     //this.showToast('',msg,'success');
//                     this.shapeSteps();
//                     this.shapeUnassigned();
//                     this._isOptimizing = false;
//                 })
//                 .catch((error) => {
//                     console.error(error);
//                     this.error = reduceErrors(error);
//                     this.showToast('','Error in callout:' + this.error, 'error');
//                     this._isOptimizing = false;
//                 });
//         }
//     }
//
//     handleCollectionRegionSelected(evt) {
//         const crId = evt.target.value;
//         if(crId && crId != '-1') {
//             this._isProcessing = true;
//             if(this.selectedCollectionRegion) {
//                 // we are changing it.. artifically refresh the form
//                 this._isFormLoaded = false;
//             }
//             this.selectedCollectionRegion = crId;
//             if(this.selectedCollectionRegion) {
//                 this._selectedCollectionRegionPlOption = this.collectionRegionOptions.find(x => x.value == this.selectedCollectionRegion);
//             }
//             this.refreshAllAutocompletes = true;
//             this.selectedStartAccountId = undefined;
//             this.selectedStartAccount = undefined;
//             this.wayPointRows = [];
//             this.wayPointRowsSelected = [];
//         } else {
//             this.selectedCollectionRegion = undefined;
//             this.showToast('','Please select a valid collection region!','warning');
//         }
//         this._isFormLoaded = true;
//     }
//
//     handleRouteSelected(evt) {
//         const routeId = evt.target.value;
//         if(routeId && routeId != '-1') {
//             this._isProcessing = true;
//             if(this.selectedRoute) {
//                 // we are changing it.. artifically refresh the form
//                 this._isFormLoaded = false;
//             }
//             this.selectedRoute = routeId;
//             this.selectedRouteId = routeId;
//             if(this.selectedRoute) {
//                 this._selectedRoutePlOption = this.routeOptions.find(x => x.value == this.selectedRoute);
//             }
//             this.refreshAllAutocompletes = true;
//             this.selectedStartAccountId = undefined;
//             this.selectedStartAccount = undefined;
//             this.wayPointRows = [];
//             this.wayPointRowsSelected = [];
//             this.rpsData = [];
//         } else {
//             this.selectedCollectionRegion = undefined;
//             this.showToast('','Please select a valid route region!','warning');
//         }
//         this._isFormLoaded = true;
//     }
//     handleRouteDateSelected(evt) {
//         const routeDate = evt.target.value;
//         if(routeDate && routeDate != '-1') {
//             this._isProcessing = true;
//             if(this.selectedRouteDate) {
//                 // we are changing it.. artifically refresh the form
//                 this._isFormLoaded = false;
//             }
//             this.selectedRouteDate = routeDate;
//             alert(this.selectedRouteDate);
//             if(this.selectedRouteDate) {
//                 this._selectedRouteDatePlOption = this.routeDateOptions.find(x => x.value == x);
//             }
//             this.refreshAllAutocompletes = true;
//             this.selectedStartAccountId = undefined;
//             this.selectedStartAccount = undefined;
//             this.wayPointRows = [];
//             this.wayPointRowsSelected = [];
//         } else {
//             this.selectedRouteDate = undefined;
//             this.showToast('','Please select a valid date!','warning');
//         }
//         this._isFormLoaded = true;
//     }
//
//     handleStartAccountSelected(evt) {
//         console.log('---> handle start account selected. value=',evt.detail.value);
//         let record = evt.detail.value;
//         if(record && record.id) {
//             this.selectedStartAccountId = record.id;
//             this.selectedStartAccount = record;
//         } else {
//             this.selectedStartAccountId = null;
//             this.selectedStartAccount = null;
//         }
//     }
//     handleLocStartSelected(evt) {
//         console.log('---> handle loc start selected. value=',evt.target.value);
//         this.selectedLocStartId = evt.target.value;
//         if(evt.target.value == 1){
//             this.selectedLocStartType = 'Current Address';
//             this.selectedLocStartCoords = this.userCurrentPosition.coords;
//             console.log('setting coords with lat:'+this.selectedLocStartCoords.latitude);
//         } else if (evt.target.value == 2) {
//             this.selectedLocStartType = 'Location';
//             this.selectedLocStartCoords = undefined;
//         }
//     }
//
//     handleVehicleSelected(evt) {
//         console.log('---> handle vehicle selected. value=',evt.target.value);
//         this.selectedVehicleId = evt.target.value;
//         let vehicleRow = this.vehicleOptions.find(x => x.value == this.selectedVehicleId);
//         if(vehicleRow) {
//             vehicleRow.selected = true;
//             if(!this.advancedOptions) {
//                 this.advancedOptions = {
//                     vehicleId : this.selectedVehicleId,
//                     vehicleDesc: vehicleRow.label
//                 }
//             } else {
//                 this.advancedOptions.vehicleId = this.selectedVehicleId;
//                 this.advancedOptions.vehicleDesc = vehicleRow.label;
//             }
//             console.log('advanced options,',JSON.parse(JSON.stringify(this.advancedOptions)));
//         }
//     }
//
//     handleWaypointRowSelected(evt) {
//         console.log('---> detail from autocomplete',JSON.parse(JSON.stringify(evt.detail)));
//
//         const record = evt.detail.value;
//         const customId = evt.detail.customId;
//
//         if(customId !== undefined && customId !== null) {
//            let wayPointRow = this.wayPointRows.find(x => x.idx == customId);
//            if(wayPointRow && record) {
//                wayPointRow.showExtraFields = true;
//                this.wayPointRowsSelected.push(wayPointRow);
//                wayPointRow.sfdcid = record.id;
//                if(this.wayPointRows.length < this.totalNumberOfWaypoints) {
//                    this.addNewWayPointRow(wayPointRow.idx + 1);
//                } else {
//                    this.showOptimizeButton = true;
//                }
//            }
//         } else {
//             alert('no custom id!');
//         }
//     }
//     handleToggleAdvancedForm(event) {
//         if(event && event.detail) {
//             this.showAdvancedOptions = event.detail.showIt;
//         }
//     }
//
//     handleShowAdvancedOptions() {
//         this.showAdvancedOptions = true;
//     }
//     handleHideAdvancedOptions() {
//         this.showAdvancedOptions = false;
//     }
//
//     handleTabSelect(event) {
//         let tabValue = event.target.value;
//         let tabName = event.target.label;
//         // this.activeTabValue = tabName;
//         this._activeTab = tabValue;
//         if(tabValue == 'route_directions') {
//             this.doRetrieveDirectionsResults();
//         } else if (tabValue == 'distance_matrix') {
//             if(this.userCoordinates) {
//                 this.originCoordinate = {
//                     latitude: this.userCoordinates.lat,
//                     longitude: this.userCoordinates.lng
//                 };
//                 this.destinationAccountIds = this.wayPointAccountIds;
//                 console.log('origin coord='+JSON.stringify(this.originCoordinate));
//                 console.log('accountIds='+ this.destinationAccountIds);
//             }
//         }
//     }
//     handleGoogleMapsOptClick(evt) {
//         evt.preventDefault();
//         evt.stopPropagation();
//         this.showToast('',' work in process','info');
//     }
//
//     handleOptimizeButtonClick(evt) {
//         evt.preventDefault();
//         this.doRetrieveOptimizationResults();
//     }
//
//     handleBackToForm(evt) {
//         console.log('--> back to form');
//         this.resetAllShit();
//     }
//
//     handleResetButtonClick(evt) {
//         console.log('---> reset clicked');
//         //this.optimizationResults = '{"a":"b"}';
//         //this.resetAllShit();
//         setTimeout(() => {  this.resetAllShit();}, 0);
//     }
//
//     resetAllShit() {
//
//         this._isFormLoaded = false;
//
//         //  Get rid of the selected: true in the territories array.
//         this.showAdvancedOptions = false;
//         this.vehicleOptions = undefined;
//         this.selectedVehicleId = null;
//         this.territoryOptions = undefined;
//         this.selectedTerritoryId = null;
//         this.selectedCollectionRegion = undefined;
//         this.buildTerritoryPlOptions(this._territoryData, '-1');
//         this.buildVehiclePlOptions();
//         this.buildCollectionRegionsPlOptions();
//         this.selectedLocStartId = undefined;
//         this.selectedLocStartType = undefined;
//         this.selectedLocStartCoords = undefined;
//         this.showOptimizeButton = false;
//         this.optimizationResults = undefined;
//         this.optimizationData = undefined;
//         this.wayPointRows = [];
//         this.wayPointRowsSelected = [];
//         this.totalNumberOfWaypoints = 0;
//         this.selectedStartAccountId = undefined;
//         this._selectedTerritoryPlOption = undefined;
//         this._selectedCollectionRegionPlOption = undefined;
//         this.selectedStartAccount = undefined;
//         this._isFormLoaded = true;
//         console.log('---> after reset');
//     }
//     /**
//      * Pub an event on this outer container of a click so that children the user the recordAutoComplete component
//      * can decide whether or not to close the slds menu.
//      * @param event
//      */
//     handleOuterContainerClick(event) {
//         fireEvent(this.pageRef, 'eventOuterContainerClicked', 'outercontainerclick');
//     }
//
//     handleTotalNumberOfWaypointsChanged(evt) {
//         this.totalNumberOfWaypoints = evt.target.value;
//         //  pump in a blank row
//         if(this.wayPointRows && this.wayPointRows.length == 0) {
//             this.addNewWayPointRow(1);
//         }
//     }
//     handleFakeResults() {
//         this.resetAllShit();
//         this.optimizationResults = '{"a":"b"}';
//     }
//
//     handleDisabledClick() {
//         this.showToast('','You must complete all form fields before running optimization','error');
//     }
//
//
//
//     addNewWayPointRow(idx){
//         let wayPointRow = {idx: idx, sfdcid: null, label: 'Location Stop ' + idx, showExtraFields: false};
//         this.wayPointRows.push(wayPointRow);
//     }
//     get toggleAdvancedContainerClass() {
//         return this.showAdvancedOptions ? this._toggleAdvancedContainerClass : 'slds-hide';
//     }
//
//     get formStyle() {
//         return this._isOptimizing ? 'display:none' : 'display:block';
//     }
//
//     get optimizingStyle() {
//         return this._isOptimizing ? 'display:block' : 'display:none';
//     }
//
//     get showTerritorySelector() {
//         return this.territoryOptions;
//     }
//     get showRouteSelector() {
//         return this.routeOptions;
//     }
//     get showProcessingSheetCollectionDateSelector() {
//         return this.routeDateOptions;
//     }
//     get showLocationSelector() {
//         return this.selectedCollectionRegion;
//     }
//     get showUnassignedData() {
//         return this.unassigned && this.unassigned.length > 0;
//     }
//     get showWaypoints() {
//         return this.wayPointRows && this.wayPointRows.length > 0;
//     }
//
//     get showTotalStops() {
//         return this.selectedStartAccountId || this.selectedLocStartId == 1;
//     }
//
//     get maxWayPoints() {
//         return MAX_WAYPOINTS;
//     }
//
//     get showSummaryCard() {
//         return this.optimizationResults;
//     }
//     get showForm() {
//         return !this.showSummaryCard;
//     }
//     get showDisabledSubmit(){
//         return !this.showOptimizeButton;
//     }
//     get showEnabledSubmit(){
//         return this.showOptimizeButton;
//     }
//     get showRunItInfo() {
//         return this.showEnabledSubmit;
//     }
//
//     get showAccountLocStart() {
//         return this.selectedCollectionRegion && this.selectedLocStartId == '2';
//     }
//     /**
//      * Basically tries to filter out account options in lookups so they are not duplicated!
//      * @return {string}
//      */
//     get accountWhereCriteria() {
// //        let whereCriteria = " Service_Territory__c = '" + this.selectedTerritoryId + "'";
//         let whereCriteria = " Collection_Region__c = '" +this.selectedCollectionRegion + "'";
//         if (this.selectedStartAccountId) {
//             whereCriteria += " And Id !=  '" + this.selectedStartAccountId + "'";
//         }
//         if (this.wayPointRows && this.wayPointRows.length > 0) {
//             const countSelectedSfdcWaypointIds = this.wayPointRows.filter((obj) => obj.sfdcid != null).length;
//
//             if (countSelectedSfdcWaypointIds > 0) {
//                 whereCriteria += ' AND Id NOT IN ('
//                 this.wayPointRows.forEach(x => {
//                     let accountId = x.sfdcid;
//                     if (accountId) {
//                         whereCriteria += " '" + x.sfdcid + "',";
//                     }
//                 });
//                 whereCriteria += ')';
//                 whereCriteria = this.removeLastInstance(',', whereCriteria);
//             }
//         }
//         console.log('---> where = ' + whereCriteria);
//         return whereCriteria;
//     }
//
//     getUsersCurrentPosition() {
//         navigator.geolocation.getCurrentPosition(position => {
//             let crd = position.coords;
//             console.log('Your current position is:');
//             console.log('Latitude : '+crd.latitude);
//             console.log('Longitude : '+crd.longitude);
//             this.userCurrentPosition = position;
//             let coordinates = {lat: crd.latitude, lng: crd.longitude};
//             this.userCoordinates = coordinates;
//             console.log('user coords=',JSON.parse(JSON.stringify(this.userCoordinates)));
//         });
//     }
//
//     buildCollectionRegionsPlOptions(collectionRegions) {
//         if(collectionRegions && Array.isArray(collectionRegions)) {
//             this.collectionRegionOptions = [];
//             this.collectionRegionOptions.push({value: -1, label: 'Select a collection region', selected: true});
//             collectionRegions.forEach(x => {
//                 let option = x;
//                 this.collectionRegionOptions.push(option);
//             });
//             console.log('col region pl options',JSON.parse(JSON.stringify(this.collectionRegionOptions)));
//         }
//     }
//     /**
//      * @param territories           ServiceTerritory sObjects.
//      * @param selectedTerritoryId   The ServiceTerritory.Id selected in the picklist.
//      */
//     buildTerritoryPlOptions( territories, selectedTerritoryId ) {
//
//         if(territories && Array.isArray(territories)) {
//
//             this.territoryOptions = [];
//             this.territoryOptions.push({value: -1, label: 'Select a territory', selected:true});
//             territories.forEach(x =>  {
//                 let optionSelected = false;
//                 if(this.selectedTerritoryId) {
//                     optionSelected = x.Id === this.selectedTerritoryId;
//                 }
//                 let option = {value: x.Id, label:x.Name, selected:optionSelected };
//                 //console.log('---> build options selected = '+optionSelected);
//                 this.territoryOptions.push(option);
//             });
//         }
//     }
//     buildRoutePlOptions( routes, selectedRouteId ) {
//
//         if(routes && Array.isArray(routes)) {
//
//             this.routeOptions = [];
//             this.routeOptions.push({value: -1, label: 'Select a route', selected:true});
//             routes.forEach(x =>  {
//                 let optionSelected = false;
//                 if(this.selectedRouteId) {
//                     optionSelected = x.Id === this.selectedRouteId;
//                 }
//                 let option = {value: x.Id, label:x.Name, selected:optionSelected };
//                 console.log('---> build options selected = '+optionSelected);
//                 this.routeOptions.push(option);
//             });
//         }
//     }
//     buildRouteDatePlOptions( routeDates, selectedRouteDate ) {
//
//         if(routeDates && Array.isArray(routeDates)) {
//
//             this.routeDateOptions = [];
//             this.routeDateOptions.push({value: -1, label: 'Select a collection date', selected:true});
//             routeDates.forEach(x =>  {
//                 let optionSelected = false;
//                 if(this.selectedRouteDate) {
//                     optionSelected = x === this.selectedRouteDate;
//                 }
//                 let label = x.toLocaleString();
//                 let option = {value: x, label:label, selected:optionSelected };
//                 console.log('---> build options selected = '+optionSelected);
//                 this.routeDateOptions.push(option);
//             });
//         }
//     }
//     buildLocStartPlOptions( selectedLocStartId ) {
//
//             this.locStartOptions = [];
//             this.locStartOptions.push({value: -1, label: 'Select a type of location to start at', selected:true});
//             if(this.userCurrentPosition) {
//                 let msg = 'Your current location ( ';
//                 if(this.startLocGeoData) {
//                     msg += this.startLocGeoData;
//                 } else {
//                     msg +=   this.userCurrentPosition.coords.latitude + ' , ' + this.userCurrentPosition.coords.longitude;
//                 }
//                 msg += ' )';
//                 this.locStartOptions.push({
//                     value: 1,
//                     label: msg,
//                     selected: false
//                 });
//             }
//             this.locStartOptions.push({value: 2, label: 'Choose a location to start', selected:false});
//
//     }
//     buildVehiclePlOptions() {
//
//         this.vehicleOptions = [];
//         this.vehicleOptions.push({value: -1, label: 'Choose a vehicle', selected:false});
//         this.vehicleOptions.push({value: 1, label: 'White Toyota RC20', selected:true});
//         this.vehicleOptions.push({value: 2, label: 'Black Toyota RC18', selected:false});
//         this.selectedVehicleId = 1;
//         let vehicleRow = this.vehicleOptions.find(x => x.value == this.selectedVehicleId);
//         if(vehicleRow) {
//             vehicleRow.selected = true;
//             if(!this.advancedOptions) {
//                 this.advancedOptions = {
//                     vehicleId : this.selectedVehicleId,
//                     vehicleDesc: vehicleRow.label
//                 }
//             } else {
//                 this.advancedOptions.vehicleId = this.selectedVehicleId;
//                 this.advancedOptions.vehicleDesc = vehicleRow.label;
//             }
//             console.log('advanced options1,',JSON.parse(JSON.stringify(this.advancedOptions)));
//         }
//
//     }
//     /**
//      *
//      * @param title
//      * @param msg
//      * @param variant
//      */
//     showToast(title, msg, variant) {
//         const evt = new ShowToastEvent({
//             title: title,
//             message: msg,
//             variant: variant
//         });
//         this.dispatchEvent(evt);
//     }
//
//     injectThemeOverrideStyle() {
//         let target = this.template.querySelector('.create-fake-overrides-class');
//         if (target) {
//             target.appendChild(this._themeOverrideStyle);
//             this._injectedThemeOverrides = true;
//         }
//     }
//
//     removeLastInstance(badtext, str) {
//         let charpos = str.lastIndexOf(badtext);
//         if (charpos<0) return str;
//         let ptone = str.substring(0,charpos);
//         let pttwo = str.substring(charpos+(badtext.length));
//         return (ptone+pttwo);
//     }
//     /**
//      * Loads font awesome js and css for fonts not available in SLDS.
//      * @todo only load what is needed. we are probably loading too much here.
//      */
//     loadFontAwesome() {
//         Promise.all([
//             loadScript(this, FONT_AWESOME + '/js/all.js'),
//             loadStyle(this, FONT_AWESOME + '/css/all.css'),
//         ])
//             .then(() => {
//                 console.log( 'debug',' === loaded font awesome ===');
//             })
//             .catch(error => {
//                 console.error(error);
//                 console.error(error.message);
//             });
//     }
//     buildThemeOverrideCss() {
//         //  border-bottom: 1px solid rgb(221,219,218)
//         let css = '';
//         css += 'div.slds-box_border > lightning-card > article > div.slds-card__header.slds-grid { ';
//         css += ' background-color: rgb(243,242,242)!important;padding:0!important;';
//         css += '}';
//         css += 'div.slds-box_border > lightning-card > article > div.slds-card__header.slds-grid > header {'
//         css += ' padding:.75em ';
//         css += '} ';
//         css += 'div.slds-box_border > lightning-card > article > div.slds-card__body {';
//         css += ' padding-left:.85em!important;padding-right:.85em!important';
//         css += '}';
//         css += ' .slds-form-element__label {color:black;font-weight:bold}'
//         this._themeOverrideStyle = document.createElement('style');
//         this._themeOverrideStyle.innerText = css;
//     }
//
//     shapeSteps() {
//         let newSteps = [];
//         let i = 0;
//         let steps = this.optimizationResults.routes[0].steps;
//         this.wayPointGeos = [];
//         let havePushed = false;
//
//         steps.forEach(step => {
//
//             let newStep = Object.assign({},step);
//             newStep.accountName = step.accountName;
//             newStep.accountId = step.accountId;
//             newStep.type = step.type;
//             newStep.totalTravelTimeFormatted = step.totalTravelTimeFormatted;
//             newStep.latLng = step.lat + ' , '+step.lng;
//             newStep.timeOfArrival = step.timeOfArrival;
//             newStep.dtOfArrival = step.dtOfArrival;
//             newStep.dServiceTimeMinutes = step.dServiceTimeMinutes;
//             newStep.vehicleDesc = step.vehicleDesc;
//
//             let geoTemp =  Object.assign({},{latitude: step.lat, longitude: step.lng});
//
//             if(newStep.type === 'START') {
//                 this.originGeo = geoTemp;
//             } else if (newStep.type === 'END') {
//                 this.destinationGeo = geoTemp;
//             } else {
//
//                 //if(!havePushed) {
//                     if (geoTemp.longitude && geoTemp.latitude) {
//                         this.wayPointGeos.push(geoTemp);
//                         havePushed = true;
//                     }
//                 //}
//             }
//             newSteps.push(newStep);
//             i++;
//         });
//         this.steps = newSteps;
//         console.log('--- steps=', JSON.parse(JSON.stringify(this.steps)));
//     }
//
//     shapeUnassigned() {
//         let newUnassigneds = [];
//         let i = 0;
//         let unassigneds = this.optimizationResults.unassigned;
//         if(unassigneds && Array.isArray(unassigneds)) {
//             unassigneds.forEach(unassigned => {
//
//                 let newUnassigned = Object.assign({}, unassigned);
//                 newUnassigned.accountName = unassigned.accountName;
//                 newUnassigned.accountId = unassigned.accountId;
//                 newUnassigned.latLng = unassigned.location[1] + ' , ' + unassigned.location[0];
//                 newUnassigneds.push(newUnassigned);
//                 i++;
//             });
//         }
//         this.unassigned = newUnassigneds;
//         //.steps = newSteps;
//         console.log('--- unassigneds=', JSON.parse(JSON.stringify(newUnassigneds)));
//     }

}