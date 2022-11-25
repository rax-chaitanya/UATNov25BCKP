//This class will be used for Tracking how many users access to the VisualForce page "Churn" that is
//on Customer Account records under the Custom Link: Revenue Retention and Growth Plays (SFDC-8206)
//Program Tracking object was created to store tracking records, therefore new record types for this 
//object can be defined to use and track other Visualforce pages by using this extension.
//         Dev Name: Luis Gonzalez  ----   22/Sep/2022
public without sharing class TrackingExtensionController {
    public Program_Tracking__c track {get;set;}
    public TrackingExtensionController(ApexPages.StandardController stdController) {
        Account acc = (Account) stdController.getRecord();
        track = new Program_Tracking__c(OwnerId = UserInfo.getUserId(), Customer_Account__c = acc.Id, Visitor__c = UserInfo.getUserId(), Visit_Date__c = System.today());
    }
    public Pagereference trackVisit(){
        insert track;
        return null;
    }
}