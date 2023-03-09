public with sharing class LookupUserController {

    private final static Integer MAX_RESULTS = 20;

    @AuraEnabled(Cacheable=true)
    public static List<LookupSearchResult> search(String searchTerm, List<String> selectedIds) {

        searchTerm += '*';

        List<List<SObject>> searchResults = [
                FIND :searchTerm
                IN ALL FIELDS
                        RETURNING
                        User(Id, Name, Email WHERE id NOT IN :selectedIds)
                LIMIT :MAX_RESULTS
        ];
        List<LookupSearchResult> results = new List<LookupSearchResult>();

        // Extract Accounts & convert them into LookupSearchResult
        String userIcon = 'standard:user';
        User[] users = ((List<User>) searchResults[0]);
        for (User user : users) {
            results.add(
                    new LookupSearchResult(
                            user.Id,
                            'User',
                            userIcon,
                            user.Name,
                            'User • ' + user.Email
                    )
            );
        }
        return results;
    }
}