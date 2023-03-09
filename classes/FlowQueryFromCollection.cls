global class FlowQueryFromCollection {

    @InvocableMethod( label='Query From List' )
    global static List<QueryResult> query( List<QueryRequest> requests ) {
        
        QueryRequest request = requests[0];

        String query = 'SELECT ';

        SObjectType objType = Schema.getGlobalDescribe().get( request.objectName );
        Map<String,Schema.SObjectField> fieldMap = objType.getDescribe().fields.getMap();
        
        // Get all of the fields on the object
        Set<String> fieldNames = fieldMap.keySet();

        String listOfIds = '';
        
        for ( String s : request.ids ) {
            listOfIds += '\''+s+'\',';
        }

        listOfIds = listOfIds.removeEnd(',');
        
        System.debug( listOfIds );

        // Build a Dynamic Query String.
        String soqlQuery = ' SELECT ' + String.join( new List<String>( fieldNames ) , ',' ) + ' FROM ' + request.objectName + ' Where ' + request.fieldName + ' in (' + listOfIds + ')' ;

        System.debug( soqlQuery );
        System.debug( soqlQuery.right(75) );

        // Need to return a generic list of sObject because we don't necessarily know exactly what the object is.
        List<sObject> records = Database.query( soqlQuery );

        QueryResult result = new QueryResult();
        result.records = records;

        return new List<QueryResult>{result};
    }

    global class QueryRequest {

        @InvocableVariable(required=true)
        global String objectName;

        @InvocableVariable(required=true)
        global String fieldName;

        @InvocableVariable(required=true)
        global List<String> ids;

    }

    global class QueryResult {
        
        @InvocableVariable
        global List<sObject> records;

    }

    class CustomQueryException extends Exception {
    }

}