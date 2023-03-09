({  responseDto : {
        isSuccess :     false,
        message:        '',
        severity:      'error',
        technicalMsg :  ''
    },
    /**
     * With credit to the sfdc monkey!.. this should be rewritten though as it's a bit out of date!
     * 
     * @param cmp
     * @param arr
     * @param fieldNames
     * @param columns
     * @returns {*}
     */
    convertArrayOfObjectsToCSV : function(cmp,arr,fieldNames, columns){
        /**
         * If a valid columns arg was passed, use it for the export column header label, also only use data that
         * was in the columns arg to export (allows us to differential export data from display data). If columns
         * not passed, just dump all dataTable data into export using js key props as column header.
         *
         * @param keys
         * @param columns
         * @param columnDivider
         * @return a comma deliminated csv string
         */
        function getColumnHeaderCsvString(keys, columns,columnDivider) {
            let csvString = '';
            if(keys && columns) {
                let headerData = [];
                keys.forEach((prop,idx) =>  {
                    const column = columns.find(x => x.fieldName === prop);
                    if(column && column.hasOwnProperty('label')) {
                        headerData.push(column.label);
                    }
                });
                if(headerData.length > 0) {
                    csvString += headerData.join(columnDivider);
                }
            } else {
                if(keys) {
                    csvString += keys.join(columnDivider);
                }
            }
            return csvString;
        }



        var csvStringResult, counter, keys, columnDivider, lineDivider;
        if (arr == null || !arr.length) {
            return null;
        }
        columnDivider = ',';
        lineDivider =  '\n';
        keys = fieldNames;

        csvStringResult = '';

        //--------------------------------------csvStringResult += keys.join(columnDivider);
        csvStringResult += getColumnHeaderCsvString(keys,columns,columnDivider);
        csvStringResult += lineDivider;
        try {
            for (var i = 0; i < arr.length; i++) {
                counter = 0;
                for (var sTempkey in keys) {
                    var skey = keys[sTempkey];
                    // add , [comma] after every String value,. [except first]
                    if (counter > 0) {
                        csvStringResult += columnDivider;
                    }
                    let data = arr[i][skey];
                    if(!data) {
                        data = '';
                    }
                    data = data.toString().replace('"','""'); // escape double quotes
                    data = data.toString().replace('#',''); // remove #
                    csvStringResult += '"' + data + '"';
                    counter++;
                }
                csvStringResult += lineDivider;
            }
        } catch (e) {
            console.error(e);
        }
        return csvStringResult;
    },
    /**
     *Can't get this to support IE yet.. locker service blocks most shit and doesn't give access to navigator object!
     * @param cmp
     * @param evt
     * @param helper
     */
    doExport: function (cmp, evt, helper) {
        let params = evt.getParam('arguments');
        let callback = params.callback;
        let fieldNames = params.fieldNames;
        let columns = params.columns;
        let arr = params.arrayToExport;
        let csv = helper.convertArrayOfObjectsToCSV(cmp, arr, fieldNames,columns);
        if (csv == null) {
            return this.responseDto;
        }
        let fileName = params.fileName;
        try {
            //console.log($A.get('$Browser'));
            // if (navigator.msSaveBlob) {
            //     alert('saving blob2');
            //     var blob = new Blob([csv], {type:  "text/plain;charset=utf-8;"});
            //     alert('saving blob');
            //     navigator.msSaveBlob(blob, fileName);
            // } else {
                let hiddenElement = document.createElement('a');
                hiddenElement.href = 'data:text/csv;charset=utf-8,' + encodeURI(csv);
                hiddenElement.target = '_self'; //
                hiddenElement.download = fileName;  // CSV file Name* you can change it.[only name not .csv]
                document.body.appendChild(hiddenElement); // Required for FireFox browser
                hiddenElement.click(); // using click() js function to download csv file
                this.responseDto.isSuccess = true;
                this.responseDto.message = arr.length + ' records exported successfully.';
                this.responseDto.severity = 'success';
            // }
        } catch (e) {
            alert(e);
        }
        callback(this.responseDto);
    },
    /**
     *
     * @param cmp
     * @param evt
     * @returns {boolean}
     */
    validateIncomingParams: function(cmp, evt) {
        let success = true;
        let params = evt.getParam('arguments');
        if (!params) {
            console.error('-- Accel_SimpleCsvExporter doExport.. no arguments found!');
            return false;
        }
        let values = params.arrayToExport;
        if (!values || values.length === 0) {
            return false;
        }
        let fieldNames = params.fieldNames;
        if(!fieldNames || fieldNames.length ===0) {
            return false;
        }
        let fileName = params.fileName;
        if(!fileName || fileName === '') {
            return false;
        }
        return success;
    }
});