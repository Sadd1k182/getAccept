import { LightningElement, api } from 'lwc';

export default class Modal extends LightningElement {
    @api showModal = false;

    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}