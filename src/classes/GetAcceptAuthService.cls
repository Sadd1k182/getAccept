public with sharing class GetAcceptAuthService {
    public class AuthRequest {
        public String email;
        public String password;
    }

    public class AuthResponse {
        public String access_token;
        public Integer expires_in;
        public String message;
    }

    @AuraEnabled
    public static String getAccessToken() {
        GetAcceptSettings__c settings = GetAcceptSettings__c.getInstance();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(GetAcceptConstants.AUTH_ENDPOINT);
        req.setMethod(GetAcceptConstants.HTTP_POST);
        req.setHeader(GetAcceptConstants.CONTENT_TYPE, GetAcceptConstants.APPLICATION_JSON);

        AuthRequest authReq = new AuthRequest();
        authReq.email = settings.Email__c;
        authReq.password = settings.Password__c;
        req.setBody(JSON.serialize(authReq));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            AuthResponse auth = (AuthResponse) JSON.deserialize(res.getBody(), AuthResponse.class);

            return auth.access_token;
        }
        throw new CalloutException(GetAcceptConstants.AUTH_FAILED_ERROR + res.getBody());
    }

    public static void getUserProfile(String accessToken) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(GetAcceptConstants.USERS_ENDPOINT);
        req.setMethod(GetAcceptConstants.HTTP_GET);
        req.setHeader(GetAcceptConstants.AUTHORIZATION, GetAcceptConstants.BEARER_PREFIX + accessToken);
        req.setHeader(GetAcceptConstants.CONTENT_TYPE, GetAcceptConstants.APPLICATION_JSON);

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            System.debug('User Profile: ' + res.getBody());
        } else {
            System.debug('Error: ' + res.getBody());
        }
    }
}