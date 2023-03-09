public class AuditTrailSvc {

    /*
     *  The SetupAuditTrail.Action to exclude (login / logout stuff etc).
     */
    public static List<String> EXCLUDE_ACTIONS = new List<String>{
            'suNetworkAdminLogin', 'suNetworkAdminLogout', 'suOrgAdminLogout', 'suOrgAdminLogin'
    };

    /**
     * @param params    an instance of AuditTrailParams.
     *
     * @return          A list of SetupAuditTrail sObjects.
     */
    public static List<SetupAuditTrail> retrieveAuditTrails(AuditTrailParams params) {
        List<SetupAuditTrail> auditTrails;

        String q = '';
        Integer iLimit = params != null ? params.iLimit : 50000;
        String filter = ' WHERE CreatedDate >= LAST_YEAR ';

        if(params != null) {
            List<String> tmpExcludeActions = new List<String>();
            if(params.devOnlyActions) {
                tmpExcludeActions.addAll(EXCLUDE_ACTIONS);
            }
            if (!params.userIds.isEmpty()) {
                List<Id> userIds = params.userIds;
                filter += ' AND CreatedById IN :userIds ';
            }
            if (!params.profileIds.isEmpty()) {
                List<Id> profileIds = params.profileIds;
                filter += ' AND CreatedBy.Profile.Id IN :profileIds ';
            }
            if (!params.excludeActions.isEmpty() || !tmpExcludeActions.isEmpty()) {
                List<String> excludeActions = params.excludeActions;
                excludeActions.addAll(tmpExcludeActions);
                filter += ' AND Action NOT IN :excludeActions ';
            }
            if (!params.includeActions.isEmpty()) {
                List<String> includeActions = params.includeActions;
                filter += ' AND Action IN :includeActions ';
            }
            if(params.startDate != null) {
                Datetime startDate = params.startDate;
                filter += ' AND CreatedDate >= :startDate ';
            }
            if(params.endDate != null) {
                Datetime endDate = params.endDate;
                filter += ' AND CreatedDate <= :endDate ';
            }
        }

        q += ' SELECT   Id,CreatedById,CreatedBy.username,CreatedBy.Name,CreatedDate,CreatedBy.Profile.Id, ';
        q += '          CreatedBy.Profile.Name,CreatedByContext, CreatedBy.LastName, CreatedBy.FirstName, ';
        q += '          Display,Section,Action ';
        q += ' FROM     SetupAuditTrail ';
        q +=   filter;
        q += ' ORDER BY CreatedDate DESC, CreatedBy.LastName ASC ';
        q += ' LIMIT    :iLimit ';

        auditTrails = Database.query(q);
        return auditTrails;
    }

   /**
    * @return A Map of UserId => User.Name
    * @todo move to user service.
    */
    public static Map<Id,String> retrieveAdminUsers() {
        Map<Id,String> mUsers = new Map<Id,String>();

        List<User> users = [
                SELECT Id,User.Name,IsActive
                FROM   User
                WHERE  User.Profile.NAME LIKE '%Admin%'
                AND    IsActive = TRUE
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
                AND    IsActive = TRUE
                ORDER  BY Name ASC
        ];
        for(User user : users) {
            String name = user.IsActive ? user.Name : user.Name + ' (De-active)';
            mUsers.put(user.Id,name);
        }
        return mUsers;
    }

    public static Map<Id,String> retrieveAllProfiles() {
        Map<Id,String> mProfiles = new Map<Id,String>();

        List<Profile> profiles = [
                SELECT Id,Name
                FROM   Profile
                ORDER BY Name ASC
        ];
        for(Profile profile : profiles) {
            String name = profile.name;
            mProfiles.put(profile.Id,name);
        }
        return mProfiles;
    }
}