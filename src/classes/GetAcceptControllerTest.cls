@IsTest
private class GetAcceptControllerTest {

    private class MultiMock implements HttpCalloutMock {
        private Map<String, HttpResponse> responses;

        public MultiMock() {
            responses = new Map<String, HttpResponse>();
            HttpResponse authRes = new HttpResponse();
            authRes.setStatusCode(200);
            authRes.setBody('{"access_token":"test_token","expires_in":3600}');
            responses.put(GetAcceptConstants.AUTH_ENDPOINT, authRes);

            HttpResponse docsRes = new HttpResponse();
            docsRes.setStatusCode(200);
            docsRes.setBody('[{"id":"doc1","status":"signed","sign_date":"2023-01-01T12:00:00+00:00","created_at":"2023-01-01T10:00:00+00:00","recipients":[{"email":"test@example.com"}]}]');
            responses.put(GetAcceptConstants.DOCUMENTS_ENDPOINT, docsRes);

            HttpResponse eventsRes = new HttpResponse();
            eventsRes.setStatusCode(200);
            eventsRes.setBody('[{"event_name":"viewed","created_at":"2023-01-01T11:00:00+00:00"}]');
            responses.put(GetAcceptConstants.DOCUMENTS_ENDPOINT + '/doc1' + GetAcceptConstants.EVENTS_ENDPOINT_SUFFIX, eventsRes);

            HttpResponse reminderRes = new HttpResponse();
            reminderRes.setStatusCode(200);
            responses.put(GetAcceptConstants.DOCUMENTS_ENDPOINT + '/doc1' + GetAcceptConstants.REMINDERS_ENDPOINT_SUFFIX, reminderRes);
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = responses.get(req.getEndpoint());
            if (res == null) {
                res = new HttpResponse();
                res.setStatusCode(400);
                res.setBody('{"error":"Bad request"}');
            }
            return res;
        }
    }

    @TestSetup
    static void setup() {
        GetAcceptSettings__c settings = (GetAcceptSettings__c) TestDataFactoryDynamic.createSObject('GetAcceptSettings__c', new Map<String, Object>{
                'Email__c' => 'test@example.com',
                'Password__c' => 'testpass'
        }, true);

        Opportunity opp = (Opportunity) TestDataFactoryDynamic.createSObject('Opportunity', new Map<String, Object>{
                'Name' => 'Test Opp',
                'StageName' => 'Prospecting',
                'CloseDate' => Date.today()
        }, true);

        GetAccept_Document__c existingDoc = (GetAccept_Document__c) TestDataFactoryDynamic.createSObject('GetAccept_Document__c', new Map<String, Object>{
                'Document_ID__c' => 'doc1',
                'Opportunity__c' => opp.Id,
                'Status__c' => 'draft'
        }, true);
    }

    @IsTest
    static void testGetDocumentsSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new MultiMock());

        Test.startTest();
        List<GetAccept_Document__c> docs = GetAcceptController.getDocuments(opp.Id);
        Test.stopTest();

        Assert.areEqual(1, docs.size(), 'Should return one document');
        Assert.areEqual('doc1', docs[0].Document_ID__c, 'Document ID should match');
        Assert.areEqual('signed', docs[0].Status__c, 'Status should be updated');
        Assert.areEqual('test@example.com', docs[0].Recipient_Email__c, 'Recipient email should match');
        Assert.isNotNull(docs[0].Last_Event__c, 'Last event should be set');
    }

    @IsTest
    static void testGetDocumentsEmptyResponse() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        MultiMock mock = new MultiMock();
        mock.responses.put(GetAcceptConstants.DOCUMENTS_ENDPOINT, new HttpResponse());
        mock.responses.get(GetAcceptConstants.DOCUMENTS_ENDPOINT).setStatusCode(200);
        mock.responses.get(GetAcceptConstants.DOCUMENTS_ENDPOINT).setBody('[]');
        Test.setMock(HttpCalloutMock.class, mock);

        Test.startTest();
        List<GetAccept_Document__c> docs = GetAcceptController.getDocuments(opp.Id);
        Test.stopTest();

        Assert.areEqual(0, docs.size(), 'Should return empty list for empty response');
    }

    @IsTest
    static void testGetDocumentEventsSuccess() {
        Test.setMock(HttpCalloutMock.class, new MultiMock());

        Test.startTest();
        List<Map<String, String>> events = GetAcceptController.getDocumentEvents('doc1');
        Test.stopTest();

        Assert.areEqual(1, events.size(), 'Should return one event');
        Assert.areEqual('viewed', events[0].get('eventName'), 'Event name should match');
        Assert.areEqual('2023-01-01T11:00:00+00:00', events[0].get('createdAt'), 'Created at should match');
    }

    @IsTest
    static void testSendReminderSuccess() {
        Test.setMock(HttpCalloutMock.class, new MultiMock());

        Test.startTest();
        GetAcceptController.sendReminder('doc1');
        Test.stopTest();
    }
}