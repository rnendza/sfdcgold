public class SObjectErrorCsv extends CsvGenerator {

    public String generateCsv( Map<Id,String> mErrorsByIds) {

        String s = line(new String[] {
                format('Id'),
                format('Error Message')
        });
        String baseUrl =  URL.getSalesforceBaseUrl().toExternalForm();

        for (Id sObjectId : mErrorsByIds.keySet()) {
            String idUrl = baseUrl+'/'+sObjectId;
            s += line(new String[] {
                    format(idUrl),
                    format(mErrorsByIds.get(sObjectId))
            });
        }
        return s;
    }
}