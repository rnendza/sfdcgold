/**
 * @see https://developer.salesforce.com/docs/atlas.en-us.238.0.object_reference.meta/object_reference/sforce_api_objects_authsession.htm
 */
public class AuthSessionSvc {

    /**
     * @param params    An instance of AuthSessionParams.
     *
     * @return          A List of AuthSession sObjects.
     * @see AuthSessionParams
     */
    public static List<AuthSession> retrieveAuthSessions(AuthSessionParams params) {
        List<AuthSession> authSessions;

        String q = '';
        Integer iLimit = params != null ? params.iLimit : 50000;
        String filter = ' WHERE CreatedDate >= THIS_MONTH ';
        if(params != null) {
            if (!params.userIds.isEmpty()) {
                List<Id> userIds = params.userIds;
                filter += ' AND UsersId IN :userIds ';
            }
            if (!params.sessionTypes.isEmpty()) {
                List<String> sessionTypes = params.sessionTypes;
                filter += ' AND SessionType IN :sessionTypes ';
            }
            if (!params.loginTypes.isEmpty()) {
                List<String> loginTypes = params.loginTypes;
                filter += ' AND LoginType IN :loginTypes ';
            }
        }

        q += ' SELECT   Id,UsersId,Users.UserName,Users.Name, UserType, SourceIp, SessionType, SessionSecurityLevel, ';
        q += '          ParentId, NumSecondsValid,LogoutUrl, LoginType, LoginGeoId, Users.LastName, ';
        q += '          CreatedDate,LastModifiedDate, ';
        q += '          LoginGeo.City,LoginGeo.PostalCode,LoginGeo.LoginTime,LoginGeo.Latitude,LoginGeo.Longitude, ';
        q += '          LoginHistory.LoginType, LoginHistory.Browser, LoginHistory.Platform ';
        q += ' FROM     AuthSession ';
        q +=   filter;
        q += ' ORDER BY Users.LastName ASC, LoginGeo.LoginTime DESC ';
        q += ' LIMIT    :iLimit ';

        authSessions = Database.query(q);
        return authSessions;
    }

    /**
     * @return xxx
     * @todo move to user service.
     */
    public static Map<Id,String> retrieveActiveLoggedInUsers() {
        Map<Id,String> mUsers = new Map<Id,String>();

        List<AuthSession> authSessions = [
                SELECT Id,UsersId,Users.Name
                FROM   AuthSession
        ];
        for(AuthSession authSession : authSessions) {
            mUsers.put(authSession.UsersId,authSession.Users.Name);
        }
        return mUsers;
    }

}