/**
*  
* @author chaitanya
* @since OCT 2022
* story - SFDC 8299
* Description - This schedule is used to schedule batch RaxTimeCardsLessThan40hrsBatch class
*Test Class - RaxTimeCardsLessThan40hrsBatchTest
*/

global class SchedRaxTimeCardsLessThan40hrsBatch    implements Schedulable {
    
    /*
String soql = 'select id,pse__Status__c,pse__Resource__r.name,pse__Total_Hours__c ,Submitted_Date__c,pse__Start_Date__c, pse__End_Date__c, pse__Project__r.name,pse__Resource__r.email,pse__Resource__r.pse__Group__r.name,pse__Resource__r.pse__Exclude_From_Time_Calculations__c,pse__Resource__r.pse__Is_Resource_Active__c from pse__Timecard_Header__c  where pse__Start_Date__c =:LastweekStartdate and pse__End_Date__c =:LastweekEnddate order by pse__Resource__r.email';
RaxTimeCardsLessThan40hrsBatch batch = new RaxTimeCardsLessThan40hrsBatch(soql);
Database.executebatch(batch, 200);
*/
    global void execute(SchedulableContext ctx){
        if(Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours')!=null && Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours').Active__c){
            
            String soql = 'select id,pse__Status__c,pse__Resource__r.name,pse__Total_Hours__c ,Submitted_Date__c,pse__Start_Date__c, pse__End_Date__c, pse__Project__r.name,pse__Resource__r.email,pse__Resource__r.pse__Group__r.name,pse__Resource__r.pse__Exclude_From_Time_Calculations__c,pse__Resource__r.pse__Is_Resource_Active__c	 from pse__Timecard_Header__c  where pse__Start_Date__c =:LastweekStartdate and pse__End_Date__c =:LastweekEnddate order by pse__Resource__r.email';
            RaxTimeCardsLessThan40hrsBatch batch = new RaxTimeCardsLessThan40hrsBatch(soql);
            // Database.executebatch(batch, Integer.ValueOf(System.Label.RaxTimeCardsLessThan40hrsBatchSize));
            Database.executebatch(batch,Integer.ValueOf(Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours').Size__c));
        }
    }
    
}