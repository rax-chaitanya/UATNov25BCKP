@isTest
public with sharing class OpportunityFocusAreaHandler_Test {
    private static testmethod void OpportunityFocusAreaHandlerTest(){
        
        Test.startTest();
        List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Lead', CompName__c = 'Lead', SourceField__c = 'Country', TargetField__c = 'Territory__c'));
        insert fieldMappings;  
        
        TestDataFactory.getTriggerManagers();
        TestDataFactory.getOrgConstants();
        TestDataFactory.createFeatureFlags();
        
        Account a = new Account(Name='Test Account1234',BillingCountry='India',ShippingCountry='India');
        insert a;
        Id CustomerRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        Account ac = new Account(Name='Test C Account',Company_Name__c=a.Id,ShippingCountry='India',RecordTypeId=CustomerRTypeId);
        insert ac;
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opty = new Opportunity(Name='Test Opport',Type='Azure',AccountId=a.Id,Account__c=ac.id,DDI__c='12345655',StageName='Stage 1 - Planning & Identification',CloseDate=System.today().addDays(15));
        insert opty;
        Opp_FocusArea__c OppFocusArea=New Opp_FocusArea__c(Opportunity__c=opty.id,Name='Test FocusArea');
        Insert OppFocusArea;
        opportunityHandler.firstTgrRun = true;
        OppFocusArea.Name='Test Update';
        Update OppFocusArea;
        opportunityHandler.firstTgrRun = true;
        Delete OppFocusArea; 
        Test.stopTest();
       }
    
    private static testmethod void OpportunityFocusAreaHandlerTest1(){
        Test.startTest();
        List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Lead', CompName__c = 'Lead', SourceField__c = 'Country', TargetField__c = 'Territory__c'));
        insert fieldMappings;  
        TestDataFactory.getTriggerManagers();
        TestDataFactory.getOrgConstants();
        TestDataFactory.createFeatureFlags();
        Account a = new Account(Name='Test Account1234',BillingCountry='India',ShippingCountry='India');
        insert a;
        Id CustomerRTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId();
        Account ac = new Account(Name='Test C Account',Company_Name__c=a.Id,ShippingCountry='India',RecordTypeId=CustomerRTypeId);
        insert ac;
        List<Opportunity> opplist = new List<Opportunity>();
        Opportunity opty1 = new Opportunity(Name='Test Opport',Type='Professional Services',AccountId=a.Id,Account__c=ac.id,DDI__c='12345655',StageName='Stage 1 - Planning & Identification',CloseDate=System.today().addDays(15),Focus_Area__c='Amazon;Data Services');
        insert opty1;
        opplist.add(opty1);
        Opp_FocusArea__c OppFocusArea1=New Opp_FocusArea__c(Opportunity__c=opty1.id,Name='Test FocusArea2');
        Insert OppFocusArea1;
        oppPSFieldUpdate.updateOppPSValue(opplist);
        opportunityHandler.firstTgrRun = true;
        opty1.Focus_Area__c = 'Amazon';
        update opty1;
        Test.stopTest();
}
    
}