public class GithubSFDXProjectDotJSON {
    public List<GithubPackageDirectory> packageDirectories;
    public String namespace;
    public string sfdcLoginUrl;
    public String sourceApiVersion;
    public String errorFlag;
    public String errorMessage;
    public map<string,string> packageAliases;    
    
    public GithubSFDXProjectDotJSON() {

    }

    public String getLatestVersionPackageVersionId(){
        system.debug('Running GithubSFDXProjectDotJSON.getLatestVersionAlias');            
        String highestVersionPackageVersion = '';
        Integer highestVersionNumber = 0;

        for (String packageAlias: this.packageAliases.keySet()){   
            if(packageAlias.indexOf('@') > 0){  
                String thisVersionText = getVersionNumberFromAlias(packageAlias);
                Integer thisVersionNumber = CpmVersionHelper.getVersionNumberFromText(thisVersionText);

                if(thisVersionNumber > highestVersionNumber){
                    highestVersionNumber = thisVersionNumber;
                    highestVersionPackageVersion = this.packageAliases.get(packageAlias);
                }
            }
        }
        return highestVersionPackageVersion;
    }

    public String getLatestVersionAlias(){
        system.debug('Running GithubSFDXProjectDotJSON.getLatestVersionAlias');            
        String latestVersionAlias = '';
        Integer highestVersionNumber = 0;

        for (String packageAlias: this.packageAliases.keySet()){
            if(packageAlias.indexOf('@') > 0){  
                String thisVersionText = getVersionNumberFromAlias(packageAlias);
                Integer thisVersionNumber = CpmVersionHelper.getVersionNumberFromText(thisVersionText);

                if(thisVersionNumber > highestVersionNumber){
                    highestVersionNumber = thisVersionNumber;
                    latestVersionAlias = packageAlias;
                }
            }
        }

        return latestVersionAlias;
    }


    public String getLatestVersionText(){
        system.debug('Running GithubSFDXProjectDotJSON.getLatestVersionText');       
        String highestVersionText = '0.0.0-1';
        Integer highestVersionNumber = 10;

        for (String packageAlias: this.packageAliases.keySet()){   
            if(packageAlias.indexOf('@') > 0){
                String thisVersionText = getVersionNumberFromAlias(packageAlias);
                Integer thisVersionNumber = CpmVersionHelper.getVersionNumberFromText(thisVersionText);
    
                if(thisVersionNumber > highestVersionNumber){
                    highestVersionNumber = thisVersionNumber;
                    highestVersionText = thisVersionText;
                }
            }else{
                system.debug(packageAlias + 'Is base Package, not a Version');
            }
        }

        return highestVersionText;
    }

    public String getVersionNumberFromAlias(String alias){     
        return alias.substring(alias.indexOf('@')+1, alias.length());
    }    

    public Integer getLatestVersionNumber(){
        return CpmVersionHelper.getVersionNumberFromText(getLatestVersionText());
    }



}