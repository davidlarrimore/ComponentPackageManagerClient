import { LightningElement, track } from "lwc";

import APXAvailableDemoComponents from "@salesforce/apex/CpmComponentController.getAvailableComponents";
import APXInstalledDemoComponents from "@salesforce/apex/CpmComponentController.getInstalledComponents";
import componentInstallChecker from "@salesforce/apex/CpmComponentInstallCheckerController.runApex";

export default class CmpHomeLayoutManager extends LightningElement {
  availableDemoComponents;
  installedDemoComponents;
  @track error;

  connectedCallback() {
    this.doDemoComponentRefresh();
    this.doComponentInstallChecker();
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


  doComponentInstallChecker() {
    componentInstallChecker()
    .then((data) => {
      console.log(`wiredcomponentInstallChecker Response: ${data}`);
      this.error = undefined;
    })
    .catch((error) => {
      this.error = error;
    });
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

}
