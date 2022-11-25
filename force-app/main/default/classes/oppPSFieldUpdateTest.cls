@isTest
public class oppPSFieldUpdateTest {
    Private static testmethod void OpportunityFocusAreaHandlerTest(){
        List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Lead', CompName__c = 'Lead', SourceField__c = 'Country', TargetField__c = 'Territory__c'));
        insert fieldMappings;
        
        List<Opportunity> opplst = new List<Opportunity>();
        Account a = new Account(Name='Test Account1234',BillingCountry='India',ShippingCountry='India');
        insert a;
        Id CustomerRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        Account ac = new Account(Name='Test C Account',Company_Name__c=a.Id,ShippingCountry='India',RecordTypeId=CustomerRTypeId);
        insert ac;
        List<Trigger_Manager__c> tms = new List<Trigger_Manager__c>();
        tms.add( new Trigger_Manager__c(name='OpportunitySplitTgr',Is_Active__c=false));
        tms.add( new Trigger_Manager__c(name='OpportunityFocusAreaTgr',Is_Active__c=false));
        insert tms;
        
        Opportunity opty = new Opportunity(Name='Test Opport',Type='Azure',AccountId=a.Id,Account__c=ac.id,DDI__c='12345655',StageName='Stage 1 - Planning & Identification',CloseDate=System.today());
        insert opty;
        opty.stageName='Stage 3 - Proposal & Quote';
        opty.Amount=24000;
        opty.Focus_Area__c='Amazon;Data Services'; 
        Update opty;
        opplst.add(opty);
        oppPSFieldUpdate.updateOppPSValue(opplst);
        Opp_FocusArea__c OppFocusArea=New Opp_FocusArea__c(Opportunity__c=opty.id,Name='Test FocusArea');
        Insert OppFocusArea;
        OppFocusArea.Name='Test Update';
        Update OppFocusArea;
        
        
    }
}