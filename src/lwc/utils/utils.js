export const TOAST_VARIANTS = {
    SUCCESS: 'success',
    ERROR: 'error'
};

export const ERROR_MESSAGES = {
    LOAD_DOCUMENTS: 'Failed to load documents',
    LOAD_EVENTS: 'Failed to load events',
    SEND_REMINDER: 'Failed to send reminder',
    NO_DOCUMENT_SELECTED: 'Please select a document to send a reminder.',
    CREATE_CONTRACT: 'An unexpected error occurred while creating the contract',
    AUTH_ERROR: 'Authentication failed. Please try again.'
};

export const SUCCESS_MESSAGES = {
    REMINDER_SENT: 'Reminder sent successfully',
    CONTRACT_CREATED: 'Contract created and sent successfully. ID: '
};

export const DATATABLE_COLUMNS = [
    { label: 'Document ID', fieldName: 'Document_ID__c' },
    { label: 'Status', fieldName: 'Status__c' },
    { label: 'Recipient Email', fieldName: 'Recipient_Email__c' },
    { type: 'button', typeAttributes: { label: 'View Events', name: 'view_events' } }
];

export const ACTION_NAMES = {
    VIEW_EVENTS: 'view_events'
};

export const BUTTON_LABELS = {
    SEND_REMINDER: 'Send Reminder',
    CREATE_CONTRACT: 'Create and Send Contract',
    CLOSE: 'Close',
};

export const UI_TEXT = {
    NO_DOCUMENTS_FOUND: 'No documents found for this Opportunity.',
    EVENT_TIMELINE_TITLE: 'Event Timeline for {0}'
};