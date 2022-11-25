/**
* @description       : SFDC-8248 - Create a Duplicate contact on Closed Won Wizard
* @author            : Someshwar
* Test Class Name - OpportunityCloseWonHelperTest 
*/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class OpportunityCloseWonHelper {
    
    /********************************************************************
// Purpose              : Clone Contact
// Author               : Someshwar
// Parameters           : String
//  Returns             : void
//JIRA Reference        : SFDC-8248 - Create a Duplicate contact on Closed Won Wizard
********************************************************************/ 
    public static void createDuplicateContact(Id contactId,Id ProdAccId){
        Contact contactCloneCopy;
        try{
            Contact con = [SELECT AccountId,Account_Number_QLT__c,Account_Team_Name__c,ACR_Count__c,Amazon_Web_Services_AWS__c,
                           appirio_core__Last_Access_Date__c,appirio_core__Licensed_Features__c,appirio_core__PIN__c,Application_Services__c,AssistantName,AssistantPhone,
                           BatchVerified__c,Batch_Status__c,Birthdate,BrightTALK__Aggregate_Viewing_Duration__c,BrightTALK__BrightTALK_User_Company_Size__c,
                           BrightTALK__BrightTALK_User_Level__c,BrightTALK__Campaign_Display_Name__c,BrightTALK__Campaign_ID__c,BrightTALK__Campaign_Reference__c,
                           BrightTALK__Context_Name__c,BrightTALK__Engagement_Score__c,BrightTALK__Intent_Lead_Scores__c,BrightTALK__Intent_Lead_Score__c,
                           BrightTALK__Lead_Context__c,BrightTALK__Lead_Type__c,BrightTALK__Referral__c,BrightTALK__TimeZone__c,BrightTALK__UserQuestionAnswered__c,
                           BrightTALK__UserQuestionText__c,BrightTALK__User_Id__c,BrightTALK__UTM_Campaign__c,BrightTALK__UTM_Content__c,BrightTALK__UTM_Medium__c,
                           BrightTALK__UTM_Source__c,BrightTALK__UTM_Term__c,Btlk_Country__c,Btlk_Sate_Province__c,BullsEye_Activity_Summary__c,BullsEye_Lead_Details__c,
                           Campaign_Member_Last_Response_Date__c,CASL_Contact_Consent_Date__c,CASL_Contact_Consent__c,Clean_Status__c,Cloud_Infrastructure__c,
                           Cloud_Management__c,Cloud_Migration__c,Cloud_Security__c,Cloud_Strategy__c,cloud_username__c,CMP__c,CM_Existing_Data__c,Cohort_Month__c,
                           ConnectionReceivedId,ConnectionSentId,Contact_Job_Function__c,Contact_Job_Level__c,coreupdatedate__c,Core_Contact_Id__c,
                           Covering_Geographic_Areas__c,CreatedById,CreatedDate,CreatedDate__c,CurrencyIsoCode,Current_Customer__c,Data_Center_Migration__c,
                           Data_Quality_Description__c,Data_Quality_Score__c,Date_Agreed_to_Terms__c,Department,DM_OldRecordId__c,DM_Temp2__c,
                           DNBoptimizer__DnBContactRecord__c,DoNotCall,Double_Opt_In_Contact_Date__c,Double_Opt_In_Contact__c,DOZISF__ZoomInfo_Company_ID__c,
                           DOZISF__ZoomInfo_Enrich_Status__c,DOZISF__ZoomInfo_First_Updated__c,DOZISF__ZoomInfo_Id__c,DOZISF__ZoomInfo_InboxAI_ID__c,
                           DOZISF__ZoomInfo_Last_Updated__c,DOZISF__ZoomInfo_Non_Matched_Reason__c,Do_Not_Mail__c,Do_Not_Survey__c,Do_Not_Sync_to_Marketing_Cloud__c,
                           DSCORGPKG__Company_HQ_Address__c,DSCORGPKG__Company_HQ_City__c,DSCORGPKG__Company_HQ_Country_Code__c,
                           DSCORGPKG__Company_HQ_Country_Full_Name__c,DSCORGPKG__Company_HQ_Postal_Code__c,DSCORGPKG__Company_HQ_State_Full_Name__c,DSCORGPKG__Company_HQ_State__c,
                           DSCORGPKG__Conflict__c,DSCORGPKG__DeletedFromDiscoverOrg__c,DSCORGPKG__department__c,DSCORGPKG__DiscoverOrg_Company_ID__c,DSCORGPKG__DiscoverOrg_Created_On__c,
                           DSCORGPKG__DiscoverOrg_First_Update__c,DSCORGPKG__DiscoverOrg_FullCountryName__c,DSCORGPKG__DiscoverOrg_ID__c,DSCORGPKG__DiscoverOrg_LastUpdate__c,
                           DSCORGPKG__DiscoverOrg_State_Full_Name__c,DSCORGPKG__DiscoverOrg_Technologies__c,DSCORGPKG__Email_Invalid__c,DSCORGPKG__Exclude_Update__c,DSCORGPKG__External_DiscoverOrg_Id__c,DSCORGPKG__ITOrgChart__c,DSCORGPKG__Job_Function__c,DSCORGPKG__LinkedIn_URL__c,DSCORGPKG__Locked_By_User__c,DSCORGPKG__Management_Level__c,DSCORGPKG__MiddleName__c,DSCORGPKG__NickName__c,DSCORGPKG__REMOVELinkedinURL__c,DSCORGPKG__ReportsTo__c,DSCORGPKG__title_Custom__c,DSCORGPKG__Twitter_URL__c,Dummy_Edit__c,Einstein_Engagement_Score__c,Email,EmailBouncedDate,EmailBouncedReason,
                           End_Date__c,et4ae5__HasOptedOutOfMobile__c,et4ae5__Mobile_Country_Code__c,Existing_Rackspace_SalesRep__c,Fax,FirstName,GDPR_Contact_Consent_Date__c,GDPR_Contact_Consent__c,GDPR_Request_Data_Date__c,GDPR_Request_Data__c,GDPR_Request_Delete_Date__c,GDPR_Request_Delete__c,Google_Cloud__c,HasOptedOutOfEmail,HasOptedOutOfFax,HomePhone,Hybrid_Cloud__c,Id,inactive__c,IndividualId,individual_id__c,Initial_Sequence_Date__c,IsDeleted,IsDelete__c,IsEmailBounced,ispartner__c,Is_Billing_Address_Verified__c,Is_Primary_Member__c,Is_Test__c,IT_as_a_Service_ITaaS__c,
                           IT_Cost_Management__c,IT_Transformation__c,Jigsaw,JigsawContactId,jsImpacts__Data_com_does_not_auto_update__c,jsImpacts__Data_com_Managed__c,jsImpacts__Imported_from_Jigsaw__c,Language__c,LastActivityDate,LastCURequestDate,LastCUUpdateDate,LastModifiedById,LastModifiedDate,LastName,LastReferencedDate,LastViewedDate,Last_Activity_Date__c,Last_Activity_within_18_months__c,Last_date_of_survey__c,Lattice_Intent__c,Lattice_Last_Score_Date__c,Lattice_Rating__c,Lattice_Score__c,LBI__LatticeAccountName__c,LD_USE_DnB_Contact__c,LeadSource,MailingAddress,MailingCity,MailingCountry,MailingCountryCode,MailingGeocodeAccuracy,MailingLatitude,MailingLongitude,MailingPostalCode,MailingState,MailingStateCode,MailingStreet,Mailing_Address_Bypassed__c,Mailing_Address_Verified__c,Mailing_County__c,Managed_Security_Services__c,Manager_Employee_Number__c,Manager_Level2__c,Manager_Level3__c,Manager__c,Marketing_Cloud_Last_Activity_Date__c,Marketing_Cloud_Subscriber_Key__c,MasterRecordId,Microsoft_Azure__c,MobilePhone,Most_Customers_In__c,Name,NPS_CCDate__c,NPS_Eligible__c,NPS_Survey_Opt_Out__c,NPS_Survey_Response__c,NPS_Survey__c,NPS_Year_Month__c,NPS__c,Number_of_Active_Sequences__c,Old_Record_Id__c,Old_RV_Member_ID__c,OnicaCollections_Communication_Preferenc__c,Onica_Add_Payment_Method_URL__c,Onica_Anaheim_Summit_2018__c,Onica_AWS_Account_Lead__c,Onica_AWS_Market_Segment__c,Onica_AWS_PSM__c,Onica_AWS_Role__c,Onica_AWS_Team__c,Onica_Bill_Rate__c,Onica_Capacity_in_Current_Month__c,Onica_Capacity_in_Current_Year__c,Onica_Capacity_Test__c,Onica_Comments__c,Onica_Company_News_Subscriber__c,Onica_Coverage_Customers_Notes__c,Onica_Default_Cost_Rate_Hidden__c,Onica_Deprecated__c,Onica_Enable_Email_Notification_FM_Com__c,Onica_Expense_Reimbursement_Account__c,Onica_Ext__c,Onica_First_Conversion__c,Onica_Former_Practice__c,Onica_Full_Time_Contractor__c,Onica_Hire_Date__c,Onica_Hosted_Profiles__c,Onica_Interaction_Count__c,Onica_Last_Contact__c,Onica_List_Source__c,Onica_Longitude_PSA__c,Onica_Member_Pricing_Enabled__c,Onica_Other_Role__c,Onica_PayPal_Payer_Id__c,Onica_ProsperWorksID__c,Onica_Quick_Notes__c,Onica_Rating__c,Onica_Recent_Conversion__c,Onica_Reporting_Line__c,Onica_Resource_Role_Group__c,Onica_Suppress_from_Company_News__c,Onica_Tags__c,Onica_Telesales_Meeting__c,Onica_Telesales__c,Onica_X18_Digit_ID__c,Onica_X130_Hidden_Cost_Rate__c,Optional_Promo_Code__c,Organization_Size__c,OtherAddress,OtherCity,OtherCountry,OtherCountryCode,OtherGeocodeAccuracy,OtherLatitude,OtherLongitude,OtherPhone,OtherPostalCode,OtherState,OtherStateCode,OtherStreet,Outreach_Actively_Being_Sequenced__c,Outreach_Current_Sequence_ID__c,Outreach_Current_Sequence_Name__c,Outreach_Current_Sequence_Status__c,Outreach_Current_Sequence_Step_Number__c,Outreach_Current_Sequence_Step_Type__c,Outreach_Current_Sequence_Task_Due_Date__c,Outreach_Current_Sequence_User_ID__c,Outreach_Date_Added_to_Sequence__c,Outreach_Finished_Sequences__c,Outreach_Initial_Sequence_ID__c,Outreach_Initial_Sequence_Name__c,OwnerId,Owner_Role__c,Owner_SSO__c,Partner_Company__c,Partner_Level__c,Partner_Region__c,pbk__Biography__c,pbk__Last_Sync_Date__c,pbk__Last_Sync_User__c,pbk__pbId__c,pbk__PB_Notes__c,pbk__PitchBook_Link__c,PFLSwagIQ__Next_Birthday__c,PFLSwagIQ__Swaggable__c,PFLSwagIQ__Swag_CM_Trigger_Value__c,PFLSwagIQ__Swag_Last_Sent__c,Phone,PhotoUrl,Preferred_First_Name__c,Preferred_Last_Name__c,Private_Cloud__c,psa_report__Hist_Sch_Utilization__c,psa_report__Resource_Name__c,pse__Action_Calculate_Utilization__c,pse__Action_Update_Current_Time_Period__c,pse__Actuals_Last_Updated_By__c,pse__Actuals_Last_Update_Date__c,pse__Allow_Timecards_Without_Assignment__c,pse__API_Resource_Correlation_Id__c,pse__Billable_External_Hours__c,pse__Billable_Internal_Hours__c,pse__Billed__c,pse__Billings__c,pse__Bookings__c,pse__Credited_Non_Billable_Internal_Hours__c,pse__Current_Time_Period_End_Date__c,pse__Current_Time_Period__c,pse__Daily_Default_Cost_Rate__c,pse__Default_Cost_Rate__c,pse__Employment_Status_Effective_Date__c,pse__Employment_Status__c,pse__ERP_Worker_Correlation_Id__c,pse__Excluded_Hours__c,pse__Exclude_From_Missing_Timecards__c,pse__Exclude_from_Resource_Planner__c,pse__Exclude_From_Time_Calculations__c,pse__Exclude_From_Time_Variance__c,pse__Expense_Budget__c,pse__Expense_Costs__c,pse__External_Costs__c,pse__External_Resource__c,pse__Group__c,pse__Historical_Utilization_Billable_Hours__c,pse__Historical_Utilization_Calendar_Hours__c,pse__Historical_Utilization_Credited_Hours__c,pse__Historical_Utilization_Excluded_Hours__c,pse__Historical_Utilization_Non_Billable_Hrs__c,pse__Historical_Utilization_Target_Attainment__c,pse__Historical_Utilization_Target_Hours__c,pse__Historical_Utilization_Target__c,pse__Historical_Utilization__c,pse__Hist_Sch_Utilization_Billable_Hours__c,pse__Hist_Sch_Utilization_Credited_Hours__c,pse__Hist_Sch_Utilization_Excluded_Hours__c,pse__Hist_Sch_Utilization_Held_Hours__c,pse__Hist_Sch_Utilization_Non_Billable_Hrs__c,pse__Internal_Budget__c,pse__Internal_Costs__c,pse__Invoiced__c,pse__Is_Resource_Active__c,pse__Is_Resource__c,pse__Jira_Correlation_Username__c,pse__Languages__c,pse__Last_Date__c,pse__Latitude_PSA__c,pse__Level__c,pse__Longitude_PSA__c,pse__Margin__c,pse__Non_Billable_External_Hours__c,pse__Non_Billable_Internal_Hours__c,pse__Other_Costs__c,pse__Pass_Through_Billings__c,pse__Practice__c,pse__Pre_Billed__c,pse__Region__c,pse__Resource_Role__c,pse__Revenue__c,pse__Salesforce_User__c,pse__Scheduled_Utilization_Billable_Hours__c,pse__Scheduled_Utilization_Calendar_Hours__c,pse__Scheduled_Utilization_Credited_Hours__c,pse__Scheduled_Utilization_Excluded_Hours__c,pse__Scheduled_Utilization_Held_Hours__c,pse__Scheduled_Utilization_Non_Billable_Hrs__c,pse__Scheduled_Utilization_Target_Attainment__c,pse__Scheduled_Utilization_Target_Hours__c,pse__Scheduled_Utilization_Target__c,pse__Scheduled_Utilization__c,pse__Send_to_Third_Party_Expenses_Application__c,pse__Start_Date__c,pse__Sync_with_Jira__c,pse__Total_Costs__c,pse__Total_Time_Period_Hours__c,pse__Total_Utilization__c,pse__Utilization_Calculation_Date__c,pse__Utilization_Elapsed_Hours__c,pse__Utilization_Full_Time_Period__c,pse__Utilization_Last_Updated_By__c,pse__Utilization_Last_Update_Date__c,pse__Utilization_Target_Attainment__c,pse__Utilization_Target_Average__c,pse__Utilization_Target_Hours__c,pse__Utilization_Target__c,pse__Utilization__c,pse__Work_Calendar__c,Public_Cloud__c,Rackspace_Contact_Number__c,Rackspace__c,Reasons_to_opt_out__c,RecordTypeId,Region__c,Replaced_Contact__c,Replacement_Contact__c,ReportsToId,Resource_Location__c,RingLeadTrigger__Consider_Updates_After__c,RingLeadTrigger__Current_Endpoint__c,RingLeadTrigger__RingLead_App_Field__c,RingLeadTrigger__RingLead_Last_Processed_Date__c,RingLeadTrigger__RingLead_Processed_Count__c,RingLeadTrigger__Trigger_Type_Created__c,RingLeadTrigger__Trigger_Type_Updated__c,rkpi2__DeletedFromRainKing__c,rkpi2__rkContactId__c,rkpi2__rk_DefaultVisibility__c,rkpi2__rk_RetrievalFlag__c,RPN__c,Sales_Team_Size__c,Salutation,Solution_Summit_Sessions__c,Specialized_Technology__c,SSO_Username__c,Start_Date__c,Status__c,Suffix,Supporting_Workloads__c,Sync_to_Marketo__c,SystemModstamp,Technical_Team_Size__c,Tech_Target_Source__c,Temp_Mailing_Country__c,Temp_Mailing_State__c,Territory__c,Title,tt_itda_watch__Tech_Target_Import_Timestamp__c,Type__c,VMware__c,Worker_Type__c
                           FROM Contact WHERE Id =:contactId];
            
            contactCloneCopy  = con.clone(false, false, false, false);
            contactCloneCopy.RPN__c = null;
            contactCloneCopy.Replaced_Contact__c = con.Id; // Linking old contact to cloned contact
            insert contactCloneCopy; 
            
            con.Replacement_Contact__c = contactCloneCopy.Id; // Linking cloned contact to old contact
            update con;
            udpateACR(contactId,ProdAccId,contactCloneCopy); // Method to link new cloned contact with the existing ACR
        }catch(Exception ex){            
            ErrorLogHelper.ClogErrorRecord(ex.getMessage(),'ErrorCloneCon');
        }       
    }
    
    /********************************************************************
// Purpose              : Updated the Existing Account contact role 
// Author               : Someshwar
// Parameters           : Old Contact and Cloned Contact
//  Returns             : void
//JIRA Reference        : SFDC-8248 - Create a Duplicate contact on Closed Won Wizard
********************************************************************/ 
    
    @Testvisible
    private static void udpateACR(Id conId,Id prodacId,Contact contactCloneCopy){
        try{
            AccountContactRelation  acr = [SELECT AccountId,ContactId,Id, Roles,Ticket_Notify__c
                                           FROM AccountContactRelation  WHERE ContactId =:conId AND AccountId=:prodacId
                                           AND Roles INCLUDES ('Business')];
            
            //String accId = acr.AccountId;
            //String accRoles = acr.Roles;
            AccountContactRelation clonedAcr= new AccountContactRelation(AccountId=acr.AccountId,ContactId=contactCloneCopy.Id,
                                                                         Roles=acr.Roles,Ticket_Notify__c=acr.Ticket_Notify__c);
            acr.Roles = 'Business';
            update acr;  
            insert clonedAcr;    
            
        }catch(Exception ex){
            
            System.debug('Error cha---- :'+ex.getMessage());
            ErrorLogHelper.ClogErrorRecord(ex.getMessage(),'ErrorCloningACR');
        }
        
    }
    
}