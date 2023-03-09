@IsTest
public class clTESTUTILS {

    public static final String PROCESSOR                    = 'PROCESSOR';
    public static final String COLLECTOR                    = 'COLLECTOR';
    public static final String SFDCMUNIS                    = 'munis';
    public static final String PUBLIC_GROUP_NAME            = 'test_cl_public_group';
    public static final String SFDCACCOUNTS                 = 'accounts';
    public static final String SFDCASSETS                   = 'assets';
    public static final String SFDCROUTES                   = 'routes';
    public static final String SFDCROUTEACCOUNTS            = 'routeaccounts';
    public static final String SFDCRTSCHEDULES              = 'routeschedules';
    public static final String SFDCRTSCHACCOUNTS            = 'routescheduleaccounts';
    public static final STRING SFDCRPS                      = 'routeprocessingsheets';
    public static final String SFDCPUBLICGROUPS             = 'clpublicgroups';
    public static final String SFDCMETERREADINGS            = 'meterreadings';
    public static final String BASE_DATA_CREATION_TIME      = 'basedatacreationtime';
    public static final String DEFAULT_COLLECTION_TYPE      = 'Regular - RT & VGT';
    public static final String  DEFAULT_PROCESSING_LOC      = 'DEV TEST 1';
    public static final String  DEFAULT_IMPORTER_HELP_FILE_TITLE = 'CL - Importer User Guide';
    public static final Integer DEFAULT_STOP_NUMBER         = 1;
    public static final Integer NUM_ACCTS_PER_MUNI          = 2;
    public static final Integer NUM_ROUTES                  = 3;
    public static final Integer NUM_CYCLES_PER_ROUTE        = 2;
    public static final Integer NUM_VGTS_PER_ACCOUNT        = 2;
    public static final String  ASSET_BV_TYPE_JCM           = 'JCM';

    /**
     * Reuses general test utils to create non cash logistics specific data. ie. accounts assets etc..
     * @return  A Map of String (Map Key) => Object (Data)
     */
    public static Map<String,Object> createAllNonClData() {
        Datetime start = System.now();
        List<Municipality__c> munis = new List<Municipality__c>{createMuni()};
        List<Account> accounts = createAccounts(munis);
        List<Asset> assets = createTestAssets(accounts,NUM_VGTS_PER_ACCOUNT);
        Datetime endTime = System.now();
        Long millis = endTime.getTime() - start.getTime();

        Map<String,Object> m = new Map<String,Object>{
                SFDCMUNIS               => munis,
                SFDCACCOUNTS            => accounts,
                SFDCASSETS              => assets,
                BASE_DATA_CREATION_TIME => millis
        };
        return m;
    }
    /**
     * Creates Routes / Schedules / RPS / Meter Data.
     *
     * @param mBaseData Base account data used to create CL Data with.
     * @return  A Map of String (Map Key) => Object (Data)
     */
    public static Map<String,Object> createEnd2EndRouteData(Map<String,Object> mBaseData) {

        Datetime start = System.now();
        Map<String,User> mUsers = clTESTUTILS.createClUsers();
        Map<String, List<GroupMember>> mGroupMembers = clTESTUTILS.createClGroupAndMembers(PUBLIC_GROUP_NAME,mUsers.values());
        System.assert(!mGroupMembers.isEmpty());

        User uCollector = mUsers.get(clTESTUTILS.COLLECTOR);

        List<Account> accounts  = (List<Account>)mBaseData.get(clTESTUTILS.SFDCACCOUNTS);
        List<Municipality__c> munis = (List<Municipality__c>)mBaseData.get(clTESTUTILS.SFDCMUNIS);
        List<Asset> assets = (List<Asset>)mBaseData.get(clTESTUTILS.SFDCASSETS);
        System.assert(!accounts.isEmpty());

        List<Route__c> routes   = clTESTUTILS.createRoutes(NUM_ROUTES,NUM_CYCLES_PER_ROUTE);
        System.assertEquals(routes.size(),NUM_ROUTES * NUM_CYCLES_PER_ROUTE);

        List<Route_Account__c> routeAccounts = clTESTUTILS.createRouteAccounts(routes,accounts);
        System.assertEquals(routeAccounts.size(),NUM_ROUTES * NUM_CYCLES_PER_ROUTE *  accounts.size());

        List<Route_Schedule__c> routeSchedules =
                clTESTUTILS.createRouteSchedules(routes,Date.today().addDays(1),Date.today(),uCollector.Id);

        List<Route_Schedule__c> todayRss = clTESTUTILS.createRouteSchedules(routes,Date.today(),Date.today().addDays(-1),uCollector.Id);
        routeSchedules.addAll(todayRss);
        System.debug('---today rss='+todayRss);
        //  Note: We are creating a current route schedule and prev route schedule for each route schedule.
        //System.assertEquals(routeSchedules.size() / 2,routes.size());
        System.assertEquals(routeSchedules.size() / 4,routes.size());


        List<Route_Schedule_Account__c> routeScheduleAccounts =
                clTESTUTILS.createRouteScheduleAccounts(routeSchedules);
        //System.assertEquals(routeScheduleAccounts.size() / 2, routeAccounts.size());
        System.assertEquals(routeScheduleAccounts.size() / 4, routeAccounts.size());

        //@todo here
        List<Route_Processing_Sheet__c> routeProcessingSheets = clTESTUTILS.createRps(routeSchedules);
        List<Meter_Reading__c> meterReadings = createMeterReadings(routeProcessingSheets,assets);


        Datetime endTime = System.now();
        Long millis = endTime.getTime() - start.getTime();

        Map<String,Object> m  = new Map<String,Object>{
                SFDCROUTES          => routes,
                SFDCROUTEACCOUNTS   => routeAccounts,
                SFDCRTSCHEDULES     => routeSchedules,
                SFDCRTSCHACCOUNTS   => routeScheduleAccounts,
                SFDCRPS             => routeProcessingSheets,
                SFDCMETERREADINGS   => meterReadings,
                SFDCPUBLICGROUPS    => mGroupMembers
        };
        //  ==== Various timers in an attempt to differentiate NON CL Automation vs. CL Automation.
        String msg = '';
        msg = '\nmunis: '+munis.size() + '\naccounts: '+accounts.size()+'\n';
        msg += 'assets:'+assets.size()+'\n';
        msg += 'Elapsed Time: '+(Long)mBaseData.get(BASE_DATA_CREATION_TIME) + ' milliseconds to create.\n';
        System.debug('\n\n---> SFDC BASE TEST DATA <----'+msg);

        msg = '\nroutes: '+routes.size() + '\nrouteaccounts: '+routeAccounts.size()+'\n';
        msg+= 'routeschedules: '+routeSchedules.size() + '\nroutescheduleaccounts: '+routeScheduleAccounts.size()+'\n';
        msg+= 'rps: '+routeProcessingSheets.size() + '\n'+'meterreadings: '+meterReadings.size() + '\n';
        msg += 'Elapsed Time: '+millis + ' milliseconds to create.\n';
        System.debug('\n\n---> CL TEST DATA <----'+msg);
        return m;
    }

    public static Municipality__c createMuni() {
        return createMunis(1)[0];
    }

    public static List<Municipality__c> createMunis(Integer iNumMunis) {
        return TestUtils.createMunicipalities('testaccellmuni',2);
    }

    /**
     * Create bare bone accounts with CL Specific Info.
     *
     * @param munis A List of munis to associated the accounts to.
     * @return      A List of newly inserted accounts.
     */
    public static List<Account> createAccounts(List<Municipality__c> munis) {
        List<Account> accounts = new List<Account>();

        for(Municipality__c municipality : munis) {
            for(Integer i = 0; i< NUM_ACCTS_PER_MUNI; i++) {

                Account account =
                        TestUtils.buildAccount('accel test acct:'+i + 'a', municipality.id,'Accel Account');
                account.X1_Fill_Level__c = 1;
                account.X5_Fill_Level__c = 5;
                account.X20_Fill_Level__c = 20;
                account.X50_Fill_Level__c = 50;
                account.X100_Fill_Level__c = 100;
                accounts.add(account);
            }
        }
        insert accounts;
        System.assert(!accounts.isEmpty());
        return accounts;
    }

    public static List<Asset> createTestAssets(List<Account> accounts, Integer iNumPerAccount) {
        List<Asset> assets = new List<Asset>();

        for(Account account : accounts) {
            for(Integer i = 0; i<iNumPerAccount; i++) {
                Asset asset = TestUtils.buildAsset(account.name + ' asset ' + i, account.id, 'VGT');
                asset.BV_Type__c = ASSET_BV_TYPE_JCM;
                assets.add(asset);
            }
        }
        insert assets;
        return assets;
    }

    public static List<Route__c> createRoutes(Integer iNum, Integer iNumCycles) {
        List<Route__c> routes = new List<Route__c>();
        for(Integer i = 0; i<iNum; i++) {
            for(Integer x = 0; x < iNumCycles; x++) {
                routes.add(new Route__c(Name = 'TEST Route ' + iNum, Cycle_Number__c = x, Processing_Location__c = DEFAULT_PROCESSING_LOC));
            }
        }
        insert routes;
        return routes;
    }

    public static List<Route_Account__c> createRouteAccounts(List<Route__c> routes, List<Account> accounts) {
        List<Route_Account__c> ras = new List<Route_Account__c>();
        for(Route__c route: routes) {
            Integer i = 1;
            for (Account account : accounts) {
               ras.add(new Route_Account__c(Route__c = route.Id, Account__c = account.Id, Stop_Number__c = i));
                i++;
            }
        }
        insert ras;
        System.debug('---> num route accounts='+ras.size());
        return ras;
    }

    public static List<Route_Schedule__c> createRouteSchedules(List<Route__c> routes, Date collectionDate, Date fillDate,Id collectorId) {

        List<Route_Schedule__c> routeSchedules = new List<Route_Schedule__c>();

        // add a previous schedule as well
        Set<Date> collectionDates = new Set<Date>{collectionDate};
        collectionDates.add(collectionDate.addMonths(-1)); // just randomly set prev schedule 1 month back.

        for(Route__c route: routes) {
            for(Date colDate : collectionDates) {
                Route_Schedule__c routeSchedule = new Route_Schedule__c();
                routeSchedule.Route__c = route.Id;
                routeSchedule.Name = route.Name;
                routeSchedule.Route_Collection_Date__c = colDate;
                routeSchedule.Route_Fill_Date__c = colDate.addDays(-1);
                routeSchedule.User__c = collectorId;
                routeSchedule.Collector_1__c = collectorId;
                routeSchedule.Assigned_Driver__c = collectorId;
                routeSchedule.Processing_Location__c = route.Processing_Location__c;
               // System.debug('---> unit test creating rs='+routeSchedule);
                routeSchedules.add(routeSchedule);
            }
        }
        insert routeSchedules;
        return routeSchedules;
    }

    public static List<Route_Schedule_Account__c> createRouteScheduleAccounts(List<Route_Schedule__c> routeSchedules) {

        Set<Id>  routeIds = new Set<Id>();
        Map<Id,Set<Route_Account__c>>  routeId_RSAs = new Map<Id,Set<Route_Account__c>>();

        for(Route_Schedule__c routeSchedule: routeSchedules) {
            routeIds.add(routeSchedule.Route__c);
        }
        List<Route_Account__c> routeAccounts = [
            SELECT  Id,Route__c,Account__c,
                    X1_Fill_Level__c,
                    X5_Fill_Level__c,
                    X20_Fill_Level__c,
                    X50_Fill_Level__c,
                    X100_Fill_Level__c,
                    Stop_Number__c
            FROM    Route_Account__c
            WHERE   Route__c IN :routeIds
        ];

        for(Route_Account__c routeAccount : routeAccounts) {
            if(!routeId_RSAs.containsKey(routeAccount.Route__c)) {
                routeId_RSAs.put(routeAccount.Route__c, new Set<Route_Account__c>{routeAccount});
            } else {
                Set<Route_Account__c> ras = routeId_RSAs.get(routeAccount.Route__c);
                ras.add(routeAccount);
            }
        }
        List<Route_Schedule_Account__c> rsas= new List<Route_Schedule_Account__c>();

        for(Route_Schedule__c routeSchedule : routeSchedules) {
            Set<Route_Account__c> ras = routeId_RSAs.get(routeSchedule.Route__c);
            for(Route_Account__c routeAccount : ras) {
                Route_Schedule_Account__c rsa   = new Route_Schedule_Account__c();
                rsa.Route_Schedule__c           = routeSchedule.Id;
                rsa.Account__c                  = routeAccount.Account__c;
                rsa.Collection_Type__c          = DEFAULT_COLLECTION_TYPE;
                rsa.Stop_Number__c              = routeAccount.Stop_Number__c;
                rsas.add(rsa);
            }
        }
        insert rsas;
        return rsas;
    }

    public static List<Route_Processing_Sheet__c> createRps(List<Route_Schedule__c> routeSchedules ) {
        List<Route_Processing_Sheet__c> routeProcessingSheets = new List<Route_Processing_Sheet__c>();

        Map<Id,Route_Schedule__c> m = new Map<Id,Route_Schedule__c>([
           SELECT Id,Route_Collection_Date__c,Processing_Location__c,
                 (
                         SELECT Id,Route_Schedule__c, Account__c,Stop_Number__c,Collection_Type__c
                         FROM   Route_Schedule_Accounts__r
                 )
           FROM   Route_Schedule__c
           WHERE  Id IN :routeSchedules
        ]);
        for(Route_Schedule__c routeSchedule : m.values()) {
            List<Route_Schedule_Account__c> routeScheduleAccounts = routeSchedule.Route_Schedule_Accounts__r;
            for(Route_Schedule_Account__c routeScheduleAccount : routeScheduleAccounts) {
                Route_Processing_Sheet__c rps = new Route_Processing_Sheet__c();
                rps.Route_Schedule__c = routeSchedule.Id;
                rps.Account__c = routeScheduleAccount.Account__c;
                rps.Collection_Date__c = routeSchedule.Route_Collection_Date__c;
                rps.Collection_Type__c = routeScheduleAccount.Collection_Type__c;
                rps.Stop_Number__c =  routeScheduleAccount.Stop_Number__c;
                rps.Route_Schedule_Account__c = routeScheduleAccount.Id;
                rps.Processing_Location__c = routeSchedule.Processing_Location__c;
                rps.Processing_Process_Status__c = 'Processing Incomplete';
                System.debug('---> unit test creating rps='+rps);
                routeProcessingSheets.add(rps);
            }
        }
        insert routeProcessingSheets;
        List<Route_Processing_Sheet__c> rpss = [
                SELECT  Id,Collection_Date__c,Processing_Location__c,Route_Schedule__r.Route_Collection_Date__c
                FROM    Route_Processing_Sheet__c
                WHERE   Collection_Date__c = TODAY
        ];
        for(Route_Processing_Sheet__c rps : rpss) {
            System.debug('---> unit test today rps='+rps + ' col date='+rps.Route_Schedule__r.Route_Collection_Date__c);
        }
        return routeProcessingSheets;


    }

    public static List<Meter_Reading__c> createMeterReadings(List<Route_Processing_Sheet__c> routeProcessingSheets, List<Asset> machines) {
        List<Meter_Reading__c> meterReadings = new List<Meter_Reading__c>();

        for(Route_Processing_Sheet__c rps : routeProcessingSheets) {
            for(Asset machine: machines) {
                Meter_Reading__c meterReading = new Meter_Reading__c();
                meterReading.Route_Processing_Sheet__c = rps.Id;
                meterReading.Asset__c = machine.Id;
                meterReading.BV_Type__c = machine.BV_Type__c;
                meterReadings.add(meterReading);
            }
        }
        System.debug('---------> attempting to insert: '+meterReadings.size() + ' meter readings');
        insert meterReadings;

        //  We have to query again to get the autonumber name field.
        meterReadings = [
                SELECT Id, Route_Processing_Sheet__c, Asset__c, Name, Account_DBA_Name__c
                FROM   Meter_Reading__c
                WHERE  Id IN :meterReadings
        ];
        return meterReadings;
    }

    public static Map<String,List<GroupMember>> createClGroupAndMembers(String groupDevName, List<User> users) {
        Group gp = createClPublicGroup(groupDevName);
        Map<String,List<GroupMember>> m = createClPublicGroupMembers(gp.DeveloperName,users);
        return m;
    }

    public static Group createClPublicGroup(String groupName) {
        String devName = groupName.replaceAll(' ','_');
        Group publicGroup = new Group(
                Name = groupName,
                DeveloperName = devName,
                Type = 'Regular'
        );
        insert publicGroup;
        return publicGroup;
    }

    public static Map<String,List<GroupMember>> createClPublicGroupMembers(String groupDevName, List<User> users) {

        Map<String,List<GroupMember>> m = new Map<String,List<GroupMember>>();

        Group publicGroup  = [SELECT Id, DeveloperName FROM Group WHERE DeveloperName = :groupDevName];
        List<GroupMember> gpMembers = new List<GroupMember>();
        for(User user : users) {
            gpMembers.add(new GroupMember(GroupId = publicGroup.Id, UserOrGroupId = user.Id));
        }
        System.runAs(new User(Id= UserInfo.getUserId())) {
            insert gpMembers;
        }
        m.put(groupDevName,gpMembers);
        return m;
    }

    public static Map<String,User> createClUsers() {
        Map<String,User> m = new Map<String,User>();
        m.put(COLLECTOR,createUserForTest('collectortest@cltest.com','CL - Route Collector'));
        m.put(PROCESSOR,createUserForTest('processortest@cltest.com','CL - Route Processor'));
        return m;
    }

    public static Map<String,User> getClUserS() {
        Map<String,User> m = new Map<String,User>();

        List<User> users = [
                SELECT Id, UserName,Profile.Name
                FROM   User
                WHERE  USerName IN ('collectortest@cltest.com','processortest@cltest.com')
        ];
        for(User user : users) {
            if(user.Profile.Name == 'CL - Route Collector') {
                m.put(COLLECTOR,user);
            } else {
                m.put(PROCESSOR,user);
            }
        }
        return m;
    }

    public static User createUserForTest(String uname,String profileName) {

        User user = new User();
        user.emailencodingkey='UTF-8';
        user.languagelocalekey='en_US';
        user.localesidkey='en_US';
        user.timezonesidkey='America/Chicago';
        user.Alias = TestUtils.generateRandomString(5);
        user.email = uname;
        user.lastname = TestUtils.generateRandomString(10);
        user.username = uname;
        user.ProfileId = [select id from Profile where Name = :profileName].Id;
        user.put(clRouteScheduleSvc.REGION_FIELD_NAME, clTESTUTILS.DEFAULT_PROCESSING_LOC);
//        user.Processing_Location__c = clTESTUTILS.DEFAULT_PROCESSING_LOC;

        insert user;
        return user;
    }

    public static CL_User_Setting__c createUserSetting(User user) {
        return createUserSetting(user,'VGT');
    }

    public static CL_User_Setting__c createUserSetting(User user,String machineType) {
        CL_User_Setting__c userSetting = new CL_User_Setting__c(
                Name = user.name + ' setting',
                User__c = user.Id,
                Selected_Machine_Type__c = machineType
        );
        insert userSetting;
        return userSetting;
    }
    /**
     * @todo make dynamic in regard to getting the value of processing locations
     */
    public static List<Route_Import__c> createClRouteImportRecords() {
        List<Route_Import__c> routeImports = new List<Route_Import__c>();
        Set<String> regions = new Set<String>{'DEV TEST 1','Burr Ridge','Tinley Park'};
        for(String region : regions) {
            Route_Import__c routeImport = new Route_Import__c(Name = region, Region__c = region, Active__c = true);
            routeImports.add(routeImport);
        }
        insert routeImports;
        return routeImports;
    }

    public static List<ContentVersion> createFiles(List<Meter_Reading__c> meterReadings) {
        return createMeterFiles(meterReadings,null);
    }

    public static List<ContentVersion> createMeterFiles(List<Meter_Reading__c> meterReadings,String redemptionImageType) {

        List<ContentVersion> contentVersions = new List<ContentVersion>();
        redemptionImageType = redemptionImageType != '' ? redemptionImageType : null;

        for(Meter_Reading__c meterReading : meterReadings) {
            contentVersions.add(new ContentVersion (    //  SDFC Black magic.. inserts contentDocument as well.
                    Title = meterReading.Name,
                    PathOnClient = meterReading.Name+'_image.jpg',
                    Cash_Logistics_Meter_Reading__c = true,
                    Redemption_Image_Type__c = redemptionImageType,
                    Description = meterReading.Name,
                    VersionData = Blob.valueOf('A pretty pretty picture'),
                    IsMajorVersion = true
            ));
        }
        insert contentVersions;

        Map<Id, ContentDocument> documents = new Map<Id, ContentDocument>([
                SELECT Id, Title, ParentId, LatestPublishedVersionId FROM ContentDocument WHERE Title LIKE 'MTR%'
        ]);
        System.assert(!documents.isEmpty());

        Map<String,ContentDocument> mDocs = new Map<String,ContentDocument>();
        for(ContentDocument doc : documents.values()) {
            mDocs.put(doc.title,doc);
        }

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for(Meter_Reading__c meterReading : meterReadings ) {
            contentDocumentLinks.add( new ContentDocumentLink(
                    LinkedEntityId = meterReading.Id,
                    ContentDocumentId = mDocs.get(meterReading.Name).Id,
                    ShareType =  'V',
                    Visibility = 'AllUsers'
            ));
        }
        insert contentDocumentLinks;

        List<ContentDistribution> contentDistributions = new List<ContentDistribution>();
        Integer i = 0;
        for(ContentVersion contentVersion : contentVersions) {
            contentDistributions.add( new ContentDistribution(
                    ContentVersionId = contentVersion.Id,
                    Name = contentVersion.Title,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = true,
                    PreferencesAllowOriginalDownload = true,
                    RelatedRecordId = meterReadings[i].Id
            ));
            i++;
        }
        insert contentDistributions;
        return contentVersions;
    }
    public static List<ContentVersion> createRpsFiles(Route_Processing_Sheet__c rps,Set<String> redemptionImageTypes) {

        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for(String redemptionImageType : redemptionImageTypes) {
            contentVersions.add(new ContentVersion (    //  SDFC Black magic.. inserts contentDocument as well.
                    Title = rps.Name,
                    PathOnClient = rps.Name + '_'+redemptionImageType+'_image.jpg',
                    Cash_Logistics_Meter_Reading__c = true,
                    Redemption_Image_Type__c = redemptionImageType,
                    Description = rps.Name,
                    VersionData = Blob.valueOf('A pretty pretty picture'),
                    IsMajorVersion = true
            ));
        }
        insert contentVersions;

        Map<Id, ContentDocument> documents = new Map<Id, ContentDocument>([
                SELECT Id, Title, ParentId, LatestPublishedVersionId FROM ContentDocument]);
        System.assert(!documents.isEmpty());

        Map<String,ContentDocument> mDocs = new Map<String,ContentDocument>();
        for(ContentDocument doc : documents.values()) {
            mDocs.put(doc.title,doc);
        }

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for(ContentDocument cd : documents.values()) {
            contentDocumentLinks.add(new ContentDocumentLink(
                    LinkedEntityId = rps.Id,
                    ContentDocumentId = cd.Id,
                    ShareType = 'V',
                    Visibility = 'AllUsers'
            ));
        }
        insert contentDocumentLinks;

        List<ContentDistribution> contentDistributions = new List<ContentDistribution>();
        Integer i = 0;
        for(ContentVersion contentVersion : contentVersions) {
            contentDistributions.add( new ContentDistribution(
                    ContentVersionId = contentVersion.Id,
                    Name = contentVersion.Title,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = true,
                    PreferencesAllowOriginalDownload = true,
                    RelatedRecordId = rps.Id
            ));
            i++;
        }
        insert contentDistributions;
        return contentVersions;
    }

    public static List<ContentVersion> createRouteImportFiles(List<Route_Import__c> routeImports) {

        List<ContentVersion> contentVersions = new List<ContentVersion>();

        for(Route_Import__c routeImport : routeImports) {
            contentVersions.add(new ContentVersion (    //  SDFC Black magic.. inserts contentDocument as well.
                    Title = routeImport.Name,
                    PathOnClient = Route_Import__c.Name + '_test_import.csv',
                    Cash_Logistics_Upload_Type_fileupload__c = clContentVersionTriggerHandler.ROUTE_IMPORT_RESULT_SUCCESS,
                    Description = RouteImport.Name + ' test import desc ',
                    VersionData = Blob.valueOf('"A","data1"'),
                    IsMajorVersion = true
            ));
        }

        insert contentVersions;

        Map<Id, ContentDocument> documents = new Map<Id, ContentDocument>([
                SELECT Id, Title, ParentId, LatestPublishedVersionId FROM ContentDocument]);
        System.assert(!documents.isEmpty());

        Map<String,ContentDocument> mDocs = new Map<String,ContentDocument>();
        for(ContentDocument doc : documents.values()) {
            mDocs.put(doc.title,doc);
        }

        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for(Route_Import__c routeImport : routeImports ) {

            Id contentDocId =  mDocs.get(routeImport.Name).Id;
            System.debug('--> contentDocId='+contentDocId);

            contentDocumentLinks.add( new ContentDocumentLink(
                    LinkedEntityId = routeImport.Id,
                    ContentDocumentId = contentDocId,
                    ShareType =  'V',
                    Visibility = 'AllUsers'
            ));
        }
        insert contentDocumentLinks;


        List<ContentDistribution> contentDistributions = new List<ContentDistribution>();
        Integer i = 0;
        for(ContentVersion contentVersion : contentVersions) {
            contentDistributions.add( new ContentDistribution(
                    ContentVersionId = contentVersion.Id,
                    Name = contentVersion.Title,
                    PreferencesAllowViewInBrowser = true,
                    PreferencesLinkLatestVersion = true,
                    PreferencesNotifyOnVisit = true,
                    PreferencesAllowOriginalDownload = true,
                    RelatedRecordId = routeImports[i].Id
            ));
            i++;
        }
        insert contentDistributions;
        return contentVersions;
    }
}