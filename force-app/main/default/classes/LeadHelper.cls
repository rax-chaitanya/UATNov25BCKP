/**
* @description       : 
* @author            : Atheer Bdaiwi
* @group             : 
* @last modified on  : 06-16-2021
* @last modified by  : Atheer Bdaiwi
* Modifications Log 
* Ver   Date         Author          Modification
* 1.0   06-16-2021   Atheer Bdaiwi   Initial Version
**/
public class LeadHelper {
    
    public static boolean deleteCMPRun = true;
    
    public static void mapLeadFiledsforAccountAndOpportunity(Map<Id,Lead> convertedLeads){
        try
        {   
            Set<Id> converConIds=new Set<Id>();
            List<Note> contact_notes = new list<note>();
            List<ContentDocumentLink> oppNotes = new List<ContentDocumentLink>();
            List<ContentDocumentLink> leadNotes = new List<ContentDocumentLink>();
            List<lead> leadWithContacts = [Select id, convertedContactId,ownerid from Lead where id in : convertedLeads.keySet()];
            List<id> convertedContact =  new List<id>();
            List<Lead> partnerLeads = new List<Lead>();
            List<id> leadOwnerIds = new List<id>(); // Added by Sreeram for SFDC-3186
            Map<Id,Account> comIdVsAccounts = new Map<Id,Account>();
            for(lead leadcon : leadWithContacts){
                convertedContact.add(leadcon.convertedContactId );
                leadOwnerIds.add(leadcon.ownerid);// Added by Sreeram for SFDC-3186
                
            }
            // Added by Sreeram for SFDC-3186-- start
            Map<id,string> leadOwnerRegionMap = new Map<id,string>();
            if(!leadOwnerIds.isEmpty()){ 
                List<user> leadOwner = [select id , name,region__c from user where id in:leadOwnerIds ];
                for(user userLead: leadOwner){
                    leadOwnerRegionMap.put(userLead.id,userLead.region__c);
                }
            }
            if(!convertedContact.isEmpty()){ 
                // Added by Sreeram for SFDC-3186-- End
                contact_notes= [select id,parentId,title,body from note where parentId in : convertedContact];
            }
            
            list<id> leadids = new list<id>();
            
            leadids.addall(convertedleads.keyset());
            if(!leadids.isEmpty()){  
                leadnotes = [select linkedEntityId, contentdocumentid, id from contentdocumentlink where LinkedEntityId IN: leadids ];
            }
            if(!contact_notes.isEmpty()){
                for(lead convertlead : convertedLeads.values()){
                    for(contentdocumentlink cdl : leadnotes){
                        oppNotes.add(new ContentDocumentLink(linkedEntityId = convertlead.ConvertedOpportunityId,contentdocumentid=cdl.contentdocumentid,ShareType= 'v'));
                    }
                } 
            }
            //End
            Set<Id> conaccountIds = new Set<Id>();
            set<Id> conopportunityIds = new Set<Id>();
            set<Id> LeadaccountIds = new Set<Id>();
            //GTMO-59-- START, Samba
            Set<Id> companyaccs = new Set<Id>();
            Set<Id> productaccs = new Set<Id>();
            Set<Id> compids = new Set<Id>();
            list<account> comprodacclist = new list<account>();
            list<account> prospectact = new list<account>();
            Map<Id,Id> comaccmap = new Map<Id,Id>();
            Map<Id,Id> comprodaccmap = new Map<Id,Id>();
            String parentcompId;
            String companytype = System.Label.CheckCompanyonRecordType;
            //GTMO-59-- END, Samba
            Map<Id,Account> conaccounts = new Map<Id,Account>();
            Map<Id,Opportunity> conopportunities = new Map<Id,Opportunity>();
            List<OpportunityTeamMember> optyTeamMembers = new List<OpportunityTeamMember>();
            String profileName = [Select id,Name from Profile Where id =: UserInfo.getProfileId() limit 1].Name;
            Set<String> opportunityTypes = new Set<String>();
            Map<String,OppRecordTypeMapping__c> oppTypeVsRecordTypes = new Map<String,OppRecordTypeMapping__c>();
            Id govRecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Government').getRecordTypeId();
            Id RBURecTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('RBU').getRecordTypeId();
            Id oppGovRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Government').getRecordTypeId();
            Id compGovRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Government Company').getRecordTypeId();
            Id accGovRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Government').getRecordTypeId();
            Id conGovRecTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Government').getRecordTypeId();
            Id oppRBURecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('RBU').getRecordTypeId();
            Id accRBURecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('RBU').getRecordTypeId();
            Id accCustomerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Customer').getRecordTypeId();
            for(Lead convertlead : convertedLeads.values()){
                conaccountIds.add(convertlead.ConvertedAccountId);
                conopportunityIds.add(convertlead.ConvertedOpportunityId);
                converConIds.add(convertlead.ConvertedContactId);
                if(String.isNotBlank(convertlead.Lead_Type__c))
                    opportunityTypes.add(convertlead.Lead_Type__c); 
                if(String.isNotBlank(convertlead.Partner_Company__c))
                    partnerLeads.add(convertlead);
            }
            if(!conaccountIds.isEmpty()){ 
                conaccounts = new Map<Id,Account>([select id,name,Account_Number__c,Territory__c,Linked_Account_CORE_number__c,BillingCity,BillingCountry,BillingState,BillingStreet,BillingPostalCode,Company_Name__c,DDI__c,FocusArea__c,Type__c,Website,RecordTypeId  from Account where  Company_Name__c in :conaccountIds and Type ='Prospect' order by CreatedDate desc]);
            }
            if(conaccounts.isempty()){
                conaccounts=new Map<Id,Account>([select id,name,Account_Number__c,Territory__c,Linked_Account_CORE_number__c,BillingCity,BillingCountry,BillingState,BillingStreet,BillingPostalCode,Company_Name__c,DDI__c,FocusArea__c,Type__c,Website,RecordTypeId,Type  from Account where  id in :conaccountIds ]);
            }
            // Added by Anjaneyulu for SFSB-466 -- Starts
            Map<Id,Account> companymap = new Map<Id,Account>([Select id,Name,ownerid,Company_Name__c,NotifiedSystems__c,ParentId,RecordTypeId,Billingstreet,BillingCity,BillingState,billingcountry,billingpostalcode,Shippingstreet,ShippingCity,ShippingState,Shippingcountry,Shippingpostalcode from Account where id in:conaccountIds]);
            Map<Id,Contact> contactmap = new Map<Id,Contact>([Select id,LastName,FirstName,RecordtypeId from Contact where id in:converConIds]);
            for(Account acc : companymap.values()){
                acc.ShippingStreet = acc.BillingStreet;
                acc.ShippingCity = acc.BillingCity;
                acc.ShippingState = acc.BillingState;
                acc.ShippingCountry = acc.BillingCountry;
                acc.ShippingPostalCode = acc.BillingPostalCode;
            } 
            // Added by Anjaneyulu for SFSB-466 -- Ends
            for(Account accCom : conaccounts.values()){
                if(accCom.Company_Name__c !=null && conaccountIds.contains(accCom.id)){
                    comIdVsAccounts.put(accCom.id,accCom);
                } else {
                    comIdVsAccounts.put(accCom.Company_Name__c,accCom);
                }
            }
            if(!conopportunityIds.isEmpty()) 
                conopportunities = new Map<Id,Opportunity>([select id,name,Accountid,Account__c,LDT_Rep__c,LDT_Role__c,LDT_Date_Passed__c,LDT_Role_ID__c,Lead_Generator__c,Lead_Generator_Role__c,Lead_ID__c,LeadSource,Primary_Contact__c,Type,Lost_Reason__c,Lost_Sub_Reason__c,Max_Date_Passed__c,Max_Lead_Gen__c,
                                                            Max_Lead_Role__c,NextStep,Other_Resolution__c,Owner_Role__c,rvpe__DateAssignedToPartner__c,rvpe__IsDealRegistration__c,StageName from Opportunity where id in:conopportunityIds]); 
            if(!opportunityTypes.isEmpty()){           
                for(OppRecordTypeMapping__c optype : [Select OppType__c, INTL_RecordType__c,US_RecordType__c from OppRecordTypeMapping__c where OppType__c in :opportunityTypes ]){
                    oppTypeVsRecordTypes.put(optype.OppType__c, optype) ;  
                }
            }
            for(Lead convertLeadValue : convertedLeads.values()){
                Opportunity oppLead = conopportunities.get(convertLeadValue.ConvertedOpportunityId);
                if(oppLead != null){
                    if(comIdVsAccounts.get(convertLeadValue.ConvertedAccountId) != null && comIdVsAccounts.get(convertLeadValue.ConvertedAccountId).Account_Number__c!= null && convertLeadValue.Name != null)
                        oppLead.Name = comIdVsAccounts.get(convertLeadValue.ConvertedAccountId).Account_Number__c+convertLeadValue.Name;
                    oppLead.LeadSource = convertLeadValue.LeadSource;
                    oppLead.Type = convertLeadValue.Lead_Type__c;
                    // Added by Anjaneyulu for SFSB -424 -- Starts
                    system.debug('Lead_Type__c........'+convertLeadValue.Lead_Type__c);
                    system.debug('oppTypeVsRecordTypes........'+oppTypeVsRecordTypes);
                    if(String.isNotBlank(convertLeadValue.Lead_Type__c)){
                        OppRecordTypeMapping__c recordTypeMapping = oppTypeVsRecordTypes.get(convertLeadValue.Lead_Type__c);
                        if(recordTypeMapping != null){
                            if(leadOwnerRegionMap.get(convertLeadValue.ownerid) != 'AMER' )  // Added by Sreeram for SFDc-3186.
                                oppLead.RecordTypeId = recordTypeMapping.INTL_RecordType__c;
                            if(leadOwnerRegionMap.get(convertLeadValue.ownerid) == 'AMER' )  // Added by Sreeram for SFDC-3186.
                                oppLead.RecordTypeId = recordTypeMapping.US_RecordType__c;
                            
                        }
                    }
                    // Added by Anjaneyulu for SFSB -424 -- Ends
                    oppLead.OwnerId = convertLeadValue.OwnerId;
                    oppLead.StageName ='Stage 1 - Planning & Identification';
                    //Added by Siva Malli for SFDC-1144--starts
                    if(govRecTypeId == convertLeadValue.recordTypeId)
                        oppLead.RecordTypeId = oppGovRecTypeId;
                    if(RBURecTypeId == convertLeadValue.recordTypeId)
                        oppLead.RecordTypeId = oppRBURecTypeId;
                    //Added by Siva Malli for SFDC-1144--Ends
                    // Added by Anjaneyuly for SFDC-2154 -- Starts
                    if(convertLeadValue.Campaign_Interest__c == 'E&A Cart' && convertLeadValue.Territory__c == 'EMEA' && convertLeadValue.LeadSource =='Site Submission'){
                        oppLead.StageName =Label.AutoConvertedOpportunityStage; // Updated this for SFDC-2533 by Anjaneyulu
                        oppLead.CloseDate = System.today();
                        oppLead.OwnerId = Label.EMEA_Opportunity_OwnerId;
                        oppLead.Market_Source__c ='No';
                        oppLead.Focus_Area__c = 'Cloud Office';
                        if(RBURecTypeId != convertLeadValue.recordTypeId){
                            oppLead.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('INTL Cloud').getRecordTypeId();
                        }
                        oppLead.Type = 'Mail Online Signup';
                        oppLead.Support_Unit__c = 'Email & Apps';
                    }
                    
                    // Added by Anjaneyuly for SFDC-2154 -- Ends
                    // Added by Atul for SFDC-7531 --Start
                    // To filling the value of forecast bucket on opportunity from lead.
                    oppLead.Forecast_Bucket__c = mappedForecastBucketField(new List<Opportunity>{oppLead});
                     // Added by Atul for SFDC-7531 --end
                    
                }
                Account accLead = comIdVsAccounts.get(convertLeadValue.ConvertedAccountId);
                Account company = companymap.get(convertLeadValue.ConvertedAccountId);
                if(govRecTypeId == convertLeadValue.recordTypeId){
                    company.RecordTypeId = compGovRecTypeId;  
                    Contact conLead = contactmap.get(convertLeadValue.ConvertedContactId);
                    conLead.RecordTypeId = conGovRecTypeId;
                }
                //GTMO-397,Samba Updating contact to company Start
                Contact con = contactmap.get(convertLeadValue.ConvertedContactId);
                if(companyaccs.size()>0 && comprodaccmap.containsKey(convertLeadValue.ConvertedAccountId) && comprodaccmap.size() > 0){
                    con.AccountId = convertLeadValue.ConvertedAccountId;
                }
                else if(productaccs.size()>0 && comaccmap.containsKey(convertLeadValue.ConvertedAccountId) && comaccmap.size() > 0){
                    con.AccountId = comaccmap.get(convertLeadValue.ConvertedAccountId);
                }
                //GTMO-397,Samba Updating contact to company End
                //SFDC-6504 excluding lead data updating to Customer accounts
                if(accLead != null && accLead.RecordTypeId != accCustomerRecordTypeId){
                    if(govRecTypeId == convertLeadValue.recordTypeId)
                        accLead.RecordTypeId = accGovRecTypeId; 
                    if(RBURecTypeId == convertLeadValue.recordTypeId)
                        accLead.RecordTypeId = accRBURecTypeId;
                    // Added by Anjaneyulu for SFSB-446 -- Starts
                    accLead.shippingstreet = company.ShippingStreet;
                    accLead.shippingcity = company.ShippingCity;
                    accLead.ShippingState = company.ShippingState;
                    accLead.ShippingCountry = company.ShippingCountry;
                    accLead.ShippingPostalCode = company.ShippingPostalCode;
                    // Added by Anjaneyulu for SFSB-446 -- Ends
                    accLead.BillingCity = convertLeadValue.City;
                    accLead.BillingCountry= convertLeadValue.Country;
                    accLead.BillingState = convertLeadValue.State;
                    accLead.BillingStreet = convertLeadValue.Street;
                    accLead.BillingPostalcode = convertLeadValue.PostalCode;
                    accLead.DDI__c = convertLeadValue.DDI__c;
                    accLead.Territory__c = convertLeadValue.Territory__c;
                    accLead.FocusArea__c = convertLeadValue.Focus_Area__c;
                    accLead.Website = convertLeadValue.Website;
                    // Added by Anjaneyuly for SFDC-2154 -- Starts
                    if(convertLeadValue.Campaign_Interest__c == 'E&A Cart' && convertLeadValue.Territory__c == 'EMEA' && convertLeadValue.LeadSource =='Site Submission'){
                        accLead.Type__c ='Customer';
                        if(RBURecTypeId == convertLeadValue.recordTypeId){
                            accLead.RecordTypeId = Label.AccountCustomerRecordTypeId;
                        }
                        accLead.Sub_Type__c = 'External Customer';  
                        accLead.Status__c = 'Active';
                        accLead.Industry ='Other';
                        accLead.Support_Segment__c ='Managed';
                        accLead.Service_Level__c ='Managed';
                        accLead.Support_Office__c ='UK';
                        accLead.Support_Team__c = 'Team UK SI';
                    }
                    // Added by Anjaneyuly for SFDC-2154 -- Ends
                }
            }
            for(Specialist__c sp : [select id,Lead__c,name,Additional_Sales_Team__c,Additional_Team_Type__c,CreatedById from  Specialist__c where Lead__c in : convertedLeads.keySet()]){
                Lead spLead = convertedLeads.get(sp.Lead__c);
                optyTeamMembers.add(new OpportunityTeamMember(UserId=sp.Additional_Sales_Team__c,TeamMemberRole=sp.Additional_Team_Type__c,OpportunityId=spLead.ConvertedOpportunityId));
            }
            Map<Id,Partner_Role__c> proles = new Map<Id,Partner_Role__c>([select id,name,Lead__c,Opportunity__c from Partner_Role__c where Lead__c in :convertedLeads.keySet()]);
            for(Id prid :proles.keySet()){
                Partner_Role__c partnerRole = proles.get(prid);
                Lead partnerLead = convertedLeads.get(partnerRole.Lead__c);
                partnerRole.Opportunity__c = partnerLead.ConvertedOpportunityId;
                // Added by Venkat for STGET-320
                partnerRole.Lead__c = null;
                partnerRole.Old_Record_Id__c = null; //raj - sfdc 639
            }
            // Added by Biswa for SFDC-1873 on 18/04/2018
            Map<Id,LiveChatTranscript> LiveChat = new Map<Id,LiveChatTranscript>([Select Id,LeadId,Opportunity__c From LiveChatTranscript where LeadId in :convertedLeads.keySet()]);
            if(LiveChat.size() > 0 ){
                for(LiveChatTranscript Live : LiveChat.values()){
                    if(String.isNotBlank(ConvertedLeads.get(Live.LeadId).ConvertedOpportunityId))
                        Live.Opportunity__c = ConvertedLeads.get(Live.LeadId).ConvertedOpportunityId;
                }
            }
            if(!conopportunities.values().isEmpty()){ 
                update conopportunities.values();
            }
            if(!companymap.values().isEmpty()){
                update companymap.values();
            }
            if(!comIdVsAccounts.values().isEmpty()){
                update comIdVsAccounts.values(); 
            }
            if(!proles.values().isEmpty()){
                update proles.values();  
            }
            if(!contactmap.values().isEmpty()){
                update contactmap.values();
            }
            if(!optyTeamMembers.isEmpty()){
                insert optyTeamMembers;
            }
            if(LiveChat.size() > 0 )
                update LiveChat.values();
            //Added by Kartikeya from SFDC-1122
            if(!partnerLeads.isEmpty() && LeadHelperController.SHARE_COMPANIES_ON_LEAD_CONVERT){
                if(!oppNotes.isEmpty())
                    insert oppNotes;
                CommunitySharingHelper.shareCompaniesOnLeadConvert(partnerLeads);
                LeadHelperController.SHARE_COMPANIES_ON_LEAD_CONVERT = false;
            }
        }
        catch (Exception e) {
            ExceptionHandler.postToAll(e, true);
        }
        
    }
    
    //Added By Thirupathi Aeneni for SFDC-3024 - Started
    Public static void checkAccounttypeforleadconversion(){
        Set<Id> convertedAccountIds = new Set<Id>();
        for(lead eachLead:(List<Lead>)trigger.new){
            if( eachLead.recordtypeid == System.label.LeadGovernmentrecordtypeid && eachLead.isConverted){
                convertedAccountIds.add(eachLead.ConvertedAccountId);
            }
        }
        if(convertedAccountIds.size()>0){
            Id compGovRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Government Company').getRecordTypeId();
            Map<Id,Account> acclist=new Map<Id,Account>([Select id,name,RecordTypeid from Account where id In: convertedAccountIds and RecordTypeid !=: compGovRecTypeId]);
            for(Lead convertingLead : (List<Lead>)Trigger.new){
                if(acclist.containsKey(convertingLead.ConvertedAccountId)){
                    convertingLead.adderror(Label.Non_Synch_Governament_Record_Type_Error_Message);
                }
            }
            
        }
        
        
    }
    //Added By Thirupathi Aeneni for SFDC-3024 - Ended
    public static void processBeforeUpdate(){
        List<Lead> leadList = new List<Lead>();
        Map<Id, Lead> lMap = (Map<Id, Lead>)Trigger.oldMap; 
        //Added By:Vinod Thupakula
        //SFDC-2966  
        //SFDC-2966
        for(Lead leadConv:(List<Lead>)Trigger.new){
            if(lMap.containsKey(leadConv.Id) && (lMap.get(leadConv.Id).Territory__c !='Unassigned' || lMap.get(leadConv.Id).Country != leadConv.Country)){
                leadList.add(leadConv);   
            }   
        }          
        UpdateTerritory.populateTerritory(leadList, lMap, 'Lead');
        
        
        
    }
    // Added by Anjaneyulu for SFDC-2154 -- Starts
    // Added by Anjaneyulu for SFDC-2154 -- Ends  
    //added for SFDC-21, JY(RDC) on Jul/25/2017, begin
    public static void populateVPFromGroup(List<Lead> triggerNew, Map<Id, Lead> triggerOldMap){
        for(Lead eachLead : triggerNew) {
            if((trigger.isInsert || 
                (trigger.isUpdate && 
                 eachLead.Owners_s_Group__c != triggerOldMap.get(eachLead.Id).Owners_s_Group__c)) &&
               String.isNotBlank(eachLead.Owners_s_Group__c) && 
               System.Label.LeadGroup.contains(eachLead.Owners_s_Group__c) &&
               Groups_Vs_VP__c.getInstance(eachLead.Owners_s_Group__c) != null) {
                   eachLead.VP_SLA__c = Groups_Vs_VP__c.getInstance(eachLead.Owners_s_Group__c).UserId__c;
               }
        }
    }
    //added for SFDC-21, JY(RDC) on Jul/25/2017, end
    public static void runAssignmentRules(){
        // Running assignment rules SFDC-20 -- Starts
        Set<Id> partnerLeadIds = new Set<Id>();
        List<sobject> leadList = new List<Lead>();
        Map<Id,Sobject> lmap = new Map<Id,sObject>();
        for(sObject s : Trigger.new ){
            if(((String)s.get('LeadSource')) == Label.LeadSourcePartnerNetwork || ((String)s.get('Territory__c')) == 'Unassigned')
                partnerLeadIds.add((Id)s.get('Id'));
            if(((String)s.get('Territory__c')) == null || ((String)s.get('Territory__c')) == 'Unassigned'){
                leadList.add(new Lead(Id=(Id)s.get('Id'),Country=(String)s.get('country')));
                lmap.put((Id)s.get('Id'),s);
            }
            
        }
        if(!leadList.isEmpty()){
            UpdateTerritory.populateTerritory(leadList, lMap, 'Lead');  
            RunAssignmentRules.runLeadTerritoryAssignmentRules(leadList);    
            //Territory population code is ended
            
        }
        if(!partnerLeadIds.isEmpty())
            RunAssignmentRules.runLeadAssignmentRules(partnerLeadIds);
        // Running assignment rules SFDC-20 -- Ends 
    }   
    public static void updateSourceForPartnerLeads(){
        if(System.Label.Partner_Profiles.contains(UserInfo.getProfileId())){
            User user = [Select Id,AccountId,Account.OwnerId,Account.Owner.Email,Account.Owner.Manager.Email,Account.Territory__c,contactId from User where Id =: UserInfo.getUserId()];
            for(Lead eachLead : (List<Lead>)Trigger.new){
                eachLead.LeadSource = Label.LeadSourcePartnerNetwork;
                eachLead.Partner_Company__c=user.AccountId;
                eachLead.Partner_Account_Manager__c = user.Account.OwnerId;
                if(eachLead.CountryCode=='US'||eachLead.CountryCode=='CA')
                    eachLead.OwnerId=user.Account.OwnerId;
                eachLead.Partner_Territory__c=user.Account.Territory__c;
                if(String.isNotBlank(eachLead.Partner_Account_Manager__c))
                    eachLead.PAM_email__c=user.Account.Owner.Email;
                if(string.isNotBlank(user.Account.Owner.Manager.Email))
                    eachLead.PAMs_Manager__c=user.Account.Owner.Manager.Email;
                eachLead.Partner_Contact__c=user.contactId;
                if(eachLead.Type_Of_Deal__c == Label.Referral)
                    eachLead.Commissions_Role__c = Label.Pay_Commissions;
                else if(eachLead.Type_Of_Deal__c == Label.No_Commissions || eachLead.Type_Of_Deal__c ==Label.Sitecore)//SFDC-2355
                    eachLead.Commissions_Role__c = Label.Dont_pay_commissions;
                else
                    eachLead.Commissions_Role__c= Label.Credit_to_this_Opp_Acct;
            }
            
        }
        
    }  
    public static void ConvertCommentToNote(){
        if(System.Label.Partner_Profiles.contains(UserInfo.getProfileId())){
            List<ContentNote> noteList = new List<ContentNote>();
            List<ContentDocumentLink> cdl = new List<ContentDocumentLink>(); 
            for(Lead eachLead : (List<Lead>)Trigger.new){
                if(eachLead.Customer_Comments__c != null && eachLead.Customer_Comments__c != ''){
                    noteList.add(new ContentNote(Content = Blob.valueof(eachLead.Customer_Comments__c.escapeJava().escapehtml4()), Title = 'Initial Comment'));
                }
            }
            if(!noteList.isEmpty()){
                insert noteList;
                for(Lead eachLead : (List<Lead>)Trigger.new){   
                    for(ContentNote cn : noteList){
                        if(cn.content == Blob.valueof(eachLead.Customer_Comments__c.escapeJava().escapehtml4())){
                            cdl.add(new ContentDocumentLink(linkedEntityId = eachLead.Id,contentdocumentid=cn.id, ShareType= 'v'));
                        }
                    }
                }
                if(!cdl.isEmpty()){
                    insert cdl;
                    
                }
            }
        }
    }
    /**
* Add Lead to Campaign
* Intended for use within LeadHandler.afterInsert()
* @see SFDC-2705, SFDC-3058
*/
    public static void AddLeadTocampaign() {
        
        List<CampaignMember> cm = new List<CampaignMember>();
        Set<String> campaignNames = new Set<String>();
        for (Lead ld : (List<Lead>)Trigger.new) {
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
            for (Campaign ca : [SELECT id, name FROM Campaign WHERE name IN :campaignNames]) {
                campaignMap.put(ca.Name.toLowerCase(), ca.id);
            }
            for (Lead ld : (List<Lead>)Trigger.new) {
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
                insert cm;           
            }       
        }
    }
    // Added by Divya for SFDC-2705-- Starts
    public static void UpdateAddLeadTocampaign(){
        
        Map<Id,String> leadIdVspromos= new Map<Id,String>();
        Set<String> oldPromocodes = new Set<String>();
        For(Lead ld: (List<Lead>)Trigger.new){
            if(String.isNotBlank(ld.Promo_Code__c) && ld.LeadSource == Label.LeadSourcePartnerNetwork && ((Map<Id,Lead>)Trigger.OldMap).get(ld.id).Promo_Code__c != ld.Promo_Code__c){ 
                leadIdVspromos.put(ld.Id,ld.Promo_Code__c.toLowerCase());
                if(string.isNotBlank(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).Promo_Code__c)){
                    oldPromocodes.add(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).Promo_Code__c.toLowerCase());
                }
            }
            // SFDC-3214 - Lead Campaign Members for UTM_Campaign__c/CMP__c Updates
            if(String.isNotBlank(ld.UTM_Campaign__c) && ((Map<Id,Lead>)Trigger.OldMap).get(ld.id).UTM_Campaign__c != ld.UTM_Campaign__c){ 
                leadIdVspromos.put(ld.Id,ld.UTM_Campaign__c.toLowerCase());
                /*
Disabled to prevent deleting previous campaign member records
@see Case #: 00057369
if(string.isNotBlank(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).UTM_Campaign__c)){
oldPromocodes.add(((Map<Id,Lead>)Trigger.OldMap).get(ld.id).UTM_Campaign__c.toLowerCase());
}
*/
            }
            if(String.isNotBlank(ld.CMP__c) && ((Map<Id,Lead>)Trigger.OldMap).get(ld.id).CMP__c != ld.CMP__c){ 
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
            List<CampaignMember> currentMembership = [Select Id, LeadId, Campaign.Name from CampaignMember where LeadId in : leadIdVspromos.keySet()];
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
            For(lead Mylead:(List<Lead>)Trigger.new){
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
            insert cm;
            delete oldCm;
        }
    }
    // Added by Divya for SFDC-2705 -- Ends
    //Added by sundarayya E for SFDC-5307
    public static void updateBtlkAddFields(List<lead> triggerNewList){
        Map<String,string> countryvalues = new Map<String, String>();
        Map<String,string> statevalues = new Map<String, String>();
        Map<String, String> btlkcustStateValue = new Map<String, String>();
        Schema.DescribeFieldResult countryfieldResult = User.Countrycode.getDescribe();
        List<Schema.PicklistEntry> countryPicValues = countryfieldResult.getPicklistValues();
        Map<String, BrightTALK__BrightTalk_State_Codes__c> BtlkcustomStateCodes = BrightTALK__BrightTalk_State_Codes__c.getall();
        for(String key : BtlkcustomStateCodes.keySet()){
            btlkcustStateValue.put(key, BtlkcustomStateCodes.get(key).BrightTALK__State_Alpha_2__c);
        }
        Schema.DescribeFieldResult statefieldResult = User.statecode.getDescribe();
        List<Schema.PicklistEntry> statePicValues = statefieldResult.getPicklistValues();
        for( Schema.PicklistEntry statePickVal : statePicValues){
            statevalues.put(statePickVal.getLabel(), statePickVal.getValue());
        }
        for( Schema.PicklistEntry f : countryPicValues){
            countryvalues.put(f.getLabel(), f.getValue());
        }
        for(Lead le : triggerNewList){
            if(countryvalues.containsKey(le.Btlk_Country__c)){
                le.CountryCode = countryvalues.get(le.Btlk_Country__c);
                if(btlkcustStateValue.containsKey(le.Btlk_Sate_Province__c)){
                    le.StateCode = btlkcustStateValue.get(le.Btlk_Sate_Province__c);
                }else if(statevalues.containsKey(le.Btlk_Sate_Province__c)){
                    le.StateCode = statevalues.get(le.Btlk_Sate_Province__c);
                }
            }
        }
    }
    //Added by sundarayya E for SFDC-5307--Ends
    // Added by Atul for SFDC-7531 --Start
    public static String mappedForecastBucketField(List<Opportunity> opps){
          string forcastbucket;
        if(opps != null && opps.size() > 0){ 
            Map<String,List<String>> picklistValues = ApexDependentPicklistUtility.getDependentOptions('Opportunity','Type','Forecast_Bucket__c');
            for(Opportunity opp : opps){
                if(picklistValues.containsKey(opp.Type) && picklistValues.get(opp.Type).size()>0){
                    forcastbucket = picklistValues.get(opp.Type)[0];
                } 
                else{
                    forcastbucket='';}
            } 
        } 
          return forcastbucket;
    }
    // Added by Atul for SFDC-7531 --End
    
}