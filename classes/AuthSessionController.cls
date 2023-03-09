public class AuthSessionController {

    public static String MAP_KEY_AUTH_SESSION_WRAPS     = 'AUTH_SESSION_WRAPS';
    public static String MAP_KEY_USER_WRAPS             = 'USER_WRAPS';

    /**
     * @param params    The search params for the AuthSession sObject query.
     * @return          A ResponseDto with a List of AuthSessionWrapper in the values map.
     *
     * @see AuthSessionSvc.retrieveAuthSessions
     * @see AuthSessionWrapper
     */
    @AuraEnabled
    public static ResponseDto retrieveAuthSessions(AuthSessionParams params) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'params: '+params;
        List<AuthSession> authSessions = AuthSessionSvc.retrieveAuthSessions(params);
        List<AuthSessionWrapper> wraps = buildAuthSessionWrappers(authSessions);

        dto.isSuccess = !wraps.isEmpty();
        dto.values.put(MAP_KEY_AUTH_SESSION_WRAPS,wraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveActiveLoggedInUsers() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mUsers = AuthSessionSvc.retrieveActiveLoggedInUsers();
        List<UserWrapper> userWraps = buildUserWrappers(mUsers);

        dto.isSuccess = !userWraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,userWraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto removeAuthSessions(List<Id> authSessionIds) {
        ResponseDto dto = new ResponseDto();
        List<AuthSession> authSessions = [
                SELECT Id
                FROM AuthSession
                WHERE Id IN : authSessionIds
        ];
        if(!authSessions.isEmpty()) {
            delete authSessions;
            dto.isSuccess = true;
            dto.severity = 'success';
            dto.message = 'Successfully removed auth sessions.';
            dto.technicalMsg = 'Removed auth sessions for ids: '+authSessionIds;
        }
        return dto;
    }

    /**
     * @param authSessions      A List of AuthSession sObjects.
     * @return                  A List of AuthSessionWrapper Objects.
     */
    public static List<AuthSessionWrapper> buildAuthSessionWrappers(List<AuthSession> authSessions) {
        List<AuthSessionWrapper> wraps = new List<AuthSessionWrapper>();
        for(AuthSession authSession : authSessions) {
            wraps.add(new AuthSessionWrapper(authSession));
        }
        return wraps;
    }

    public static List<UserWrapper> buildUserWrappers(Map<Id,String> mUsers) {
        List<UserWrapper> wraps = new List<UserWrapper>();
        for(Id uid : mUsers.keySet()) {
            UserWrapper wrap = new UserWrapper();
            wrap.userId = uid;
            wrap.userName = mUsers.get(uid);
            wraps.add(wrap);
        }
        return wraps;
    }

    /**
     * Wraps an AuthSession sObject.
     */
    public class AuthSessionWrapper {

        @AuraEnabled public Id authSessionId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userFullName;
        @AuraEnabled public String userLastName;
        @AuraEnabled public String userLink;
        @AuraEnabled public Id userId;
        @AuraEnabled public String userType;
        @AuraEnabled public String sourceIp;
        @AuraEnabled public String sessionType;
        @AuraEnabled public String sessionSecurityLevel;
        @AuraEnabled public Integer numSecondsValid;
        @AuraEnabled public String logoutUrl;
        @AuraEnabled public String loginType;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public Datetime lastModifiedDate;
        @AuraEnabled public Datetime loginTime;
        @AuraEnabled public String city;
        @AuraEnabled public String postalCode;
        @AuraEnabled public Decimal longitude;
        @AuraEnabled public Decimal latitude;
        @AuraEnabled public String loginHistoryType;
        @AuraEnabled public String loginHistoryPlatform;
        @AuraEnabled public String loginHistoryBrowser;
        @AuraEnabled public String loginHistoryPlatformAndBrowser;

        public AuthSessionWrapper(AuthSession authSession) {
            this.authSessionId = authSession.Id;
            this.userId = authSession.UsersId;
            this.userName = authSession.Users.Username;
            this.userLastName = authSession.Users.LastName;
            this.userLink = '/'+authSession?.UsersId;
            this.userFullName = authSession.Users.Name;
            this.userType = authSession.UserType;
            this.sourceIp = authSession.SourceIp;
            this.sessionType = authSession.SessionType;
            this.sessionSecurityLevel = authSession.SessionSecurityLevel;
            this.numSecondsValid = authSession.NumSecondsValid;
            this.logoutUrl = authSession.LogoutUrl;
            this.loginType = authSession.LoginType;
            this.createdDate = authSession.CreatedDate;
            this.lastModifiedDate = authSession.LastModifiedDate;
            this.loginTime = authSession.LoginGeo.LoginTime;
            this.city = authSession.LoginGeo.City;
            this.postalCode = authSession.LoginGeo.PostalCode;
            this.latitude = authSession.LoginGeo.Latitude;
            this.longitude = authSession.LoginGeo.Longitude;
            this.loginHistoryType = authSession.LoginHistory.LoginType;
            this.loginHistoryPlatform = authSession.LoginHistory.Platform;
            this.loginHistoryBrowser = authSession.LoginHistory.Browser;
            this.loginHistoryPlatformAndBrowser = this.loginHistoryPlatform + ' ' + this.loginHistoryBrowser;
        }
    }

    public class UserWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
    }

}