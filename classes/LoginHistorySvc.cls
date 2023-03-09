public class LoginHistorySvc {

    public static List<LoginHistory> retrieveLoginHistories(LoginHistoryParams params) {
        List<LoginHistory> loginHistories;

        String q = '';
        Integer iLimit = params != null ? params.iLimit : 50000;
        String filter = ' WHERE LoginTime >= LAST_N_DAYS:7 ';

        if (params != null) {
            if (!params.userIds.isEmpty()) {
                List<Id> userIds = params.userIds;
                filter += ' AND UserId IN :userIds ';
            }
            if (params.startDate != null) {
                Datetime startDate = params.startDate;
                filter += ' AND LoginTime >= :startDate ';
            }
            if (params.endDate != null) {
                Datetime endDate = params.endDate;
                filter += ' AND LoginTime <= :endDate ';
            }
        }
        q += ' SELECT   Id,UserId, ';
        q += '          ApiType,ApiVersion,Application,AuthMethodReference,AuthenticationServiceId, ';
        q += '          Browser,CipherSuite,ClientVersion,CountryIso, ';
        q += '          LoginGeoId,LoginGeo.City,LoginGeo.Subdivision,LoginTime,LoginType,LoginUrl, ';
        q += '          NetworkId,OptionsIsGet,OptionsIsPost,Platform,SourceIp,Status,TlsProtocol ';
        q += ' FROM LoginHistory ';
        q += filter;
        q += ' ORDER By UserId ASC, LoginTime DESC ';
        q += ' LIMIT :iLimit ';

        loginHistories = Database.query(q);
        return loginHistories;
    }
    /**
     * Since login history only returns a userId and no reference to User. We must have a second query
     * to get additional User Based information
     *
     * @param usersIds A Set of UserIds
     * @return A Map of Id => User sObject.
     */
    public static Map<Id, User> retrieveLoginHistoryUsers(Set<Id> usersIds) {
        Map<Id, User> mUsers = new Map<Id, User>([
                SELECT Id, Username, Name, FirstName, LastName, ProfileId, Profile.Name
                FROM User
                WHERE Id IN :usersIds
        ]);
        return mUsers;
    }

    public static Map<Id, String> retrieveAllUsers() {
        Map<Id,String> mUsers = new Map<Id,String>();

        List<User> users = [
                SELECT Id, Name, IsActive
                FROM User
                ORDER BY Name ASC
        ];
        for(User user : users) {
            String name = user.IsActive ? user.Name : user.Name + ' (De-active)';
            mUsers.put(user.Id,name);
        }
        return mUsers;
    }

    public static List<User> retrieveUsers(UserParams params) {
        List<User> users;

        String q = '';
        Integer iLimit = params != null ? params.iLimit : 50000;
        String filter = ' WHERE CreatedDate >= LAST_N_DAYS:36000 ';

        if (params != null) {
            if (!params.userIds.isEmpty()) {
                List<Id> userIds = params.userIds;
                filter += ' AND Id IN :userIds ';
            }
            if (!params.userTypes.isEmpty()) {
                List<String> userTypes = params.userTypes;
                filter += ' AND UserType IN :userTypes ';
            }
            if(!params.activeInactives.isEmpty()) {
                if(params.activeInactives.contains('active') && params.activeInactives.contains('inactive')) {
                    //  no filter
                } else if(params.activeInactives.contains('active')) {
                    filter += ' AND IsActive = TRUE ';
                } else {
                    filter += ' AND IsActive = FALSE ';
                }
            }
        }

        q += ' SELECT   Id,Name,IsActive ';
        q += ' FROM User ';
        q += filter;
        q += ' ORDER By Name ASC ';
        q += ' LIMIT :iLimit ';

        users = Database.query(q);
        return users;
    }


    public static Map<Id,String> retrieveAdminUsers() {
        Map<Id,String> mUsers = new Map<Id,String>();

        List<User> users = [
                SELECT Id,User.Name,IsActive
                FROM   User
                WHERE  User.Profile.NAME LIKE '%Admin%'
                ORDER  BY Name ASC
        ];
        for(User user : users) {
            String name = user.IsActive ? user.Name : user.Name + ' (De-active)';
            mUsers.put(user.Id,name);
        }
        return mUsers;
    }

    public static Map<Id,String> retrieveWestMonroeUsers() {
        Map<Id,String> mUsers = new Map<Id,String>();

        List<User> users = [
                SELECT Id,User.Name,IsActive
                FROM   User
                WHERE  User.Email LIKE '%westmonroe.com'
                ORDER  BY Name ASC
        ];
        for(User user : users) {
            String name = user.IsActive ? user.Name : user.Name + ' (De-active)';
            mUsers.put(user.Id,name);
        }
        return mUsers;
    }

}