import {LightningElement, api,track } from 'lwc';

export default class DayNumberToName extends LightningElement {

    @track dayOfWeekAsString;

    @api
    get dayNumber() { return null; }
    set dayNumber(value) { this.dayOfWeekAsString = this.convertDayNumber(value); }

    convertDayNumber(dayNumb) {
        return dayNumb ?  ["Sun", "Mon", "Tues", "Wed", "Thurs", "Fri", "Sat"][dayNumb] : '';
    }
}