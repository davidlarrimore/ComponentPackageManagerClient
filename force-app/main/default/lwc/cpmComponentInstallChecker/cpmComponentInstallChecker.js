import { LightningElement, track, wire } from "lwc";
import installedComponents from "@salesforce/apex/CpmComponentInstallCheckerController.runApex";

console.log("Running CPMInstallCheckerCard");

export default class CpmInstallCheckerCard extends LightningElement {
  @track error;
  @track record;

  @wire(installedComponents)
  wiredInstalledComponents({ error, data }) {
    console.log("wiredInstalledComponents");
    if (data) {
      this.record = data;
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.record = undefined;
    }
  }

  get getIDs() {
    return this.record;
  }

  get apexRanFlag() {
    if (this.record) {
      return true;
    }
    return false;
  }
}
