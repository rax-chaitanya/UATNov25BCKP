/*********************************************************************************

Author: Chaitanya
defect - This is created due to large execution issue with Journey builder flow related to campaings.so if in future some records fail we also need to check JB flows that if
they are updated and optimized
Description: This apex class is created for running the add lead to campaign member in async mode and this code will post dml fails on clog record.
SFDC-7824 - added LeadHelper.AddLeadTocampaign();  method code and modified it to run afterinsert and afterupdate
Test Class - LeadRelatedList_Test3
**********************************************************************************/

public with sharing class LeadHelperQueueable implements Queueable{
public Map<Id,Lead> leadstocmpin;
public Map<Id,Lead> leadstocmpup;

public boolean afterInsert;
public boolean afterUpdate;
public Map<Id,Lead> OldLeadsMap;

public LeadHelperQueueable( Map<Id,Lead> newleadstoinsert,boolean afInsert,boolean afUpdate) {
    this.leadstocmpin= new  Map<Id,Lead>([select id,Promo_Code__c,CMP__c,UTM_Campaign__c,LeadSource from lead where id IN:newleadstoinsert.keyset() FOR UPDATE]);
    //this.leadstocmpin=newleadstoinsert;
    this.afterInsert=afInsert;
    this.afterUpdate=afUpdate;
}
public LeadHelperQueueable( Map<Id,Lead> newleadstoupdate,Map<Id,Lead> leadsOldMap,boolean afInsert,boolean afUpdate) {
    this.leadstocmpup=new  Map<Id,Lead>([select id,Promo_Code__c,CMP__c,UTM_Campaign__c,LeadSource from lead where id IN:newleadstoupdate.keyset() FOR UPDATE]);
    //this.leadstocmpup=newleadstoupdate;
    this.afterInsert=afInsert;
    this.afterUpdate=afUpdate;
    this.OldLeadsMap=leadsOldMap;
}


public void execute(QueueableContext qc){
    try {
        if (afterInsert) {
            
            
            List<CampaignMember> cm = new List<CampaignMember>();
            Set<String> campaignNames = new Set<String>();
            for (Lead ld : leadstocmpin.values()) {
                if (String.isNotBlank(ld.Promo_Code__c) && System.Label.LeadSourcePartnerNetwork.contains(ld.LeadSource)) {
                    campaignNames.add(ld.Promo_Code__c.toLowerCase());
                }
                if (String.isNotBlank(ld.UTM_Campaign__c)) {
                    campaignNames.add(ld.UTM_Campaign__c.toLowerCase());
                }
                if (String.isNotBlank(ld.CMP__c)) {
                    campaignNames.add(ld.CMP__c.toLowerCase());
                }      
            }
            
            if (!campaignNames.isEmpty()) {
                
                Map <String,Id> campaignMap = new Map<String,Id>();
                for (Campaign ca : [SELECT id, name FROM Campaign WHERE name IN :campaignNames FOR UPDATE]) {
                    campaignMap.put(ca.Name.toLowerCase(), ca.id);
                }
                for (Lead ld : leadstocmpin.values()) {
                    // SFDC-2705 - Check for Campaign eligibility by Promo_Code__c field.
                    if (String.isNotBlank(ld.Promo_Code__c)) {
                        // Check if lowercase Campaign name is in the Map.
                        if (campaignMap.containsKey(ld.Promo_Code__c.toLowerCase())) {
                            // Add new CampaignMember to List.
                            cm.add(new CampaignMember(CampaignId=campaignMap.get(ld.Promo_Code__c.toLowerCase()), LeadId=ld.id));
                        }
                    }
                    // SFDC-3058 - Check for Campaign eligibility by UTM_Campaign__c field. 
                    if (String.isNotBlank(ld.UTM_Campaign__c)) {
                        // Check if lowercase Campaign name is in the Map.
                        if (campaignMap.containsKey(ld.UTM_Campaign__c.toLowerCase())) {
                            // Add new CampaignMember to List.
                            cm.add(new CampaignMember(CampaignId=campaignMap.get(ld.UTM_Campaign__c.toLowerCase()), LeadId=ld.id));
                        }
                    }
                    // SFDC-3058 - Check for Campaign eligibility by CMP__c field. 
                    if (String.isNotBlank(ld.CMP__c)) {
                        Boolean matchingUtm = String.isNotBlank(ld.UTM_Campaign__c) && ld.CMP__c.toLowerCase() == ld.UTM_Campaign__c.toLowerCase();
                        // Check if lowercase Campaign name is in the Map.
                        if (!matchingUtm && campaignMap.containsKey(ld.CMP__c.toLowerCase())) {
                            // Add new CampaignMember to List.
                            cm.add(new CampaignMember(CampaignId=campaignMap.get(ld.CMP__c.toLowerCase()), LeadId=ld.id));
                        }
                    }
                }
                // Insert CampaignMembers in bulk.
                if (!cm.isEmpty()) {
                    //insert cm;           
                    Database.SaveResult[] results = Database.insert(cm, false);
                    ErrorLogHelper.logErrorRecords(results,cm,'LeadHelperQueueable');
                }
                
            }
        }
            
            else If(afterUpdate){
                
                Map<Id,String> leadIdVspromos= new Map<Id,String>();
                Set<String> oldPromocodes = new Set<String>();
                For(Lead ld: leadstocmpup.values()){
                    if(String.isNotBlank(ld.Promo_Code__c) && ld.Promo_Code__c!=null   && ld.LeadSource == Label.LeadSourcePartnerNetwork && OldLeadsMap.get(ld.id).Promo_Code__c != ld.Promo_Code__c){ 
                        leadIdVspromos.put(ld.Id,ld.Promo_Code__c.toLowerCase());
                        if(string.isNotBlank(OldLeadsMap.get(ld.id).Promo_Code__c)){
                            oldPromocodes.add(OldLeadsMap.get(ld.id).Promo_Code__c.toLowerCase());
                        }
                    }
                    // SFDC-3214 - Lead Campaign Members for UTM_Campaign__c/CMP__c Updates
                    if(String.isNotBlank(ld.UTM_Campaign__c) && OldLeadsMap.get(ld.id).UTM_Campaign__c != ld.UTM_Campaign__c){ 
                        leadIdVspromos.put(ld.Id,ld.UTM_Campaign__c.toLowerCase());
                        /*
Disabled to prevent deleting previous campaign member records
@see Case #: 00057369
if(string.isNotBlank(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).UTM_Campaign__c)){
oldPromocodes.add(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).UTM_Campaign__c.toLowerCase());
}
*/
                    }
                    if(String.isNotBlank(ld.CMP__c) && OldLeadsMap.get(ld.id).CMP__c != ld.CMP__c){ 
                        
                        leadIdVspromos.put(ld.Id,ld.CMP__c.toLowerCase());
                        /*
Disabled to prevent deleting previous campaign member records
@see Case #: 00057369
if(string.isNotBlank(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).CMP__c)){
oldPromocodes.add(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).CMP__c.toLowerCase());
}
*/
                    }
                }
                
                if(!leadIdVspromos.isEmpty()){
                    List<CampaignMember> cm=new List<CampaignMember>();
                    /*
Disabled to prevent deleting previous campaign member records
@see Case #: 00057369

Delete [Select Id from CampaignMember where campaign.Name in : oldPromocodes and LeadId in : leadIdVspromos.keySet()];

Build old and current campaign member lists
@see Case #: 00057369
*/
                    List<CampaignMember> currentMembership = [Select Id, LeadId, Campaign.Name from CampaignMember where LeadId in : leadIdVspromos.keySet() FOR UPDATE];
                    List<CampaignMember> oldCm=new List<CampaignMember>();
                    Map<ID, Set<String>> existingCM = new Map<ID, Set<String>>();
                    for(CampaignMember myCm : currentMembership){
                        if (oldPromocodes.contains(myCm.Campaign.Name.toLowerCase())) {
                            oldCm.add(myCm);
                        }
                        if (!existingCM.containsKey(myCm.LeadId)) {
                            existingCM.put(myCm.LeadId, new Set<String>());
                        }
                        existingCM.get(myCm.LeadId).add(myCm.Campaign.Name.toLowerCase());
                    }
                    
                    Map <String,Id> campaignMap = new Map<String,Id>();
                    for(Campaign ca :[select id, name FROM Campaign WHERE name in : leadIdVspromos.values()]){
                        campaignMap.put(ca.Name.toLowerCase(),ca.id);
                    }
                    
                    /*
Declare variables before for loop
@see Case #: 00057369
*/
                    Boolean addPromoCodeCM, addUtmCM, addCmpCM;
                    Set<String> leadCm;
                    For(lead Mylead:leadstocmpup.values()){
                        /*
Get the list of campaign names for current membership
@see Case #: 00057369
*/
                        leadCm = existingCM.containsKey(Mylead.Id) ? existingCM.get(Mylead.Id) : new Set<String>();
                        /*
Handle promo code campaign members
@see Case #: 00057369
if(String.isNotBlank(Mylead.Promo_Code__c) && campaignMap.containsKey(MyLead.Promo_Code__c.toLowerCase())){
*/
                        addPromoCodeCM = String.isNotBlank(Mylead.Promo_Code__c) && 
                            campaignMap.containsKey(MyLead.Promo_Code__c.toLowerCase()) && 
                            !leadCm.contains(MyLead.Promo_Code__c.toLowerCase());
                        if (addPromoCodeCM) {
                            cm.add(new CampaignMember(campaignid=campaignMap.get(MyLead.Promo_Code__c.toLowerCase()),leadid=Mylead.id));
                        }
                        /*
Handle UTM Campaign campaign members
@see Case #: 00057369
@see SFDC-3214 - Lead Campaign Members for UTM_Campaign__c/CMP__c Updates
if(String.isNotBlank(Mylead.UTM_Campaign__c) && campaignMap.containsKey(MyLead.UTM_Campaign__c.toLowerCase())){
*/
                        addUtmCM = String.isNotBlank(Mylead.UTM_Campaign__c) && 
                            campaignMap.containsKey(MyLead.UTM_Campaign__c.toLowerCase()) &&
                            !leadCm.contains(MyLead.UTM_Campaign__c.toLowerCase());
                        if (addUTMCM) {
                            cm.add(new CampaignMember(campaignid=campaignMap.get(MyLead.UTM_Campaign__c.toLowerCase()),leadid=Mylead.id));
                        }
                        /*
Handle CMP campaign members
@see Case #: 00057369
@see SFDC-3214 - Lead Campaign Members for UTM_Campaign__c/CMP__c Updates
if(String.isNotBlank(Mylead.CMP__c) && campaignMap.containsKey(MyLead.CMP__c.toLowerCase())){
*/
                        addCmpCM = String.isNotBlank(Mylead.CMP__c) && 
                            campaignMap.containsKey(MyLead.CMP__c.toLowerCase()) &&
                            !leadCm.contains(MyLead.CMP__c.toLowerCase());
                        if (addCmpCM) {
                            cm.add(new CampaignMember(campaignid=campaignMap.get(MyLead.CMP__c.toLowerCase()),leadid=Mylead.id));
                        }
                    }
                    /*
Add new campaign members and delete old where needed
@see Case #: 00057369
*/
                    //insert cm;
                    Database.SaveResult[] results = Database.insert(cm, false);
                    ErrorLogHelper.logErrorRecords(results,cm,'LeadHelperQueueable');
                    delete oldCm;
                    
                    
                }
                
            }
        } catch (Exception ex)
        {
            
            ErrorLogHelper.ClogErrorRecord(ExceptionHandler.getBody(ex),'CMPtoLeadError');
            
        }
        
    }
    
}