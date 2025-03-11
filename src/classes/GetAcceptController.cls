public with sharing class GetAcceptController {

    @AuraEnabled(Cacheable=false)
    public static List<GetAccept_Document__c> getDocuments(String opportunityId) {
        String token = GetAcceptAuthService.getAccessToken();

        Map<String, GetAccept_Document__c> existingDocsById = new Map<String, GetAccept_Document__c>();

        for (GetAccept_Document__c doc : [
                SELECT Id, Document_ID__c, Status__c, Last_Event__c, Recipient_Email__c
                FROM GetAccept_Document__c
                WHERE Opportunity__c = :opportunityId
        ]) {
            existingDocsById.put(doc.Document_ID__c, doc);
        }

        HttpRequest request = buildHttpRequest(GetAcceptConstants.DOCUMENTS_ENDPOINT, GetAcceptConstants.HTTP_GET, token);
        HttpResponse response = new Http().send(request);

        List<GetAccept_Document__c> resultDocs = new List<GetAccept_Document__c>();

        if (response.getStatusCode() == 200) {
            List<Object> documents = (List<Object>) JSON.deserializeUntyped(response.getBody());

            if (documents == null || documents.isEmpty()) return resultDocs;

            for (Object d : documents) {
                Map<String, Object> docMap = (Map<String, Object>) d;
                String docId = (String) docMap.get(GetAcceptConstants.ID_KEY);

                GetAccept_Document__c doc = existingDocsById.get(docId) != null
                        ? existingDocsById.get(docId)
                        : new GetAccept_Document__c(Document_ID__c = docId, Opportunity__c = opportunityId);

                doc.Status__c = (String) docMap.get(GetAcceptConstants.STATUS_KEY);
                doc.Last_Event__c = parseDateTime(docMap, GetAcceptConstants.SIGN_DATE_KEY, GetAcceptConstants.CREATED_AT_KEY);

                List<Object> recipients = (List<Object>) docMap.get(GetAcceptConstants.RECIPIENTS_KEY);

                if (recipients != null && !recipients.isEmpty()) {
                    Map<String, Object> recipient = (Map<String, Object>) recipients[0];
                    doc.Recipient_Email__c = (String) recipient.get(GetAcceptConstants.EMAIL_KEY);
                }

                resultDocs.add(doc);
            }

            if (!resultDocs.isEmpty()) {
                upsert resultDocs Document_ID__c;
            }
        } else {
            throw new AuraHandledException(GetAcceptConstants.FETCH_DOCUMENTS_FAILED_ERROR + response.getStatusCode() + ' - ' + response.getBody());
        }

        return resultDocs;
    }

    @AuraEnabled(Cacheable=false)
    public static List<Map<String, String>> getDocumentEvents(String documentId) {
        String token = GetAcceptAuthService.getAccessToken();
        String endpoint = GetAcceptConstants.DOCUMENTS_ENDPOINT + '/' + documentId + GetAcceptConstants.EVENTS_ENDPOINT_SUFFIX;
        HttpRequest request = buildHttpRequest(endpoint, GetAcceptConstants.HTTP_GET, token);
        HttpResponse response = new Http().send(request);

        List<Map<String, String>> events = new List<Map<String, String>>();

        if (response.getStatusCode() == 200) {
            List<Object> eventList = (List<Object>) JSON.deserializeUntyped(response.getBody());

            if (eventList != null) {
                for (Object evt : eventList) {
                    Map<String, Object> evtMap = (Map<String, Object>) evt;
                    events.add(new Map<String, String>{
                            'eventName' => (String) evtMap.get(GetAcceptConstants.EVENT_NAME_KEY),
                            'createdAt' => (String) evtMap.get(GetAcceptConstants.CREATED_AT_KEY)
                    });
                }
            }
        } else {
            throw new AuraHandledException(GetAcceptConstants.FETCH_EVENTS_FAILED_ERROR + response.getStatusCode() + ' - ' + response.getBody());
        }

        return events;
    }

    @AuraEnabled
    public static void sendReminder(String documentId) {
        String token = GetAcceptAuthService.getAccessToken();
        String endpoint = GetAcceptConstants.DOCUMENTS_ENDPOINT + '/' + documentId + GetAcceptConstants.REMINDERS_ENDPOINT_SUFFIX;
        HttpRequest request = buildHttpRequest(endpoint, GetAcceptConstants.HTTP_POST, token);
        request.setBody('{"type":"email","text":"Reminder about document","not_opened":"true","not_signed":"true"}');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() != 200 && response.getStatusCode() != 201) {
            throw new AuraHandledException(GetAcceptConstants.SEND_REMINDER_FAILED_ERROR + response.getStatusCode() + ' - ' + response.getBody());
        }
    }

    private static HttpRequest buildHttpRequest(String endpoint, String method, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader(GetAcceptConstants.AUTHORIZATION, GetAcceptConstants.BEARER_PREFIX + token);
        req.setHeader(GetAcceptConstants.CONTENT_TYPE, GetAcceptConstants.APPLICATION_JSON);

        return req;
    }

    private static Datetime parseDateTime(Map<String, Object> data, String primaryKey, String fallbackKey) {
        String dateString = (String) data.get(primaryKey);
        if (dateString == null) dateString = (String) data.get(fallbackKey);

        return dateString != null ? Datetime.valueOf(dateString.replace('T', ' ').replace('+00:00', '')) : null;
    }
}