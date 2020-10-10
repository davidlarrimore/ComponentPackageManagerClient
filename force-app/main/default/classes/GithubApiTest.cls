@isTest
public with sharing class GithubApiTest {

    @testSetup 
    static void setup() {
        List<Demo_Component__c> demoComponents = new List<Demo_Component__c>();
        demoComponents.add(new Demo_Component__c(
            Github_Repository_URL__c = ApiCalloutMock.GITHUB_REPO_URL,
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
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubUser githubUser = new GithubUser();

        Test.startTest();        
            githubUser = GithubAPIHelper.getGithubUser(ApiCalloutMock.GITHUB_API_USER_URL);
        Test.stopTest(); 
        
        System.assertEquals('David Larrimore', githubUser.name);
    }

    static testmethod void testGithubUserAPI404() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 
        GithubUser githubUser = new GithubUser();
        Test.startTest();        
            githubUser = GithubAPIHelper.getGithubUser(ApiCalloutMock.GITHUB_API_USER_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubUser);
    }


    static testmethod void testGithubRepoAPI() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();
        GithubRepoOwner githubRepoOwner = new GithubRepoOwner();

        Test.startTest();        
            githubRepo = GithubAPIHelper.getGithubRepo(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 
        
        githubRepoOwner = githubRepo.githubRepoOwner;

        System.assertEquals('richTextInputFSC', githubRepo.name);
        System.assertEquals('davidlarrimore', githubRepoOwner.login);    


    }

    static testmethod void testGithubRepoAPI404() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();

        Test.startTest();        
            githubRepo = GithubAPIHelper.getGithubRepo(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubRepo);
    }


    static testmethod void testGithubRepoAPIWWW() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();

        Test.startTest();        
            githubRepo = GithubAPIHelper.getGithubRepo(ApiCalloutMock.GITHUB_REPO_URL_WWWW);
        Test.stopTest(); 
        
        System.assertEquals('richTextInputFSC', githubRepo.name);
    }


    static testmethod void testGithubCommitsAPI() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        List<GithubRepoCommit> githubCommits = new List<GithubRepoCommit>();
        
        Test.startTest();        
        githubCommits = GithubAPIHelper.getGithubCommits(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(6, githubCommits.size());
    
    }    

    static testmethod void testGithubCommitsAPI404() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 
        List<GithubRepoCommit> githubCommits = new List<GithubRepoCommit>();

        Test.startTest();        
        githubCommits = GithubAPIHelper.getGithubCommits(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubCommits);
    
    }    


    static testmethod void testGithubCommitMasterAPI() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        GithubRepoCommitInfo commitInfo = new GithubRepoCommitInfo();
        GithubRepoCommitInfoCommiter committer = new GithubRepoCommitInfoCommiter(); 
        GithubRepoCommitAuthor author = new GithubRepoCommitAuthor();


        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommit(ApiCalloutMock.GITHUB_REPO_URL, new Map<String,String>());
        Test.stopTest(); 

        author = githubCommit.author;
        commitInfo = githubCommit.commitInfo;
        committer = commitInfo.committer;

        System.assertEquals('adding orgInit.sh', commitInfo.message);
        System.assertEquals('davidlarrimore', author.login);
        System.assertEquals('David Larrimore', committer.name);
    }    

    static testmethod void testGithubCommitDirectAPI() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        GithubRepoCommitInfo commitInfo = new GithubRepoCommitInfo();
        GithubRepoCommitInfoCommiter committer = new GithubRepoCommitInfoCommiter(); 
        GithubRepoCommitAuthor author = new GithubRepoCommitAuthor();


        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommit(ApiCalloutMock.GITHUB_API_COMMIT_HASH_URL);
        Test.stopTest(); 

        author = githubCommit.author;
        commitInfo = githubCommit.commitInfo;
        committer = commitInfo.committer;

        System.assertEquals('adding orgInit.sh', commitInfo.message);
        System.assertEquals('davidlarrimore', author.login);
        System.assertEquals('David Larrimore', committer.name);
    }    


    static testmethod void testGithubCommitByHashAPI() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommit(ApiCalloutMock.GITHUB_REPO_URL, new Map<String,String>{'commitHash' => ApiCalloutMock.GITHUB_COMMIT_HASH});
        Test.stopTest(); 
        
        System.assertEquals('adding orgInit.sh', githubCommit.commitInfo.message);
    }    


   
    static testmethod void testGithubCommitMasterAPI404() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        Test.startTest();        
        githubCommit = GithubAPIHelper.getGithubCommit(ApiCalloutMock.GITHUB_API_COMMIT_MASTER_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubCommit);
    }    
 

    static testmethod void testGithubSFDXProjectDotJson() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        List<GithubPackageDirectory> packageDirectories = new List<GithubPackageDirectory>();
        GithubPackageDirectory packageDirectory = new GithubPackageDirectory();

        Test.startTest();        
        githubSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 
        

        packageDirectories = GithubSFDXProjectDotJSON.packageDirectories;
        packageDirectory = packageDirectories[0];

        System.assertEquals('https://login.salesforce.com', githubSFDXProjectDotJSON.sfdcLoginUrl);
        System.assertEquals('04t3h000004bdyCAAQ', githubSFDXProjectDotJSON.getLatestVersionPackageVersionId());
        System.assertEquals('richTextAreaFSC@0.3.0-1', githubSFDXProjectDotJSON.getLatestVersionAlias());
        System.assertEquals('0.3.0-1', githubSFDXProjectDotJSON.getLatestVersionText());
        System.assertEquals(30001, githubSFDXProjectDotJSON.getLatestVersionNumber());
        System.assertEquals(1, packageDirectories.size());
        System.assertEquals('richTextAreaFSC', packageDirectory.packageName);       
    }   

    static testmethod void testGithubSFDXProjectDotJson404() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        Test.startTest();        
        githubSFDXProjectDotJSON = GithubAPIHelper.getGithubSFDXProjectDotJSON(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubSFDXProjectDotJSON);
    }   



    static testmethod void testGithubTagsAPI() {
        Test.setMock(HttpCalloutMock.class, new ApiCalloutMock()); 
        List<GithubRepoTag> githubRepoTags = new List<GithubRepoTag>();
        GithubRepoTag githubRepoTag = new GithubRepoTag();

        Test.startTest();        
            githubRepoTags = GithubAPIHelper.getGithubTags(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 

        githubRepoTag = githubRepoTags[0];
        System.assertEquals('3.0', githubRepoTag.name);
    }

    static testmethod void testGithubTagsAPI404() {
        Test.setMock(HttpCalloutMock.class, new ApiError404CalloutMock()); 
        List<GithubRepoTag> githubRepoTags = new List<GithubRepoTag>();

        Test.startTest();        
            githubRepoTags = GithubAPIHelper.getGithubTags(ApiCalloutMock.GITHUB_REPO_URL);
        Test.stopTest(); 

        System.assertEquals(null, githubRepoTags);
    }

}


