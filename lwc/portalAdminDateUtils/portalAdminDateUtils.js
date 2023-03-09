export const dateUtils = {

    get yesterdaysDateISO() {
        return this.yesterdaysDate.toISOString().slice(0,10);
    },
    get yesterdaysDate() {
        let today = new Date();
        today.setDate(today.getDate() - 1);
        return today;
    },
    get todaysDateISO() {
        return this.todaysDate.toISOString().slice(0,10);
    },
    get todaysDate() {
        return new Date();
    },
    getMonthsBackDateISO(d,monthsBack) {
        d.setMonth(d.getMonth() - monthsBack);
        return d.toISOString().slice(0,10);
    }
}