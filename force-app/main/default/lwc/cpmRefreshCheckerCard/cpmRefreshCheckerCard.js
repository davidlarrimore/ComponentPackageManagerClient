import { LightningElement, api, track, wire } from "lwc";
import refreshComponent from "@salesforce/apex/CpmRefreshCheckerController.runApex";

console.log("Running CpmRefreshCheckerCard");

export default class CpmRefreshCheckerCard extends LightningElement {
  @api recordId;
  @track error;

  @wire(refreshComponent, { searchKey: "$recordId" })
  wiredrefreshComponent({ error, data }) {
    console.log("wiredrefreshComponent");
    if (data) {
      console.log(
        `CpmRefreshCheckerCard.wiredrefreshComponent Response: ${data}`
      );
      this.error = undefined;
    } else if (error) {
      console.log(
        `CpmRefreshCheckerCard.wiredrefreshComponent ERROR: ${JSON.stringify(
          error
        )}`
      );
      this.error = error;
      this.record = undefined;
    }
  }
}
