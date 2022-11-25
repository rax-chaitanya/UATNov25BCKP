/**
* @description       : SFDC- 7195 - Email notification to Partner Contact when Sharing Notes On Opporutnities
* @author            : Rishabh Anand
* @group             : 
* @last modified on  : 04-20-2022
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
* Last Modified : July 2022
* Test Class - PartnerRolesEmailControllerTest
* Changes  : SFDC-7957 - Added if condition to check prEmail is not null 
**/
public class PartnerRolesEmailController {
    
    public static void processOpportunities(Set<Id> notesOppId){
        
        EmailTemplate  et = [Select Id,Name from EmailTemplate where Name = 'Partner Role Email Template'];
        String owEmailAddressId = generateOWEmailId();
        String oppEmail;
        String oppId;
        String oppName;
        List<String> prEmail = new List<String> ();
        for (Partner_Role__c partnerRoles : [SELECT Id,Name,Opportunity__c,
                                             Partner_Contact__c,Partner_Contact__r.Email,Partner_Company__c,
                                             Opportunity__r.Name,Opportunity__r.Id,Opportunity__r.OwnerId, Opportunity__r.Owner.Email
                                             FROM Partner_Role__c WHERE Opportunity__c IN: notesOppId])
        {
            oppEmail = partnerRoles.Opportunity__r.Owner.Email;
            oppId = partnerRoles.Opportunity__r.Id;
            oppName =  partnerRoles.Opportunity__r.Name;
            if(partnerRoles.Partner_Contact__r.Email != null){
                prEmail.add(partnerRoles.Partner_Contact__r.Email);
            }
        }
        
       try {
            //Added If condition by chaitanya to check if emails list is not null for 7957
            if(prEmail!=Null){
                Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
                Messaging.SingleEmailMessage mail1 = new Messaging.SingleEmailMessage();
                mail1.setSubject('A Note has been added on Opportunity '+ oppName);
                String mailbody = '';
                if(oppEmail!=Null){
                    msg.CcAddresses = new string[]{oppEmail};
                        mail1.CcAddresses = new string[]{oppEmail};
                            }
                msg.toaddresses=prEmail; 
                mail1.toaddresses=prEmail;
                msg= Messaging.renderStoredEmailTemplate(et.id, null, oppId);
                mailbody = string.valueof(msg.getHtmlBody()) + mailbody; 
                mail1.setHtmlBody(mailbody);              
                mail1.setOrgWideEmailAddressId(owEmailAddressId);            
                mail1.setSaveAsActivity(true);
                // Adding condition regarding SFDC-8437
                if((mail1.toaddresses != null && mail1.toaddresses.size() > 0) || (mail1.CcAddresses != null && mail1.CcAddresses.size() > 0)){
                    Messaging.sendEmail (new Messaging.SingleEmailMessage[] {mail1});    
                }
                
            }
        } 
       catch(exception ex){
            System.debug(LoggingLevel.Debug,'Unable to send email. Exception message :::'+ex.getMessage());
            ExceptionHandler.postToAll(ex);
        }
    }    
    public static String generateOWEmailId(){
        
        String owEmailAddressId='';
        String owEmailDisplayName = 'SF Email Alert';
        List<OrgWideEmailAddress> owea = new List<OrgWideEmailAddress>();
        
        owea = [SELECT Address,DisplayName FROM OrgWideEmailAddress where DisplayName =: owEmailDisplayName LIMIT 1];
        if (!owea.isEmpty()){
            owEmailAddressId = owea[0].Id;
        }
        return owEmailAddressId;
    }
}