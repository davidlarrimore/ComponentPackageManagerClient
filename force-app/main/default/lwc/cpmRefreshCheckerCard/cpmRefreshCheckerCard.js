import { LightningElement, api, track, wire } from "lwc";
import refreshComponent from "@salesforce/apex/CpmRefreshCheckerController.runApex";

console.log("Running CpmRefreshCheckerCard");

export default class CpmRefreshCheckerCard extends LightningElement {
  @api recordId;
  @track error;
  @track record = [];

  @wire(refreshComponent, { searchKey: "$recordId" })
  wiredrefreshComponent({ error, data }) {
    console.log("wiredrefreshComponent");
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
