global class CaseEscalationBatch implements Database.Batchable<sObject>, Database.Stateful {

    global Database.QueryLocator start(Database.BatchableContext bc) {
        // Query cases that are open and haven't been modified in over 3 days
        return Database.getQueryLocator(
            'SELECT Id, OwnerId, Status, LastModifiedDate, Subject FROM Case WHERE Status != \'Closed\' AND LastModifiedDate < LAST_N_DAYS:3'
        );
    }

    global void execute(Database.BatchableContext bc, List<Case> scope) {
        List<Escalation_Audit_Trail__c> auditTrails = new List<Escalation_Audit_Trail__c>();
        Group tier2Queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Tier_2_Escalations' LIMIT 1];

        for (Case c : scope) {
            String oldOwner = c.OwnerId;
            
            // Reassign to Tier 2 queue if not already owned by it
            if (tier2Queue != null && c.OwnerId != tier2Queue.Id) {
                c.OwnerId = tier2Queue.Id;
                
                auditTrails.add(new Escalation_Audit_Trail__c(
                    Case__c = c.Id,
                    Previous_Owner__c = oldOwner,
                    New_Owner__c = tier2Queue.Id,
                    Escalation_Level__c = 'Level 2',
                    Trigger_Reason__c = 'Automatic batch escalation due to inactivity (>3 days)'
                ));
            }
        }

        if (!auditTrails.isEmpty()) {
            insert auditTrails;
            update scope;
        }
    }

    global void finish(Database.BatchableContext bc) {
        System.debug('CaseEscalationBatch processed successfully.');
    }
}