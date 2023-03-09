/**
 *
 */
export default class HpdComparison {

    constructor(hpdWrapper) {
        this.accountId              = hpdWrapper.accountId;
        this.dbaName                = hpdWrapper.accountName;
        this.accountNickname        = hpdWrapper.accountNickname;
        this.address                = hpdWrapper.accountPhysicalStreet;
        this.city                   = hpdWrapper.accountCity;
        this.month1Date             = null;
        this.month2Date             = null;
        this.startDateLocShare      = 0;
        this.endDateLocShare        = 0;
        this.startDateFundsIn       = 0;
        this.endDateFundsIn         = 0;
        this._fundsInPctChange      = 0;
        this._locSharePctChange     = 0;
        this.fundsInPctChange = 0;
        this.locSharePctChange = 0;
    }
    calcPctChanges() {
        this.calcFundsInPctChange();
        this.calcLocSharePctChange();
    }
    calcFundsInPctChange() {
        this._fundsInPctChange = (this.endDateFundsIn - this.startDateFundsIn) / this.startDateFundsIn;
        this.fundsInPctChange = (this.endDateFundsIn - this.startDateFundsIn) / this.startDateFundsIn;
    }
    calcLocSharePctChange() {
        this._locSharePctChange = (this.endDateLocShare - this.startDateLocShare) / this.startDateLocShare;
        this.locSharePctChange = (this.endDateLocShare - this.startDateLocShare) / this.startDateLocShare;
    }
}