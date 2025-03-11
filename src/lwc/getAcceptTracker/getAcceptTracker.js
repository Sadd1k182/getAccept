import {LightningElement, api} from 'lwc';
import getDocuments from '@salesforce/apex/GetAcceptController.getDocuments';
import getDocumentEvents from '@salesforce/apex/GetAcceptController.getDocumentEvents';
import sendReminder from '@salesforce/apex/GetAcceptController.sendReminder';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {
    TOAST_VARIANTS,
    ERROR_MESSAGES,
    SUCCESS_MESSAGES,
    DATATABLE_COLUMNS,
    ACTION_NAMES,
    BUTTON_LABELS,
    UI_TEXT
} from 'c/utils';

export default class GetAcceptTracker extends LightningElement {
    @api recordId;
    documents;
    selectedDocumentEvents;
    selectedDocumentId;
    error;
    isModalOpen = false;
    isSendingReminder = false;
    isLoadingDocuments = false;
    isLoadingEvents = false;

    labels = {
        toastSuccess: TOAST_VARIANTS.SUCCESS,
        toastError: TOAST_VARIANTS.ERROR,
        sendReminderButton: BUTTON_LABELS.SEND_REMINDER,
        noDocumentsFound: UI_TEXT.NO_DOCUMENTS_FOUND,
        eventTimelineTitle: UI_TEXT.EVENT_TIMELINE_TITLE,
        closeButton: BUTTON_LABELS.CLOSE,
        loadDocumentsError: ERROR_MESSAGES.LOAD_DOCUMENTS,
        loadEventsError: ERROR_MESSAGES.LOAD_EVENTS,
        sendReminderError: ERROR_MESSAGES.SEND_REMINDER,
        noDocumentSelectedError: ERROR_MESSAGES.NO_DOCUMENT_SELECTED,
        reminderSentSuccess: SUCCESS_MESSAGES.REMINDER_SENT,
    };

    columns = DATATABLE_COLUMNS;
    actionNames = ACTION_NAMES;

    get formattedEvents() {
        if (!this.selectedDocumentEvents) {
            return null;
        }
        return this.selectedDocumentEvents.map(event => ({
            ...event,
            formattedCreatedAt: this.formatDateTime(event.createdAt)
        }));
    }

    get isReminderDisabled() {
        return !this.selectedDocumentId || this.isSendingReminder;
    }

    get dynamicEventTimelineTitle() {
        return this.labels.eventTimelineTitle.replace('{0}', this.selectedDocumentId);
    }

    async connectedCallback() {
        await this.fetchDocuments();
    }

    async fetchDocuments() {
        this.isLoadingDocuments = true;
        this.error = null;
        try {
            this.documents = await getDocuments({opportunityId: this.recordId});
        } catch (error) {
            this.handleError(error, this.labels.loadDocumentsError);
            this.documents = null;
        } finally {
            this.isLoadingDocuments = false;
        }
    }

    async fetchDocumentEvents(documentId) {
        this.isLoadingEvents = true;
        this.error = null;
        try {
            this.selectedDocumentEvents = await getDocumentEvents({documentId});
        } catch (error) {
            this.handleError(error, this.labels.loadEventsError);
            this.selectedDocumentEvents = null;
        } finally {
            this.isLoadingEvents = false;
        }
    }

    async handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === this.actionNames.VIEW_EVENTS) {
            this.selectedDocumentId = row.Document_ID__c;
            await this.fetchDocumentEvents(this.selectedDocumentId);
            if (!this.error) {
                this.isModalOpen = true;
            }
        }
    }

    async handleSendReminder() {
        if (this.isReminderDisabled) {
            this.showToast('Error', this.labels.noDocumentSelectedError, this.labels.toastError);
            return;
        }

        this.isSendingReminder = true;
        this.error = null;
        try {
            await sendReminder({documentId: this.selectedDocumentId});
            this.showToast('Success', this.labels.reminderSentSuccess, this.labels.toastSuccess);
            await this.fetchDocuments();
            this.closeModal();
        } catch (error) {
            this.handleError(error, this.labels.sendReminderError);
        } finally {
            this.isSendingReminder = false;
        }
    }

    closeModal() {
        this.isModalOpen = false;
        this.isSendingReminder = false;
    }

    handleError(error, defaultMessage) {
        let message = defaultMessage;
        if (error.body && error.body.message) {
            message = error.body.message;
        }
        this.error = message;
        this.showToast('Error', message, this.labels.toastError);
        console.error('Error:', error);
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({title, message, variant}));
    }

    formatDateTime(dateTimeString) {
        if (!dateTimeString) {
            return '';
        }
        const date = new Date(dateTimeString);
        return new Intl.DateTimeFormat('en-US', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: 'numeric',
            second: 'numeric',
        }).format(date);
    }
}