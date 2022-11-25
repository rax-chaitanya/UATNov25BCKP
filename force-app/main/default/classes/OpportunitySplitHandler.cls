/**********************************************************************************

Author: Pradeep Guttha
Description: This apex class is created for the Trigger Framework. This class 
controls the flow of execution of the trigger.

**********************************************************************************/

public class OpportunitySplitHandler implements TriggerInterface
{
    public static Boolean IS_TRIGGER_ENABLED = true;
    public static boolean firstTgrRun = true;
    public static string stopRecursion = 'Before Update';
    
    public Boolean isActive()
    {
        return IS_TRIGGER_ENABLED && Trigger_Manager__c.getInstance('OpportunitySplitTgr').Is_Active__c;
    }
 
    public void beforeInsert() {}
 
    public void beforeUpdate() {
        if(stopRecursion == 'Before Update'){
            stopRecursion = 'After Update'; 
    
     for(OpportunitySplit os : (List<OpportunitySplit>)Trigger.new)
     {
        system.debug('*******************::'+os.Old_Opportunity_Id__c);
        //if(os.SplitOwnerId <> os.Opportunity.OwnerId)
        //{ 
       system.debug('Opp Old Id ***Before********::'+os.Old_Opportunity_Id__c);
       //os.Old_Opportunity_Id__c = 'testing'; 
       system.debug('Opp Old Id *****After*******::'+os.Old_Opportunity_Id__c);
       // }
     }
        }
    }
    
    public void beforeDelete() {}
 
    public void afterInsert()  {}
 
    public void afterUpdate() {}
 
    public void afterDelete() {
        List<OpportunitySplit> OppSplitList = (List<OpportunitySplit>)Trigger.old;
        DeleteUndeleteTriggerHandler.DeleteUndelete(OppSplitList, 'OpportunitySplit');
    }
    
    public void afterUndelete() {}
    
}