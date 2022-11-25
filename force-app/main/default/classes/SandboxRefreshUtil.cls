/* Author - Chaitanya
* Test Class - SandboxRefreshUtilTest
* Created Date - July 2022
* Description - This is class is used to change system admin emails from custom metadata when sandbox is refreshed
* Create the mdt records for required admins with .invalid email and the new email with type email update
* And while refreshing the sandbox, mention this apex class to run and it will pull all those mdt records and updates the user email

* Use the below anonymous code block to run the logic

public class sbxContextanonymous implements SandboxContext
{
public ID organizationID(){return UserInfo.getOrganizationId();}
public ID sandboxID(){return UserInfo.getOrganizationId();}
public String sandboxName(){return 'sandbox';}
}

//**Declare the instance**
sbxContextanonymous context = new sbxContextanonymous();
SandboxRefreshUtil sbxRefresh = new SandboxRefreshUtil();
sbxRefresh.runApexClass(context);

*/

global class SandboxRefreshUtil implements SandboxPostCopy { 
    
    @TestVisible
    public static Map<String, Sandbox_Refresh__mdt>  userEmailMdt {
        get {
            if (userEmailMdt == null) {
                userEmailMdt = Sandbox_Refresh__mdt.getAll();
            }
            
            return userEmailMdt;
        }
        private set;
    }
    global Organization org = [SELECT Id, isSandbox FROM Organization];
    
    global void runApexClass(SandboxContext context) { 
        
        if (org.IsSandbox == true || Test.isRunningTest()) {
            //System.debug(context.organizationId());         
            //System.debug(context.sandboxId()); 
            //System.debug(context.sandboxName()); 
            //System.Debug('Sandbox detected: Begin Refresh');
            runLogic(); 
        }
        else {
            //System.debug('You are not running this in a sandbox');
        }
        
    } 
    
    global static void runLogic() { 
        Map<string,Sandbox_Refresh__mdt> userMap=new Map<string,Sandbox_Refresh__mdt>();
        List<user> toUpdateUser=new    List<user>();
        List<user> existingUser=new    List<user>();
        if(userEmailMdt!=Null){
        for(String nameusermdt : userEmailMdt.keySet()){
            
            //System.debug('----->'+userEmailMdt.get(nameusermdt).Current_Value__c);
            
            if(userEmailMdt.get(nameusermdt).Action_Type__c=='Email Update' && userEmailMdt.get(nameusermdt).Active__c){
                userMap.put(userEmailMdt.get(nameusermdt).Current_Value__c,userEmailMdt.get(nameusermdt));
            }
            
        }
        
        if(userMap.size() > 0)    
        { 
            existingUser=[select id,name,email,profileid,profile.name,username from user where email=:userMap.keyset()];
            //system.debug('chap'+userMap);
            //system.debug('toUpdateUser'+toUpdateUser);            
        }
        
        if(existingUser.size() > 0)       
        { 
            for(user eachuser : existingUser){
                if(eachuser.email==userMap.get(eachuser.email).Current_Value__c
                   && eachuser.email!=userMap.get(eachuser.email).New_Value__c)
                {
                    eachuser.email=userMap.get(eachuser.email).New_Value__c;
                    toUpdateUser.add(eachuser);
                    //system.debug('success '+eachuser.username+'user id--'+eachuser.id+'user need password--' );
                    
                }
            }
        }
        
        if(toUpdateUser.size()>0)
        {
            List<Database.SaveResult> updateResults = Database.update(toUpdateUser, false);
            
            
/* 
 * 
 * update the code to also send password request after email update to user
for(Integer i=0;i<updateResults.size();i++){
if (updateResults.get(i).isSuccess()){
updateResults.get(i).getId();

}else if (!updateResults.get(i).isSuccess()){
// DML operation failed
Database.Error error = updateResults.get(i).getErrors().get(0);
String failedDML = error.getMessage();
arudate.get(i);//failed record from the list
system.debug('Failed ID'+arudate.get(i).Id);
}

}
*/
        } 
        }
    }
   
}