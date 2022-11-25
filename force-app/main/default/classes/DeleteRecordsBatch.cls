global class DeleteRecordsBatch implements Database.Batchable<sObject>, Database.Stateful{
public String query = 'Select ID,Action_Record_ID__c from cLog__c where CreatedDate <=2019-12-31T00:00:00.001Z';
    global Database.QueryLocator start(Database.BatchableContext context)
    {
        
         return Database.getQueryLocator(query);
    }
       
    global void execute(Database.BatchableContext context, List<SObject> records)
    {
       
        if(records != null){
        System.debug('we have got:'+records.size()+' records to Delete');
        
        delete records;
        }else{
            System.debug('No Records to Delete !');
        }
    }
    global void finish(Database.BatchableContext context)
    {
        
    }
}