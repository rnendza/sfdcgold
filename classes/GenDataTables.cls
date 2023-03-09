public class GenDataTables {
    public List<AggregateResult> regionBreakDownList;
    public List<AggregateResult> technicianBreakDownList;
    public List<AggregateResult> callCenterBreakDownList;
    public List<AggregateResult> manufacturerBreakDownList;
    public List<Case> dailyLogList; 
    public List<Case> pendingLogList;
    public genDatatables(){
        regionBreakDownList = [Select Account.Service_Region__c, COUNT(Id) from Case where CreatedDate = yesterday GROUP BY Account.Service_Region__c order by COUNT(Id) DESC NULLS LAST];
        technicianBreakDownList = [Select Assigned_Resource__r.Name, COUNT(Id) from Case where CreatedDate = yesterday and Assigned_Resource__c NOT IN (select id from user where user.profile.name = 'Accel Call Center') GROUP BY Assigned_Resource__r.Name order by COUNT(Id) DESC NULLS LAST];
        callCenterBreakDownList = [Select Assigned_Resource__r.Name, COUNT(Id) from Case where CreatedDate = yesterday and Assigned_Resource__c IN (select id from user where user.profile.name = 'Accel Call Center') GROUP BY Assigned_Resource__r.Name order by COUNT(Id) DESC NULLS LAST];
        manufacturerBreakDownList = [Select Asset.GP_Manufacturer__c, COUNT(Id) from Case where CreatedDate = yesterday GROUP BY Asset.GP_Manufacturer__c order by COUNT(Id) DESC NULLS LAST];
        dailyLogList = [select IGB_Number__c, Account.Name, City__c, Service_Region__c, Assigned_Resource__r.Name,
                                FORMAT(CreatedDate), FORMAT(ClosedDate), Model__c, Serial__c, Work_Type__r.Name, Description, Accel_Solution__c, Accel_Solution__r.Name,  CreatedBy.Name
                        from    Case
                        where CreatedDate = yesterday ORDER BY Service_Region__c ASC NULLS LAST, CreatedDate DESC];
        pendingLogList = [select  Account.Name, Service_Region__c, Assigned_Resource__r.Name, FORMAT(CreatedDate), Model__c, Work_Type__r.Name, Description from Case where CreatedDate = yesterday and (Status = 'Pending' or Status = 'In Progress') and ClosedDate = NULL ORDER BY Service_Region__c ASC NULLS LAST, CreatedDate DESC];
    }  
    public List<AggregateResult> regionBreakDownListAgg {
      get{  return regionBreakDownList;}
    }
     public List<AggregateResult> technicianBreakDownListAgg {
      get{  return technicianBreakDownList;}
    }
     public List<AggregateResult> callCenterBreakDownListAgg {
      get{  return callCenterBreakDownList;}
    }
     public List<AggregateResult> manufacturerBreakDownListAgg {
      get{  return manufacturerBreakDownList;}
    }
     public List<Case> dailyLogAgg {
      get{  return dailyLogList;}
    }
     public List<Case> pendingLogAgg {
      get{   return pendingLogList;}
    }
    public String getReportDate() {
        Date d = date.Today().addDays(-1);
        return d.format();
    }
    public integer getTotalCalls(){
        integer tc=database.countQuery('select count() from Case where CreatedDate = yesterday');
        return tc;
    }
    public integer getTechComplete(){
        List<User> cc = [select id from user where user.profile.name = 'Accel Call Center'];
        integer tc=database.countQuery('Select COUNT() from Case where ClosedDate != null and Assigned_Resource__c NOT IN :cc and CreatedDate = yesterday');
        return tc;
    }
    public integer getCallCenterComplete(){
        List<User> cc = [select id from user where user.profile.name = 'Accel Call Center'];
        integer tc=database.countQuery('Select COUNT() from Case where  ClosedDate != null and Assigned_Resource__c IN :cc and CreatedDate = yesterday');
        return tc; 
    }
    public integer getIncompleteCalls(){
        integer tc=database.countQuery('select count() from Case where ClosedDate = null and CreatedDate = yesterday');
        return tc;
    }
    public integer getInProgressCalls(){
        String prog = 'In Progress';
        integer tc=database.countQuery('select count() from Case where ClosedDate = null and Status = :prog and CreatedDate = yesterday');
        return tc;
    }
    public integer getUnresolvedCalls(){
        String pend = 'Pending';
        integer tc=database.countQuery('select count() from Case where ClosedDate = null and Status = :pend and CreatedDate = yesterday');
        return tc;
    }
}