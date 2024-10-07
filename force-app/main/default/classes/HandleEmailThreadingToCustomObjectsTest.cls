/**
 * @description       : Test class HandleEmailThreadingToCustomObjects
 * @author            : Andreas.sevland@stretch.no
 * @group             : Test
 * @last modified on  : 09/25/2024
 * @last modified by  : Andreas Sevland
 **/

@isTest
private class HandleEmailThreadingToCustomObjectsTest {

    static final String fromEmail = 'testfromemail@testemail.com';

@TestSetup
static void makeData(){
    // Create a Opportunity with name "Test Opportunity"
    Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today());
    insert testOpportunity;
    }

@isTest
    private static void inboundEmailTestPositive() {
        Id opportunityId = [SELECT id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1].id;
        String threadingToken = EmailMessages.getFormattedThreadingToken(opportunityId);
        Messaging.InboundEmail email = createEmail(threadingToken);
        Messaging.InboundEnvelope env = createEnvelope();

        Test.startTest();
        Messaging.InboundEmailResult result = new HandleEmailThreadingToCustomObjects().handleInboundEmail(email, env);
        // HandleEmailThreadingToCustomObjects emailThreading = new HandleEmailThreadingToCustomObjects();
        // emailThreading.handleInboundEmail(email, env);
        Test.stopTest();

        List<EmailMessage> recievedEmailList = new List<EmailMessage>([SELECT id, relatedToId FROM EmailMessage WHERE relatedToId = :opportunityId]);

        Assert.isTrue(result.success, 'The result should be success');
        Assert.areEqual(2, [SELECT Count() FROM ContentVersion], 'There should be 2 ContentVersion records');
        Assert.areEqual(1, [SELECT Count() FROM ContentDocumentLink WHERE LinkedEntityId = :opportunityId], 'There should be 1 ContentDocumentLink records');
        Assert.areEqual(1, recievedEmailList.size(), 'There should be 1 email related to Opportunity in status new');
        Assert.areEqual(opportunityId, recievedEmailList[0].relatedToId, 'Opportunity should be related to Email Message');
        Assert.areEqual(0, [SELECT Count() FROM Case], 'There should be no cases created');       
    }

    @IsTest
    private static void inboundEmailTestNegative() {
        Messaging.InboundEmail email = createEmail(null);
        Messaging.InboundEnvelope env = createEnvelope();

        Test.startTest();
        Messaging.InboundEmailResult result = new HandleEmailThreadingToCustomObjects().handleInboundEmail(email, env);
        Test.stopTest();

        List<EmailMessage> recievedEmailList = new List<EmailMessage>([SELECT id, parentId FROM EmailMessage WHERE subject LIKE 'test subject%' AND status = '0']);
        List<Case> createdCases = new List<Case>([SELECT id FROM Case]);
    
        Assert.areEqual(1, recievedEmailList.size(), 'There should be no emails with status 0');
        Assert.areEqual(1, createdCases.size(), 'There should be 1 cases created');
        Assert.areEqual(recievedEmailList[0].parentId, createdCases[0].id, 'The created Case should be parent of Created EmailMessage');
    }

    @isTest
    private static void testGetClientThreadIdentifier() {
        HandleEmailThreadingToCustomObjects handler = new HandleEmailThreadingToCustomObjects();
        
        // Test with null headers
        Messaging.InboundEmail emailWithNullHeaders = new Messaging.InboundEmail();
        emailWithNullHeaders.headers = null;
        String result = handler.getClientThreadIdentifier(emailWithNullHeaders.headers);
        
        Assert.isNull(result, 'Result should be null for null headers');
        
        // Test with empty headers
        Messaging.InboundEmail emailWithEmptyHeaders = new Messaging.InboundEmail();
        emailWithEmptyHeaders.headers = new List<Messaging.InboundEmail.Header>();
        result = handler.getClientThreadIdentifier(emailWithEmptyHeaders.headers);
        
        Assert.isNull(result, 'Result should be null for empty headers');
        
        // Test with valid thread-index header
        Messaging.InboundEmail emailWithValidHeader = new Messaging.InboundEmail();
        String validBase64 = 'AQHSReAAcLWSleq7Uj9N8kTwpwCrrw=='; // This is a sample Base64 encoded string
        emailWithValidHeader.headers = new List<Messaging.InboundEmail.Header>();
        emailWithValidHeader.headers.add(createHeader('thread-index', validBase64));
        result = handler.getClientThreadIdentifier(emailWithValidHeader.headers);
        
        Assert.isNotNull(result, 'Result should not be null for valid thread-index');
        Assert.areEqual(44, result.length(), 'Result should be a 44-character string');
        Assert.isTrue(result.equals(result.toUpperCase()), 'Result should be in uppercase');
        
        // Test with invalid thread-index header
        Messaging.InboundEmail emailWithInvalidHeader = new Messaging.InboundEmail();
        emailWithInvalidHeader.headers = new List<Messaging.InboundEmail.Header>();
        emailWithInvalidHeader.headers.add(createHeader('thread-index', 'invalid-base64-string'));
        result = handler.getClientThreadIdentifier(emailWithInvalidHeader.headers);
        
        Assert.isNull(result, 'Result should be null for invalid thread-index');
        
        // Test with case-insensitive header name
        Messaging.InboundEmail emailWithCaseInsensitiveHeader = new Messaging.InboundEmail();
        emailWithCaseInsensitiveHeader.headers = new List<Messaging.InboundEmail.Header>();
        emailWithCaseInsensitiveHeader.headers.add(createHeader('ThReAd-InDeX', validBase64));
        result = handler.getClientThreadIdentifier(emailWithCaseInsensitiveHeader.headers);
        
        Assert.isNotNull(result, 'Result should not be null for case-insensitive header name');
        Assert.areEqual(44, result.length(), 'Result should be a 44-character string');
    }

    // Helper method to create a header
    private static Messaging.InboundEmail.Header createHeader(String name, String value) {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.headers = new List<Messaging.InboundEmail.Header>();
        email.headers.add(new Messaging.InboundEmail.Header());
        email.headers[0].name = name;
        email.headers[0].value = value;
        return email.headers[0];
    }

    private static Messaging.InboundEmail createEmail(String threadingToken) {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        email.Subject = threadingToken != null ? ('test subject ' + threadingToken) : 'test subject ';
        email.plainTextBody = threadingToken != null ? ('test body ' + threadingToken) : 'test body ';
        email.toAddresses = new List<String>{'toaddress.test@gmail.com'};
        email.FromAddress = fromEmail;
        email.FromName = 'Test Name';
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{createAttachment('HelloWorld.txt', Blob.valueOf('Test File'))};

        return email;
    }

    private static Messaging.InboundEnvelope createEnvelope() {
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        env.fromAddress = fromEmail;
        env.toAddress = 'toaddress.test@gmail.com';
        return env;
    }

    private static Messaging.InboundEmail.BinaryAttachment createAttachment(String fileName, Blob fileBody){
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.fileName = fileName;
        attachment.body = fileBody;
        return attachment;
    }        
}
