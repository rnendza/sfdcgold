import { LightningElement, track, api } from 'lwc';

export default class UiMultiselect extends LightningElement {

    @api options;
    @api pillIcon;
    @api selectedValue;
    @api selectedValues = [];
    @api label;
    @api labelStyle = 'font-weight:bold';
    @api entityLabel;
    @api name;
    @api minChar = 2;
    @api disabled = false;
    @api multiSelect = false;
    @api customSelectClass;
    @api noSelectionMeansAll;
    @api autoCloseOnSelect;

    @track value;
    @track values = [];
    @track optionData;
    @track searchString;
    @track message;
    @track showDropdown = false;

    connectedCallback() {
        this.showDropdown = false;
        var optionData = this.options ? (JSON.parse(JSON.stringify(this.options))) : null;
        var value = this.selectedValue ? (JSON.parse(JSON.stringify(this.selectedValue))) : null;
        var values = this.selectedValues ? (JSON.parse(JSON.stringify(this.selectedValues))) : null;
        if(value || values) {
            var searchString;
            var count = 0;
            for(var i = 0; i < optionData.length; i++) {
                if(this.multiSelect) {
                    if(values.includes(optionData[i].value)) {
                        optionData[i].selected = true;
                        count++;
                    }
                } else {
                    if(optionData[i].value == value) {
                        searchString = optionData[i].label;
                    }
                }
            }
            if(this.multiSelect) {
                if(this.noSelectionMeansAll && count === 0) {
                    this.searchString = 'All ' + this.entityLabel + ' Selected';
                } else {
                    this.searchString = count + ' ' + this.entityLabel + ' Selected';
                }
            } else {
                this.searchString = searchString;
            }
        }
        this.value = value;
        this.values = values;
        this.optionData = optionData;
    }

    filterOptions(event) {
        this.searchString = event.target.value;
        if( this.searchString && this.searchString.length > 0 ) {
            this.message = '';
            if(this.searchString.length >= this.minChar) {
                var flag = true;
                for(var i = 0; i < this.optionData.length; i++) {
                    if(this.optionData[i].label.toLowerCase().trim().includes(this.searchString.toLowerCase().trim())) {
                        this.optionData[i].isVisible = true;
                        flag = false;
                    } else {
                        this.optionData[i].isVisible = false;
                    }
                }
                if(flag) {
                    this.message = "No results found for '" + this.searchString + "'";
                }
            }
            this.showDropdown = true;
        } else {
            this.showDropdown = false;
        }
    }



    selectItem(event) {
        var selectedVal = event.currentTarget.dataset.id;
        if(selectedVal) {
            var count = 0;
            var options = JSON.parse(JSON.stringify(this.optionData));
            for(var i = 0; i < options.length; i++) {
                if(options[i].value === selectedVal) {
                    if(this.multiSelect) {
                        if(this.values.includes(options[i].value)) {
                            this.values.splice(this.values.indexOf(options[i].value), 1);
                        } else {
                            this.values.push(options[i].value);
                        }
                        options[i].selected = options[i].selected ? false : true;
                    } else {
                        this.value = options[i].value;
                        this.searchString = options[i].label;
                    }
                }
                if(options[i].selected) {
                    count++;
                }
            }
            this.optionData = options;
            if(this.multiSelect) {
                if (this.noSelectionMeansAll && count === 0) {
                    this.searchString = 'All ' + this.entityLabel + ' Selected';
                } else {
                    this.searchString = count + ' ' + this.entityLabel + ' Selected';
                }
            }

            if(this.multiSelect) {
                event.preventDefault();
                if(this.autoCloseOnSelect) {
                    this.showDropdown = false;
                }
            } else {
                this.showDropdown = false;
            }

            this.dispatchEvent(new CustomEvent('select', {
                detail: {
                    'name' : this.name,
                    'payloadType' : 'multi-select',
                    'payload' : {
                        'value' : this.value,
                        'values' : this.values
                    }
                }
            }));

        }
    }

    showOptions() {
        if(this.disabled == false && this.options) {
            this.message = '';
            this.searchString = '';
            var options = JSON.parse(JSON.stringify(this.optionData));
            for(var i = 0; i < options.length; i++) {
                options[i].isVisible = true;
            }
            if(options.length > 0) {
                this.showDropdown = true;
            }
            this.optionData = options;
        }
    }
    handleNoResultsIconClick(evt) {
        this.blurEvent();
    }
    removePill(event) {
        let optionsRemoved = [];
        var value = event.currentTarget.name;
        var count = 0;
        var options = JSON.parse(JSON.stringify(this.optionData));
        for(var i = 0; i < options.length; i++) {
            if(options[i].value === value) {
                options[i].selected = false;
                optionsRemoved.push(options[i]);
                this.values.splice(this.values.indexOf(options[i].value), 1);
            }
            if(options[i].selected) {
                count++;
            }
        }
        this.optionData = options;
        if(this.multiSelect) {
            if(this.noSelectionMeansAll && count === 0) {
                this.searchString = 'All ' + this.entityLabel + ' Selected';
            } else {
                this.searchString = count + ' ' + this.entityLabel + ' Selected';
            }
        }

        if(optionsRemoved.length > 0) {
            console.log('---> firing event with payload.optionsRemoved',optionsRemoved);
            this.dispatchEvent(new CustomEvent('remove', {
                detail: {
                    'name': this.name,
                    'payloadType': 'multi-select',
                    'payload': {
                        'optionsRemoved': optionsRemoved
                    }
                }
            }));
        }
    }
    get selectClass() {
        return ' inputBox accel-multiselect-input ' + this.customSelectClass;
    }

    handleMouseOut(evt) {
        if(!this.searchString || this.searchString.includes('Selected')) {
            if(!this.autoCloseOnSelect) {
                this.showDropdown = false;
            }
        }
    }

    blurEvent() {
        var previousLabel;
        var count = 0;
        let payloadType = 'multi-select';
        for(var i = 0; i < this.optionData.length; i++) {
            if(this.optionData[i].value === this.value) {
                previousLabel = this.optionData[i].label;
            }
            if(this.optionData[i].selected) {
                count++;
            }
        }
        if(this.multiSelect) {

            if(this.noSelectionMeansAll && count === 0) {
                this.searchString = 'All ' + this.entityLabel + ' Selected';
            } else {
                this.searchString = count + ' ' + this.entityLabel + ' Selected';
            }
        } else {
            payloadType = 'select';
            this.searchString = previousLabel;
        }
        if(this.searchString.includes('Selected') || !this.searchString) {
            if(!this.autoCloseOnSelect || this.searchString) {
                this.showDropdown = false;
            }
        }

        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                'name' : this.name,
                'payloadType' : payloadType,
                'payload' : {
                    'value' : this.value,
                    'values' : this.values
                }
            }
        }));
    }
}