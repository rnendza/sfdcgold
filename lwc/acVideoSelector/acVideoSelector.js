import {api, LightningElement, track} from 'lwc';

export default class AcVideoSelector extends LightningElement {

    @api
    get videoOptions() { return this._videoOptions; }
    set videoOptions( val ) { this._videoOptions = val; }

    @track videoSelectedValue = '';

    _videoOptions = [  //--- @todo pull from custom object?
        {label: '-- Select One --', value: ''},
        {label: 'Test Video - 398955336 ', value: '398955336'}
    ];
    /**
     * Fire off custom DOM event to parent passing vimeo video Id.
     * @param event
     */
    handleVideoPlChange(event) {
        this.videoSelectedValue = event.detail.value;
        if (this.videoSelectedValue !== '') {
            this.dispatchEvent(new CustomEvent('videoselected', {bubbles: false, detail: {value: this. videoSelectedValue}}));
        }
    }
}