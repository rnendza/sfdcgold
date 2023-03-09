import {LightningElement} from 'lwc';

export default class GeoTabAdminContainer extends LightningElement {
    _activeTabValue = 'tab_utils_home';

    handleTabClick(evt) {
        this._activeTabValue = evt.target.value;
    }
}