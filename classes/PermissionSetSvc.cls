public class PermissionSetSvc {
    /**
     *
     * @param userId - The Id of the User to search for
     * @return A List of PermissionSetAssignment sObjects if any, otherwise an empty list.
     */
    public static List<PermissionSetAssignment> retrieveUsersPermissionSetAssignments( Id userId ) {
        List<PermissionSetAssignment> psas = [
                SELECT  PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId,
                        PermissionSet.Profile.Name, AssigneeId, Assignee.Name
                FROM    PermissionSetAssignment
                WHERE   AssigneeId = :userId
        ];
        return psas;
    }
    /**
     *
     * @param userId
     * @param permissionSetApiName
     *
     * @return
     */
    public static Boolean isUserInPermissionSet( Id userId, String permissionSetApiName ) {
        Boolean hasAccess = false;
        List<PermissionSetAssignment> psas = [
                SELECT  Id
                FROM    PermissionSetAssignment
                WHERE   AssigneeId = :userId
                AND     PermissionSet.Name    = :permissionSetApiName
        ];
        hasAccess = !psas.isEmpty();
        return hasAccess;
    }
    /**
     *
     * @param userId
     * @param permissionSetApiName
     *
     * @return
     */
    public static Boolean isUserInPermissionSet( String permissionSetApiName ) {
        return isUserInPermissionSet( userInfo.getUserId(), permissionSetApiName);
    }
}