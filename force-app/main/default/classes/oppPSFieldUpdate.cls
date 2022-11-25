/********************************************************************
// Purpose              : Update Apps PS , Security PS && Infra PS Field on Opportunity on the bases of focus Area record
// Author               : Atul
// Parameters           : List<Opportunity>
//  Returns             : void
//JIRA Reference        : SFDC-7894 - Develop ProServ Product Field (Calculated)
********************************************************************/ 
public class oppPSFieldUpdate {
    public Static void updateOppPSValue(List<Opportunity> OppFocusAreaList ){
        system.debug('calling updateOppPSValue');
        List<Opportunity> updateOppList = new List<Opportunity>();
        Map<id,List<Opp_FocusArea__c>> mapidObj = new Map<id,List<Opp_FocusArea__c>>();
        List<Opp_FocusArea__c> focus = [SELECT id,name,Focus_Area_Total__c,Product_Group__c,Opportunity__c
                                   FROM Opp_FocusArea__c Where Opportunity__c IN: OppFocusAreaList];
        if(!focus.isEmpty()){
        For(Opp_FocusArea__c eachfocus : focus){
            if(mapidObj.containsKey(eachfocus.Opportunity__c) && mapidObj.get(eachfocus.Opportunity__c) != null){
                List<Opp_FocusArea__c> focusLst = mapidObj.get(eachfocus.Opportunity__c);
                focusLst.add(eachfocus);
                mapidObj.put(eachfocus.Opportunity__c,focusLst);
            }
            else{
                mapidObj.put(eachfocus.Opportunity__c,new List<Opp_FocusArea__c> {eachfocus});
            }
        }
        For(Opportunity eachOpp : OppFocusAreaList){
            
            //if(eachOpp.Category__c == 'Bookings Credit' || eachOpp.Type == 'Professional Services' || eachOpp.Type == 'TriCore ProServe'){
                eachOpp.Apps_PS__c = 0;
                eachOpp.Security_PS__c = 0;
                eachOpp.Infra_PS__c = 0;
            For(Opp_FocusArea__c eachFocusRec: mapidObj.get(eachOpp.id)){
                system.debug('eachFocusRec.Focus_Area_Total__c'+eachFocusRec.Focus_Area_Total__c);
                if(eachFocusRec.Product_Group__c == 'Application Services' || eachFocusRec.Product_Group__c == 'Data services'){
                       eachOpp.Apps_PS__c = eachOpp.Apps_PS__c + eachFocusRec.Focus_Area_Total__c;
                    }
                    else if(eachFocusRec.Product_Group__c == 'Managed security'){
                        eachOpp.Security_PS__c = eachOpp.Security_PS__c + eachFocusRec.Focus_Area_Total__c;
                    }
                    else{
                        eachOpp.Infra_PS__c = eachOpp.Infra_PS__c + eachFocusRec.Focus_Area_Total__c;
                    }
                
            }   
                updateOppList.add(eachOpp);
           // }
            
        }
        }
         if(!updateOppList.isEmpty()){
            update updateOppList;
        }
        
    }
    @InvocableMethod
    public Static void updateOppPSValueFuture(List<Id> oppID){
        List<Opportunity> oppRecords = [SELECT id,name,Apps_PS__c,Security_PS__c,Infra_PS__c FROM Opportunity where id =: oppID];
       updateOppPSValue(oppRecords);
        
    }

}