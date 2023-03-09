/**
 * Generally used as a performance improvement on costly global describes.
 */
global class CustomDescribe {
    private static Map<String, SobjectType> globalDescribe;

    global static Map<String,SObjectType> getGlobalDescribe() {
        if(globalDescribe == null) {
            globalDescribe = Schema.getGlobalDescribe();
        }
        return globalDescribe;
    }
}