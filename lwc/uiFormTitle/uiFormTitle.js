/**
 * Created by rnend on 7/29/2021.
 */

import {api, LightningElement} from 'lwc';

export default class UiFormTitle extends LightningElement {

    @api formTitle;     // required
    @api formSubtitle;
    @api iconName       = 'standard:account';
    @api iconClass      = '';
    @api iconSize       = 'medium';
    @api subTitleTextClass = 'accel-card_subtitle';
    @api subTitleTextStyle = '';

}