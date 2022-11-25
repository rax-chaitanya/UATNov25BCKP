/**
* File :  UpdateEmailOptOut.cls
* Description : Update HasOptedOutOfEmail field for duplicate emails,currently used for Lead and contact.(SFDC-3273)
* Created Date : 17/May/2019 
* Author : RDC
* 
* Last Modified : July 2022
* Changes  : SFDC-7957 Chaitanya - Updated the catch block to not future post to chatter method because it is causing below error
First error: Future method cannot be called from a future or batch method: ExceptionHandler.postToChatter(String)
*Test Class- updateEmailOptOutTest
*/
public class UpdateEmailOptOut{
    @future
    public static void updateEmailOptOutField(Set<String> setOfEmailIds,String sObjectName) {
        try{
            List<SObject> objList = new List<SObject>();
            updateEmailOptOutSecondObjectField(setOfEmailIds, sObjectName,objList);
            if(sObjectName == 'Lead')
            {
                updateEmailOptOutSecondObjectField(setOfEmailIds,'Contact',objList);
            }
            else if(sObjectName == 'Contact')
            {
                updateEmailOptOutSecondObjectField(setOfEmailIds,'Lead',objList);
            }
            if(objList.size()>0){
                update objList;   
            }
        } 
        catch (Exception e) 
        {
            //ExceptionHandler.postToAll(e, true);
            ExceptionHandler.postToChatter(e);
            throw new CustomException(ExceptionHandler.getBody(e));
        }
    }
    public static void updateEmailOptOutSecondObjectField(Set<String> setOfEmailIds,String sObjectName,List<SObject> objList) {
        try{
            String strQuery = 'SELECT Id,HasOptedOutOfEmail FROM '+sObjectName+' WHERE email IN: setOfEmailIds AND HasOptedOutOfEmail = false';
            if(sObjectName == 'Lead'){
                strQuery += ' AND Isconverted = false';
            }
            for(SObject sObj: Database.query(strQuery)){
                sObj.put('HasOptedOutOfEmail',true);
                objList.add(sObj);     
            }
        } 
        catch (Exception e) {
            ExceptionHandler.postToAll(e, true);
            throw new CustomException(ExceptionHandler.getBody(e));  
        }
    }
}