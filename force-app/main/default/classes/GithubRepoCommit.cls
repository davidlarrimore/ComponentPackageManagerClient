public with sharing class GithubRepoCommit {
    public String sha;
    public String url;
    public GithubRepoCommitInfo commitInfo;
    public Boolean latestCommitFlag;
    public GithubRepoCommitAuthor author;    
    
    public GithubRepoCommit() {
        this.latestCommitFlag = false;
    }
}