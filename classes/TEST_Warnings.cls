@IsTest
private class TEST_Warnings {

    @IsTest static void test_checkQueryLimits_Positive() {
        Warnings.checkQueryLimits(10000);
    }

    @IsTest static void test_checkQueryLimits_Negative() {
        Exception customException;
        try {
            Warnings.checkQueryLimits( Warnings.MAX_QUERY_ROWS + 1);
        } catch ( Warnings.QueryLimitException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.QueryLimitException);
    }

    @IsTest static void test_checkResponseDto_Negative() {
        Exception customException;
        ResponseDto dto = new ResponseDto();
        try {
            Warnings.checkResponseDto(dto);
        } catch ( Warnings.EndUserMessageException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.EndUserMessageException);
        System.assert(customException.getMessage() != null);
    }

    @IsTest static void test_checkSObjectUpdateValidity_Positive() {
        Warnings.checkObjectUpdateValidity( new User( Id=UserInfo.getUserId() ) );
    }

    @IsTest static void test_checkSObjectUpdateValidity_Negative() {
        Exception customException;
        try {

            Warnings.checkObjectUpdateValidity( new User() );
        } catch ( Warnings.InvalidUpdateParamsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidUpdateParamsException);
    }

    @IsTest static void test_checkContactSettingsParams_Positive() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('muni name',1);
        Account account = TestUtils.buildAccount('account name',munis[0].id);
        insert account;
        Contact contact = TestUtils.buildContact(account.id, 'Contact lastname');
        insert contact;

        Test.startTest();
        Warnings.checkContactSettingsParams( contact.Id, new Set<String>{'Name'} );
        Test.stopTest();
    }

    @IsTest static void test_checkContactSettingsParams_Negative() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('muni name',1);
        Account account = TestUtils.buildAccount('account name',munis[0].id);
        insert account;
        Contact contact = TestUtils.buildContact(account.id, 'Contact lastname');
        insert contact;

        Test.startTest();
        Exception customException;
        try {
            Warnings.checkContactSettingsParams( null, new Set<String>{'Name'} );
        } catch ( Warnings.InvalidContactSettingsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidContactSettingsException);

        try {
            Warnings.checkContactSettingsParams( contact.Id, null );
        } catch ( Warnings.InvalidContactSettingsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidContactSettingsException);

        try {
            Warnings.checkContactSettingsParams( contact.Id, new Set<String>() );
        } catch ( Warnings.InvalidContactSettingsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidContactSettingsException);

        Test.stopTest();
    }

    @IsTest static void test_checkForValidCommunityUser_Positive() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('muni name',1);
        Account account = TestUtils.buildAccount('account name',munis[0].id);
        insert account;
        Contact contact = TestUtils.buildContact(account.id, 'Contact lastname');
        insert contact;

        Test.startTest();
        Warnings.checkForValidCommunityUser( UserInfo.getUserId(), contact.Id  );
        Test.stopTest();
    }

    @IsTest static void test_checkForValidCommunityUser_Negative() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('muni name',1);
        Account account = TestUtils.buildAccount('account name',munis[0].id);
        insert account;
        Contact contact = TestUtils.buildContact(account.id, 'Contact lastname');
        insert contact;

        Test.startTest();

        Exception customException;
        try {
            Warnings.checkForValidCommunityUser( UserInfo.getUserId(),null );
        } catch ( Warnings.InvalidCommunityUserException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidCommunityUserException);

        Test.stopTest();
    }

    @IsTest static void test_checkCommunityUserSettingsParams_Positive() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('muni name',1);
        Account account = TestUtils.buildAccount('account name',munis[0].id);
        insert account;
        Contact contact = TestUtils.buildContact(account.id, 'Contact lastname');
        insert contact;

        Test.startTest();
        Warnings.checkCommunityUserSettingsParams( UserInfo.getUserId(), contact.Id, new Set<String> {'Name'}  );
        Test.stopTest();
    }

    @IsTest static void test_checkCommunityUserSettingsParams_Negative() {
        List<Municipality__c> munis = TestUtils.createMunicipalities('muni name',1);
        Account account = TestUtils.buildAccount('account name',munis[0].id);
        insert account;
        Contact contact = TestUtils.buildContact(account.id, 'Contact lastname');
        insert contact;

        Test.startTest();

        Exception customException;
        try {
            Warnings.checkCommunityUserSettingsParams( null, UserInfo.getUserId(), new Set<String> {'Name'}  );
        } catch ( Warnings.InvalidParamsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidParamsException);

        try {
            Warnings.checkCommunityUserSettingsParams( contact.Id, null, new Set<String> {'Name'}  );
        } catch ( Warnings.InvalidParamsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidParamsException);

        try {
            Warnings.checkCommunityUserSettingsParams( contact.Id, UserInfo.getUserId(), null  );
        } catch ( Warnings.InvalidParamsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidParamsException);

        try {
            Warnings.checkCommunityUserSettingsParams( contact.Id, UserInfo.getUserId(), new Set<String>()  );
        } catch ( Warnings.InvalidParamsException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidParamsException);

        Test.stopTest();
    }

    @IsTest static void test_checkSObjectType_Negative() {
        Exception customException;
        try {
            Warnings.checkSObjectType(null,'Account');
        } catch ( Warnings.InvalidSObjectApiNameException ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.InvalidSObjectApiNameException);
    }

    @IsTest static void test_checkGeoDistanceParams_Negative() {

        Exception customException;
        GeoCoordinates originGeo = new GeoCoordinates();
        Set<GeoCoordinates> waypointGeos = new Set<GeoCoordinates>{originGeo};
        String unit = 'mi';

        try {
            Warnings.checkGeoDistanceParams(null,waypointGeos,unit);
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);

        GeoCoordinates sampleGeo = new GeoCoordinates(Double.valueOf(41.7957554),Double.valueOf(-88.0744586));
        try {
            Warnings.checkGeoDistanceParams(sampleGeo,waypointGeos,null);
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);

        try {
            originGeo.latitude = null;
            Warnings.checkGeoDistanceParams(originGeo,waypointGeos,unit);
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);

        try {
            originGeo.longitude = null;
            Warnings.checkGeoDistanceParams(originGeo,waypointGeos,unit);
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);

        try {
            Warnings.checkGeoDistanceParams(sampleGeo,waypointGeos,'bogusunit');
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);


        try {
            originGeo.latitude = 1;
            originGeo.longitude = null;
            Warnings.checkGeoDistanceParams(originGeo,waypointGeos,'mi');
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);


        try {
            originGeo.latitude = 1;
            originGeo.longitude = 2;
            GeoCoordinates geo2 = originGeo.clone();
            GeoCoordinates geo3 = originGeo.clone();
            geo2.latitude = null;
            geo3.longitude = null;
            waypointGeos.add(geo2);
            waypointGeos.add(geo3);
            Warnings.checkGeoDistanceParams(originGeo,waypointGeos,'mi');
        } catch ( Warnings.GeoCoordinatesException  ex ) {
            customException = ex;
        }
        System.assert(customException instanceof Warnings.GeoCoordinatesException);

    }
}