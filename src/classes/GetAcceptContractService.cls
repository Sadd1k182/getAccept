public with sharing class GetAcceptContractService {
    @AuraEnabled
    public static String createAndSendContract(String accessToken, Id opportunityId) {
        Opportunity opp = fetchOpportunity(opportunityId);
        Contact primaryContact = fetchPrimaryContact(opportunityId);
        ContentVersion cv = fetchLatestDocument(opportunityId);

        String fileId = uploadFileToGetAccept(accessToken, cv);
        if (String.isBlank(fileId)) throw new CalloutException(GetAcceptConstants.UPLOAD_FILE_FAILED_ERROR);

        HttpRequest req = buildHttpRequest(GetAcceptConstants.DOCUMENTS_ENDPOINT, GetAcceptConstants.HTTP_POST, accessToken);
        req.setBody(buildContractRequestBody(opp, primaryContact, fileId));

        HttpResponse res = new Http().send(req);
        if (res.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            return (String) response.get(GetAcceptConstants.ID_KEY);
        } else {
            throw new CalloutException(GetAcceptConstants.CONTRACT_CREATION_FAILED_ERROR + res.getStatusCode() + ' - ' + res.getBody());
        }
    }

    private static String uploadFileToGetAccept(String accessToken, ContentVersion cv) {
        HttpRequest req = buildHttpRequest(GetAcceptConstants.UPLOAD_ENDPOINT, GetAcceptConstants.HTTP_POST, accessToken);
        Map<String, String> requestBody = new Map<String, String>{
                GetAcceptConstants.FILE_NAME_KEY => cv.Title + '.' + cv.FileExtension,
                GetAcceptConstants.FILE_CONTENT_KEY => EncodingUtil.base64Encode(cv.VersionData)
        };
        req.setBody(JSON.serialize(requestBody));

        HttpResponse res = new Http().send(req);

        if (res.getStatusCode() == 200) {
            Map<String, Object> response = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

            return (String) response.get(GetAcceptConstants.FILE_ID_KEY);
        }

        return null;
    }

    private static Opportunity fetchOpportunity(Id opportunityId) {
        Opportunity opp = [
                SELECT Id,
                        Name,
                        Account.Name,
                        Account.BillingStreet,
                        Account.BillingCity,
                        Account.BillingPostalCode,
                        Account.BillingCountry,
                        Amount
                FROM Opportunity
                WHERE Id = :opportunityId
        ];

        if (opp == null) throw new CalloutException(GetAcceptConstants.OPPORTUNITY_NOT_FOUND_ERROR);

        return opp;
    }

    private static Contact fetchPrimaryContact(Id opportunityId) {
        List<OpportunityContactRole> contactRoles = [
                SELECT Contact.Name,
                        Contact.Email,
                        Contact.FirstName,
                        Contact.LastName
                FROM OpportunityContactRole
                WHERE OpportunityId = :opportunityId
                AND IsPrimary = TRUE
                LIMIT 1
        ];

        if (contactRoles.isEmpty()) throw new CalloutException(GetAcceptConstants.PRIMARY_CONTACT_NOT_FOUND_ERROR);

        return contactRoles[0].Contact;
    }

    private static ContentVersion fetchLatestDocument(Id opportunityId) {
        List<ContentDocumentLink> cdls = [
                SELECT ContentDocumentId,
                        ContentDocument.LatestPublishedVersionId,
                        ContentDocument.Title,
                        ContentDocument.FileExtension
                FROM ContentDocumentLink
                WHERE LinkedEntityId = :opportunityId
                AND ContentDocument.FileExtension IN ('pdf', 'doc', 'docx')
                ORDER BY ContentDocument.CreatedDate DESC
                LIMIT 1
        ];

        if (cdls.isEmpty()) throw new CalloutException(GetAcceptConstants.NO_SUITABLE_DOCUMENT_FOUND_ERROR);

        return [SELECT Id, VersionData, Title, FileExtension FROM ContentVersion WHERE Id = :cdls[0].ContentDocument.LatestPublishedVersionId];
    }

    private static String buildContractRequestBody(Opportunity opp, Contact contact, String fileId) {
        Map<String, Object> requestBody = new Map<String, Object>{
                'name' => 'Contract for ' + opp.Name,
                'type' => 'sales',
                'value' => opp.Amount != null ? opp.Amount : 0,
                'is_signing' => true,
                'is_automatic_sending' => true,
                'file_ids' => fileId
        };

        requestBody.put(GetAcceptConstants.RECIPIENTS_KEY, new List<Map<String, Object>>{
                new Map<String, Object>{
                        'first_name' => contact.FirstName,
                        'last_name' => contact.LastName,
                        GetAcceptConstants.EMAIL_KEY => contact.Email,
                        'role' => 'signer'
                }
        });

        requestBody.put('company', new Map<String, Object>{
                'name' => opp.Account.Name,
                'address' => opp.Account.BillingStreet,
                'city' => opp.Account.BillingCity,
                'zip' => opp.Account.BillingPostalCode,
                'country' => opp.Account.BillingCountry
        });

        return JSON.serialize(requestBody, true);
    }

    private static HttpRequest buildHttpRequest(String endpoint, String method, String token) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod(method);
        req.setHeader(GetAcceptConstants.AUTHORIZATION, GetAcceptConstants.BEARER_PREFIX + token);
        req.setHeader(GetAcceptConstants.CONTENT_TYPE, GetAcceptConstants.APPLICATION_JSON);

        return req;
    }
}