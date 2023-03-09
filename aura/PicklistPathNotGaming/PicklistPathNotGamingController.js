/**
 * Created by CedricN on 8/4/2022.
 */

({
    handleSelect : function (component, event, helper) {
        var stepName = event.getParam("detail").value;


        component.set("v.PicklistField", stepName);





        component.find("record").saveRecord($A.getCallback(function(response) {
            if (response.state === "SUCCESS") {
                $A.get('e.force:refreshView').fire();
            }
        }));
    }

})