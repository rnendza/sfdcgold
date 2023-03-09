({
    doInit: function(cmp,event,helper) {
        helper.initLocationDatatableColumns(cmp);
        helper.initLocationMonthDatatableColumns(cmp);
    },
    handleMonthSelectedEvent: function (cmp,event,helper) {
        var dateSelected = event.getParam("dateSelected");
        var accountIds = event.getParam("accountIds");
        cmp.set('v.totalPages',1);
        cmp.set('v.currentPageNumber',1);
        dateSelected = new Date(dateSelected);
        var hackedDate  =new Date(dateSelected.getFullYear(),dateSelected.getMonth(),dateSelected.getDate()+1);
        cmp.set('v.dateSelected',hackedDate);
        cmp.set('v.accountIds',accountIds);
        cmp.set('v.showMonthlyLocData',true);
        cmp.set('v.showAllLocData',false);
        helper.retrieveAllAccountMonthlyTotals(cmp,helper);
    },
    handleLocShareTotalsLoadedEvent: function (cmp, event, helper) {
        var splicedArray;
        var arr = event.getParam("locationMonthlyData");
        var freq = event.getParam("locationMonthlyFrequency");
        var desc = event.getParam("locationMonthlyDataDescription");
        cmp.set('v.locationDataDescription',desc);
        helper.log(cmp,'location monthly data','info',arr);

        if (!freq) {
            freq = 12;
        }
        //@TODO cleanup
        if (freq !== -1) {
            if (arr.length > freq) {
                splicedArray = arr.slice(0, freq);
                cmp.set('v.totalPages',1);
                cmp.set('v.currentPageNumber',1);
                cmp.set('v.locationData', splicedArray);
                cmp.set('v.locationRawData',splicedArray);

                cmp.set("v.totalPages", Math.ceil(splicedArray.length/cmp.get("v.pageSize")));
            } else {
                cmp.set('v.totalPages',1);
                cmp.set('v.currentPageNumber',1);
                cmp.set('v.locationData', arr);
                cmp.set('v.locationRawData',arr);
                cmp.set("v.totalPages", Math.ceil(arr.length/cmp.get("v.pageSize")));
            }
        } else {
            cmp.set('v.totalPages',1);
            cmp.set('v.currentPageNumber',1);
            cmp.set('v.locationData', arr);
            cmp.set('v.locationRawData',arr);
            cmp.set("v.totalPages", Math.ceil(arr.length/cmp.get("v.pageSize")));
        }
        helper.buildData(cmp,'v.locationRawData','v.locationData');

        cmp.set('v.showMonthlyLocData', false);
        cmp.set('v.showAllLocData', true);
    },
    updateLocationMonthTotalsColumnSorting: function(cmp,event,helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        var data = cmp.get('v.locationRawData');
        helper.sortData(cmp, data,fieldName, sortDirection,'v.locationData','v.locationRawData');
    },
    updateLocationBreakdownColumnSorting: function(cmp,event,helper) {
        var fieldName = event.getParam('fieldName');
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        var data = cmp.get('v.locationMonthlyRawData');
        helper.log(cmp,'calling sortData with fieldName='+fieldName + '.. direction='+sortDirection,'info',data);
        helper.sortData(cmp, data,fieldName, sortDirection,'v.locationMonthlyData','locationMonthlyRawData');
    },
    //@TODO handle these button clicks in more generic way ie. just call a generic helper method since we cant call
    //another controller method!
    onNext: function (component, event, helper) {
        var btnId = event.getSource().getLocalId();
        if(btnId) {
             var pageNumber = component.get("v.currentPageNumber");
             component.set("v.currentPageNumber", pageNumber + 1);
             var rawDataAttrName,dataAttrName;
             if(btnId === 'onNextBtnLocationData') {
                 rawDataAttrName    = 'v.locationRawData';
                 dataAttrName       = 'v.locationData';
             } else if (btnId === 'onNextBtnMonthlyData') {
                 rawDataAttrName = 'v.locationMonthlyRawData';
                 dataAttrName = 'v.locationMonthlyData';
             }
             helper.buildData(component, rawDataAttrName, dataAttrName);
         }
    },

    onPrev: function (component, event, helper) {
        var btnId = event.getSource().getLocalId();
        if(btnId) {
            var pageNumber = component.get("v.currentPageNumber");
            component.set("v.currentPageNumber", pageNumber - 1);
            var rawDataAttrName, dataAttrName;
            if (btnId === 'onPrevBtnLocationData') {
                rawDataAttrName = 'v.locationRawData';
                dataAttrName = 'v.locationData';
            } else if (btnId === 'onPrevBtnMonthlyData') {
                rawDataAttrName = 'v.locationMonthlyRawData';
                dataAttrName = 'v.locationMonthlyData';
            }
            helper.buildData(component, rawDataAttrName, dataAttrName);
        }
    },

    processMe: function (component, event, helper) {
        component.set("v.currentPageNumber", parseInt(event.target.name));
        helper.buildData(component,'v.locationRawData','v.locationData');
    },

    onFirst: function (component, event, helper) {
        var btnId = event.getSource().getLocalId();
        if(btnId) {
            component.set("v.currentPageNumber", 1);
            var rawDataAttrName, dataAttrName;
            if (btnId === 'onFirstBtnLocationData') {
                rawDataAttrName = 'v.locationRawData';
                dataAttrName = 'v.locationData';
            } else if (btnId === 'onFirstBtnMonthlyData') {
                rawDataAttrName = 'v.locationMonthlyRawData';
                dataAttrName = 'v.locationMonthlyData';
            }
            helper.buildData(component, rawDataAttrName, dataAttrName);
        }
    },

    onLast: function (component, event, helper) {
        var btnId = event.getSource().getLocalId();
        if(btnId) {
            component.set("v.currentPageNumber", component.get("v.totalPages"));
            var rawDataAttrName, dataAttrName;
            if (btnId === 'onLastBtnLocationData') {
                rawDataAttrName = 'v.locationRawData';
                dataAttrName = 'v.locationData';
            } else if (btnId === 'onLastBtnMonthlyData') {
                rawDataAttrName = 'v.locationMonthlyRawData';
                dataAttrName = 'v.locationMonthlyData';
            }
            helper.buildData(component, rawDataAttrName, dataAttrName);
        }
    }
})