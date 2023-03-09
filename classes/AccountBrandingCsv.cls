public class AccountBrandingCsv extends CsvGenerator implements ICsvGenerator{

    public String generateCsv(List<Account> accounts) {
        String s = line(new String[] {
                format('Id'),
                format('Account Url'),
                format('Branding'),
                format('Physical State'),
                format('Record Type'),
                format('Type'),
                format('Created Date'),
                format('Created By')
        });
        String baseUrl =  URL.getSalesforceBaseUrl().toExternalForm();

        for (Account account: accounts) {
            String tsUrl = baseUrl+'/'+account.Id;
            s += line(new String[] {
                    format(account.Id),
                    format(tsUrl),
                    format(account.Branding__c),
                    format(account.ShippingState),
                    format(account.RecordType.DeveloperName),
                    format(account.Type),
                    format(account.CreatedDate),
                    format(account.createdBy.Username)
            });
        }
        return s;
    }
}