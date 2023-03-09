public class AuditTrailController {

    public static String MAP_KEY_AUDIT_TRAIL_WRAPS      = 'AUDIT_TRAIL_WRAPS';
    public static String MAP_KEY_USER_WRAPS             = 'USER_WRAPS';
    public static String MAP_KEY_PROFILE_WRAPS          = 'PROFILE_WRAPS';

    /**
     * @param params    The search params for the SetupAuditTrail sObject query.
     * @return          A ResponseDto with a List of AuditTrailWrapper in the values map.
     */
    @AuraEnabled
    public static ResponseDto retrieveAuditTrails(AuditTrailParams params) {
        ResponseDto dto = new ResponseDto();
        dto.technicalMsg += 'params: '+params;

        List<SetupAuditTrail> auditTrails = AuditTrailSvc.retrieveAuditTrails(params);
        List<AuditTrailWrapper> wraps = buildAuditTrailWrappers(auditTrails);

        dto.isSuccess = !wraps.isEmpty();
        dto.values.put(MAP_KEY_AUDIT_TRAIL_WRAPS,wraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAdminUsers() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mUsers = AuditTrailSvc.retrieveAdminUsers();
        List<UserWrapper> userWraps = buildUserWrappers(mUsers);

        dto.isSuccess = !userWraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,userWraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveWestMonroeUsers() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mUsers = AuditTrailSvc.retrieveWestMonroeUsers();
        List<UserWrapper> userWraps = buildUserWrappers(mUsers);

        dto.isSuccess = !userWraps.isEmpty();
        dto.values.put(MAP_KEY_USER_WRAPS,userWraps);
        return dto;
    }

    @AuraEnabled
    public static ResponseDto retrieveAllProfiles() {
        ResponseDto dto = new ResponseDto();

        Map<Id,String> mProfiles = AuditTrailSvc.retrieveAllProfiles();
        List<ProfileWrapper> profileWrappers = buildProfileWrappers(mProfiles);

        dto.isSuccess = !profileWrappers.isEmpty();
        dto.values.put(MAP_KEY_PROFILE_WRAPS,profileWrappers);
        return dto;
    }


    public static List<AuditTrailWrapper> buildAuditTrailWrappers(List<SetupAuditTrail> auditTrails) {
        List<AuditTrailWrapper> wraps = new List<AuditTrailWrapper>();
        for(SetupAuditTrail auditTrail : auditTrails) {
            wraps.add(new AuditTrailWrapper(auditTrail));
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

    public static List<ProfileWrapper> buildProfileWrappers(Map<Id,String> mProfiles) {
        List<ProfileWrapper> wraps = new List<ProfileWrapper>();
        for(Id pid : mProfiles.keySet()) {
            ProfileWrapper wrap = new ProfileWrapper();
            wrap.profileId = pid;
            wrap.profileName = mProfiles.get(pid);
            wraps.add(wrap);
        }
        return wraps;
    }

    public class AuditTrailWrapper {
        @AuraEnabled public Id auditTrailId;
        @AuraEnabled public Id createdById;
        @AuraEnabled public String userLink;
        @AuraEnabled public String createdByUserName;
        @AuraEnabled public String createdByFullName;
        @AuraEnabled public String createdByFirstName;
        @AuraEnabled public String createdByLastName;
        @AuraEnabled public String createdByProfileId;
        @AuraEnabled public String createdByProfileName;
        @AuraEnabled public Datetime createdDate;
        @AuraEnabled public String display;
        @AuraEnabled public String section;
        @AuraEnabled public String action;

        public AuditTrailWrapper(SetupAuditTrail auditTrail) {
            this.auditTrailId = auditTrail.Id;
            this.userLink = '/'+auditTrail.CreatedById;
            this.createdById = auditTrail.CreatedById;
            this.createdByUserName = auditTrail.CreatedBy.Username;
            this.createdByFullName = auditTrail?.CreatedBy?.Name != null ? auditTrail.CreatedBy.Name : '' ;
            this.createdByFirstName = auditTrail.CreatedBy.FirstName;
            this.createdByLastName = auditTrail.CreatedBy.LastName;
            this.createdByProfileId = auditTrail.CreatedBy.ProfileId;
            this.createdByProfileName = auditTrail.CreatedBy.Profile.Name;
            this.createdDate = auditTrail.CreatedDate;
            this.display = auditTrail.Display;
            this.section = auditTrail.Section;
            this.action = auditTrail.Action;
        }
    }

    public class UserWrapper {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
    }

    public class ProfileWrapper {
        @AuraEnabled public Id profileId;
        @AuraEnabled public String profileName;
    }
}