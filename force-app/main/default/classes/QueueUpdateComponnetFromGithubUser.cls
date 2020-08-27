public class QueueUpdateComponnetFromGithubUser implements Queueable, Database.AllowsCallouts  {
    Id demoComponentId = null;
    
    
    public QueueUpdateComponnetFromGithubUser(Id demoComponentId) {
        this.demoComponentId = demoComponentId;
    }


    public void execute(QueueableContext context) {
        
    }
}
