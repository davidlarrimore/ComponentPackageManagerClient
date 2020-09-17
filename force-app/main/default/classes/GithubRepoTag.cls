public class GithubRepoTag {
    
    public String name;
    public GithubRepoCommit githubCommit;
    public Boolean latestTagFlag;
    public DateTime tagDate;  

    public GithubRepoTag() {
        this.latestTagFlag=false;
        
    }
}
