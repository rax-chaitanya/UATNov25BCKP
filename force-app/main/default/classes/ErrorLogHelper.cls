/* Last modified      : by chaitnaya on Aug 2022
 * changes 			  : SFDC- 8055 ,updated ClogErrorRecord method to use insert dml instead of
 * 						database.insert which is ignoring dml failure.and posting exceptions for Clog errors
 * 						into SF errors group with excptionhandler class
 * 
 * Test Class         : ErrorLogHelper_Test
 * 
 */
public class ErrorLogHelper {

    public static void logErrorRecord(String errorMessage,string actionType){
        try{
            ErrorLog__c errordetails=new Errorlog__c();
            errordetails.Message__c = errorMessage;
            errordetails.Action_Type__c = actionType;
            Database.insert(errordetails,false);
        } catch(Exception e){
             System.debug('Error :'+e.getMessage());
        }
    }
    
    public static void logErrorRecords(List<Database.Saveresult> updateResult,List<SObject> listToUpdate,string actionType){
        try{
            List<ErrorLog__c> errorslist=new  List<ErrorLog__c>();
            
            for(Integer i=0;i<updateResult.size();i++){
                if (!updateResult.get(i).isSuccess()){            
                    Database.Error error = updateResult.get(i).getErrors().get(0);
                    system.debug('Failed ID: '+listToUpdate.get(i).Id + 'Error msg: '+ error.getMessage());
                    ErrorLog__c errordetails = new Errorlog__c();
                    errordetails.RecordID__c = (String)listToUpdate.get(i).Id;
                    errordetails.Message__c = error.getMessage();
                    errordetails.Action_Type__c = actionType;
                    errorslist.add(errordetails);
                }                
            }
            
            if(errorslist.size()> 0){
                Database.insert(errorslist,false);
            }            
        } catch(Exception e){
            System.debug('Error :'+e.getMessage());
        }
        
    }
    public static void ClogErrorRecord(String errorMessage,string actionType){
        try{
            CLog__c errordetails=new Clog__c();
            errordetails.Error_Description__c = errorMessage;
            errordetails.Action_Name__c = actionType;
            insert errordetails;//SFDC- 8005 added this line to see exceptions in DML instead of database insert method
            //Database.insert(errordetails,false); //SFDC-8005 commented this line for catching the exception 
        } catch(Exception e){
             System.debug('Error :'+e.getMessage());
             ExceptionHandler.postToChatter(e);// SFDC-8005 added this line to post exception in chatter 
        }
    }
}