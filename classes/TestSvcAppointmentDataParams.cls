/**
 * This class is meant to be used in conjunction with TestUtils when creating end to end data for service appointments.
 */
public class TestSvcAppointmentDataParams {

    public Integer              iNumMunis                           {get; set;}
    public Integer              iNumAccountsPerMuni                 {get; set;}
    public Integer              iNumOppHours                        {get; set;}
    public Integer              iNumAssetsPerAccount                {get; set;}
    public Integer              iNumServiceTerritoriesPerOppHours   {get; set;}
    public Integer              iNumWorkOrdersPerCase               {get; set;}

    public String               muniNamePrefix                      {get; set;}
    public String               accountNamePrefix                   {get; set;}
    public String               assetNamePrefix                     {get; set;}
    public String               caseSubjectPrefix                   {get; set;}
    public String               oppHrNameNamePrefix                 {get; set;}
    public String               serviceTerritoryNamePrefix          {get; set;}

    public String               accountType                         {get; set;}
    public String               caseRecordTypeName                  {get; set;}
    public String               caseStatus                          {get; set;}
    public String               workOrderStatus                     {get; set;}
    public String               workOrderDurationType               {get; set;}
    public String               workOrderSiteGrade                  {get; set;}
    public String               workOrderSiteGradeDesc              {get; set;}
    public String               assetRecordTypeName                 {get; set;}
    public String               workOrderRecordTypeName             {get; set;}
    public String               serviceAppointmentRecordTypeName    {get; set;}
    public String               serviceAppointmentStatus            {get; set;}
    public String               timeZone                            {get; set;}

    public Set<String>          workTypeNames                       {get; set;}
    public Decimal              workTypeEstDuration                 {get; set;}
    public Map<String, String>  mSiteGradeMeaning_SiteGrade         {get; set;}
    /**
     * Constructor inits to defaults. Override in instantiating class if needed.
     */
    public TestSvcAppointmentDataParams() {
        /**
         *  rjn removed stress tests to play nicely with declarative stuff 9/24/19 so we don't hit that magic 12!
         *  @TODO this probably should be revisited as it's really not the answer.
         */
//        iNumMunis                           =   2;
//        iNumAccountsPerMuni                 =   5;
//        iNumOppHours                        =   2;
//        iNumServiceTerritoriesPerOppHours   =   2;
//        iNumWorkOrdersPerCase               =   2;
//        iNumAssetsPerAccount                =   2;

        iNumMunis                           =   1;
        iNumAccountsPerMuni                 =   1;
        iNumOppHours                        =   1;
        iNumServiceTerritoriesPerOppHours   =   1;
        iNumWorkOrdersPerCase               =   1;
        iNumAssetsPerAccount                =   1;

        muniNamePrefix                      =   'testaccellmuni';
        accountNamePrefix                   =   'Accel Account';
        assetNamePrefix                     =   'Ass';
        caseSubjectPrefix                   =   'Test Subject for act:';
        oppHrNameNamePrefix                 =   'Accel test opp hours';
        serviceTerritoryNamePrefix          =   'Svc Terr';

        accountType                         =   'Accel Account';
        caseStatus                          =   'In Progress';
        caseRecordTypeName                  =   'Call_Center';
        workOrderDurationType               =   'Minutes';
        workOrderStatus                     =   'Open';
        workOrderSiteGradeDesc              =   'Cleanest';
        assetRecordTypeName                 =   'VGT';
        workOrderRecordTypeName             =   'Service_Appointment';
        serviceAppointmentRecordTypeName    =   'Service';
        serviceAppointmentStatus            =   'None';

        workTypeNames                       =   new Set<String>{'ALL GAMES ARE DOWN', 'BILL JAM / NOT ACCEPTING MONEY'};
        workTypeEstDuration                 =   15.5;
        //--- no one but those inside accel will know what the heck A,B,C etc mean. so this map exists for clarity.
        mSiteGradeMeaning_SiteGrade         =   new Map<String, String>{'Cleanest' => 'A', 'Dirtiest' => 'F'};
        workOrderSiteGrade                  =   'A';
        timeZone                            =   'America/Chicago';
    }
}