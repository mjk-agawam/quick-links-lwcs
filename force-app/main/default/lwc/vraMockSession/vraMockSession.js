import { LightningElement, api, wire } from 'lwc';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';

import WO_NUMBER from '@salesforce/schema/WorkOrder.WorkOrderNumber';
import WO_SUBJECT from '@salesforce/schema/WorkOrder.Subject';

const FIELDS = [WO_NUMBER, WO_SUBJECT];
const CONNECT_DELAY_MS = 2600;

// Mock expert the technician is "connected" to. Purely presentational — no real VRA session.
const EXPERT = {
    name: 'Dana Whitfield',
    title: 'Senior Equipment Specialist',
    initials: 'DW'
};

export default class VraMockSession extends LightningElement {
    @api recordId;

    phase = 'connecting';
    muted = false;
    cameraOff = false;
    expert = EXPERT;
    _timer;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    workOrder;

    get workOrderNumber() {
        return getFieldValue(this.workOrder.data, WO_NUMBER);
    }

    get workOrderSubject() {
        return getFieldValue(this.workOrder.data, WO_SUBJECT);
    }

    get isConnecting() {
        return this.phase === 'connecting';
    }

    get isConnected() {
        return this.phase === 'connected';
    }

    get muteLabel() {
        return this.muted ? 'Unmute' : 'Mute';
    }

    get muteIcon() {
        return this.muted ? 'utility:muted' : 'utility:unmuted';
    }

    get cameraLabel() {
        return this.cameraOff ? 'Camera On' : 'Camera Off';
    }

    get cameraIcon() {
        return this.cameraOff ? 'utility:turn_off_camera' : 'utility:video';
    }

    connectedCallback() {
        this._timer = setTimeout(() => {
            this.phase = 'connected';
        }, CONNECT_DELAY_MS);
    }

    disconnectedCallback() {
        if (this._timer) {
            clearTimeout(this._timer);
            this._timer = undefined;
        }
    }

    toggleMute() {
        this.muted = !this.muted;
    }

    toggleCamera() {
        this.cameraOff = !this.cameraOff;
    }

    handleEnd() {
        history.back();
    }
}