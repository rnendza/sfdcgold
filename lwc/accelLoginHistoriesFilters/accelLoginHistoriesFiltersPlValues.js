export const plValuesHelper = {

    getStatusOptions() {

        let options = [];
        options.push({label: 'Success',value: 'Success'});
        options.push({label: 'Multi-factor required',value: 'Multi-factor required'});
        options.push({label: 'Invalid Password',value: 'Invalid Password'});
        options.push({label: 'Failed: Computer activation required',value: 'Failed: Computer activation required'});
        options.push({label: 'Failed: API security token required',value: 'Failed: API security token required'});
        options.push({label: 'Password Lockout',value: 'Password Lockout'});
        options.push({label: 'User is Inactive',value: 'User is Inactive'});
        options.push({label: 'Invalid Password',value: 'Invalid Password'});
        return options;
    }
}