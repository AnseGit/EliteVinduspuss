/**
 * @description       : Invokable action to generate threading token for email
 * @author            : Andreas.sevland@stretch.no
 * @last modified on  : 09/25/2024
 * @last modified by  : Andreas Sevland
 **/

public with sharing class ThreadingTokenCreation {
    @invocableMethod(
        label = 'Email - Generate Lightning ThreadingToken'
    )
    public static List<Response> execute (List<Request> requests){
        if(requests != null){
            List<Response> responseList = new List<Response>();
            for(Request curRequest : requests){
                Response response = new Response();

                if (String.isNotBlank(curRequest.relatedrecordId)) {
                    response.threadingToken = EmailMessages.getFormattedThreadingToken(curRequest.relatedrecordId);
                } else {
                    response.threadingToken = null;
                }

                responseList.add(response);
            }
            return responseList;         
        } else{
            return null;
        }
    }

    public class Request{
        @invocableVariable(required = TRUE label = 'Related ID' description = 'RecordId the response-email should relate to') 
        public String relatedrecordId;
    }

    public class Response{
        @InvocableVariable (label = 'Threading Token recieved')
        public String threadingToken;
    }
}