import { LightningElement, api, track, wire } from "lwc";
import refreshComponent from "@salesforce/apex/CpmRefreshCheckerController.runApex";

console.log("Running CpmRefreshCheckerCard");

export default class CpmRefreshCheckerCard extends LightningElement {
  @api recordId;
  @track error;
  jobList = [];

  @wire(refreshComponent, { searchKey: "$recordId" })
  wiredrefreshComponent({ error, data }) {
    console.log("wiredrefreshComponent");
    if (data) {
      console.log(
        `CpmRefreshCheckerCard.wiredrefreshComponent Response: ${data}`
      );

      let newjobList = [];
      for (let i = 0; i < data.length; i++) {
        newjobList.push(String(data[i]));
      }
      this.jobList = newjobList;

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
