public with sharing class SARelatedLinksController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCounts(Id saId) {
        Map<String, Object> result = new Map<String, Object>();

        ServiceAppointment sa = [
            SELECT AccountId, ContactId, Asset__c, ParentRecordId, ParentRecordType
            FROM ServiceAppointment
            WHERE Id = :saId
            LIMIT 1
        ];

        result.put('accountId', sa.AccountId != null ? (String)sa.AccountId : null);
        result.put('contactId', sa.ContactId != null ? (String)sa.ContactId : null);
        result.put('assetId',   sa.Asset__c  != null ? (String)sa.Asset__c  : null);

        // Only link to WorkOrder if parent is actually a WO
        String parentType = sa.ParentRecordType;
        Boolean parentIsWO = parentType != null && parentType.equalsIgnoreCase('WorkOrder');
        result.put('workOrderId', parentIsWO ? (String)sa.ParentRecordId : null);

        result.put('assignedResourceCount', [SELECT COUNT() FROM AssignedResource WHERE ServiceAppointmentId = :saId]);

        try {
            result.put('skillRequirementCount', [SELECT COUNT() FROM SkillRequirement WHERE RelatedRecordId = :saId]);
        } catch (Exception e) {
            result.put('skillRequirementCount', 0);
        }

        try {
            result.put('preferredResourceCount', [SELECT COUNT() FROM ResourcePreference WHERE RelatedRecordId = :saId AND PreferenceType = 'Preferred']);
        } catch (Exception e) {
            result.put('preferredResourceCount', 0);
        }

        result.put('serviceReportCount', [SELECT COUNT() FROM ServiceReport WHERE ParentId = :saId]);

        result.put('openActivityCount',    [SELECT COUNT() FROM Task WHERE WhatId = :saId AND IsClosed = false]);
        result.put('activityHistoryCount', [SELECT COUNT() FROM Task WHERE WhatId = :saId AND IsClosed = true]);
        result.put('taskCount',            [SELECT COUNT() FROM Task WHERE WhatId = :saId]);

        try {
            result.put('emailCount', [SELECT COUNT() FROM EmailMessage WHERE RelatedToId = :saId]);
        } catch (Exception e) {
            result.put('emailCount', 0);
        }

        result.put('fileCount',       [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :saId]);
        result.put('attachmentCount', [SELECT COUNT() FROM Attachment WHERE ParentId = :saId]);
        result.put('noteCount',       [SELECT COUNT() FROM Note WHERE ParentId = :saId]);

        return result;
    }
}
