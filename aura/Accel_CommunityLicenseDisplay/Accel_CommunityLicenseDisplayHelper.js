({
    validateDates: function (cmp, helper) {
        var dojLicense = cmp.get('v.dojLicense');
        var currentTime = new Date();
        var expDate = new Date(dojLicense.Expiration_Date__c);
        if(dojLicense && dojLicense.Expiration_Date__c) {
            dojLicense.bExpired  = expDate < currentTime;
        }

    }
})