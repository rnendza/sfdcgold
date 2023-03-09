({
    doInit : function(cmp, event, helper) {
        var iTimePeriod = cmp.get('v.timePeriod');
        switch (iTimePeriod) {
            case 4:
                cmp.set('v.hpdDetail', cmp.get('v.location.hpd4Week'));
                break;
            case 8:
                cmp.set('v.hpdDetail', cmp.get('v.location.hpd8Week'));
                break;
            case 12:
                cmp.set('v.hpdDetail', cmp.get('v.location.hpd12Week'));
                break;
            case 52:
                cmp.set('v.hpdDetail', cmp.get('v.location.hpdTtm'));
                break;
            default:
                console.log('ooops');
        }
    }
})