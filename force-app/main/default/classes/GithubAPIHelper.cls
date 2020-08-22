public with sharing class GithubAPIHelper {


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

    public static Map<String,Object> getGithubSFDXProjectDotJSON(String githubUrl){
        system.debug('Running getGithubSFDXProjectDotJSON against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRawGithubUrl(githubUrl, 'sfdx-project.json');

        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
        return (Map<String,Object>) APIHelper.doRestRequest(newGithubUrl, false);
    }

    public static Map<String,Object> getGithubDemoConfigDotJSON(String githubUrl){
        system.debug('Running getGithubDemoConfigDotJSON against URL:' + githubUrl);
        String newGithubUrl = GithubAPIHelper.convertToRawGithubUrl(githubUrl, 'demo-config.json');

        String SFdomainUrl=URL.getSalesforceBaseUrl().toExternalForm();
        return (Map<String,Object>) APIHelper.doRestRequest(newGithubUrl, false);
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

}
