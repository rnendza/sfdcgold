import {LightningElement,api,track} from 'lwc';

export default class AccelCompactLayoutOnHover extends LightningElement {
    @api sObjectName;
    @api hoverTitle;
    @api
    get recordId(){
        return this._recordId;
    }
    set recordId(value) {
        this._recordId = value;
    }

    @api
    get topmargin(){
        return this._top;
    }

    set topmargin(value) {
        this._top = value;
    }

    @api
    get leftmargin(){
        return this._left;
    }

    set leftmargin(value) {
        this._left = value;
    }


    @track _recordId;
    @track _top = 50;
    @track _left = 50;

    constructor() {
        super();
        console.log('---> co layout!');
    }

    get showOnHover() {
        return this.recordId && this.sObjectName;
    }

    get boxClass() {
        return `background-color:white; top:${this._top - 280}px; left:${this._left}px`;
    }

}