import { LightningElement, api, track} from "lwc";
import jobInfo from "@salesforce/apex/CpmAsyncJobMonitorController.getJobsByDate";
import Utils from "c/utils";

export default class cmpAsynchJobMonitor extends LightningElement {
  @track jobIds = [];
  @track jobs = [];
  //refreshApex(valueProvisionedByWireService)
  inDate = new Date();

  @api
	get jobIdList() {
		return this.jobIds;
	}

	set jobIdList(value) {
      if(this.jobIdList.length > 0){
        console.log(`Adding ${value} to Tracked jobList`);
        this.jobIds.push(value);
      }else{
        console.log(`Initializing Tracked JobList`);
        this.jobIds = value;
      } 

      console.log(`Job List: ${this.jobIds.length} - ${this.jobIds}`);
      this.doJobSearch();
	}

  connectedCallback() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setInterval(() => {
      console.log(`PING! Interval hit...`);
      if(this.jobIdList.length > 0){
          console.log(`Processing the following Tracked Jobs: ${this.jobIdList.length} - ${this.jobIdList}`);
          this.doJobSearch();
      }
    }, 6000);
  }

  doJobSearch() {
    jobInfo({ recordIds: this.jobIds, inDate:this.inDate  })
      .then((result) => {
        console.log("cmpAsynchJobMonitor: running jobInfo");
        if (result) {
          console.log(`Received ${result.length} results`);
          if(result.length > 0){
            console.log(`Results: ${JSON.stringify(result)}`);
            this.jobs = result;
            for(let i =0; i < this.jobs.length; i++){
              if (this.jobs[i].Status === "Completed") {
                this.jobs[i].jobStatusClass = "slds-badge slds-theme_success";
              } else if (this.jobs[i].Status === "Queued") {
                this.jobs[i].jobStatusClass = "slds-badge";
              } else if (this.jobs[i].Status === "Processing") {
                this.jobs[i].jobStatusClass = "slds-badge slds-theme_warning";
              } else if (this.jobs[i].Status === "Failed") {
                this.jobs[i].jobStatusClass = "slds-badge slds-theme_error";
                Utils.showToast(
                  this,
                  "Job Failed",
                  `Job ${this.jobId} failed with message: ${this.jobExtendedStatus}`,
                  "error"
                );
              }else{
                this.jobs[i].jobStatusClass = "slds-badge_lightest";
              }
            }
          }
          this.error = undefined;
        }
      })
      .catch((error) => {
        console.log(`cmpAsynchJobMonitor ERROR: ${JSON.stringify(error)}`);
        this.error = error;
        //this.jobs = undefined;
      });
  }

}
