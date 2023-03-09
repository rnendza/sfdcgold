public without sharing class clRouteSchAdminOnly {

    public static final String MAP_KEY_ROUTES = 'ROUTE_DATA';
    public static final String MAP_KEY_ROUTE = 'ROUTE';

    /**
     * @return Ret
     */
    @AuraEnabled(Cacheable=true)
    public static ResponseDto retrieveRoutes(){
        ResponseDto dto = new ResponseDto();
        List<Route__c> allRoutes = clRouteSvc.retrieveAllRoutes();

        // slice to return only needed data.
        List<Route> routes = buildRoutesResponse(allRoutes);
        dto.isSuccess = !routes.isEmpty();
        dto.values.put(MAP_KEY_ROUTES,routes);
        return dto;
    }

    public static List<Route> buildRoutesResponse(List<Route__c> allRoutes) {
        List<Route> routes = new List<Route>();
        for(Route__c route : allRoutes) {
            routes.add(new Route(route));
        }
        return routes;
    }

    /**
     * Creates a new Route__c and Route_Account__c record(s) based on passed paramters.
     *
     * @param oldRouteId            The old route id to copy.
     * @param newRouteName          The new route name
     * @param iRouteCycleNumber     The new route cycle number.
     * @param processingLocation    The Route__c.Processing_Locatoin__c field.
     * @param collectionDate        The Route__c.Collection_Date__c field.
     *
     * @return                      A dto containing success / failure info
     */
    @AuraEnabled
    public static ResponseDto cloneRoute(   String oldRouteId, String newRouteName,
                                            Integer iRouteCycleNumber,String processingLocation) {
        ResponseDto dto = new ResponseDto();

        Route__c route = new Route__c();
        route.Name = newRouteName;
        route.Cycle_Number__c = iRouteCycleNumber;
        route.Processing_Location__c = processingLocation;
        insert route;

        List<Route_Account__c> newRas = [
                SELECT  Account__c,Route__c,
                        X1_Fill_Level__c,
                        X5_Fill_Level__c,
                        X20_Fill_Level__c,
                        X50_Fill_Level__c,
                        X100_Fill_Level__c
                FROM    Route_Account__c
                WHERE   Route__c = :oldRouteId
        ];
        for(Route_Account__c newRa : newRas) {
            newRa.Route__c = route.Id;
            newRa.Id = null;
        }
        insert newRas;

        if(newRas.isEmpty()) {
            dto.message = 'Unable to create route and associated accounts';
            dto.severity = 'error';
        } else {
            dto.isSuccess = true;
            // slice Route__c to only fields we want to return.
            Route routeCreated = new Route(route);
            dto.values.put(MAP_KEY_ROUTE,routeCreated);
            dto.severity = 'success';
            dto.message = 'Successfully Created route: '+route.Name + ' with  '+newRas.size() + ' accounts.';
        }
        return dto;
    }

    public class Route {
        @AuraEnabled public Id routeId;
        @AuraEnabled public String routeName;
        @AuraEnabled public Integer totalAccounts = 0;
        public Route(Route__c route) {
            this.routeId = route.Id;
            this.routeName = route.Name;
            this.totalAccounts = Integer.valueOf(route.Total_Accounts__c);
        }
    }
}