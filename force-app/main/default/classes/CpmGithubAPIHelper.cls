public with sharing class CpmGithubAPIHelper {


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
            newGithubUrl = rawGithubUrl.replace('/tree', '') + '/' + contentName;
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
            rawGithubUrl = githubUrl.replace('www.github.com', 'api.github.com/repos');
        }else{
            rawGithubUrl = githubUrl.replace('github.com', 'api.github.com/repos');
        }
        
        //TODO: Deal with subdirectories
        system.debug('Converted URL to ' + rawGithubUrl);

        return rawGithubUrl;
    }

    public static GithubSFDXProjectDotJSON getGithubSFDXProjectDotJSON(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotJSON against URL:' + githubUrl);
        String newGithubUrl = CpmGithubAPIHelper.convertToRawGithubUrl(githubUrl, 'sfdx-project.json');
        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
  
        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(newGithubUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"package":', '"packageName":');
            JSONResponse = JSONResponse.replace('"default":', '"defaultDirectory":');
            
            //system.debug('Processing JSON: ' + JSONResponse);
            return (GithubSFDXProjectDotJSON)System.JSON.deserialize(JSONResponse, GithubSFDXProjectDotJSON.class);
        }
        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }

   /* 
    * Get Latest Master Commit
    * Options:
    * commitHash, will look for a specific hash
    * Otherwise defaults to master
    */
    public static GithubRepoCommit getGithubCommit(String githubUrl, Map<String,String> options){
        system.debug('Running getLatestGithubCommit against URL:' + githubUrl);
        String newGithubUrl = CpmGithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        //TODO: Use the /master to grab the latest commit
        
        if(options.containsKey('commitHash')){
            newGithubUrl = newGithubUrl + '/commits/'+options.get('commitHash');
        }else{
            newGithubUrl = newGithubUrl + '/commits/master';
        }
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(newGithubUrl, false);

        if(JSONResponse != null ){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"commitInfo":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            //system.debug('Processing JSON: ' + JSONResponse);
            GithubRepoCommit githubCommit = (GithubRepoCommit)System.JSON.deserialize(JSONResponse, GithubRepoCommit.class);
            if(githubCommit != null){
                githubCommit.latestCommitFlag = true;
    
                system.debug(githubCommit);
                return githubCommit;
            }else{
                return null;
            }
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }


    /* 
    * Get All commits
    * Get Base Repo Info from Github API: https://api.github.com/repos/davidlarrimore/gpbu-visitor-management
    * Get Commits: https://api.github.com/repos/davidlarrimore/gpbu-visitor-management/commits/master (the /master grabs the latest)
    * Get Tags: https://api.github.com/repos/davidlarrimore/gpbu-visitor-management/tags
    * ALternative Method:
    * 1) Grab Latest Release: https://api.github.com/repos/davidlarrimore/richtextinputfsc/releases/latest
    * 2) Use Name to grab latest Tag: https://api.github.com/repos/davidlarrimore/richtextinputfsc/releases/tags/3.0
    * 
    */
    public static List<GithubRepoCommit> getGithubCommits(String githubUrl){
        system.debug('Running getGithubCommits against URL:' + githubUrl);
        String newGithubUrl = CpmGithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        //TODO: Use the /master to grab the latest commit
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(newGithubUrl + '/commits', false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"commitInfo":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            //system.debug('Processing JSON: ' + JSONResponse);
            List<GithubRepoCommit> githubCommits = (List<GithubRepoCommit>)System.JSON.deserialize(JSONResponse, List<GithubRepoCommit>.class);

            DateTime NewestCommitDateTime = DateTime.newInstance(1901, 1, 1, 1, 1, 0);

            if(githubCommits != null){
                system.debug('Processing GithubCommit Object to find latest commit');
                for(GithubRepoCommit thisCommit: githubCommits){
                    //defaulting commit flag to false
                    thisCommit.latestCommitFlag = false;

                    if(NewestCommitDateTime < thisCommit.commitInfo.committer.commitDate){
                        NewestCommitDateTime = thisCommit.commitInfo.committer.commitDate;
                    }
                }
                system.debug('Latest commit date is: ' + NewestCommitDateTime + '. now setting it as latest commit flag');

                for(GithubRepoCommit thisCommit: githubCommits){
                    if(NewestCommitDateTime == thisCommit.commitInfo.committer.commitDate){
                        thisCommit.latestCommitFlag = true;
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

    /* 
    * Get individual commit
    */
    public static GithubRepoCommit getGithubCommit(String commitUrl){
        system.debug('Running getGithubCommit against URL:' + commitUrl);

        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(commitUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"commitInfo":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            //system.debug('Processing JSON: ' + JSONResponse);
            GithubRepoCommit githubCommit = (GithubRepoCommit)System.JSON.deserialize(JSONResponse, GithubRepoCommit.class);

            if(githubCommit != null){
                system.debug(githubCommit);
                return githubCommit;
            }
            return null;
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }



    public static List<GithubRepoTag> getGithubTags(String githubUrl){
        system.debug('Running getGithubTags against URL:' + githubUrl);
        String newGithubUrl = CpmGithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(newGithubUrl + '/tags', false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"githubCommit":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            //system.debug('Processing JSON: ' + JSONResponse);
            List<GithubRepoTag> githubTags = (List<GithubRepoTag>)System.JSON.deserialize(JSONResponse, List<GithubRepoTag>.class);

            if(githubTags != null && githubTags.size() > 0){
                system.debug(githubTags);
                system.debug('Found Tags, grabbing commits');

                List<GithubRepoCommit> githubCommits = CpmGithubAPIHelper.getGithubCommits(githubUrl);

                if(githubCommits != null && githubCommits.size() > 0){
                    system.debug(githubTags);
                    system.debug('Found Commits, processing');
                    for(GithubRepoTag githubTag: githubTags){
                        for(GithubRepoCommit githubCommit: githubCommits){
                            if(githubTag.githubCommit.sha == githubCommit.sha){
                                system.debug('Commit matches tag, merging');
                                githubTag.githubCommit = githubCommit;
                                githubTag.tagDate = githubCommit.commitInfo.committer.commitDate;
                            }
                        }                        
                    }
                    system.debug('Now finding latest tag');
                    if(githubCommits.size() == 1){
                        system.debug('Only 1 tag, defaulting to latest');
                        githubTags[0].latestTagFlag = true;
                    }else{
                        DateTime NewestTagDateTime = DateTime.newInstance(1901, 1, 1, 1, 1, 0);
                        for(GithubRepoTag githubTag: githubTags){
                            if(NewestTagDateTime < githubTag.tagDate){
                                NewestTagDateTime = githubTag.tagDate;
                            }              
                        }
                        system.debug('Latest tag date is: ' + NewestTagDateTime + '. now setting it as latest tag flag');
                        for(GithubRepoTag githubTag: githubTags){
                            if(NewestTagDateTime == githubTag.tagDate){
                                githubTag.latestTagFlag = true;
                            }
                        }
                    }
                    
                    return githubTags;
                }

            }
            return null;
        }

        system.debug('There was an issue with the doRestRequestJSON');
        return null;
    }

    public static GithubRepository getGithubRepo(String githubUrl){
        system.debug('Running getGithubRepo against URL:' + githubUrl);
        String newGithubUrl = CpmGithubAPIHelper.convertToRepoApiGithubUrl(githubUrl);

        //get JSON String
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(newGithubUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"githubCommit":');
            JSONResponse = JSONResponse.replace('"owner":', '"githubRepoOwner":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            //system.debug('Processing JSON: ' + JSONResponse);
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
        String JSONResponse = CpmAPIHelper.doRestRequestJSON(githubUserUrl, false);

        if(JSONResponse != null){
            //Changing Reserved words
            JSONResponse = JSONResponse.replace('"commit":', '"githubCommit":');
            JSONResponse = JSONResponse.replace('"owner":', '"githubRepoOwner":');
            JSONResponse = JSONResponse.replace('"date":', '"commitDate":');

            //system.debug('Processing JSON: ' + JSONResponse);
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
