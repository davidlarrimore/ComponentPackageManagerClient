import { LightningElement, api, track } from "lwc";
import refreshComponent from "@salesforce/apex/CpmRefreshCheckerController.runApex";

export default class CpmRefreshCheckerCard extends LightningElement {
  @api recordId;
  @track error;


  connectedCallback() {
    console.log("Running doRefreshComponent");
    this.doRefreshComponent();
  }

  doRefreshComponent() {
    refreshComponent({demoComponentId: this.recordId})
      .then((data) => {
        console.log(`CpmRefreshCheckerCard Response: ${data}`);
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
      });
    }
}
