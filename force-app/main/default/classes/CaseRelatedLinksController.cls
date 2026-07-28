public with sharing class CaseRelatedLinksController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCounts(Id caseId) {
        Map<String, Object> result = new Map<String, Object>();

        Case c = [SELECT AccountId, ContactId, AssetId FROM Case WHERE Id = :caseId LIMIT 1];
        result.put('accountId', c.AccountId != null ? (String)c.AccountId : null);
        result.put('accountCount', c.AccountId != null ? 1 : 0);
        result.put('contactId', c.ContactId != null ? (String)c.ContactId : null);
        result.put('contactCount', c.ContactId != null ? 1 : 0);
        result.put('assetId', c.AssetId != null ? (String)c.AssetId : null);
        result.put('assetCount', c.AssetId != null ? 1 : 0);

        result.put('workOrderCount', [SELECT COUNT() FROM WorkOrder WHERE CaseId = :caseId]);

        result.put('caseCommentCount', [SELECT COUNT() FROM CaseComment WHERE ParentId = :caseId]);

        try {
            result.put('emailCount', [SELECT COUNT() FROM EmailMessage WHERE RelatedToId = :caseId]);
        } catch (Exception e) {
            result.put('emailCount', 0);
        }

        result.put('openActivityCount',    [SELECT COUNT() FROM Task WHERE WhatId = :caseId AND IsClosed = false]);
        result.put('activityHistoryCount', [SELECT COUNT() FROM Task WHERE WhatId = :caseId AND IsClosed = true]);
        result.put('taskCount',            [SELECT COUNT() FROM Task WHERE WhatId = :caseId]);

        result.put('fileCount',       [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :caseId]);
        result.put('attachmentCount', [SELECT COUNT() FROM Attachment WHERE ParentId = :caseId]);
        result.put('noteCount',       [SELECT COUNT() FROM Note WHERE ParentId = :caseId]);

        try {
            result.put('knowledgeCount', [SELECT COUNT() FROM CaseArticle WHERE CaseId = :caseId]);
        } catch (Exception e) {
            result.put('knowledgeCount', 0);
        }

        return result;
    }
}
