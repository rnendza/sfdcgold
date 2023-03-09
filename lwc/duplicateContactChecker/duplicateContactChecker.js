/**
 * Created by CedricN on 2/3/2022.
 */
import {LightningElement, wire, track, api} from 'lwc';


import { CurrentPageReference} from 'lightning/navigation';

import { getRecord, getFieldValue } from 'lightning/uiRecordApi';


//import {getRecord, getFieldValues} from "./lds";

import getContacts from '@salesforce/apex/DuplicateContact.DuplicateContactMethod';

import FirstName_FIELD from '@salesforce/schema/Portal_Contact_Request__c.First_Name__c';

import LastName_FIELD from '@salesforce/schema/Portal_Contact_Request__c.Last_Name__c';


//
export default class ContactDuplicate extends LightningElement {


    @track error;

    @api recordId;

    @track contacts;

    @track columns = [

        { label: 'Contact name',
    fieldName: 'nameUrl',
    type: 'url',
    typeAttributes: {label: { fieldName: 'Name' },
        target: '_blank'},
    sortable: true
},
        { label: 'First Name', fieldName: 'FirstName', type: 'text' },
        { label: 'Last Name', fieldName: 'LastName', type: 'text' },
        { label: 'Email', fieldName: 'Email'}
    ];

    @track opportunities = [];

   @track ShowTable = false;

   @track message;

    //  @wire(getRecord, { recordId: '$recordId', fields })
    PCR;




    @wire(getContacts, {records: '$recordId'})
    Dupes({error, data}){
        if (data) {

            if(JSON.stringify(data) != '[]') {

                this.ShowTable = true;


                let nameUrl;
                this.contacts = data.map(row => {
                    nameUrl = `/${row.Id}`;
                    return {...row, nameUrl}
                })

                //  this.contacts = data;
                this.error = undefined;

             //  alert(JSON.stringify(data));

            }

      /*  } else if (error) {
            this.error = error;
            this.contacts = undefined;
        }*/
        } else  {
            this.ShowTable = false;
            this.error = error;
            this.contacts = undefined;
        }
    }











}