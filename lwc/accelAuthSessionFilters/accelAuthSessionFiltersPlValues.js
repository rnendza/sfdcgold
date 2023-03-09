export const plValuesHelper = {

    getLoginTypePlOptions() {
        let options = [];
        options.push({label: 'AJAX Toolkit',value: 'AJAX Toolkit'});
        options.push({label: 'Apex Office Toolkit',value: 'Apex Office Toolkit'});
        options.push({label: 'AppExchange',value: 'AppExchange'});
        options.push({label: 'Application',value: 'Application'});
        options.push({label: 'AppStore',value: 'AppStore'});
        options.push({label: 'Certificate-based login',value: 'Certificate-based login'});

        options.push({label: 'Chatter Communities Eternal User Third Party SSO',value: 'Chatter Communities Eternal User Third Party SSO'});
        options.push({label: 'Chatter Communities External User',value: 'Chatter Communities External User'});
        options.push({label: 'Community',value: 'Community'});
        options.push({label: 'Customer Service Portal Third-Party SSO',value: 'Customer Service Portal Third-Party SSO'});
        options.push({label: 'Customer Service Portal',value: 'Customer Service Portal'});
        options.push({label: 'DataJunction',value: 'DataJunction'});

        options.push({label: 'DB Replication',value: 'DB Replication'});
        options.push({label: 'Employee Login to Community',value: 'Employee Login to Community'});
        options.push({label: 'Excel Integration',value: 'Excel Integration'});
        options.push({label: 'Help and Training',value: 'Help and Training'});
        options.push({label: 'HOTP YubiKey',value: 'HOTP YubiKey'});
        options.push({label: 'Lightning Login',value: 'Lightning Login'});

        options.push({label: 'Networks Portal API Only',value: 'Networks Portal API Only'});
        options.push({label: 'Offline Client',value: 'Offline Client'});
        options.push({label: 'Order Center',value: 'Order Center'});
        options.push({label: 'Other Apex API',value: 'Other Apex API'});
        options.push({label: 'Outlook Integration',value: 'Outlook Integration'});

        options.push({label: 'Partner Portal Third-Party SSO',value: 'Partner Portal Third-Party SSO'});
        options.push({label: 'Partner Portal',value: 'Partner Portal'});
        options.push({label: 'Partner Product',value: 'Partner Product'});
        options.push({label: 'Passwordless Login',value: 'Passwordless Login'});
        options.push({label: 'Remote Access 2.0',value: 'Remote Access 2.0'});
        options.push({label: 'Remote Access Client',value: 'Remote Access Client'});
        options.push({label: 'Sales Anywhere',value: 'Sales Anywhere'});

        options.push({label: 'Salesforce Outlook Integration',value: 'Salesforce Outlook Integration'});
        options.push({label: 'Salesforce.com Website',value: 'Salesforce.com Website'});
        options.push({label: 'SAML Chatter Communities External User SSO',value: 'SAML Chatter Communities External User SSO'});
        options.push({label: 'SAML Customer Service Portal SSO',value: 'SAML Customer Service Portal SSO'});
        options.push({label: 'SAML Idp Initiated SSO',value: 'SAML Idp Initiated SSO'});
        options.push({label: 'SAML Partner Portal SSO',value: 'SAML Partner Portal SSO'});
        options.push({label: 'SAML Sfdc Initiated SSO',value: 'SAML Sfdc Initiated SSO'});

        options.push({label: 'SAML Site SSO',value: 'SAML Site SSO'});
        options.push({label: 'Self-Service',value: 'Self-Service'});
        options.push({label: 'Signup',value: 'Signup'});
        options.push({label: 'Sync',value: 'Sync'});
        options.push({label: 'SysAdmin Switch',value: 'SysAdmin Switch'});
        options.push({label: 'Third Party SSO',value: 'Third Party SSO'});
        options.push({label: 'Validate',value: 'Validate'});

        return options;
    },
    getSessionTypeOptions() {
        let options = [];
        options.push({label: 'UI',value: 'UI'});
        options.push({label: 'API',value: 'API'});
        options.push({label: 'APIOnlyUser',value: 'APIOnlyUser'});
        options.push({label: 'Aura',value: 'Aura'});
        options.push({label: 'ChatterNetworks',value: 'ChatterNetworks'});
        options.push({label: 'ChatterNetworksAPIOnly',value: 'ChatterNetworksAPIOnly'});
        options.push({label: 'ChatterNetworksAPIOnlyOAuth',value: 'ChatterNetworksAPIOnlyOAuth'});
        options.push({label: 'Content',value: 'Content'});

        options.push({label: 'DataDownloadOnly',value: 'DataDownloadOnly'});
        options.push({label: 'LightningContainerComponent',value: 'LightningContainerComponent'});
        options.push({label: 'LivePreview',value: 'LivePreview'});
        options.push({label: 'Node',value: 'Node'});

        options.push({label: 'OauthApprovalUI',value: 'OauthApprovalUI'});
        options.push({label: 'Oauth2',value: 'Oauth2'});
        options.push({label: 'SamlOauthApprovalUi',value: 'SamlOauthApprovalUi'});
        options.push({label: 'SiteStudio',value: 'SiteStudio'});
        options.push({label: 'SitePreview',value: 'SitePreview'});
        options.push({label: 'STREAMING_API',value: 'STREAMING_API'});
        options.push({label: 'InternalServiceCall',value: 'InternalServiceCall'});
        options.push({label: 'SubstituteUser',value: 'SubstituteUser'});

        options.push({label: 'UnspecifiedType',value: 'UnspecifiedType'});
        options.push({label: 'UserSite',value: 'UserSite'});
        options.push({label: 'Visualforce',value: 'Visualforce'});
        options.push({label: 'WDC_API',value: 'WDC_API'});

        return options;
    }
}