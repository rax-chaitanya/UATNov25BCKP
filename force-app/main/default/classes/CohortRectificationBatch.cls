/*
* Name: CohortRectificationBatch
* Created On: 1 Feb 2022
* Author: Mrinal Tripathi (mrinal.tripathi@rackspace.com)
* Description: Batch process to correctly update the cohort month on contacts
*/
global class CohortRectificationBatch implements Database.Batchable<sObject> {
    
    // Custom settting which drives the batch query and status of the logic
    Cohort_Calculation_Settings__c CS = Cohort_Calculation_Settings__c.getInstance(UserInfo.getOrganizationId());
    
    // Map to maintain email Id with min created date of contacts to be updated
    Datetime dt = System.now().addDays( Integer.valueOf(cs.Number_of_days__c) );
    //Set<Id> failedRecordIds = new Set<Id>();
    //Boolean retrial = false;
    String queryString = '';
    List<String> emailIds = new List<String>();
    List<Contact> contactList = new List<Contact>();
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        
        queryString = CS.Batch_query__c  + ' ';
        queryString += !String.isBlank(CS.Query_sort_order__c) ? CS.query_sort_order__c : '' ;
        System.debug('query String:::'+ queryString);
        //System.debug('updatedContacts::'+updatedContacts);
        return Database.getqueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<AccountContactRelation> scope){
        
        for(AccountContactRelation acr: scope){
            if(!emailIds.contains(acr.contact.email)){
                emailIds.add(acr.contact.email);
            }
        }
        for(contact con: [Select id, email, CM_Existing_Data__c, skip_obms__c, cohort_month__c,last_date_of_survey__c,createddate from contact where email IN: emailIds]){
            if(!contactList.contains(con)){
                contactList.add(con);
            }
            
        }
        CohortCalculationHelper.handleDuplicateConactCohort(contactList);        
    }
    
    global void finish(Database.BatchableContext BC){
        System.debug('Finish!!');
        cs.last_run_time__c = System.now();
        update cs;
    }
}