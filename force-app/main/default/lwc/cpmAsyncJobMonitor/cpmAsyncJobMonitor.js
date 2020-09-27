import { LightningElement, track } from "lwc";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class cmpAsynchJobMonitor extends LightningElement {
  channelName = "/event/CPM_Async_Event__e";
  isSubscribeDisabled = false;
  isUnsubscribeDisabled = !this.isSubscribeDisabled;
  subscription = {};

  @track jobTracker = [];


  get hasJobs(){
    if(this.jobTracker.length > 0){
      return true;
    }
    return false;
  }

  connectedCallback() {
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
          console.log(`${job.AsyncApexJob_Name__c} is completed and now marked for removal, will remove next round.`);
        }
        newJobTracker.push(job);
      }
    }
    this.jobTracker = newJobTracker;
  }


  // Tracks changes to channelName text field
  handleChannelName(event) {
    this.channelName = event.target.value;
  }

  doProcessPlatformEventCPMAsync(payload) {
    console.log("Processing CPM Async Event Payload");
    if (undefined !== payload.Job_Id__c) {
      console.log(`Current list of CPM Async Events (CPM_Async_Event__e) = ${this.jobTracker.length}`);

      let newJobTracker = [];
      let newJobFlag = true;
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
      switch (newJob.Current_Job_Stage__c) {
        case "Completed":
          newJob.icon.name = "action:approval";
          newJob.icon.altText = "Completed";
          newJob.icon.title = "Completed";
          newJob.icon.variant = "success";
          break;
        case "Queued":
          newJob.icon.name = "action:refresh";
          newJob.icon.altText = "Queued";
          newJob.icon.title = "Queued";
          newJob.icon.variant = "inverse";
          break;
        case "Processing":
          newJob.icon.name = "action:defer";
          newJob.icon.altText = "Processing";
          newJob.icon.title = "Processing";
          newJob.icon.variant = "warning";
          break;
        case "Failed":
          newJob.icon.name = "action:close";
          newJob.icon.altText = "Failed";
          newJob.icon.title = "Failed";
          newJob.icon.variant = "error";
          break;
        default:
          newJob.icon.name = "action:refresh";
          newJob.icon.altText = "Other";
          newJob.icon.title = "Other";
          newJob.icon.variant = "inverse";
          break;
      }
      console.log(`Successfully updated icons for ${newJob.Current_Job_Stage__c}`);


      
      for (let i = 0; i < this.jobTracker.length; i++) {
        if (this.jobTracker[i].Job_Id__c === newJob.Job_Id__c) {
          console.log(`Found Existing CPM Async Event (CPM_Async_Event__e), updating...`);
          newJobFlag = false;
          newJob.events = this.jobTracker[i].events;
          newJob.events.push(newJobEvent);

          newJobTracker.push(newJob);

        } else {
          newJobTracker.push(this.jobTracker[i]);
        }
      }
      
      console.log(`newJobFlag is ${newJobFlag}`);
      if (newJobFlag) {
        console.log(`Adding New CPM Async Event (CPM_Async_Event__e), ${newJob.Job_Id__c}`);
        newJob.events.push(newJobEvent);
        newJobTracker.push(newJob);
      }

      this.jobTracker = newJobTracker;
    }else{
      console.log('TODO: Will need to figure out a way for Job info to propogate, in child jobs');
    }
    console.log("Completed doProcessPlatformEventCPMAsync()");
  }

  doToast(payload) {
    console.log("Publishing Toast");
    try {
      const evt = new ShowToastEvent({
        mode: "pester",
        title: payload.Event_Status_Title__c,
        message: payload.Event_Status_Message__c,
        variant: payload.Event_Level__c
      });
      this.dispatchEvent(evt);
    } catch (err) {
      console.log(`Toast error: ${err}`);
    }
  }

  // Handles subscribe button click
  handleSubscribe() {
    // Callback invoked whenever a new event message is received
    const messageCallback = function (response) {
      console.log("New message received: ", JSON.stringify(response));
      this.doProcessPlatformEventCPMAsync(response.data.payload);

      if (response.data.payload.Send_Toast_Flag__c) {
        console.log(`Toast requested`);
        this.doToast(response.data.payload);
      }

      // Response contains the payload of the new message received
    }.bind(this);

    // Invoke subscribe method of empApi. Pass reference to messageCallback
    subscribe(this.channelName, -1, messageCallback).then((response) => {
      // Response contains the subscription information on subscribe call
      console.log(
        "Subscription request sent to: ",
        JSON.stringify(response.channel)
      );
      this.subscription = response;
      this.toggleSubscribeButton(true);
    });
  }

  // Handles unsubscribe button click
  handleUnsubscribe() {
    this.toggleSubscribeButton(false);

    // Invoke unsubscribe method of empApi
    unsubscribe(this.subscription, (response) => {
      console.log("unsubscribe() response: ", JSON.stringify(response));
      // Response is true for successful unsubscribe
    });
  }

  toggleSubscribeButton(enableSubscribe) {
    this.isSubscribeDisabled = enableSubscribe;
    this.isUnsubscribeDisabled = !enableSubscribe;
  }

  registerErrorListener() {
    // Invoke onError empApi method
    onError((error) => {
      console.log("Received error from server: ", JSON.stringify(error));
      // Error contains the server-side error
    });
  }
}
