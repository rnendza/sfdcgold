@isTest
private class DailyCallLogTest {

   @isTest static void validateDailyCallLogTest(){
       GenDataTables g = new GenDataTables();
       Date d = date.Today().addDays(-1);
       String fd = d.format();
       System.assertEquals(g.getReportDate(),fd); 
       System.assert(g.regionBreakDownListAgg!=null);
       System.assert(g.technicianBreakDownListAgg!=null);
       System.assert(g.callCenterBreakDownListAgg!=null);
       System.assert(g.manufacturerBreakDownListAgg!=null);
       System.assert(g.dailyLogAgg!=null);
       System.assert(g.pendingLogAgg!=null); 
       System.assert(g.getTotalCalls()!=null);
       System.assert(g.getTechComplete()!=null);
       System.assert(g.getCallCenterComplete()!=null);
       System.assert(g.getInProgressCalls()!=null);  
       System.assert(g.getIncompleteCalls()!=null);    
       System.assert(g.getUnresolvedCalls()!=null); 
     }
}