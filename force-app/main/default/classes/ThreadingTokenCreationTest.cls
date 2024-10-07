/**
 * @description       : Test class ThreadingTokenCreation
 * @author            : Andreas.sevland@stretch.no
 * @group             : Test
 * @last modified on  : 09/25/2024
 * @last modified by  : Andreas Sevland
 **/

 @IsTest
public with sharing class ThreadingTokenCreationTest {
    
@TestSetup
static void makeData(){
    Opportunity testOpportunity = new Opportunity(Name = 'Test Opportunity', StageName = 'Prospecting', CloseDate = Date.today().addDays(30));
    insert testOpportunity;
}

@IsTest
    public static void createThreadingTokenTest() {
        String relatedRecordId = [SELECT id FROM Opportunity WHERE Name = 'Test Opportunity' LIMIT 1].id;
        String threadingToken = EmailMessages.getFormattedThreadingToken(relatedrecordId);
        ThreadingTokenCreation.Request testReq = new ThreadingTokenCreation.Request();
        testReq.relatedrecordId = relatedRecordId;

        List<ThreadingTokenCreation.Request> testReqList = new List<ThreadingTokenCreation.Request>();
        testReqList.add(testReq);

        List<ThreadingTokenCreation.Response> testResponseList = ThreadingTokenCreation.execute(
            testReqList
        );

        Assert.areEqual(testResponseList.size(), 1, 'Response list should contain one element');
        Assert.areEqual(testResponseList[0].threadingToken, threadingToken, 'Threading token should be the same');
    }

    @IsTest
    public static void createThreadingTokenTestNull() {
        ThreadingTokenCreation.Request testReq = new ThreadingTokenCreation.Request();
        testReq.relatedrecordId = '';
        
        List<ThreadingTokenCreation.Request> testReqList = new List<ThreadingTokenCreation.Request>();
        testReqList.add(testReq);

        List<ThreadingTokenCreation.Response> testResponseList = ThreadingTokenCreation.execute(
            testReqList
        );

        Assert.isTrue(testResponseList.size() == 1, 'Response list should contain one element');
        Assert.isNull(testResponseList[0].threadingToken, 'Threading token should be null for empty relatedrecordId');
    }

    @IsTest
    public static void createThreadingTokenTestRequestsNull() {
        Test.startTest();
        List<ThreadingTokenCreation.Response> testResponseList = ThreadingTokenCreation.execute(null);
        Test.stopTest();

        Assert.isNull(testResponseList, 'Response list should be null when input requests is null');
    }
}