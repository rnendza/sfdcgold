public class clRouteAccountCsv {

    public String generateRouteAccountCsv(List<Route_Account__c> routeAccounts) {
        String s = line(new String[] {
                format('Route Account Id'),
                format('Route Account Name'),
                format('Route Id'),
                format('Route Name'),
                format('Stop #'),
                format('Account Id'),
                format('Account Name'),
                format('Collection Type'),
                format('X1 Fill Level'),
                format('X5 Fill Level'),
                format('X20 Fill Level'),
                format('X50 Fill Level'),
                format('X100 Fill Level'),
                format('Replenishment Type'),
                format('Created Date'),
                format('Created By Id'),
                format('Created By User')
        });
        //String baseUrl =  URL.getSalesforceBaseUrl().toExternalForm();

        for (Route_Account__c  ra: routeAccounts) {
            //String raUrl = baseUrl+'/'+Route_Account__c.Id;
            s += line(new String[] {
                    format(ra.Id),
                    format(ra.Name),
                    format(ra.Route__c),
                    format(ra.Route__r.Name),
                    format(ra.Stop_Number__c),
                    format(ra.Account__c),
                    format(ra.Account__r.Name),
                    format(ra.Collection_Type__c),
                    format(ra.X1_Fill_Level__c),
                    format(ra.X5_Fill_Level__c),
                    format(ra.X20_Fill_Level__c),
                    format(ra.X50_Fill_Level__c),
                    format(ra.X100_Fill_Level__c),
                    format(ra.Replenishment_Type__c),
                    format(ra.CreatedDate),
                    format(ra.CreatedById),
                    format(ra.CreatedBy.UserName)
            });
        }
        return s;
    }
    private String line(String[] cells) {
        return String.join(cells, ',') + '\n';
    }
    private String format(Decimal d) {
        return d != null ? '"' + Integer.valueOf(d) + '"' : '""';
    }
    private String format(DateTime dt) {
        return dt != null ? '"' + dt + '"' : '""';
    }
    private String format(String s) {
        return s != null ? '"' + s.escapeCsv() + '"' : '""';
    }
}