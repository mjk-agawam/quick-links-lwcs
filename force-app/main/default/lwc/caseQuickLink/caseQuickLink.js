import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import getCounts from '@salesforce/apex/CaseRelatedLinksController.getCounts';

const RELATED_LISTS = [
    { label: 'Case Comments',      key: 'caseCommentCount',    rel: 'CaseComments' },
    { label: 'Emails',             key: 'emailCount',          rel: 'EmailMessages' },
    { label: 'Open Activities',    key: 'openActivityCount',   rel: 'OpenActivities' },
    { label: 'Activity History',   key: 'activityHistoryCount', rel: 'ActivityHistories' },
    { label: 'Tasks',              key: 'taskCount',           rel: 'Tasks' },
    { label: 'Files',              key: 'fileCount',           rel: 'CombinedAttachments' },
    { label: 'Attachments',        key: 'attachmentCount',     rel: 'Attachments' },
    { label: 'Notes',              key: 'noteCount',           rel: 'Notes' },
];

export default class CaseQuickLink extends NavigationMixin(LightningElement) {
    @api recordId;

    isLoading = true;
    rows = [];
    _data = null;

    @wire(getCounts, { caseId: '$recordId' })
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
            label: 'Account',
            count: d.accountCount,
            handler: () => {
                if (d.accountId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: { recordId: d.accountId, actionName: 'view' }
                    });
                }
            }
        });

        built.push({
            label: 'Contact',
            count: d.contactCount,
            handler: () => {
                if (d.contactId) {
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: { recordId: d.contactId, actionName: 'view' }
                    });
                }
            }
        });

        built.push({
            label: 'Asset',
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

        built.push({
            label: 'Work Orders',
            count: d.workOrderCount,
            handler: () => this._goToRelatedList('WorkOrders')
        });

        built.push({
            label: 'Knowledge Articles',
            count: d.knowledgeCount || 0,
            handler: () => this._goToRelatedList('CaseArticles')
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
                objectApiName: 'Case',
                relationshipApiName,
                actionName: 'view'
            }
        });
    }
}
