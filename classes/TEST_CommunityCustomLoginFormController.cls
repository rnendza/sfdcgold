@IsTest(SeeAllData = true)
/**
 * @TODO clone of SFDC OOTB Apex controller class. not sure why the use seealldata = true
 *       against their suggestions
 */        
public with sharing class TEST_CommunityCustomLoginFormController {

    @IsTest
    static void testLoginWithInvalidCredentials() {
        System.assertEquals('Argument 1 cannot be null', Accel_CommunityCustomLoginFormController.login('testUser', 'fakepwd', null));
    }

    @IsTest
    static void Accel_CommunityCustomLoginFormControllerInstantiation() {
        Accel_CommunityCustomLoginFormController controller = new Accel_CommunityCustomLoginFormController();
        System.assertNotEquals(controller, null);
    }

    @IsTest
    static void testIsUsernamePasswordEnabled() {
        System.assertEquals(true, Accel_CommunityCustomLoginFormController.getIsUsernamePasswordEnabled());
    }

    @IsTest
    static void testIsSelfRegistrationEnabled() {
        System.assertEquals(false, Accel_CommunityCustomLoginFormController.getIsSelfRegistrationEnabled());
    }

    @IsTest
    static void testGetSelfRegistrationURL() {
        System.assertEquals(null, Accel_CommunityCustomLoginFormController.getSelfRegistrationUrl());
    }

    @IsTest
    static void testAuthConfig() {
        Auth.AuthConfiguration authConfig = Accel_CommunityCustomLoginFormController.getAuthConfig();
        System.assertNotEquals(null, authConfig);
    }
}