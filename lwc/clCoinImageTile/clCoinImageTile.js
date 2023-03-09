import {LightningElement,api} from 'lwc';

export default class ClCoinImageTile extends LightningElement {
    @api tileLabel = 'Coin Fill Levels';
    @api tileSize  = '5x';
}