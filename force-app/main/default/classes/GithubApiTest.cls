@isTest
public with sharing class GithubApiTest {
    public static final String githubApiRepoURL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC';
    public static final String githubApiUserURL = 'https://api.github.com/users/davidlarrimore';
    public static final String githubApiCommitsURL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/commits';
    public static final String githubApiCommitURL = 'https://api.github.com/repos/davidlarrimore/richTextInputFSC/git/commits/ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';
    public static final String githubApiCommitHash = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81';


    @testSetup 
    static void setup() {
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();
        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = QueueTest.richTextAreaFSCGithubUrl,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = 'ba99ca2ffdd0e25596be4e1fa9cbc18bb2f57f81',
            Latest_Commit_DateTime__c = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class)
        ));

        insert demoComponents;
    }
    
    static testmethod void testGithubUserAPI() {
        Test.setMock(HttpCalloutMock.class, new GithubApiGetUserCalloutMock()); 
        GithubUser githubUser = new GithubUser();

        Test.startTest();        
            githubUser = GithubAPIHelper.getGithubUser(githubApiUserURL);
        Test.stopTest(); 
        
        System.assertEquals('David Larrimore', githubUser.name);
    }


    static testmethod void testGithubRepoAPI() {
        Test.setMock(HttpCalloutMock.class, new GithubApiGetRepoCalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();

        Test.startTest();        
            githubRepo = GithubAPIHelper.getGithubRepo(githubApiRepoURL);
        Test.stopTest(); 
        
        System.assertEquals('richTextInputFSC', githubRepo.name);
    }


    static testmethod void testGithubCommitsAPI() {
        Test.setMock(HttpCalloutMock.class, new GithubApiGetCommitsCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        //List<GithubRepoCommit> getGithubCommits
        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommits(githubApiCommitsURL);
        Test.stopTest(); 
        
        System.assertEquals('richTextInputFSC', githubCommit.name);
    
    }    

    static testmethod void testGithubCommitAPI() {
        Test.setMock(HttpCalloutMock.class, new GithubApiGetCommitsCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        //List<GithubRepoCommit> getGithubCommits
        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommit(githubApiCommitURL);
        Test.stopTest(); 
        
        System.assertEquals('adding orgInit.sh', githubCommit.commitInfo.message);
    }    


    static testmethod void testGithubSpecificCommitAPI() {
        Test.setMock(HttpCalloutMock.class, new GithubApiGetCommitsCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        //List<GithubRepoCommit> getGithubCommits
        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommit(githubApiRepoURL, new Map<String,String>{'commitHash' => githubApiCommitHash});
        Test.stopTest(); 
        
        System.assertEquals('adding orgInit.sh', githubRepo.commitInfo.message);

    }    

}


