import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCounts from '@salesforce/apex/WorkOrderRelatedLinksController.getCounts';

const RELATED_LISTS = [
    { label: 'Work Order Line Items',  key: 'workOrderLineItemCount',  rel: 'WorkOrderLineItems' },
    { label: 'Products Required',      key: 'productRequiredCount',    rel: 'ProductsRequired' },
    { label: 'Products Consumed',      key: 'productConsumedCount',    rel: 'ProductsConsumed' },
    { label: 'Work Plans',             key: 'workPlanCount',           rel: 'WorkPlans' },
    { label: 'Work Steps',             key: 'workStepCount',           rel: null },
    { label: 'Skill Requirements',     key: 'skillRequirementCount',   rel: 'SkillRequirements' },
    { label: 'Open Activities',        key: 'openActivityCount',       rel: 'OpenActivities' },
    { label: 'Activity History',       key: 'activityHistoryCount',    rel: 'ActivityHistories' },
    { label: 'Tasks',                  key: 'taskCount',               rel: 'Tasks' },
    { label: 'Emails',                 key: 'emailCount',              rel: 'Emails' },
    { label: 'Files',                  key: 'fileCount',               rel: 'CombinedAttachments' },
    { label: 'Attachments',            key: 'attachmentCount',         rel: 'Attachments' },
    { label: 'Notes',                  key: 'noteCount',               rel: 'Notes' },
];

export default class SaQuickLink extends NavigationMixin(LightningElement) {
    @api recordId;

    isLoading = true;
    rows = [];
    _data = null;

    @wire(getCounts, { workOrderId: '$recordId' })
    wiredCounts({ error, data }) {
        if (data) {
            this._data = data;
            this._buildRows();
            this.isLoading = false;
        } else if (error) {
            this.isLoading = false;
        }
    }

    _buildRows() {
        const d = this._data;
        const built = [];

        built.push({
            label: 'Service Appointments',
            count: d.serviceAppointmentCount,
            handler: () => {
                if (d.serviceAppointmentCount === 1 && d.serviceAppointmentId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: { recordId: d.serviceAppointmentId, actionName: 'view' }
                    });
                } else {
                    this._goToRelatedList('ServiceAppointments');
                }
            }
        });

        built.push({
            label: 'Assets',
            count: d.assetCount,
            handler: () => {
                if (d.assetId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: { recordId: d.assetId, actionName: 'view' }
                    });
                }
            }
        });

        for (const item of RELATED_LISTS) {
            const rel = item.rel;
            built.push({
                label: item.label,
                count: d[item.key] || 0,
                handler: rel ? () => this._goToRelatedList(rel) : () => {}
            });
        }

        this.rows = built;
    }

    _goToRelatedList(relationshipApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'WorkOrder',
                relationshipApiName,
                actionName: 'view'
            }
        });
    }
}
