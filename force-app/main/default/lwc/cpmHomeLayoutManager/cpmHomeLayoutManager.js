import { LightningElement, wire, track } from "lwc";

import APXAvailableDemoComponents from "@salesforce/apex/CpmComponentController.getAvailableComponents";
import APXInstalledDemoComponents from "@salesforce/apex/CpmComponentController.getInstalledComponents";
import componentInstallChecker from "@salesforce/apex/CpmComponentInstallCheckerController.runApex";

export default class CmpHomeLayoutManager extends LightningElement {
  availableDemoComponents;
  installedDemoComponents;
  @track error;
  jobList = [];

  connectedCallback() {
    this.doDemoComponentRefresh();
  }

  doDemoComponentRefresh() {
    APXAvailableDemoComponents({ recordIds: this.jobIds })
      .then((data) => {
        console.log("CmpHomeLayoutManager.APXAvailableDemoComponents SUCCESS");
        console.log(`Found ${data.length} availableDemoComponents`);
        this.availableDemoComponents = data;
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        console.log(
          `CmpHomeLayoutManager APXAvailableDemoComponents ERROR: ${JSON.stringify(
            error
          )}`
        );
      });

    APXInstalledDemoComponents({ recordIds: this.jobIds })
      .then((data) => {
        console.log("CmpHomeLayoutManager.APXInstalledDemoComponents SUCCESS");
        console.log(`Found ${data.length} availableDemoComponents`);
        this.installedDemoComponents = data;
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        console.log(
          `CmpHomeLayoutManager APXInstalledDemoComponents ERROR: ${JSON.stringify(
            error
          )}`
        );
      });
  }

  @wire(componentInstallChecker)
  wiredcomponentInstallChecker({ error, data }) {
    console.log("Running CmpHomeLayoutManager.wiredcomponentInstallChecker");
    if (data) {
      console.log(`wiredcomponentInstallChecker Response: ${data}`);

      let newjobList = [];
      for (let i = 0; i < data.length; i++) {
        newjobList.push(String(data[i]));
      }
      this.jobList = newjobList;

      console.log(
        `CmpHomeLayoutManager.wiredcomponentInstallChecker Received the following Data: ${this.jobList}`
      );
      this.error = undefined;
    } else if (error) {
      console.log(
        `CmpHomeLayoutManager.wiredcomponentInstallChecker ERROR: ${JSON.stringify(
          error
        )}`
      );
      this.error = error;
      this.jobList = undefined;
    }
  }

  get getIDs() {
    return this.record;
  }

  handleAddedDemoComponent(event) {
    console.log(`Running handleAddedDemoComponent`);
    console.log(
      `Adding the following Jobs: ${event.detail.jobList.length} - ${event.detail.jobList}`
    );

    let newJobList = this.jobList;
    for (let i = 0; i < event.detail.jobList.length; i++) {
      newJobList.push(String(event.detail.jobList[i]));
    }
    this.jobList = newJobList;

    console.log(`Updated jobList: ${this.jobList.length} - ${this.jobList}`);

    this.doDemoComponentRefresh();
  }


  handleRemoveAsyncJobById(event){
    console.log(`Running handleRemoveAsyncJobById`);
    console.log(
      `Removing the following Job: ${event.detail.Id}`
    );

    let jobId = event.detail.Id;
    let newJobList = [];
    for(let i = 0; i < this.jobList.length; i ++){
      if (this.jobList[i] !== jobId){
        newJobList.push(this.jobList[i]);
      }
    }

    console.log(`Updated jobList: ${this.jobList.length} - ${this.jobList}`);

    this.jobList = newJobList;
  }


}
