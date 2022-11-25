@isTest
public class TrackingExtensionController_Test {
    @isTest
    static void testTrack() {
        Account testAccount = new Account(
            Name = 'testCustomer',
            OwnerId = UserInfo.getUserId(),
            RecordTypeId = Schema.Sobjecttype.Account.getRecordTypeInfosByName().get('Customer Account').getRecordTypeId()
        );
        Insert testAccount;
        ApexPages.StandardController ctl = new ApexPages.StandardController(testAccount);
        TrackingExtensionController tc = new TrackingExtensionController(ctl);

        Test.startTest();
        tc.trackVisit();
        Test.stopTest();

        List<Program_Tracking__c> result = [SELECT ID from Program_Tracking__c WHERE Customer_Account__c =: testAccount.Id];
        System.assert(result.size()>0,true);
        

    }
}