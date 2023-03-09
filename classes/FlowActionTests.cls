@isTest
public class FlowActionTests {
    
    static testmethod void testFlow() {
        
        Account a = new Account(Name='test');
        insert a;
        
        FlowQueryFromCollection.QueryRequest r = new FlowQueryFromCollection.QueryRequest();
        r.objectName = 'Account';
        r.fieldName = 'Id';
        r.ids = new List<String>{a.Id};
        
        List<FlowQueryFromCollection.QueryRequest> requestList = new List<FlowQueryFromCollection.QueryRequest>{ r };
            
        FlowQueryFromCollection.query(requestList);
        
	}
    
}