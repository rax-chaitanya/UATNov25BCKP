/*
* Name: CohortCalculationHelper
* Created On: 19 Apr 2022
* Author: Mrinal Tripathi (mrinal.tripathi@rackspace.com)
* Description: Helper class to update duplicate contacts
*/
public class CohortCalculationHelper{
    
    static Map<String, datetime> emailWithLastSurveyDate = new Map<String, datetime>();
    static String eligibleDays  = System.Label.NPS_Eligible_Days;
    static String eligibleMonths = System.Label.NPS_Cohort_Initial_Month;
    static List<String> emailWithLastSurveyFound = new List<String>();
    
    public static void handleDuplicateConactCohort(List<contact> conList){
        
        if(!CheckRecursive.firstcall){
            System.debug('Con list size::' +conList.size());
            //System.debug('failed records::' +failedRecordIds);
            
            List<contact> contactsToUpdate = new List<Contact>();
            datetime surveyDate;
            
            /*
* 
*/
            for(contact con: conList){
                
                if(emailWithLastSurveyDate.containsKey(con.email)){
                    
                    surveyDate = emailWithLastSurveyDate.get(con.email);
                    
                    if(con.last_date_of_survey__c != null && con.last_date_of_survey__c > surveyDate){
                        surveyDate = con.last_date_of_survey__c;
                        emailWithLastSurveyFound.add(con.email);
                    }
                    else if(con.last_date_of_survey__c == null && !emailWithLastSurveyFound.contains(con.email) 
                            && surveyDate > con.createddate ){
                                surveyDate = con.createdDate;
                            }
                }
                else{
                    
                    if(con.last_date_of_survey__c != null){
                        surveyDate = con.last_date_of_survey__c;
                        emailWithLastSurveyFound.add(con.email);
                    }
                    else{
                        surveyDate = con.createdDate;
                    }
                    
                }  
                emailWithLastSurveyDate.put(con.email, surveyDate);                                        
                
            }
            
            
            updateContactRecords(conList);
        }
    }
    private static void updateContactRecords(List<contact> contactsToUpdate){
        
        
        String cohertFinal;
        
        // Initialize the custom label outside the loop to improve time       
        
        
        System.debug('email with last survey found map before update::::' + emailWithLastSurveyDate);
        for(contact con : contactsToUpdate){
            
            if(emailWithLastSurveyDate.containsKey(con.email)){
                
                cohertFinal = !emailWithLastSurveyFound.contains(con.email) ? String.valueOf(emailWithLastSurveyDate.get(con.email).addDays(Integer.valueOf(eligibleDays)).addMonths(Integer.valueOf(eligibleMonths)).month()) : String.valueOf(emailWithLastSurveyDate.get(con.email).month());
                //System.debug('con::' +con);
                //System.debug('cohertFinal::::'+cohertFinal);
                //System.debug('Cohert period:::' +Cohort_Period__mdt.getInstance('Month_' +cohertFinal));
                //System.debug('Cohort final month number:::'+cohertFinal);
                //System.Debug('Calculated date::'+emailWithMinCreatedDate.get(con.email).addDays(Integer.valueOf(eligibleDays)));
                
                cohertFinal = Cohort_Period__mdt.getInstance('Month_' +cohertFinal).Cohort_months__c;
                //System.debug('Cohort final value in metadata:::'+cohertFinal);
                con.CM_Existing_Data__c = cohertFinal;
                con.skip_obms__c = true;
                //System.debug('con.CM_Existing_Data__c:::' +con.CM_Existing_Data__c + ' ' +con.id);
            }

            
        }
        
        
        if(contactsToUpdate.size() > 0){
            
            try{
                Database.update(contactsToUpdate, false);
            }
            catch(Exception e){
                System.debug('Exception while running the batch::' +e);
            }
            preventOBMTrigger(contactsToUpdate);
            
        }
    }
    
    /* Function to update skip OBM flag on contact so that no OBM is fired when the batch is invoked
-> The function updates the OBM flag to true and then to false
*/
    private static void preventOBMTrigger(List<contact> contactsToUpdate){
        
        for(Contact con: contactsToUpdate){
            con.skip_obms__c = false;
            //con.cohort_calculation_failed__c = failedRecordIds.contains(con.Id) ? true : false;
        }
        try{
            CheckRecursive.firstCall = true;
            Database.update(contactsToUpdate, false);
        }
        catch(Exception e){
            System.debug('Exception in OBM flag update:::' +e);
        }
    }
    @future
    public static void calculateCohortByEmails(List<String> emailIds){
        List<contact> contactList = new List<contact>();
        //Customize the query
        for(contact con: [Select id, email, CM_Existing_Data__c, skip_obms__c, cohort_month__c, Last_date_of_survey__c,createddate  from contact where email IN :emailIds Limit 50000]){
            contactList.add(con);
        }
        if(contactList.size() > 0){
            handleDuplicateConactCohort(contactList);
        }
    }
}