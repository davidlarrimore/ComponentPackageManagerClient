public class XTagFile {
    public String name;
    public String demoComponentId;
    public Datetime installDateTime;
    public String githubBranch;
    public String githubRepositoryUrl;
    public String installType;
    public String commitHash;
    public String commitTagName;
    public Boolean demoComponentAlreadyExistsFlag;
    public Boolean demoComponentAlreadyInstalledFlag;
    public XTagFile() {
        this.demoComponentAlreadyExistsFlag = false;
        this.demoComponentAlreadyInstalledFlag = false;
    }
}