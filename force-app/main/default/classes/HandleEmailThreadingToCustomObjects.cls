/**
 * @description       : Handles threading of emails to custom objects with help of email services
 * @author            : Andreas.sevland@stretch.no
 * @last modified on  : 09/25/2024
 * @last modified by  : Andreas Sevland
 **/


public with sharing class HandleEmailThreadingToCustomObjects implements Messaging.InboundEmailHandler {  
    
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
       
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();  // Create an InboundEmailResult object for returning the result of the Apex Email Service.
        
        Id relatedToId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);
        Id caseId = null;
        Id acctId = null;
        String toAddresses = '';

        if (relatedToId == null) {
            caseId = createCaseFromEmail(email);
            acctId = findAccountIdFromEmail(email);
        } 

        createFilesByEmailAttachement(email.binaryAttachments, relatedToId);

        EmailMessage ems = new EmailMessage(
            Status = '0',
            MessageIdentifier = email.messageId,
            ParentId = caseId,
            Subject = relatedToId != null ? email.subject.replace(EmailMessages.getFormattedThreadingToken(relatedToId), '') : email.subject, 
            TextBody = email.plainTextBody,
            FromAddress = email.fromAddress,
            FromName = email.fromName,
            ToAddress = email.toAddresses != null ? String.join(email.toAddresses, '; ') : '',
            HtmlBody = email.htmlBody,
            relatedToId = relatedToId != null ? relatedToId : acctId != null ? acctId : null,
            ClientThreadIdentifier = getClientThreadIdentifier(email.headers)
        );

        if (Schema.sObjectType.EmailMessage.isCreateable()){
            insert ems;
            createFilesByEmailAttachement(email.binaryAttachments, ems.id);
            result.success = true; // Set the result to true. No need to send an email back to the user with an error message.
            return result;
        } else {
            return null;
        }        
    }

    private Id createCaseFromEmail(Messaging.InboundEmail email){
        if (!Schema.sObjectType.Case.isCreateable()){
            return null;
        }

        Case newCase = new Case(
            Subject = email.subject,
            Description = email.plainTextBody,
            status = 'New',
            origin = 'Email'
        ); 
        
        try{
            insert newCase;
            return newCase.id;
        } catch (DmlException e){
            System.debug('Failed to create Case: ' + e.getMessage());
            return null;
        }
    }

    private Id findAccountIdFromEmail(Messaging.InboundEmail email){
        List<Account> relatedAccounts = [
            SELECT Id
            FROM Account
            WHERE Id IN (
                SELECT AccountId 
                FROM Contact 
                WHERE Email = :email.fromAddress) 
            LIMIT 1]; 

            return relatedAccounts.isEmpty() ? null : relatedAccounts[0].id;
    }

    private void createFilesByEmailAttachement(List<Messaging.InboundEmail.BinaryAttachment> inboundAttachements, Id relatedToId){
        if(inboundAttachements == null || relatedToId == null){
            return;
        }

        List<FileAndLinkObject> toCreate = new List <FileAndLinkObject>();  

        for(Messaging.InboundEmail.BinaryAttachment currentAttachement : inboundAttachements){
            FileAndLinkObject newFile = new FileAndLinkObject();
            newFile.fileContents = currentAttachement.body;
            newFile.fileName = currentAttachement.fileName;
            newFile.attachedTo = relatedToId;
            toCreate.add(newFile);
        }
        
        createFilesAttachedToRecords(toCreate);
    }

    public static List<Database.SaveResult> createFilesAttachedToRecords(List<FileAndLinkObject> toCreate){
        List<ContentVersion> filesToCreate = new List<ContentVersion>();

        for (FileAndLinkObject files : toCreate) {
            ContentVersion fileToUpload = new ContentVersion();
            fileToUpload.ContentLocation = 'S';
            fileToUpload.PathOnClient = files.fileName;
            fileToUpload.Title = files.fileName;
            fileToUpload.VersionData = files.fileContents;
            fileToUpload.FirstPublishLocationId = files.attachedTo;
            filesToCreate.add(fileToUpload);
        }

        List<Database.SaveResult> saveResult = new List<Database.SaveResult>();
        try {
            saveResult = Database.insert(filesToCreate, AccessLevel.USER_MODE);
        } catch (DmlException DMLe) {
            System.debug(LoggingLevel.INFO, 'Failed to insert filesToUpload, error is: ' + DMLe.getMessage());
        }
        
        return saveResult;
    }

    @TestVisible
    private String getClientThreadIdentifier(List<Messaging.InboundEmail.Header> headers) {
        if (headers == null || headers.size() == 0){
            return null;
        }
        
        try {
            for (Messaging.InboundEmail.Header header : headers) {
                if (header.name.equalsIgnoreCase('thread-index')) {
                    Blob threadIndex = EncodingUtil.base64Decode(header.value.trim());
                    return EncodingUtil.convertToHex(threadIndex).substring(0, 44).toUpperCase();
                }
            }
        } catch (Exception e){
            return null;
        }
        return null;
    } 

    public class FileAndLinkObject {
        public Blob fileContents { get; set; }
        public Id attachedTo { get; set; }
        public String fileName { get; set; }
    }
}

