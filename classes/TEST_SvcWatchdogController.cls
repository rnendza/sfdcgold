@isTest
private class TEST_SvcWatchdogController {

    public static String ADMINUNAME                             = 'acceltestadmin@accel.com';
    public static String CALLCENTERUNAME                        = 'callcenterdude@dude.com';
    public static final String SVC_WATCHDOG_PERM_SET_API_NAME   = 'Service_Watchdog_Component_Access';
    public static final String SVC_WATCHDOG_PERM_SET_LABEL      = 'Service Watchdog Component Access';

    public static  User uCallCenter = TestUtils.getUserForTest( CALLCENTERUNAME );
    public static  User uAdmin      = TestUtils.getUserForTest( ADMINUNAME );


    static {
        List<Profile> profiles = [SELECT Id from Profile where Name in :SvcWatchdogController.noAssignedResourceProfileNames];
        uCallCenter.profileId = profiles[0].id;
        update uCallCenter;
    }

    /**
     * Builds munis, accounts, work types, assets, operating hours, service territories, cases, work orders, and
     * service appointments and ties them all together.
     */
    @testSetup static void setup() {

        System.runAs(uCallCenter) {
            Test.startTest();  //merely to reset gov limits to get around cpu time
            TestSvcAppointmentDataParams params = new TestSvcAppointmentDataParams();
            TestUtils.createAllDataToServiceAppointments( params );
            TestUtils.createSvcWatchdogUtilityBarSettings(uCallCenter);
            List<Account> accounts = [SELECT Id, ShippingStreet, ShippingCity, ShippingState FROM Account ];
            Integer i = 0;
            for(Account account :accounts) {
                account.ShippingStreet = '123 xyz - '+i;
                account.ShippingCity   = 'Chicago - '+i;
                account.ShippingState  = 'IL';            //  Be careful of we implement state / country picklists!
            }
            update accounts;
            // Can't so as of Spring 2020  TestUtils.createPermissionSetAndAssignment(  SVC_WATCHDOG_PERM_SET_LABEL,SVC_WATCHDOG_PERM_SET_API_NAME,uCallCenter.Id );
            Test.stopTest();
        }
        //Move to be created by the running user which will be system admin (Spring 2020 PSA Insert Fix)
        TestUtils.createPermissionSetAndAssignment(  SVC_WATCHDOG_PERM_SET_LABEL,SVC_WATCHDOG_PERM_SET_API_NAME,uCallCenter.Id );
    }
    /**
     * Removes all cases and service appointments to ensure no data to display.
     *
     * (1)-- Test No Records to Observe.
     * (2)-- Test No Alerts to Display.
     */
    @isTest static void test_retrieveCasesMissingAssignedResources_NoData() {

        System.runAs(uAdmin) {
            List<Case> cases = [SELECT ID From Case];
            if(!cases.isEmpty()) {
                delete cases;
            }
            List<ServiceAppointment> serviceAppointments = [SELECT ID From ServiceAppointment];
            if(!serviceAppointments.isEmpty()) {
                delete serviceAppointments;
            }
            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveCasesMissingAssignedResources();
            //--(1)-- Ensure nothing is retrieved to observe.
            System.assert( ((List<SvcWatchdogWrapper>)dto.values
                    .get(SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE)).isEmpty() );
            //--(2)-- Ensure nothing is retrieved to alert.
            System.assert( ((List<SvcWatchdogWrapper>)dto.values
                    .get(SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_ALERT)).isEmpty() );

            Test.stopTest();
        }
    }
    /**
     * Tests that we have cases that have not been assigned a resource but are in progress and created by the correct
     * profile(s) but have not exceeded the threshhold limit.
     *
     * (1)-- Test The number of records to observe with a notification reason of 'No Assigned Resource'
     * eq the number of cases created.
     */
    @isTest static void test_retrieveCasesMissingAssignedResources_Under_Threshhold_Positive() {

        System.runAs(uCallCenter) {

            List<Case> cases = [
                    SELECT  Id
                    FROM    Case
                    WHERE   Status = :SvcWatchdogController.noAssignedResourceStatusToWatch
            ];
            Integer iNumTestCases = cases.size();

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveCasesMissingAssignedResourcesCacheable();
            system.assert(dto.isSuccess);
            List<SvcWatchdogWrapper> observeWraps = (List<SvcWatchdogWrapper>)dto.values
                    .get(SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE);
            //--(1)-- The number of records retrieved for observe wraps with a notification reason of No Assigned Resource
            //        is equal to the number of cases created.
            Integer iNumNoAssignedResources = 0;
            for(SvcWatchdogWrapper wrap : observeWraps) {
                if(wrap.notificationReason == 'No Assigned Resource') {
                    iNumNoAssignedResources++;
                }
            }
            System.assert( iNumNoAssignedResources == iNumTestCases );

            Test.stopTest();
        }
    }
    /**
     * @TODO doc this test.
     */
    @isTest static void test_populateAssignedResource_Positive() {

        System.runAs(uCallCenter) {

            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            Integer iLimitSas = 12;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
                    FROM    ServiceAppointment
                    LIMIT   :iLimitSas
            ];
            if(serviceAppointments.size() < iLimitSas) {
                iLimitSas = serviceAppointments.size(); // we needed to mod base test data creation to play nice with non bulk safe processes.
            }

            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;

            Datetime yesterday = Datetime.now().addDays(-1);
            Integer halfOfServiceAppointments = iLimitSas/2;
            for(Integer i=0; i<=halfOfServiceAppointments; i++ ) {
                ServiceAppointment sa = serviceAppointments[i];
                Test.setCreatedDate(sa.Work_Order__c, yesterday);
                Test.setCreatedDate(sa.Work_Order__r.CaseId, yesterday);
                Test.setCreatedDate(sa.Id, yesterday);
            }

            Test.startTest();
            //make sure there is an assigned resource
            List<Case> cases = [
                    SELECT  Id, Assigned_Resource__c
                    FROM    Case
            ];
            update cases;
            for(Case cse : cases) {
                cse.Assigned_Resource__c = uCallCenter.id;
            }
            update cases;

            ResponseDto dto = SvcWatchdogController.retrieveNotDispatched();
            System.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> notDispatchedWrapsAlerts = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);

            for(SvcWatchdogWrapper wrapAlert : notDispatchedWrapsAlerts) {
                System.assert(wrapAlert.assignedResourceName != null);
            }

            Test.stopTest();
        }
    }
    /**
     *
     */
    @isTest static void test_retrieveCasesMissingAssignedResources_Over_Threshhold_Positive() {

        System.runAs(uCallCenter) {
            List<Case> noArcases = [
                    SELECT  Id
                    FROM    Case
                    WHERE   Status = :SvcWatchdogController.noAssignedResourceStatusToWatch
            ];
            Integer iNumTestNoArCases = noArcases.size();

            Datetime yesterday = Datetime.now().addDays(-1);
            Integer i = 0;
            for(Case cse : noArCases ) {
                yesterday.addDays(i); //artificially increment so we can test cageage sort
                Test.setCreatedDate(cse.Id, yesterday);
                i++;
            }
            //--- for rejected and enroute (only do
            // a couple of service appointments)

            //--- only work with 2 as we don't want to change all of them.
            Integer iNumRejected = 2;
            Integer iNumAcceptedButNotEnroute = 2;
            List<ServiceAppointment> serviceAppointmentsRejected  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId
                    FROM    ServiceAppointment
                    WHERE   Work_Order__r.Case.Status = :SvcWatchdogController.noAssignedResourceStatusToWatch
                    LIMIT   :iNumRejected
            ];
            List<ServiceAppointment> serviceAppointmentsAcceptedButNotEnroute  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId
                    FROM    ServiceAppointment
                    WHERE   Work_Order__r.Case.Status = :SvcWatchdogController.noAssignedResourceStatusToWatch
                    AND     Id NOT IN :serviceAppointmentsRejected
                    LIMIT   :iNumAcceptedButNotEnroute
            ];
            if(serviceAppointmentsRejected.size() < iNumRejected) {
                iNumRejected = serviceAppointmentsRejected.size();
            }
            if(serviceAppointmentsAcceptedButNotEnroute.size() < iNumAcceptedButNotEnroute) {
                iNumAcceptedButNotEnroute = serviceAppointmentsAcceptedButNotEnroute.size();
            }

            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            //--------------------------     SET UP REJECTIONS --------------------------------------------------------
            Set<Id> caseIdsRejected = new Set<Id>();
            for(ServiceAppointment serviceAppointment : serviceAppointmentsRejected) {
                serviceAppointment.Status = 'Scheduled';
                caseIdsRejected.add(serviceAppointment.Work_Order__r.CaseId);
            }
            update serviceAppointmentsRejected;
            //--- must have the below for flow that clears the assigned resource.
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case where Id NOT IN :noArcases];
            for(Case cse : cases) {
                cse.Assigned_Resource__c = uAdmin.id;
            }
            update cases;
            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointmentsRejected) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointmentsRejected;

            for(ServiceAppointment serviceAppointment : serviceAppointmentsRejected) {
                serviceAppointment.Status = 'Rejected';
                serviceAppointment.Solution_Notes__c = 'FSL IS THE ANTICHRIST!';
            }
            update serviceAppointmentsRejected;

            //--------------------------     SET UP ACCEPTED BUT NOT ENROUTE   -----------------------------------------
            Set<Id> caseIdsAccepted = new Set<Id>();
            for(ServiceAppointment serviceAppointment : serviceAppointmentsAcceptedButNotEnroute) {
                serviceAppointment.Status = 'Scheduled';
                caseIdsAccepted.add(serviceAppointment.Work_Order__r.CaseId);
            }
            update serviceAppointmentsAcceptedButNotEnroute;

            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointmentsAcceptedButNotEnroute) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointmentsAcceptedButNotEnroute;

            for(ServiceAppointment serviceAppointment : serviceAppointmentsAcceptedButNotEnroute) {
                serviceAppointment.Status = 'Accepted';
                serviceAppointment.Solution_Notes__c = 'FSL IS THE ANTICHRIST - Accepted';
            }
            update serviceAppointmentsAcceptedButNotEnroute;

            for(ServiceAppointment serviceAppointment : serviceAppointmentsAcceptedButNotEnroute) {
                serviceAppointment.Time_Accepted__c  = System.now().addMinutes(-6);
            }
            update serviceAppointmentsAcceptedButNotEnroute;
            System.assert(serviceAppointmentsAcceptedButNotEnroute.size() == iNumAcceptedButNotEnroute);

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveCasesMissingAssignedResources();
            system.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> observeWraps = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_OBSERVE);
           //@TODO Check this  System.assert( observeWraps.size() == 0 );

            List<SvcWatchdogWrapper> alertWraps = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_ALERT);

            Integer  iTotalRejected = 0, iTotalNoAr = 0;

            for(SvcWatchdogWrapper wrap : alertWraps) {
                if(wrap.notificationReason == 'Rejected') {
                    iTotalRejected ++;
                    //@TODO Deprecate / Toggle with Custom Meta disabled switch. Jeff Nieman said this is not needed
                    //during a late phase of this feature.
//                } else if (wrap.notificationReason == 'Accepted But Not En Route') {
//                    iTotalAcceptedButNotEnroute ++;
                } else if (wrap.notificationReason == 'No Assigned Resource') {
                    iTotalNoAr ++;
                }
            }
            System.assertEquals(iNumRejected,iTotalRejected);
            //@TODO Deprecate / Toggle with Custom Meta disabled switch. Jeff Nieman said this is not needed
            //during a late phase of this feature.
            //System.assertEquals(iNumAcceptedButNotEnroute,iTotalAcceptedButNotEnroute);
            System.assertEquals(iNumTestNoArCases,iTotalNoAr);



            for(SvcWatchdogWrapper wrap : alertWraps ) {
                System.debug('rick wrap:'+wrap.caseAgeSeconds);
            }


            Test.stopTest();
        }
    }
    /**
     *
     */
    @isTest static void test_retrieveRejectedServiceCalls_Positive() {

        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            List<ServiceAppointment> serviceAppointments  = [
                SELECT  ID, Status, Solution_Notes__c, StatusCategory
                FROM    ServiceAppointment
                LIMIT   12
            ];
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
            }
            update serviceAppointments;
            //--- must have the below for flow that clears the assigned resource.
            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case];
            for(Case cse : cases) {
                cse.Assigned_Resource__c = uAdmin.id;
            }
            update cases;
            /*
             * Note the below is absolutely redic but apparently it's another "feature" of the great FSL Managed Package!
             * @see https://salesforce.stackexchange.com/questions/254779/fsl-service-appointment-test-class
             */
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = null; // huh? why???
            }
            update serviceAppointments;

            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Rejected';
                serviceAppointment.Solution_Notes__c = 'FSL IS THE ANTICHRIST!';
            }
            update serviceAppointments;

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveRejectedServiceCalls();
            System.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> rejectedWraps = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_REJECTED);
            List<SvcWatchdogWrapper> rejectedWrapsObservce = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_REJECTED_OBSERVE);
            System.assert( rejectedWraps.size() + rejectedWrapsObservce.size() == serviceAppointments.size());

            for(SvcWatchdogWrapper rejectedWrap : rejectedWraps) {
                System.assert(rejectedWrap.notificationReason == 'Rejected'); //@TODO Move to custom label
            }

            Test.stopTest();
        }
    }
    /**
     *
     */
    @isTest static void test_retrieveNotDispatchedServiceCalls_Positive() {

        System.runAs(uCallCenter) {
            //--- have to limit to 12 bc these processes  are not bulk safe and pretty much all over them blow
            //--- up on a bulk dml opp of 13 or greater!
            Integer iLimitSas = 12;
            List<ServiceAppointment> serviceAppointments  = [
                    SELECT  ID, Status, Solution_Notes__c, StatusCategory, Work_Order__r.CaseId, Work_Order__c
                    FROM    ServiceAppointment
                    LIMIT   :iLimitSas
            ];
            Set<Id> caseIds = new Set<Id>();
            if(serviceAppointments.size() < iLimitSas) {
                iLimitSas = serviceAppointments.size();
            }
            //@see https://accelentertainment--uat.lightning.force.com/lightning/n/FSL__Master_Settings
            for(ServiceAppointment serviceAppointment : serviceAppointments) {
                serviceAppointment.Status = 'Scheduled';
                caseIds.add(serviceAppointment.Work_Order__r.CaseId);
            }
            update serviceAppointments;

            List<Case> cases = [SELECT Id, Assigned_Resource__c FROM Case WHERE Id IN :caseIds];
            for(Case cse: cases) {
                cse.Assigned_Resource__c = uCallCenter.Id;
            }
            update cases;

            Datetime yesterday = Datetime.now().addDays(-1);
            Integer halfOfServiceAppointments = iLimitSas/2;
            for(Integer i=0; i<=halfOfServiceAppointments; i++ ) {
                ServiceAppointment sa = serviceAppointments[i];
                Test.setCreatedDate(sa.Work_Order__c, yesterday);
                Test.setCreatedDate(sa.Work_Order__r.CaseId, yesterday);
                Test.setCreatedDate(sa.Id, yesterday);
            }

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveNotDispatched();
            System.assert(dto.isSuccess);

            List<SvcWatchdogWrapper> notDispatchedWrapsAlerts = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_ALERT);
            List<SvcWatchdogWrapper> notDispatchedWrapsObserves = (List<SvcWatchdogWrapper>)dto.values.get(
                    SvcWatchdogController.MAP_KEY_WATCHDOG_WRAPPERS_NOTDISPATCHED_OBSERVE);

            System.debug(LoggingLevel.INFO,'---> dto alerts= '+notDispatchedWrapsAlerts);


          //----  System.assert( notDispatchedWrapsAlerts.size() + notDispatchedWrapsObserves.size() == serviceAppointments.size());

            for(SvcWatchdogWrapper wrap : notDispatchedWrapsAlerts) {
                System.assert(wrap.notificationReason == 'Unaccepted / Not Dispatched'); //@TODO Move to custom label
            }
            for(SvcWatchdogWrapper wrap : notDispatchedWrapsObserves) {
                System.assert(wrap.notificationReason == 'Unaccepted / Not Dispatched'); //@TODO Move to custom label
            }
            Test.stopTest();
        }
    }
    /**
     *
     */
    @isTest static void test_retrieveRunningUserData_Positive() {
        System.runAs(uCallCenter) {

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveRunningUserData();
            System.assert(dto.isSuccess);
            System.assert( ((Profile)dto.values
                    .get(SvcWatchdogController.MAP_KEY_USER_PROFILE_DATA)).Id == uCallCenter.ProfileId);

            Test.stopTest();
        }
    }
   /**
    *
    */
    @isTest static void test_retrieveNotificationSchedulingInfo_Positive() {

        String jobName = 'Accel_Schedule_Svc_Automated_Notifications';

        Integer intervalMinutes = 1;
        DateTime dtNow      = DateTime.now();
        Sch_QueueableSvcAutomationNotifications schJob = new Sch_QueueableSvcAutomationNotifications(intervalMinutes);
        String cronString = '' + dtNow.second()+' '+dtNow.addMinutes(1).minute()+' '+ dtNow.hour()+' '+dtNow.day()+' '+
                dtNow.month()+' ? '+dtNow.year();

        System.schedule(jobName + '-' + dtNow.format(), cronString, schJob);

        System.runAs(uCallCenter) {

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveNotificationSchedulingInfo(jobName);
            System.assert(dto.isSuccess);
            CronTrigger cronTrigger = ((List<CronTrigger>)dto.values.get(SvcWatchdogController.MAP_KEY_CRON_TRIGGERS))[0];

            System.assert(cronTrigger.CronJobDetail.Name.contains(jobName));

            Test.stopTest();
        }
    }


    /**
     *
     */
    @IsTest static void test_retrieveSvcWatchdogUtilityBarSettings_positive() {

        System.runAs(uCallCenter) {

            Test.startTest();

            ResponseDto dto = SvcWatchdogController.retrieveRunningUserData();
            Service_Utility_Bar_Config__c configSetting = (Service_Utility_Bar_Config__c)dto.values
                    .get(SvcWatchdogController.MAP_KEY_SVC_WATCHDOG_UTILITY_SETTINGS);

            System.assert(configSetting.Id != null);

            Test.stopTest();
        }
    }
    @IsTest static void test_IsUserInPermissionSet_Positive() {
        System.runAs(uCallCenter) {
            Test.startTest();
            //-- test that we retrieve every PSA available for the user and that one of thm was the one created in setup.
            System.assert(SvcWatchdogController.isUserInPermissionSet(SVC_WATCHDOG_PERM_SET_API_NAME));
            Test.stopTest();
        }
    }
    @IsTest static void test_IsUserInPermissionSet_Negative() {
        System.runAs(uCallCenter) {
            Test.startTest();
            System.assert(!SvcWatchdogController.isUserInPermissionSet('blah bogus'));
            Test.stopTest();
        }
    }
    /**
     */
    @isTest static void test_Additional_WrapperMethods() {
        //-- test no arg constructor.
        SvcWatchdogWrapper sww = new SvcWatchdogWrapper();
        //--- test show case tech notes nothing in there.
        System.assert(!sww.showCaseTechNotes);
        //--- test show case tech notes with a value.
        sww.caseTechNotes = 'bogus tech notes';
        System.assert(sww.showCaseTechNotes);

        System.assert(!sww.showAssignedResourceMobilePhone);
        sww.assignedResourceMobile = '555-555-5555';
        System.assert(sww.showAssignedResourceMobilePhone);

        sww.notificationReason = null;
        System.assert(!sww.isRejected);
        sww.notificationReason = 'Rejected';
        System.assert(sww.isRejected);
        System.assert(sww.iconName == SvcWatchdogWrapper.NOTIFICATION_ICON_REJECTED);

        System.assert(!sww.isNoAssignedResource);
        sww.notificationReason = 'No Assigned Resource';
        System.assert(sww.isNoAssignedResource);
        System.assert(sww.iconName == SvcWatchdogWrapper.NOTIFICATION_ICON_NOASSIGNEDRESOURCE);

        System.assert(!sww.isNotDispatched);
        sww.notificationReason ='Unaccepted / Not Dispatched';
        System.assert(sww.isNotDispatched);
        System.assert(sww.showServiceAppointmentNumber);
        System.assert(sww.iconName == SvcWatchdogWrapper.NOTIFICATION_ICON_NOTDISPATCHED);

        sww.caseServiceZone = 'YOU WILL DIE SERVICE ZONE';
        System.assert(sww.showCaseServiceZone);


        //  Test wrapper build account unique name.
        sww.accountDbaName = 'FOR THOSE ABOUT TO ROCK!';
        sww.buildAccountUniqueName();
        System.assert(sww.accountUniqueName == sww.accountDbaName);

        sww.accountStreet = '666 Hells Bells';
        sww.buildAccountUniqueName();
        System.assert(sww.accountUniqueName.contains(sww.accountStreet));

        sww.accountCity = 'POSEIDON';
        sww.buildAccountUniqueName();
        System.assert(sww.accountUniqueName.contains(sww.accountCity));

        sww.accountState = 'IL'; // @TODO beware if State and Country Pls implemented.
        sww.buildAccountUniqueName();
        System.assert(sww.accountUniqueName.contains(sww.accountState));

        sww.notificationReason = null;
        System.assert(sww.iconName == '');
    }
}