public with sharing class WorkOrderRelatedLinksController {

    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getCounts(Id workOrderId) {
        Map<String, Object> result = new Map<String, Object>();

        WorkOrder wo = [SELECT AssetId FROM WorkOrder WHERE Id = :workOrderId LIMIT 1];
        result.put('assetId', wo.AssetId != null ? (String)wo.AssetId : null);
        result.put('assetCount', wo.AssetId != null ? 1 : 0);

        List<ServiceAppointment> sas = [SELECT Id FROM ServiceAppointment WHERE ParentRecordId = :workOrderId];
        result.put('serviceAppointmentCount', sas.size());
        result.put('serviceAppointmentId', sas.size() == 1 ? (String)sas[0].Id : null);

        result.put('workOrderLineItemCount', [SELECT COUNT() FROM WorkOrderLineItem WHERE WorkOrderId = :workOrderId]);

        result.put('productRequiredCount', [SELECT COUNT() FROM ProductRequired WHERE ParentRecordId = :workOrderId]);
        result.put('productConsumedCount', [SELECT COUNT() FROM ProductConsumed WHERE WorkOrderId = :workOrderId]);

        result.put('workPlanCount', [SELECT COUNT() FROM WorkPlan WHERE WorkOrderId = :workOrderId]);

        List<Id> wpIds = new List<Id>();
        for (WorkPlan wp : [SELECT Id FROM WorkPlan WHERE WorkOrderId = :workOrderId]) {
            wpIds.add(wp.Id);
        }
        result.put('workStepCount', wpIds.isEmpty() ? 0 : [SELECT COUNT() FROM WorkStep WHERE WorkPlanId IN :wpIds]);

        try {
            result.put('skillRequirementCount', [SELECT COUNT() FROM SkillRequirement WHERE RelatedRecordId = :workOrderId]);
        } catch (Exception e) {
            result.put('skillRequirementCount', 0);
        }

        result.put('openActivityCount',    [SELECT COUNT() FROM Task WHERE WhatId = :workOrderId AND IsClosed = false]);
        result.put('activityHistoryCount', [SELECT COUNT() FROM Task WHERE WhatId = :workOrderId AND IsClosed = true]);
        result.put('taskCount',            [SELECT COUNT() FROM Task WHERE WhatId = :workOrderId]);

        try {
            result.put('emailCount', [SELECT COUNT() FROM EmailMessage WHERE RelatedToId = :workOrderId]);
        } catch (Exception e) {
            result.put('emailCount', 0);
        }

        result.put('fileCount',       [SELECT COUNT() FROM ContentDocumentLink WHERE LinkedEntityId = :workOrderId]);
        result.put('attachmentCount', [SELECT COUNT() FROM Attachment WHERE ParentId = :workOrderId]);
        result.put('noteCount',       [SELECT COUNT() FROM Note WHERE ParentId = :workOrderId]);

        return result;
    }
}
