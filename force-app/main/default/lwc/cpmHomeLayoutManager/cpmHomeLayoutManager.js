import { LightningElement, wire, track } from "lwc";
import { refreshApex } from '@salesforce/apex';

import availableDemoComponents from "@salesforce/apex/CpmComponentController.getAvailableComponents";
import installedDemoComponents from "@salesforce/apex/CpmComponentController.getInstalledComponents";
import componentInstallChecker from "@salesforce/apex/CpmComponentInstallCheckerController.runApex";

export default class CmpHomeLayoutManager extends LightningElement {
  @track availableDemoComponents;
  @track installedDemoComponents;
  @track error;
  @track record = [];

  @wire(availableDemoComponents)
  wiredAvailableDemoComponents({ error, data }) {
    if (data) {
      console.log("CmpHomeLayoutManager.wiredAvailableDemoComponents SUCCESS");
      //console.log(`Data = ${console.log(JSON.stringify(data))}`);
      this.availableDemoComponents = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log(
        "CmpHomeLayoutManager wiredAvailableDemoComponents ERROR: " + error
      );
    }
  }


  @wire(installedDemoComponents)
  wiredInstalledDemoComponents({ error, data }) {
    if (data) {
      console.log("CmpHomeLayoutManager.wiredInstalledDemoComponents SUCCESS");
      //console.log(`Data = ${console.log(JSON.stringify(data))}`);
      this.installedDemoComponents = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log(
        "CmpHomeLayoutManager wiredDemoComponents ERROR: " + error
      );
    }
  }
 

  @wire(componentInstallChecker)
  wiredcomponentInstallChecker({ error, data }) {
    console.log("Running CmpHomeLayoutManager.wiredcomponentInstallChecker");
    if (data) {
      this.record = data;
      console.log(`CmpHomeLayoutManager.wiredcomponentInstallChecker Received the following Data: ${this.record}`);
      this.error = undefined;
    } else if (error) {
      console.log(`CmpHomeLayoutManager.wiredcomponentInstallChecker ERROR: ${JSON.stringify(error)}`);
      this.error = error;
      this.record = undefined;
    }
  }

  get getIDs() {
    return this.record;
  }

  refreshDemoComponents(){
    console.log('Refreshing DemoComponents');
    refreshApex(this.wiredAvailableDemoComponents);
    refreshApex(this.installedDemoComponents);
  }


}
