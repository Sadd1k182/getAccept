// GetAcceptConstants.cls
public with sharing class GetAcceptConstants {
    public static final GetAcceptSettings__c settings = GetAcceptSettings__c.getOrgDefaults();
    public static final String BASE_URL = 'callout:GetAccept';
    public static final String AUTH_ENDPOINT = BASE_URL + '/v1/auth';
    public static final String DOCUMENTS_ENDPOINT = BASE_URL + '/v1/documents';
    public static final String USERS_ENDPOINT = BASE_URL + '/v1/users/me';
    public static final String DOCUMENTS_BY_COMPANY_ENDPOINT = BASE_URL + '/v1/documents?company_name=';
    public static final String UPLOAD_ENDPOINT = BASE_URL + '/v1/upload';
    public static final String REMINDERS_ENDPOINT_SUFFIX = '/reminders';
    public static final String EVENTS_ENDPOINT_SUFFIX = '/events';

    // HTTP Methods
    public static final String HTTP_GET = 'GET';
    public static final String HTTP_POST = 'POST';

    // Headers
    public static final String CONTENT_TYPE = 'Content-Type';
    public static final String APPLICATION_JSON = 'application/json';
    public static final String AUTHORIZATION = 'Authorization';
    public static final String BEARER_PREFIX = 'Bearer ';

    // JSON Keys
    public static final String ID_KEY = 'id';
    public static final String STATUS_KEY = 'status';
    public static final String SIGN_DATE_KEY = 'sign_date';
    public static final String CREATED_AT_KEY = 'created_at';
    public static final String RECIPIENTS_KEY = 'recipients';
    public static final String EMAIL_KEY = 'email';
    public static final String EVENT_NAME_KEY = 'event_name';
    public static final String FILE_ID_KEY = 'file_id';
    public static final String FILE_NAME_KEY = 'file_name';
    public static final String FILE_CONTENT_KEY = 'file_content';

    // Error Messages
    public static final String AUTH_FAILED_ERROR = 'Authentication failed: ';
    public static final String UPLOAD_FILE_FAILED_ERROR = 'Failed to upload file to GetAccept.';
    public static final String CONTRACT_CREATION_FAILED_ERROR = 'Contract creation failed: Status ';
    public static final String OPPORTUNITY_NOT_FOUND_ERROR = 'Opportunity not found.';
    public static final String PRIMARY_CONTACT_NOT_FOUND_ERROR = 'Primary contact not found for the opportunity.';
    public static final String NO_SUITABLE_DOCUMENT_FOUND_ERROR = 'No suitable document found attached to the Opportunity.';
    public static final String FETCH_DOCUMENTS_FAILED_ERROR = 'Failed to fetch documents: Status ';
    public static final String FETCH_EVENTS_FAILED_ERROR = 'Failed to fetch events: Status ';
    public static final String SEND_REMINDER_FAILED_ERROR = 'Failed to send reminder: Status ';
}