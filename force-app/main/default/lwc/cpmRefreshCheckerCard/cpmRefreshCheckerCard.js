import { LightningElement, api, track, wire } from "lwc";
import refreshComponent from "@salesforce/apex/CpmRefreshCheckerController.runApex";

console.log("Running CpmRefreshCheckerCard");

export default class CpmRefreshCheckerCard extends LightningElement {
  @api recordId;
  @track error;
  @track record = [];

  @wire(refreshComponent, { searchKey: "$recordId" })
  wiredrefreshComponent({ error, data }) {
    console.log("Running CpmRefreshCheckerCard.wiredrefreshComponent");
    if (data) {
      this.record = data;
      console.log(`CpmRefreshCheckerCard.wiredrefreshComponent Received the following Data: ${this.record}`);
      this.error = undefined;
    } else if (error) {
      console.log(`CpmRefreshCheckerCard.wiredrefreshComponent ERROR: ${JSON.stringify(error)}`);
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
