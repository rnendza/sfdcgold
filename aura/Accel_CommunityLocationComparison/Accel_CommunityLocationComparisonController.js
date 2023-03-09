({
    doInit: function (cmp,evt,helper) {
        helper.formatUtils = cmp.find('formatUtils');
        helper.initDatatableColumns(cmp);
        helper.mockUserAccounts(cmp);
        helper.mockDatatableData(cmp);
        helper.mockLocTypes(cmp);
        helper.mockDistances(cmp);
        helper.mockMapInfo(cmp);
    },
    onChangeLocPlType: function (cmp, evt, helper) {
        var selectedPlVal = cmp.find("locTypeSelect").get("v.value");
        console.log('dev todo onchange locType value='+selectedPlVal);
    },
    scriptsLoaded: function (cmp,evt,helper) {
        if (typeof (echarts) == 'undefined') {
        } else {
            helper.mockChart(cmp);
        }
    },

})