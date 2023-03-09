({
    mockUserAccounts: function (cmp) {
        let accounts = [];
        for(let i = 0; i<20;i++) {
            let account = {Id:i,Name:'account '+i,ShippingStreet:'street '+i,ShippingCity: 'city '+i};
            accounts.push(account);
            cmp.set('v.userAccounts',accounts);
        }
    }
})