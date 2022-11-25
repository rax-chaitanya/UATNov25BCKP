({
    doInit: function (component, event, helper) {
        // LTCSF-140 : fetch Contact RecordTypes available for current user
        helper.fetchContactRecordTypes(component, event, helper);   
    },
    searchContactAndLead: function (component, event, helper) {
        var frstName = component.find('inputfrstName').get('v.value');
        var lstName = component.find('inputlstName').get('v.value');
        
        //Validating the FirstName and LastName fields against Null check
        if(frstName != '' && frstName != undefined && lstName != '' && lstName != undefined){            
            console.log('Searching records');
            var emailValid = component.find('inputemail').checkValidity();
            //console.log('emailValid--->'+emailValid);
            if (emailValid) {
                helper.searchContactAndLead(component, event, helper);
            } else {
                component.find('inputemail').showHelpMessageIfInvalid();
            }
        }else{
            if(frstName == '' || frstName == undefined)
                component.find('inputfrstName').showHelpMessageIfInvalid();
            
            if(lstName == '' || lstName == undefined)
                component.find('inputlstName').showHelpMessageIfInvalid();
        }
        // User Story :- SFDC-7663
        helper.getAccountList(component);
    },
    createAcRecord : function (component, event, helper) {
        //US:-SFDC-7663
        // Checking that as per the text enter in company field is there any such company is present or not
        var accountIDValueCheck = component.get('v.accountID');
         var IDsValue = ''
         if(!$A.util.isUndefinedOrNull(accountIDValueCheck)){
             // If we found any company record we are assigning that record to lookup field else null
             var IDsValue = component.get('v.accountID');
           }
        ////US:-SFDC-7663
        var wsUrl = JSON.stringify(component.get("v.pageReference").state.ws);
        var AccountId;
        console.log('wsUrl::' + wsUrl);
        if(!$A.util.isUndefinedOrNull(wsUrl)){
          var wsUrls = [];  
          wsUrls = wsUrl.split('/');
          AccountId = wsUrls[4];  
        }        
        
        var createRecordEvent = $A.get("e.force:createRecord");
        var selectedRecordTypeId = event.getParam("value");
        createRecordEvent.setParams({
            "entityApiName": "Contact",
            "recordTypeId": selectedRecordTypeId,
            "defaultFieldValues":{
                "FirstName" : component.get("v.firstName"),
                "LastName" : component.get("v.lastName"),
                "Email" : component.get("v.email"),
                "AccountId" : IDsValue
            }
        });
        createRecordEvent.fire();
    },
    // this function automatic call by aura:waiting event  
    showSpinner: function(component, event, helper) {
        // make Spinner attribute true for display loading spinner 
        component.set("v.Spinner", true); 
        $A.util.removeClass(spinner, "slds-hide");
        $A.util.addClass(spinner, "slds-show");
    },
    
    // this function automatic call by aura:doneWaiting event 
    hideSpinner : function(component,event,helper){
        // make Spinner attribute to false for hide loading spinner    
        component.set("v.Spinner", false);
        $A.util.addClass(spinner, "slds-hide");
        $A.util.removeClass(spinner, "slds-show");
    },
    
    resetForm : function(component,event,helper){
        component.set("v.firstName",'');
        component.set("v.lastName",'');
        component.set("v.email",'');
        component.set("v.companyName",'');
    }
})