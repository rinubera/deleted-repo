public class ComplaintProcessorHelper {

    // Analyzes incoming feedback, creates complaint logs, and flags high-risk cases
    public static void processComplaints(List<Case> newCases) {
        List<Complaint_Log__c> logsToInsert = new List<Complaint_Log__c>();
        
        // Fetch Tier 2 Queue ID for fallback routing
        Group tier2Queue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Tier_2_Escalations' LIMIT 1];

        for (Case c : newCases) {
            if (String.isNotBlank(c.Description)) {
                // Simple keyword-based sentiment mock logic (can be replaced with an Einstein AI callout)
                Decimal sentiment = calculateMockSentiment(c.Description);
                String rootCause = determineRootCause(c.Description);

                // Create Complaint Log record linked to the Case
                logsToInsert.add(new Complaint_Log__c(
                    Case__c = c.Id,
                    Sentiment_Score__c = sentiment,
                    Root_Cause_Category__c = rootCause
                ));

                // Auto-escalate severe complaints (Sentiment < -3.0)
                if (sentiment < -3.0 && tier2Queue != null) {
                    c.OwnerId = tier2Queue.Id;
                    c.Priority = 'High';
                }
            }
        }

        if (!logsToInsert.isEmpty()) {
            insert logsToInsert;
        }
    }

    private static Decimal calculateMockSentiment(String description) {
        String lowerDesc = description.toLowerCase();
        if (lowerDesc.contains('terrible') || lowerDesc.contains('awful') || lowerDesc.contains('unusable')) {
            return -4.5;
        } else if (lowerDesc.contains('disappointed') || lowerDesc.contains('bad') || lowerDesc.contains('issue')) {
            return -2.0;
        }
        return 0.5; // Neutral or positive
    }

    private static String determineRootCause(String description) {
        String lowerDesc = description.toLowerCase();
        if (lowerDesc.contains('bill') || lowerDesc.contains('charge') || lowerDesc.contains('invoice')) {
            return 'Billing';
        } else if (lowerDesc.contains('error') || lowerDesc.contains('bug') || lowerDesc.contains('crash')) {
            return 'Technical';
        } else if (lowerDesc.contains('broken') || lowerDesc.contains('defect')) {
            return 'Product Defect';
        }
        return 'Customer Service';
    }
}