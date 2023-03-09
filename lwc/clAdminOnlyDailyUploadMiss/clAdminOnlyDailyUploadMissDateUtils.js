export const dateUtils = {

    get yesterdaysDateISO() {
        return this.yesterdaysDate.toISOString().slice(0,10);
    },
    get yesterdaysDate() {
        let today = new Date();
        today.setDate(today.getDate() - 1);
        return today;
    },
    get todaysDatetimeISO() {
        return this.todaysDate.toISOString();
    },
    get todaysDate() {
        return new Date();
    },
    getDaysBackDateISO(d,daysBack) {
        d.setDate(d.getDate() - daysBack);
        return d.toISOString().slice(0,10);
    },
    getMonthsBackDateISO(d,monthsBack) {
        d.setMonth(d.getMonth() - monthsBack);
        return d.toISOString().slice(0,10);
    }

}