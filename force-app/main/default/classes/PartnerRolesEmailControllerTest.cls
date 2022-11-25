/**
* @description       : Test Class for PartnerRolesEmailController
* @author            : Rishabh Anand
* @group             : 
* @last modified on  : 04-21-2022
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
@isTest
public with sharing class PartnerRolesEmailControllerTest {
    
    @TestSetup
    static void dataSetup(){
        
        UserRole SARole = [Select Id,Name from UserRole Where Name LIKE '%US SA%' LIMIT 1];
        
        user adminUser = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1].Id,
            LastName = 'testAdminUser123',
            Email = 'puser000@amamama.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = SARole.Id
        );
        Insert adminUser;
        System.runAs(adminUser){
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
            
            Trigger_Manager__c accTm = new Trigger_Manager__c (Name ='AccountContactRelation',Is_Active__c = true);
            insert accTm;
            
            TestClassUtility.setTestSetupData();            
            Id accRID= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner Company').getRecordTypeId(); 
            Id conRID= Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Partner').getRecordTypeId(); 
            
            Account oppAcc = new Account(Name='Test Account12345',Partner_Account_Status__c='Approved',BillingCountry='India',ShippingCountry='India',RecordTypeId = accRID);
            insert oppAcc;
            
            List<Account> accList = new List<Account>();
            Account acc = new Account(Partner_Account_Status__c='Approved',ParentId=oppAcc.Id,Agreed_By_Timestamp__c=System.now().addDays(-10),Contract_Signed_Date__c =System.today(),Partner_Level__c='Referral',RecordTypeId= accRID,Name='Test Account1234',BillingCountry='India',ShippingCountry='India');
            accList.add(acc);
            
            Account childAcc = new Account(Partner_Company__c=acc.Id ,Name='childAcc 11Account',Partner_Account_Status__c='Approved',ParentId=acc.Id,Agreed_By_Timestamp__c=System.now().addDays(-10),Contract_Signed_Date__c =System.today(),Partner_Level__c='Referral',Company_Name__c=oppAcc.Id, RecordTypeId = Label.Account_Prospect_RecordType_ID);
            accList.add(childAcc);
            Insert accList;
            
            List<Contact> conList = new List<Contact>();
            Contact con = new Contact(firstname='Test Contact',RecordTypeId= conRID,LastName='Test Last',AccountId=oppAcc.id,HasOptedOutOfEmail=false,Btlk_Country__c='India',Btlk_Sate_Province__c='Karnataka',Email='tst.22@tst.com');
            conList.add(con);
            
            Contact cont = new Contact(firstname='New Contact',RecordTypeId= conRID,LastName='Test New',AccountId=oppAcc.id,HasOptedOutOfEmail=false,Btlk_Country__c='India',Btlk_Sate_Province__c='Karnataka',Email='tst.11@tst.com');
            conList.add(cont);
            Insert conList;
            
            oppAcc.Primary_Member__c = con.Id;
            update oppAcc;
            
            Opportunity opty = new Opportunity(Quotingsystem__C='Datapipe',Partner_Company__c=oppAcc.Id,Was_a_Partner_Involved__c='Yes',Type='AWS',Name='Test Opport',StageName='Stage 1 - Planning & Identification',CloseDate=System.today().addDays(15), Lead_Id__C = 'L-GARBAGE');
            insert opty;
            
            List<Partner_Role__c> prList = new List<Partner_Role__c>();
            Partner_Role__c pRoles=new Partner_Role__c(Has_Attachment__c =true,Opportunity__c=opty.Id,Partner_Contact__c=con.Id,Partner_Company__c=oppAcc.Id,Role__c='Influence',Status__c='Approved',Justification__c='Testing',Commission_Role__c='Credit to this Opp-Acct');
            prList.add(pRoles); 
            
            Partner_Role__c pRole=new Partner_Role__c(Has_Attachment__c =true,Opportunity__c=opty.Id,Partner_Contact__c=cont.Id,Partner_Company__c=oppAcc.Id,Role__c='Influence',Status__c='Approved',Justification__c='Testing',Commission_Role__c='Credit to this Opp-Acct');
            prList.add(pRole);
            Insert prList;
        }   
    }
    
    @isTest
    private static void processOpportunitiesTest(){
        
        Test.startTest();
        System.assertEquals(0, Limits.getEmailInvocations(), 'No emails should be sent');
        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Name='Test Opport'];
        Set<Id> oppIds = new Set<Id>();
        oppIds.add(opp.Id);
        PartnerRolesEmailController.processOpportunities(oppIds); 
        System.assertEquals(1, Limits.getEmailInvocations(), 'Emails should be sent');
        Test.stopTest();
        
    }
    
}