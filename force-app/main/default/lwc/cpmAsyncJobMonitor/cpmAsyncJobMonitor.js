import { LightningElement, track } from "lwc";
import { subscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class cmpAsynchJobMonitor extends LightningElement {
  channelName = "/event/Cpm_Async_Event__e";
  isSubscribed = false;
  isSubscriptionError = false;
  isSubscriptionRequested = true;
  subscription = {};

  cols = [
    {
        type: 'text',
        fieldName: 'Job_Name__c',
        label: 'Job Name',
    },
    {
        type: 'text',
        label: 'Status',
        cellAttributes: { iconName: { fieldName: 'iconName' }, iconPosition: 'right'},
        initialWidth:80
    },
  ];

  @track jobTracker = [];

  get hasJobs(){
    if(this.jobTracker.length > 0){
      return true;
    }
    return false;
  }

  connectedCallback() {
    console.log(`cmpAsynchJobMonitor Callback`);
    this.registerErrorListener();
    this.handleSubscribe();
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setInterval(() => {
      console.log(`PING! Interval hit...pruning`);
      this.doPruneJobTracker();
    }, 10000);
  }


  doPruneJobTracker(){
    let newJobTracker = [];
    for (let i = 0; i < this.jobTracker.length; i++) {
      let job = this.jobTracker[i];
      if (job.markedForRemoval === false){
        if(job.Current_Job_Stage__c === 'Completed'){
          job.markedForRemoval = true;
          console.log(`${job.Job_Name__c} is completed and now marked for removal, will remove next round.`);
        }
        newJobTracker.push(job);
      }
    }
    this.jobTracker = newJobTracker;
  }

  doProcessPlatformEventCPMAsync(payload) {
    console.log(`Processing CPM Async Event Payload ${payload.Job_Id__c}`);
    if (undefined !== payload.Job_Id__c) {
      console.log(`Current list of CPM Async Events (Cpm_Async_Event__e) = ${this.jobTracker.length}`);
      let newJob = payload;
      newJob.icon = {};
      newJob.events = [];

      let newJobEvent = [{
        'Event_Status_Title__c': payload.Event_Status_Title__c,
        'Event_Status_Message__c': payload.Event_Status_Message__c,
        'Event_Level__c': payload.Event_Level__c,
        'Current_Job_Stage__c': payload.Current_Job_Stage__c
      }];

      newJob.markedForRemoval = false;


      newJob.iconName = this.doGetIconName(newJob.Current_Job_Stage__c);

      console.log(`Successfully updated icons for ${newJob.Current_Job_Stage__c}`);

      for (let i = 0; i < this.jobTracker.length; i++) {
        if (this.jobTracker[i].Job_Id__c === newJob.Job_Id__c) {
          console.log(`Found Existing CPM Async Event (Cpm_Async_Event__e), updating Events...`);
          newJob.events = this.jobTracker[i].events;

          if (this.jobTracker[i]._children) {
            newJob._children = this.jobTracker[i]._children;
          }

        }
      }

      newJob.events.push(newJobEvent);
      this.doPushJob(newJob);

    }else{
      console.log('TODO: Will need to figure out a way for Job info to propogate, in child jobs');
    }
    console.log("Completed doProcessPlatformEventCPMAsync()");
  }

  doPushJob(newJob){
    console.log(`Pushing Job`);
    //Processing Child Jobs
    if (newJob.Job_Parent_Id__c != null) {
      console.log(`This is a Child Job, adding to child`);
      let newJobTracker = this.jobTracker;
      for (let i = 0; i < newJobTracker.length; i++) {
        if (newJobTracker[i].Job_Id__c === newJob.Job_Parent_Id__c) {
          if (newJobTracker[i]._children) {
            console.log(`Parent job had existing Children, Upserting`);
            let newChildArray = [];
            let newChildJobFlag = true;
              for (let j = 0; j < newJobTracker[i]._children.length; j++) {
                if (newJobTracker[i]._children[j].Job_Id__c === newJob.Job_Id__c) {
                  console.log(`Found the existing Child Job`);
                  newChildJobFlag = false;
                  newChildArray.push(newJob);
                }else{
                  newChildArray.push(newJobTracker[i]._children[j]);
                }
              }
              if(newChildJobFlag){
                console.log(`This was a newly reported child job for this parent Job, adding`);
                newChildArray.push(newJob);
              }
              newJobTracker[i]._children = newChildArray;
          }else{
            console.log(`Parent Job had no children...Congratulations, you are now a father...`);
            newJobTracker[i]._children = [];
            newJobTracker[i]._children.push(newJob);
          }
          newJobTracker[i] = this.doGetParentStatus(newJobTracker[i]);
        }
      }
      this.jobTracker = newJobTracker;
    }else{
      console.log(`This is not a child Job`);
      let newJobFlag = true;
      let newJobTracker = [];
      for (let i = 0; i < this.jobTracker.length; i++) {
        if (this.jobTracker[i].Job_Id__c === newJob.Job_Id__c) {
          console.log(`Found Existing CPM Async Event (Cpm_Async_Event__e), updating...`);
          newJobFlag = false;
          newJob.events = this.jobTracker[i].events;
          if(this.jobTracker[i]._children){
            newJob._children = this.jobTracker[i]._children;
          }
          newJob = this.doGetParentStatus(newJob);
          newJobTracker.push(newJob);
        }else{
          newJobTracker.push(this.jobTracker[i]);
        }
      }
      if(newJobFlag){
        newJobTracker.push(newJob);
      }
      this.jobTracker = newJobTracker;
    }
    console.log(`Completed Pushing Job ${newJob.Job_Id__c}`);
  }


  doGetParentStatus(parentJob){
    //LOGIC TO SEE IF CHILD JOBS EXISTS, IF SO, WE UPDATE STAGE TO REFLECT OVERALL STATUS
    let jobFailedFlag = false;
    if(parentJob._children){
      for (let i = 0; i < parentJob._children.length; i++) {
        let runningJobFlag = false;
        //If any child jobs are less than completed, we mark as processing
        if (this.getJobStageNumber(parentJob._children[i].Current_Job_Stage__c) < 3){
          console.log(`Child Jobs are not done, setting parent status to "processing"`);
          parentJob.Current_Job_Stage__c = "Processing";
          runningJobFlag = true;
        }else if(parentJob._children[i].Current_Job_Stage__c === "Failed"){
          jobFailedFlag = true;
        }

        if(jobFailedFlag){
          parentJob.Current_Job_Stage__c = "Failed";
        }else if(!runningJobFlag){
            console.log(`All child jobs are done, setting to "Completed"`);
            parentJob.Current_Job_Stage__c = "Completed";
        }


      }

    }
    parentJob.iconName = this.doGetIconName(parentJob.Current_Job_Stage__c);
    return parentJob;
  }



 doGetIconName(Current_Job_Stage__c){
  let iconName = `action:refresh`;

  switch (Current_Job_Stage__c) {
    case "Completed":
      iconName = "action:approval";
      break;
    case "Queued":
      iconName = "action:refresh";
      break;
    case "Processing":
      iconName = "action:defer";
      break;
    case "Failed":
      iconName = "action:close";
      break;
    case "Completed with Errors":
      iconName = "action:close";
      break;
    default:
      iconName = "action:refresh";
      break;
  }

    return iconName;
 }



  doToast(payload) {
    console.log("Publishing Toast");
    let mode = 'pester';

    if(payload.Event_Level__c === "error"){
      mode = 'sticky';
    }

    try {
      const evt = new ShowToastEvent({
        mode: mode,
        title: payload.Event_Status_Title__c,
        message: payload.Event_Status_Message__c,
        variant: payload.Event_Level__c
      });
      this.dispatchEvent(evt);
    } catch (err) {
      console.log(`Toast error: ${err}`);
    }
  }

  getJobStageNumber(jobStage){

    let retval = 1;
    switch (jobStage) {
      case "Completed":
        retval = 3;
        break;
      case "Queued":
        retval = 1;
        break;
      case "Processing":
        retval = 2;
        break;
      case "Failed":
        retval = 3;
        break;
      default:
        retval = 1;
        break;
    }
    return retval;
  }


  // Tracks changes to channelName text field
  handleChannelName(event) {
    this.channelName = event.target.value;
  }

  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = (response) => {
      console.log(`New Async Job message received: ${JSON.stringify(response)}`);
      this.doProcessPlatformEventCPMAsync(response.data.payload);

      if (response.data.payload.Send_Toast_Flag__c) {
        console.log(`Toast requested`);
        this.doToast(response.data.payload);
      }

      // Response contains the payload of the new message received
    }

    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log(`Subscription request sent to: ${JSON.stringify(response.channel)}`);
      console.log(`Subscription request Response: ${JSON.stringify(response)}`);
      this.subscription = response;
      this.isSubscriptionRequested = false;
      this.isSubscribed = true;
    });
  }

  registerErrorListener() {
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      this.isSubscriptionRequested = false;
      this.isSubscribed = false;
      this.isSubscriptionError = true;
      const evt = new ShowToastEvent({
        mode: 'pester',
        title: `Async Monitor Error: Failed to connect to Platform Events`,
        message: `Error: ${JSON.stringify(error)}`,
        variant: 'error'
      });
      this.dispatchEvent(evt);
    });
  }
}