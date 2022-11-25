// Testing class for the PlatformEventTriggerHandler class

@isTest(seeAllData=false)
public with sharing class PlatformEventTriggerHandler_Test {
    // Get contact record type ids
    private static final Id STANDARD_CONTACT_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Standard').getRecordTypeId();
    private static final Id GOVERNMENT_CONTACT_RECORD_TYPE_ID = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Government').getRecordTypeId();

    // Get account record type ids
    private static final Id STANDARD_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Standard_Company').getRecordTypeId();
    private static final Id GOVERNMENT_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Government_Company').getRecordTypeId();

    // Get User profile ids
    private static final Id SYSTEM_ADMINISTRATOR_PROFILE_ID = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
    
    // Object name constants
    private static final String STANDARD_ACCOUNT_NAME = 'Nates Standard Account';
    private static final String GOVERNMENT_ACCOUNT_NAME = 'Nates Government Account';
    private static final String ADMIN_USER_FIRST_NAME = 'SystemAdmin';
    private static final String INVALID_ADMIN_USER_FIRST_NAME = 'InvalidSystemAdmin';

    // Create common testing data
    @testSetup static void setup() {
        // Insert default records
        TestDataFactory.getTriggerManagers();
        TestDataFactory.getOrgConstants();

        List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        //fieldMappings.add(new FieldMapping__c(Name = 'Territory-Lead', CompName__c = 'Lead', SourceField__c = 'Country', TargetField__c = 'Territory__c'));
        insert fieldMappings;
        
        // Create a Standard test account
        Account testStandardAccount = new Account(Name = STANDARD_ACCOUNT_NAME,
                                                  BillingCountry = 'United States',
                                                  ShippingCountry = 'United States',
                                                  RecordTypeId = STANDARD_ACCOUNT_RECORD_TYPE_ID);
        
        // Create a Government test account
        Account testGovernmentAccount = new Account(Name = GOVERNMENT_ACCOUNT_NAME,
                                                    BillingCountry = 'United States',
                                                    ShippingCountry = 'United States',
                                                    RecordTypeId = GOVERNMENT_ACCOUNT_RECORD_TYPE_ID);
        
        List<Account> testAccountList = new List<Account>{testStandardAccount,testGovernmentAccount};
        insert testAccountList;

        // Create a System Admin user
        User testSystemAdministratorUser = new User(Alias = 'alias',
                                                    CommunityNickname ='cname', 
                                                    Email= 'testemail@testingfakestuff.com', 
                                                    EmailEncodingKey='UTF-8',
                                                    FederationIdentifier = 'TestUser1337',
                                                    FirstName = ADMIN_USER_FIRST_NAME, 
                                                    LastName= 'TestUser', 
                                                    LanguageLocaleKey='en_US', 
                                                    LocaleSidKey='en_US', 
                                                    ProfileId = SYSTEM_ADMINISTRATOR_PROFILE_ID, 
                                                    TimeZoneSidKey='America/Los_Angeles', 
                                                    UserName = 'testuseradmin@testingfakestuff.com');   

        // Create the user for the invalid user checks in the PlatformEventHandlerHelper class
        User testInvalidSystemAdministratorUser = new User(Alias = 'alias2',
                                                           CommunityNickname ='cname2', 
                                                           Email= 'testemail2@testingfakestuff.com', 
                                                           EmailEncodingKey='UTF-8',
                                                           FederationIdentifier = 'TestUser1338',
                                                           FirstName = INVALID_ADMIN_USER_FIRST_NAME,
                                                           LastName= 'TestUser', 
                                                           LanguageLocaleKey='en_US', 
                                                           LocaleSidKey='en_US', 
                                                           ProfileId = SYSTEM_ADMINISTRATOR_PROFILE_ID, 
                                                           TimeZoneSidKey='America/Los_Angeles', 
                                                           UserName = 'testuserinvalidadmin@testingfakestuff.com');   

        List<User> testUserList = new List<User>{testSystemAdministratorUser,testInvalidSystemAdministratorUser};
        insert testUserList;
    }

    /**
     * Test Method:
     *     generateFeedItemsSuccessfully()
     * Test Description:
     *     Generates the a platform event triggering the outputFeedToUsers() method in the PlatformEventTriggerHandler class. Will generate feed items to selected users in this test class.
     * Test Expected Output:
     *     Feed item generated for testSystemAdminUser
     */
    @isTest static void generateFeedItemsSuccessfully() {
        // Get the invalid test user
        User testInvalidUser = [SELECT Id FROM User WHERE FirstName = :INVALID_ADMIN_USER_FIRST_NAME LIMIT 1];

        // Get the test user
        User testSystemAdminUser = [SELECT Id FROM User WHERE FirstName = :ADMIN_USER_FIRST_NAME LIMIT 1];
        
        // Set all of the testing data within the PlatformEventHandlerHelper class
        PlatformEventHandlerHelper.allEventsInstanceActive = true;
        PlatformEventHandlerHelper.objectEventsInstanceActive = true;
        PlatformEventHandlerHelper.invalidProfilesTestData = '';
        PlatformEventHandlerHelper.skipUserIdTestData = testInvalidUser.Id;
        PlatformEventHandlerHelper.fmwApiUserIdTestData = testInvalidUser.Id;

        // Set all of the testing data within the PlatformEventTriggerHandler class
        PlatformEventTriggerHandler.feedItemIdList = testSystemAdminUser.Id;
        PlatformEventTriggerHandler.allEventsFeedItemOutputEnabled = true;
        PlatformEventTriggerHandler.thisEventFeedItemOutputEnabled = true;

        // Get the test standard account
        Account testStandardAccount = [SELECT Id, Name FROM Account WHERE Name = :STANDARD_ACCOUNT_NAME LIMIT 1];

        // Create a contact record
        Contact testContact = new Contact(FirstName = 'Nathan',
                          			      LastName = 'TestContact',
                          			      RecordTypeId = STANDARD_CONTACT_RECORD_TYPE_ID,
                          			      AccountId = testStandardAccount.Id,
                          			      Email = 'testemail@fake.com',
                          			      Phone = '5555555555',
                                          Old_Record_Id__c = '123',
                                          DP_ContactId__c = 'DATAPIPE123',
                                          Status__c = null);

        Test.startTest();
        
        // Execute contact trigger logic
        System.runAs(testSystemAdminUser) {
            insert testContact;
        }

        Test.stopTest();

        // Get the feed items which were generated
        List<FeedItem> feedItemList = [SELECT Id, Body, ParentId FROM FeedItem WHERE ParentId = :testSystemAdminUser.Id];

        // Assert that the feed item was generated for the user
        System.assertNotEquals(0, feedItemList.size(), 'No feed item generated');
    }

    /**
     * Test Method:
     *     generateFeedItemsUnsuccessfullyUserShouldNotHaveFeedItemGeerated()
     * Test Description:
     *     Generates the a platform event triggering the outputFeedToUsers() method in the PlatformEventTriggerHandler class. Will not generate feed items because user is not included within the feedItemIdList
     * Test Expected Output:
     *     No feed item generated for testSystemAdminUser
     */
    @isTest static void generateFeedItemsUnsuccessfullyUserShouldNotHaveFeedItemGeerated() {
        // Get the invalid test user
        User testInvalidUser = [SELECT Id FROM User WHERE FirstName = :INVALID_ADMIN_USER_FIRST_NAME LIMIT 1];

        // Get the test user
        User testSystemAdminUser = [SELECT Id FROM User WHERE FirstName = :ADMIN_USER_FIRST_NAME LIMIT 1];
        
        // Set all of the testing data within the PlatformEventHandlerHelper class
        PlatformEventHandlerHelper.allEventsInstanceActive = true;
        PlatformEventHandlerHelper.objectEventsInstanceActive = true;
        PlatformEventHandlerHelper.invalidProfilesTestData = '';
        PlatformEventHandlerHelper.skipUserIdTestData = testInvalidUser.Id;
        PlatformEventHandlerHelper.fmwApiUserIdTestData = testInvalidUser.Id;

        // Set all of the testing data within the PlatformEventTriggerHandler class
        PlatformEventTriggerHandler.feedItemIdList = '';
        PlatformEventTriggerHandler.allEventsFeedItemOutputEnabled = true;
        PlatformEventTriggerHandler.thisEventFeedItemOutputEnabled = true;

        // Get the test standard account
        Account testStandardAccount = [SELECT Id, Name FROM Account WHERE Name = :STANDARD_ACCOUNT_NAME LIMIT 1];

        // Create a contact record
        Contact testContact = new Contact(FirstName = 'Nathan',
                          			      LastName = 'TestContact',
                          			      RecordTypeId = STANDARD_CONTACT_RECORD_TYPE_ID,
                          			      AccountId = testStandardAccount.Id,
                          			      Email = 'testemail@fake.com',
                          			      Phone = '5555555555',
                                          Old_Record_Id__c = '123',
                                          DP_ContactId__c = 'DATAPIPE123',
                                          Status__c = null);

        Test.startTest();
        
        // Execute contact trigger logic
        System.runAs(testSystemAdminUser) {
            insert testContact;
        }

        Test.stopTest();

        // Get the feed items which were generated
        List<FeedItem> feedItemList = [SELECT Id, Body, ParentId FROM FeedItem WHERE ParentId = :testSystemAdminUser.Id];

        // Assert that the feed item was generated for the user
        System.assertEquals(0, feedItemList.size(), 'A feed item has been generated');
    }

    /**
     * Test Method:
     *     generateFeedItemsUnsuccessfullyFeedItemDisabled()
     * Test Description:
     *     Generates the a platform event triggering the outputFeedToUsers() method in the PlatformEventTriggerHandler class. Will not generate feed items because feed item generation is disabled
     * Test Expected Output:
     *     No feed item generated for testSystemAdminUser
     */
    @isTest static void generateFeedItemsUnsuccessfullyFeedItemDisabled() {
        // Get the invalid test user
        User testInvalidUser = [SELECT Id FROM User WHERE FirstName = :INVALID_ADMIN_USER_FIRST_NAME LIMIT 1];

        // Get the test user
        User testSystemAdminUser = [SELECT Id FROM User WHERE FirstName = :ADMIN_USER_FIRST_NAME LIMIT 1];
        
        // Set all of the testing data within the PlatformEventHandlerHelper class
        PlatformEventHandlerHelper.allEventsInstanceActive = true;
        PlatformEventHandlerHelper.objectEventsInstanceActive = true;
        PlatformEventHandlerHelper.invalidProfilesTestData = '';
        PlatformEventHandlerHelper.skipUserIdTestData = testInvalidUser.Id;
        PlatformEventHandlerHelper.fmwApiUserIdTestData = testInvalidUser.Id;

        // Set all of the testing data within the PlatformEventTriggerHandler class
        PlatformEventTriggerHandler.feedItemIdList = '';
        PlatformEventTriggerHandler.allEventsFeedItemOutputEnabled = false;
        PlatformEventTriggerHandler.thisEventFeedItemOutputEnabled = true;

        // Get the test standard account
        Account testStandardAccount = [SELECT Id, Name FROM Account WHERE Name = :STANDARD_ACCOUNT_NAME LIMIT 1];

        // Create a contact record
        Contact testContact = new Contact(FirstName = 'Nathan',
                          			      LastName = 'TestContact',
                          			      RecordTypeId = STANDARD_CONTACT_RECORD_TYPE_ID,
                          			      AccountId = testStandardAccount.Id,
                          			      Email = 'testemail@fake.com',
                          			      Phone = '5555555555',
                                          Old_Record_Id__c = '123',
                                          DP_ContactId__c = 'DATAPIPE123',
                                          Status__c = null);

        Test.startTest();
        
        // Execute contact trigger logic
        System.runAs(testSystemAdminUser) {
            insert testContact;
        }

        Test.stopTest();

        // Get the feed items which were generated
        List<FeedItem> feedItemList = [SELECT Id, Body, ParentId FROM FeedItem WHERE ParentId = :testSystemAdminUser.Id];

        // Assert that the feed item was generated for the user
        System.assertEquals(0, feedItemList.size(), 'A feed item has been generated');
    }

    /**
     * Test Method:
     *     platformEventPublishersMarkedPublished()
     * Test Description:
     *     Generates the a platform event triggering the publishPlatformEventPublishers() method in the PlatformEventTriggerHandler class. Platform Event Publisher records are marked as published successfully.
     * Test Expected Output:
     *     Generated platform event is marked as published
     */
    @isTest static void platformEventPublishersMarkedPublished() {
        // Get the invalid test user
        User testInvalidUser = [SELECT Id FROM User WHERE FirstName = :INVALID_ADMIN_USER_FIRST_NAME LIMIT 1];

        // Get the test user
        User testSystemAdminUser = [SELECT Id FROM User WHERE FirstName = :ADMIN_USER_FIRST_NAME LIMIT 1];
        
        // Set all of the testing data within the PlatformEventHandlerHelper class
        PlatformEventHandlerHelper.allEventsInstanceActive = true;
        PlatformEventHandlerHelper.objectEventsInstanceActive = true;
        PlatformEventHandlerHelper.invalidProfilesTestData = '';
        PlatformEventHandlerHelper.skipUserIdTestData = testInvalidUser.Id;
        PlatformEventHandlerHelper.fmwApiUserIdTestData = testInvalidUser.Id;

        // Set all of the testing data within the PlatformEventTriggerHandler class
        PlatformEventTriggerHandler.feedItemIdList = '';
        PlatformEventTriggerHandler.allEventsFeedItemOutputEnabled = true;
        PlatformEventTriggerHandler.thisEventFeedItemOutputEnabled = true;

        // Get the test standard account
        Account testStandardAccount = [SELECT Id, Name FROM Account WHERE Name = :STANDARD_ACCOUNT_NAME LIMIT 1];

        // Create a contact record
        Contact testContact = new Contact(FirstName = 'Nathan',
                          			      LastName = 'TestContact',
                          			      RecordTypeId = STANDARD_CONTACT_RECORD_TYPE_ID,
                          			      AccountId = testStandardAccount.Id,
                          			      Email = 'testemail@fake.com',
                          			      Phone = '5555555555',
                                          Old_Record_Id__c = '123',
                                          DP_ContactId__c = 'DATAPIPE123',
                                          Status__c = null);

        Test.startTest();
        
        // Execute contact trigger logic
        System.runAs(testSystemAdminUser) {
            insert testContact;
        }

        Test.stopTest();

        // Get the platform event stage record which should have been created
        Platform_Event_Stage__c testPlatformEventStage = [SELECT Id, Destination_System__c, Platform_Event_Payload__c, Platform_Event_Publisher__c, Platform_Event_Source__c, Platform_Event_Stage_Status__c, Platform_Event_Type__c, Record_Id__c, sObject_Type__c 
                                                          FROM Platform_Event_Stage__c 
                                                          WHERE Record_Id__c = :testContact.Id];

        // Get the platform event publisher record which should have been created
        Platform_Event_Publisher__c testPlatformEventPublisher = [SELECT Id, Publisher_Status__c 
                                                                  FROM Platform_Event_Publisher__c 
                                                                  WHERE Id = :testPlatformEventStage.Platform_Event_Publisher__c];

        // Assert that the feed item was generated for the user
        System.assertEquals(PlatformEventHandlerHelper.PUBLISHED_PUBLISHER_STATUS_CODE, testPlatformEventPublisher.Publisher_Status__c, 'Expected publisher status equal to ' + PlatformEventHandlerHelper.PUBLISHED_PUBLISHER_STATUS_CODE);
    }

}