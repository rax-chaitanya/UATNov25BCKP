@isTest(seeAllData = false)
class SandboxRefreshUtilTest {
    @testSetup static void setupTestData() {
        
        Id p = [select id from profile where name='System Administrator'].id;
        User testuser = new User(alias = 'testuser', email='testuser@rackspace.com.invalid',
                                 emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                                 localesidkey='en_US', profileid = p, timezonesidkey='America/Los_Angeles', username='testuseraaqq@noemail.com');
        insert testuser;

    }

    @isTest
    static void testMySandboxPrep() {
        String testdata = '{"testuser":{"DeveloperName": "testuser","Action_Type__c": "Email Update","Current_Value__c" : "testuser@rackspace.com.invalid","New_Value__c" : "testuser@rackspace.com","Active__c" : "true"}}';
        Map<String, Sandbox_Refresh__mdt>  testSandboxRefreshMappings = (Map<String, Sandbox_Refresh__mdt>)Json.deserialize(testdata,Map<String,Sandbox_Refresh__mdt>.class); 
        SandboxRefreshUtil.userEmailMdt = testSandboxRefreshMappings;
        Test.startTest();
        Test.testSandboxPostCopyScript(
            new SandboxRefreshUtil(), UserInfo.getOrganizationId(),
            UserInfo.getOrganizationId(), UserInfo.getOrganizationName());
        
        Test.stopTest();

    }
}