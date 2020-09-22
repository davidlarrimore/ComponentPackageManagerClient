public class QueueUpdateComponentFromGithubUser implements Queueable, Database.AllowsCallouts  {
    Id demoComponentId = null;
    
    
    public QueueUpdateComponentFromGithubUser(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }


    public void execute(QueueableContext context) {
        
    }
}
