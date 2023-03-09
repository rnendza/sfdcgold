/**
 * Auto Generated and Deployed by the Declarative Lookup Rollup Summaries Tool package (dlrs)
 **/
@IsTest
private class dlrs_ServiceAppointment
{
    @IsTest
    private static void testTrigger()
    {
        // Force the dlrs_CaseTrigger to be invoked, fails the test if org config or other Apex code prevents this.
        //dlrs.RollupService.testHandler(new ServiceAppointment());
        
        Account a = new Account(Name='test');
        insert a;
        
        WorkOrder wo = new WorkOrder();
        insert wo;
        
        ServiceAppointment sa = new ServiceAppointment();
        sa.ParentRecordId = wo.Id;
        insert sa;
        
    }
}