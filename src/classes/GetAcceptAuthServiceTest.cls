@IsTest
private class GetAcceptAuthServiceTest {

    private class AuthSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"test_token_123","expires_in":3600,"message":"Success"}');
            res.setStatusCode(200);
            return res;
        }
    }

    private class AuthFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('{"error":"Invalid credentials"}');
            res.setStatusCode(401);
            return res;
        }
    }

    private class UserProfileSuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"user_id":"123","name":"Test User","email":"test@example.com"}');
            res.setStatusCode(200);
            return res;
        }
    }

    @TestSetup
    static void setup() {
        TestDataFactoryDynamic.createSObject('GetAcceptSettings__c', new Map<String, Object>{
                'Email__c' => 'test@example.com',
                'Password__c' => 'testpassword'
        }, true);
    }

    @IsTest
    static void testGetAccessTokenSuccess() {
        Test.setMock(HttpCalloutMock.class, new AuthSuccessMock());

        Test.startTest();
        String accessToken = GetAcceptAuthService.getAccessToken();
        Test.stopTest();

        Assert.areEqual('test_token_123', accessToken, 'Access token should match mock response');
    }

    @IsTest
    static void testGetUserProfileSuccess() {
        Test.setMock(HttpCalloutMock.class, new UserProfileSuccessMock());

        Test.startTest();
        GetAcceptAuthService.getUserProfile('test_token_123');
        Test.stopTest();
    }

    @IsTest
    static void testGetAccessTokenFailure() {
        Test.setMock(HttpCalloutMock.class, new AuthFailureMock());

        Test.startTest();
        try {
            GetAcceptAuthService.getAccessToken();
            Assert.isTrue(false, 'Should have thrown an exception');
        } catch (CalloutException e) {
            Assert.isTrue(e.getMessage().contains(GetAcceptConstants.AUTH_FAILED_ERROR), 'Exception message should contain AUTH_FAILED_ERROR');
        }
        Test.stopTest();
    }

    @IsTest
    static void testAuthRequestSerialization() {
        GetAcceptAuthService.AuthRequest authReq = new GetAcceptAuthService.AuthRequest();
        authReq.email = 'test@example.com';
        authReq.password = 'testpass';

        String jsonString = JSON.serialize(authReq);
        Map<String, Object> deserialized = (Map<String, Object>) JSON.deserializeUntyped(jsonString);

        Assert.areEqual('test@example.com', deserialized.get('email'), 'Email should match');
        Assert.areEqual('testpass', deserialized.get('password'), 'Password should match');
    }

    @IsTest
    static void testAuthResponseDeserialization() {
        String jsonString = '{"access_token":"test_token","expires_in":3600,"message":"Success"}';
        GetAcceptAuthService.AuthResponse authResp =
                (GetAcceptAuthService.AuthResponse) JSON.deserialize(jsonString, GetAcceptAuthService.AuthResponse.class);

        Assert.areEqual('test_token', authResp.access_token, 'Access token should match');
        Assert.areEqual(3600, authResp.expires_in, 'Expires in should match');
        Assert.areEqual('Success', authResp.message, 'Message should match');
    }
}