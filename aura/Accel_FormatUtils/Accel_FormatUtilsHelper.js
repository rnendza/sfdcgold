({
    formatDto: {value: null,message:''},
    /**
     * Looks at infoToFormat object and takes prefix, value, and fixed properties and formats number.
     * prefix is something like '$' or any symbol to prefix the number with. value is the actual numeric value.
     * fixed is the number of decimal points after the decimal.
     *
     * @param cmp
     * @param evt
     * @returns {*} an object with properties value and message (if applicable)
     * @todo ensure fixed is working in all use cases!
     */
    formatNumericValue: function (cmp,evt) {
        let params = evt.getParam('arguments');
        let infoToFormat = params.infoToFormat;
        if(!infoToFormat) {
            this.formatDto.message = 'infoToFormat param not found.';
            return this.formatDto;
        }
        let prefix = infoToFormat.prefix;
        let value = infoToFormat.value;
        let fixed = infoToFormat.fixed;
        var num = value;
        if (num === null) {
            return null;
        } // terminate early
        if (num === 0) {
            return '0';
        } // terminate early
        fixed = (!fixed || fixed < 0) ? 0 : fixed; // number of decimal places to show
        var b = (num).toPrecision(2).split("e"), // get power
            k = b.length === 1 ? 0 : Math.floor(Math.min(b[1].slice(1), 14) / 3), // floor at decimals, ceiling at trillions
            c = k < 1 ? num.toFixed(0 + fixed) : (num / Math.pow(10, k * 3)).toFixed(0 + fixed), // divide by power
            d = c < 0 ? c : Math.abs(c), // enforce -0 is 0
            e = d + ['', 'K', 'M', 'B', 'T'][k]; // append power
        var ret = '';
        if (prefix) {
            ret = prefix + e;
        } else {
            ret = e;
        }
        this.formatDto.value = ret;
        return this.formatDto;
    }
});