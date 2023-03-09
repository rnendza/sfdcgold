trigger Accel_HoldPerDayTrigger on Hold_Per_Day__c (after insert) {

    if(Trigger.isAfter && Trigger.isInsert) {  
        HoldPerDayTriggerHandler.updateAccountMostRecentHPD(Trigger.new); // only here so we can deploye
//        @deprecated replace with BatchHpdMonthlyImport for CPU Timeout issues.
//        List<Account> updatedAccounts = HoldPerDayTriggerHandler.updateAccountMostRecentHPD(Trigger.new);
//        System.debug(LoggingLevel.DEBUG,updatedAccounts);
    }
}