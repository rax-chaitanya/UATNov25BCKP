/**
******************************************************************************************************************  
* @author chaitanya
* @since OCT 2022
* story - SFDC 8299
* Description - This batch will run weekly and fetch submitted time cards for the last week
*                  and if resource filled less than 40 hours for all the entered time in different cards
*                  then we will send an email alert
*Test Class - RaxTimeCardsLessThan40hrsBatchTest
******************************************************************************************************************
*/

global class RaxTimeCardsLessThan40hrsBatch implements Database.Batchable<sObject>, Database.Stateful {
    //date testmyDate = date.newInstance(2022, 8, 15);
    // global date Lastweekstartdate = date.today().addDays(-8);
    // global date Lastweekstartdate = date.today().addDays(-8);
    // global date LastweekEnddate = date.today().addDays(-2);  
    
    date currentDate = date.today();
    date weekStart = currentDate.toStartofWeek();
    global date LastweekStartdate = weekStart.addDays(-7);
    global date LastweekEnddate = weekStart.addDays(-1);
    private String query;
    public static final List<String> reqRegions = System.Label.RaxTimeCardsLessThan40hrsGroups.split(',');
    public static final List<String> reqtimeCardStatus = System.Label.RaxTimeCardsLessThan40hrsStatus.split(',');
   	//SFDC-8512 Moved below variables here to hold values through execution for stateful data.
    Map<id,decimal> resToTotalHrs = new map<id,decimal>();
    Map<id,string> resToEmail = new map<id,string>();
    Map<id,List<pse__Timecard_Header__c>> resToTimecardList = new map<id,List<pse__Timecard_Header__c>>();
    
    
/* @TestVisible
public static Map<String, Rax_Batch_Run_Setting__mdt>  batchRunMdt {
get {
if (batchRunMdt == null) {
batchRunMdt = Rax_Batch_Run_Setting__mdt.getAll();
}

return batchRunMdt;
}
private set;
}*/
    global RaxTimeCardsLessThan40hrsBatch (String soql){
        query = soql;
    }
    
    
    // The batch job starts
    global Database.Querylocator start(Database.BatchableContext bc){
        System.debug('>>>> start ' + query);
        system.debug('chap start---'+LastweekStartdate);
        system.debug('chap end---'+LastweekEnddate);
        return Database.getQuerylocator(query);
    } 
    
    
    
    
    
    global void execute(Database.BatchableContext bc, List<pse__Timecard_Header__c> scope){
        
        if(Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours')!=null && Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours').Active__c){
            
            //if(batchRunMdt.get('RaxTimeCardsLessThan40hours')!=null && batchRunMdt.get('RaxTimeCardsLessThan40hours').Active__c){
            
            System.debug('>>>> execute ' + scope.size());
            
            Map<Id, pse__Timecard_Header__c> timeCardMap = new Map<Id, pse__Timecard_Header__c>(scope);
            
            for(pse__Timecard_Header__c timecardrec:timeCardMap.values()){
                //System.debug('>>>> execute ' +timecardrec.pse__Resource__r.email );
                //System.debug('resource grop frpm teste ' +timecardrec.pse__Resource__r.pse__Group__r.name );
                
                if(timecardrec.pse__Total_Hours__c >0 && timecardrec.pse__Total_Hours__c <40 && !string.isblank(timecardrec.pse__Resource__r.email)
                   && reqRegions.contains(timecardrec.pse__Resource__r.pse__Group__r.name)
                   && reqtimeCardStatus.contains(timecardrec.pse__Status__c)
                   && timecardrec.pse__Resource__r.pse__Is_Resource_Active__c
                   && !timecardrec.pse__Resource__r.pse__Exclude_From_Time_Calculations__c){
                       System.debug('>>>> execute with filter--- ' +timecardrec.pse__Resource__r.email );
                       if(resToTimecardList.containskey(timecardrec.pse__Resource__c))
                       {
                           resToTimecardList.get(timecardrec.pse__Resource__c).add(timecardrec);
                       }else{
                           List<pse__Timecard_Header__c> newtolistTC=new List<pse__Timecard_Header__c>();
                           newtolistTC.add(timecardrec);
                           resToTimecardList.put(timecardrec.pse__Resource__c,newtolistTC);
                       }
                       if(!resToEmail.containskey(timecardrec.pse__Resource__c)){
                           resToEmail.put(timecardrec.pse__Resource__c, timecardrec.pse__Resource__r.email);
                       }
                       
                       if(resToTotalHrs.containskey(timecardrec.pse__Resource__c))
                       {
                           
                           resToTotalHrs.put(timecardrec.pse__Resource__c,
                                             resToTotalHrs.get(timecardrec.pse__Resource__c)+timecardrec.pse__Total_Hours__c);
                       }
                       else{
                           resToTotalHrs.put(timecardrec.pse__Resource__c,timecardrec.pse__Total_Hours__c);
                       }
                   }
            }
            system.debug('chap recs---'+resToTotalHrs);
            
            
        }    
        
    }
    
    global void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
        System.debug('>>>> finish ' + job.Status);
        
        
        //SFDC- 8512 Moved the below email logic to finish method to send emails only after all the execution is completed 
        try{
            String owEmailAddressId = PartnerRolesEmailController.generateOWEmailId();
            List<Messaging.SingleEmailMessage> emailSendList = new List<Messaging.SingleEmailMessage>();
            EmailTemplate  template = [Select Id,Name from EmailTemplate where Name = 'RaxTimeCardsLessThan40hrs']; 
            
            If(!resToTotalHrs.isEmpty()){ 
                
                for(Id resid:resToTotalHrs.keyset()){
                    if(resToTotalHrs.containskey(resid) && resToTotalHrs.get(resid) < 40 
                       && resToTimecardList.containskey(resid) &&resToTimecardList.get(resid).size()>0 
                      ){
                          // && resToEmail.get(resid)=='bhimisetty.venkatachaitanya@rackspace.com'
                          //if(resToTotalHrs.get(resid) < 40 ){
                          
                          system.debug('chap+'+resToEmail.get(resid)+'--hours--'+resToTotalHrs.get(resid));
                          Messaging.SingleEmailMessage singlemsg = new Messaging.SingleEmailMessage();
                          String mailbody = '';
                          
                          //                            !String.isblank(Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours').Test_User_or_Data__c) ?
                          //Rax_Batch_Run_Setting__mdt.getInstance('RaxTimeCardsLessThan40hours').Test_User_or_Data__c
                          // :
                          String[] toAddress = new String[] { resToEmail.get(resid)        };
                              system.debug('----checking user emails if test user available--'+toAddress);
                          //String[] toAddress = new String[] {timecard.pse__Resource__r.email};
                          singlemsg= Messaging.renderStoredEmailTemplate(template.id,resToTimecardList.get(resid)[0].pse__Resource__c , resToTimecardList.get(resid)[0].id);
                          mailbody = string.valueof(singlemsg.getHtmlBody()) + mailbody; 
                          singlemsg.setHtmlBody(mailbody); 
                          singlemsg.setToAddresses(toAddress);
                          singlemsg.setOrgWideEmailAddressId(owEmailAddressId);  
                          singlemsg.setSaveAsActivity(false);           
                          if(!toAddress.isempty()) { emailSendList.add(singlemsg);}
                          //system.debug('less than for user--'+timecard.pse__Resource__r.name);
                      }
                }
            }
            if(!emailSendList.isEmpty()) {
                Messaging.sendEmail(emailSendList);
                system.debug('less than for user emails--'+emailSendList);
                
            }
        }
        catch (Exception ex)
        {
            
            ErrorLogHelper.ClogErrorRecord(ExceptionHandler.getBody(ex),'Timecardlesstha40batchError');
            
        }        
        
        
        
    }
    
    
    
/*
String soql = 'select id,pse__Status__c,pse__Resource__r.name,pse__Total_Hours__c ,Submitted_Date__c,pse__Start_Date__c, pse__End_Date__c, pse__Project__r.name,pse__Resource__r.email,pse__Resource__r.pse__Group__r.name,pse__Resource__r.pse__Exclude_From_Time_Calculations__c,pse__Resource__r.pse__Is_Resource_Active__c from pse__Timecard_Header__c  where pse__Start_Date__c =:LastweekStartdate and pse__End_Date__c =:LastweekEnddate order by pse__Resource__r.email';
RaxTimeCardsLessThan40hrsBatch batch = new RaxTimeCardsLessThan40hrsBatch(soql);
Database.executebatch(batch, 200);
*/
    
    
    
}