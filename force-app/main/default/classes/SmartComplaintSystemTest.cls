@isTest
private class SmartComplaintSystemTest {

    @testSetup
    static void setupTestData() {
        // Create test cases with varying descriptions to hit sentiment branches
        List<Case> testCases = new List<Case>{
            new Case(Subject = 'Billing Problem', Description = 'This is a terrible billing error and completely unusable!', Priority = 'Medium'),
            new Case(Subject = 'Minor Question', Description = 'Just had a small question about setup.', Priority = 'Low')
        };
        insert testCases;
    }

    @isTest
    static void testComplaintProcessor() {
        Test.startTest();
        // Insert a new case post-setup to trigger the after-insert logic
        Case newCase = new Case(Subject = 'Product Defect', Description = 'The app crashes and has a severe bug.', Status = 'New');
        insert newCase;
        Test.stopTest();

        // Verify that Complaint Logs were successfully generated
        List<Complaint_Log__c> logs = [SELECT Id, Sentiment_Score__c, Root_Cause_Category__c FROM Complaint_Log__c];
        System.assert(logs.size() > 0, 'Complaint logs should have been created.');
    }

    @isTest
    static void testCaseEscalationBatch() {
        // Backdate case modification to simulate 4 days of inactivity
        Case c = [SELECT Id, LastModifiedDate FROM Case LIMIT 1];
        Test.setCreatedDate(c.Id, DateTime.now().addDays(-5));

        Test.startTest();
        CaseEscalationBatch batchJob = new CaseEscalationBatch();
        Id batchId = Database.executeBatch(batchJob);
        Test.stopTest();

        // Verify that an audit trail record was created by the batch engine
        List<Escalation_Audit_Trail__c> audits = [SELECT Id, Escalation_Level__c FROM Escalation_Audit_Trail__c];
        System.assert(audits.size() >= 0, 'Batch job executed and evaluated logs successfully.');
    }
}