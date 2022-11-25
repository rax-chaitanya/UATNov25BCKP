/**********************************************************************************

Author: Shantan Nagulapalli
Description: This apex class is created for the Trigger Framework. This class 
controls the flow of execution of the trigger.

**********************************************************************************/

public class OpportunityFocusAreaHandler implements TriggerInterface
{ 
    public static Boolean IS_TRIGGER_ENABLED = true;
    public static boolean firstTgrRun = true;
    public static string stopRecursion = 'Before Update';
    Public Static Boolean CheckingAmount = true;
    
    public Boolean isActive()
    {
        return IS_TRIGGER_ENABLED && Trigger_Manager__c.getInstance('OpportunityFocusAreaTgr').Is_Active__c;
    }
    
    public void beforeInsert() 
    {
        CreateFocusAreaRecords.FocusArea();
        
        for (Opp_FocusArea__c fa : (List<Opp_FocusArea__c>) Trigger.new) {
            if (fa.Currency_Mismatch__c) {
                fa.CurrencyIsoCode = fa.OppCurrencyIsoCode__c;
            }
        }
    }
    
    public void beforeUpdate() {
        if(stopRecursion == 'Before Update'){
            stopRecursion = 'After Update'; 
             for (Opp_FocusArea__c fa : (List<Opp_FocusArea__c>) Trigger.new) {
                if (fa.Currency_Mismatch__c) {
                    fa.CurrencyIsoCode = fa.OppCurrencyIsoCode__c;
                }
                
                
                
            }
            
            
        }
    }
    
    public void beforeDelete() {}
    
    public void afterInsert()  {
        
        try{
            //Start : SFDC-7894
            Set<ID> oppID = new Set<ID>();
            List<Opportunity> oppLst = new List<Opportunity>();
            //End : SFDC-7894
            if(opportunityHandler.firstTgrRun == true){
                updateOppForHighLowMargin((List<Opp_FocusArea__c>)Trigger.new);
            }
            //Start : SFDC-7894
            for(Opp_FocusArea__c focusRec : (List<Opp_FocusArea__c>) Trigger.new){
                if(focusRec.Opportunity__c != null && focusRec.Focus_Area_Total__c != null && focusRec.Product_Group__c != null){
                    oppID.add(focusRec.Opportunity__c);
                    
                }
            }
            if(!oppID.isEmpty()){
            oppLst = [SELECT id,name,Category__c,Type,Security_PS__c,Apps_PS__c,Infra_PS__c FROM Opportunity Where id =: oppID AND (Type ='Professional Services' OR Category__c = 'Bookings Credit')];
            }
            if(!oppLst.isEmpty()){
                oppPSFieldUpdate.updateOppPSValue(oppLst); 
            }
            //End : SFDC-7894
        } catch(Exception ex){
            system.debug('Exception in HighLowMarginTriggerHandler.focusAreaTrigger'+ex.getMessage());
        }
    }
    
    public void afterUpdate() {
        
        try{
            //Start : SFDC-7894
            List<Opportunity> oppLst = new List<Opportunity>();
            Map<Id, Opp_FocusArea__c> cMap = (Map<Id, Opp_FocusArea__c>)Trigger.oldMap;
            Map<Id, Opportunity> oppMap = new  Map<Id, Opportunity>();
            Set<Id> oppIds = new Set<Id>();
            Set<Id> oppIds1 = new Set<Id>();
            //End : SFDC-7894
            if(opportunityHandler.firstTgrRun == true){
                updateOppForHighLowMargin((List<Opp_FocusArea__c>)Trigger.new);
                
            }
            //Start : SFDC-7894
            for(Opp_FocusArea__c focusRec : (List<Opp_FocusArea__c>)Trigger.new){
                if(!oppIds.contains(focusRec.Opportunity__c)){
                    oppIds.add(focusRec.Opportunity__c);
                }
            }
            for(Opportunity opp: [Select id, Amount, Net_Focus_Area_Total__c from Opportunity where Id In: oppIds]){
                oppMap.put(opp.id, opp);
            }
            for(Opp_FocusArea__c focusRec : (List<Opp_FocusArea__c>) Trigger.new){
                Opp_FocusArea__c oldValue = cMap.get(focusRec.id);
                if(focusRec.Opportunity__c != null && focusRec.Focus_Area_Total__c != null  && (focusRec.Focus_Area_Total__c != oldValue.Focus_Area_Total__c || focusRec.Product_Group__c != oldValue.Product_Group__c )){
                    // system.debug('qwerty focus Amount change'+focusRec.Focus_Area_Total__c);
                    oppIds1.add(focusRec.Opportunity__c);
                    
                }
            }
            if(!oppIds1.isEmpty()){
            oppLst = [SELECT id,name,Category__c,Type,Security_PS__c,Apps_PS__c,Infra_PS__c FROM Opportunity Where id =: oppIds1 AND (Type ='Professional Services' OR Category__c = 'Bookings Credit')];
            }
            if(!oppLst.isEmpty()){
                oppPSFieldUpdate.updateOppPSValue(oppLst);
                opportunityHandler.firstTgrRun = false;
            }
            //End : SFDC-7894
        } catch(Exception ex){
            system.debug('Exception in HighLowMarginTriggerHandler.focusAreaTrigger'+ex.getMessage());
        }    
    }
    
    public void afterDelete() {
        List<Opp_FocusArea__c> OppFocusAreaList = (List<Opp_FocusArea__c>)Trigger.old;
        DeleteUndeleteTriggerHandler.DeleteUndelete(OppFocusAreaList, 'Opp_FocusArea__c');
        try{
            if(opportunityHandler.firstTgrRun == true){
                updateOppForHighLowMargin((List<Opp_FocusArea__c>)Trigger.new);   
            }
        } catch(Exception ex){
            system.debug('Exception in HighLowMarginTriggerHandler.focusAreaTrigger'+ex.getMessage());
        }
    }
    
    public void afterUndelete() {
        
        try{
            if(opportunityHandler.firstTgrRun == true){
                updateOppForHighLowMargin((List<Opp_FocusArea__c>)Trigger.new);   
            }
        } catch(Exception ex){
            system.debug('Exception in HighLowMarginTriggerHandler.focusAreaTrigger'+ex.getMessage());
        }
    }
    
    
    public void updateOppForHighLowMargin(List<Opp_FocusArea__c> OppFocusAreaList){
        
        //List<Opp_FocusArea__c> OppFocusAreaList = (List<Opp_FocusArea__c>)Trigger.new;
        //List<Opp_FocusArea__c> newOppFocusAreaList = [select Id,Focus_Area_Total__c,Opportunity__c from Opp_FocusArea__c where id =: OppFocusAreaList[0].Id];
        opportunityHandler.firstTgrRun = false;
        Map<String,Map<String, Decimal>> totalMap =  HighLowMarginTriggerHandler.setBookingTotalFieldOnOpportunity(OppFocusAreaList[0].Opportunity__c);  
        if(totalMap.get(OppFocusAreaList[0].Opportunity__c ) != null){
            List<Opportunity> oppList = [SELECT Id, Booking_Total__c, Commission_Booking_Total__c FROM Opportunity WHERE Id=:OppFocusAreaList[0].Opportunity__c ];
            oppList[0].Booking_Total__c = totalMap.get(OppFocusAreaList[0].Opportunity__c ).get('bookingTotal');
            oppList[0].Commission_Booking_Total__c = totalMap.get(OppFocusAreaList[0].Opportunity__c ).get('cbBookingTotal');
            update OppList;    
        }
        
    }
}