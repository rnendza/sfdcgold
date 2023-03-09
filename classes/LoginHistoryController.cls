public class LoginHistoryController {

    public static String MAP_KEY_LOGIN_HISTORY_WRAPS    = 'LOGIN_HISTORY_WRAPS';
    public static String MAP_KEY_USER_WRAPS             = 'USER_WRAPS';

    @AuraEnabled
    public static ResponseDto retrieveLoginHistories(LoginHistoryParams params) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'params: '+params;

        List<LoginHistory> loginHistories = LoginHistorySvc.retrieveLoginHistories(params);
        List<LoginHistoryWrapper> wraps = buildLoginHistoryWrappers(loginHistories);

        dto.isSuccess = !wraps.isEmpty();
        dto.values.put(MAP_KEY_LOGIN_HISTORY_WRAPS,wraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAdminUsers() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mUsers = LoginHistorySvc.retrieveAdminUsers();
        List<UserWrapper> userWraps = buildUserWrappers(mUsers);

        dto.isSuccess = !userWraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,userWraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveUsers(UserParams params) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'params: '+params;
        List<User> users = LoginHistorySvc.retrieveUsers(params);

        List<UserWrapper> wraps = buildSearchUserWrappers(users);

        dto.isSuccess = !wraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,wraps);
        return dto;
    }

    @AuraEnabled(cacheable=true)
    public static ResponseDto retrieveAllUsers() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mUsers = LoginHistorySvc.retrieveAllUsers();
        List<UserWrapper> userWraps = buildUserWrappers(mUsers);

        dto.isSuccess = !userWraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,userWraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveWestMonroeUsers() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mUsers = LoginHistorySvc.retrieveWestMonroeUsers();
        List<UserWrapper> userWraps = buildUserWrappers(mUsers);

        dto.isSuccess = !userWraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,userWraps);
        return dto;
    }

    public static List<LoginHistoryWrapper> buildLoginHistoryWrappers(List<LoginHistory> loginHistories) {
        List<LoginHistoryWrapper> wraps = new List<LoginHistoryWrapper>();

        Set<Id> userIds = new Set<Id>();
        for(LoginHistory lh : loginHistories) {
            userIds.add(lh.UserId);
        }
        Map<Id,User> mUsers = LoginHistorySvc.retrieveLoginHistoryUsers(userIds);
        for(LoginHistory loginHistory : loginHistories) {
            wraps.add(new LoginHistoryWrapper(loginHistory,mUsers));
        }
        return wraps;
    }

    public static List<UserWrapper> buildSearchUserWrappers(List<User> users) {
        List<UserWrapper> wraps = new List<UserWrapper>();
        for(User user : users) {
            UserWrapper wrap = new UserWrapper();
            wrap.userId = user.Id;
            wrap.userName = !user.IsActive ? user.Name + ' (Deactive)' : user.Name;
            wraps.add(wrap);
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

    public class LoginHistoryWrapper {
        @AuraEnabled public Id loginHistoryId;
        @AuraEnabled public Id userId;
        @AuraEnabled public String userLink;
        @AuraEnabled public String userName;
        @AuraEnabled public String userFullName;
        @AuraEnabled public String userFirstName;
        @AuraEnabled public String userLastName;
        @AuraEnabled public String userProfileId;
        @AuraEnabled public String userProfileName;
        @AuraEnabled public Datetime loginTime;
        @AuraEnabled public String apiType;
        @AuraEnabled public String apiVersion;
        @AuraEnabled public String application;
        @AuraEnabled public String browser;
        @AuraEnabled public Id loginGeoId;
        @AuraEnabled public String loginCity;
        @AuraEnabled public String loginStatus;
        @AuraEnabled public String platform;
        @AuraEnabled public String location;
        @AuraEnabled public String sourceIp;
        @AuraEnabled public String loginUrl;

//        q += '          ApiType,ApiVersion,Application,AuthMethodReference,AuthenticationServiceId, ';
//        q += '          Browser,CipherSuite,ClientVersion,CountryIso, ';
//        q += '          LoginGeoId,LoginGeo.City,LoginGeo.Subdivision,LoginTime,LoginType,LoginUrl, ';
//        q += '          NetworkId,OptionsIsGet,OptionsIsPost,Platform,SourceIp,Status,TlsProtocol ';
//

        public LoginHistoryWrapper(LoginHistory loginHistory,Map<Id,User> mUsers) {
            this.loginHistoryId = loginHistory.Id;
            this.userId = loginHistory.UserId;
            this.userLink = '/'+this.userId;
            this.loginTime = loginHistory.LoginTime;
            this.apiType = loginHistory.ApiType;
            this.apiVersion = loginHistory.ApiVersion;
            this.application = loginHistory.Application;
            this.browser = loginHistory.Browser;
            this.loginGeoId = loginHistory.LoginGeoId;
            this.loginCity = loginHistory?.LoginGeo.City;
            this.loginStatus = loginHistory.Status;
            this.platform = loginHistory.Platform + ' ' + loginHistory.Browser;
            this.sourceIp = loginHistory.SourceIp;
            this.location = this.loginCity + ' ' + loginHistory?.LoginGeo.Subdivision;
            this.loginUrl = loginHistory.LoginUrl;

            if(mUsers.containsKey(this.userId)){
                User user = mUsers.get(this.userId);
                this.userName = user.Username;
                this.userFullName = user.Name;
                this.userFirstName = user.FirstName;
                this.userProfileId = user.ProfileId;
                this.userProfileName = user.Profile.Name;
                this.userLastName = user.LastName;
            }
        }
    }

    public class UserWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
    }
}