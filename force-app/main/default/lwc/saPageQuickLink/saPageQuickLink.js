import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCounts from '@salesforce/apex/SARelatedLinksController.getCounts';

const RELATED_LISTS = [
    { label: 'Assigned Resources',    key: 'assignedResourceCount',   rel: 'AssignedResources' },
    { label: 'Skill Requirements',    key: 'skillRequirementCount',   rel: 'SkillRequirements' },
    { label: 'Preferred Resources',   key: 'preferredResourceCount',  rel: 'ResourcePreferences' },
    { label: 'Service Reports',       key: 'serviceReportCount',      rel: 'ServiceReports' },
    { label: 'Open Activities',       key: 'openActivityCount',       rel: 'OpenActivities' },
    { label: 'Activity History',      key: 'activityHistoryCount',    rel: 'ActivityHistories' },
    { label: 'Tasks',                 key: 'taskCount',               rel: 'Tasks' },
    { label: 'Emails',                key: 'emailCount',              rel: 'Emails' },
    { label: 'Files',                 key: 'fileCount',               rel: 'CombinedAttachments' },
    { label: 'Attachments',           key: 'attachmentCount',         rel: 'Attachments' },
    { label: 'Notes',                 key: 'noteCount',               rel: 'Notes' },
];

export default class SaPageQuickLink extends NavigationMixin(LightningElement) {
    @api recordId;
    @api columns = '1';

    isLoading = true;
    rows = [];
    _data = null;

    get gridClass() {
        return Number(this.columns) === 2 ? 'quick-link-grid two-col' : 'quick-link-grid';
    }

    @wire(getCounts, { saId: '$recordId' })
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

        // Direct navigation links
        if (d.workOrderId) {
            built.push({
                label: 'Work Order',
                count: 1,
                handler: () => this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId: d.workOrderId, actionName: 'view' }
                })
            });
        }

        if (d.accountId) {
            built.push({
                label: 'Account',
                count: 1,
                handler: () => this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId: d.accountId, actionName: 'view' }
                })
            });
        }

        if (d.contactId) {
            built.push({
                label: 'Contact',
                count: 1,
                handler: () => this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId: d.contactId, actionName: 'view' }
                })
            });
        }

        if (d.assetId) {
            built.push({
                label: 'Asset',
                count: 1,
                handler: () => this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: { recordId: d.assetId, actionName: 'view' }
                })
            });
        }

        // Related list links
        for (const item of RELATED_LISTS) {
            built.push({
                label: item.label,
                count: d[item.key] || 0,
                handler: () => this._goToRelatedList(item.rel)
            });
        }

        this.rows = built;
    }

    _goToRelatedList(relationshipApiName) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.recordId,
                objectApiName: 'ServiceAppointment',
                relationshipApiName,
                actionName: 'view'
            }
        });
    }
}
