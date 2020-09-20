import { LightningElement, api, track} from "lwc";
import jobInfo from "@salesforce/apex/CpmAsyncJobMonitorController.getJobs";
import Utils from "c/utils";

export default class cmpAsynchJobMonitor extends LightningElement {
  @track jobIds = [];
  @track jobs = [];
  //refreshApex(valueProvisionedByWireService)

  @api
	get jobIdList() {
		return this.jobIds;
	}

	set jobIdList(value) {
    this.jobIds = value;
    this.doJobSearch();
	}

  connectedCallback() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setInterval(() => {
      if(undefined !== this.jobIds && undefined !== this.jobs){
        let stillRunningFlag = false;

        for(let i =0; i < this.jobs.length; i++){
          if (this.jobs[i].Status === "Queued" || this.jobs[i].Status === "Processing") {
            stillRunningFlag = true;
          }
        }
  
        if (stillRunningFlag) {
          console.log("Async Jobs are still running. Refreshing.....");
          this.doJobSearch();
        }
      }
    }, 5000);
  }

  doJobSearch() {
    jobInfo({ recordIds: this.jobIds })
      .then((result) => {
        console.log("cmpAsynchJobMonitor: running jobInfo");
        if (result) {
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
          
          this.error = undefined;
        }
      })
      .catch((error) => {
        this.error = error;
        //this.jobs = undefined;
      });
  }

}
