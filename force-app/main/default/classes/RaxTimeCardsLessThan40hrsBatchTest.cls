/**
*  
* @author chaitanya
* @since OCT 2022
* story - SFDC 8299
* Description - Test Class for RaxTimeCardsLessThan40hrsBatch and SchedRaxTimeCardsLessThan40hrsBatch
*
*/

//@IsTest(SeeAllData=true)
@IsTest
public class RaxTimeCardsLessThan40hrsBatchTest {
    
    
    @testSetup static void setup() {
        
        List<Trigger_Manager__c> tms = new List<Trigger_Manager__c>();
        tms.add( new Trigger_Manager__c (Name ='AccountContactRelation',Is_Active__c = true));
        insert tms;
        List<FieldMapping__c> fieldMappings = new List<FieldMapping__c>();
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Company', CompName__c = 'Account', SourceField__c = 'BillingCountry', TargetField__c = 'Territory__c'));
        fieldMappings.add(new FieldMapping__c(Name = 'Territory-Contact', CompName__c = 'Contact', SourceField__c = 'MailingCountry', TargetField__c = 'Territory__c'));
        insert fieldMappings;
        TestClassUtility.setTestSetupData();
        Rax_Batch_Run_Setting__mdt insertmdt= new Rax_Batch_Run_Setting__mdt(Active__c=true,Class_Name__c='RaxTimeCardsLessThan40hrsBatch',
                                                                             Size__c=200,label='RaxTimeCardsLessThan40hours'); 
        Account pseacc=new Account(name='test pse req',recordtypeid='01261000000X4t2AAC',phone='2222222',CurrencyIsoCode='USD');
        insert pseacc;
        
        pse__Grp__c psegrp=new pse__Grp__c();
        psegrp.name='Americas ';
        insert psegrp;
        contact pserescon=new contact(pse__Group__c=psegrp.id,pse__Salesforce_User__c=UserInfo.getUserId(),pse__Is_Resource__c=true,Accountid=pseacc.id,email='testincalidemai@i.com',FirstName='test pse',LastName='con',pse__Is_Resource_Active__c=true,recordtypeid='01261000000j2upAAA',pse__Exclude_From_Time_Calculations__c=false);
        insert pserescon;
        
        
    }
    
    
    @isTest
    private static void testExecute(){
        date myDate = date.today();
        date weekStart = myDate.toStartofWeek();
        date LastweekStartdate = weekStart.addDays(-7);
        date LastweekEnddate = weekStart.addDays(-1);
        Test.StartTest();
      /*  String testdata = '{"RaxTimeCardsLessThan40hours":{"DeveloperName": "RaxTimeCardsLessThan40hours","Active__c": "true","Class_Name__c" : "RaxTimeCardsLessThan40hrsBatch","Size__c" : "200"}}';
        Map<String, Rax_Batch_Run_Setting__mdt>  testSandboxRefreshMappings = (Map<String, Rax_Batch_Run_Setting__mdt>)Json.deserialize(testdata,Map<String,Rax_Batch_Run_Setting__mdt>.class); 
        RaxTimeCardsLessThan40hrsBatch.batchRunMdt = testSandboxRefreshMappings;*/
        String soql ='select id,pse__Status__c,pse__Resource__r.name,pse__Total_Hours__c ,Submitted_Date__c,pse__Start_Date__c, pse__End_Date__c, pse__Project__r.name,pse__Resource__r.email,pse__Resource__r.pse__Group__r.name,pse__Resource__r.pse__Exclude_From_Time_Calculations__c,pse__Resource__r.pse__Is_Resource_Active__c from pse__Timecard_Header__c  where pse__Start_Date__c =:LastweekStartdate and pse__End_Date__c =:LastweekEnddate order by pse__Resource__r.email';
        SchedRaxTimeCardsLessThan40hrsBatch testsche = new SchedRaxTimeCardsLessThan40hrsBatch();
        String sch = '0 0 23 * * ?';
        system.schedule('Test schedule', sch, testsche );
        
        contact resource=[select id from contact where email='testincalidemai@i.com' limit 1];
        
        
        pse__Region__c reg = new pse__Region__c();
        reg.Name = 'Americas';
        insert reg;
        pse__Permission_Control__c pc=new pse__Permission_Control__c ();
        pc.pse__Staffing__c =true;
        pc.pse__Region__c=reg.id;
        pc.pse__User__c=UserInfo.getUserId();
        insert pc;
        
        pse__Proj__c project = new pse__Proj__c();
        project.name = 'Test';
        project.pse__Allow_Self_Staffing__c=true;
        project.pse__Region__c = reg.id;
        project.pse__Start_Date__c = Date.today().addDays(-30);
        project.pse__End_Date__c = Date.today().addDays(30);
        project.pse__Is_Active__c = TRUE ;
        insert project;  
        pse__Milestone__c milestone = new pse__Milestone__c();
        milestone.name='project hours';
        milestone.pse__Project__c = project.id;
        milestone.pse__Target_Date__c = Date.today().addDays(30);
        milestone.pse__Milestone_Amount__c = 0;
        milestone.pse__Closed_for_Time_Entry__c=false;
        milestone.CurrencyIsoCode='USD';
        milestone.pse__Status__c='In Progress';
        milestone.recordtypeid='0123f000000XdTmAAK';
        
        insert milestone;
        
        pse__Schedule__c s = new pse__Schedule__c();
        s.pse__Start_Date__c = Date.today().addDays(-30);
        s.pse__End_Date__c = Date.today().addDays(30);
        insert s;
        
        
        
        pse__Assignment__c assign = new pse__Assignment__c();
        assign.pse__Bill_Rate__c = 0;
        assign.pse__Schedule__c= s.id;
        assign.pse__Project__c= project.id;   
        assign.pse__Resource__c= resource.id;
        insert assign;
        
        pse__Timecard_Header__c timecard = new pse__Timecard_Header__c();
        timecard.pse__Resource__c = resource.id;
        timecard.pse__Project__c = project.id;
        timecard.pse__Assignment__c = assign.id;
        timecard.pse__Start_Date__c = LastweekStartdate;
        timecard.pse__End_Date__c = LastweekEnddate;
        timecard.pse__Monday_Hours__c = 2;
        timecard.pse__Monday_Notes__c = 'mon notes';
        timecard.pse__Tuesday_Hours__c = 2;
        timecard.pse__Tuesday_Notes__c = 'tues notes';
        timecard.pse__Wednesday_Hours__c = 2;
        timecard.pse__Wednesday_Notes__c = 'wed notes';
        timecard.pse__Thursday_Hours__c = 2;
        timecard.pse__Thursday_Notes__c = 'thurs notes';
        timecard.pse__Friday_Hours__c = 8;
        timecard.pse__Friday_Notes__c = 'fri notes';
        timecard.pse__Status__c= 'Submitted';
        timecard.pse__Milestone__c=milestone.id;
        timecard.pse__Approver__c=UserInfo.getUserId();
        insert timecard;
        
        RaxTimeCardsLessThan40hrsBatch batch = new RaxTimeCardsLessThan40hrsBatch(soql);
        Database.executebatch(batch, 200); 
        Test.stopTest();    
        
    }
    
}