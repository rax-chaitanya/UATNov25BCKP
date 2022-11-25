@isTest(seeAllData = true)
public class OpportunityCloseWonWizardController_Test {
    
    
    @IsTest static void testOptyCloseWonWizardNegative6(){
    Id devRecordTypeId3 = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Company').getRecordTypeId();
     Id condevRecordTypeId3 = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Standard').getRecordTypeId();
        Id devRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        
        Account a = new Account(RecordTypeId =devRecordTypeId3,Name='Test Account1234',BillingCountry='Australia',ShippingCountry='Australia',Partner_Account_Status__c='Approved');
        insert a;
         Account a1 = new Account(RecordTypeId =devRecordTypeId3,Name='Test Account12345',BillingCountry='Australia',ShippingCountry='Australia',Partner_Account_Status__c='Approved');
        insert a1;
        Contact c = new Contact(RecordTypeId =condevRecordTypeId3,firstname='Test Contact',LastName='Test Last',AccountId=a1.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c;
        Account ac = new Account(RecordTypeId =devRecordTypeId,Name='Test C Account',Company_Name__c=a.Id,DDI__c='123456');
        insert ac;
      Test.startTest();
        AccountContactRelation acr2=new AccountContactRelation(Contactid=c.id,Roles='Billing',Accountid=ac.id);
        insert acr2;
        AccountContactRelation acr=[select id,roles,contactid from AccountContactRelation where Accountid=:ac.id Limit 1];
       acr.roles='Billing';
        update acr;
        Opportunity opt = new Opportunity(DDI__c='12345',Was_a_Partner_Involved__c='No',Why_Did_We_Win__c='Contract negotiations',Name='Test Opport',Type='Azure',
        AccountId=a.Id,StageName='Stage 1 - Planning & Identification',
        CloseDate=System.today().addDays(15),Account__c=ac.id);
        List<Opportunity> li=new List<Opportunity>();
        li.add(opt);
        insert li;
      
          Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        Account ac2 = new Account(Name='Test C Account',Company_Name__c=a.Id,Old_Record_Id__c='',RecordTypeId =devRecordTypeId2);
        insert ac2;
        
        ApexPages.currentPage().getParameters().put('id', opt.Id); 
        
        OpportunityCloseWonWizardController optycw = new OpportunityCloseWonWizardController();
        System.assert(!optycw.getIsPartnerInvolved(),true);
        
        optycw.accDDI = null;
        optycw.contact = c;
        optycw.recordID = acr.id;
        optycw.pageNumber =3;
        User u = [Select Id,Region__c from user where isActive=:true AND Region__c=:null Limit 1];
        
        optycw.save();
        optycw.LoadAccRoles();
        system.runAs(u){
            system.debug('After runAs');
            optycw.recordID = acr.id;
            optycw.pageNumber =3; 
            optycw.save();
            system.debug('Current user'+UserInfo.getUserName());
        }
        optycw.saveAndNextUs1();
        optycw.saveAndNextUs2();
        optycw.saveAndNextUs3();
        
        optycw.saveAndNextUs4();
       /* optycw.saveAndNextUs5();
        optycw.SaveContact();
        optycw.LoadAccRoles();
        optycw.RsOppList=li;
        optycw.getChildOpportunities();
        
        
        optycw.RSCloudContinue();
        optycw.getCustomerRecordTypeID();
        optycw.getEConnectDocumentsURL();
        optycw.getRaptorDocumentsURL();
        //28-Mar-2018
        optycw.getRedirectToOpp();
        optycw.query('Unknown');
        optycw.account = null;
        optycw.saveandnextUS2();
        optycw.PrimaryQuoteUpdate();*/
        test.stopTest();
    }
    @isTest
    static void accountContactRoleTest1(){
    Trigger_Manager__c Tm = new Trigger_Manager__c (Name ='ContactTgr1',Is_Active__c = true);
    insert Tm;
        Id StandardCmpRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Company').getRecordTypeId();
        Id ProspectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        
        Account cmp = new Account(Name='Test Account1234',RecordTypeId=StandardCmpRecordTypeId,Partner_Account_Status__c ='Approved',phone ='1212121212', BillingCountry = 'India', ShippingCountry = 'India',BillingState='Karnataka');
        insert cmp;
         Account cmp1 = new Account(Name='Test Account12634',RecordTypeId=StandardCmpRecordTypeId,Partner_Account_Status__c ='Approved',phone ='12121271212', BillingCountry = 'India', ShippingCountry = 'India',BillingState='Karnataka');
        insert cmp1;
        Account pac = new Account(Name='Test C Account',Company_Name__c=cmp.Id,RecordTypeId=ProspectRecordTypeId,phone ='1212121212');
        insert pac;
         Account pac2 = new Account(Name='Test C Account2',Company_Name__c=cmp.Id,RecordTypeId=ProspectRecordTypeId,phone ='1212412166');
        insert pac2;
        Contact c = new Contact(firstname='Test Contact',LastName='Test Last',AccountId=cmp1.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c;
        //Contact c1 = new Contact(firstname='Test Contact2',LastName='Test Last',AccountId=pac.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        //insert c1;
         Contact c2 = new Contact(firstname='Test Contact3',LastName='Test Last',AccountId=cmp.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c2;
        
        AccountContactRelation acr= new AccountContactRelation(Accountid=pac.id,Contactid=c.id,Roles='Billing');
        //insert acr;
       // delete acr;
         //Test.startTest();
    
Opportunity opt = new Opportunity(Was_a_Partner_Involved__c='No',Why_Did_We_Win__c='Contract negotiations',Name='Test Opport',Type='Azure',
        AccountId=cmp.Id,StageName='Stage 1 - Planning & Identification',
        CloseDate=System.today().addDays(15),Account__c=pac.id);
        List<Opportunity> li=new List<Opportunity>();
        li.add(opt);
        
        insert li;
      
        //  Id devRecordTypeId2 = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
       // Account ac2 = new Account(Name='Test C Account',Company_Name__c=a.Id,Old_Record_Id__c='',RecordTypeId =devRecordTypeId2);
        //insert ac2;
        ApexPages.currentPage().getParameters().put('id', opt.Id); 
        
        OpportunityCloseWonWizardController optycw = new OpportunityCloseWonWizardController();
        System.assert(!optycw.getIsPartnerInvolved(),true);
        Test.startTest();
        optycw.accDDI = null;
        optycw.contact = c;
        optycw.recordID = acr.id;
        optycw.pageNumber =3;
        User u = [Select Id,Region__c from user where isActive=:true AND Region__c=:null Limit 1];
       
        optycw.save();
        optycw.LoadAccRoles();
        system.runAs(u){
            system.debug('After runAs');
            optycw.recordID = acr.id;
            optycw.pageNumber =3; 
            optycw.save();
            system.debug('Current user'+UserInfo.getUserName());
        }
        optycw.saveAndNextUs1();
        optycw.saveAndNextUs2();
        optycw.saveAndNextUs3();
        
        optycw.saveAndNextUs4();
        optycw.saveAndNextUs5();
        optycw.SaveContact();
        optycw.LoadAccRoles();
        optycw.RsOppList=li;
        optycw.getChildOpportunities();
        
        
        optycw.RSCloudContinue();
        optycw.getCustomerRecordTypeID();
        optycw.getEConnectDocumentsURL();
        optycw.getRaptorDocumentsURL();
        //28-Mar-2018
        optycw.getRedirectToOpp();
        optycw.query('Unknown');
        optycw.account = null;
        optycw.saveandnextUS2();
        //optycw.PrimaryQuoteUpdate();
        test.stopTest();
    }
  /*   @isTest
    static void accountContactRoleTest1_1(){
    Trigger_Manager__c Tm = new Trigger_Manager__c (Name ='ContactTgr1',Is_Active__c = true);
    insert Tm;
   user u= [SELECT Name FROM user WHERE Id = :UserInfo.getUserId()];
   system.runas(u){
        Id StandardCmpRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Standard Company').getRecordTypeId();
        Id ProspectRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Prospect').getRecordTypeId();
        Account cmp = new Account(Name='Test Account1234',RecordTypeId=StandardCmpRecordTypeId,Partner_Account_Status__c ='Approved',phone ='1212121212', BillingCountry = 'India', ShippingCountry = 'India',BillingState='Karnataka');
        insert cmp;
        Account cmp1 = new Account(Name='Test Account12354',RecordTypeId=StandardCmpRecordTypeId,Partner_Account_Status__c ='Approved',phone ='12125121212', BillingCountry = 'India', ShippingCountry = 'India',BillingState='Karnataka');
        insert cmp1;
        Account pac = new Account(Name='Test C Account',Company_Name__c=cmp.Id,RecordTypeId=ProspectRecordTypeId,phone ='1212121212');
        insert pac;
         Account pac2 = new Account(Name='Test C Account2',Company_Name__c=cmp.Id,RecordTypeId=ProspectRecordTypeId,phone ='1212412166');
        insert pac2;
        Contact c = new Contact(firstname='Test Contact',LastName='Test Last',AccountId=cmp1.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c;
        Contact c1 = new Contact(firstname='Test Contact2',LastName='Test Last',AccountId=pac.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c1;
         Contact c2 = new Contact(firstname='Test Contact3',LastName='Test Last',AccountId=cmp.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
        insert c2;
      Account cmp2 = new Account(Name='Test Account1234',RecordTypeId=StandardCmpRecordTypeId,Partner_Account_Status__c ='Approved',phone ='1212121212', BillingCountry = 'India', ShippingCountry = 'India',BillingState='Karnataka');
        insert cmp2;
        Contact c3 = new Contact(firstname='Test Contact90',LastName='Test Last890',AccountId=cmp2.id,mailingpostalcode='2324',Mailingcity='Test',MailingStreet='Test',Mailingcountry='United States',mailingstate='California');
     insert c3;
        
 
      //  AccountContactRelation acr= new AccountContactRelation(Accountid=pac.id,Contactid=c.id,Roles='Primary Contact');
      // insert acr;
       /* AccountContactRelation acr2= new AccountContactRelation(Accountid=pac.id,Contactid=c2.id,Roles='Primary Contact');
        insert acr2;
       // delete acr;
        
    
 Opportunity opt = new Opportunity(Was_a_Partner_Involved__c='No',Why_Did_We_Win__c='Contract negotiations',Name='Test Opport',Type='Azure',
        AccountId=cmp.Id,StageName='Stage 1 - Planning & Identification',
        CloseDate=System.today().addDays(15),Account__c=pac.id);
       // List<Opportunity> li=new List<Opportunity>();
       // li.add(opt);
        insert opt;
      
        ApexPages.currentPage().getParameters().put('id', opt.Id); 
        
        OpportunityCloseWonWizardController optycw = new OpportunityCloseWonWizardController();
        System.assert(!optycw.getIsPartnerInvolved(),true);
        
        optycw.accDDI = null;
        optycw.contact = c;
      //  optycw.recordID = acr.id;
        optycw.pageNumber =3;
       // User u = [Select Id,Region__c from user where isActive=:true AND Region__c=:null Limit 1];
        Test.startTest();
        optycw.save();
       // optycw.LoadAccRoles();
        system.runAs(u){
            system.debug('After runAs');
           // optycw.recordID = acr.id;
            optycw.pageNumber =3; 
            optycw.save();
            system.debug('Current user'+UserInfo.getUserName());
        }
        optycw.saveAndNextUs1();
        optycw.saveAndNextUs2();
        optycw.saveAndNextUs3();
        
        optycw.saveAndNextUs4();
        optycw.saveAndNextUs5();
        optycw.SaveContact();
        optycw.LoadAccRoles();
        //optycw.RsOppList=li;
        optycw.getChildOpportunities();
        
        
        optycw.RSCloudContinue();
        optycw.getCustomerRecordTypeID();
        optycw.getEConnectDocumentsURL();
        optycw.getRaptorDocumentsURL();
        //28-Mar-2018
        optycw.getRedirectToOpp();
        optycw.query('Unknown');
        optycw.account = null;
        optycw.saveandnextUS2();
        optycw.PrimaryQuoteUpdate();
        test.stopTest();
    }
    }*/
     @IsTest static void withaccounttest(){

Account a = new Account(Name='Test Account1234',BillingCountry='India',ShippingCountry='India',RecordTypeId = Label.Standard_Company_RecordTypeId);
        insert a;
        Account a1 = new Account(Name='Test Account',BillingCountry='India',ShippingCountry='India',RecordTypeId = Label.Standard_Company_RecordTypeId);
        insert a1;
        Contact c = new Contact(firstname='Test Contact',LastName='Test Last',AccountId=a.id,MailingCountry='India',Email='test.t@test.com',
                                MailingStreet='Whitefield',Phone='12345676',MailingCity='Bangalore',MailingPostalCode='560066',MailingState='Karnataka');
        // insert c;
        Account ac = new Account(Name='Test C Account',Company_Name__c=a.Id,RecordTypeId = Label.Account_Prospect_RecordType_ID,BillingCountry='India',ShippingCountry='India');
        insert ac;
        Contact c1 = new Contact(firstname='Test Contact',LastName='Test Last',AccountId=a.id);
        insert c1; 
        Opportunity opty = new Opportunity(Was_a_Partner_Involved__c='Yes',Type='AWS',Name='Test Opport',AccountId=a.Id,Account__c=ac.id,DDI__c='12345655',StageName='Stage 1 - Planning & Identification',QuotingSystem__c='Rackspace',Expected_Revenue_Start_Date__c=System.today(),CloseDate=System.today().addDays(15),Cloud_Contract_Type__c='Regular',Category__c='Downgrade');
        insert opty;
        ApexPages.currentPage().getParameters().put('id', opty.Id); 
       // ApexPages.currentPage().getParameters().put('aid', ac.Id); 
        Accountcontactrelation acr= new Accountcontactrelation(Contactid=c1.id,Roles='Technical',Accountid=a1.id);
        insert acr;
        OpportunityCloseWonWizardController optycw = new OpportunityCloseWonWizardController();
          optycw.saveAndNextUs5();
        }


  // Method:
  //  relatedAccountOwnersNotUpdated()
  // Description:
  //  It was determined that it is not correct for Accounts with the same DDI as the Opportunity being set to Closed/Won to have the owner overwritten to be equal to the owner of the Opportunity unless 
  //  the Account owners are Integration API users. This test demos a case where the Account related to the opportunity being set to ClosedWon does not have its owner set to be equal to the Opportunity 
  //  owner upon hitting the final save button in the Closed/Won Wizard class.
  // Expected output:
  //  The OwnerIds of the Account records remain unchanged
  @IsTest static void relatedAccountOwnersNotUpdated() {

    // Get the profile of the expected users
    List<Profile> profileList = [SELECT Id, Name FROM Profile WHERE Name = 'Rackspace Seller-US' LIMIT 1];

    // Generate test users
    User testUser1 = new User(Alias = 'test1', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting1',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = profileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting1@testorg.com');
    insert testUser1;

    User testUser2 = new User(Alias = 'test2', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting2',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = profileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting2@testorg.com');
    insert testUser2;

    // Create standard account which will be the parent account of the account related to the opportunity
    Account testParentAccount = new Account(Name='Test Account1234',
                                            BillingCountry='India',
                                            ShippingCountry='India',
                                            RecordTypeId = Label.Standard_Company_RecordTypeId,
                                            OwnerId = testUser1.Id,
                                            CurrencyIsoCode = 'USD');
    insert testParentAccount;

    System.debug('The id of the test account is: ' + testParentAccount.Id);

    // Create customer account which will be the account related to the opportunity
    Account testChildAccount = new Account(Name='Test Account1234',
                                           BillingCountry='India',
                                           ShippingCountry='India',
                                           RecordTypeId = Label.AccountCustomerRecordTypeId, 
                                           Company_Name__c = testParentAccount.Id, 
                                           ParentId = testParentAccount.Id, 
                                           DDI__c = '1937560',
                                           OwnerId = testUser1.Id,
                                           CurrencyIsoCode = 'USD',
                                           Contracting_Entity__c = 'a0M61000002lLZqEAM');
    insert testChildAccount;

    // Create the opportunity and link it to the testParentAccount and testChildAccount
    Opportunity testOpportunity = new Opportunity(Was_a_Partner_Involved__c='Yes',
                                                  Type='AWS',
                                                  Name='Test Opport',
                                                  AccountId=testParentAccount.Id,
                                                  Account__c=testChildAccount.id,
                                                  DDI__c='1937560',
                                                  StageName='Stage 1 - Planning & Identification',
                                                  QuotingSystem__c='Rackspace',
                                                  Expected_Revenue_Start_Date__c=System.today(),
                                                  CloseDate=System.today().addDays(15),
                                                  Cloud_Contract_Type__c='Regular',
                                                  Category__c='Downgrade',
                                                  OwnerId = testUser2.Id);
    insert testOpportunity;

    // Create a case so the updateCase() method passes when the following save() method is called
    RecordType recordType = [Select id from RecordType where sobjectType='Case' and Name='Partner Portal' limit 1]; 
    Case testCase = new Case(AccountId = testChildAccount.Id,
                             RecordTypeId=recordType.Id,
                             Origin = 'Email',
                             Status ='1-New',
                             Type='Problem',
                             Opportunity_Name__c = testOpportunity.Id);
    insert testCase;

    // Add the id of the opportunity to the apex pages
    ApexPages.currentPage().getParameters().put('id', testOpportunity.Id);

    // Create an opportunity closed won controller instance
    OpportunityCloseWonWizardController opportunityClosedWonController = new OpportunityCloseWonWizardController();
    opportunityClosedWonController.account = [SELECT Id, Name, Account_Number__c, Type, RecordTypeId, BillingCountry, ShippingCountry, BillingCountryCode, ShippingCountryCode, DDI__c, CurrencyIsoCode, Company_Name__r.CurrencyIsoCode, Contracting_Entity__c FROM Account WHERE Id = :testChildAccount.Id];    // Have to override account because when running this test the field Company_Name__r.CurrencyIsoCode is not known

    Test.startTest();
    // Save the opportunity
    opportunityClosedWonController.save();
    Test.stopTest();

    // Verify that the owners of the account records have not changed
    System.assertEquals(testUser1.Id, testChildAccount.OwnerId, 'The owner of the parent account of the opportunity is not equal to the account\'s original owner');
    System.assertEquals(testUser1.Id, testParentAccount.OwnerId, 'The owner of the parent account of the parent account of the opportunity is not equal to the parent account\'s original owner');
  }

  // Method:
  //  relatedAccountOwnersUpdated()
  // Description:
  //  It was determined that it is not correct for Accounts with the same DDI as the Opportunity being set to Closed/Won to have the owner overwritten to be equal to the owner of the Opportunity unless 
  //  the Account owners are Integration API users. This test demos a case where the Account related to the opportunity being set to ClosedWon does not have its owner set to be equal to the Opportunity 
  //  owner upon hitting the final save button in the Closed/Won Wizard class.
  // Expected output:
  //  The OwnerIds of the Account records are changed to be equal to the Opportunity OwnerIds
  @IsTest static void relatedAccountOwnersUpdated() {

    // Get the profile of the expected users
    List<Profile> soaProfileList = [SELECT Id, Name FROM Profile WHERE Id = :System.Label.Integration_API_Profile LIMIT 1];
    List<Profile> sellerProfileList = [SELECT Id, Name FROM Profile WHERE Name = 'Rackspace Seller-US' LIMIT 1];

    // Generate test users
    User testUser1 = new User(Alias = 'test1', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting1',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = soaProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting1@testorg.com');
    insert testUser1;

    User testUser2 = new User(Alias = 'test2', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting2',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = sellerProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting2@testorg.com');
    insert testUser2;

    // Create standard account which will be the parent account of the account related to the opportunity
    Account testParentAccount = new Account(Name='Test Parent Account',
                                            BillingCountry='India',
                                            ShippingCountry='India',
                                            RecordTypeId = Label.Standard_Company_RecordTypeId,
                                            OwnerId = testUser1.Id,
                                            CurrencyIsoCode = 'USD');
    insert testParentAccount;

    // Create customer account which will be the account related to the opportunity
    Account testChildAccount = new Account(Name='Test Child Account',
                                           BillingCountry='India',
                                           ShippingCountry='India',
                                           RecordTypeId = Label.AccountCustomerRecordTypeId, 
                                           Company_Name__c = testParentAccount.Id, 
                                           ParentId = testParentAccount.Id, 
                                           DDI__c = '1937560',
                                           OwnerId = testUser1.Id,
                                           CurrencyIsoCode = 'USD',
                                           Contracting_Entity__c = 'a0M61000002lLZqEAM');
    insert testChildAccount;

    // Create the opportunity and link it to the testParentAccount and testChildAccount
    Opportunity testOpportunity = new Opportunity(Was_a_Partner_Involved__c='Yes',
                                                  Type='AWS',
                                                  Name='Test Opport',
                                                  AccountId=testParentAccount.Id,
                                                  Account__c=testChildAccount.id,
                                                  DDI__c='1937560',
                                                  StageName='Stage 1 - Planning & Identification',
                                                  QuotingSystem__c='Rackspace',
                                                  Expected_Revenue_Start_Date__c=System.today(),
                                                  CloseDate=System.today().addDays(15),
                                                  Cloud_Contract_Type__c='Regular',
                                                  Category__c='Downgrade',
                                                  OwnerId = testUser2.Id);
    insert testOpportunity;

    // Create a case so the updateCase() method passes when the following save() method is called
    RecordType recordType = [Select id from RecordType where sobjectType='Case' and Name='Partner Portal' limit 1]; 
    Case testCase = new Case(AccountId = testChildAccount.Id,
                             RecordTypeId=recordType.Id,
                             Origin = 'Email',
                             Status ='1-New',
                             Type='Problem',
                             Opportunity_Name__c = testOpportunity.Id);
    insert testCase;

    // Add the id of the opportunity to the apex pages
    ApexPages.currentPage().getParameters().put('id', testOpportunity.Id);

    // Create an opportunity closed won controller instance
    OpportunityCloseWonWizardController opportunityClosedWonController = new OpportunityCloseWonWizardController();
    opportunityClosedWonController.account = [SELECT Id, Name, Account_Number__c, Type, RecordTypeId, BillingCountry, ShippingCountry, BillingCountryCode, ShippingCountryCode, DDI__c, CurrencyIsoCode, Company_Name__r.CurrencyIsoCode, Contracting_Entity__c FROM Account WHERE Id = :testChildAccount.Id];    // Have to override account because when running this test the field Company_Name__r.CurrencyIsoCode is not known

    Test.startTest();
    // Save the opportunity
    opportunityClosedWonController.save();
    Test.stopTest();

    // Verify that the owners of the account records have changed to be equal to the owner of the opportunity
    List<Account> accountList = [SELECT Id, Name, OwnerId FROM Account WHERE Id IN (:testParentAccount.Id, :testChildAccount.Id)];
    Map<String, Id> accountNameAccountIdMap = new Map<String, Id>();
    for(Account theAccount : accountList) {
      accountNameAccountIdMap.put(theAccount.Name, theAccount.OwnerId);
    }

    System.assertEquals(testUser2.Id, accountNameAccountIdMap.get('Test Child Account'), 'The owner of the parent account of the opportunity is not equal to the opportunity\'s owner');
    System.assertEquals(testUser2.Id, accountNameAccountIdMap.get('Test Parent Account'), 'The owner of the parent account of the parent account of the opportunity is not equal to the opportunity\'s owner');
  }

  // Method:
  //  relatedParentAccountOwnerUpdated()
  // Description:
  //  It was determined that it is not correct for Accounts with the same DDI as the Opportunity being set to Closed/Won to have the owner overwritten to be equal to the owner of the Opportunity unless 
  //  the Account owners are Integration API users. If the parent account's owner is equal to a user with the integration user profile and the account related to the opportunity does not then do not
  //  set the owner of the parent account equal to the owner of the opportunity.
  // Expected output:
  //  The OwnerId of the parent Account record related to the Account which is related to the Opportunity is equal to the Opportunity OwnerId
  @IsTest static void relatedParentAccountOwnerUpdated() {

    // Get the profile of the expected users
    List<Profile> soaProfileList = [SELECT Id, Name FROM Profile WHERE Id = :System.Label.Integration_API_Profile LIMIT 1];
    List<Profile> sellerProfileList = [SELECT Id, Name FROM Profile WHERE Name = 'Rackspace Seller-US' LIMIT 1];

    // Generate test users
    User testUser1 = new User(Alias = 'test1', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting1',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = soaProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting1@testorg.com');
    insert testUser1;

    User testUser2 = new User(Alias = 'test2', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting2',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = sellerProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting2@testorg.com');
    insert testUser2;

    User testUser3 = new User(Alias = 'test3', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting3',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = sellerProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting3@testorg.com');
    insert testUser3;

    // Create standard account which will be the parent account of the account related to the opportunity
    Account testParentAccount = new Account(Name='Test Parent Account',
                                            BillingCountry='India',
                                            ShippingCountry='India',
                                            RecordTypeId = Label.Standard_Company_RecordTypeId,
                                            OwnerId = testUser1.Id,
                                            CurrencyIsoCode = 'USD');
    insert testParentAccount;

    // Create customer account which will be the account related to the opportunity
    Account testChildAccount = new Account(Name='Test Child Account',
                                           BillingCountry='India',
                                           ShippingCountry='India',
                                           RecordTypeId = Label.AccountCustomerRecordTypeId, 
                                           Company_Name__c = testParentAccount.Id, 
                                           ParentId = testParentAccount.Id, 
                                           DDI__c = '1937560',
                                           OwnerId = testUser3.Id,
                                           CurrencyIsoCode = 'USD',
                                           Contracting_Entity__c = 'a0M61000002lLZqEAM');
    insert testChildAccount;

    // Create the opportunity and link it to the testParentAccount and testChildAccount
    Opportunity testOpportunity = new Opportunity(Was_a_Partner_Involved__c='Yes',
                                                  Type='AWS',
                                                  Name='Test Opport',
                                                  AccountId=testParentAccount.Id,
                                                  Account__c=testChildAccount.id,
                                                  DDI__c='1937560',
                                                  StageName='Stage 1 - Planning & Identification',
                                                  QuotingSystem__c='Rackspace',
                                                  Expected_Revenue_Start_Date__c=System.today(),
                                                  CloseDate=System.today().addDays(15),
                                                  Cloud_Contract_Type__c='Regular',
                                                  Category__c='Downgrade',
                                                  OwnerId = testUser2.Id);
    insert testOpportunity;

    // Create a case so the updateCase() method passes when the following save() method is called
    RecordType recordType = [Select id from RecordType where sobjectType='Case' and Name='Partner Portal' limit 1]; 
    Case testCase = new Case(AccountId = testChildAccount.Id,
                             RecordTypeId=recordType.Id,
                             Origin = 'Email',
                             Status ='1-New',
                             Type='Problem',
                             Opportunity_Name__c = testOpportunity.Id);
    insert testCase;

    // Add the id of the opportunity to the apex pages
    ApexPages.currentPage().getParameters().put('id', testOpportunity.Id);

    // Create an opportunity closed won controller instance
    OpportunityCloseWonWizardController opportunityClosedWonController = new OpportunityCloseWonWizardController();
    opportunityClosedWonController.account = [SELECT Id, Name, Account_Number__c, Type, RecordTypeId, BillingCountry, ShippingCountry, BillingCountryCode, ShippingCountryCode, DDI__c, CurrencyIsoCode, Company_Name__r.CurrencyIsoCode, Contracting_Entity__c FROM Account WHERE Id = :testChildAccount.Id];    // Have to override account because when running this test the field Company_Name__r.CurrencyIsoCode is not known

    Test.startTest();
    // Save the opportunity
    opportunityClosedWonController.save();
    Test.stopTest();

    // Verify that the owners of the account records have changed to be equal to the owner of the opportunity
    List<Account> accountList = [SELECT Id, Name, OwnerId FROM Account WHERE Id IN (:testParentAccount.Id, :testChildAccount.Id)];
    Map<String, Id> accountNameAccountIdMap = new Map<String, Id>();
    for(Account theAccount : accountList) {
      accountNameAccountIdMap.put(theAccount.Name, theAccount.OwnerId);
    }

    System.assertEquals(testUser3.Id, accountNameAccountIdMap.get('Test Child Account'), 'The owner of the parent account of the opportunity is not equal to the opportunity\'s owner');
    System.assertEquals(testUser1.Id, accountNameAccountIdMap.get('Test Parent Account'), 'The owner of the parent account of the parent account of the opportunity is not equal to the opportunity\'s owner');
  }

  // Method:
  //  relatedChildAccountOwnerUpdated()
  // Description:
  //  It was determined that it is not correct for Accounts with the same DDI as the Opportunity being set to Closed/Won to have the owner overwritten to be equal to the owner of the Opportunity unless 
  //  the Account owners are Integration API users. This test demos a case where only the child Account related to the opportunity being set to ClosedWon has its owner set to be equal to the Opportunity 
  //  owner upon hitting the final save button in the Closed/Won Wizard class.
  // Expected output:
  //  The OwnerId of the child Account record related to the Opportunity is equal to the Opportunity OwnerId
  @IsTest static void relatedChildAccountOwnerUpdated() {

    // Get the profile of the expected users
    List<Profile> soaProfileList = [SELECT Id, Name FROM Profile WHERE Id = :System.Label.Integration_API_Profile LIMIT 1];
    List<Profile> sellerProfileList = [SELECT Id, Name FROM Profile WHERE Name = 'Rackspace Seller-US' LIMIT 1];

    // Generate test users
    User testUser1 = new User(Alias = 'test1', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting1',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = soaProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting1@testorg.com');
    insert testUser1;

    User testUser2 = new User(Alias = 'test2', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting2',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = sellerProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting2@testorg.com');
    insert testUser2;

    User testUser3 = new User(Alias = 'test3', 
                       Email='standarduser@testorg.com', 
                       EmailEncodingKey='UTF-8',
                       LastName='Quetesting3',
                       LanguageLocaleKey='en_US', 
                       LocaleSidKey='en_US',
                       ProfileId = sellerProfileList[0].Id, 
                       TimeZoneSidKey='America/Los_Angeles',
                       UserName='Quetesting3@testorg.com');
    insert testUser3;

    // Create standard account which will be the parent account of the account related to the opportunity
    Account testParentAccount = new Account(Name='Test Parent Account',
                                            BillingCountry='India',
                                            ShippingCountry='India',
                                            RecordTypeId = Label.Standard_Company_RecordTypeId,
                                            OwnerId = testUser3.Id,
                                            CurrencyIsoCode = 'USD');
    insert testParentAccount;

    // Create customer account which will be the account related to the opportunity
    Account testChildAccount = new Account(Name='Test Child Account',
                                           BillingCountry='India',
                                           ShippingCountry='India',
                                           RecordTypeId = Label.AccountCustomerRecordTypeId, 
                                           Company_Name__c = testParentAccount.Id, 
                                           ParentId = testParentAccount.Id, 
                                           DDI__c = '1937560',
                                           OwnerId = testUser1.Id,
                                           CurrencyIsoCode = 'USD',
                                           Contracting_Entity__c = 'a0M61000002lLZqEAM');
    insert testChildAccount;

    // Create the opportunity and link it to the testParentAccount and testChildAccount
    Opportunity testOpportunity = new Opportunity(Was_a_Partner_Involved__c='Yes',
                                                  Type='AWS',
                                                  Name='Test Opport',
                                                  AccountId=testParentAccount.Id,
                                                  Account__c=testChildAccount.id,
                                                  DDI__c='1937560',
                                                  StageName='Stage 1 - Planning & Identification',
                                                  QuotingSystem__c='Rackspace',
                                                  Expected_Revenue_Start_Date__c=System.today(),
                                                  CloseDate=System.today().addDays(15),
                                                  Cloud_Contract_Type__c='Regular',
                                                  Category__c='Downgrade',
                                                  OwnerId = testUser2.Id);
    insert testOpportunity;

    // Create a case so the updateCase() method passes when the following save() method is called
    RecordType recordType = [Select id from RecordType where sobjectType='Case' and Name='Partner Portal' limit 1]; 
    Case testCase = new Case(AccountId = testChildAccount.Id,
                             RecordTypeId=recordType.Id,
                             Origin = 'Email',
                             Status ='1-New',
                             Type='Problem',
                             Opportunity_Name__c = testOpportunity.Id);
    insert testCase;

    // Add the id of the opportunity to the apex pages
    ApexPages.currentPage().getParameters().put('id', testOpportunity.Id);

    // Create an opportunity closed won controller instance
    OpportunityCloseWonWizardController opportunityClosedWonController = new OpportunityCloseWonWizardController();
    opportunityClosedWonController.account = [SELECT Id, Name, Account_Number__c, Type, RecordTypeId, BillingCountry, ShippingCountry, BillingCountryCode, ShippingCountryCode, DDI__c, CurrencyIsoCode, Company_Name__r.CurrencyIsoCode, Contracting_Entity__c FROM Account WHERE Id = :testChildAccount.Id];    // Have to override account because when running this test the field Company_Name__r.CurrencyIsoCode is not known

    Test.startTest();
    // Save the opportunity
    opportunityClosedWonController.save();
    Test.stopTest();

    // Verify that the owners of the account records have changed to be equal to the owner of the opportunity
    List<Account> accountList = [SELECT Id, Name, OwnerId FROM Account WHERE Id IN (:testParentAccount.Id, :testChildAccount.Id)];
    Map<String, Id> accountNameAccountIdMap = new Map<String, Id>();
    for(Account theAccount : accountList) {
      accountNameAccountIdMap.put(theAccount.Name, theAccount.OwnerId);
    }

    System.assertEquals(testUser2.Id, accountNameAccountIdMap.get('Test Child Account'), 'The owner of the parent account of the opportunity is not equal to the opportunity\'s owner');
    System.assertEquals(testUser3.Id, accountNameAccountIdMap.get('Test Parent Account'), 'The owner of the parent account of the parent account of the opportunity is not equal to the opportunity\'s owner');
  }

  // TODO: write tests for different opportunity types and when not hitting the logic at all
  

}