({
    helperMethod : function() {
        
    },
    getPicklistValues: function(component, event){
        console.log('Picklist helper method called');
        var action = component.get("c.getTypeOfDealFieldValue");
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                console.log('Successful server call for picklist values');
                var result = response.getReturnValue();
                var fieldMap = [];
                for(var key in result){
                    fieldMap.push({key: key, value: result[key]});
                }
                component.set("v.fieldMap", fieldMap);
            }
            else{
                //var error = response.getError();
                console.log('Error message');
            }
        });
        $A.enqueueAction(action);
    }
    
})