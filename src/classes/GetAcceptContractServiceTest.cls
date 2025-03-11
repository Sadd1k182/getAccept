@IsTest
private class GetAcceptContractServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            if (req.getEndpoint().contains(GetAcceptConstants.UPLOAD_ENDPOINT)) {
                res.setBody('{"file_id":"test_file_123"}');
            } else {
                res.setBody('{"id":"test_contract_123"}');
            }
            res.setStatusCode(200);
            return res;
        }
    }

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"error":"Something went wrong"}');
            res.setStatusCode(400);
            return res;
        }
    }

    @TestSetup
    static void setup() {
        Account acc = (Account) TestDataFactoryDynamic.createSObject('Account', new Map<String, Object>{
                'Name' => 'Test Account',
                'BillingStreet' => '123 Test St',
                'BillingCity' => 'Test City',
                'BillingPostalCode' => '12345',
                'BillingCountry' => 'Test Country'
        }, true);

        Contact con = (Contact) TestDataFactoryDynamic.createSObject('Contact', new Map<String, Object>{
                'FirstName' => 'John',
                'LastName' => 'Doe',
                'Email' => 'john.doe@test.com'
        }, true);

        Opportunity opp = (Opportunity) TestDataFactoryDynamic.createSObject('Opportunity', new Map<String, Object>{
                'Name' => 'Test Opp',
                'AccountId' => acc.Id,
                'StageName' => 'Prospecting',
                'CloseDate' => Date.today(),
                'Amount' => 1000
        }, true);

        TestDataFactoryDynamic.createSObject('OpportunityContactRole', new Map<String, Object>{
                'OpportunityId' => opp.Id,
                'ContactId' => con.Id,
                'IsPrimary' => true
        }, true);

        ContentVersion cv = new ContentVersion(
                Title = 'Test Doc',
                PathOnClient = 'test.pdf',
                VersionData = Blob.valueOf('Test Content')
        );
        insert cv;

        ContentDocument cd = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId = :cv.Id];

        TestDataFactoryDynamic.createSObject('ContentDocumentLink', new Map<String, Object>{
                'LinkedEntityId' => opp.Id,
                'ContentDocumentId' => cd.Id,
                'ShareType' => 'V'
        }, true);
    }

    @IsTest
    static void testCreateAndSendContractSuccess() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String contractId = GetAcceptContractService.createAndSendContract('test_token', opp.Id);
        Test.stopTest();

        Assert.areEqual('test_contract_123', contractId, 'Contract ID should match mock response');
    }

    @IsTest
    static void testUploadFileFailure() {
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opp' LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new FailureMock());

        Test.startTest();
        try {
            GetAcceptContractService.createAndSendContract('test_token', opp.Id);
            Assert.fail('Should have thrown an exception');
        } catch (CalloutException e) {
            Assert.isTrue(e.getMessage().contains(GetAcceptConstants.UPLOAD_FILE_FAILED_ERROR),
                    'Exception should contain upload file failed error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testNoPrimaryContact() {
        Account acc = (Account) TestDataFactoryDynamic.createSObject('Account', new Map<String, Object>{
                'Name' => 'No Contact Account'
        }, true);

        Opportunity opp = (Opportunity) TestDataFactoryDynamic.createSObject('Opportunity', new Map<String, Object>{
                'Name' => 'No Contact Opp',
                'AccountId' => acc.Id,
                'StageName' => 'Prospecting',
                'CloseDate' => Date.today()
        }, true);

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        try {
            GetAcceptContractService.createAndSendContract('test_token', opp.Id);
            Assert.fail('Should have thrown an exception');
        } catch (CalloutException e) {
            Assert.isTrue(e.getMessage().contains(GetAcceptConstants.PRIMARY_CONTACT_NOT_FOUND_ERROR),
                    'Exception should contain primary contact not found error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testMultipleDocuments() {
        Account acc = (Account) TestDataFactoryDynamic.createSObject('Account', new Map<String, Object>{
                'Name' => 'Multi Doc Account'
        }, true);

        Contact con = (Contact) TestDataFactoryDynamic.createSObject('Contact', new Map<String, Object>{
                'LastName' => 'Multi',
                'Email' => 'multi@test.com'
        }, true);

        Opportunity opp = (Opportunity) TestDataFactoryDynamic.createSObject('Opportunity', new Map<String, Object>{
                'Name' => 'Multi Doc Opp',
                'AccountId' => acc.Id,
                'StageName' => 'Prospecting',
                'CloseDate' => Date.today()
        }, true);

        TestDataFactoryDynamic.createSObject('OpportunityContactRole', new Map<String, Object>{
                'OpportunityId' => opp.Id,
                'ContactId' => con.Id,
                'IsPrimary' => true
        }, true);

        List<ContentVersion> cvs = new List<ContentVersion>();
        cvs.add(new ContentVersion(
                Title = 'Test Doc 1',
                PathOnClient = 'test1.pdf',
                VersionData = Blob.valueOf('Test Content 1')
        ));
        cvs.add(new ContentVersion(
                Title = 'Test Doc 2',
                PathOnClient = 'test2.pdf',
                VersionData = Blob.valueOf('Test Content 2')
        ));
        insert cvs;

        List<ContentDocument> cds = [SELECT Id FROM ContentDocument WHERE LatestPublishedVersionId IN :cvs];
        List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();
        for (ContentDocument cd : cds) {
            cdls.add((ContentDocumentLink) TestDataFactoryDynamic.createSObject('ContentDocumentLink', new Map<String, Object>{
                    'LinkedEntityId' => opp.Id,
                    'ContentDocumentId' => cd.Id,
                    'ShareType' => 'V'
            }, false));
        }
        insert cdls;

        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        String contractId = GetAcceptContractService.createAndSendContract('test_token', opp.Id);
        Test.stopTest();

        Assert.areEqual('test_contract_123', contractId, 'Contract ID should match mock response with multiple documents');
    }
}