@isTest
public class updateEmailOptOutTest {
    @TestSetUp
    static void setDataUp(){
        TestClassUtility.setTestSetupData();
        
        insertOrgConstants();
    }
    
    
    public static void insertOrgConstants() {
        List<OrgConstants__c> constants = new List<OrgConstants__c>();
        constants.add(new OrgConstants__c(Name = '#salesforce-errors', Non_Prod_Value__c = 'https://www.google.com', Prod_Value__c = 'https://www.google.com'));
        constants.add(new OrgConstants__c(Name = 'Salesforce Errors Group', Non_Prod_Value__c = '0F961000000JJa2', Prod_Value__c = '0F961000000JJa2'));
        insert constants;
        Trigger_Manager__c Tm = new Trigger_Manager__c (Name ='AccountContactRelation',Is_Active__c = true);
        insert Tm;
            List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Lead', CompName__c = 'Lead', SourceField__c = 'Country', TargetField__c = 'Territory__c'));
        insert fieldMappings;
    }
    
    @isTest
    static void updateEmailOptOutMethod(){
        
        Set<String>setEmailString = new Set<String>();
        Lead l = new Lead(firstname='asdasd',lastname='fssdfgsfd',company='Test compansdfdsfy',Isconverted = false,
                          email='test.test@test.com.asda',LeadSource='Chat',Lead_Type__c='AWS',
                          Focus_Area__c='Amazon',street='Marathalli',city='Bangalore',State='Karnataka',HasOptedOutOfEmail=false,
                          country='India',postalcode='560037',Campaign_Interest__c='E&A Cart');
        insert l;
        Account a = new Account(Name='Test Account1234',BillingCountry='India',ShippingCountry='India' );
        insert a;
        Contact c = new Contact(firstname='Test Contact',LastName='Test Last',AccountId=a.id,email='test.test@test.com.asda',HasOptedOutOfEmail=false);
        insert c;
        c.HasOptedOutOfEmail = true;
        update c;
        setEmailString.add(l.Email);
        Test.startTest();
        UpdateEmailOptOut.updateEmailOptOutField(setEmailString,'Lead');
        
        Test.stopTest();
        
    }
    
}