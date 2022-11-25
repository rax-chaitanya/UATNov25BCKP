public class CompanyUpdateOfMarketingSegment {
    public static void populateMarketingSegmentInfo(List<Account> newAccList, Boolean checkChild){
        Set<Id> accParentIds = new Set<Id>();
        Set<ID> accChildIds = new Set<ID>();
        List<Account> parentLst = new List<Account>();
        Map<id,Account> standardUpdateMap = new Map<id,Account>();
        Map<id,Account> parentChangeInsertMap = new Map<id,Account>();
        Id prospectTypeId =label.Account_Prospect_RecordType_ID;
        Id customerTypeID = label.AccountCustomerRecordTypeId;
        for(Account acc : newAccList){
            if(!checkChild){
                accParentIds.add(acc.id);
                standardUpdateMap.put(acc.id,acc);   
            }
            if(checkChild){
                accChildIds.add(acc.Company_Name__c);
            }
        }
        if(checkChild && !(accChildIds.isEmpty())){
            parentLst = [SELECT id,name,Marketing_Segment_Group__c,Marketing_S3_Priority__c FROM Account where id =:accChildIds ];
            for(Account eachParent : parentLst){
                parentChangeInsertMap.put(eachParent.id,eachParent);
            }
        }
        
        if(!checkChild && (!accParentIds.isEmpty())){
            List<Account> accProsCustlist = [SELECT id,name,Marketing_Segment_Group__c ,Marketing_S3_Priority__c,Company_Name__c FROM Account WHERE Company_Name__c IN :accParentIds AND (RecordTypeId =: prospectTypeId OR RecordTypeId =:customerTypeID)];
            For(Account eachAcc : accProsCustlist){
                eachAcc.Marketing_Segment_Group__c = standardUpdateMap.get(eachAcc.Company_Name__c).Marketing_Segment_Group__c;
                eachAcc.Marketing_S3_Priority__c = standardUpdateMap.get(eachAcc.Company_Name__c).Marketing_S3_Priority__c;
            }
            if(!accProsCustlist.isEmpty()){
                Update accProsCustlist;
            }
        }
        if(checkChild && (!parentChangeInsertMap.isEmpty())){
            for(Account eachChildAcc : newAccList){
                if(eachChildAcc.RecordTypeId == prospectTypeId || eachChildAcc.RecordTypeId == customerTypeID){
                    eachChildAcc.Marketing_Segment_Group__c = parentChangeInsertMap.get(eachChildAcc.Company_Name__c).Marketing_Segment_Group__c;
                    eachChildAcc.Marketing_S3_Priority__c = parentChangeInsertMap.get(eachChildAcc.Company_Name__c).Marketing_S3_Priority__c;
                }
            }
        }
        
    }
}