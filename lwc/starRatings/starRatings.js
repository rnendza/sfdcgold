import {LightningElement,track,api} from 'lwc';
import {loadScript, loadStyle} from "lightning/platformResourceLoader";
import FONT_AWESOME from  '@salesforce/resourceUrl/font_awesome_v5_free';

export default class StarRatings extends LightningElement {

    _hasRendered = false;
    _ratingCount = 0;
    _emptyStarClass = 'far fa-star fa-1x rating-star';
    _fullStarClass = 'fas fa-star fa-1x rating-star';

    @track ratingStars = [];

    // Public / Reactive Required Properties.
    @api totalStars = 1;
    @api
    get ratingCount() {
        return this._ratingCount;
    }
    set ratingCount(value) {
        this._ratingCount = value;
    }

    /**
     * Build initial rating array.
     */
    constructor() {
        super();
    }

    connectedCallback() {
        this.buildRatingStars();
        this.fillRatingStars();
    }

    /**
     * load Font Awesome.
     * @todo is this loading for every row or is it cached?
     */
    renderedCallback() {
        if(!this._hasRendered) {
            this._hasRendered = true;
            this.loadFontAwesome();
        }
    }

    /**
     * Takes the total number of starts and loops that number of times to build an array so that we can iterate
     * in the html.
     */
    buildRatingStars() {
        for(let i = 0; i<this.totalStars; i++) {
            let rating = {idx: i, ratingClass : this._emptyStarClass};
            this.ratingStars.push(rating);
        }
        console.warn('---------------- built array:'+this.ratingStars);
    }

    /**
     * Toggles css classes to determine if the star should be filled or not.
     * Anything less then or equal the rating count gets filled.
     */
    fillRatingStars() {
        if(this.ratingStars && Array.isArray(this.ratingStars) && this.ratingStars.length > 0) {
            this.ratingStars.forEach((x,idx) =>  {
                if(idx <= this.ratingCount) {
                    x.ratingClass = this._fullStarClass
                } else {
                    x.ratingClass = this._emptyStarClass;
                }
            });
        }
    }

    loadFontAwesome() {
        Promise.all([
            loadScript(this, FONT_AWESOME + '/js/all.js'),
            loadStyle(this, FONT_AWESOME + '/css/all.css'),
        ])
            .then(() => {
                console.log('fa loaded!');
            })
            .catch(error => {
                console.error(error);
                console.error(error.message);
            });
    }
}