import { LightningElement, api, track } from "lwc";
import jobInfo from "@salesforce/apex/CpmAsyncJobMonitorController.getAllJobs";

export default class cmpAsynchJobMonitor extends LightningElement {
  jobIds = [];

  @track jobs = [];

  @api
  get jobIdList() {
    return this.jobIds;
  }

  set jobIdList(value) {
    this.jobIds = value;
    console.log(`Job List: ${this.jobIds}`);
  }

  connectedCallback() {
    // eslint-disable-next-line @lwc/lwc/no-async-operation
    setInterval(() => {
      console.log(`PING! Interval hit...`);
      if (this.jobIdList.length > 0) {
        console.log(
          `Processing the following Tracked Jobs: ${JSON.stringify(
            this.jobIdList
          )}`
        );
        this.doJobSearch();
      }
    }, 6000);

    this.doJobSearch();
  }

  doJobSearch() {
    jobInfo({ recordIds: this.jobIds })
      .then((result) => {
        console.log("cmpAsynchJobMonitor: running jobInfo");
        if (result) {
          console.log(`Received ${result.length} AsyncApexJobs`);
          if (result.length > 0) {
            if (this.jobs.length > 0) {
              let jobInfoResults = result;
              let newJobs = [];
              let existingJobs = this.jobs;

              for (let i = 0; i < jobInfoResults.length; i++) {
                let existingJobIndex = -1;
                console.log(
                  `Checking to see if ${jobInfoResults[i].Id} already exists`
                );
                for (let j = 0; j < existingJobs.length; j++) {
                  if (jobInfoResults[i].Id === existingJobs[j].Id) {
                    console.log(`It exists, setting Index as ${j}`);
                    existingJobIndex = j;
                  }
                }

                if (existingJobIndex > -1) {
                  console.log(
                    `Existing Status=${existingJobs[existingJobIndex].Status} || New Status=${jobInfoResults[i].Status}`
                  );
                  if (
                    jobInfoResults[i].Status === "Completed" &&
                    existingJobs[existingJobIndex].Status === "Completed"
                  ) {
                    console.log(
                      `${existingJobs[existingJobIndex].Id} Is already completed, Marking as Completed and removing from List`
                    );
                    
                    this.dispatchEvent(new CustomEvent('removeasyncjobbyid', {bubbles: true, composed: true, detail :{ Id: existingJobs[existingJobIndex].Id}}));
                  } else {
                    newJobs.push(jobInfoResults[i]);
                  }
                } else {
                  newJobs.push(jobInfoResults[i]);
                }
              }
              this.jobs = newJobs;
            } else {
              this.jobs = result;
            }

            //We may have just removed all of the jobs.....
            if (this.jobs.length > 0) {
              for (let i = 0; i < this.jobs.length; i++) {
                this.jobs[i].icon = {};
                switch (this.jobs[i].Status) {
                  case "Completed":
                    this.jobs[i].icon.name = "action:approval";
                    this.jobs[i].icon.altText = "Completed";
                    this.jobs[i].icon.title = "Completed";
                    this.jobs[i].icon.variant = "success";
                    break;
                  case "Queued":
                    this.jobs[i].icon.name = "action:refresh";
                    this.jobs[i].icon.altText = "Queued";
                    this.jobs[i].icon.title = "Queued";
                    this.jobs[i].icon.variant = "inverse";
                    break;
                  case "Processing":
                    this.jobs[i].icon.name = "action:defer";
                    this.jobs[i].icon.altText = "Processing";
                    this.jobs[i].icon.title = "Processing";
                    this.jobs[i].icon.variant = "warning";
                    break;
                  case "Failed":
                    this.jobs[i].icon.name = "utility:error";
                    this.jobs[i].icon.altText = "Failed";
                    this.jobs[i].icon.title = "Failed";
                    this.jobs[i].icon.variant = "error";
                    break;
                  default:
                    this.jobs[i].icon.name = "action:refresh";
                    this.jobs[i].icon.altText = "Other";
                    this.jobs[i].icon.title = "Other";
                    this.jobs[i].icon.variant = "inverse";
                    break;
                }

                switch (this.jobs[i].ApexClass.Name) {
                  case "QueueGetInstalledPackages":
                    this.jobs[i].JobName = "Checking for Installed Packages";
                    break;
                  case "QueueUpdateComponentFromPackageVersion":
                    this.jobs[i].JobName =
                      "Fetching Updated Component Package Info";
                    break;
                  case "QueueUpdateComponentSourceCommitInfo":
                    this.jobs[i].JobName =
                      "Fetching Updated Source Commit Info";
                    break;
                  case "QueueUpdateComponentFromSFDX":
                    this.jobs[i].JobName = "Fetching Updated SFDX Info";
                    break;
                  case "QueueUpdateComponentSourceTagInfo":
                    this.jobs[i].JobName = "Fetching Updated Source Tag Info";
                    break;
                  case "QueueUpdateComponentFromGithubUser":
                    this.jobs[i].JobName = "Fetching Updated Source Owner Info";
                    break;
                  default:
                    this.jobs[i].JobName = this.jobs[i].ApexClass.JobName;
                    break;
                }
              }
              console.log(`Converted Results: ${JSON.stringify(this.jobs)}`);
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
