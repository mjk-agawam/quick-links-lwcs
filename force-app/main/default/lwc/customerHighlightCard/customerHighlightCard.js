import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import getUserPhotoUrl from '@salesforce/apex/CustomerHighlightCardController.getUserPhotoUrl';

const CASE_FIELDS = [
    'Case.ContactId',
    'Case.Contact.Name',
    'Case.Contact.Email',
    'Case.Contact.Phone',
    'Case.Contact.MobilePhone',
    'Case.Contact.Title',
    'Case.Contact.AccountId',
    'Case.Contact.Account.Name'
];

const CONTACT_FIELDS = [
    'Contact.Id',
    'Contact.Name',
    'Contact.Email',
    'Contact.Phone',
    'Contact.MobilePhone',
    'Contact.Title',
    'Contact.AccountId',
    'Contact.Account.Name'
];

const WORKORDER_FIELDS = [
    'WorkOrder.ContactId',
    'WorkOrder.Contact.Name',
    'WorkOrder.Contact.Email',
    'WorkOrder.Contact.Phone',
    'WorkOrder.Contact.MobilePhone',
    'WorkOrder.Contact.Title',
    'WorkOrder.Contact.AccountId',
    'WorkOrder.Contact.Account.Name'
];

const SA_FIELDS = [
    'ServiceAppointment.ContactId',
    'ServiceAppointment.Contact.Name',
    'ServiceAppointment.Contact.Email',
    'ServiceAppointment.Contact.Phone',
    'ServiceAppointment.Contact.MobilePhone',
    'ServiceAppointment.Contact.Title',
    'ServiceAppointment.Contact.AccountId',
    'ServiceAppointment.Contact.Account.Name'
];

export default class CustomerHighlightCard extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    @api showStatusIcon;
    @api backgroundImageName = 'SDO_Service_TrailheadSunBG';

    contactId;
    contactName;
    email;
    phone;
    mobile;
    title;
    contactPhotoUrl;
    accountId;
    accountName;
    showNoContactMessage = false;

    get backgroundImage() {
        return `/resource/${this.backgroundImageName}`;
    }

    get fields() {
        switch(this.objectApiName) {
            case 'Case':
                return CASE_FIELDS;
            case 'Contact':
                return CONTACT_FIELDS;
            case 'WorkOrder':
                return WORKORDER_FIELDS;
            case 'ServiceAppointment':
                return SA_FIELDS;
            default:
                return [];
        }
    }

    get contactUrl() {
        return this.contactId ? `/${this.contactId}` : null;
    }

    get accountUrl() {
        return this.accountId ? `/${this.accountId}` : null;
    }

    get emailLink() {
        return this.email ? `/lightning/o/Contact/email?context=composer&emailTo=${this.email}` : null;
    }

    get phoneLink() {
        return this.phone ? `tel:${this.phone}` : null;
    }

    get mobileLink() {
        return this.mobile ? `tel:${this.mobile}` : null;
    }

    @wire(getRecord, { recordId: '$recordId', fields: '$fields' })
    wiredRecord({ error, data }) {
        if (data) {
            this.showNoContactMessage = false;

            if (this.objectApiName === 'Contact') {
                this.contactId = getFieldValue(data, 'Contact.Id');
                this.contactName = getFieldValue(data, 'Contact.Name');
                this.email = getFieldValue(data, 'Contact.Email');
                this.phone = getFieldValue(data, 'Contact.Phone');
                this.mobile = getFieldValue(data, 'Contact.MobilePhone');
                this.title = getFieldValue(data, 'Contact.Title');
                this.accountId = getFieldValue(data, 'Contact.AccountId');
                this.accountName = getFieldValue(data, 'Contact.Account.Name');
                this.loadPhoto(null, this.contactId);
            } else if (this.objectApiName === 'Case') {
                this.contactId = getFieldValue(data, 'Case.ContactId');
                this.contactName = getFieldValue(data, 'Case.Contact.Name');
                this.email = getFieldValue(data, 'Case.Contact.Email');
                this.phone = getFieldValue(data, 'Case.Contact.Phone');
                this.mobile = getFieldValue(data, 'Case.Contact.MobilePhone');
                this.title = getFieldValue(data, 'Case.Contact.Title');
                this.accountId = getFieldValue(data, 'Case.Contact.AccountId');
                this.accountName = getFieldValue(data, 'Case.Contact.Account.Name');
                this.loadPhoto(null, this.contactId);
            } else if (this.objectApiName === 'WorkOrder') {
                this.contactId = getFieldValue(data, 'WorkOrder.ContactId');
                this.contactName = getFieldValue(data, 'WorkOrder.Contact.Name');
                this.email = getFieldValue(data, 'WorkOrder.Contact.Email');
                this.phone = getFieldValue(data, 'WorkOrder.Contact.Phone');
                this.mobile = getFieldValue(data, 'WorkOrder.Contact.MobilePhone');
                this.title = getFieldValue(data, 'WorkOrder.Contact.Title');
                this.accountId = getFieldValue(data, 'WorkOrder.Contact.AccountId');
                this.accountName = getFieldValue(data, 'WorkOrder.Contact.Account.Name');
                this.loadPhoto(null, this.contactId);
            } else if (this.objectApiName === 'ServiceAppointment') {
                this.contactId = getFieldValue(data, 'ServiceAppointment.ContactId');

                if (!this.contactId) {
                    this.showNoContactMessage = true;
                    return;
                }

                this.contactName = getFieldValue(data, 'ServiceAppointment.Contact.Name');
                this.email = getFieldValue(data, 'ServiceAppointment.Contact.Email');
                this.phone = getFieldValue(data, 'ServiceAppointment.Contact.Phone');
                this.mobile = getFieldValue(data, 'ServiceAppointment.Contact.MobilePhone');
                this.title = getFieldValue(data, 'ServiceAppointment.Contact.Title');
                this.accountId = getFieldValue(data, 'ServiceAppointment.Contact.AccountId');
                this.accountName = getFieldValue(data, 'ServiceAppointment.Contact.Account.Name');
                this.loadPhoto(null, this.contactId);
            }
        } else if (error) {
            console.error('Error loading record:', error);
        }
    }

    async loadPhoto(contactPhotoUrl, contactId) {
        if (contactPhotoUrl) {
            this.contactPhotoUrl = contactPhotoUrl;
        } else if (contactId) {
            try {
                const userPhotoUrl = await getUserPhotoUrl({ contactId: contactId });
                this.contactPhotoUrl = userPhotoUrl || this.getDefaultAvatar();
            } catch (error) {
                console.error('Error loading user photo:', error);
                this.contactPhotoUrl = this.getDefaultAvatar();
            }
        } else {
            this.contactPhotoUrl = this.getDefaultAvatar();
        }
    }

    getDefaultAvatar() {
        return '/assets/images/profile_avatar_200.png';
    }
}