@isTest
public class DeleteRecordsBatch_Test
{
           
    static testMethod void testMethod1()
    {
        
        Test.startTest();
        DeleteRecordsBatch cb = New DeleteRecordsBatch();
        
        Database.QueryLocator ql = cb.start(null);
        cb.execute(null,null);
        cb.Finish(null);
        
        //DeleteRecordsBatch drb = new DeleteRecordsBatch();
        DataBase.executeBatch(cb,10);
        
        Test.stopTest();
        
    } 
    
}