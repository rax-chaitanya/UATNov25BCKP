/**
* @description       : Test Class for OpportunityCloseWonHelper
* @author            : Someshwar
* @group             : 
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@isTest (SeeAllData=false)
public class OpportunityCloseWonHelperTest {
    
    static Testmethod void duplicateContactTest(){
        List<Trigger_Manager__c> tmList = new List<Trigger_Manager__c>();
        Trigger_Manager__c tM = new Trigger_Manager__c (Name ='ContactTgr',Is_Active__c = true);
        tmList.add(tM);
        
        Trigger_Manager__c accTm = new Trigger_Manager__c (Name ='AccountContactRelation',Is_Active__c = true);
        tmList.add(accTm);
        
        Trigger_Manager__c acrTm = new Trigger_Manager__c (Name ='AcrTgr',Is_Active__c = true);
        tmList.add(acrTm);
        
        Trigger_Manager__c clogTm = new Trigger_Manager__c (Name ='cLogTgr',Is_Active__c = true);
        tmList.add(clogTm);
        
        insert tmList;
        
        List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Lead', CompName__c = 'Lead', SourceField__c = 'Country', TargetField__c = 'Territory__c'));
        insert fieldMappings;
        
        List<BrightTALK__BrightTalk_State_Codes__c> btlkstatecode = new List<BrightTALK__BrightTalk_State_Codes__c>();
        btlkstatecode.add(new BrightTALK__BrightTalk_State_Codes__c(Name = 'Florida', BrightTALK__State_Alpha_2__c = 'FL'));
        insert btlkstatecode;
        
        List<CountryTerritoryMapping__c> mappings = new List<CountryTerritoryMapping__c>();
        mappings.add(new CountryTerritoryMapping__c(Name = 'United States', Territory_Name__c = 'US/CANADA'));
        mappings.add(new CountryTerritoryMapping__c(Name = 'Canada', Territory_Name__c = 'US/CANADA'));
        insert mappings;
        
     Id devRecordTypeId3 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Company').getRecordTypeId();
     Id condevRecordTypeId3 = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect Account').getRecordTypeId();
        Account a = new Account(RecordTypeId =devRecordTypeId3,Name='Test Account1234',BillingCountry='Australia',ShippingCountry='Australia',Partner_Account_Status__c='Approved');
        insert a;
         Account acct = new Account(RecordTypeId =devRecordTypeId3,Name='Test Account12345',BillingCountry='Australia',ShippingCountry='Australia',Partner_Account_Status__c='Approved');
        insert acct;
        Contact c = new Contact(RecordTypeId =condevRecordTypeId3,firstname='Test Contact',LastName='Test Last',AccountId=acct.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c;
        Account ac = new Account(RecordTypeId =devRecordTypeId,Name='Test C Account',Company_Name__c=a.Id,DDI__c='123456');
        insert ac;
      
        AccountContactRelation acr2=new AccountContactRelation(Contactid=c.id,Roles='Business',Accountid=ac.id,Ticket_Notify__c=false);
        insert acr2;
        acr2.roles='Primary Contact';
        update acr2;
        AccountContactRelation acr1=[select id,Roles,contactid,Ticket_Notify__c from AccountContactRelation where Accountid=:ac.id Limit 1];
       //insert acr1; 
        acr1.roles='Administrative';
        //acr1.Account_ID__c = acr2.Roles;
        //acr1.c = acr1.Id;
        acr1.Account_Contact_Ids__c = c.Id;
        acr1.Account_Contact_Ids__c=acr2.Id;
        acr1.Account_Contact_Ids__c=acr1.Id;
        acr1.Account_Contact_Ids__c=acct.Id;

        
        update acr1;
        Test.startTest();
        OpportunityCloseWonHelper.createDuplicateContact(c.Id, acct.Id);
        Test.stopTest();
        AccountContactRelation acr3=new AccountContactRelation(id=acr1.id,Contactid=c.id,Accountid=acct.id,Roles='Primary Contact');
             
            //insert acr3;
               acr3.Roles='Primary Contact';
               acr3.Roles='Business';
        
            update acr3;
        
    {
        Account thePersonAccount = new Account(Id = acct.Id);
        //thePersonAccount.recordTypeId = personAcctRecordTypeId;
        update thePersonAccount;
    }
     
}
}