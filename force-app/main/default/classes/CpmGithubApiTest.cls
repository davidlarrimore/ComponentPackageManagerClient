@isTest
public with sharing class CpmGithubApiTest {

    @testSetup 
    static void setup() {
        List<Cpm_Component_Package__c> demoComponents = new List<Cpm_Component_Package__c>();
        demoComponents.add(new Cpm_Component_Package__c(
            Github_Repository_URL__c = CpmApiCalloutMock.RTA_GITHUB_REPO_URL,
            SFDX_Package_Enabled_Flag__c=true,
            Source_Install_Type_Flag__c=true,
            Package_Install_Type_Flag__c=true,
            Title__c = 'richTextAreaFSC',
            Last_Fetched__c = datetime.now(),
            Latest_Commit_Hash__c = CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH,
            Latest_Commit_DateTime__c = (DateTime)Json.deserialize('2020-08-27T19:26:30.000Z', DateTime.class)
        ));

        insert demoComponents;
    }
    
    static testmethod void testGithubUserAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubUser githubUser = new GithubUser();

        Test.startTest();        
            githubUser = CpmGithubAPIHelper.getGithubUser(CpmApiCalloutMock.GITHUB_API_USER_URL);
        Test.stopTest(); 
        
        System.assertEquals('David Larrimore', githubUser.name);
    }

    static testmethod void testGithubUserAPI404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        GithubUser githubUser = new GithubUser();
        Test.startTest();        
            githubUser = CpmGithubAPIHelper.getGithubUser(CpmApiCalloutMock.GITHUB_API_USER_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubUser);
    }


    static testmethod void testGithubRepoAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();
        GithubRepoOwner githubRepoOwner = new GithubRepoOwner();

        Test.startTest();        
            githubRepo = CpmGithubAPIHelper.getGithubRepo(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 
        
        githubRepoOwner = githubRepo.githubRepoOwner;

        System.assertEquals('richTextInputFSC', githubRepo.name);
        System.assertEquals('davidlarrimore', githubRepoOwner.login);    


    }

    static testmethod void testGithubRepoAPI404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();

        Test.startTest();        
            githubRepo = CpmGithubAPIHelper.getGithubRepo(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubRepo);
    }


    static testmethod void testGithubRepoAPIWWW() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubRepository githubRepo = new GithubRepository();

        Test.startTest();        
            githubRepo = CpmGithubAPIHelper.getGithubRepo(CpmApiCalloutMock.RTA_GITHUB_REPO_URL_WWWW);
        Test.stopTest(); 
        
        System.assertEquals('richTextInputFSC', githubRepo.name);
    }


    static testmethod void testGithubCommitsAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        List<GithubRepoCommit> githubCommits = new List<GithubRepoCommit>();
        
        Test.startTest();        
        githubCommits = CpmGithubAPIHelper.getGithubCommits(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(6, githubCommits.size());
    
    }    

    static testmethod void testGithubCommitsAPI404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        List<GithubRepoCommit> githubCommits = new List<GithubRepoCommit>();

        Test.startTest();        
        githubCommits = CpmGithubAPIHelper.getGithubCommits(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubCommits);
    
    }    


    static testmethod void testGithubCommitMasterAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        GithubRepoCommitInfo commitInfo = new GithubRepoCommitInfo();
        GithubRepoCommitInfoCommiter committer = new GithubRepoCommitInfoCommiter(); 
        GithubRepoCommitAuthor author = new GithubRepoCommitAuthor();


        Test.startTest();        
        githubCommit = CpmGithubAPIHelper.getGithubCommit(CpmApiCalloutMock.RTA_GITHUB_REPO_URL, new Map<String,String>());
        Test.stopTest(); 

        author = githubCommit.author;
        commitInfo = githubCommit.commitInfo;
        committer = commitInfo.committer;

        System.assertEquals('adding orgInit.sh', commitInfo.message);
        System.assertEquals('davidlarrimore', author.login);
        System.assertEquals('David Larrimore', committer.name);
    }    

    static testmethod void testGithubCommitDirectAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        GithubRepoCommitInfo commitInfo = new GithubRepoCommitInfo();
        GithubRepoCommitInfoCommiter committer = new GithubRepoCommitInfoCommiter(); 
        GithubRepoCommitAuthor author = new GithubRepoCommitAuthor();


        Test.startTest();        
        githubCommit = CpmGithubAPIHelper.getGithubCommit(CpmApiCalloutMock.RTA_GITHUB_API_CURRENT_COMMIT_HASH_URL);
        Test.stopTest(); 

        author = githubCommit.author;
        commitInfo = githubCommit.commitInfo;
        committer = commitInfo.committer;

        System.assertEquals('adding orgInit.sh', commitInfo.message);
        System.assertEquals('davidlarrimore', author.login);
        System.assertEquals('David Larrimore', committer.name);
    }    


    static testmethod void testGithubCommitByHashAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        Test.startTest();        
        githubCommit = CpmGithubAPIHelper.getGithubCommit(CpmApiCalloutMock.RTA_GITHUB_REPO_URL, new Map<String,String>{'commitHash' => CpmApiCalloutMock.RTA_GITHUB_CURRENT_COMMIT_HASH});
        Test.stopTest(); 
        
        System.assertEquals('adding orgInit.sh', githubCommit.commitInfo.message);
    }    


   
    static testmethod void testGithubCommitMasterAPI404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        GithubRepoCommit githubCommit = new GithubRepoCommit();
        Test.startTest();        
        githubCommit = CpmGithubAPIHelper.getGithubCommit(CpmApiCalloutMock.RTA_GITHUB_API_COMMIT_MASTER_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubCommit);
    }    
 

    static testmethod void testGithubSFDXProjectDotJson() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        List<GithubPackageDirectory> packageDirectories = new List<GithubPackageDirectory>();
        GithubPackageDirectory packageDirectory = new GithubPackageDirectory();

        Test.startTest();        
        githubSFDXProjectDotJSON = CpmGithubAPIHelper.getGithubSFDXProjectDotJSON(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
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
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        GithubSFDXProjectDotJSON githubSFDXProjectDotJSON = new GithubSFDXProjectDotJSON();
        Test.startTest();        
        githubSFDXProjectDotJSON = CpmGithubAPIHelper.getGithubSFDXProjectDotJSON(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 
        
        System.assertEquals(null, githubSFDXProjectDotJSON);
    }   



    static testmethod void testGithubTagsAPI() {
        Test.setMock(HttpCalloutMock.class, new CpmApiCalloutMock()); 
        List<GithubRepoTag> githubRepoTags = new List<GithubRepoTag>();
        GithubRepoTag githubRepoTag = new GithubRepoTag();

        Test.startTest();        
            githubRepoTags = CpmGithubAPIHelper.getGithubTags(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 

        githubRepoTag = githubRepoTags[0];
        System.assertEquals('3.0', githubRepoTag.name);
    }

    static testmethod void testGithubTagsAPI404() {
        Test.setMock(HttpCalloutMock.class, new CpmApiError404CalloutMock()); 
        List<GithubRepoTag> githubRepoTags = new List<GithubRepoTag>();

        Test.startTest();        
            githubRepoTags = CpmGithubAPIHelper.getGithubTags(CpmApiCalloutMock.RTA_GITHUB_REPO_URL);
        Test.stopTest(); 

        System.assertEquals(null, githubRepoTags);
    }

}


