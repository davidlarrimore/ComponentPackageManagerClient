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
    }, 6000);
  }


  doPruneJobTracker(){
    let newJobTracker = [];
    for (let i = 0; i < this.jobTracker.length; i++) {
      let job = this.jobTracker[i];
      if (job.markedForRemoval === false){
        if(job.AsyncApexJob_Status__c === 'Completed'){
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
    console.log("Processing AsyncApexJob Payload");
    if (undefined !== payload.AsyncApexJob_Id__c) {
      console.log(`Current list of AsyncApexJobs = ${this.jobTracker.length}`);

      let newJobTracker = [];
      let newJobFlag = true;

      let newJob = payload;
      newJob.icon = {};
      newJob.markedForRemoval = false;
      switch (newJob.AsyncApexJob_Status__c) {
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
          newJob.icon.name = "utility:error";
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
      console.log(`Successfully updated icons`);

      for (let i = 0; i < this.jobTracker.length; i++) {
        if (
          this.jobTracker[i].AsyncApexJob_Id__c === newJob.AsyncApexJob_Id__c
        ) {
          console.log(`Found Existing AsyncApexJob, updating...`);
          newJobFlag = false;
          newJobTracker.push(newJob);
        } else {
          newJobTracker.push(this.jobTracker[i]);
        }
      }
      console.log(`newJobFlag is ${newJobFlag}`);
      if (newJobFlag) {
        console.log(`Adding New AsyncApexJob, ${newJob.AsyncApexJob_Id__c}`);
        newJobTracker.push(newJob);
      }

      this.jobTracker = newJobTracker;
    }else{
      console.log('TODO: Will need to figure out a way for Job info to propogate, in child jobs');
    }
    console.log("Completed AsyncApexJob Payload");
  }
  /*
{"Demo_Component_Title__c":null,
  "Send_Toast__c":false,
  "ApexClass_Name__c":
  "QueueUpdateComponentFromPackageVersion",
  "Toast_Variant__c":null,
  "AsyncApexJob_Id__c":"7073D00000ypMRwQAM",
  "Toast_Title__c":null,
  "CreatedById":"0053D000004h8QDQAY",
  "AsyncApexJob_Status__c":"Queued",
  "CreatedDate":"2020-09-23T18:09:10Z",
  "Toast_Message__c":null,
  "jobTracker":"Fetching Updated Component Package Info",
  "Demo_Component_Id__c":null,"Toast_Mode__c":null,
  "AsyncApexJob_Parent_Id__c":"7073D00000ypMJsQAM"}
*/

  doToast(payload) {
    console.log("Publishing Toast");
    try {
      const evt = new ShowToastEvent({
        mode: "pester",
        title: payload.Toast_Title__c,
        message: payload.Toast_Message__c,
        variant: payload.Toast_Variant__c
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

      if (response.data.payload.Send_Toast__c) {
        this.doToast(response.data.payload);
      }

      console.log("Published Toast");
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
