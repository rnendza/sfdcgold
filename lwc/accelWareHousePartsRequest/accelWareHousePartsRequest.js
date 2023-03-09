/**
 * Created by CedricN on 1/30/2023.
 */

import {LightningElement,track,wire,api} from 'lwc';

import getWarehouse from '@salesforce/apex/WarehouseRequest.getWarehouseList';
import getListView from '@salesforce/apex/WarehouseRequest.getListView';
import getAssets from '@salesforce/apex/WarehouseRequest.getAssetList';
//import getProductRequests from '@salesforce/apex/WarehouseRequest.getProductReqList';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin} from "lightning/navigation";
import FORM_FACTOR from '@salesforce/client/formFactor';
import {getObjectInfos} from "lightning/uiObjectInfoApi";
import PRODUCT_REQUEST_OBJECT from '@salesforce/schema/ProductRequest';


export default class AccelWareHousePartsRequest extends NavigationMixin(LightningElement) {
    @api value;
    @api showEditForm;  // Used to toggle between showing the recordEditForm and search cmp and assets.
    @api disablePullToRefresh;
    @api prodReqList = [];
    @api showAssetSearch;
    @api selectedRecordId;
    @api type = 'Cage Request';
    @api cardTitle = 'Parts Request';
    @api cardIconName = 'standard:product_request'
    @api RecordTypeId;
    @api listViewId;
    @api maxQtyRequestedAllowed = 20;
    @api afterSaveListViewApiName = 'My_WH_Parts_Requests';
    @api sObjectApiName = 'ProductRequest';
    @api formRecordTypeName = 'Warehouse Request';
    @api submitButtonLabel = 'Create Product Request';
    

    // Variables to be passed to reusable lookup cmp.  Set as properties to allow cmp to be reusable for different applications.
    @api searchObjectApiName = 'Asset';
    @api searchObjectLabel = 'Asset';
    @api searchLabel = 'Asset #';
    @api searchIconName = 'standard:asset_object';
    @api searchFieldApiName = 'Name';
    @api searchOtherFieldApiName = 'Model__c';
    @api searchHelpText = 'Search for VGT or RT Asset by Asset #';
    @api searchParentFieldApiName = 'AccountId';
    @api searchRecordTypeFilter = '(\'VGT\', \'Redemption\')'; 

    @track allWarehouse;
    @track warehouseOptions;
    @track assetList = [];
    @track assetId = [];

    assetSelectedRecord;
    loaded;
    sObjectApiNames = [PRODUCT_REQUEST_OBJECT];
    

    @wire(getWarehouse, {})
    WiredgetWarehouse({ error, data }) {
        if(data) {
            try {
                this.allWarehouse = data;
                let options = [];
                options.push({label: '-- Select Warehouse --',value: '-1',selected: true})
                for (var key in data) {
                    options.push({ label: data[key].Name, value: data[key].Id });
                }
                this.warehouseOptions = options;
            } catch (error) {
                console.error('Error', error);
            }
        } else if (error) {
            console.error('Error', error);
        }
        this.getListViewId();
    }

    @wire(getObjectInfos, { objectApiNames: '$sObjectApiNames' })
    handleObjectInfo({ error, data}) {
        if (data) {
            this.setRecordTypeId(data);
        } else if (error) {
            console.error('Error', error);
        }
    }

    setRecordTypeId(results) {
        const productRequestObjectInfo = this.findObjectInfo(PRODUCT_REQUEST_OBJECT.objectApiName,results);
        this.RecordTypeId = this.getRecordTypeId(productRequestObjectInfo.result.recordTypeInfos,this.formRecordTypeName);
    }

    findObjectInfo(objectApiName,objectInfos) {
        if(objectInfos && objectInfos.results) {
            return objectInfos.results.find(x => x.result.apiName === objectApiName);
        }
    }

    getRecordTypeId(recordTypeInfos,recordTypeName) {
        if(recordTypeInfos && recordTypeName) {
            return Object.keys(recordTypeInfos).find(rti => recordTypeInfos[rti].name === recordTypeName);
        }
    }

    getListViewId() {
        
        getListView({ recordTypeName : this.afterSaveListViewApiName, sObjectApiName : this.sObjectApiName})
        .then( result => {
            this.listViewId = result;
        })
        .catch(error => {
            this.error = error;
        })
    }

    handleChange(event) {
        this.value = event.target.value;
        this.retrieveAssets();
        if(this.assetSelectedRecord != null) {
            this.template.querySelector('c-reusable-lookup').warehouseChanged();
        } 
    }

    // Most Likely update due to possibly only wanting a single asset
    retrieveAssets() {
        getAssets({ whId : this.value})
        .then( result => {
            for ( let k = 0; k<result.length; k++) {
                this.assetId.push(result[k].Id);
            }
            this.assetList = result;
            //this.retrieveProductRequests();
        })
        .catch(error => {
            this.error = error;
        })
        this.showAssetSearch = true;
    }

    // Most likely update to retrieve product requests for one single asset
    /*retrieveProductRequests() {
        getProductRequests({ recordIds : this.assetId })
        .then( result => {
            this.prodReqList = result;
        })
        .catch(error => {
            this.error = error;
        })
        this.showAssetSearch = true;
    }*/

    handleFormSubmit(event) {
        // Prevent default form submission and set behind the scenes fields before creating the record.
        event.preventDefault();
        const fields = event.detail.fields;
        fields.RecordTypeId	 = this.RecordTypeId;
        if(this.validateFields(fields)){
            this.template.querySelector('lightning-record-edit-form').submit(fields);
            if(FORM_FACTOR === 'Small') {
                setTimeout(function(){    window.location.reload(); }, 2000)
            }
        }
    }

    handleFormSuccess(event) {
        this.showSuccessToast();
    }

    handleFormError(event) {

    }

    handleValueSelectedOnAccount(event) {
        this.assetSelectedRecord = event.detail;
        this.selectedRecordId = event.detail.id;
    }

    handleValueDeSelectedOnAccount(event) {
        this.assetSelectedRecord = '';
    }

    handleClick() {
        this.showEditForm = true;
        this.loaded = true;
    }

    handleCloseClick() {
        //this.showEditForm = false;
        //this.showAssetSearch = true;
        // just for testing purposes
        setTimeout(function(){    window.location.reload(); }, 2000)

    }

    showSuccessToast() {
        const event = new ShowToastEvent({
            title: 'Success!',
            message: 'Product request has been created.',
            variant: 'success',
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
        this.handleListViewNavigation();
    }

    handleListViewNavigation() {
        this[NavigationMixin.Navigate]({
            type:'standard__objectPage',
            attributes: {
                objectApiName: 'ProductRequest',
                actionName: 'list'
            },
            state: {
                filterName: this.listViewId
            }
        });
    }

    handleLoad(event) {
        this.loaded = false;
    }

    validateFields(fields) {
        let allValid;
        let msg = '';
        if(fields.Quantity_Requested__c <1 || fields.Quantity_Requested__c > this.maxQtyRequestedAllowed) {
            msg += 'Quantity Requested must be between 1 and '+this.maxQtyRequestedAllowed;
        } else  {
            allValid = true;
        }
        if(!allValid) {
            const evt = new ShowToastEvent({
                title: '',
                message: msg,
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(evt);
        }
        return allValid;
    }

    get warehouseHelpText() {
        return 'The Warehouse in which the Asset exists.';
    }

}