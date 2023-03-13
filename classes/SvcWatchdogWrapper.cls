public with sharing class SvcWatchdogWrapper  implements  Comparable {
   // test comment
    @AuraEnabled public String              accountDbaName                  { get; set; }
    @AuraEnabled public String              accountCity                     { get; set; }
    @AuraEnabled public String              accountStreet                   { get; set; }
    @AuraEnabled public String              accountState                    { get; set; }
    @AuraEnabled public String              accountUniqueName               { get; set; }
    @AuraEnabled public String              accountId                       { get; set; }
    @AuraEnabled public Id                  caseId                          { get; set; }
    @AuraEnabled public String              caseStatus                      { get; set; }
    @AuraEnabled public Datetime            caseCreatedDateTime             { get; set; }
    @AuraEnabled public Datetime            caseDtOpened                    { get; set; }
    @AuraEnabled public Decimal             caseAgeMinutes                  { get; set; }
    @AuraEnabled public Integer             caseAgeSeconds                  { get; set; }
    @AuraEnabled public String              caseServiceZone                 { get; set; }
    @AuraEnabled public String              caseNumber                      { get; set; }
    @AuraEnabled public String              caseDesc                        { get; set; }
    @AuraEnabled public String              caseTechNotes                   { get; set; }
    @AuraEnabled public Id                  caseWorkTypeId                  { get; set; }
    @AuraEnabled public Decimal             caseAgeBottomSort               { get; set; }
    @AuraEnabled public Datetime            caseLastModDatetime             { get; set; }

    @AuraEnabled public String              workOrderNbr                    { get; set; }
    @AuraEnabled public Id                  workOrderId                     { get; set; }
    @AuraEnabled public String              workOrderStatus                 { get; set; }

    @AuraEnabled public String              serviceAptNbr                   { get; set; }
    @AuraEnabled public Id                  serviceAptId                    { get; set; }
    @AuraEnabled public String              serviceAptStatus                { get; set; }
    @AuraEnabled public Datetime            serviceAptTimeAccepted          { get; set; }
    @AuraEnabled public Decimal             servicePendingAcceptanceTimeMins{ get; set; }
    @AuraEnabled public Integer             servicePendingAcceptanceTimeSecs{ get; set; }
    @AuraEnabled public Datetime            serviceAptLastModDatetime       { get; set; }
    @AuraEnabled public String              notificationReason              { get; set; }

    @AuraEnabled public Case                cse                             { get; set; }
    @AuraEnabled public ServiceAppointment  serviceAppointment              { get; set; }
    @AuraEnabled public Id                  assignedResourceId              { get; set; }
    @AuraEnabled public String              assignedResourceName            { get; set; }
    @AuraEnabled public String              assignedResourcePhone           { get; set; }
    @AuraEnabled public String              assignedResourceMobile          { get; set; }
    @AuraEnabled public Boolean             showWrap                        { get; set; }
    @AuraEnabled public String              iteratorKey                     { get; set; } //unique key for lwc iterator.

    //  -- Custom notification enhancement
    @AuraEnabled public List<Custom_Notifications_Sent__c>  customNotificationsSent     { get;set; }
    @AuraEnabled public Custom_Notifications_Sent__c        lastCustomNotificationSent  { get;set; }

    public  enum    SORT_BY     { ByCaseAgeSeconds }
    public  static  SORT_BY     sortBy  = SORT_BY.ByCaseAgeSeconds;

    //  @TODO put in custom meta.
    public  static final String NOTIFICATION_ICON_REJECTED                = 'utility:dislike';
    public  static final String NOTIFICATION_ICON_NOTDISPATCHED           = 'utility:waits';
    public  static final String NOTIFICATION_ICON_NOASSIGNEDRESOURCE      = 'utility:resource_absence';

    @AuraEnabled public Boolean showCaseTechNotes {
        get {
            return caseTechNotes != null && caseTechNotes != '' ? TRUE : FALSE;
        }
    }
    @AuraEnabled public Boolean showCaseServiceZone {
        get {
            return caseServiceZone != null && caseServiceZone != '' ? TRUE : FALSE;
        }
    }
    @AuraEnabled public Boolean showAssignedResourceMobilePhone {
        get {
            return assignedResourceMobile != null && assignedResourceMobile != '' ? TRUE : FALSE;
        }
    }
    @AuraEnabled public Boolean isRejected {
        get {
            return notificationReason == 'Rejected' ? TRUE : FALSE;
        }
    }
    @AuraEnabled public Boolean isNoAssignedResource {
        get {
            return notificationReason == 'No Assigned Resource' ? TRUE : FALSE;
        }
    }
    @AuraEnabled public Boolean isNotDispatched {
        get {
            return notificationReason == 'Unaccepted / Not Dispatched' ? TRUE : FALSE;
        }
    }
    @AuraEnabled public Boolean showServiceAppointmentNumber {
        get {
            return isRejected || isNotDispatched;
        }
    }
    /**
     *
     */
    @AuraEnabled public String iconName {
        get {
            switch on notificationReason {
                when 'Rejected' {
                    return NOTIFICATION_ICON_REJECTED;
                }
                when 'No Assigned Resource' {
                    return NOTIFICATION_ICON_NOASSIGNEDRESOURCE;
                }
                when 'Unaccepted / Not Dispatched' {
                    return NOTIFICATION_ICON_NOTDISPATCHED;
                }
                when else {
                    return '';
                }
            }
        }
    }
    public SvcWatchdogWrapper() {
        this.caseAgeSeconds = 0;
    }
    /**
     * Takes a Case and flattens it out into individual properties.
     * @param pCase The Case sObject.
     */
    public SvcWatchdogWrapper( Case pCase ) {
        this.showWrap               = true;
        this.notificationReason     = 'No Assigned Resource';

        this.accountDbaName         = pCase.Account.DBA_Account_Name__c;

        if(accountDbaName == null) { //not sure why this is happening perhaps manual entry is wrong?
            this.accountDbaName = pCase.Account__r.Name;
        }
        this.accountCity            = pCase.Account.ShippingCity;
        this.accountStreet          = pCase.Account.ShippingStreet;
        this.accountState           = pCase.Account.ShippingState;
        this.accountId              = pCase.AccountId;
        this.buildAccountUniqueName();
        this.cse                    = pCase;
        this.caseId                 = pCase.Id;
        this.caseStatus             = pCase.Status;
        this.caseCreatedDateTime    = pCase.CreatedDate;
        this.caseDtOpened           = pCase.CreatedDate;
        this.caseNumber             = pCase.CaseNumber;
        this.caseServiceZone        = pCase.Service_Region__c;
        this.caseDesc               = pCase.Description;
        this.caseTechNotes          = pCase.Tech_Notes__c;
        this.caseWorkTypeId         = pCase.Work_Type__c;
        this.caseLastModDatetime    = pCase.LastModifiedDate;

        if(pCase.Age_of_Case_Hours__c !=  null) {
            //--- note whoever created the api name of this field did it wrong. this is in fact minutes and not hours!
            this.caseAgeMinutes = pCase.Age_of_Case_Hours__c;
            this.caseAgeSeconds = Integer.valueOf(caseAgeMinutes * 60);
        }
        this.caseAgeBottomSort = SvcWatchdogController.utilityArMdt.Case_Age_Bottom_Sort__c;
        this.buildIteratorKey();
    }
    /**
     * Takes a ServiceAppointmemt and flattens it out into individual properties.
     * @param pServiceAppointment The ServiceAppointment sObject.
     */
    public SvcWatchdogWrapper( ServiceAppointment pServiceAppointment ) {
        this.showWrap                       = true;
        this.notificationReason             = 'Rejected';
        this.accountDbaName                 = pServiceAppointment.Account.DBA_Account_Name__c;
        this.accountCity                    = pServiceAppointment.Account.ShippingCity;
        this.accountStreet                  = pServiceAppointment.Account.ShippingStreet;
        this.accountState                   = pServiceAppointment.Account.ShippingState;
        this.accountId                      = pServiceAppointment.AccountId;
        this.buildAccountUniqueName();
        this.serviceAppointment             = pServiceAppointment;
        this.caseId                         = pServiceAppointment.Work_Order__r.CaseId;
        this.caseStatus                     = pServiceAppointment.Work_Order__r.Case.Status;
        this.caseCreatedDateTime            = pServiceAppointment.Work_Order__r.Case.CreatedDate;
        this.caseDtOpened                   = pServiceAppointment.Work_Order__r.Case.CreatedDate;
        this.caseNumber                     = pServiceAppointment.Work_Order__r.Case.CaseNumber;
        this.caseServiceZone                = pServiceAppointment.Work_Order__r.Case.Service_Region__c;
        this.caseDesc                       = pServiceAppointment.Work_Order__r.Case.Description;
        this.caseWorkTypeId                 = pServiceAppointment.Work_Order__r.Case.Work_Type__c;
        this.caseLastModDatetime            = pServiceAppointment.Work_Order__r.Case.LastModifiedDate;

        this.workOrderId                    = pServiceAppointment.Work_Order__c;
        this.workOrderNbr                   = pServiceAppointment.Work_Order__r.WorkOrderNumber;
        this.workOrderStatus                = pServiceAppointment.Work_Order__r.Status;


        this.serviceAptNbr                      = pServiceAppointment.AppointmentNumber;
        this.serviceAptId                       = pServiceAppointment.Id;
        this.serviceAptStatus                   = pServiceAppointment.Status;
        this.serviceAptTimeAccepted             = pServiceAppointment.Time_Accepted__c;
        this.servicePendingAcceptanceTimeMins   = pServiceAppointment.Pending_Acceptance_Time__c;
        this.serviceAptLastModDatetime          = pServiceAppointment.LastModifiedDate;
        this.caseTechNotes                      = pServiceAppointment.Solution_Notes__c;
        this.buildAssignedResourceName();
        this.assignedResourcePhone              = pServiceAppointment.Work_Order__r.Case.Assigned_Resource__r.Phone;
        this.assignedResourceMobile             = pServiceAppointment.Work_Order__r.Case.Assigned_Resource__r.MobilePhone;
        this.assignedResourceId                 = pServiceAppointment.Work_Order__r.Case.Assigned_Resource__c;

        //  -- Custom notification enhancement set a property for easier client usage.
        this.customNotificationsSent    = new List<Custom_Notifications_Sent__c>();
        this.lastCustomNotificationSent = new Custom_Notifications_Sent__c();
        if(pServiceAppointment.Custom_Notifications_Sent__r != null) {
            this.customNotificationsSent = pServiceAppointment.Custom_Notifications_Sent__r;
            if(!this.customNotificationsSent.isEmpty()) {
                //  -- meh this is a bit risky as it's depending on the order by on the soql but in interests of performance.
                this.lastCustomNotificationSent = this.customNotificationsSent[0];
            }
        }

        if(pServiceAppointment.Work_Order__r.Case.Age_of_Case_Hours__c !=  null) {
            //--- note whoever created the api name of this field did it wrong. this is in fact minutes and not hours!
            this.caseAgeMinutes = pServiceAppointment.Work_Order__r.Case.Age_of_Case_Hours__c;
            this.caseAgeSeconds = Integer.valueOf(caseAgeMinutes * 60);
        }
        //  Pending Acceptance Time looks to be in minutes.
        if(pServiceAppointment.Pending_Acceptance_Time__c !=  null) {
            this.servicePendingAcceptanceTimeMins  = pServiceAppointment.Pending_Acceptance_Time__c;
            this.servicePendingAcceptanceTimeSecs = Integer.valueOf(this.servicePendingAcceptanceTimeMins * 60);
        }
        this.caseAgeBottomSort = SvcWatchdogController.utilityArMdt.Case_Age_Bottom_Sort__c;
        if(caseAgeSeconds == null){
            caseAgeSeconds = 0;
        }
        this.buildIteratorKey();
    }
   /**
    *
    * @param compareTo
    * @return
    */
    public Integer compareTo(Object compareTo) {
        Integer iRet = 0;
        SvcWatchdogWrapper compareToWrap = (SvcWatchdogWrapper) compareTo;
        if(compareToWrap != null) {
            //MOVE Not dispatched to the top per new req.
            if (compareToWrap.isNotDispatched) {
                return 1;
            }
        }
        iRet = Integer.valueOf(((SvcWatchdogWrapper) compareTo).caseAgeSeconds)  > caseAgeSeconds ? -1 : 1;
        return iRet;
    }
    /**
     *
     */
    @TestVisible
    private void buildAccountUniqueName() {
        if(accountDbaName != null) {
            accountUniqueName = accountDbaName;
            if (accountStreet != null) {
                accountUniqueName += ' - ' + accountStreet;
            }
            if(accountCity != null) {
                accountUniqueName += ' - ' + accountCity;
            }
            if(accountState != null) {
                accountUniqueName += ' , ' + accountState;
            }
        }
    }
    @TestVisible
    private void buildAssignedResourceName() {
        if(this.serviceAppointment != null) {
            if( this.serviceAppointment.Work_Order__r.Case.Assigned_Resource__c != null ) {
                this.assignedResourceName = this.serviceAppointment.Work_Order__r.Case.Assigned_Resource__r.Name;
            }
            if( this.serviceAppointment.Work_Order__r.Case.Assigned_Resource__c != null ) {
                this.assignedResourceName = this.serviceAppointment.Work_Order__r.Case.Assigned_Resource__r.Name;
            }
        }
    }
    /**
     *
     */
    @TestVisible
    private void buildIteratorKey() {
        iteratorKey = this.caseId;
        if(serviceAppointment != null) {
            if(workOrderId != null) {
                iteratorKey += workOrderId;
            }
            iteratorKey +=  serviceAppointment.Id;
        }
    }
}