/**
 * AggregateResultsIterable assist with performing an aggregate query in a Batch Start Method
 * (alternative to QueryLocator)
 */
global class AggregateResultIterable implements Iterable<AggregateResult> {
    private String query;

    global AggregateResultIterable(String soql){
        query = soql;
    }

    global Iterator<AggregateResult> Iterator(){
        return new AggregateResultIterator(query);
    }
}