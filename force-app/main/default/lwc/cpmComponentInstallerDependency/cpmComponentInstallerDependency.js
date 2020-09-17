import { LightningElement, api, track, wire } from "lwc";
import dependentPackages from "@salesforce/apex/CpmComponentInstallerController.getDependentPackages";

export default class CpmComponentInstallerDependency extends LightningElement {
  @api recordId;
  @track demoComponent;
  @track error;
  @track demoComponentDependencies;
  @track selectedItemValue = "closed";

  @wire(dependentPackages, { searchKey: "$recordId" })
  wiredPackageDependencies({ error, data }) {
    if (data) {
      this.demoComponentDependencies = data;
      console.log("wiredPackageDependencies SUCCESS");
      console.log(data);
      this.error = undefined;
    } else if (error) {
      this.error = error;
      console.log("wiredPackageDependencies ERROR: " + error);
      this.demoComponentDependencies = undefined;
    }
  }

}
