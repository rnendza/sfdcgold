export const plValuesHelper = {

    getActionOptions() {
        let options = [];
        options.push({label: 'Apex Class Changed',value: 'changedApexClass'});
        options.push({label: 'Apex Class Created',value: 'createdApexClass'});
        options.push({label: 'Data Export Requested',value: 'export'});
        options.push({label: 'Deploy Change Sets',value: 'deployedchangeset'});
        options.push({label: 'Email Status Verified',value: 'changedUserEmailVerifiedStatusVerified'});
        options.push({label: 'Formula Field - Custom Changed',value: 'changedCFFormulaCustom'});
        options.push({label: 'Flow Activated',value: 'activatedinteractiondefinition'});
        options.push({label: 'Flow Version Activated',value: 'activatedinteractiondefversion'});
        options.push({label: 'Flow Version Deactivated',value: 'deactivatedinteractiondefversion'});
        options.push({label: 'Lightning Page Changed',value: 'changedFlexiPage'});
        options.push({label: 'Lightning Page Created',value: 'createdFlexiPage'});
        options.push({label: 'Group Created',value: 'createdgroup'});
        options.push({label: 'Group Membership - Changed',value: 'groupMembership'});
        options.push({label: 'LWC Changed',value: 'changedLightningWebComponent'});
        options.push({label: 'LWC Created',value: 'createdLightningWebComponent'});

        options.push({label: 'Package - Installed',value: 'installedpackagingapp'});

        options.push({label: 'Picklist Changed',value: 'changedUniPicklist'});
        options.push({label: 'Profile - Standard - FLS Changed',value: 'profileFlsChangedStandard'});
        options.push({label: 'Profile - Custom - FLS Changed',value: 'profileFlsChangedCustom'});
        options.push({label: 'Record Type Activated',value: 'activateRecordTypeCustom'});
        options.push({label: 'Track Field History Changed',value: 'entity_history_field_tracked'});
        options.push({label: 'User - Perm Set Assignment',value: 'PermSetAssign'});
        options.push({label: 'User - Perm Set License Created',value: 'PermSetCreateNoLicense'});
        options.push({label: 'User - Perm Set FLS Changed',value: 'PermSetFlsChanged'});
        options.push({label: 'User - Password Changed',value: 'changedpassword'});
        options.push({label: 'User - Profile Changed',value: 'changedprofileforuser'});
        options.push({label: 'User - Role Changed',value: 'changedroleforuser'});
        options.push({label: 'User - Role Added',value: 'changedroleforuserfromnone'});
        options.push({label: 'Validation Removed',value: 'removedValidation'});
        options.push({label: 'Validation Rule Changed',value: 'changedValidationFormula'});
        options.push({label: 'VisualForce Page Created',value: 'createdApexPage'});
        options.push({label: 'Workflow Rule Created',value: 'createdflowtrigger'});
        options.push({label: 'Workflow Rule - Created',value: 'createdworkflowrule'});

        return options;
    },
}