public with sharing class GithubAPIHelper {


    public class ComponentConfigDotJSON {
        public String name;
        public String description;
        public String author;
        public String authorEmail;
        public String alias;
        public String packageType;
        public String permissionSet;
        public Boolean disableSourceInstall;             
        public Boolean disablePackageInstall;
        public List<map<string,string>> dependencies;
        public String errorFlag;
        public String errorMessage;
    }
    public class SFDXProjectDotJSON {
        public List<PackageDirectory> packageDirectories;
        public String namespace;
        public string sfdcLoginUrl;
        public String sourceApiVersion;
        public String errorFlag;
        public String errorMessage;
        public map<string,string> packageAliases;
    }

    public class PackageDirectory {
        public String path;
        public Boolean defaultDirectory;
        public String packageName;
        public String versionName;
        public String versionNumber;
        public String versionDescription;
        public List<map<string,string>> dependencies;
    }

    public class GithubRepository {
        public String id;
        public String name;
        public String full_name;
        public String description;
        public String default_branch;
        public String homepage;
        public GithubRepoOwner githubRepoOwner;
    }

    public class GithubRepoOwner {
        public String login;
        public String id;
        public String url;
        public String bio;
    }

    public class GithubUser {
        public String login;
        public String id;
        public String url;
        public String name;
        public String email;
        public String bio;
        public String gravatar_id;
        public String type;
        public String company;
    }

    public class GithubCommit {
        public String sha;
        public String url;
        public GithubCommitInfo commitInfo;
        public Boolean latestCommitFlag;
    }

    public class GithubCommitInfo {
        public String sha;
        public String node_id;
        public GithubCommitInfoCommiter committer;
        public GithubCommitInfoAuthor author;
        public String message;
    }

    public class GithubCommitInfoAuthor {
        public String authorName;
        public String email;
        public DateTime commitDate;
    }    

    public class GithubCommitInfoCommiter {
        public String name;
        public String email;
        public DateTime commitDate;
    }

    public class GithubTag {
        public String name;
        public GithubCommit githubCommit;
    }

    public static String convertToRawGithubUrl(String githubUrl, String contentName){
        system.debug('Running convertToRawGithubUrl against URL:' + githubUrl);
        String rawGithubUrl = '';
        String newGithubUrl = '';

        if(githubUrl.lastIndexOf('/')+1 == githubUrl.length()){
            system.debug('Last Character is a slash (/), removing it');
            githubUrl = githubUrl.substring(0, githubUrl.length()-1);
            system.debug('New URL: ' + githubUrl);
        }

        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'raw.githubusercontent.com');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'raw.githubusercontent.com');
        }

        if(rawGithubUrl.contains('master')){
            system.debug('Url Contains Master, Assuming this is a subdirectory of a project');
            rawGithubUrl = rawGithubUrl.replace('/tree', '');
            newGithubUrl = rawGithubUrl + '/' + contentName;
        }else{
            newGithubUrl = rawGithubUrl + '/master/' + contentName;
        }

        system.debug('Converted URL to ' + newGithubUrl);

        return newGithubUrl;
    }

    public static String convertToRepoApiGithubUrl(String githubUrl){
        system.debug('Running convertToRepoApiGithubUrl against URL:' + githubUrl);
        String rawGithubUrl = '';

        if(githubUrl.lastIndexOf('/')+1 == githubUrl.length()){
            system.debug('Last Character is a slash (/), removing it');
            githubUrl = githubUrl.substring(0, githubUrl.length()-1);
            system.debug('New URL: ' + githubUrl);
        }

        if(githubUrl.indexOf('www.github.com') > 0){
            rawGithubUrl = githubUrl.replace('www.github', 'api.github.com/repos');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'api.github.com/repos');
        }
        
        //TODO: Deal with subdirectories
        system.debug('Converted URL to ' + rawGithubUrl);

        return rawGithubUrl;
    }


    public static SFDXProjectDotJSON getGithubSFDXProjectDotJSON(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotJSON against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRawGithubUrl(githubUrl, 'sfdx-project.json');
        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
  
        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(newGithubUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"package":', '"packageName":');
            JSONResponse = JSONResponse.replace('"default":', '"defaultDirectory":');
            
            system.debug('Processing JSON: ' + JSONResponse);
            return (SFDXProjectDotJSON)System.JSON.deserialize(JSONResponse, SFDXProjectDotJSON.class);
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;

    }

    public static ComponentConfigDotJSON getGithubComponentConfigDotJSON(String githubUrl){
        system.debug('Running getGithubComponentConfigDotJSON against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRawGithubUrl(githubUrl, 'component-config.json');
        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(newGithubUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"package":', '"packageName":');
            JSONResponse = JSONResponse.replace('"default":', '"defaultDirectory":');

            system.debug('Processing JSON: ' + JSONResponse);
            return (ComponentConfigDotJSON)System.JSON.deserialize(JSONResponse, ComponentConfigDotJSON.class);
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }


    //For older packages (PRE SFDX), we can try to grab the /src/package.xml
    public static Dom.Document getGithubSFDXProjectDotXML(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotXML against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRawGithubUrl(githubUrl+'/src/', 'package.xml');

        try{        
            Http http = new Http();
            HttpRequest request = new HttpRequest();

            request.setEndpoint(newGithubUrl);

            request.setMethod('GET');
            HttpResponse response = http.send(request);
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200) {
                // Deserialize the JSON string into collections of primitive data types.
                return response.getBodyDocument();
            }else{
                return null;
            }
        }catch(Exception e){
            system.debug('Error Running API: ' + e);
            return null;
        }          
    }


    /* 
    * Get Base Repo Info from Github API: https://api.github.com/repos/davidlarrimore/gpbu-visitor-management
    * Get Commits: https://api.github.com/repos/davidlarrimore/gpbu-visitor-management/commits
    * Get Tags: https://api.github.com/repos/davidlarrimore/gpbu-visitor-management/tags
    * 
    */
    public static List<GithubCommit> getGithubCommits(String githubUrl){
        system.debug('Running getGithubCommits against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(newGithubUrl + '/commits', false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"commitInfo":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            system.debug('Processing JSON: ' + JSONResponse);
            List<GithubCommit> githubCommits = (List<GithubCommit>)System.JSON.deserialize(JSONResponse, List<GithubCommit>.class);

            DateTime NewestCommitDateTime = DateTime.newInstance(1901, 1, 1, 1, 1, 0);

            if(githubCommits != null){
                system.debug('Processing GithubCommit Object to find latest commit');
                for(GithubCommit thisCommit: githubCommits){
                    //defaulting commit flag to false
                    thisCommit.latestCommitFlag = false;

                    if(NewestCommitDateTime < thisCommit.commitInfo.committer.commitDate){
                        NewestCommitDateTime = thisCommit.commitInfo.committer.commitDate;
                    }
                }
                system.debug('Latest commit date is: ' + NewestCommitDateTime + '. now setting it as latest commit flag');

                for(GithubCommit thisCommit: githubCommits){
                    if(NewestCommitDateTime == thisCommit.commitInfo.committer.commitDate){
                        thisCommit.latestCommitFlag = true;
                        NewestCommitDateTime = thisCommit.commitInfo.committer.commitDate;
                    }
                }
                system.debug(githubCommits);
                return githubCommits;
            }
            return null;
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }



    public static List<GithubTag> getGithubTags(String githubUrl){
        system.debug('Running getGithubTags against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(newGithubUrl + '/tags', false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"githubCommit":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            system.debug('Processing JSON: ' + JSONResponse);
            List<GithubTag> githubTags = (List<GithubTag>)System.JSON.deserialize(JSONResponse, List<GithubTag>.class);

            DateTime NewestCommitDateTime = DateTime.newInstance(1901, 1, 1, 1, 1, 0);

            if(githubTags != null){
                system.debug(githubTags);
                return githubTags;
            }
            return null;
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }


    public static GithubRepository getGithubRepo(String githubUrl){
        system.debug('Running getGithubRepo against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(newGithubUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"githubCommit":');
            JSONResponse = JSONResponse.replace('"owner":', '"githubRepoOwner":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            system.debug('Processing JSON: ' + JSONResponse);
            GithubRepository githubRepository = (GithubRepository)System.JSON.deserialize(JSONResponse, GithubRepository.class);

            DateTime NewestCommitDateTime = DateTime.newInstance(1901, 1, 1, 1, 1, 0);

            if(githubRepository != null){
                system.debug(githubRepository);
                return githubRepository;
            }
            return null;
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }

    //requires the actual URL
    public static GithubUser getGithubUser(String githubUserUrl){
        system.debug('Running getGithubUser against URL:' + githubUserUrl);

        //get JSON String
        String JSONResponse = APIHelper.doRestRequestJSON(githubUserUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"githubCommit":');
            JSONResponse = JSONResponse.replace('"owner":', '"githubRepoOwner":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            system.debug('Processing JSON: ' + JSONResponse);
            GithubUser githubUser = (GithubUser)System.JSON.deserialize(JSONResponse, GithubUser.class);

            if(githubUser != null){
                system.debug(githubUser);
                return githubUser;
            }
            return null;
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }



}
